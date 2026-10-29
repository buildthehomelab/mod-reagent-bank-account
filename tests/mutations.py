#!/usr/bin/env python3
"""Require representative production mutants to compile and fail assertions."""
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MUTATIONS = [
    ('pair-limit', 'MAX_REAGENT_BANK_ITEM_AMOUNT_PAIRS = 80', 'MAX_REAGENT_BANK_ITEM_AMOUNT_PAIRS = 81'),
    ('unchecked-add', 'if (add > MAX_REAGENT_BANK_STORED_AMOUNT - current)', 'if (add > MAX_REAGENT_BANK_STORED_AMOUNT)'),
    ('accept-zero-item', 'if (!itemEntry || !amount)', 'if (!amount)'),
    ('accept-zero-amount', 'if (!itemEntry || !amount)', 'if (!itemEntry)'),
    ('parse-zero-is-invalid', 'value = uint32(parsed);', 'if (parsed == 0) return false; value = uint32(parsed);'),
    ('split-duplicate-requests', 'pairs.emplace_back(pair.first, pair.second);', 'pairs.emplace_back(pair.first, 1);'),
    ('ignore-share-owner', 'accountKey = it != g_shareOwnerByKey.end() ? it->second : accountId;', 'accountKey = it != g_shareOwnerByKey.end() ? accountId : accountId;'),
    ('absolute-debit', 'uint32 const removed = previousAmount - item.Amount;', 'uint32 const removed = previousAmount;'),
    ('no-zero-cleanup', 'AND item_entry = {} AND amount = 0', 'AND item_entry = {} AND amount = 1'),
    ('save-bags-omitted', 'player->SaveInventoryAndGoldToDB(trans);', 'static_cast<void>(player);'),
    ('commit-not-waited', 'if (!CharacterDatabase.AsyncCommitTransaction(trans).m_future.get())', 'if (CharacterDatabase.AsyncCommitTransaction(trans).m_future.wait_for(std::chrono::seconds(0)) != std::future_status::ready)'),
    ('ignore-commit-failure', 'if (!CharacterDatabase.AsyncCommitTransaction(trans).m_future.get())', 'if (CharacterDatabase.AsyncCommitTransaction(trans).m_future.get())'),
    ('deposit-trade-items', 'if (!item || item->IsInTrade())', 'if (!item)'),
    ('deposit-quest-items', 'IsDepositExcluded(itemEntry) || IsNeededByActiveQuest(player, itemEntry)', 'IsDepositExcluded(itemEntry) && IsNeededByActiveQuest(player, itemEntry)'),
    ('deposit-without-destroying', 'player->DestroyItem(bagSlot, itemSlot, true);', 'static_cast<void>(bagSlot); static_cast<void>(itemSlot);'),
    ('withdraw-no-stock-limit', 'std::min<uint32>(requestedAmount, stored.Amount)', 'requestedAmount'),
    ('withdraw-too-small', 'std::min<uint32>(stackSize, remainingRequest)', 'std::min<uint32>(stackSize, remainingRequest) - 1'),
    ('withdraw-stock-not-debited', 'stored.Amount -= toGive;', 'stored.Amount -= 0;'),
    ('withdraw-creation-failure-ignored', 'if (!item)\n            {\n                stoppedForBagSpace', 'if (false)\n            {\n                stoppedForBagSpace'),
    ('withdraw-bag-failure-flag', 'player->SendEquipError(msg, nullptr, nullptr, stored.ItemEntry);\n                stoppedForBagSpace = true;', 'player->SendEquipError(msg, nullptr, nullptr, stored.ItemEntry);\n                stoppedForBagSpace = false;'),
    ('one-means-stack', 'requested = 1;', 'requested = 20;'),
    ('stack-means-one', 'requested = std::max<uint32>(1, proto->GetMaxStackSize());', 'requested = 1;'),
    ('all-means-one', 'requested = stored.Amount;', 'requested = 1;'),
]


def main():
    source = (ROOT / 'src/ReagentBankAccount.cpp').read_text()
    for name, old, new in MUTATIONS:
        if old not in source:
            raise RuntimeError(f'Missing mutation anchor: {name}')
        with tempfile.TemporaryDirectory(prefix='reagent-mutant-') as tmp:
            path = Path(tmp) / 'ReagentBankAccount.cpp'
            path.write_text(source.replace(old, new, 1))
            env = dict(os.environ, REAGENT_SOURCE=str(path), BUILD_DIR=str(Path(tmp) / 'build'))
            result = subprocess.run(['python3', str(ROOT / 'tests/run.py')], env=env,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=45)
            # Compilation failure and timeout are harness failures, never kills.
            if not (Path(tmp) / 'build/reagent-tests').exists():
                raise RuntimeError(f'{name} did not compile:\n{result.stdout}')
            if result.returncode == 0:
                raise RuntimeError(f'{name} survived:\n{result.stdout}')
            # Only our CHECK output establishes a behavioral rejection.
            if not any(line.partition(':')[0].isdigit() for line in result.stdout.splitlines()):
                raise RuntimeError(f'{name} failed without an assertion:\n{result.stdout}')
            print(f'caught {name}', flush=True)
    print(f'{len(MUTATIONS)}/{len(MUTATIONS)} compiled mutants caught')


if __name__ == '__main__':
    main()
