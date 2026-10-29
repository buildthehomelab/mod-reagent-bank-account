// SPDX-License-Identifier: AGPL-3.0-or-later
#include <algorithm>
#include <atomic>
#include <cassert>
#include <cerrno>
#include <chrono>
#include <cctype>
#include <cstdint>
#include <cstdlib>
#include <future>
#include <iostream>
#include <limits>
#include <map>
#include <memory>
#include <mutex>
#include <sstream>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>
using uint8 = uint8_t;
using uint32 = uint32_t;
using uint64 = uint64_t;
static unsigned checks = 0;
#define CHECK(expr) do { ++checks; if (!(expr)) { std::cerr << __LINE__ << ": " #expr "\n"; std::exit(1); } } while (0)
static std::atomic<unsigned> errors{0};
#define LOG_ERROR(...) (++errors)
#include "definitions.inc"
static bool g_accountWideReagentBank = false;
static std::unordered_map<uint32, uint32> g_shareOwnerByKey;
struct Guid { uint32 value; uint64 GetCounter() const { return value; } std::string ToString() const { return std::to_string(value); } };
struct Session { uint32 account; uint32 GetAccountId() const { return account; } };
struct Statement { std::string sql; std::vector<uint32> args; };
struct Transaction {
    std::vector<Statement> statements;
    template<class... Args> void Append(char const* sql, Args... args) { statements.push_back({sql, {uint32(args)...}}); }
    std::size_t GetSize() const { return statements.size(); }
};
using CharacterDatabaseTransaction = std::shared_ptr<Transaction>;
struct Database {
    std::atomic<unsigned> commits{0};
    CharacterDatabaseTransaction last;
    bool success = true;
    std::shared_ptr<std::promise<bool>> pending;
    CharacterDatabaseTransaction BeginTransaction() { return std::make_shared<Transaction>(); }
    struct Result { std::future<bool> m_future; };
    Result AsyncCommitTransaction(CharacterDatabaseTransaction trans) {
        last = trans;
        ++commits;
        if (pending) return {pending->get_future()};
        std::promise<bool> promise; promise.set_value(success); return {promise.get_future()};
    }
} CharacterDatabase;
struct ItemTemplate;
struct Item { bool trade=false; uint32 count=5; bool IsInTrade() const { return trade; } uint32 GetCount() const { return count; } ItemTemplate const* GetTemplate() const; };
struct ItemTemplate { uint32 stack = 20; uint32 GetMaxStackSize() const { return stack; } };
struct ObjectMgr {
    ItemTemplate proto;
    bool missing = false;
    ItemTemplate const* GetItemTemplate(uint32) const { return missing ? nullptr : &proto; }
} objectMgr;
static ObjectMgr* sObjectMgr = &objectMgr;
ItemTemplate const* Item::GetTemplate() const { return &objectMgr.proto; }
static bool storable=true, excluded=false, quest=false;
// Eligibility services are boundary doubles in this focused suite.
static bool IsStorableReagent(ItemTemplate const*, uint32& entry, uint32& category) { entry=1; category=7; return storable; }
static bool IsDepositExcluded(uint32) { return excluded; }
using ItemPosCountVec = std::vector<uint32>;
enum InventoryResult { EQUIP_ERR_OK, EQUIP_ERR_INVENTORY_FULL };
static constexpr uint8 NULL_BAG = 0, NULL_SLOT = 0;
struct Player {
    Session session{10}; Guid guid{100}; Item item; bool present=true; unsigned destroyed=0;
    Item* GetItemByPos(uint8,uint8) { return present ? &item : nullptr; }
    void DestroyItem(uint8,uint8,bool) { ++destroyed; present=false; bags-=item.count; }
    uint32 bags = 0, capacity = UINT32_MAX, storedCalls = 0, failAt = UINT32_MAX, notified = 0, equipErrors = 0, saves = 0;
    Session const* GetSession() const { return &session; }
    Guid GetGUID() const { return guid; }
    InventoryResult CanStoreNewItem(uint8, uint8, ItemPosCountVec& dest, uint32, uint32 count) {
        if (count > capacity - bags) return EQUIP_ERR_INVENTORY_FULL;
        dest.push_back(count); return EQUIP_ERR_OK;
    }
    Item* StoreNewItem(ItemPosCountVec const& dest, uint32, bool) {
        if (storedCalls++ == failAt) return nullptr;
        bags += dest.at(0); return &item;
    }
    void SendEquipError(InventoryResult, Item*, Item*, uint32) { ++equipErrors; }
    void SendNewItem(Item*, uint32 count, bool, bool) { notified += count; }
    void SaveInventoryAndGoldToDB(CharacterDatabaseTransaction trans) { ++saves; trans->Append("inventory", bags); }
};
static bool IsNeededByActiveQuest(Player const*,uint32) { return quest; }
// LoadStoredItem is an explicit boundary double, not a tested SQL query.
static StoredItem bank{1, 7, 55};
static bool loadMissing = false;
static bool LoadStoredItem(Player const*, uint32, StoredItem& out) { out = bank; return !loadMissing; }
#include "production.inc"

static void reset() {
    storable=true; excluded=false; quest=false; objectMgr = {}; bank = {1, 7, 55}; loadMissing = false;
    g_accountWideReagentBank = false; g_shareOwnerByKey.clear();
    CharacterDatabase.last.reset(); CharacterDatabase.commits = 0;
    CharacterDatabase.pending.reset(); CharacterDatabase.success = true; errors = 0;
}
static void arithmetic() {
    uint32 out = 123;
    CHECK(AddAmountChecked(0, 0, out) && out == 0);
    CHECK(AddAmountChecked(UINT32_MAX, 0, out) && out == UINT32_MAX);
    CHECK(AddAmountChecked(UINT32_MAX - 1, 1, out) && out == UINT32_MAX);
    out = 77;
    CHECK(!AddAmountChecked(UINT32_MAX, 1, out) && out == 77);
    ItemAmountMap map{{1, UINT32_MAX}};
    CHECK(!AddToItemAmountMapChecked(map, 1, 1) && map.at(1) == UINT32_MAX);
    CHECK(!AddToItemAmountMapChecked(map, 0, 1) && map.size() == 1);
    CHECK(!AddToItemAmountMapChecked(map, 2, 0) && map.size() == 1);
    CHECK(AddToItemAmountMapChecked(map, 2, 1) && map.at(2) == 1);
    CHECK(SumItemAmountMap(map) == uint64(UINT32_MAX) + 1);
    for (auto const& invalid : {"", "-1", "+1", "1 ", " 1", "1x", "4294967296", "99999999999999999999999"}) {
        out = 42; CHECK(!TryParseUInt32(invalid, out) && out == 0);
    }
    CHECK(TryParseUInt32("4294967295", out) && out == UINT32_MAX);
    CHECK(TryParseUInt32("0", out) && out == 0);
    std::vector<std::pair<uint32,uint32>> pairs;
    CHECK(TryParseItemAmountPairs({"1", "2", "1", "3", "2", "4"}, 0, pairs));
    CHECK((pairs == std::vector<std::pair<uint32,uint32>>{{1,5},{2,4}}));
    for (auto const& tokens : std::vector<std::vector<std::string>>{{},{"1"},{"0","1"},{"1","0"},{"1","x"},{"x","1"},{"1","4294967295","1","1"}}) {
        pairs = {{9,9}}; CHECK(!TryParseItemAmountPairs(tokens, 0, pairs) && pairs.empty());
    }
    std::vector<std::string> many;
    for (unsigned i=0;i<80;++i) { many.push_back("1"); many.push_back("1"); }
    CHECK(TryParseItemAmountPairs(many, 0, pairs) && pairs.at(0).second == 80);
    many.insert(many.end(), {"1","1"}); CHECK(!TryParseItemAmountPairs(many, 0, pairs));
    CHECK(TryParseItemAmountPairs({"skip","2","3"}, 1, pairs) && pairs.at(0).first == 2);
    WithdrawMode mode = WithdrawMode::All;
    CHECK(ParseWithdrawMode("ONE", mode) && mode == WithdrawMode::One);
    CHECK(ParseWithdrawMode("stack", mode) && mode == WithdrawMode::Stack);
    CHECK(ParseWithdrawMode("all", mode) && mode == WithdrawMode::All);
    CHECK(!ParseWithdrawMode("bogus", mode));
}
static void keys() {
    reset(); Player a, b, c; b.guid.value=101; c.guid.value=102; c.session.account=11;
    uint32 account=999, guid=999;
    GetStorageKeys(&a,account,guid); CHECK(account==0 && guid==100 && GetShareKey(&a)==100);
    GetStorageKeys(&b,account,guid); CHECK(account==0 && guid==101);
    g_shareOwnerByKey[101]=100;
    GetStorageKeys(&b,account,guid); CHECK(account==0 && guid==100);
    GetStorageKeys(&c,account,guid); CHECK(account==0 && guid==102);
    g_shareOwnerByKey.clear(); g_accountWideReagentBank=true;
    GetStorageKeys(&a,account,guid); CHECK(account==10 && guid==0 && GetShareKey(&a)==10);
    GetStorageKeys(&b,account,guid); CHECK(account==10 && guid==0);
    GetStorageKeys(&c,account,guid); CHECK(account==11 && guid==0);
    g_shareOwnerByKey[11]=10;
    GetStorageKeys(&c,account,guid); CHECK(account==10 && guid==0 && GetShareKey(&c)==11);
    g_shareOwnerByKey.erase(11);
    GetStorageKeys(&c,account,guid); CHECK(account==11 && guid==0);
}
static void deltas() {
    reset(); Player player; auto trans=CharacterDatabase.BeginTransaction();
    StoredItem item{3,7,10};
    AppendStoredItemChange(trans,&player,item,10); CHECK(trans->GetSize()==0);
    AppendStoredItemChange(trans,&player,item,4); CHECK(trans->GetSize()==1);
    CHECK((trans->statements[0].args==std::vector<uint32>{0,100,3,7,6,6,7}));
    CHECK(trans->statements[0].sql.find("LEAST(4294967295, amount + {})")!=std::string::npos);
    trans=CharacterDatabase.BeginTransaction(); item.Amount=0;
    AppendStoredItemChange(trans,&player,item,10); CHECK(trans->GetSize()==2);
    CHECK((trans->statements[0].args==std::vector<uint32>{10,10,0,100,3}));
    CHECK(trans->statements[0].sql.find("IF(amount > {}, amount - {}, 0)")!=std::string::npos);
    CHECK(trans->statements[1].sql.find("AND amount = 0")!=std::string::npos);
}
static void withdrawal(uint32 request, uint32 stock, uint32 stack, uint32 capacity, uint32 failAt, uint32 expected, bool stopped, bool missing=false) {
    reset(); objectMgr.proto.stack=stack; objectMgr.missing=missing;
    Player player; player.capacity=capacity; player.failAt=failAt;
    StoredItem stored{1,7,stock}; ItemAmountMap withdrawn; bool full=true;
    auto trans=CharacterDatabase.BeginTransaction();
    uint32 total=WithdrawExact(&player,stored,request,full,withdrawn,trans);
    CHECK(total==expected); CHECK(player.bags==expected); CHECK(stored.Amount==stock-expected);
    CHECK(uint64(player.bags)+stored.Amount==stock); CHECK(SumItemAmountMap(withdrawn)==expected);
    CHECK(player.notified==expected); CHECK(full==stopped);
    CHECK(trans->GetSize()==(expected ? 2u : 0u));
    if (expected) CHECK(trans->statements.at(0).args.at(0)==expected);
    CHECK(CharacterDatabase.commits==0 && player.saves==0);
}
static void deposits() {
    for (unsigned scenario=0; scenario<10; ++scenario) {
        reset(); Player p; p.bags=5;
        std::map<uint32,StoredItem> stored{{1,{1,7,10}}}; ItemAmountMap amounts; bool overflow=false;
        if (scenario==1) p.present=false;
        if (scenario==2) p.item.trade=true;
        if (scenario==3) storable=false;
        if (scenario==4) excluded=true;
        if (scenario==5) quest=true;
        if (scenario==6) p.item.count=0;
        if (scenario==7) stored[1].Amount=UINT32_MAX;
        if (scenario==8) amounts[1]=UINT32_MAX;
        uint32 before=stored[1].Amount;
        uint32 total=DepositFromSlot(&p,0,0,scenario==9?8:7,stored,amounts,overflow);
        CHECK(total==(scenario==0?5u:0u));
        CHECK(p.destroyed==(scenario==0?1u:0u));
        CHECK(p.bags==(scenario==0?0u:5u));
        CHECK(stored[1].Amount==before+(scenario==0?5u:0u));
        CHECK(overflow==(scenario==7 || scenario==8));
        if (scenario==0) CHECK(amounts.at(1)==5);
        if (scenario==8) CHECK(amounts.at(1)==UINT32_MAX);
    }
}
static void commits() {
    reset(); Player player; auto trans=CharacterDatabase.BeginTransaction();
    CommitStoredItemChanges(&player,trans); CHECK(player.saves==0 && CharacterDatabase.commits==0);
    trans->Append("bank",1); CommitStoredItemChanges(&player,trans);
    CHECK(player.saves==1 && CharacterDatabase.commits==1 && CharacterDatabase.last==trans);
    CHECK(trans->statements.at(0).sql=="bank" && trans->statements.at(1).sql=="inventory");
    CharacterDatabase.success=false; CommitStoredItemChanges(&player,trans); CHECK(errors==1);
    // A real promise/future verifies waiting, rather than a fake immediate .get().
    reset(); trans=CharacterDatabase.BeginTransaction(); trans->Append("bank",1);
    CharacterDatabase.pending=std::make_shared<std::promise<bool>>();
    auto task=std::async(std::launch::async,[&] { CommitStoredItemChanges(&player,trans); });
    auto deadline=std::chrono::steady_clock::now()+std::chrono::seconds(2);
    while (CharacterDatabase.commits==0 && std::chrono::steady_clock::now()<deadline) std::this_thread::yield();
    CHECK(CharacterDatabase.commits==1);
    CHECK(task.wait_for(std::chrono::milliseconds(25))==std::future_status::timeout);
    CharacterDatabase.pending->set_value(true);
    CHECK(task.wait_for(std::chrono::seconds(2))==std::future_status::ready); task.get();
    CHECK(errors==0);
    for (auto mode : {WithdrawMode::One,WithdrawMode::Stack,WithdrawMode::All}) {
        reset(); Player p; ItemAmountMap amounts; bool full=true;
        uint32 expected=mode==WithdrawMode::One?1:mode==WithdrawMode::Stack?20:55;
        CHECK(WithdrawItem(&p,1,mode,full,amounts)==expected);
        CHECK(p.bags==expected && !full && SumItemAmountMap(amounts)==expected);
        CHECK(p.saves==1 && CharacterDatabase.commits==1);
        CHECK(CharacterDatabase.last->statements.back().sql=="inventory");
    }
    reset(); loadMissing=true; Player p; ItemAmountMap amounts; bool full=true;
    CHECK(WithdrawItem(&p,1,WithdrawMode::All,full,amounts)==0 && !full && p.saves==0);
    loadMissing=false; objectMgr.missing=true;
    CHECK(WithdrawItem(&p,1,WithdrawMode::All,full,amounts)==0 && p.saves==0);
}
int main() {
    arithmetic(); keys(); deltas(); deposits();
    withdrawal(0,55,20,100,UINT32_MAX,0,false);
    withdrawal(1,55,20,100,UINT32_MAX,1,false);
    withdrawal(20,55,20,100,UINT32_MAX,20,false);
    withdrawal(100,55,20,100,UINT32_MAX,55,false);
    withdrawal(5,0,20,100,UINT32_MAX,0,false);
    withdrawal(5,5,0,100,UINT32_MAX,5,false);
    withdrawal(55,55,20,0,UINT32_MAX,0,true);
    withdrawal(55,55,20,40,UINT32_MAX,40,true);
    withdrawal(55,55,20,100,0,0,true);
    withdrawal(55,55,20,100,1,20,true);
    withdrawal(55,55,20,100,UINT32_MAX,0,false,true);
    commits(); std::cout << checks << " checks passed\n";
}
