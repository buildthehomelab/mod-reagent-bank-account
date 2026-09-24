-- ReagentBankUI
-- WotLK 3.3.5a-safe: no Retail APIs. Built from stock Blizzard frame templates.
local ADDON_NAME = ...
if not ADDON_NAME or ADDON_NAME == "" then
    ADDON_NAME = "ReagentBankUI"
end

local RB = CreateFrame("Frame", "ReagentBankUIController")
_G.ReagentBankUI = RB

_G.BINDING_HEADER_REAGENTBANKUI = "Reagent Bank UI"
_G.BINDING_NAME_REAGENTBANKUI_AUTO_DEPOSIT_APPLY = "Periodic auto-deposit: Apply"
_G.BINDING_NAME_REAGENTBANKUI_AUTO_DEPOSIT_OFF = "Periodic auto-deposit: Off"

local COMMAND_PREFIX = ".rbank"

local CATEGORY_ORDER = {
    { id = 5,  name = "Cloth",             sample = 2589  },
    { id = 8,  name = "Meat",              sample = 12208 },
    { id = 7,  name = "Metal & Stone",     sample = 2772  },
    { id = 12, name = "Enchanting",        sample = 10940 },
    { id = 10, name = "Elemental",         sample = 7068  },
    { id = 1,  name = "Parts",             sample = 4359  },
    { id = 11, name = "Other Trade Goods", sample = 2604  },
    { id = 9,  name = "Herb",              sample = 2453  },
    { id = 6,  name = "Leather",           sample = 2318  },
    { id = 4,  name = "Jewelcrafting",     sample = 1206  },
    { id = 2,  name = "Explosives",        sample = 4358  },
    { id = 3,  name = "Devices",           sample = 4388  },
    { id = 13, name = "Nether Material",   sample = 23572 },
    { id = 14, name = "Armor Vellum",      sample = 38682 },
    { id = 15, name = "Weapon Vellum",     sample = 39349 },
}

local CATEGORY_BY_ID = {}
for _, category in ipairs(CATEGORY_ORDER) do
    CATEGORY_BY_ID[category.id] = category
end

-- Stock Blizzard art, so the windows look like the rest of the default UI.
local DIALOG_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

local INSET_BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local ROW_ODD_COLOR = { 1.00, 1.00, 1.00, 0.05 }
local ROW_EVEN_COLOR = { 1.00, 1.00, 1.00, 0.02 }
local ROW_FILL_COLOR = { 1.00, 0.82, 0.00, 0.12 }
local LIST_HEADER_COLOR = { 1.00, 1.00, 1.00, 0.08 }
local DIVIDER_COLOR = { 0.60, 0.60, 0.60, 0.35 }

local DEFAULT_SCALE = 1.00
local MAIN_FRAME_WIDTH = 740
local MAIN_FRAME_HEIGHT = 600
local QUICK_WITHDRAW_WIDTH = 470
local ROW_COUNT = 15
local ROW_HEIGHT = 24
local ROW_SPACING = 2
-- The server's page size is configurable (MaxItemsPerPage, up to 50), so the
-- list scrolls instead of dropping whatever does not fit in ROW_COUNT rows.
local LIST_ROW_INSET = 8
local LIST_SCROLL_ROW_INSET = 30
local REQUEST_TIMEOUT_SECONDS = 8.0
local MUTATION_REFRESH_DELAY = 0.85
local ITEM_CACHE_REFRESH_INTERVAL = 0.35
local ITEM_CACHE_REFRESH_TIMEOUT = 8.0
local AUTO_DEPOSIT_AFTER_CLOSE_DELAY = 0.80
local AUTO_DEPOSIT_PREP_EXPIRE_SECONDS = 300
local AUTO_DEPOSIT_TICKER_DEFAULT_SECONDS = 300
local AUTO_DEPOSIT_TICKER_MIN_SECONDS = 30
local AUTO_DEPOSIT_TICKER_MAX_SECONDS = 3600
local AUTO_DEPOSIT_TICKER_RETRY_DELAY = 10
local TRANSACTION_MAX_PAIRS_PER_COMMAND = 10
local TRANSACTION_CHAT_ITEM_LIMIT = 6
local TRADE_SKILL_PREPARE_COUNT_MIN = 1
local TRADE_SKILL_PREPARE_COUNT_MAX = 999
local DEPOSIT_PREVIEW_ROW_COUNT = 10
local TRADE_SKILL_CHECK_TIMEOUT = 2.0
local TOOLTIP_BANK_CHECK_TIMEOUT = 2.0
local TOOLTIP_BANK_COUNT_CACHE_SECONDS = 60
local TRADE_SKILL_SHOPPING_LIST_LIMIT = 3
local PROFESSION_PREFETCH_PAIRS_PER_COMMAND = 15
local PROFESSION_PREFETCH_SEND_INTERVAL = 0.3
local PROFESSION_PREFETCH_TIMEOUT = 20.0
local REAGENT_OVERLAY_ROW_COUNT = 8
local REAGENT_OVERLAY_FONT_SIZE = 10
local REAGENT_OVERLAY_GAP = 5
-- Reagent rows are not always Blizzard's 296px single column; skins lay them
-- out two-up in cells barely wider than the name itself. Past roughly this
-- share of the column, making room for the badge only pushes the name onto an
-- extra line, so a badge that still will not fit is hidden instead.
local REAGENT_NAME_MAX_RESERVE_RATIO = 0.42
local PROFESSION_PANEL_WIDTH = 232
local PROFESSION_PANEL_PADDING = 16
local PROFESSION_PANEL_X = -33
local PROFESSION_PANEL_Y = -12
local PROFESSION_PANEL_NOTE_TOP = 216
local PROFESSION_PANEL_MIN_HEIGHT = 344
local PROFESSION_PRESET_BUTTON_HEIGHT = 20
local PROFESSION_PRESET_GAP = 6
local PROFESSION_ACTION_BUTTON_WIDTH = 140
local PROFESSION_ACTION_BUTTON_HEIGHT = 22
local PROFESSION_BAG_REFRESH_DELAY = 0.15
local PROFESSION_PRESET_BATCH_COUNT = 100
local PROFESSION_PANEL_MAX_HEIGHT = 500
local PROFESSION_PANEL_ITEM_LIMIT = 3
local SHOPPING_LIST_CHAT_ITEM_LIMIT = 12
local SHOPPING_LIST_IMPORT_TIMEOUT = 10.0
local AUCTION_SHOPPING_ROW_COUNT = 9
local AUCTION_SHOPPING_FRAME_WIDTH = 350
local AUCTION_STEP_BUTTON_SIZE = 18
local AUCTION_SHOPPING_FRAME_HEIGHT = 382
local AUCTION_SHOPPING_FRAME_GAP = 8
-- A bid with no server reply after this long is dropped instead of counted.
local AUCTION_BID_REPLY_TIMEOUT = 20.0
-- Auctionator's Buy tab id and the shopping list the AH list is mirrored into.
local AUCTIONATOR_BUY_TAB = 3
local AUCTIONATOR_LIST_NAME = "Reagent Bank"
-- Width Auctionator 3.x gives the list box on its Shopping Lists options page.
local AUCTIONATOR_OPTIONS_LIST_WIDTH = 180
local LOW_STOCK_DEFAULT_CRAFTS = 5

-- Main window top action button placement.
-- Change these to move/resize Deposit All, Withdraw All, and Refresh.
local ROOT_BUTTON_ROW_X = 18
local ROOT_BUTTON_ROW_Y = -60
-- One width for every button on the top row so it reads as a toolbar instead
-- of a ragged line. Six buttons at 110 plus five 8px gaps exactly fill the
-- 704px between the frame's side margins.
local ROOT_ACTION_BUTTON_WIDTH = 110
local ROOT_REFRESH_BUTTON_WIDTH = 110
local ROOT_SORT_BUTTON_WIDTH = 110
local ROOT_PREVIEW_TOGGLE_BUTTON_WIDTH = 110
local ROOT_SHOPPING_BUTTON_WIDTH = 110
local ROOT_BUTTON_HEIGHT = 24
local ROOT_BUTTON_GAP = 8
local LIST_COUNT_COLUMN_WIDTH = 158
local LIST_COUNT_COLUMN_INSET = 8
local LIST_COLUMN_SPLIT = LIST_COUNT_COLUMN_WIDTH + LIST_COUNT_COLUMN_INSET
local UNDO_BUTTON_WIDTH = 128

-- Category/detail navigation button placement.
-- Change these to move/resize Categories, Deposit Category, Withdraw Category, Prev, and Next.
local CATEGORY_BUTTON_ROW_X = 18
local CATEGORY_BUTTON_ROW_Y = -90
local CATEGORY_BACK_BUTTON_WIDTH = 96
local CATEGORY_ACTION_BUTTON_WIDTH = 148
local CATEGORY_PAGE_BUTTON_WIDTH = 72
local CATEGORY_BUTTON_HEIGHT = 24
local CATEGORY_BUTTON_GAP = 8
local CATEGORY_PAGE_TEXT_GAP = 10
local CATEGORY_PAGE_TEXT_WIDTH = 104
local SHOPPING_RECIPE_BUTTON_WIDTH = 132
local SHOPPING_PRINT_BUTTON_WIDTH = 96
local SHOPPING_CLEAR_BUTTON_WIDTH = 96

-- PaperDoll toggle button placement/style.
-- Uses the same round minimap-style art as the PaperDollAHButton example.
-- Primary position: immediately to the right of PaperDollAHButton.
-- Fallback position is used if PaperDollAHButton is not loaded yet.
local PAPERDOLL_BUTTON_ENABLED = true
local PAPERDOLL_BUTTON_PARENT = "PaperDollFrame"
local PAPERDOLL_ANCHOR_BUTTON_NAME = "PaperDollAHButton"
local PAPERDOLL_BUTTON_GAP = 2

-- Fallback: this matches the AH button's sample position and places this button
-- directly to the right of it: AH TOPRIGHT is -324, -474; this TOPLEFT is -322, -474.
local PAPERDOLL_BUTTON_FALLBACK_POINT = "TOPLEFT"
local PAPERDOLL_BUTTON_FALLBACK_RELATIVE_POINT = "TOPRIGHT"
local PAPERDOLL_BUTTON_FALLBACK_X = -322
local PAPERDOLL_BUTTON_FALLBACK_Y = -474

local PAPERDOLL_BUTTON_SIZE = 32
local PAPERDOLL_BUTTON_ICON = "Interface\\Icons\\INV_Misc_Bag_10"
local PAPERDOLL_BUTTON_ICON_SIZE = 17
local PAPERDOLL_BUTTON_ICON_CROP = 0.08

local PAPERDOLL_BUTTON_BG_TEXTURE = "Interface\\Minimap\\MiniMap-TrackingBackground"
local PAPERDOLL_BUTTON_BG_SIZE = 20
local PAPERDOLL_BUTTON_BG_R = 0.15
local PAPERDOLL_BUTTON_BG_G = 0.15
local PAPERDOLL_BUTTON_BG_B = 0.15
local PAPERDOLL_BUTTON_BG_A = 0.95

local PAPERDOLL_BUTTON_BORDER_TEXTURE = "Interface\\Minimap\\MiniMap-TrackingBorder"
local PAPERDOLL_BUTTON_BORDER_SIZE = 54

local PAPERDOLL_BUTTON_HIGHLIGHT_TEXTURE = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local PAPERDOLL_BUTTON_HIGHLIGHT_SIZE = 52

local PAPERDOLL_LAUNCHER_DOCK_VERSION = 20260518

local function EnsurePaperDollLauncherDock()
    local dock = _G.PaperDollLauncherDock
    if type(dock) ~= "table" then
        dock = {}
        _G.PaperDollLauncherDock = dock
    end

    dock.entries = dock.entries or {}

    if (tonumber(dock.version) or 0) >= PAPERDOLL_LAUNCHER_DOCK_VERSION and dock.Register and dock.Layout then
        return dock
    end

    dock.version = PAPERDOLL_LAUNCHER_DOCK_VERSION
    dock.startPoint = "TOPRIGHT"
    dock.startRelativePoint = "TOPRIGHT"
    dock.startX = -324
    dock.startY = -464
    dock.gap = 2

    function dock:GetParentFrame()
        return _G.PaperDollFrame or _G.CharacterFrame or UIParent
    end

    function dock:InstallHooks()
        self.hookedParents = self.hookedParents or {}

        local candidates = { _G.PaperDollFrame, _G.CharacterFrame }
        for _, parent in ipairs(candidates) do
            if parent and parent.HookScript and not self.hookedParents[parent] then
                parent:HookScript("OnShow", function()
                    if _G.PaperDollLauncherDock and _G.PaperDollLauncherDock.Layout then
                        _G.PaperDollLauncherDock:Layout()
                    end
                end)
                self.hookedParents[parent] = true
            end
        end

        if not self.eventFrame then
            self.eventFrame = CreateFrame("Frame")
            self.eventFrame:RegisterEvent("PLAYER_LOGIN")
            self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
            self.eventFrame:RegisterEvent("ADDON_LOADED")
            self.eventFrame:SetScript("OnEvent", function()
                if _G.PaperDollLauncherDock and _G.PaperDollLauncherDock.Layout then
                    _G.PaperDollLauncherDock:Layout()
                end
            end)
        end
    end

    function dock:Register(id, button, order)
        if not id or not button then
            return
        end

        self.entries = self.entries or {}
        self.entries[id] = self.entries[id] or {}
        self.entries[id].button = button
        self.entries[id].order = tonumber(order) or 1000

        button.PaperDollLauncherDockID = id

        self:InstallHooks()
        self:Layout()
    end

    function dock:Unregister(id)
        if self.entries then
            self.entries[id] = nil
        end

        self:Layout()
    end

    function dock:Layout()
        self:InstallHooks()

        local parent = self:GetParentFrame()
        local buttons = {}

        for id, entry in pairs(self.entries or {}) do
            if entry and entry.button then
                table.insert(buttons, {
                    id = id,
                    button = entry.button,
                    order = tonumber(entry.order) or 1000,
                })
            end
        end

        table.sort(buttons, function(a, b)
            if a.order == b.order then
                return tostring(a.id) < tostring(b.id)
            end

            return a.order < b.order
        end)

        local previousButton = nil

        for _, entry in ipairs(buttons) do
            local button = entry.button

            if button.SetParent and button:GetParent() ~= parent then
                button:SetParent(parent)
            end

            if button.SetMovable then
                button:SetMovable(false)
            end

            if button.SetClampedToScreen then
                button:SetClampedToScreen(false)
            end

            if button.SetFrameLevel and parent and parent.GetFrameLevel then
                button:SetFrameLevel((parent:GetFrameLevel() or 1) + 12)
            end

            button:ClearAllPoints()

            if previousButton then
                button:SetPoint("LEFT", previousButton, "RIGHT", self.gap, 0)
            else
                button:SetPoint(self.startPoint, parent, self.startRelativePoint, self.startX, self.startY)
            end

            button:Show()
            previousButton = button
        end
    end

    dock:InstallHooks()
    return dock
end

local function Trim(text)
    if not text then
        return ""
    end

    text = tostring(text)
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue

    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function SplitColon(text)
    local parts = {}

    for part in string.gmatch(text or "", "([^:]+)") do
        table.insert(parts, part)
    end

    return parts
end

local function FormatCount(value)
    value = tonumber(value) or 0

    if value >= 1000000 then
        return string.format("%.1fm", value / 1000000)
    end

    if value >= 10000 then
        return string.format("%.1fk", value / 1000)
    end

    return tostring(value)
end

-- FormatCount keeps four significant digits below 10k, which is right for the
-- panel lists but too wide for a badge squeezed into a reagent cell. Cap the
-- badge at five characters so it always has room.
local function FormatBadgeCount(value)
    value = math.floor(tonumber(value) or 0)

    if value >= 1000000 then
        return string.format("%dm", math.floor(value / 1000000))
    end

    if value >= 10000 then
        return string.format("%dk", math.floor(value / 1000))
    end

    if value >= 1000 then
        return string.format("%.1fk", value / 1000)
    end

    return tostring(value)
end

local TEXT_GOOD = "7fdc7f"
local TEXT_WARN = "ffb04a"
local TEXT_BAD = "ff6b5e"
local TEXT_DIM = "97a0ae"

local function ColorText(text, color)
    return "|cff" .. (color or TEXT_DIM) .. tostring(text or "") .. "|r"
end

local function GetItemDisplay(itemEntry)
    itemEntry = tonumber(itemEntry)
    if not itemEntry then
        return "Interface\\Icons\\INV_Misc_QuestionMark", "Unknown item", nil, 1, false
    end

    local name, link, quality, itemLevel, minLevel, itemType, itemSubType, stackCount, equipLoc, icon = GetItemInfo(itemEntry)
    local missingInfo = name == nil or link == nil

    if not icon then
        icon = GetItemIcon(itemEntry)
    end

    if not name then
        name = "Item #" .. tostring(itemEntry)
    end

    stackCount = tonumber(stackCount) or 1
    if stackCount < 1 then
        stackCount = 1
    end

    return icon or "Interface\\Icons\\INV_Misc_QuestionMark", name, link, stackCount, missingInfo
end

local function HideTooltip()
    if GameTooltip and GameTooltip:IsShown() then
        GameTooltip:Hide()
    end
end

local function SetTooltipItem(itemEntry)
    itemEntry = tonumber(itemEntry)
    if not itemEntry then
        return
    end

    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    GameTooltip:SetHyperlink("item:" .. tostring(itemEntry) .. ":0:0:0:0:0:0:0")
    GameTooltip:Show()
end

local function ParseItemIdFromLink(link)
    if not link then
        return nil
    end

    local itemId = string.match(link, "item:(%d+):")
    return tonumber(itemId)
end

local BANK_COUNT_TOOLTIP_NAMES = {
    "GameTooltip",
    "ItemRefTooltip",
    "ShoppingTooltip1",
    "ShoppingTooltip2",
}

local function ForEachBankCountTooltip(callback)
    if type(callback) ~= "function" then
        return
    end

    for _, tooltipName in ipairs(BANK_COUNT_TOOLTIP_NAMES) do
        local tooltip = _G[tooltipName]
        if tooltip then
            callback(tooltip)
        end
    end
end

local function AddAmountToMap(map, itemEntry, amount)
    if type(map) ~= "table" then
        return false
    end

    itemEntry = tonumber(itemEntry)
    amount = math.floor(tonumber(amount) or 0)

    if not itemEntry or itemEntry <= 0 or amount <= 0 then
        return false
    end

    itemEntry = math.floor(itemEntry)
    map[itemEntry] = (tonumber(map[itemEntry]) or 0) + amount
    return true
end

local function AmountMapHasItems(map)
    if type(map) ~= "table" then
        return false
    end

    for itemEntry, amount in pairs(map) do
        if tonumber(itemEntry) and (tonumber(amount) or 0) > 0 then
            return true
        end
    end

    return false
end

local function AmountMapTotal(map)
    local total = 0

    if type(map) ~= "table" then
        return total
    end

    for _, amount in pairs(map) do
        total = total + math.max(0, math.floor(tonumber(amount) or 0))
    end

    return total
end

local function BuildSortedItemsFromAmountMap(map)
    local items = {}

    if type(map) ~= "table" then
        return items
    end

    for itemEntry, amount in pairs(map) do
        itemEntry = tonumber(itemEntry)
        amount = math.floor(tonumber(amount) or 0)

        if itemEntry and itemEntry > 0 and amount > 0 then
            table.insert(items, {
                entry = math.floor(itemEntry),
                amount = amount,
            })
        end
    end

    table.sort(items, function(a, b)
        return (tonumber(a.entry) or 0) < (tonumber(b.entry) or 0)
    end)

    return items
end

local function PrintAddon(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99ReagentBankUI|r " .. tostring(message or ""))
    end
end

local function GetItemChatText(itemEntry)
    local icon, name, link = GetItemDisplay(itemEntry)

    if link and link ~= "" then
        return link
    end

    return name or ("Item #" .. tostring(itemEntry or 0))
end

local function BuildItemAmountChatText(itemEntry, amount)
    amount = math.floor(tonumber(amount) or 0)
    return tostring(amount) .. "x " .. GetItemChatText(itemEntry)
end

local function SafeTransactionSource(source)
    source = string.lower(tostring(source or "manual"))

    if source == "profession" or source == "reverse" or source == "manual" or source == "auto" then
        return source
    end

    return "manual"
end

local function SafeTransactionLabel(label)
    label = Trim(label or "")

    if label == "" then
        return nil
    end

    return label
end

local function SafeDate()
    if date then
        return date("%H:%M:%S")
    end

    return "now"
end

local function NormalizeItemSortMode(mode)
    mode = string.lower(tostring(mode or "id"))

    if mode == "name" or mode == "alpha" or mode == "alphabetical" then
        return "name"
    end

    if mode == "amount" or mode == "amount_desc" or mode == "count" or mode == "count_desc" then
        return "amount"
    end

    if mode == "amount_asc" or mode == "count_asc" then
        return "amount_asc"
    end

    return "id"
end

local function NormalizeCategorySortMode(mode)
    mode = string.lower(tostring(mode or "order"))

    if mode == "name" then
        return "name"
    end

    if mode == "amount" or mode == "amount_desc" or mode == "total" then
        return "amount"
    end

    if mode == "types" or mode == "types_desc" then
        return "types"
    end

    return "order"
end

local function ItemSortLabel(mode)
    mode = NormalizeItemSortMode(mode)

    if mode == "name" then
        return "Sort: Name"
    elseif mode == "amount" then
        return "Sort: Most"
    elseif mode == "amount_asc" then
        return "Sort: Least"
    end

    return "Sort: ID"
end

local function CategorySortLabel(mode)
    mode = NormalizeCategorySortMode(mode)

    if mode == "name" then
        return "Sort: Name"
    elseif mode == "amount" then
        return "Sort: Total"
    elseif mode == "types" then
        return "Sort: Types"
    end

    return "Sort: Default"
end

local function CycleItemSortMode(mode)
    mode = NormalizeItemSortMode(mode)

    if mode == "id" then
        return "name"
    elseif mode == "name" then
        return "amount"
    elseif mode == "amount" then
        return "amount_asc"
    end

    return "id"
end

local function CycleCategorySortMode(mode)
    mode = NormalizeCategorySortMode(mode)

    if mode == "order" then
        return "amount"
    elseif mode == "amount" then
        return "types"
    elseif mode == "types" then
        return "name"
    end

    return "order"
end

local function TableValueCount(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do
        count = count + 1
    end
    return count
end

local function SetTextureColor(texture, color, alphaOverride)
    if not texture or type(color) ~= "table" then
        return
    end

    texture:SetVertexColor(color[1] or 1, color[2] or 1, color[3] or 1, alphaOverride or color[4] or 1)
end

function RB:MakeBackdrop(frame, alpha, panel)
    if panel then
        frame:SetBackdrop(INSET_BACKDROP)
        frame:SetBackdropColor(0, 0, 0, alpha or 0.60)
        frame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1.00)
        return
    end

    frame:SetBackdrop(DIALOG_BACKDROP)
end

function RB:StyleListRow(row, index)
    SetTextureColor(row.bg, (index % 2) == 0 and ROW_EVEN_COLOR or ROW_ODD_COLOR)
    SetTextureColor(row.fill, ROW_FILL_COLOR)
    SetTextureColor(row.split, DIVIDER_COLOR)
end

function RB:SetButtonEnabled(button, enabled)
    if not button then
        return
    end

    if enabled then
        button:Enable()
    else
        button:Disable()
    end
end

function RB:Status(text, r, g, b)
    self.lastStatus = text

    if self.frame and self.frame.status then
        self.frame.status:SetText(text or "")
        self.frame.status:SetTextColor(r or 0.70, g or 0.70, b or 0.70)
    end

    if self.auctionShoppingFrame and self.auctionShoppingFrame.status then
        self.auctionShoppingFrame.status:SetText(text or "")
        self.auctionShoppingFrame.status:SetTextColor(r or 0.70, g or 0.70, b or 0.70)
    end
end

function RB:EnsureOnUpdate()
    self:SetScript("OnUpdate", function(frame, elapsed)
        frame:OnUpdate(elapsed)
    end)
end

function RB:BeginBusy(kind, text)
    self.busyKind = kind or "request"
    self.busyText = text or "Working..."
    self.busyStartedAt = GetTime()

    self:Status(self.busyText, 0.82, 0.82, 0.82)
    self:UpdateControls()
    self:EnsureOnUpdate()
end

function RB:ClearBusy(text, r, g, b)
    self.busyKind = nil
    self.busyText = nil
    self.busyStartedAt = nil

    self:UpdateControls()

    if text then
        self:Status(text, r or 0.45, g or 1.00, b or 0.45)
    end
end

function RB:ScheduleRefresh(delay, view, categoryId, page)
    delay = tonumber(delay) or MUTATION_REFRESH_DELAY

    self.pendingRefresh = {
        at = GetTime() + delay,
        view = view or self.currentView or "root",
        categoryId = categoryId or self.currentCategoryId,
        page = page or self.currentPage or 0,
    }

    self:EnsureOnUpdate()
end

function RB:ScheduleCurrentRefresh(delay)
    if self.currentView == "category" or self.currentView == "detail" then
        if self.currentCategoryId then
            self:ScheduleRefresh(delay, "category", self.currentCategoryId, self.currentPage or 0)
            return
        end
    end

    self:ScheduleRefresh(delay, "root", nil, 0)
end

function RB:QueueItemInfoRefresh()
    local now = GetTime()

    if not self.itemInfoRefreshStartedAt then
        self.itemInfoRefreshStartedAt = now
    end

    self.nextItemInfoRefreshAt = now + ITEM_CACHE_REFRESH_INTERVAL
    self:EnsureOnUpdate()
end

function RB:ClearItemInfoRefresh()
    self.itemInfoRefreshStartedAt = nil
    self.nextItemInfoRefreshAt = nil
end

function RB:RefreshItemInfoIfNeeded()
    self.nextItemInfoRefreshAt = nil

    local mainShown = self.frame and self.frame:IsShown()
    local auctionListShown = self.auctionShoppingFrame and self.auctionShoppingFrame:IsShown()

    if not mainShown and not auctionListShown then
        self:ClearItemInfoRefresh()
        return
    end

    if self.itemInfoRefreshStartedAt and GetTime() - self.itemInfoRefreshStartedAt >= ITEM_CACHE_REFRESH_TIMEOUT then
        self:ClearItemInfoRefresh()
        return
    end

    if auctionListShown then
        self:RefreshAuctionShoppingFrame(true)
    end

    if not mainShown then
        return
    end

    if self.depositPreview and self.frame.depositPreview and self.frame.depositPreview:IsShown() then
        self:ShowDepositPreview(self.depositPreview)
        return
    end

    if self.currentView == "category" and self.currentCategoryId then
        self:RenderCategory(true)
        return
    end

    if self.currentView == "detail" and self.detailItem then
        self:ShowDetail(self.detailItem, true)
        return
    end

    if self.currentView == "shopping" then
        self:RenderShoppingList(true)
        return
    end

    self:ClearItemInfoRefresh()
end

function RB:OnUpdate(elapsed)
    local now = GetTime()

    if self.pendingAutoDepositAt and now >= self.pendingAutoDepositAt then
        self.pendingAutoDepositAt = nil
        self:DepositPreparedLeftovers()
    end

    self:RunAutoDepositTicker(now)

    if self.pendingTradeSkillBagRefreshAt and now >= self.pendingTradeSkillBagRefreshAt then
        self.pendingTradeSkillBagRefreshAt = nil
        self:UpdateTradeSkillControls()
    end

    if self.professionPrefetchQueue and #self.professionPrefetchQueue > 0 then
        self:SendNextProfessionPrefetchBatch(now)
    end

    if self.professionPrefetchDeadline and now >= self.professionPrefetchDeadline then
        -- Prefetch stalled; drop it so the per-recipe path takes over.
        self.professionPrefetchDeadline = nil
        self.professionPrefetchQueue = nil
        self.professionPrefetchPending = nil
        self.professionPrefetchOutstanding = 0
        self.professionPrefetchKey = nil
        self.professionPrefetchSkillCount = nil
    end

    if self.pendingRefresh and now >= self.pendingRefresh.at then
        local refresh = self.pendingRefresh
        self.pendingRefresh = nil

        if refresh.view == "category" and refresh.categoryId then
            self:RequestCategory(refresh.categoryId, refresh.page or 0)
        else
            self:RequestRoot()
        end

        return
    end

    if self.nextItemInfoRefreshAt and now >= self.nextItemInfoRefreshAt then
        self:RefreshItemInfoIfNeeded()
    end

    if self.busyStartedAt and now - self.busyStartedAt >= REQUEST_TIMEOUT_SECONDS then
        self:ClearBusy("No server data yet. Press Refresh to try again.", 1.00, 0.82, 0.32)
    end

    if not self.pendingRefresh and not self.busyStartedAt and not self.pendingAutoDepositAt and not self.nextItemInfoRefreshAt and not self.nextAutoDepositTickerAt and not self.professionPrefetchDeadline and not self.pendingTradeSkillBagRefreshAt then
        self:SetScript("OnUpdate", nil)
    end
end

function RB:QueueTransactionContext(action, source, label)
    action = self:NormalizeTransactionAction(action)
    if not action then
        return
    end

    self.pendingTransactionContexts = self.pendingTransactionContexts or {}
    table.insert(self.pendingTransactionContexts, {
        action = action,
        source = SafeTransactionSource(source),
        label = SafeTransactionLabel(label),
        queuedAt = GetTime(),
    })

    while #self.pendingTransactionContexts > 20 do
        table.remove(self.pendingTransactionContexts, 1)
    end
end

function RB:TakeTransactionContext(action)
    action = self:NormalizeTransactionAction(action)
    if not action or not self.pendingTransactionContexts then
        return nil
    end

    local now = GetTime()
    local index = 1
    while index <= #self.pendingTransactionContexts do
        local context = self.pendingTransactionContexts[index]

        if context and context.queuedAt and now - context.queuedAt > 12.0 then
            table.remove(self.pendingTransactionContexts, index)
        elseif context and context.action == action then
            table.remove(self.pendingTransactionContexts, index)
            return context
        else
            index = index + 1
        end
    end

    return nil
end

function RB:SendServerCommand(command, transactionContext)
    command = Trim(command or "")

    if command == "" then
        command = "open"
    end

    if transactionContext then
        self:QueueTransactionContext(
            transactionContext.action,
            transactionContext.source,
            transactionContext.label
        )
    end

    SendChatMessage(COMMAND_PREFIX .. " " .. command, "SAY")
end

function RB:CacheBankItemCount(itemEntry, amount)
    itemEntry = tonumber(itemEntry)
    if not itemEntry or itemEntry <= 0 then
        return
    end

    itemEntry = math.floor(itemEntry)
    amount = math.max(0, math.floor(tonumber(amount) or 0))

    self.bankItemCounts = self.bankItemCounts or {}
    self.bankItemCountUpdatedAt = self.bankItemCountUpdatedAt or {}
    self.bankItemCounts[itemEntry] = amount
    self.bankItemCountUpdatedAt[itemEntry] = GetTime()
end

function RB:GetCachedBankItemCount(itemEntry)
    itemEntry = tonumber(itemEntry)
    if not itemEntry or itemEntry <= 0 or type(self.bankItemCounts) ~= "table" then
        return nil
    end

    itemEntry = math.floor(itemEntry)
    local amount = self.bankItemCounts[itemEntry]
    if amount == nil then
        return nil
    end

    local updatedAt = self.bankItemCountUpdatedAt and self.bankItemCountUpdatedAt[itemEntry] or nil
    if updatedAt and GetTime() - updatedAt > TOOLTIP_BANK_COUNT_CACHE_SECONDS then
        self.bankItemCounts[itemEntry] = nil
        self.bankItemCountUpdatedAt[itemEntry] = nil
        return nil
    end

    return math.max(0, math.floor(tonumber(amount) or 0))
end

function RB:ApplyBankCountTransaction(transaction)
    local action = self:NormalizeTransactionAction(transaction and transaction.action)
    if not action or not transaction.items then
        return
    end

    local direction = action == "deposit" and 1 or -1
    for _, item in ipairs(transaction.items) do
        local itemEntry = tonumber(item.entry)
        local amount = math.floor(tonumber(item.amount) or 0)
        if itemEntry and itemEntry > 0 and amount > 0 then
            local cachedAmount = self:GetCachedBankItemCount(itemEntry)
            if cachedAmount ~= nil then
                self:CacheBankItemCount(itemEntry, cachedAmount + (direction * amount))
            end

            self:AdjustProfessionBankCount(itemEntry, direction * amount)
        end
    end

    -- The per-recipe cache is never invalidated on its own, so a withdraw would keep
    -- showing pre-withdrawal bank counts until a different recipe was selected.
    self.tradeSkillBankCountsKey = nil

    if (TradeSkillFrame and TradeSkillFrame:IsShown()) or self:GetActiveRecipeProvider() then
        self:UpdateTradeSkillControls()
    end
end

function RB:AddBankCountTooltipLine(tooltip, itemEntry, amount)
    if not tooltip then
        return
    end

    itemEntry = tonumber(itemEntry)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if not itemEntry or itemEntry <= 0 or amount <= 0 then
        return
    end

    itemEntry = math.floor(itemEntry)
    if tooltip.ReagentBankUICountItem == itemEntry and tooltip.ReagentBankUICountAmount == amount then
        return
    end

    tooltip:AddDoubleLine("Reagent Bank", FormatCount(amount), 0.20, 1.00, 0.60, 1.00, 1.00, 1.00)
    tooltip.ReagentBankUICountItem = itemEntry
    tooltip.ReagentBankUICountAmount = amount
    tooltip:Show()
end

function RB:ClearBankCountTooltipState(tooltip)
    if not tooltip then
        return
    end

    tooltip.ReagentBankUICountItem = nil
    tooltip.ReagentBankUICountAmount = nil
end

function RB:RequestTooltipBankCount(itemEntry)
    itemEntry = tonumber(itemEntry)
    if not itemEntry or itemEntry <= 0 then
        return
    end

    itemEntry = math.floor(itemEntry)
    local now = GetTime()
    self.tooltipBankCheckPendingByItem = self.tooltipBankCheckPendingByItem or {}
    if self.tooltipBankCheckPendingByItem[itemEntry] and now < self.tooltipBankCheckPendingByItem[itemEntry] then
        return
    end

    self.tooltipBankCheckRequestId = (tonumber(self.tooltipBankCheckRequestId) or 700000000) + 1
    if self.tooltipBankCheckRequestId > 799999999 then
        self.tooltipBankCheckRequestId = 700000001
    end

    local requestId = self.tooltipBankCheckRequestId
    self.pendingTooltipBankChecks = self.pendingTooltipBankChecks or {}
    self.pendingTooltipBankChecks[requestId] = {
        itemEntry = itemEntry,
        createdAt = now,
    }
    self.tooltipBankCheckPendingByItem[itemEntry] = now + TOOLTIP_BANK_CHECK_TIMEOUT

    self:SendServerCommand(self:BuildItemAmountCommand("check recipe " .. tostring(requestId), {
        { entry = itemEntry, amount = 1 },
    }))
end

function RB:RefreshBankCountTooltip(tooltip)
    if not tooltip or not tooltip.GetItem then
        return
    end

    local _, link = tooltip:GetItem()
    local itemEntry = ParseItemIdFromLink(link)
    if not itemEntry then
        return
    end

    local amount = self:GetCachedBankItemCount(itemEntry)
    if amount ~= nil then
        self:AddBankCountTooltipLine(tooltip, itemEntry, amount)
        return
    end

    self:RequestTooltipBankCount(itemEntry)
end

function RB:RefreshOpenBankCountTooltips(itemEntry)
    itemEntry = tonumber(itemEntry)
    if not itemEntry or itemEntry <= 0 then
        return
    end

    itemEntry = math.floor(itemEntry)
    ForEachBankCountTooltip(function(tooltip)
        if tooltip and tooltip:IsShown() and tooltip.GetItem then
            local _, link = tooltip:GetItem()
            if ParseItemIdFromLink(link) == itemEntry then
                self:RefreshBankCountTooltip(tooltip)
            end
        end
    end)
end

function RB:InstallBankCountTooltipHooks()
    if self.bankCountTooltipHooksInstalled then
        return
    end

    self.bankCountTooltipHooksInstalled = true
    ForEachBankCountTooltip(function(tooltip)
        if tooltip and tooltip.HookScript then
            tooltip:HookScript("OnTooltipSetItem", function(selfTooltip)
                RB:RefreshBankCountTooltip(selfTooltip)
            end)
            tooltip:HookScript("OnTooltipCleared", function(selfTooltip)
                RB:ClearBankCountTooltipState(selfTooltip)
            end)
        end
    end)
end

function RB:GetItemSortMode()
    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.sortMode = NormalizeItemSortMode(ReagentBankUIDB.sortMode)
    return ReagentBankUIDB.sortMode
end

function RB:GetCategorySortMode()
    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.categorySortMode = NormalizeCategorySortMode(ReagentBankUIDB.categorySortMode)
    return ReagentBankUIDB.categorySortMode
end

function RB:IsDepositPreviewEnabled()
    ReagentBankUIDB = ReagentBankUIDB or {}

    if ReagentBankUIDB.depositPreviewEnabled == nil then
        ReagentBankUIDB.depositPreviewEnabled = true
    end

    return ReagentBankUIDB.depositPreviewEnabled ~= false
end

function RB:SetDepositPreviewEnabled(enabled, silent)
    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.depositPreviewEnabled = enabled and true or false

    if not ReagentBankUIDB.depositPreviewEnabled then
        self:HideDepositPreview()
    end

    self:UpdatePreviewToggleButton()

    if not silent then
        PrintAddon("deposit preview confirmation " .. (ReagentBankUIDB.depositPreviewEnabled and "enabled." or "disabled."))
        self:Status("Deposit preview confirmation " .. (ReagentBankUIDB.depositPreviewEnabled and "enabled." or "disabled."), 0.82, 0.82, 0.82)
    end
end

function RB:ToggleDepositPreviewEnabled()
    self:SetDepositPreviewEnabled(not self:IsDepositPreviewEnabled())
end

function RB:ClampAutoDepositTickerSeconds(seconds)
    seconds = math.floor(tonumber(seconds) or AUTO_DEPOSIT_TICKER_DEFAULT_SECONDS)

    if seconds <= 0 then
        return 0
    end

    return Clamp(seconds, AUTO_DEPOSIT_TICKER_MIN_SECONDS, AUTO_DEPOSIT_TICKER_MAX_SECONDS)
end

function RB:GetAutoDepositTickerSeconds()
    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.autoDepositTickerSeconds = self:ClampAutoDepositTickerSeconds(ReagentBankUIDB.autoDepositTickerSeconds)
    return ReagentBankUIDB.autoDepositTickerSeconds
end

function RB:IsAutoDepositTickerEnabled()
    return self:GetAutoDepositTickerSeconds() > 0
end

function RB:RestartAutoDepositTicker()
    local seconds = self:GetAutoDepositTickerSeconds()

    if seconds > 0 then
        self.nextAutoDepositTickerAt = GetTime() + seconds
        self:EnsureOnUpdate()
    else
        self.nextAutoDepositTickerAt = nil
        self.autoDepositQuietUntil = nil
        self.autoDepositSuppressViewUntil = nil
    end
end

function RB:SetAutoDepositTickerSeconds(seconds, silent)
    ReagentBankUIDB = ReagentBankUIDB or {}
    seconds = self:ClampAutoDepositTickerSeconds(seconds)
    ReagentBankUIDB.autoDepositTickerSeconds = seconds

    self:RestartAutoDepositTicker()
    self:UpdateAutoDepositTickerControls()

    if not silent then
        if seconds > 0 then
            PrintAddon("periodic auto-deposit enabled every " .. tostring(seconds) .. " second(s).")
            self:Status("Periodic auto-deposit every " .. tostring(seconds) .. " second(s).", 0.82, 0.82, 0.82)
        else
            PrintAddon("periodic auto-deposit disabled.")
            self:Status("Periodic auto-deposit disabled.", 0.82, 0.82, 0.82)
        end
    end
end


function RB:IsProfessionWindowOpen()
    return (TradeSkillFrame and TradeSkillFrame:IsShown()) or self:GetActiveRecipeProvider() ~= nil
end

-- The periodic ticker holds off while a profession window is open so it does not
-- deposit reagents withdrawn for a craft. Closing the window restarts the countdown;
-- if another profession window is still open the ticker simply pauses again.
function RB:ResumeAutoDepositTickerAfterProfession()
    if not self.autoDepositPausedForProfession then
        return
    end

    self.autoDepositPausedForProfession = nil
    self:RestartAutoDepositTicker()
end

function RB:ApplyAutoDepositTickerBox(silent)
    if not self.settingsPanel or not self.settingsPanel.autoDepositIntervalBox then
        return
    end

    local text = Trim(self.settingsPanel.autoDepositIntervalBox:GetText() or "")
    local seconds = tonumber(text) or 0
    self:SetAutoDepositTickerSeconds(seconds, silent)
end

function RB:ApplyAutoDepositTickerBinding()
    if self.settingsPanel and self.settingsPanel:IsShown() and self.settingsPanel.autoDepositIntervalBox then
        self:ApplyAutoDepositTickerBox()
        return
    end

    local seconds = self:GetAutoDepositTickerSeconds()
    if seconds <= 0 then
        seconds = AUTO_DEPOSIT_TICKER_DEFAULT_SECONDS
    end

    self:SetAutoDepositTickerSeconds(seconds)
end

function RB:TurnOffAutoDepositTickerBinding()
    self:SetAutoDepositTickerSeconds(0)
end

function ReagentBankUI_PeriodicAutoDepositApply()
    if _G.ReagentBankUI and _G.ReagentBankUI.ApplyAutoDepositTickerBinding then
        _G.ReagentBankUI:ApplyAutoDepositTickerBinding()
    end
end

function ReagentBankUI_PeriodicAutoDepositOff()
    if _G.ReagentBankUI and _G.ReagentBankUI.TurnOffAutoDepositTickerBinding then
        _G.ReagentBankUI:TurnOffAutoDepositTickerBinding()
    end
end

function RB:UpdateAutoDepositTickerControls()
    local frame = self.settingsPanel
    if not frame then
        return
    end

    local seconds = self:GetAutoDepositTickerSeconds()

    if frame.autoDepositIntervalBox then
        local desiredText = tostring(seconds > 0 and seconds or AUTO_DEPOSIT_TICKER_DEFAULT_SECONDS)
        if frame.autoDepositIntervalBox:GetText() ~= desiredText then
            frame.autoDepositIntervalBox:SetText(desiredText)
        end
    end

    if frame.autoDepositStatus then
        if seconds > 0 then
            frame.autoDepositStatus:SetText("Enabled: Deposit All runs every " .. tostring(seconds) .. " second(s).")
        else
            frame.autoDepositStatus:SetText("Disabled. Apply enables every " .. tostring(AUTO_DEPOSIT_TICKER_DEFAULT_SECONDS) .. " seconds; enter 0 or click Off to keep it off.")
        end
    end
end

function RB:IsAutoDepositQuietActive()
    return self.autoDepositQuietUntil and GetTime() <= self.autoDepositQuietUntil
end

function RB:IsAutoDepositViewSuppressed()
    if not self.autoDepositSuppressViewUntil or GetTime() > self.autoDepositSuppressViewUntil then
        return false
    end
    return true
end

function RB:RunAutoDepositTicker(now)
    local seconds = self:GetAutoDepositTickerSeconds()

    if seconds <= 0 then
        self.nextAutoDepositTickerAt = nil
        return
    end

    if not self.nextAutoDepositTickerAt then
        self.nextAutoDepositTickerAt = now + seconds
        return
    end

    if now < self.nextAutoDepositTickerAt then
        return
    end

    if self:IsProfessionWindowOpen() then
        self.autoDepositPausedForProfession = true
        self.nextAutoDepositTickerAt = now + AUTO_DEPOSIT_TICKER_RETRY_DELAY
        return
    end

    if self.busyKind or self.pendingRefresh or self.pendingAutoDepositAt or self.pendingDepositPreview or self.pendingTransaction then
        self.nextAutoDepositTickerAt = now + AUTO_DEPOSIT_TICKER_RETRY_DELAY
        return
    end

    if UnitAffectingCombat and UnitAffectingCombat("player") then
        self.nextAutoDepositTickerAt = now + AUTO_DEPOSIT_TICKER_RETRY_DELAY
        return
    end

    self.nextAutoDepositTickerAt = now + seconds
    self.autoDepositQuietUntil = now + REQUEST_TIMEOUT_SECONDS
    self.autoDepositSuppressViewUntil = now + REQUEST_TIMEOUT_SECONDS
    self:SendServerCommand("deposit all", { action = "deposit", source = "auto" })

    if self.frame and self.frame:IsShown() then
        self:ScheduleCurrentRefresh(MUTATION_REFRESH_DELAY)
    end
end

function RB:UpdatePreviewToggleButton()
    if not self.frame or not self.frame.previewToggle then
        return
    end

    if self:IsDepositPreviewEnabled() then
        self.frame.previewToggle:SetText("Preview: On")
        self.frame.previewToggle.tooltipText = "Deposit All and Deposit Category will show a confirmation preview first."
    else
        self.frame.previewToggle:SetText("Preview: Off")
        self.frame.previewToggle.tooltipText = "Deposit All and Deposit Category will deposit immediately."
    end
end

function RB:UpdateSortButton()
    if not self.frame or not self.frame.sortMode then
        return
    end

    if self.currentView == "shopping" then
        self.frame.sortMode:SetText("Sort: Name")
        self.frame.sortMode.tooltipText = "AH shopping list items are sorted by item name."
    elseif self.currentView == "root" then
        self.frame.sortMode:SetText(CategorySortLabel(self:GetCategorySortMode()))
        self.frame.sortMode.tooltipText = "Cycle category sorting: default order, total amount, type count, or name."
    else
        self.frame.sortMode:SetText(ItemSortLabel(self:GetItemSortMode()))
        self.frame.sortMode.tooltipText = "Cycle item sorting: item ID, name, most stored, or least stored."
    end
end

function RB:CycleSortMode()
    ReagentBankUIDB = ReagentBankUIDB or {}

    if self.currentView == "root" or not self.currentCategoryId then
        ReagentBankUIDB.categorySortMode = CycleCategorySortMode(ReagentBankUIDB.categorySortMode)
        self:RenderRoot()
        return
    end

    ReagentBankUIDB.sortMode = CycleItemSortMode(ReagentBankUIDB.sortMode)
    self:RequestCategory(self.currentCategoryId, 0)
end

function RB:NormalizeShoppingList()
    ReagentBankUIDB = ReagentBankUIDB or {}

    local source = ReagentBankUIDB.shoppingList
    local normalized = {}

    if type(source) == "table" then
        for itemEntry, amount in pairs(source) do
            itemEntry = tonumber(itemEntry)
            amount = math.floor(tonumber(amount) or 0)

            if itemEntry and itemEntry > 0 and amount > 0 then
                itemEntry = math.floor(itemEntry)
                normalized[itemEntry] = (normalized[itemEntry] or 0) + amount
            end
        end
    end

    ReagentBankUIDB.shoppingList = normalized

    -- Bought counts only mean something while the item is still on the list.
    local bought = {}
    if type(ReagentBankUIDB.shoppingBought) == "table" then
        for itemEntry, amount in pairs(ReagentBankUIDB.shoppingBought) do
            itemEntry = tonumber(itemEntry)
            amount = math.floor(tonumber(amount) or 0)

            if itemEntry and normalized[math.floor(itemEntry)] and amount > 0 then
                bought[math.floor(itemEntry)] = amount
            end
        end
    end
    ReagentBankUIDB.shoppingBought = bought

    return normalized
end

function RB:GetShoppingListMap()
    ReagentBankUIDB = ReagentBankUIDB or {}

    if type(ReagentBankUIDB.shoppingList) ~= "table" then
        ReagentBankUIDB.shoppingList = {}
    end

    return ReagentBankUIDB.shoppingList
end

function RB:GetShoppingBoughtMap()
    ReagentBankUIDB = ReagentBankUIDB or {}

    if type(ReagentBankUIDB.shoppingBought) ~= "table" then
        ReagentBankUIDB.shoppingBought = {}
    end

    return ReagentBankUIDB.shoppingBought
end

function RB:GetShoppingBoughtAmount(itemEntry)
    itemEntry = tonumber(itemEntry)
    if not itemEntry then
        return 0
    end

    return math.floor(tonumber(self:GetShoppingBoughtMap()[math.floor(itemEntry)]) or 0)
end

function RB:GetShoppingBoughtTotal()
    local total = 0

    for _, amount in pairs(self:GetShoppingBoughtMap()) do
        total = total + (tonumber(amount) or 0)
    end

    return total
end

function RB:FormatShoppingBought(itemEntry)
    local bought = self:GetShoppingBoughtAmount(itemEntry)
    if bought > 0 then
        return ColorText("x" .. FormatCount(bought), TEXT_GOOD)
    end

    return ColorText("x0", TEXT_DIM)
end

function RB:RefreshShoppingListViews()
    if self.currentView == "shopping" then
        self:RenderShoppingList(true)
    else
        self:UpdateControls()
    end
    self:RefreshAuctionShoppingFrame(true)
end

function RB:GetShoppingListItems()
    local items = BuildSortedItemsFromAmountMap(self:GetShoppingListMap())

    table.sort(items, function(a, b)
        local _, aName = GetItemDisplay(a.entry)
        local _, bName = GetItemDisplay(b.entry)
        aName = string.lower(tostring(aName or ""))
        bName = string.lower(tostring(bName or ""))

        if aName == bName then
            return (tonumber(a.entry) or 0) < (tonumber(b.entry) or 0)
        end

        return aName < bName
    end)

    return items
end

function RB:GetShoppingListTotals()
    local items = self:GetShoppingListItems()
    local total = 0

    for _, item in ipairs(items) do
        total = total + (tonumber(item.amount) or 0)
    end

    return #items, total
end

function RB:AddShoppingListItem(itemEntry, amount, silent)
    itemEntry = tonumber(itemEntry)
    amount = math.floor(tonumber(amount) or 0)

    if not itemEntry or itemEntry <= 0 then
        if not silent then
            self:Status("Choose a valid item first.", 1.00, 0.82, 0.32)
        end
        return false
    end

    if amount <= 0 then
        if not silent then
            self:Status("Enter an amount for the shopping list.", 1.00, 0.82, 0.32)
        end
        return false
    end

    itemEntry = math.floor(itemEntry)
    local list = self:GetShoppingListMap()
    list[itemEntry] = math.floor((tonumber(list[itemEntry]) or 0) + amount)

    if not silent then
        local _, name, link = GetItemDisplay(itemEntry)
        local message = "Added " .. BuildItemAmountChatText(itemEntry, amount) .. " to the AH shopping list."
        PrintAddon(message)
        self:Status("Added " .. tostring(link or name or ("Item #" .. tostring(itemEntry))) .. " x" .. FormatCount(amount) .. " to AH list.", 0.45, 1.00, 0.45)
    end

    if self.currentView == "shopping" then
        self:RenderShoppingList(true)
    else
        self:UpdateControls()
    end
    if not silent then
        self:RefreshAuctionShoppingFrame(true)
    end

    return true
end

function RB:AddShoppingListRows(rows, sourceLabel)
    local addedTypes = 0
    local addedTotal = 0

    for _, row in ipairs(rows or {}) do
        local itemEntry = tonumber(row.itemEntry or row.entry)
        local amount = math.floor(tonumber(row.amount) or 0)

        if itemEntry and itemEntry > 0 and amount > 0 then
            if self:AddShoppingListItem(itemEntry, amount, true) then
                addedTypes = addedTypes + 1
                addedTotal = addedTotal + amount
            end
        end
    end

    if addedTypes > 0 then
        local label = sourceLabel and (" from " .. sourceLabel) or ""
        PrintAddon("added " .. FormatCount(addedTotal) .. " reagent(s) across " .. tostring(addedTypes) .. " item type(s)" .. label .. " to the AH shopping list.")
        self:Status("Added " .. FormatCount(addedTotal) .. " reagent(s) to the AH shopping list.", 0.45, 1.00, 0.45)
        if self.currentView == "shopping" then
            self:RenderShoppingList(true)
        else
            self:UpdateControls()
        end
        self:RefreshAuctionShoppingFrame(true)
        return true
    end

    return false
end

function RB:RemoveShoppingListItem(itemEntry, silent)
    itemEntry = tonumber(itemEntry)
    if not itemEntry or itemEntry <= 0 then
        return false
    end

    itemEntry = math.floor(itemEntry)
    local list = self:GetShoppingListMap()
    local amount = tonumber(list[itemEntry]) or 0

    if amount <= 0 then
        return false
    end

    list[itemEntry] = nil
    self:GetShoppingBoughtMap()[itemEntry] = nil

    if not silent then
        PrintAddon("removed " .. BuildItemAmountChatText(itemEntry, amount) .. " from the AH shopping list.")
        self:Status("Removed item from AH shopping list.", 0.82, 0.82, 0.82)
    end

    self:RefreshShoppingListViews()

    return true
end

function RB:SetShoppingListItemAmount(itemEntry, amount, silent)
    itemEntry = tonumber(itemEntry)
    amount = math.floor(tonumber(amount) or 0)

    if not itemEntry or itemEntry <= 0 then
        return false
    end

    itemEntry = math.floor(itemEntry)

    if amount <= 0 then
        return self:RemoveShoppingListItem(itemEntry, silent)
    end

    local list = self:GetShoppingListMap()
    list[itemEntry] = amount

    if not silent then
        PrintAddon("set AH shopping list amount: " .. BuildItemAmountChatText(itemEntry, amount) .. ".")
        self:Status("Updated AH shopping list amount.", 0.45, 1.00, 0.45)
    end

    if self.currentView == "shopping" then
        self:RenderShoppingList(true)
    else
        self:UpdateControls()
    end
    self:RefreshAuctionShoppingFrame(true)

    return true
end

-- The AH panel's -/+ buttons: one item per click, or a full stack with
-- Shift. Minus stops at 1 so a stray click cannot drop an item and its bought
-- count; Shift-right-click the row to take it off the list.
function RB:StepShoppingListItem(itemEntry, direction)
    itemEntry = tonumber(itemEntry)
    if not itemEntry or itemEntry <= 0 then
        return false
    end

    itemEntry = math.floor(itemEntry)
    local current = math.floor(tonumber(self:GetShoppingListMap()[itemEntry]) or 0)
    if current <= 0 then
        return false
    end

    local step = 1
    if IsShiftKeyDown and IsShiftKeyDown() then
        local _, _, _, stackCount = GetItemDisplay(itemEntry)
        step = math.max(tonumber(stackCount) or 1, 1)
    end

    if direction < 0 then
        step = -step
    end

    local amount = math.max(current + step, 1)
    if amount == current then
        return false
    end

    self:SetShoppingListItemAmount(itemEntry, amount, true)

    local _, name = GetItemDisplay(itemEntry)
    self:Status(tostring(name) .. ": x" .. FormatCount(amount) .. " left to buy.", 0.45, 1.00, 0.45)
    return true
end

function RB:ClearShoppingList()
    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.shoppingList = {}
    ReagentBankUIDB.shoppingBought = {}
    self:HideShoppingAmountPrompt()

    PrintAddon("AH shopping list cleared.")
    self:Status("AH shopping list cleared.", 0.82, 0.82, 0.82)

    self:RefreshShoppingListViews()
end

-- Called once the server accepts a buyout. Takes the stack off the list and
-- keeps a running bought count until the item is covered.
function RB:RecordShoppingPurchase(itemEntry, count)
    itemEntry = tonumber(itemEntry)
    count = math.floor(tonumber(count) or 0)

    if not itemEntry or itemEntry <= 0 or count <= 0 then
        return false
    end

    itemEntry = math.floor(itemEntry)
    local list = self:GetShoppingListMap()
    local needed = math.floor(tonumber(list[itemEntry]) or 0)

    if needed <= 0 then
        return false
    end

    local boughtMap = self:GetShoppingBoughtMap()
    local bought = math.floor(tonumber(boughtMap[itemEntry]) or 0) + count
    local remaining = needed - count
    local _, name = GetItemDisplay(itemEntry)

    if remaining > 0 then
        list[itemEntry] = remaining
        boughtMap[itemEntry] = bought
        PrintAddon("bought " .. BuildItemAmountChatText(itemEntry, count) .. ": " .. FormatCount(bought) .. " bought, " .. FormatCount(remaining) .. " left on the AH list.")
        self:Status("Bought " .. FormatCount(count) .. "x " .. tostring(name) .. ". " .. FormatCount(remaining) .. " left to buy.", 0.45, 1.00, 0.45)
    else
        list[itemEntry] = nil
        boughtMap[itemEntry] = nil
        local extra = ""
        if remaining < 0 then
            extra = " (" .. FormatCount(-remaining) .. " more than needed)"
        end
        PrintAddon("finished " .. GetItemChatText(itemEntry) .. ": bought " .. FormatCount(bought) .. extra .. ". Removed it from the AH list.")
        self:Status("Finished buying " .. tostring(name) .. ".", 0.45, 1.00, 0.45)
    end

    self:RefreshShoppingListViews()
    return true
end

-- PlaceAuctionBid gets no direct reply, so each bid is queued here and
-- matched to the server's answer: "Bid accepted." or an auction error. The
-- server answers bids in the order they were placed.
function RB:OnPlaceAuctionBid(listType, index, bid)
    local link = GetAuctionItemLink and GetAuctionItemLink(listType, index)
    local _, _, count, _, _, _, _, _, buyoutPrice = GetAuctionItemInfo(listType, index)
    buyoutPrice = tonumber(buyoutPrice) or 0

    self.pendingAuctionBids = self.pendingAuctionBids or {}
    table.insert(self.pendingAuctionBids, {
        itemEntry = ParseItemIdFromLink(link),
        count = tonumber(count) or 0,
        isBuyout = buyoutPrice > 0 and (tonumber(bid) or 0) >= buyoutPrice,
        placedAt = GetTime(),
    })
end

function RB:PopPendingAuctionBid()
    local queue = self.pendingAuctionBids
    if not queue then
        return nil
    end

    local now = GetTime()
    while queue[1] and now - (queue[1].placedAt or 0) > AUCTION_BID_REPLY_TIMEOUT do
        table.remove(queue, 1)
    end

    return table.remove(queue, 1)
end

function RB:HandleAuctionBidAccepted()
    local pending = self:PopPendingAuctionBid()

    -- A plain bid only wins later, if at all, so only buyouts count.
    if pending and pending.isBuyout then
        self:RecordShoppingPurchase(pending.itemEntry, pending.count)
    end
end

function RB:GetShoppingPromptAmount()
    if not self.frame or not self.frame.shoppingPromptBox then
        return 0
    end

    local amount = tonumber(self.frame.shoppingPromptBox:GetText() or "") or 0
    amount = math.floor(amount)

    if amount < 0 then
        amount = 0
    end

    return amount
end

function RB:HideShoppingAmountPrompt()
    self.shoppingPromptItem = nil

    if self.frame and self.frame.shoppingPrompt then
        self.frame.shoppingPrompt:Hide()
    end

    if self.frame and self.frame.shoppingPromptBox then
        self.frame.shoppingPromptBox:SetText("")
        self.frame.shoppingPromptBox:ClearFocus()
    end

    self:UpdateControls()
end

function RB:UpdateShoppingAmountPromptControls()
    if not self.frame or not self.frame.shoppingPrompt then
        return
    end

    local item = self.shoppingPromptItem
    local amount = self:GetShoppingPromptAmount()
    local enabled = self.busyKind == nil and item ~= nil and amount > 0

    if self.frame.shoppingPromptHint then
        if amount <= 0 then
            self.frame.shoppingPromptHint:SetText("Enter a number above 0, or use Remove.")
            self.frame.shoppingPromptHint:SetTextColor(1.00, 0.82, 0.32)
        else
            self.frame.shoppingPromptHint:SetText("This replaces the amount on your AH shopping list.")
            self.frame.shoppingPromptHint:SetTextColor(0.78, 0.82, 0.88)
        end
    end

    self:SetButtonEnabled(self.frame.shoppingPromptUpdate, enabled)
    self:SetButtonEnabled(self.frame.shoppingPromptRemove, self.busyKind == nil and item ~= nil)
    self:SetButtonEnabled(self.frame.shoppingPromptCancel, true)
end

function RB:ShowShoppingAmountPrompt(item)
    if not item or not item.entry then
        return
    end

    self:CreateFrame()
    self:HideWithdrawPrompt()

    local currentAmount = tonumber(item.amount) or 0
    if currentAmount <= 0 then
        self:RenderShoppingList(true)
        return
    end

    self.shoppingPromptItem = {
        entry = math.floor(tonumber(item.entry) or 0),
        amount = math.floor(currentAmount),
    }

    HideTooltip()

    local f = self.frame
    local icon, name, link = GetItemDisplay(item.entry)

    f.shoppingPromptIcon:SetTexture(icon)
    f.shoppingPromptName:SetText(link or name)
    f.shoppingPromptCurrent:SetText("Current list amount: x" .. FormatCount(currentAmount))
    f.shoppingPromptBox:SetText(tostring(math.floor(currentAmount)))
    f.shoppingPromptBox:SetFocus()
    f.shoppingPromptBox:HighlightText()
    f.shoppingPrompt:Show()
    f.shoppingPrompt:SetFrameLevel((f:GetFrameLevel() or 1) + 82)

    self:UpdateShoppingAmountPromptControls()
    self:Status("Edit AH shopping list amount for " .. tostring(name or ("Item #" .. tostring(item.entry))) .. ".", 0.82, 0.82, 0.82)
end

function RB:ApplyShoppingAmountPrompt()
    local item = self.shoppingPromptItem
    if not item or not item.entry then
        self:HideShoppingAmountPrompt()
        return
    end

    local amount = self:GetShoppingPromptAmount()
    if amount <= 0 then
        self:Status("Enter a number above 0, or use Remove.", 1.00, 0.82, 0.32)
        self:UpdateShoppingAmountPromptControls()
        return
    end

    local itemEntry = item.entry
    self:HideShoppingAmountPrompt()
    self:SetShoppingListItemAmount(itemEntry, amount)
end

function RB:RemoveShoppingPromptItem()
    local item = self.shoppingPromptItem
    if not item or not item.entry then
        self:HideShoppingAmountPrompt()
        return
    end

    local itemEntry = item.entry
    self:HideShoppingAmountPrompt()
    self:RemoveShoppingListItem(itemEntry)
end

function RB:GetDetailShoppingAmount()
    if not self.frame or not self.frame.shoppingAmountBox then
        return 0
    end

    local amount = tonumber(self.frame.shoppingAmountBox:GetText() or "") or 0
    amount = math.floor(amount)

    if amount < 0 then
        amount = 0
    end

    return amount
end

function RB:AddDetailItemToShoppingList()
    if not self.detailItem or not self.detailItem.entry then
        self:Status("Choose an item first.", 1.00, 0.82, 0.32)
        return
    end

    local amount = self:GetDetailShoppingAmount()
    if self:AddShoppingListItem(self.detailItem.entry, amount) and self.frame and self.frame.shoppingAmountBox then
        self.frame.shoppingAmountBox:SetText("")
        self.frame.shoppingAmountBox:ClearFocus()
    end
end

local SHOPPING_AMOUNT_POPUP = "REAGENTBANKUI_SHOPPING_AMOUNT"

local function ApplyShoppingAmountPopup(dialog)
    local data = dialog and dialog.data
    local box = dialog and _G[dialog:GetName() .. "EditBox"]
    if not data or not data.entry or not box then
        return
    end

    local amount = tonumber(box:GetText() or "")
    if not amount or amount < 0 then
        RB:Status("Enter a number, or 0 to take the item off the AH list.", 1.00, 0.82, 0.32)
        return
    end

    amount = math.floor(amount)
    if data.current > 0 then
        RB:SetShoppingListItemAmount(data.entry, amount)
    else
        RB:AddShoppingListItem(data.entry, amount)
    end
end

StaticPopupDialogs[SHOPPING_AMOUNT_POPUP] = {
    text = "AH shopping list: %s\n%s",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    maxLetters = 6,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
        ApplyShoppingAmountPopup(self)
    end,
    EditBoxOnEnterPressed = function(self)
        local dialog = self:GetParent()
        ApplyShoppingAmountPopup(dialog)
        dialog:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
}

-- Asks how many of an item to buy. Items already on the list start at their
-- current amount, new ones at a full stack.
function RB:ShowShoppingAmountPopup(itemEntry)
    itemEntry = tonumber(itemEntry)
    if not itemEntry or itemEntry <= 0 then
        return false
    end

    itemEntry = math.floor(itemEntry)
    local current = math.floor(tonumber(self:GetShoppingListMap()[itemEntry]) or 0)
    local _, _, _, stackCount = GetItemDisplay(itemEntry)
    local hint

    if current > 0 then
        hint = "On the list: x" .. FormatCount(current) .. ". Enter the new amount, or 0 to remove it."
    else
        hint = "How many do you want to buy?"
    end

    local dialog = StaticPopup_Show(SHOPPING_AMOUNT_POPUP, GetItemChatText(itemEntry), hint)
    if not dialog then
        return false
    end

    dialog.data = {
        entry = itemEntry,
        current = current,
    }

    local box = _G[dialog:GetName() .. "EditBox"]
    if box then
        box:SetText(tostring(current > 0 and current or stackCount))
        box:SetFocus()
        box:HighlightText()
    end

    return true
end

-- An item dropped from the bags onto the AH list goes to the amount popup
-- and back into the bag it came from.
function RB:AddCursorItemToShoppingList()
    if not GetCursorInfo then
        return false
    end

    local kind, itemId, link = GetCursorInfo()
    if kind ~= "item" then
        return false
    end

    ClearCursor()
    return self:ShowShoppingAmountPopup(tonumber(itemId) or ParseItemIdFromLink(link))
end

function RB:ImportSelectedRecipeToShoppingList()
    local reagents, errText, recipeName, repeatCount = self:GetSelectedTradeSkillReagents()

    if errText then
        PrintAddon(errText)
        self:Status(errText, 1.00, 0.82, 0.32)
        return false
    end

    if not reagents or #reagents == 0 then
        local message = "No reagent shopping list needed for the selected recipe."
        PrintAddon(message)
        self:Status(message, 0.45, 1.00, 0.45)
        return true
    end

    repeatCount = self:ClampTradeSkillPrepareCount(repeatCount or 1)
    local plan = self:BuildTradeSkillShoppingPlan(reagents, repeatCount, self:GetLowStockCraftCount())

    if not plan.bankReady then
        self.pendingShoppingListImport = {
            key = self:BuildTradeSkillReagentKey(reagents),
            reagents = reagents,
            recipeName = recipeName,
            repeatCount = repeatCount,
            createdAt = GetTime(),
        }

        local message = "Checking reagent bank stock. Missing AH reagents will be added when the check finishes."
        PrintAddon(message)
        self:Status(message, 1.00, 0.82, 0.32)
        self:UpdateTradeSkillControls()
        return false
    end

    if not plan.missing or #plan.missing == 0 then
        local message = "Bags and bank already cover the selected recipe."
        PrintAddon(message)
        self:Status(message, 0.45, 1.00, 0.45)
        return true
    end

    return self:AddShoppingListRows(plan.missing, tostring(repeatCount) .. " craft(s) of " .. tostring(recipeName or "selected recipe"))
end

function RB:CompletePendingShoppingListImport(completedKey)
    local pending = self.pendingShoppingListImport
    if not pending then
        return false
    end

    if pending.createdAt and GetTime() - pending.createdAt > SHOPPING_LIST_IMPORT_TIMEOUT then
        self.pendingShoppingListImport = nil
        return false
    end

    if completedKey and pending.key and completedKey ~= pending.key then
        return false
    end

    local plan = self:BuildTradeSkillShoppingPlan(pending.reagents, pending.repeatCount, self:GetLowStockCraftCount())
    if not plan.bankReady then
        return false
    end

    self.pendingShoppingListImport = nil

    if not plan.missing or #plan.missing == 0 then
        local message = "Bags and bank already cover " .. tostring(pending.recipeName or "the selected recipe") .. "."
        PrintAddon(message)
        self:Status(message, 0.45, 1.00, 0.45)
        return true
    end

    return self:AddShoppingListRows(plan.missing, tostring(pending.repeatCount or 1) .. " craft(s) of " .. tostring(pending.recipeName or "selected recipe"))
end

function RB:PrintShoppingList()
    local items = self:GetShoppingListItems()

    if not items or #items == 0 then
        PrintAddon("AH shopping list is empty.")
        self:Status("AH shopping list is empty.", 0.82, 0.82, 0.82)
        return false
    end

    local total = 0
    for _, item in ipairs(items) do
        total = total + (tonumber(item.amount) or 0)
    end

    PrintAddon("AH shopping list: " .. FormatCount(total) .. " reagent(s) across " .. tostring(#items) .. " item type(s).")
    PrintAddon("buy: " .. self:FormatTradeSkillPlanItems(items, SHOPPING_LIST_CHAT_ITEM_LIMIT))
    self:Status("Printed AH shopping list to chat.", 0.45, 1.00, 0.45)
    return true
end

function RB:SearchAuctionHouseForItem(itemEntry)
    itemEntry = tonumber(itemEntry)
    if not itemEntry or itemEntry <= 0 then
        self:Status("Choose an item to search for.", 1.00, 0.82, 0.32)
        return false
    end

    local _, name = GetItemDisplay(itemEntry)
    name = Trim(name or "")

    if name == "" or string.match(name, "^Item #") then
        self:Status("Item info is still loading. Try again in a moment.", 1.00, 0.82, 0.32)
        self:QueueItemInfoRefresh()
        return false
    end

    if not AuctionFrame or not AuctionFrame:IsShown() then
        self:Status("Open the Auction House, then click an AH list row to search.", 1.00, 0.82, 0.32)
        return false
    end

    if self:SearchAuctionatorForItem(name) then
        self:Status("Searching Auctionator for " .. name .. ".", 0.45, 1.00, 0.45)
        return true
    end

    if AuctionFrameTab1 and AuctionFrameTab1.Click then
        AuctionFrameTab1:Click()
    end

    if AuctionFrameBrowse then
        AuctionFrameBrowse:Show()
    end

    if BrowseName and BrowseName.SetText then
        BrowseName:SetText(name)
        BrowseName:SetFocus()
        BrowseName:HighlightText()
    else
        self:Status("Auction House search box was not found.", 1.00, 0.82, 0.32)
        return false
    end

    if BrowseSearchButton and BrowseSearchButton.Click and BrowseSearchButton:IsEnabled() then
        BrowseSearchButton:Click()
        self:Status("Searching Auction House for " .. name .. ".", 0.45, 1.00, 0.45)
        return true
    end

    if QueryAuctionItems then
        QueryAuctionItems(name, nil, nil, 0, 0, 0, 0, 0, 0)
        self:Status("Searching Auction House for " .. name .. ".", 0.45, 1.00, 0.45)
        return true
    end

    self:Status("Auction House search is not ready yet.", 1.00, 0.82, 0.32)
    return false
end

-- Runs the search on Auctionator's Buy tab when Auctionator is loaded, so the
-- results land where its Buy button can pick them up.
function RB:SearchAuctionatorForItem(name)
    if type(Atr_SelectPane) ~= "function" or type(Atr_FindTabIndex) ~= "function"
        or type(Atr_Search_Onclick) ~= "function" or not Atr_Search_Box then
        return false
    end

    local ok = pcall(function()
        if (tonumber(Atr_FindTabIndex(AUCTIONATOR_BUY_TAB)) or 0) <= 0 then
            error("Auctionator Buy tab is not set up")
        end

        Atr_SelectPane(AUCTIONATOR_BUY_TAB)
        Atr_Search_Box:SetText(name)
        Atr_Search_Onclick()
    end)

    return ok
end

-- Auctionator 3.x's Shopping Lists options page anchors its list box to
-- TOPLEFT and BOTTOM. On 3.3.5 that pair overrides the box's width and
-- stretches it across the page, and its rows stretch with it over the Delete,
-- Edit and Rename buttons, taking their clicks. The Edit window it opens is
-- also fixed in place with no close button. Older Auctionators have neither
-- frame, so this does nothing there.
function RB:FixAuctionatorShoppingListOptions()
    local panel = _G.Atr_ShpList_Options_Frame
    local scroll = _G.Atr_ShpList_ScrollFrame
    if panel and scroll and not self.auctionatorListBoxFixed then
        self.auctionatorListBoxFixed = true
        scroll:ClearAllPoints()
        scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -95)
        scroll:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 20, 30)
        scroll:SetWidth(AUCTIONATOR_OPTIONS_LIST_WIDTH)
    end

    -- The buildthehomelab Auctionator already makes this window movable with a
    -- close button; adding a second one would stack two on top of each other.
    local editFrame = _G.Atr_ShpList_Edit_Frame
    if editFrame and editFrame:IsMovable() then
        self.auctionatorEditFrameFixed = true
    end
    if editFrame and not self.auctionatorEditFrameFixed then
        self.auctionatorEditFrameFixed = true
        editFrame:SetMovable(true)
        editFrame:SetClampedToScreen(true)
        editFrame:RegisterForDrag("LeftButton")
        editFrame:SetScript("OnDragStart", function(selfFrame)
            selfFrame:StartMoving()
        end)
        editFrame:SetScript("OnDragStop", function(selfFrame)
            selfFrame:StopMovingOrSizing()
        end)

        local close = self:CreateCloseButton(editFrame)
        close:SetPoint("TOPRIGHT", -6, -6)
        close:SetScript("OnClick", function()
            editFrame:Hide()
        end)
    end
end

-- Keeps an Auctionator shopping list named "Reagent Bank" in step with the AH
-- list, so the same items can be searched from Auctionator's own list panel.
function RB:SyncAuctionatorShoppingList()
    local lists = _G.AUCTIONATOR_SHOPPING_LISTS

    -- lists[1] is Auctionator's Recent Searches list. Until Auctionator has
    -- given it the Atr_SList methods, its lists are not set up yet and must
    -- be left alone.
    if type(lists) ~= "table" or type(Atr_SList) ~= "table"
        or type(lists[1]) ~= "table" or getmetatable(lists[1]) ~= Atr_SList then
        return
    end

    local slist
    for _, candidate in ipairs(lists) do
        if type(candidate) == "table" and candidate.name == AUCTIONATOR_LIST_NAME then
            slist = candidate
            break
        end
    end

    local items = self:GetShoppingListItems()

    if not slist then
        if #items == 0 then
            return
        end

        slist = setmetatable({ name = AUCTIONATOR_LIST_NAME, items = {} }, Atr_SList)
        table.insert(lists, slist)
        if type(Atr_SortSlists) == "function" then
            table.sort(lists, Atr_SortSlists)
        end
    end

    local names = {}
    for _, item in ipairs(items) do
        local _, name, _, _, missingInfo = GetItemDisplay(item.entry)
        if not missingInfo then
            table.insert(names, name)
        end
    end

    slist.items = names
    slist.isSorted = false

    if type(Atr_GetCurrentPane) == "function" and Atr_GetCurrentPane() and type(Atr_SetUINeedsUpdate) == "function" then
        Atr_SetUINeedsUpdate()
    end
end

function RB:PositionAuctionShoppingFrame()
    local frame = self.auctionShoppingFrame
    if not frame then
        return
    end

    local parent = _G.AuctionFrame or UIParent
    if frame:GetParent() ~= parent then
        frame:SetParent(parent)
    end

    frame:ClearAllPoints()
    if parent and parent ~= UIParent then
        frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", AUCTION_SHOPPING_FRAME_GAP, 0)
        if frame.SetFrameLevel and parent.GetFrameLevel then
            frame:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
        end
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

function RB:CreateAuctionShoppingFrame()
    if self.auctionShoppingFrame then
        return
    end

    local parent = _G.AuctionFrame or UIParent
    local frame = CreateFrame("Frame", "ReagentBankUIAuctionShoppingFrame", parent)
    frame:SetWidth(AUCTION_SHOPPING_FRAME_WIDTH)
    frame:SetHeight(AUCTION_SHOPPING_FRAME_HEIGHT)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetFrameStrata("DIALOG")
    -- Dragging only lasts until the Auction House closes;
    -- ShowAuctionShoppingFrame docks it beside the frame on the next open.
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(selfFrame)
        selfFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
    end)
    frame:SetScript("OnReceiveDrag", function()
        RB:AddCursorItemToShoppingList()
    end)
    frame:SetScript("OnMouseUp", function()
        RB:AddCursorItemToShoppingList()
    end)
    self:MakeBackdrop(frame)
    frame:Hide()

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", 16, -16)
    frame.title:SetPoint("RIGHT", -40, 0)
    frame.title:SetJustifyH("LEFT")
    frame.title:SetText("AH Shopping List")
    frame.title:SetTextColor(1.00, 0.82, 0.28)

    frame.close = self:CreateCloseButton(frame)
    frame.close:SetPoint("TOPRIGHT", -4, -4)
    frame.close:SetScript("OnClick", function()
        RB:HideAuctionShoppingFrame(true)
    end)

    frame.summary = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.summary:SetPoint("TOPLEFT", 16, -40)
    frame.summary:SetPoint("RIGHT", -16, 0)
    frame.summary:SetJustifyH("LEFT")
    frame.summary:SetTextColor(0.78, 0.82, 0.88)
    frame.summary:SetText("")

    frame.header = CreateFrame("Frame", nil, frame)
    frame.header:SetHeight(22)
    frame.header:SetPoint("TOPLEFT", 14, -62)
    frame.header:SetPoint("RIGHT", -14, 0)

    frame.header.bg = frame.header:CreateTexture(nil, "BACKGROUND")
    frame.header.bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    frame.header.bg:SetAllPoints(frame.header)
    SetTextureColor(frame.header.bg, LIST_HEADER_COLOR)

    frame.headerName = frame.header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.headerName:SetPoint("LEFT", 30, 0)
    frame.headerName:SetJustifyH("LEFT")
    frame.headerName:SetText("Item")

    frame.headerCount = frame.header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.headerCount:SetWidth(82)
    frame.headerCount:SetPoint("RIGHT", -7, 0)
    frame.headerCount:SetJustifyH("RIGHT")
    frame.headerCount:SetText("Left / Bought")

    frame.rows = {}
    for index = 1, AUCTION_SHOPPING_ROW_COUNT do
        local row = CreateFrame("Button", nil, frame, "ReagentBankUIListRowTemplate")
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("LEFT", 14, 0)
        row:SetPoint("RIGHT", -14, 0)

        if index == 1 then
            row:SetPoint("TOP", frame.header, "BOTTOM", 0, -2)
        else
            row:SetPoint("TOP", frame.rows[index - 1], "BOTTOM", 0, -ROW_SPACING)
        end

        if row.fill then
            row.fill:SetHeight(ROW_HEIGHT)
            row.fill:SetWidth(1)
            row.fill:Hide()
        end

        if row.hover then
            row:SetHighlightTexture(row.hover)
        end

        row.plus = self:CreateStepButton(row, "Plus", 1)
        row.plus:SetPoint("RIGHT", -93, 0)
        row.minus = self:CreateStepButton(row, "Minus", -1)
        row.minus:SetPoint("RIGHT", row.plus, "LEFT", -2, 0)

        if row.text then
            row.text:ClearAllPoints()
            row.text:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
            row.text:SetPoint("RIGHT", row.minus, "LEFT", -4, 0)
        end

        if row.count then
            row.count:SetWidth(82)
            row.count:ClearAllPoints()
            row.count:SetPoint("RIGHT", -7, 0)
        end

        row.split = row:CreateTexture(nil, "ARTWORK")
        row.split:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        row.split:SetWidth(1)
        row.split:SetPoint("TOP", row, "TOPRIGHT", -89, -3)
        row.split:SetPoint("BOTTOM", row, "BOTTOMRIGHT", -89, 3)

        self:StyleListRow(row, index)

        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function(selfRow, mouseButton)
            if RB:AddCursorItemToShoppingList() then
                return
            end

            if not selfRow.item or not selfRow.item.entry then
                return
            end

            if mouseButton == "RightButton" then
                if IsShiftKeyDown and IsShiftKeyDown() then
                    RB:RemoveShoppingListItem(selfRow.item.entry)
                else
                    RB:ShowShoppingAmountPopup(selfRow.item.entry)
                end
            else
                RB:SearchAuctionHouseForItem(selfRow.item.entry)
            end
        end)
        row:SetScript("OnReceiveDrag", function()
            RB:AddCursorItemToShoppingList()
        end)
        row:SetScript("OnEnter", function(selfRow)
            if selfRow.item and selfRow.item.entry then
                SetTooltipItem(selfRow.item.entry)
            end
        end)
        row:SetScript("OnLeave", HideTooltip)

        frame.rows[index] = row
    end

    frame.prev = self:CreateButton(frame, 70, 22, "Prev")
    frame.prev:SetPoint("BOTTOMLEFT", 16, 36)
    frame.prev:SetScript("OnClick", function()
        local page = tonumber(frame.page) or 0
        if page > 0 then
            frame.page = page - 1
            RB:RefreshAuctionShoppingFrame(true)
        end
    end)

    frame.next = self:CreateButton(frame, 70, 22, "Next")
    frame.next:SetPoint("LEFT", frame.prev, "RIGHT", 8, 0)
    frame.next:SetScript("OnClick", function()
        local page = tonumber(frame.page) or 0
        local totalPages = math.max(tonumber(frame.totalPages) or 1, 1)
        if page + 1 < totalPages then
            frame.page = page + 1
            RB:RefreshAuctionShoppingFrame(true)
        end
    end)

    frame.clear = self:CreateButton(frame, 70, 22, "Clear")
    frame.clear:SetPoint("BOTTOMRIGHT", -16, 36)
    frame.clear:SetScript("OnClick", function()
        RB:ClearShoppingList()
    end)

    frame.pageText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.pageText:SetPoint("LEFT", frame.next, "RIGHT", 8, 0)
    frame.pageText:SetPoint("RIGHT", frame.clear, "LEFT", -8, 0)
    frame.pageText:SetJustifyH("RIGHT")
    frame.pageText:SetText("")

    frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.status:SetPoint("BOTTOMLEFT", 16, 18)
    frame.status:SetPoint("RIGHT", -16, 0)
    frame.status:SetJustifyH("LEFT")
    frame.status:SetText("")

    self.auctionShoppingFrame = frame
    self:PositionAuctionShoppingFrame()
end

function RB:UpdateAuctionShoppingControls()
    local frame = self.auctionShoppingFrame
    if not frame then
        return
    end

    local page = tonumber(frame.page) or 0
    local totalPages = math.max(tonumber(frame.totalPages) or 1, 1)
    local shoppingTypes = self:GetShoppingListTotals()
    self:SetButtonEnabled(frame.prev, page > 0)
    self:SetButtonEnabled(frame.next, page + 1 < totalPages)
    self:SetButtonEnabled(frame.clear, shoppingTypes > 0)
end

function RB:ClearAuctionShoppingRows()
    local frame = self.auctionShoppingFrame
    if not frame or not frame.rows then
        return
    end

    for _, row in ipairs(frame.rows) do
        row.item = nil
        row.plus:Hide()
        row.minus:Hide()
        if row.fill then
            row.fill:SetWidth(1)
            row.fill:Hide()
        end
        row.icon:Show()
        row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        row.text:SetText("")
        row.count:SetText("")
        row:Hide()
    end
end

function RB:SetAuctionShoppingEmptyRow(text)
    local frame = self.auctionShoppingFrame
    if not frame or not frame.rows or not frame.rows[1] then
        return
    end

    local row = frame.rows[1]
    row.item = nil
    if row.fill then
        row.fill:SetWidth(1)
        row.fill:Hide()
    end
    row.icon:Show()
    row.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
    row.text:SetText(text or "AH shopping list is empty.")
    row.count:SetText("")
    row:Show()
end

function RB:RefreshAuctionShoppingFrame(preservePage)
    self:NormalizeShoppingList()
    self:SyncAuctionatorShoppingList()

    local frame = self.auctionShoppingFrame
    if not frame then
        return
    end

    local items = self:GetShoppingListItems()
    local total = 0
    local maxAmount = 0
    for _, item in ipairs(items) do
        local amount = tonumber(item.amount) or 0
        total = total + amount
        if amount > maxAmount then
            maxAmount = amount
        end
    end

    local totalPages = math.max(math.ceil(#items / AUCTION_SHOPPING_ROW_COUNT), 1)
    local page = preservePage and (tonumber(frame.page) or 0) or 0
    if page < 0 then
        page = 0
    elseif page >= totalPages then
        page = totalPages - 1
    end

    frame.page = page
    frame.totalPages = totalPages
    local summary = FormatCount(total) .. " reagent(s) across " .. tostring(#items) .. " item type(s)"
    local boughtTotal = self:GetShoppingBoughtTotal()
    if boughtTotal > 0 then
        summary = summary .. ", " .. FormatCount(boughtTotal) .. " bought"
    end
    frame.summary:SetText(summary)
    frame.pageText:SetText("Page " .. tostring(page + 1) .. "/" .. tostring(totalPages))

    self:ClearAuctionShoppingRows()

    local missingItemInfo = false
    local startIndex = (page * AUCTION_SHOPPING_ROW_COUNT) + 1

    for rowIndex = 1, AUCTION_SHOPPING_ROW_COUNT do
        local item = items[startIndex + rowIndex - 1]
        local row = frame.rows[rowIndex]
        if row and item then
            local icon, name, link, stackCount, missingInfo = GetItemDisplay(item.entry)
            if missingInfo then
                missingItemInfo = true
            end

            row.item = item
            row.icon:SetTexture(icon)
            row.text:SetText(link or name)
            row.count:SetText("x" .. FormatCount(item.amount) .. " / " .. self:FormatShoppingBought(item.entry))
            self:SetRowFill(row, item.amount, maxAmount)
            row.plus:Show()
            row.minus:Show()
            row.minus:SetAlpha((tonumber(item.amount) or 0) > 1 and 1 or 0.4)
            row:Show()
        end
    end

    if #items == 0 then
        self:SetAuctionShoppingEmptyRow("AH shopping list is empty.")
        missingItemInfo = false
    end

    if missingItemInfo then
        self:QueueItemInfoRefresh()
    elseif not (self.frame and self.frame:IsShown()) then
        self:ClearItemInfoRefresh()
    end

    self:UpdateAuctionShoppingControls()
end

function RB:ShowAuctionShoppingFrame()
    if self.auctionShoppingFrameDismissed then
        return
    end

    self:CreateAuctionShoppingFrame()
    self:PositionAuctionShoppingFrame()
    self:RefreshAuctionShoppingFrame()
    self.auctionShoppingFrame:Show()
    self:Status("Click to search. -/+ adjust (Shift: a stack). Ctrl+Shift-click any item to add it.", 0.82, 0.82, 0.82)
end

function RB:HideAuctionShoppingFrame(dismissed)
    if dismissed then
        self.auctionShoppingFrameDismissed = true
    end

    if self.auctionShoppingFrame then
        self.auctionShoppingFrame:Hide()
    end
end

function RB:ShowShoppingList()
    self:CreateFrame()
    self.frame:Show()
    self:RenderShoppingList()
end

function RB:HandleShoppingListSlash(value)
    value = Trim(value or "")

    local subCommand, rest = string.match(value, "^(%S+)%s*(.-)$")
    subCommand = string.lower(subCommand or "")
    rest = Trim(rest or "")

    if subCommand == "" or subCommand == "show" or subCommand == "open" or subCommand == "list" then
        self:ShowShoppingList()
        return
    end

    if tonumber(subCommand) and rest == "" then
        self:SetTradeSkillPrepareCount(tonumber(subCommand), true)
        self:PrintTradeSkillShoppingList()
        self:UpdateTradeSkillControls()
        return
    end

    if subCommand == "plan" then
        local count = tonumber(rest)
        if count then
            self:SetTradeSkillPrepareCount(count, true)
        end
        self:PrintTradeSkillShoppingList()
        self:UpdateTradeSkillControls()
        return
    end

    if subCommand == "recipe" or subCommand == "import" or subCommand == "fromrecipe" then
        self:ImportSelectedRecipeToShoppingList()
        return
    end

    if subCommand == "print" then
        self:PrintShoppingList()
        return
    end

    if subCommand == "clear" or subCommand == "reset" then
        self:ClearShoppingList()
        return
    end

    if subCommand == "remove" or subCommand == "delete" then
        local itemEntry = ParseItemIdFromLink(rest) or tonumber(string.match(rest, "^(%d+)"))
        if not self:RemoveShoppingListItem(itemEntry) then
            PrintAddon("usage: /rbank ahlist remove itemId")
        end
        return
    end

    if subCommand == "add" then
        local itemEntry = ParseItemIdFromLink(rest) or tonumber(string.match(rest, "^(%d+)"))
        local amount = tonumber(string.match(rest, "%s(%d+)%s*$")) or 1
        if not self:AddShoppingListItem(itemEntry, amount) then
            PrintAddon("usage: /rbank ahlist add itemId amount")
        end
        return
    end

    if tonumber(subCommand) and rest ~= "" then
        self:AddShoppingListItem(tonumber(subCommand), tonumber(rest) or 1)
        return
    end

    local directItemEntry = ParseItemIdFromLink(value)
    if directItemEntry then
        local amount = tonumber(string.match(value, "%s(%d+)%s*$")) or 1
        self:AddShoppingListItem(directItemEntry, amount)
        return
    end

    PrintAddon("shopping list commands: /rbank ahlist, /rbank ahlist recipe, /rbank ahlist add itemId amount, /rbank ahlist print, /rbank ahlist clear")
end

function RB:BuildItemAmountCommands(prefix, items, maxPairs)
    local commands = {}
    local current = prefix
    local pairsInCurrent = 0
    maxPairs = math.max(1, tonumber(maxPairs) or TRANSACTION_MAX_PAIRS_PER_COMMAND)

    for _, item in ipairs(items or {}) do
        local itemEntry = tonumber(item.itemEntry or item.entry)
        local amount = tonumber(item.amount) or 0

        if itemEntry and itemEntry > 0 and amount > 0 then
            if pairsInCurrent >= maxPairs then
                table.insert(commands, current)
                current = prefix
                pairsInCurrent = 0
            end

            current = current .. " " .. tostring(math.floor(itemEntry)) .. " " .. tostring(math.floor(amount))
            pairsInCurrent = pairsInCurrent + 1
        end
    end

    if pairsInCurrent > 0 then
        table.insert(commands, current)
    end

    return commands
end

function RB:SendItemAmountCommands(prefix, items, maxPairs, transactionContext)
    local commands = self:BuildItemAmountCommands(prefix, items, maxPairs)
    for _, command in ipairs(commands) do
        self:SendServerCommand(command, transactionContext)
    end
    return #commands
end

function RB:RequestRoot()
    self:HideDepositPreview()
    self:HideShoppingAmountPrompt()
    self.pendingRefresh = nil
    self.awaitingView = "root"

    self:BeginBusy("request", "Refreshing categories...")
    self:SendServerCommand("open")
end

function RB:RequestCategory(categoryId, page)
    self:HideWithdrawPrompt()
    self:HideDepositPreview()
    self:HideShoppingAmountPrompt()
    categoryId = tonumber(categoryId)
    page = tonumber(page) or 0

    if not categoryId then
        self:RequestRoot()
        return
    end

    self.pendingRefresh = nil
    self.awaitingView = "category"

    local category = CATEGORY_BY_ID[categoryId]
    local categoryName = category and category.name or "category"

    self:BeginBusy("request", "Loading " .. categoryName .. "...")
    self:SendServerCommand("list " .. tostring(categoryId) .. " " .. tostring(page) .. " " .. self:GetItemSortMode())
end

function RB:HideDepositPreview()
    if self.frame and self.frame.depositPreview then
        self.frame.depositPreview:Hide()
    end

    self.pendingDepositPreview = nil
    self.depositPreview = nil
    self:UpdateControls()
end

function RB:BuildDepositPreviewTitle(preview)
    local scope = tostring(preview and preview.scope or "all")

    if scope == "category" then
        local category = CATEGORY_BY_ID[tonumber(preview and preview.categoryId)]
        return "Deposit Preview: " .. tostring(category and category.name or "Category")
    end

    return "Deposit Preview: All Bags"
end

function RB:RequestDepositPreview(scope, categoryId)
    self:HideWithdrawPrompt()
    self:HideDepositPreview()

    scope = tostring(scope or "all")

    if scope == "category" then
        categoryId = tonumber(categoryId or self.currentCategoryId)
        if not categoryId then
            return
        end

        self:BeginBusy("request", "Building deposit preview...")
        self:SendServerCommand("preview deposit category " .. tostring(categoryId))
        return
    end

    self:BeginBusy("request", "Building deposit preview...")
    self:SendServerCommand("preview deposit all")
end

function RB:ShowDepositPreview(preview)
    self:CreateFrame()
    self:HideWithdrawPrompt()

    if not preview or not preview.items or #preview.items == 0 then
        self:HideDepositPreview()
        self:ClearBusy("No matching reagents were found in your bags.", 1.00, 0.82, 0.32)
        return
    end

    table.sort(preview.items, function(a, b)
        local _, an = GetItemDisplay(a.entry)
        local _, bn = GetItemDisplay(b.entry)
        an = string.lower(tostring(an or ""))
        bn = string.lower(tostring(bn or ""))
        if an == bn then
            return (tonumber(a.entry) or 0) < (tonumber(b.entry) or 0)
        end
        return an < bn
    end)

    self.depositPreview = preview

    local f = self.frame
    local panel = f.depositPreview
    panel:Show()
    panel.title:SetText(self:BuildDepositPreviewTitle(preview))
    panel.summary:SetText("This will deposit " .. FormatCount(preview.total or 0) .. " reagent(s) across " .. tostring(#preview.items) .. " item type(s).")

    local missingItemInfo = false
    for index = 1, DEPOSIT_PREVIEW_ROW_COUNT do
        local row = panel.rows[index]
        local item = preview.items[index]

        if item then
            local icon, name, link, stackCount, missingInfo = GetItemDisplay(item.entry)
            if missingInfo then
                missingItemInfo = true
            end

            row.icon:SetTexture(icon)
            row.name:SetText(link or name)
            row.count:SetText("x" .. FormatCount(item.amount))
            row:Show()
        else
            row:Hide()
        end
    end

    local remaining = #preview.items - DEPOSIT_PREVIEW_ROW_COUNT
    if remaining > 0 then
        panel.more:SetText("+" .. tostring(remaining) .. " more item type(s).")
        panel.more:Show()
    else
        panel.more:SetText("")
        panel.more:Hide()
    end

    self:SetButtonEnabled(panel.confirm, self.busyKind == nil)
    self:ClearBusy("Review the deposit preview, then confirm or cancel.", 0.82, 0.82, 0.82)

    if missingItemInfo then
        self:QueueItemInfoRefresh()
    end
end

function RB:RunDeposit(scope, categoryId)
    self:HideWithdrawPrompt()
    self:HideDepositPreview()

    scope = tostring(scope or "all")

    if scope == "category" then
        categoryId = tonumber(categoryId or self.currentCategoryId)
        if not categoryId then
            return
        end

        self.mutationNeedsRefresh = "category"
        self:BeginBusy("mutation", "Depositing this category...")
        self:SendServerCommand("deposit category " .. tostring(categoryId), { action = "deposit", source = "manual" })
        self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "category", categoryId, self.currentPage or 0)
        return
    end

    self.mutationNeedsRefresh = "root"
    self:BeginBusy("mutation", "Depositing all reagents...")
    self:SendServerCommand("deposit all", { action = "deposit", source = "manual" })
    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "root", nil, 0)
end

function RB:ConfirmDepositPreview()
    local preview = self.depositPreview
    if not preview then
        self:HideDepositPreview()
        return
    end

    self:RunDeposit(preview.scope, preview.categoryId)
end

function RB:DepositAll()
    if self:IsDepositPreviewEnabled() then
        self:RequestDepositPreview("all")
    else
        self:RunDeposit("all")
    end
end

function RB:WithdrawAll()
    self:HideWithdrawPrompt()
    self.mutationNeedsRefresh = "root"
    self:BeginBusy("mutation", "Withdrawing all reagents...")
    self:SendServerCommand("withdraw all")
    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "root", nil, 0)
end

function RB:DepositCategory()
    if not self.currentCategoryId then
        return
    end

    if self:IsDepositPreviewEnabled() then
        self:RequestDepositPreview("category", self.currentCategoryId)
    else
        self:RunDeposit("category", self.currentCategoryId)
    end
end

function RB:WithdrawCategory()
    self:HideWithdrawPrompt()
    if not self.currentCategoryId then
        return
    end

    self.mutationNeedsRefresh = "category"
    self:BeginBusy("mutation", "Withdrawing this category...")
    self:SendServerCommand("withdraw category " .. tostring(self.currentCategoryId))
    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "category", self.currentCategoryId, self.currentPage or 0)
end

function RB:GetOptimisticWithdrawAmount(item, mode, exactAmount)
    if not item then
        return 0
    end

    local stored = tonumber(item.amount) or 0
    if stored <= 0 then
        return 0
    end

    if mode == "one" then
        return math.min(stored, 1)
    end

    if mode == "stack" then
        local icon, name, link, stackCount = GetItemDisplay(item.entry)
        return math.min(stored, stackCount or 1)
    end

    if mode == "all" then
        return stored
    end

    if mode == "exact" then
        return math.min(stored, math.max(tonumber(exactAmount) or 0, 0))
    end

    return 0
end

function RB:ApplyOptimisticWithdraw(itemEntry, amount)
    itemEntry = tonumber(itemEntry)
    amount = tonumber(amount) or 0

    if not itemEntry or amount <= 0 then
        return
    end

    local removedType = false

    if self.items then
        local index = 1
        while index <= #self.items do
            local item = self.items[index]
            if item and tonumber(item.entry) == itemEntry then
                local newAmount = math.max((tonumber(item.amount) or 0) - amount, 0)
                item.amount = newAmount

                if newAmount <= 0 then
                    table.remove(self.items, index)
                    removedType = true
                end

                break
            end

            index = index + 1
        end
    end

    if self.detailItem and tonumber(self.detailItem.entry) == itemEntry then
        self.detailItem.amount = math.max((tonumber(self.detailItem.amount) or 0) - amount, 0)
    end

    if self.currentCategoryId then
        self.categoryAmount = math.max((tonumber(self.categoryAmount) or 0) - amount, 0)

        if removedType then
            self.categoryTypeCount = math.max((tonumber(self.categoryTypeCount) or 0) - 1, 0)
        end

        if self.categories and self.categories[self.currentCategoryId] then
            local category = self.categories[self.currentCategoryId]
            category.amount = math.max((tonumber(category.amount) or 0) - amount, 0)

            if removedType then
                category.types = math.max((tonumber(category.types) or 0) - 1, 0)
            end
        end
    end

    if self.currentView == "detail" then
        if self.detailItem and (tonumber(self.detailItem.amount) or 0) > 0 then
            self:ShowDetail(self.detailItem, true)
        else
            self:RenderCategory(true)
        end
    elseif self.currentView == "category" then
        self:RenderCategory(true)
    end
end

function RB:GetExactWithdrawAmount()
    if not self.frame or not self.frame.exactBox then
        return 0
    end

    local amount = tonumber(self.frame.exactBox:GetText() or "") or 0
    amount = math.floor(amount)

    if amount < 0 then
        amount = 0
    end

    return amount
end

function RB:WithdrawItem(mode)
    self:HideWithdrawPrompt()
    if not self.detailItem or not self.detailItem.entry then
        return
    end

    mode = mode or "one"

    local categoryId = self.currentCategoryId or 0
    local page = self.currentPage or 0
    local itemEntry = self.detailItem.entry
    local optimisticAmount = self:GetOptimisticWithdrawAmount(self.detailItem, mode)

    self.mutationNeedsRefresh = "category"
    self:BeginBusy("mutation", "Withdrawing item...")
    self:SendServerCommand("withdraw item " .. tostring(itemEntry) .. " " .. tostring(mode) .. " " .. tostring(categoryId) .. " " .. tostring(page))

    if optimisticAmount > 0 then
        self:ApplyOptimisticWithdraw(itemEntry, optimisticAmount)
        self:Status("Withdraw sent. Count updated locally; synchronizing...", 0.82, 0.82, 0.82)
    end

    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "category", categoryId, page)
end

function RB:WithdrawItemExact()
    self:HideWithdrawPrompt()
    if not self.detailItem or not self.detailItem.entry then
        return
    end

    local amount = self:GetExactWithdrawAmount()
    if amount <= 0 then
        self:Status("Enter an exact amount first.", 1.00, 0.82, 0.32)
        return
    end

    local categoryId = self.currentCategoryId or 0
    local page = self.currentPage or 0
    local itemEntry = self.detailItem.entry
    local optimisticAmount = self:GetOptimisticWithdrawAmount(self.detailItem, "exact", amount)

    self.mutationNeedsRefresh = "category"
    self:BeginBusy("mutation", "Withdrawing exact amount...")
    self:SendServerCommand("withdraw item " .. tostring(itemEntry) .. " exact " .. tostring(amount) .. " " .. tostring(categoryId) .. " " .. tostring(page))

    if optimisticAmount > 0 then
        self:ApplyOptimisticWithdraw(itemEntry, optimisticAmount)
        self:Status("Exact withdraw sent. Count updated locally; synchronizing...", 0.82, 0.82, 0.82)
    end

    if self.frame and self.frame.exactBox then
        self.frame.exactBox:SetText("")
        self.frame.exactBox:ClearFocus()
    end

    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "category", categoryId, page)
end

function RB:GetWithdrawPromptAmount()
    if not self.frame or not self.frame.quickWithdrawBox then
        return 0
    end

    local amount = tonumber(self.frame.quickWithdrawBox:GetText() or "") or 0
    amount = math.floor(amount)

    if amount < 0 then
        amount = 0
    end

    return amount
end

function RB:HideWithdrawPrompt()
    self.promptItem = nil

    if self.frame and self.frame.quickWithdraw then
        self.frame.quickWithdraw:Hide()
    end

    if self.frame and self.frame.quickWithdrawBox then
        self.frame.quickWithdrawBox:SetText("")
        self.frame.quickWithdrawBox:ClearFocus()
    end

    self:UpdateControls()
end

function RB:UpdateQuickWithdrawControls()
    if not self.frame or not self.frame.quickWithdraw then
        return
    end

    local item = self.promptItem
    local stored = item and (tonumber(item.amount) or 0) or 0
    local amount = self:GetWithdrawPromptAmount()
    local missingAmount = math.max(0, amount - stored)
    local enabled = self.busyKind == nil and item ~= nil and stored > 0 and amount > 0 and amount <= stored

    if amount > stored and stored > 0 then
        self.frame.quickWithdrawHint:SetText("Only " .. FormatCount(stored) .. " stored. Add " .. FormatCount(missingAmount) .. " missing to the AH list.")
        self.frame.quickWithdrawHint:SetTextColor(1.00, 0.50, 0.35)
    else
        self.frame.quickWithdrawHint:SetText("")
        self.frame.quickWithdrawHint:SetTextColor(0.50, 0.50, 0.50)
    end

    self:SetButtonEnabled(self.frame.quickWithdrawButton, enabled)
    self:SetButtonEnabled(self.frame.quickWithdrawAll, self.busyKind == nil and item ~= nil and stored > 0)
    self:SetButtonEnabled(self.frame.quickWithdrawShopping, self.busyKind == nil and item ~= nil and missingAmount > 0)
    self:SetButtonEnabled(self.frame.quickWithdrawCancel, true)
end

function RB:SetWithdrawPromptAmountToAll()
    if not self.promptItem or not self.frame or not self.frame.quickWithdrawBox then
        return
    end

    local stored = math.max(tonumber(self.promptItem.amount) or 0, 0)
    self.frame.quickWithdrawBox:SetText(tostring(math.floor(stored)))
    self.frame.quickWithdrawBox:HighlightText()
    self:UpdateQuickWithdrawControls()
end

function RB:AddWithdrawPromptMissingToShoppingList()
    local item = self.promptItem
    if not item or not item.entry then
        self:HideWithdrawPrompt()
        return
    end

    local stored = math.max(tonumber(item.amount) or 0, 0)
    local amount = self:GetWithdrawPromptAmount()
    local missingAmount = math.max(0, amount - stored)

    if missingAmount <= 0 then
        self:Status("Enter more than the stored amount to add the shortfall to the AH list.", 1.00, 0.82, 0.32)
        self:UpdateQuickWithdrawControls()
        return
    end

    local itemEntry = item.entry
    self:HideWithdrawPrompt()
    self:AddShoppingListItem(itemEntry, missingAmount)
end

function RB:ShowWithdrawPrompt(item)
    if not item or not item.entry then
        return
    end

    self:CreateFrame()

    local stored = math.max(tonumber(item.amount) or 0, 0)
    if stored <= 0 then
        self:Status("That item is no longer stored.", 1.00, 0.82, 0.32)
        return
    end

    self.promptItem = item
    HideTooltip()

    local f = self.frame
    local icon, name, link, stackCount = GetItemDisplay(item.entry)

    f.quickWithdrawIcon:SetTexture(icon)
    f.quickWithdrawName:SetText(link or name)
    f.quickWithdrawStored:SetText("Stored: " .. FormatCount(stored))
    f.quickWithdrawBox:SetText("")
    f.quickWithdrawBox:SetFocus()
    f.quickWithdrawBox:HighlightText()
    f.quickWithdraw:Show()
    f.quickWithdraw:SetFrameLevel((f:GetFrameLevel() or 1) + 80)

    self:UpdateQuickWithdrawControls()
    self:Status("Enter amount to withdraw for " .. tostring(name or ("Item #" .. tostring(item.entry))) .. ".", 0.82, 0.82, 0.82)
end

function RB:WithdrawItemExactFromPrompt(item, amount)
    if not item or not item.entry then
        return
    end

    amount = math.floor(tonumber(amount) or 0)

    if amount <= 0 then
        self:Status("Enter an amount first.", 1.00, 0.82, 0.32)
        return
    end

    local stored = tonumber(item.amount) or 0
    if amount > stored then
        self:Status("You only have " .. FormatCount(stored) .. " stored.", 1.00, 0.82, 0.32)
        return
    end

    local categoryId = self.currentCategoryId or 0
    local page = self.currentPage or 0
    local itemEntry = item.entry
    local optimisticAmount = self:GetOptimisticWithdrawAmount(item, "exact", amount)

    self.mutationNeedsRefresh = "category"
    self:BeginBusy("mutation", "Withdrawing exact amount...")
    self:SendServerCommand("withdraw item " .. tostring(itemEntry) .. " exact " .. tostring(amount) .. " " .. tostring(categoryId) .. " " .. tostring(page))

    if optimisticAmount > 0 then
        self:ApplyOptimisticWithdraw(itemEntry, optimisticAmount)
        self:Status("Exact withdraw sent. Count updated locally; synchronizing...", 0.82, 0.82, 0.82)
    end

    self:HideWithdrawPrompt()
    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "category", categoryId, page)
end

function RB:ConfirmWithdrawPrompt()
    if not self.promptItem then
        self:HideWithdrawPrompt()
        return
    end

    local amount = self:GetWithdrawPromptAmount()
    self:WithdrawItemExactFromPrompt(self.promptItem, amount)
end

-- Other addons with their own profession window (e.g. MillingUI) can borrow the
-- profession sidebar. While the provider's frame is shown, the sidebar docks
-- beside it and reads the selected recipe from the provider instead of the
-- Blizzard trade skill API.
--
-- provider = {
--     name = "Milling",                       -- prefetch key
--     frame = MillingFrame,                   -- host window
--     reagentButtons = { button, ... },       -- rows that get the "+N bank" overlay
--     GetRecipe = function() return recipeName, { { itemEntry, name, requiredPerCraft }, ... } end,
--                 -- or return nil, errText
--     GetAllReagentEntries = function() return { itemEntry, ... } end,
--     GetRepeatCount = function() return n end,        -- optional
--     SetRepeatCount = function(n) end,                -- optional
-- }
function RB:RegisterRecipeProvider(provider)
    if type(provider) ~= "table" or not provider.frame or not provider.GetRecipe then
        return false
    end

    -- Several addons can register (e.g. MillingUI and ProspectingUI); the
    -- sidebar follows whichever of their windows was opened last.
    self.recipeProviders = self.recipeProviders or {}
    for _, registered in ipairs(self.recipeProviders) do
        if registered.frame == provider.frame then
            return false
        end
    end
    table.insert(self.recipeProviders, provider)

    provider.frame:HookScript("OnShow", function()
        RB.lastShownRecipeProvider = provider
        RB:CreateTradeSkillControls()
        RB:AttachTradeSkillControls()
        RB:DockTradeSkillPanel()
        RB:ResetProfessionBankPrefetch()
        RB:PrefetchProfessionBankCounts(true)
        -- Start from the saved prepare count and push it into the provider.
        RB:SetTradeSkillPrepareCount(RB:GetTradeSkillRepeatCount(), true)
    end)

    provider.frame:HookScript("OnHide", function()
        RB:AttachTradeSkillControls()
        RB:ResetProfessionBankPrefetch()
        RB:HideReagentBankOverlays()
        RB:HandleTradeSkillClosed()

        -- Another provider's window is still open and now owns the sidebar.
        if RB:GetActiveRecipeProvider() then
            RB:PrefetchProfessionBankCounts(true)
            RB:UpdateTradeSkillControls()
        end
    end)

    return true
end

function RB:GetActiveRecipeProvider()
    local last = self.lastShownRecipeProvider
    if last and last.frame:IsShown() then
        return last
    end

    for _, provider in ipairs(self.recipeProviders or {}) do
        if provider.frame:IsShown() then
            return provider
        end
    end
    return nil
end

-- The Blizzard trade skill window has no provider to report bag changes, and a
-- withdraw's confirmation reaches the client before the items land in the bags,
-- so the sidebar would keep showing pre-withdraw bag counts. BAG_UPDATE fires
-- once per bag, so the redraw is batched into one.
function RB:ScheduleTradeSkillBagRefresh()
    if self:GetActiveRecipeProvider() or not (TradeSkillFrame and TradeSkillFrame:IsShown()) then
        return
    end

    if not self.pendingTradeSkillBagRefreshAt then
        self.pendingTradeSkillBagRefreshAt = GetTime() + PROFESSION_BAG_REFRESH_DELAY
        self:EnsureOnUpdate()
    end
end

-- Providers call this when their selection or bags change.
function RB:NotifyRecipeProviderChanged()
    if self:GetActiveRecipeProvider() then
        self:UpdateTradeSkillControls()
    end
end

function RB:ClampTradeSkillPrepareCount(value)
    value = math.floor(tonumber(value) or 1)

    if value < TRADE_SKILL_PREPARE_COUNT_MIN then
        value = TRADE_SKILL_PREPARE_COUNT_MIN
    end

    if value > TRADE_SKILL_PREPARE_COUNT_MAX then
        value = TRADE_SKILL_PREPARE_COUNT_MAX
    end

    return value
end

function RB:GetNativeTradeSkillRepeatCount()
    local provider = self:GetActiveRecipeProvider()
    if provider then
        local value = provider.GetRepeatCount and tonumber(provider.GetRepeatCount())
        if value and value > 0 then
            return self:ClampTradeSkillPrepareCount(value)
        end
        return 1
    end

    local input = _G.TradeSkillInputBox
    if input and input.GetNumber then
        local value = tonumber(input:GetNumber())
        if value and value > 0 then
            return self:ClampTradeSkillPrepareCount(value)
        end
    end

    if input and input.GetText then
        local value = tonumber(input:GetText())
        if value and value > 0 then
            return self:ClampTradeSkillPrepareCount(value)
        end
    end

    return 1
end

function RB:GetTradeSkillRepeatCount()
    if self.tradeSkillQuantityBox and self.tradeSkillQuantityBox.GetText then
        local value = tonumber(self.tradeSkillQuantityBox:GetText())
        if value and value > 0 then
            return self:ClampTradeSkillPrepareCount(value)
        end
    end

    ReagentBankUIDB = ReagentBankUIDB or {}
    local saved = tonumber(ReagentBankUIDB.tradeSkillPrepareCount)
    if saved and saved > 0 then
        return self:ClampTradeSkillPrepareCount(saved)
    end

    return self:GetNativeTradeSkillRepeatCount()
end

function RB:SetTradeSkillPrepareCount(value, updateNative)
    value = self:ClampTradeSkillPrepareCount(value)

    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.tradeSkillPrepareCount = value

    if self.tradeSkillQuantityBox and self.tradeSkillQuantityBox.GetText then
        local textValue = tostring(value)
        if self.tradeSkillQuantityBox:GetText() ~= textValue then
            self.suppressTradeSkillQuantityChanged = true
            self.tradeSkillQuantityBox:SetText(textValue)
            self.suppressTradeSkillQuantityChanged = nil
        end
    end

    if updateNative then
        self:SyncNativeTradeSkillRepeatCount(value)
    end

    self:UpdateTradeSkillControls()
    return value
end

function RB:NormalizeTradeSkillQuantityBox(updateNative)
    return self:SetTradeSkillPrepareCount(self:GetTradeSkillRepeatCount(), updateNative)
end

function RB:SyncNativeTradeSkillRepeatCount(value)
    value = self:ClampTradeSkillPrepareCount(value)

    local provider = self:GetActiveRecipeProvider()
    if provider then
        if provider.SetRepeatCount then
            provider.SetRepeatCount(value)
        end
        return
    end

    local input = _G.TradeSkillInputBox
    if not input then
        return
    end

    self.suppressNativeTradeSkillQuantityChanged = true

    if input.SetNumber then
        input:SetNumber(value)
    elseif input.SetText then
        input:SetText(tostring(value))
    end

    self.suppressNativeTradeSkillQuantityChanged = nil
end

function RB:GetSelectedProviderReagents(provider)
    local recipeName, recipeReagents = provider.GetRecipe()
    if not recipeName then
        return nil, recipeReagents or "Select a recipe first.", nil, nil
    end

    local reagents = {}
    for _, reagent in ipairs(recipeReagents or {}) do
        local itemEntry = tonumber(reagent.itemEntry)
        local requiredPerCraft = tonumber(reagent.requiredPerCraft) or 0

        if itemEntry and itemEntry > 0 and requiredPerCraft > 0 then
            table.insert(reagents, {
                itemEntry = itemEntry,
                entry = itemEntry,
                requiredPerCraft = requiredPerCraft,
                bagCount = GetItemCount and (tonumber(GetItemCount(itemEntry, false)) or 0) or 0,
                name = reagent.name or ("Item #" .. tostring(itemEntry)),
            })
        end
    end

    return reagents, nil, recipeName, self:GetTradeSkillRepeatCount()
end

function RB:GetSelectedTradeSkillReagents()
    local provider = self:GetActiveRecipeProvider()
    if provider then
        return self:GetSelectedProviderReagents(provider)
    end

    if not GetTradeSkillSelectionIndex or not GetTradeSkillInfo or not GetTradeSkillNumReagents or not GetTradeSkillReagentInfo then
        return nil, "The trade skill API is not available.", nil, nil
    end

    local index = GetTradeSkillSelectionIndex()
    if not index or index <= 0 then
        return nil, "Select a recipe first.", nil, nil
    end

    local recipeName, recipeType, numAvailable, isExpanded = GetTradeSkillInfo(index)
    if isExpanded or recipeType == "header" then
        return nil, "Select a craftable recipe, not a category header.", nil, nil
    end

    local reagentCount = GetTradeSkillNumReagents(index) or 0
    if reagentCount <= 0 then
        return {}, nil, recipeName, self:GetTradeSkillRepeatCount()
    end

    local repeatCount = self:GetTradeSkillRepeatCount()
    local byItem = {}
    local order = {}

    for reagentIndex = 1, reagentCount do
        local reagentName, reagentTexture, requiredCount, playerCount = GetTradeSkillReagentInfo(index, reagentIndex)
        requiredCount = tonumber(requiredCount) or 0

        local link = nil
        if GetTradeSkillReagentItemLink then
            link = GetTradeSkillReagentItemLink(index, reagentIndex)
        end

        local itemEntry = ParseItemIdFromLink(link)
        if itemEntry and requiredCount > 0 then
            local inBags = 0

            if GetItemCount then
                inBags = tonumber(GetItemCount(itemEntry, false)) or 0
            end

            if inBags <= 0 and playerCount then
                inBags = tonumber(playerCount) or 0
            end

            if not byItem[itemEntry] then
                byItem[itemEntry] = {
                    itemEntry = itemEntry,
                    entry = itemEntry,
                    requiredPerCraft = 0,
                    bagCount = 0,
                    name = reagentName or ("Item #" .. tostring(itemEntry)),
                }
                table.insert(order, itemEntry)
            end

            byItem[itemEntry].requiredPerCraft = byItem[itemEntry].requiredPerCraft + requiredCount
            byItem[itemEntry].bagCount = math.max(tonumber(byItem[itemEntry].bagCount) or 0, inBags)
        end
    end

    local reagents = {}
    for _, itemEntry in ipairs(order) do
        local reagent = byItem[itemEntry]
        if reagent and (tonumber(reagent.requiredPerCraft) or 0) > 0 then
            table.insert(reagents, reagent)
        end
    end

    return reagents, nil, recipeName, repeatCount
end

function RB:BuildTradeSkillReagentKey(reagents)
    local parts = {}

    for _, reagent in ipairs(reagents or {}) do
        local itemEntry = tonumber(reagent.itemEntry or reagent.entry)
        local requiredPerCraft = math.floor(tonumber(reagent.requiredPerCraft or reagent.amount) or 0)

        if itemEntry and itemEntry > 0 and requiredPerCraft > 0 then
            table.insert(parts, tostring(math.floor(itemEntry)) .. "x" .. tostring(requiredPerCraft))
        end
    end

    table.sort(parts)
    return table.concat(parts, ";")
end

function RB:RequestTradeSkillBankCounts(reagents)
    if not reagents or #reagents == 0 then
        return
    end

    local key = self:BuildTradeSkillReagentKey(reagents)
    if key == "" then
        return
    end

    if self.tradeSkillBankCountsKey == key then
        return
    end

    if self.pendingTradeSkillCheckKey == key and self.pendingTradeSkillCheckUntil and GetTime() < self.pendingTradeSkillCheckUntil then
        return
    end

    self.tradeSkillCheckRequestId = (tonumber(self.tradeSkillCheckRequestId) or 0) + 1
    if self.tradeSkillCheckRequestId > 100000000 then
        self.tradeSkillCheckRequestId = 1
    end

    local requestId = self.tradeSkillCheckRequestId
    self.pendingTradeSkillChecks = self.pendingTradeSkillChecks or {}
    self.pendingTradeSkillChecks[requestId] = {
        key = key,
        createdAt = GetTime(),
    }
    self.pendingTradeSkillCheckKey = key
    self.pendingTradeSkillCheckUntil = GetTime() + TRADE_SKILL_CHECK_TIMEOUT

    local items = {}
    for _, reagent in ipairs(reagents) do
        local itemEntry = tonumber(reagent.itemEntry or reagent.entry)
        local requiredPerCraft = math.floor(tonumber(reagent.requiredPerCraft) or 0)

        if itemEntry and itemEntry > 0 and requiredPerCraft > 0 then
            table.insert(items, {
                entry = math.floor(itemEntry),
                amount = requiredPerCraft,
            })
        end
    end

    if #items > 0 then
        self:SendServerCommand(self:BuildItemAmountCommand("check recipe " .. tostring(requestId), items))
    end
end

function RB:GetTradeSkillCraftability(reagents, repeatCount)
    local bankCounts = self:GetProfessionBankCountsFor(reagents)
    local bankCountsReady = bankCounts ~= nil

    if not bankCountsReady then
        local key = self:BuildTradeSkillReagentKey(reagents)
        bankCountsReady = key ~= "" and self.tradeSkillBankCountsKey == key
        bankCounts = bankCountsReady and self.tradeSkillBankCounts or {}
    end

    local bagCrafts = nil
    local bankCrafts = nil
    local combinedCrafts = nil
    local missingTypes = 0

    repeatCount = self:ClampTradeSkillPrepareCount(repeatCount or 1)

    for _, reagent in ipairs(reagents or {}) do
        local itemEntry = tonumber(reagent.itemEntry or reagent.entry)
        local requiredPerCraft = math.floor(tonumber(reagent.requiredPerCraft) or 0)

        if itemEntry and itemEntry > 0 and requiredPerCraft > 0 then
            local bagCount = 0
            if GetItemCount then
                bagCount = tonumber(GetItemCount(itemEntry, false)) or 0
            end

            if (not bagCount or bagCount <= 0) and reagent.bagCount then
                bagCount = tonumber(reagent.bagCount) or 0
            end

            local bankCount = tonumber(bankCounts and bankCounts[itemEntry]) or 0
            local fromBags = math.floor(bagCount / requiredPerCraft)
            local fromBank = math.floor(bankCount / requiredPerCraft)
            local fromCombined = math.floor((bagCount + bankCount) / requiredPerCraft)

            if bagCrafts == nil or fromBags < bagCrafts then
                bagCrafts = fromBags
            end

            if bankCountsReady then
                if bankCrafts == nil or fromBank < bankCrafts then
                    bankCrafts = fromBank
                end

                if combinedCrafts == nil or fromCombined < combinedCrafts then
                    combinedCrafts = fromCombined
                end

                if bagCount + bankCount < requiredPerCraft * repeatCount then
                    missingTypes = missingTypes + 1
                end
            end
        end
    end

    if bagCrafts == nil then
        bagCrafts = 0
    end

    if bankCountsReady and bankCrafts == nil then
        bankCrafts = 0
    end

    if combinedCrafts == nil then
        combinedCrafts = bagCrafts
    end

    return {
        bankReady = bankCountsReady,
        bankCrafts = bankCrafts,
        bagCrafts = bagCrafts,
        combinedCrafts = combinedCrafts,
        missingTypes = missingTypes,
    }
end

-- The same figure the panel headlines as "N craftable": how many crafts bags
-- and bank cover between them, capped by the scarcest reagent. Returns nil
-- while bank counts are still arriving, so Max cannot hand back a bags-only
-- number that is about to change under the player.
function RB:GetMaxCraftableCount()
    local reagents, errText = self:GetSelectedTradeSkillReagents()
    if errText or not reagents or #reagents == 0 then
        return nil
    end

    local craftability = self:GetTradeSkillCraftability(reagents, self:GetTradeSkillRepeatCount())
    if not craftability or not craftability.bankReady then
        return nil
    end

    local combined = math.floor(tonumber(craftability.combinedCrafts) or 0)
    if combined < TRADE_SKILL_PREPARE_COUNT_MIN then
        return nil
    end

    return self:ClampTradeSkillPrepareCount(combined)
end

function RB:GetLowStockCraftCount()
    ReagentBankUIDB = ReagentBankUIDB or {}
    return self:ClampTradeSkillPrepareCount(tonumber(ReagentBankUIDB.lowStockCrafts) or LOW_STOCK_DEFAULT_CRAFTS)
end

function RB:SetLowStockCraftCount(value)
    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.lowStockCrafts = self:ClampTradeSkillPrepareCount(value or LOW_STOCK_DEFAULT_CRAFTS)
    self:UpdateTradeSkillControls()
    PrintAddon("low-stock alerts check enough reagents for " .. tostring(ReagentBankUIDB.lowStockCrafts) .. " craft(s).")
    return ReagentBankUIDB.lowStockCrafts
end

function RB:ResetProfessionBankPrefetch()
    self.professionBankCounts = nil
    self.professionBankCountsReady = false
    self.professionPrefetchKey = nil
    self.professionPrefetchSkillCount = nil
    self.professionPrefetchQueue = nil
    self.professionPrefetchPending = nil
    self.professionPrefetchOutstanding = 0
    self.professionPrefetchNextSendAt = nil
    self.professionPrefetchDeadline = nil
end

function RB:BuildProfessionPrefetchKey()
    local provider = self:GetActiveRecipeProvider()
    if provider then
        return "provider:" .. tostring(provider.name or "external")
    end

    if not GetTradeSkillLine then
        return ""
    end

    local skillName = GetTradeSkillLine()
    if type(skillName) ~= "string" or skillName == "" or skillName == "UNKNOWN" then
        return ""
    end

    return skillName
end

function RB:CollectProfessionReagentEntries()
    local provider = self:GetActiveRecipeProvider()
    if provider then
        if not provider.GetAllReagentEntries then
            return nil
        end

        local seen = {}
        local entries = {}
        for _, rawEntry in ipairs(provider.GetAllReagentEntries() or {}) do
            local itemEntry = tonumber(rawEntry)
            if itemEntry and itemEntry > 0 and not seen[itemEntry] then
                seen[itemEntry] = true
                table.insert(entries, math.floor(itemEntry))
            end
        end
        return entries, #entries
    end

    if not GetNumTradeSkills or not GetTradeSkillInfo or not GetTradeSkillNumReagents or not GetTradeSkillReagentItemLink then
        return nil
    end

    local numSkills = GetNumTradeSkills() or 0
    if numSkills <= 0 then
        return nil
    end

    local seen = {}
    local entries = {}

    for skillIndex = 1, numSkills do
        local _, skillType = GetTradeSkillInfo(skillIndex)

        if skillType ~= "header" then
            local reagentCount = GetTradeSkillNumReagents(skillIndex) or 0

            for reagentIndex = 1, reagentCount do
                local link = GetTradeSkillReagentItemLink(skillIndex, reagentIndex)
                local itemEntry = ParseItemIdFromLink(link)

                if itemEntry and itemEntry > 0 and not seen[itemEntry] then
                    seen[itemEntry] = true
                    table.insert(entries, math.floor(itemEntry))
                end
            end
        end
    end

    return entries, numSkills
end

function RB:PrefetchProfessionBankCounts(force)
    local key = self:BuildProfessionPrefetchKey()
    if key == "" then
        return
    end

    if self.professionPrefetchDeadline then
        return
    end

    local numSkills = 0
    if self:GetActiveRecipeProvider() then
        -- A provider's list doesn't grow while it's open; one prefetch per show.
        numSkills = tonumber(self.professionPrefetchSkillCount) or 0
    elseif GetNumTradeSkills then
        numSkills = GetNumTradeSkills() or 0
    end

    if not force and self.professionPrefetchKey == key then
        local covered = tonumber(self.professionPrefetchSkillCount) or 0
        if numSkills <= covered then
            return
        end
    end

    local entries, collectedSkillCount = self:CollectProfessionReagentEntries()
    if not entries or #entries == 0 then
        return
    end

    self:ResetProfessionBankPrefetch()

    self.professionPrefetchKey = key
    self.professionPrefetchSkillCount = collectedSkillCount or numSkills
    self.professionBankCounts = {}
    self.professionPrefetchPending = {}
    self.professionPrefetchQueue = {}

    local batch = {}
    for _, itemEntry in ipairs(entries) do
        table.insert(batch, itemEntry)

        if #batch >= PROFESSION_PREFETCH_PAIRS_PER_COMMAND then
            table.insert(self.professionPrefetchQueue, batch)
            batch = {}
        end
    end

    if #batch > 0 then
        table.insert(self.professionPrefetchQueue, batch)
    end

    self.professionPrefetchOutstanding = #self.professionPrefetchQueue
    self.professionPrefetchNextSendAt = GetTime()
    self.professionPrefetchDeadline = GetTime() + PROFESSION_PREFETCH_TIMEOUT
    self:EnsureOnUpdate()
end

function RB:SendNextProfessionPrefetchBatch(now)
    local queue = self.professionPrefetchQueue
    if type(queue) ~= "table" or #queue == 0 then
        return
    end

    if self.professionPrefetchNextSendAt and now < self.professionPrefetchNextSendAt then
        return
    end

    local batch = table.remove(queue, 1)
    self.professionPrefetchNextSendAt = now + PROFESSION_PREFETCH_SEND_INTERVAL

    self.tradeSkillCheckRequestId = (tonumber(self.tradeSkillCheckRequestId) or 0) + 1
    if self.tradeSkillCheckRequestId > 100000000 then
        self.tradeSkillCheckRequestId = 1
    end

    local requestId = self.tradeSkillCheckRequestId
    self.professionPrefetchPending = self.professionPrefetchPending or {}
    self.professionPrefetchPending[requestId] = true

    -- Built directly rather than through BuildItemAmountCommand, which keeps only its
    -- first command and would silently drop the rest of the batch. The server ignores
    -- the amount in a check, so 1 is fine.
    local command = "check recipe " .. tostring(requestId)
    for _, itemEntry in ipairs(batch) do
        command = command .. " " .. tostring(itemEntry) .. " 1"
    end

    self:SendServerCommand(command)
end

function RB:HandleProfessionPrefetchResponse(requestId, counts)
    if type(self.professionPrefetchPending) ~= "table" or not self.professionPrefetchPending[requestId] then
        return false
    end

    self.professionPrefetchPending[requestId] = nil
    self.professionBankCounts = self.professionBankCounts or {}

    for rawEntry, rawAmount in pairs(counts or {}) do
        local itemEntry = tonumber(rawEntry)
        if itemEntry and itemEntry > 0 then
            self.professionBankCounts[math.floor(itemEntry)] = math.max(0, math.floor(tonumber(rawAmount) or 0))
        end
    end

    self.professionPrefetchOutstanding = math.max(0, (tonumber(self.professionPrefetchOutstanding) or 0) - 1)

    local queueEmpty = type(self.professionPrefetchQueue) ~= "table" or #self.professionPrefetchQueue == 0

    if self.professionPrefetchOutstanding <= 0 and queueEmpty then
        self.professionBankCountsReady = true
        self.professionPrefetchDeadline = nil
        self:UpdateTradeSkillControls()
    end

    return true
end

function RB:GetProfessionBankCountsFor(reagents)
    if not self.professionBankCountsReady or type(self.professionBankCounts) ~= "table" then
        return nil
    end

    local counts = {}

    for _, reagent in ipairs(reagents or {}) do
        local itemEntry = tonumber(reagent.itemEntry or reagent.entry)
        if itemEntry and itemEntry > 0 then
            itemEntry = math.floor(itemEntry)
            local amount = self.professionBankCounts[itemEntry]
            if amount == nil then
                -- Recipe uses a reagent the prefetch never covered, so fall back.
                return nil
            end
            counts[itemEntry] = amount
        end
    end

    return counts
end

function RB:AdjustProfessionBankCount(itemEntry, delta)
    if type(self.professionBankCounts) ~= "table" then
        return
    end

    itemEntry = tonumber(itemEntry)
    if not itemEntry or itemEntry <= 0 then
        return
    end

    itemEntry = math.floor(itemEntry)
    local current = self.professionBankCounts[itemEntry]
    if current == nil then
        return
    end

    self.professionBankCounts[itemEntry] = math.max(0, current + delta)
end

function RB:GetTradeSkillBankCounts(reagents)
    local prefetched = self:GetProfessionBankCountsFor(reagents)
    if prefetched then
        return true, prefetched
    end

    local key = self:BuildTradeSkillReagentKey(reagents)
    local ready = key ~= "" and self.tradeSkillBankCountsKey == key

    if not ready then
        self:RequestTradeSkillBankCounts(reagents)
    end

    return ready, ready and self.tradeSkillBankCounts or {}
end

function RB:BuildTradeSkillShoppingPlan(reagents, repeatCount, lowStockCrafts)
    repeatCount = self:ClampTradeSkillPrepareCount(repeatCount or 1)
    lowStockCrafts = self:ClampTradeSkillPrepareCount(lowStockCrafts or self:GetLowStockCraftCount())

    local bankReady, bankCounts = self:GetTradeSkillBankCounts(reagents)
    local plan = {
        bankReady = bankReady,
        repeatCount = repeatCount,
        lowStockCrafts = lowStockCrafts,
        needs = {},
        withdraw = {},
        missing = {},
        lowStock = {},
    }

    for _, reagent in ipairs(reagents or {}) do
        local itemEntry = tonumber(reagent.itemEntry or reagent.entry)
        local requiredPerCraft = math.floor(tonumber(reagent.requiredPerCraft) or 0)

        if itemEntry and itemEntry > 0 and requiredPerCraft > 0 then
            local bagCount = 0
            if GetItemCount then
                bagCount = tonumber(GetItemCount(itemEntry, false)) or 0
            end
            if bagCount <= 0 and reagent.bagCount then
                bagCount = tonumber(reagent.bagCount) or 0
            end

            local bankCount = bankReady and (tonumber(bankCounts[itemEntry]) or 0) or 0
            local required = requiredPerCraft * repeatCount
            local neededFromBags = math.max(0, required - bagCount)
            local itemName = reagent.name or GetItemChatText(itemEntry)

            if neededFromBags > 0 then
                local row = {
                    entry = itemEntry,
                    name = itemName,
                    amount = neededFromBags,
                    bagCount = bagCount,
                    bankCount = bankCount,
                    required = required,
                }
                table.insert(plan.needs, row)

                if bankReady then
                    local withdrawAmount = math.min(neededFromBags, bankCount)
                    if withdrawAmount > 0 then
                        table.insert(plan.withdraw, {
                            entry = itemEntry,
                            name = itemName,
                            amount = withdrawAmount,
                            bagCount = bagCount,
                            bankCount = bankCount,
                            required = required,
                        })
                    end

                    if neededFromBags > bankCount then
                        table.insert(plan.missing, {
                            entry = itemEntry,
                            name = itemName,
                            amount = neededFromBags - bankCount,
                            bagCount = bagCount,
                            bankCount = bankCount,
                            required = required,
                        })
                    end
                end
            end

            if bankReady then
                local lowStockRequired = requiredPerCraft * lowStockCrafts
                local totalStock = bagCount + bankCount
                if totalStock < lowStockRequired then
                    table.insert(plan.lowStock, {
                        entry = itemEntry,
                        name = itemName,
                        amount = lowStockRequired - totalStock,
                        bagCount = bagCount,
                        bankCount = bankCount,
                        required = lowStockRequired,
                    })
                end
            end
        end
    end

    return plan
end

function RB:FormatTradeSkillPlanItems(rows, limit)
    local parts = {}
    limit = math.max(1, tonumber(limit) or TRADE_SKILL_SHOPPING_LIST_LIMIT)

    for index, row in ipairs(rows or {}) do
        if index > limit then
            break
        end
        table.insert(parts, BuildItemAmountChatText(row.entry, row.amount))
    end

    if rows and #rows > limit then
        table.insert(parts, "+" .. tostring(#rows - limit) .. " more")
    end

    if #parts == 0 then
        return "none"
    end

    return table.concat(parts, ", ")
end

function RB:GetReagentNameFontString(index)
    return _G["TradeSkillReagent" .. tostring(index) .. "Name"]
end

-- The reagent name font string owns the whole text column, so a badge pinned to
-- the right edge butts straight into longer names. Narrow the column by exactly
-- what the badge needs while it is up, and hand the width back when it goes
-- away. Returns how much was actually granted, which can be less than asked.
function RB:SetReagentNameReserved(index, reserved)
    local nameText = self:GetReagentNameFontString(index)
    if not nameText or not nameText.SetWidth or not nameText.GetWidth then
        return 0
    end

    self.reagentNameWidths = self.reagentNameWidths or {}
    self.reagentNameReserved = self.reagentNameReserved or {}

    reserved = math.max(0, math.floor(tonumber(reserved) or 0))

    local applied = math.floor(tonumber(self.reagentNameReserved[index]) or 0)
    if applied <= 0 then
        -- Nothing is taken from the column right now, so whatever it measures is
        -- its natural width. Reading it here rather than once at creation keeps
        -- us correct when a skin lays the row out after we first saw it.
        local natural = tonumber(nameText:GetWidth()) or 0
        if natural > 0 then
            self.reagentNameWidths[index] = natural
        end
    end

    local original = math.floor(tonumber(self.reagentNameWidths[index]) or 0)
    if original <= 0 then
        return 0
    end

    if reserved > 0 then
        reserved = math.min(reserved, math.floor(original * REAGENT_NAME_MAX_RESERVE_RATIO))
    end

    if reserved ~= applied then
        self.reagentNameReserved[index] = reserved
        nameText:SetWidth(original - reserved)
    end

    return reserved
end

function RB:HideReagentBankOverlays()
    for _, provider in ipairs(self.recipeProviders or {}) do
        for _, button in ipairs(provider.reagentButtons or {}) do
            if button.reagentBankOverlay then
                button.reagentBankOverlay:Hide()
            end
        end
    end

    if type(self.reagentBankOverlays) ~= "table" then
        return
    end

    for index, overlay in pairs(self.reagentBankOverlays) do
        if overlay then
            overlay:Hide()
        end
        self:SetReagentNameReserved(index, 0)
    end
end

-- Same "+N bank" text as the trade skill rows, on a provider's reagent buttons.
function RB:UpdateProviderReagentBankOverlays(provider)
    local reagents = self:GetSelectedProviderReagents(provider)
    local bankCounts = reagents and self:GetReagentBankCountsForOverlay(reagents) or nil

    for index, button in ipairs(provider.reagentButtons or {}) do
        local overlay = button.reagentBankOverlay
        if not overlay and button.CreateFontString then
            overlay = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            overlay:SetPoint("RIGHT", button, "RIGHT", -2, 0)
            overlay:SetJustifyH("RIGHT")
            button.reagentBankOverlay = overlay
        end

        local reagent = reagents and reagents[index]
        local itemEntry = reagent and math.floor(reagent.itemEntry)
        local bankAmount = (bankCounts and itemEntry) and (tonumber(bankCounts[itemEntry]) or 0) or 0

        if overlay and bankAmount > 0 then
            local repeatCount = self:GetTradeSkillRepeatCount()
            overlay:SetText("+" .. FormatCount(bankAmount) .. " bank")

            if (reagent.bagCount or 0) + bankAmount >= reagent.requiredPerCraft * repeatCount then
                overlay:SetTextColor(0.38, 0.86, 0.38)
            else
                overlay:SetTextColor(1.00, 0.55, 0.25)
            end
            overlay:Show()
        elseif overlay then
            overlay:Hide()
        end
    end
end

function RB:EnsureReagentBankOverlays()
    -- Blizzard_TradeSkillUI is load-on-demand, so the rows may not exist yet.
    if not _G.TradeSkillFrame then
        return false
    end

    self.reagentBankOverlays = self.reagentBankOverlays or {}

    for index = 1, REAGENT_OVERLAY_ROW_COUNT do
        if not self.reagentBankOverlays[index] then
            local row = _G["TradeSkillReagent" .. tostring(index)]

            if row and row.CreateFontString then
                local overlay = row:CreateFontString(nil, "OVERLAY")
                overlay:SetFont(STANDARD_TEXT_FONT, REAGENT_OVERLAY_FONT_SIZE, "OUTLINE")
                overlay:SetPoint("RIGHT", row, "RIGHT", -3, 0)
                overlay:SetJustifyH("RIGHT")
                overlay:Hide()
                self.reagentBankOverlays[index] = overlay
            end
        end
    end

    return true
end

function RB:GetReagentBankCountsForOverlay(reagents)
    local counts = self:GetProfessionBankCountsFor(reagents)
    if counts then
        return counts
    end

    local key = self:BuildTradeSkillReagentKey(reagents)
    if key ~= "" and self.tradeSkillBankCountsKey == key then
        return self.tradeSkillBankCounts
    end

    return nil
end

function RB:UpdateReagentBankOverlays()
    local provider = self:GetActiveRecipeProvider()
    if provider then
        self:UpdateProviderReagentBankOverlays(provider)
        return
    end

    if not _G.TradeSkillFrame or not _G.TradeSkillFrame:IsShown() then
        self:HideReagentBankOverlays()
        return
    end

    if not self:EnsureReagentBankOverlays() then
        return
    end

    local overlays = self.reagentBankOverlays
    if type(overlays) ~= "table" then
        return
    end

    if not GetTradeSkillSelectionIndex or not GetTradeSkillNumReagents or not GetTradeSkillReagentInfo or not GetTradeSkillReagentItemLink then
        self:HideReagentBankOverlays()
        return
    end

    local index = GetTradeSkillSelectionIndex()
    if not index or index <= 0 then
        self:HideReagentBankOverlays()
        return
    end

    local reagents = self:GetSelectedTradeSkillReagents()
    local bankCounts = reagents and self:GetReagentBankCountsForOverlay(reagents) or nil

    if not bankCounts then
        self:HideReagentBankOverlays()
        return
    end

    local reagentCount = GetTradeSkillNumReagents(index) or 0

    for row = 1, REAGENT_OVERLAY_ROW_COUNT do
        local overlay = overlays[row]
        local shown = false

        if overlay and row <= reagentCount then
            local itemEntry = ParseItemIdFromLink(GetTradeSkillReagentItemLink(index, row))

            if itemEntry and itemEntry > 0 then
                local bankAmount = tonumber(bankCounts[math.floor(itemEntry)]) or 0

                if bankAmount > 0 then
                    local _, _, requiredCount = GetTradeSkillReagentInfo(index, row)
                    requiredCount = tonumber(requiredCount) or 0

                    local bagCount = 0
                    if GetItemCount then
                        bagCount = tonumber(GetItemCount(itemEntry, false)) or 0
                    end

                    overlay:SetText("+" .. FormatBadgeCount(bankAmount))

                    if requiredCount <= 0 or bagCount + bankAmount >= requiredCount then
                        overlay:SetTextColor(0.50, 0.88, 0.50)
                    else
                        overlay:SetTextColor(1.00, 0.69, 0.29)
                    end

                    -- Size the badge to the text it is actually showing, then
                    -- claim that much plus a gap. A badge the column cannot
                    -- spare room for is dropped rather than printed against the
                    -- reagent name; the sidebar still lists the same amount.
                    local badgeWidth = 0
                    if overlay.GetStringWidth then
                        badgeWidth = math.ceil(tonumber(overlay:GetStringWidth()) or 0)
                    end

                    if badgeWidth > 0 then
                        overlay:SetWidth(badgeWidth)

                        local needed = badgeWidth + REAGENT_OVERLAY_GAP
                        if self:SetReagentNameReserved(row, needed) >= needed then
                            overlay:Show()
                            shown = true
                        end
                    end
                end
            end
        end

        if not shown then
            if overlay then
                overlay:Hide()
            end
            self:SetReagentNameReserved(row, 0)
        end
    end
end

function RB:UpdateProfessionPanelHeight()
    local panel = self.tradeSkillPanel
    if not panel or not self.tradeSkillStatsText then
        return
    end

    local textHeight = 0
    if self.tradeSkillStatsText.GetStringHeight then
        textHeight = tonumber(self.tradeSkillStatsText:GetStringHeight()) or 0
    end

    -- GetStringHeight is the only wrap-aware measure available, but it reports a
    -- single line on some clients. Counting the explicit line breaks gives a
    -- floor so a long plan never spills past the panel border.
    local lineCount = 1
    for _ in string.gmatch(self.tradeSkillStatsText:GetText() or "", "\n") do
        lineCount = lineCount + 1
    end
    textHeight = math.max(textHeight, lineCount * 14)

    local noteHeight = 0
    if panel.craftNote and panel.craftNote.GetStringHeight then
        noteHeight = tonumber(panel.craftNote:GetStringHeight()) or 0
    end

    local height = PROFESSION_PANEL_NOTE_TOP + noteHeight + 10 + textHeight + 14
    panel:SetHeight(Clamp(height, PROFESSION_PANEL_MIN_HEIGHT, PROFESSION_PANEL_MAX_HEIGHT))
end

function RB:SetProfessionCraftableStat(value, label, note, r, g, b)
    local panel = self.tradeSkillPanel
    if not panel then
        return
    end

    if panel.craftValue then
        panel.craftValue:SetText(tostring(value or "-"))
        panel.craftValue:SetTextColor(r or 1.00, g or 0.82, b or 0.28)
    end

    if panel.craftLabel then
        panel.craftLabel:SetText(label or "")
    end

    if panel.craftNote then
        panel.craftNote:SetText(note or "")
    end
end

function RB:UpdateTradeSkillStatsText()
    if not self.tradeSkillStatsText then
        return
    end

    local reagents, errText, recipeName, repeatCount = self:GetSelectedTradeSkillReagents()

    if errText then
        self:SetProfessionCraftableStat("-", "", "", 0.62, 0.65, 0.70)
        self.tradeSkillStatsText:SetText(ColorText(errText, TEXT_DIM))
        self.tradeSkillStatsText:Show()
        self:UpdateProfessionPanelHeight()
        return
    end

    if not reagents or #reagents == 0 then
        self:SetProfessionCraftableStat("-", "", "", 0.62, 0.65, 0.70)
        self.tradeSkillStatsText:SetText(ColorText("This recipe has no tracked reagents.", TEXT_DIM))
        self.tradeSkillStatsText:Show()
        self:UpdateProfessionPanelHeight()
        return
    end

    repeatCount = self:ClampTradeSkillPrepareCount(repeatCount or 1)

    local plan = self:BuildTradeSkillShoppingPlan(reagents, repeatCount, self:GetLowStockCraftCount())
    local craftability = self:GetTradeSkillCraftability(reagents, repeatCount)
    local bags = craftability and tonumber(craftability.bagCrafts) or 0

    if craftability and craftability.bankReady then
        local combined = tonumber(craftability.combinedCrafts) or bags
        local note

        if combined > bags then
            note = "bags cover " .. tostring(bags) .. ", the bank adds " .. tostring(combined - bags) .. "."
        elseif combined > 0 then
            note = "all from bags, the bank adds nothing."
        else
            note = "bags and bank together are short a reagent."
        end

        if combined > 0 then
            self:SetProfessionCraftableStat(combined, "craftable", note, 0.48, 0.92, 0.48)
        else
            self:SetProfessionCraftableStat(0, "craftable", note, 1.00, 0.42, 0.37)
        end
    else
        self:SetProfessionCraftableStat(bags, "from bags", "Reading reagent bank stock...", 1.00, 0.82, 0.28)
    end

    local lines = {}

    local function AddBlock(heading, body, color)
        table.insert(lines, ColorText(heading, color) .. "  " .. tostring(body or ""))
    end

    local countText = "x" .. tostring(repeatCount)

    if not plan.bankReady then
        if #plan.needs > 0 then
            AddBlock("Short " .. countText,
                self:FormatTradeSkillPlanItems(plan.needs, PROFESSION_PANEL_ITEM_LIMIT), TEXT_WARN)
        else
            AddBlock("Ready " .. countText, "bags already cover this craft.", TEXT_GOOD)
        end
    elseif #plan.withdraw > 0 then
        AddBlock("Withdraw " .. countText,
            self:FormatTradeSkillPlanItems(plan.withdraw, PROFESSION_PANEL_ITEM_LIMIT), TEXT_GOOD)
    elseif #plan.needs == 0 then
        AddBlock("Ready " .. countText, "bags already cover this craft.", TEXT_GOOD)
    else
        AddBlock("Short " .. countText, "the reagent bank cannot cover it.", TEXT_BAD)
    end

    if plan.bankReady and #plan.missing > 0 then
        AddBlock("Buy",
            self:FormatTradeSkillPlanItems(plan.missing, PROFESSION_PANEL_ITEM_LIMIT), TEXT_BAD)
    end

    if plan.bankReady and #plan.lowStock > 0 then
        AddBlock("Low under x" .. tostring(plan.lowStockCrafts),
            self:FormatTradeSkillPlanItems(plan.lowStock, PROFESSION_PANEL_ITEM_LIMIT), TEXT_WARN)
    end

    self.tradeSkillStatsText:SetText(table.concat(lines, "\n"))
    self.tradeSkillStatsText:Show()
    self:UpdateProfessionPanelHeight()
end

function RB:PrintTradeSkillShoppingList()
    local reagents, errText, recipeName, repeatCount = self:GetSelectedTradeSkillReagents()

    if errText then
        PrintAddon(errText)
        return false
    end

    if not reagents or #reagents == 0 then
        PrintAddon("No reagent plan needed for the selected recipe.")
        return true
    end

    repeatCount = self:ClampTradeSkillPrepareCount(repeatCount or 1)
    local plan = self:BuildTradeSkillShoppingPlan(reagents, repeatCount, self:GetLowStockCraftCount())

    PrintAddon("shopping list for " .. tostring(repeatCount) .. " craft(s) of " .. tostring(recipeName or "selected recipe") .. ":")

    if not plan.bankReady then
        if #plan.needs > 0 then
            PrintAddon("bag needs: " .. self:FormatTradeSkillPlanItems(plan.needs, 10))
        else
            PrintAddon("bags already cover this recipe.")
        end
        PrintAddon("checking reagent bank stock; run /rbank plan again in a moment.")
        return true
    end

    if #plan.withdraw > 0 then
        PrintAddon("withdraw: " .. self:FormatTradeSkillPlanItems(plan.withdraw, 10))
    elseif #plan.needs == 0 then
        PrintAddon("bags already cover this recipe.")
    else
        PrintAddon("nothing withdrawable in bank for the missing bag reagents.")
    end

    if #plan.missing > 0 then
        PrintAddon("missing after bank: " .. self:FormatTradeSkillPlanItems(plan.missing, 10))
    else
        PrintAddon("bank covers the missing bag reagents.")
    end

    if #plan.lowStock > 0 then
        PrintAddon("low stock below " .. tostring(plan.lowStockCrafts) .. " craft(s): " .. self:FormatTradeSkillPlanItems(plan.lowStock, 10))
    end

    return true
end

function RB:GetSelectedTradeSkillNeeds()
    local reagents, errText, recipeName, repeatCount = self:GetSelectedTradeSkillReagents()
    if errText then
        return nil, errText, recipeName, repeatCount
    end

    repeatCount = self:ClampTradeSkillPrepareCount(repeatCount or 1)

    if not reagents or #reagents == 0 then
        return {}, nil, recipeName, repeatCount
    end

    local needs = {}
    for _, reagent in ipairs(reagents) do
        local itemEntry = tonumber(reagent.itemEntry or reagent.entry)
        local requiredPerCraft = tonumber(reagent.requiredPerCraft) or 0
        local bagCount = 0

        if itemEntry and GetItemCount then
            bagCount = tonumber(GetItemCount(itemEntry, false)) or 0
        end

        if bagCount <= 0 and reagent.bagCount then
            bagCount = tonumber(reagent.bagCount) or 0
        end

        local missing = (requiredPerCraft * repeatCount) - bagCount
        if itemEntry and itemEntry > 0 and missing > 0 then
            table.insert(needs, {
                itemEntry = itemEntry,
                entry = itemEntry,
                amount = math.floor(missing),
                name = reagent.name or ("Item #" .. tostring(itemEntry)),
            })
        end
    end

    return needs, nil, recipeName, repeatCount
end

function RB:BuildItemAmountCommand(prefix, items)
    local commands = self:BuildItemAmountCommands(prefix, items, 999)
    return commands[1] or prefix
end

function RB:NormalizeTransactionAction(action)
    action = string.lower(tostring(action or ""))

    if action == "deposit" or action == "withdraw" then
        return action
    end

    return nil
end

function RB:BuildTransactionSummary(transaction)
    if not transaction or not transaction.action or not transaction.items or #transaction.items == 0 then
        return "No reversible transaction is available."
    end

    local total = tonumber(transaction.total) or 0
    if total <= 0 then
        for _, item in ipairs(transaction.items) do
            total = total + (tonumber(item.amount) or 0)
        end
    end

    local verb = transaction.action == "deposit" and "Deposited" or "Withdrew"
    return "Last: " .. verb .. " " .. FormatCount(total) .. " reagent(s) across " .. tostring(#transaction.items) .. " item type(s)."
end

function RB:GetTransactionTotal(transaction)
    local total = tonumber(transaction and transaction.total) or 0

    if total > 0 then
        return total
    end

    for _, item in ipairs((transaction and transaction.items) or {}) do
        total = total + (tonumber(item.amount) or 0)
    end

    return total
end

function RB:BuildTransactionItemChatList(transaction, limit)
    if not transaction or not transaction.items or #transaction.items == 0 then
        return ""
    end

    limit = math.max(1, tonumber(limit) or TRANSACTION_CHAT_ITEM_LIMIT)

    local items = {}
    for _, item in ipairs(transaction.items) do
        local itemEntry = tonumber(item.entry)
        local amount = tonumber(item.amount) or 0

        if itemEntry and itemEntry > 0 and amount > 0 then
            local icon, name, link = GetItemDisplay(itemEntry)
            table.insert(items, {
                entry = itemEntry,
                amount = math.floor(amount),
                name = name or ("Item #" .. tostring(itemEntry)),
                text = BuildItemAmountChatText(itemEntry, amount),
            })
        end
    end

    table.sort(items, function(a, b)
        local an = string.lower(tostring(a.name or ""))
        local bn = string.lower(tostring(b.name or ""))
        if an == bn then
            return (tonumber(a.entry) or 0) < (tonumber(b.entry) or 0)
        end
        return an < bn
    end)

    local pieces = {}
    local shown = math.min(#items, limit)
    for index = 1, shown do
        table.insert(pieces, items[index].text)
    end

    if #items > shown then
        table.insert(pieces, "+" .. tostring(#items - shown) .. " more")
    end

    return table.concat(pieces, ", ")
end

function RB:GetDepositChatPrefix(transaction)
    local source = SafeTransactionSource(transaction and transaction.source)

    if source == "profession" then
        return "Profession leftovers auto-deposited"
    elseif source == "auto" then
        return "Auto-deposited"
    elseif source == "reverse" then
        return "Undo deposited"
    end

    return "Deposited"
end

function RB:PrintDepositTransactionMessage(transaction)
    if not transaction or transaction.action ~= "deposit" or not transaction.items or #transaction.items == 0 then
        return
    end

    local total = self:GetTransactionTotal(transaction)
    if total <= 0 then
        return
    end

    local detailText = self:BuildTransactionItemChatList(transaction, TRANSACTION_CHAT_ITEM_LIMIT)
    local prefix = self:GetDepositChatPrefix(transaction)
    local message = prefix .. " " .. FormatCount(total) .. " reagent(s)"

    if detailText ~= "" then
        message = message .. ": " .. detailText
    end

    message = message .. "."
    PrintAddon(message)

    if self.frame and self.frame:IsShown() then
        self:Status(message, 0.45, 1.00, 0.45)
    end
end

function RB:GetReverseTransactionLabel(transaction)
    if not transaction or not transaction.action then
        return "Reverse Last"
    end

    if transaction.action == "deposit" then
        return "Undo Deposit"
    elseif transaction.action == "withdraw" then
        return "Undo Withdraw"
    end

    return "Reverse Last"
end

function RB:UpdateUndoButton()
    if not self.frame or not self.frame.undoLast then
        return
    end

    local transaction = self.lastTransaction
    local canReverse = transaction and transaction.items and #transaction.items > 0

    self.frame.undoLast:SetText(self:GetReverseTransactionLabel(transaction))
    self.frame.undoLast.tooltipText = canReverse and self:BuildTransactionSummary(transaction) or "No reversible deposit or withdraw transaction has been seen yet."
    self:SetButtonEnabled(self.frame.undoLast, canReverse and self.busyKind == nil)
end

function RB:MergeTransactionIntoCollector(transaction)
    if not transaction or not self.reverseCollector then
        return false
    end

    local collector = self.reverseCollector
    collector.action = transaction.action
    collector.itemsByEntry = collector.itemsByEntry or {}

    for _, item in ipairs(transaction.items or {}) do
        local itemEntry = tonumber(item.entry)
        local amount = tonumber(item.amount) or 0
        if itemEntry and itemEntry > 0 and amount > 0 then
            collector.itemsByEntry[itemEntry] = (collector.itemsByEntry[itemEntry] or 0) + amount
            collector.total = (collector.total or 0) + amount
        end
    end

    collector.remaining = math.max((collector.remaining or 1) - 1, 0)

    if collector.remaining <= 0 then
        local items = {}
        for itemEntry, amount in pairs(collector.itemsByEntry) do
            table.insert(items, {
                entry = tonumber(itemEntry),
                amount = tonumber(amount) or 0,
            })
        end

        table.sort(items, function(a, b)
            return (tonumber(a.entry) or 0) < (tonumber(b.entry) or 0)
        end)

        self.lastTransaction = {
            action = collector.action,
            source = "reverse",
            total = collector.total or 0,
            items = items,
            updatedAt = GetTime(),
        }
        self.reverseCollector = nil
        self:PrintDepositTransactionMessage(self.lastTransaction)
        self:UpdateUndoButton()
        return true
    end

    return true
end

function RB:FinalizeTransaction(transaction)
    if not transaction or not transaction.action or not transaction.items or #transaction.items == 0 then
        return
    end

    self:ApplyBankCountTransaction(transaction)

    if self.reverseCollector and self:MergeTransactionIntoCollector(transaction) then
        return
    end

    transaction.updatedAt = GetTime()
    self.lastTransaction = transaction
    self:PrintDepositTransactionMessage(transaction)
    self:UpdateUndoButton()

    if self.frame and self.frame:IsShown() then
        self:ScheduleCurrentRefresh(MUTATION_REFRESH_DELAY)
    end
end

function RB:ReverseLastTransaction()
    local transaction = self.lastTransaction
    if not transaction or not transaction.items or #transaction.items == 0 then
        self:Status("No reversible transaction is available.", 1.00, 0.82, 0.32)
        return
    end

    local prefix = nil
    local reverseAction = nil

    if transaction.action == "deposit" then
        prefix = "withdraw needed"
        reverseAction = "withdraw"
    elseif transaction.action == "withdraw" then
        prefix = "deposit items"
        reverseAction = "deposit"
    end

    if not prefix then
        self:Status("This transaction cannot be reversed.", 1.00, 0.82, 0.32)
        return
    end

    local commands = self:BuildItemAmountCommands(prefix, transaction.items, TRANSACTION_MAX_PAIRS_PER_COMMAND)
    if #commands == 0 then
        self:Status("No reversible item amounts were found.", 1.00, 0.82, 0.32)
        return
    end

    self.reverseCollector = {
        action = reverseAction,
        remaining = #commands,
        total = 0,
        itemsByEntry = {},
    }

    if reverseAction == "withdraw" then
        end

    self.mutationNeedsRefresh = self.currentView == "category" and "category" or "root"
    self:BeginBusy("mutation", "Reversing last reagent bank action...")

    for _, command in ipairs(commands) do
        self:SendServerCommand(command, { action = reverseAction, source = "reverse" })
    end

    self:ScheduleCurrentRefresh(MUTATION_REFRESH_DELAY)
end

function RB:ArmAutoDepositLeftovers(needs, recipeName, repeatCount)
    ReagentBankUIDB = ReagentBankUIDB or {}

    if not ReagentBankUIDB.autoDepositLeftovers then
        self.pendingAutoDepositLeftovers = nil
        self.pendingAutoDepositAt = nil
        return
    end

    if not needs or #needs == 0 then
        return
    end

    local pending = self.pendingAutoDepositLeftovers
    if not pending then
        pending = {
            itemsByEntry = {},
            recipeNames = {},
            firstArmedAt = GetTime(),
        }
        self.pendingAutoDepositLeftovers = pending
    end

    pending.expiresAt = GetTime() + AUTO_DEPOSIT_PREP_EXPIRE_SECONDS

    if recipeName and recipeName ~= "" then
        pending.recipeNames[tostring(recipeName)] = true
    end

    for _, need in ipairs(needs) do
        local itemEntry = tonumber(need.itemEntry or need.entry)
        if itemEntry and itemEntry > 0 then
            local key = tostring(itemEntry)
            if not pending.itemsByEntry[key] then
                pending.itemsByEntry[key] = {
                    itemEntry = itemEntry,
                    baseline = GetItemCount(itemEntry, false) or 0,
                }
            end
        end
    end

    PrintAddon(
        "Auto-deposit armed for profession window close" ..
        " (" .. tostring(repeatCount or 1) .. " prepared craft(s))."
    )
end

function RB:BuildPreparedLeftoverItems(pending)
    local items = {}

    if not pending or not pending.itemsByEntry then
        return items
    end

    for _, info in pairs(pending.itemsByEntry) do
        local itemEntry = tonumber(info.itemEntry)
        local baseline = tonumber(info.baseline) or 0

        if itemEntry and itemEntry > 0 then
            local current = GetItemCount(itemEntry, false) or 0
            local leftover = current - baseline

            if leftover > 0 then
                table.insert(items, {
                    entry = itemEntry,
                    amount = math.floor(leftover),
                })
            end
        end
    end

    table.sort(items, function(a, b)
        return (tonumber(a.entry) or 0) < (tonumber(b.entry) or 0)
    end)

    return items
end

function RB:WithdrawNeededForSelectedRecipe()
    local needs, errText, recipeName, repeatCount = self:GetSelectedTradeSkillNeeds()
    repeatCount = self:ClampTradeSkillPrepareCount(repeatCount or 1)

    if errText then
        PrintAddon(errText)
        self:Status(errText, 1.00, 0.82, 0.32)
        return
    end

    self:SetTradeSkillPrepareCount(repeatCount, true)

    if not needs or #needs == 0 then
        local message = "You already have the selected recipe reagents in your bags for " .. tostring(repeatCount) .. " craft(s)."
        PrintAddon(message)
        self:Status(message, 0.45, 1.00, 0.45)
        return
    end

    self:ArmAutoDepositLeftovers(needs, recipeName, repeatCount)

    self:SendItemAmountCommands("withdraw needed", needs, TRANSACTION_MAX_PAIRS_PER_COMMAND)

    local total = 0
    for _, need in ipairs(needs) do
        total = total + (tonumber(need.amount) or 0)
    end

    PrintAddon(
        "Requested " .. tostring(total) .. " reagent(s) for " ..
        tostring(repeatCount) .. " craft(s) of " .. tostring(recipeName or "selected recipe") .. "."
    )

    self:UpdateTradeSkillControls()
end

function RB:DepositPreparedLeftovers()
    local pending = self.pendingAutoDepositLeftovers
    self.pendingAutoDepositLeftovers = nil
    self.pendingAutoDepositAt = nil

    local items = self:BuildPreparedLeftoverItems(pending)
    if not items or #items == 0 then
        if pending then
            PrintAddon("No prepared reagent leftovers to auto-deposit.")
        end
        return
    end

    self:SendItemAmountCommands(
        "deposit items",
        items,
        TRANSACTION_MAX_PAIRS_PER_COMMAND,
        { action = "deposit", source = "profession" }
    )

    PrintAddon("Auto-depositing prepared reagent leftovers after closing the profession window.")
end

function RB:HandleTradeSkillClosed()
    self:UpdateTradeSkillControls()
    self:ResumeAutoDepositTickerAfterProfession()

    local pending = self.pendingAutoDepositLeftovers
    if not pending then
        return
    end

    if pending.expiresAt and GetTime() > pending.expiresAt then
        self.pendingAutoDepositLeftovers = nil
        self.pendingAutoDepositAt = nil
        PrintAddon("Prepared reagent auto-deposit expired.")
        return
    end

    self.pendingAutoDepositAt = GetTime() + AUTO_DEPOSIT_AFTER_CLOSE_DELAY
    self:EnsureOnUpdate()
end

function RB:Toggle()
    self:CreateFrame()

    if self.frame:IsShown() then
        self:Close()
        return
    end

    self.frame:Show()
    self:RequestRoot()
end

function RB:PositionPaperDollButton()
    if not self.paperDollButton then
        return
    end

    local dock = EnsurePaperDollLauncherDock()
    dock:Register("ReagentBankUI", self.paperDollButton, 20)
end

-- Settings live in the standard Interface Options window, under AddOns.
function RB:CreateSettingsPanel()
    if self.settingsPanel then
        return
    end

    local panel = CreateFrame("Frame", "ReagentBankUISettingsPanel", UIParent)
    panel.name = "Reagent Bank"
    panel:Hide()

    panel.title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    panel.title:SetPoint("TOPLEFT", 16, -16)
    panel.title:SetJustifyH("LEFT")
    panel.title:SetText("Reagent Bank")

    panel.note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panel.note:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -8)
    panel.note:SetPoint("RIGHT", -32, 0)
    panel.note:SetJustifyH("LEFT")
    panel.note:SetText("Settings are saved per account.")

    local slider = CreateFrame("Slider", "ReagentBankUIScaleSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", panel.note, "BOTTOMLEFT", 2, -34)
    slider:SetWidth(200)
    slider:SetMinMaxValues(0.75, 1.20)
    slider:SetValueStep(0.05)
    _G[slider:GetName() .. "Low"]:SetText("75%")
    _G[slider:GetName() .. "High"]:SetText("120%")
    slider:SetScript("OnValueChanged", function(_, value)
        if RB.updatingSettingsPanel then
            return
        end
        RB:SetScaleValue(value, true)
    end)
    panel.scaleSlider = slider
    panel.scaleText = _G[slider:GetName() .. "Text"]

    panel.resetWindow = self:CreateButton(panel, 128, 22, "Reset Window")
    panel.resetWindow:SetPoint("LEFT", slider, "RIGHT", 24, 0)
    panel.resetWindow:SetScript("OnClick", function()
        RB:ResetWindowPosition()
    end)

    panel.autoDepositHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    panel.autoDepositHeader:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", -2, -34)
    panel.autoDepositHeader:SetJustifyH("LEFT")
    panel.autoDepositHeader:SetText("Periodic auto-deposit")

    panel.autoDepositNote = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panel.autoDepositNote:SetPoint("TOPLEFT", panel.autoDepositHeader, "BOTTOMLEFT", 0, -6)
    panel.autoDepositNote:SetPoint("RIGHT", -32, 0)
    panel.autoDepositNote:SetJustifyH("LEFT")
    panel.autoDepositNote:SetText("Runs Deposit All on a timer while you are online. Enter 0 to disable. Minimum: 30 seconds.")

    panel.autoDepositLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    panel.autoDepositLabel:SetPoint("TOPLEFT", panel.autoDepositNote, "BOTTOMLEFT", 0, -16)
    panel.autoDepositLabel:SetJustifyH("LEFT")
    panel.autoDepositLabel:SetText("Every")

    panel.autoDepositIntervalBox = self:CreateEditBox(panel, 66, 20)
    panel.autoDepositIntervalBox:SetPoint("LEFT", panel.autoDepositLabel, "RIGHT", 12, 0)
    panel.autoDepositIntervalBox:SetScript("OnEnterPressed", function(selfBox)
        RB:ApplyAutoDepositTickerBox()
        selfBox:ClearFocus()
    end)
    panel.autoDepositIntervalBox:SetScript("OnEscapePressed", function(selfBox)
        RB:UpdateAutoDepositTickerControls()
        selfBox:ClearFocus()
    end)
    panel.autoDepositIntervalBox:SetScript("OnTextChanged", nil)

    panel.autoDepositSecondsText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    panel.autoDepositSecondsText:SetPoint("LEFT", panel.autoDepositIntervalBox, "RIGHT", 10, 0)
    panel.autoDepositSecondsText:SetText("seconds")

    panel.autoDepositApply = self:CreateButton(panel, 80, 22, "Apply")
    panel.autoDepositApply:SetPoint("LEFT", panel.autoDepositSecondsText, "RIGHT", 12, 0)
    panel.autoDepositApply:SetScript("OnClick", function()
        RB:ApplyAutoDepositTickerBox()
    end)

    panel.autoDepositOff = self:CreateButton(panel, 80, 22, "Off")
    panel.autoDepositOff:SetPoint("LEFT", panel.autoDepositApply, "RIGHT", 6, 0)
    panel.autoDepositOff:SetScript("OnClick", function()
        RB:SetAutoDepositTickerSeconds(0)
    end)

    panel.autoDepositStatus = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    panel.autoDepositStatus:SetPoint("TOPLEFT", panel.autoDepositLabel, "BOTTOMLEFT", 0, -16)
    panel.autoDepositStatus:SetPoint("RIGHT", -32, 0)
    panel.autoDepositStatus:SetJustifyH("LEFT")
    panel.autoDepositStatus:SetText("")

    panel:SetScript("OnShow", function()
        RB:UpdateSettingsPanel()
    end)

    self.settingsPanel = panel
    InterfaceOptions_AddCategory(panel)
end

function RB:UpdateSettingsPanel()
    local panel = self.settingsPanel
    if not panel then
        return
    end

    ReagentBankUIDB = ReagentBankUIDB or {}
    local scale = Clamp(ReagentBankUIDB.scale or DEFAULT_SCALE, 0.75, 1.20)

    self.updatingSettingsPanel = true
    panel.scaleSlider:SetValue(scale)
    self.updatingSettingsPanel = nil
    panel.scaleText:SetText("Window Scale: " .. tostring(math.floor((scale * 100) + 0.5)) .. "%")

    self:UpdateAutoDepositTickerControls()
end

function RB:OpenSettings()
    self:CreateSettingsPanel()

    -- The 3.3.5 options frame ignores the category the first time it opens,
    -- so it is asked twice.
    InterfaceOptionsFrame_OpenToCategory(self.settingsPanel)
    InterfaceOptionsFrame_OpenToCategory(self.settingsPanel)
end

function RB:ResetWindowPosition()
    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.point = nil
    ReagentBankUIDB.relativePoint = nil
    ReagentBankUIDB.xOfs = nil
    ReagentBankUIDB.yOfs = nil
    self:SetScaleValue(DEFAULT_SCALE, true)
    if self.frame then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    self:Status("Window position and scale reset.", 0.82, 0.82, 0.82)
end
function RB:CreatePaperDollButton()
    if self.paperDollButton or not PAPERDOLL_BUTTON_ENABLED then
        return
    end

    local dock = EnsurePaperDollLauncherDock()
    local parent = dock:GetParentFrame()

    local button = CreateFrame("Button", "ReagentBankUIPaperDollButton", parent)
    button:SetWidth(PAPERDOLL_BUTTON_SIZE)
    button:SetHeight(PAPERDOLL_BUTTON_SIZE)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetFrameLevel((parent:GetFrameLevel() or 1) + 12)

    -- Dark circular background, matching the AH button style.
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(PAPERDOLL_BUTTON_BG_TEXTURE)
    bg:SetWidth(PAPERDOLL_BUTTON_BG_SIZE)
    bg:SetHeight(PAPERDOLL_BUTTON_BG_SIZE)
    bg:SetPoint("CENTER", button, "CENTER", 0, 0)
    bg:SetVertexColor(
        PAPERDOLL_BUTTON_BG_R,
        PAPERDOLL_BUTTON_BG_G,
        PAPERDOLL_BUTTON_BG_B,
        PAPERDOLL_BUTTON_BG_A
    )
    button.bg = bg

    -- Inner icon.
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(PAPERDOLL_BUTTON_ICON)
    icon:SetWidth(PAPERDOLL_BUTTON_ICON_SIZE)
    icon:SetHeight(PAPERDOLL_BUTTON_ICON_SIZE)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetTexCoord(
        PAPERDOLL_BUTTON_ICON_CROP,
        1 - PAPERDOLL_BUTTON_ICON_CROP,
        PAPERDOLL_BUTTON_ICON_CROP,
        1 - PAPERDOLL_BUTTON_ICON_CROP
    )
    button.icon = icon

    -- Circular border ring.
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture(PAPERDOLL_BUTTON_BORDER_TEXTURE)
    border:SetWidth(PAPERDOLL_BUTTON_BORDER_SIZE)
    border:SetHeight(PAPERDOLL_BUTTON_BORDER_SIZE)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button.border = border

    -- Mouseover glow.
    button:SetHighlightTexture(PAPERDOLL_BUTTON_HIGHLIGHT_TEXTURE)
    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetBlendMode("ADD")
        highlight:SetWidth(PAPERDOLL_BUTTON_HIGHLIGHT_SIZE)
        highlight:SetHeight(PAPERDOLL_BUTTON_HIGHLIGHT_SIZE)
        highlight:ClearAllPoints()
        highlight:SetPoint("CENTER", button, "CENTER", 0, 0)
    end

    button:SetScript("OnMouseDown", function(selfButton)
        selfButton.bg:ClearAllPoints()
        selfButton.bg:SetPoint("CENTER", selfButton, "CENTER", 1, -1)

        selfButton.icon:ClearAllPoints()
        selfButton.icon:SetPoint("CENTER", selfButton, "CENTER", 1, -1)
    end)

    button:SetScript("OnMouseUp", function(selfButton)
        selfButton.bg:ClearAllPoints()
        selfButton.bg:SetPoint("CENTER", selfButton, "CENTER", 0, 0)

        selfButton.icon:ClearAllPoints()
        selfButton.icon:SetPoint("CENTER", selfButton, "CENTER", 0, 0)
    end)

    button:SetScript("OnClick", function(selfButton, mouseButton)
        if IsControlKeyDown and IsControlKeyDown() then
            RB:OpenSettings()
            return
        end

        if mouseButton == "RightButton" then
            RB:CreateFrame()
            RB.frame:Show()
            RB:RequestRoot()
            return
        end

        RB:Toggle()
    end)

    button:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reagent Bank", 1, 0.82, 0)
        GameTooltip:AddLine("Left-click: open or close.", 1, 1, 1)
        GameTooltip:AddLine("Right-click: refresh categories.", 0.82, 0.82, 0.82)
        GameTooltip:AddLine("Ctrl-click: settings.", 0.62, 0.88, 1.00)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", HideTooltip)

    self.paperDollButton = button
    self:PositionPaperDollButton()

    -- If the AH button addon loads after this addon, retry for a few seconds
    -- and then snap to the right of PaperDollAHButton as soon as it exists.
    button.positionElapsed = 0
    button.positionAttempts = 0
    button:SetScript("OnUpdate", function(selfButton, elapsed)
        selfButton.positionElapsed = (selfButton.positionElapsed or 0) + elapsed
        if selfButton.positionElapsed < 0.25 then
            return
        end

        selfButton.positionElapsed = 0
        selfButton.positionAttempts = (selfButton.positionAttempts or 0) + 1

        RB:PositionPaperDollButton()

        if _G[PAPERDOLL_ANCHOR_BUTTON_NAME] or selfButton.positionAttempts >= 40 then
            selfButton:SetScript("OnUpdate", nil)
        end
    end)

    if parent.HookScript and not parent.ReagentBankUIPositionHooked then
        parent:HookScript("OnShow", function()
            RB:CreatePaperDollButton()
            RB:PositionPaperDollButton()
        end)
        parent.ReagentBankUIPositionHooked = true
    end
end

function RB:UpdateTradeSkillControls()
    if not self.tradeSkillButton then
        return
    end

    ReagentBankUIDB = ReagentBankUIDB or {}

    local needs, errText, recipeName, repeatCount = self:GetSelectedTradeSkillNeeds()
    repeatCount = self:ClampTradeSkillPrepareCount(repeatCount or 1)

    local enabled = errText == nil

    self:SetButtonEnabled(self.tradeSkillButton, enabled)
    self:SetButtonEnabled(self.tradeSkillMinusButton, repeatCount > TRADE_SKILL_PREPARE_COUNT_MIN)
    self:SetButtonEnabled(self.tradeSkillPlusButton, repeatCount < TRADE_SKILL_PREPARE_COUNT_MAX)

    if self.tradeSkillPresetButtons then
        for _, presetButton in ipairs(self.tradeSkillPresetButtons) do
            self:SetButtonEnabled(presetButton, enabled)
        end
    end

    if self.tradeSkillMaxButton then
        local maxCrafts = enabled and self:GetMaxCraftableCount() or nil

        self:SetButtonEnabled(self.tradeSkillMaxButton, maxCrafts ~= nil)

        if maxCrafts then
            self.tradeSkillMaxButton.tooltipText =
                "Prepare " .. tostring(maxCrafts) .. " craft(s), everything your bags and reagent bank cover between them."
        elseif enabled then
            self.tradeSkillMaxButton.tooltipText =
                "Waiting on reagent bank counts, or no reagent is stocked well enough for a full craft."
        else
            self.tradeSkillMaxButton.tooltipText = errText or "Select a recipe first."
        end
    end

    local shoppingPending = self.pendingShoppingListImport ~= nil
    if shoppingPending and self.pendingShoppingListImport.createdAt and GetTime() - self.pendingShoppingListImport.createdAt > SHOPPING_LIST_IMPORT_TIMEOUT then
        self.pendingShoppingListImport = nil
        shoppingPending = false
    end

    local shoppingEnabled = enabled and needs and #needs > 0 and not shoppingPending
    self:SetButtonEnabled(self.tradeSkillShoppingButton, shoppingEnabled)

    if self.tradeSkillShoppingButton then
        if shoppingPending then
            self.tradeSkillShoppingButton:SetText("Adding...")
            self.tradeSkillShoppingButton.tooltipText = "Waiting for reagent bank counts, then missing AH reagents will be added to your shopping list."
        else
            self.tradeSkillShoppingButton:SetText("Add to AH List")
            if errText then
                self.tradeSkillShoppingButton.tooltipText = errText
            elseif needs and #needs > 0 then
                self.tradeSkillShoppingButton.tooltipText =
                    "Add reagents for " .. tostring(repeatCount) .. " craft(s) of " .. tostring(recipeName or "selected recipe") ..
                    " that your bags and reagent bank cannot cover."
            else
                self.tradeSkillShoppingButton.tooltipText =
                    "You already have the selected recipe reagents in your bags for " .. tostring(repeatCount) .. " craft(s)."
            end
        end
    end

    if self.tradeSkillQuantityBox and not self.tradeSkillQuantityBox:HasFocus() then
        local textValue = tostring(repeatCount)
        if self.tradeSkillQuantityBox:GetText() ~= textValue then
            self.suppressTradeSkillQuantityChanged = true
            self.tradeSkillQuantityBox:SetText(textValue)
            self.suppressTradeSkillQuantityChanged = nil
        end
    end

    if needs and #needs > 0 then
        local total = 0
        for _, need in ipairs(needs) do
            total = total + (tonumber(need.amount) or 0)
        end

        if repeatCount > 1 then
            self.tradeSkillButton:SetText("Withdraw x" .. tostring(repeatCount))
            self.tradeSkillButton.tooltipText =
                "Prepare " .. tostring(repeatCount) .. " craft(s) of " .. tostring(recipeName or "selected recipe") ..
                " by withdrawing " .. tostring(total) .. " missing reagent(s)."
        else
            self.tradeSkillButton:SetText("Withdraw Needed")
            self.tradeSkillButton.tooltipText =
                "Withdraw " .. tostring(total) .. " missing reagent(s) for " .. tostring(recipeName or "selected recipe") .. "."
        end
    else
        if repeatCount > 1 then
            self.tradeSkillButton:SetText("Ready x" .. tostring(repeatCount))
        else
            self.tradeSkillButton:SetText("Withdraw Needed")
        end

        if errText then
            self.tradeSkillButton.tooltipText = errText
        else
            self.tradeSkillButton.tooltipText =
                "You already have the selected recipe reagents in your bags for " .. tostring(repeatCount) .. " craft(s)."
        end
    end

    if self.tradeSkillAutoDepositCheck then
        self.tradeSkillAutoDepositCheck:SetChecked(ReagentBankUIDB.autoDepositLeftovers and true or false)
    end

    self:UpdateTradeSkillStatsText()
    self:UpdateReagentBankOverlays()
end

-- The sidebar sits on the Blizzard trade skill window or on a registered
-- provider's window, whichever is open. It is only re-docked when its host
-- changes, so a panel the player dragged stays put while that window is open.
function RB:GetTradeSkillControlsHost()
    local provider = self:GetActiveRecipeProvider()
    return provider and provider.frame or _G.TradeSkillFrame
end

function RB:AttachTradeSkillControls()
    local panel = self.tradeSkillPanel
    local host = self:GetTradeSkillControlsHost()
    if not panel or not host or panel:GetParent() == host then
        return
    end

    panel:SetParent(host)
    panel:SetFrameLevel((host:GetFrameLevel() or 1) + 5)
    self:DockTradeSkillPanel()
end

function RB:CreateTradeSkillControls()
    if self.tradeSkillPanel then
        self:AttachTradeSkillControls()
        self:UpdateTradeSkillControls()
        return
    end

    local parent = self:GetTradeSkillControlsHost()
    if not parent then
        return
    end

    -- Everything lives in one bordered sidebar docked to the profession window.
    -- The controls used to chain off TradeSkillCreateButton, which pushed them
    -- past the frame edge and left the summary text a column too narrow to read.
    local panel = CreateFrame("Frame", "ReagentBankUIProfessionPanel", parent)
    panel:SetWidth(PROFESSION_PANEL_WIDTH)
    panel:SetHeight(PROFESSION_PANEL_MIN_HEIGHT)
    panel:SetPoint("TOPLEFT", parent, "TOPRIGHT", PROFESSION_PANEL_X, PROFESSION_PANEL_Y)
    panel:SetFrameLevel((parent:GetFrameLevel() or 1) + 5)
    panel:EnableMouse(true)
    -- Dragging and closing only last until the profession window closes;
    -- DockTradeSkillPanel puts it back beside the frame on the next open.
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(selfPanel)
        selfPanel:StartMoving()
    end)
    panel:SetScript("OnDragStop", function(selfPanel)
        selfPanel:StopMovingOrSizing()
    end)
    self:MakeBackdrop(panel)
    self.tradeSkillPanel = panel

    local inset = PROFESSION_PANEL_PADDING
    local contentWidth = PROFESSION_PANEL_WIDTH - (inset * 2)

    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.title:SetPoint("TOPLEFT", inset, -16)
    panel.title:SetJustifyH("LEFT")
    panel.title:SetText("Reagent Bank")

    panel.close = self:CreateCloseButton(panel)
    panel.close:SetPoint("TOPRIGHT", -4, -4)
    panel.close:SetScript("OnClick", function()
        panel:Hide()
    end)
    panel.close:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Hide Reagent Bank", 1, 0.82, 0)
        GameTooltip:AddLine("Comes back the next time you open a profession.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    panel.close:SetScript("OnLeave", HideTooltip)

    panel.titleLine = panel:CreateTexture(nil, "ARTWORK")
    panel.titleLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    panel.titleLine:SetPoint("TOPLEFT", inset, -34)
    panel.titleLine:SetPoint("TOPRIGHT", -inset, -34)
    panel.titleLine:SetHeight(1)
    SetTextureColor(panel.titleLine, DIVIDER_COLOR)

    local quantityLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    quantityLabel:SetPoint("LEFT", panel, "TOPLEFT", inset, -52)
    quantityLabel:SetJustifyH("LEFT")
    quantityLabel:SetText("Crafts")
    self.tradeSkillQuantityLabel = quantityLabel

    local plusButton = self:CreateButton(panel, 22, 22, "+")
    plusButton:SetPoint("TOPRIGHT", -inset, -41)
    plusButton:SetScript("OnClick", function()
        RB:SetTradeSkillPrepareCount(RB:GetTradeSkillRepeatCount() + 1, true)
    end)
    plusButton:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Increase prepare count", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    plusButton:SetScript("OnLeave", HideTooltip)
    self.tradeSkillPlusButton = plusButton

    local quantityBox = CreateFrame("EditBox", "ReagentBankUIPrepareCountBox", panel, "InputBoxTemplate")
    quantityBox:SetWidth(40)
    quantityBox:SetHeight(20)
    quantityBox:SetAutoFocus(false)
    quantityBox:SetNumeric(true)
    quantityBox:SetJustifyH("CENTER")
    quantityBox:SetPoint("RIGHT", plusButton, "LEFT", -8, 0)
    quantityBox:SetScript("OnEscapePressed", function(selfBox)
        RB:NormalizeTradeSkillQuantityBox(false)
        selfBox:ClearFocus()
    end)
    quantityBox:SetScript("OnEnterPressed", function(selfBox)
        RB:NormalizeTradeSkillQuantityBox(true)
        selfBox:ClearFocus()
        RB:WithdrawNeededForSelectedRecipe()
    end)
    quantityBox:SetScript("OnEditFocusLost", function()
        RB:NormalizeTradeSkillQuantityBox(false)
    end)
    quantityBox:SetScript("OnTextChanged", function(selfBox)
        if RB.suppressTradeSkillQuantityChanged then
            return
        end

        local value = tonumber(selfBox:GetText())
        if value and value > 0 then
            ReagentBankUIDB = ReagentBankUIDB or {}
            ReagentBankUIDB.tradeSkillPrepareCount = RB:ClampTradeSkillPrepareCount(value)
        end

        RB:UpdateTradeSkillControls()
    end)
    quantityBox:SetScript("OnEnter", function(selfBox)
        GameTooltip:SetOwner(selfBox, "ANCHOR_RIGHT")
        GameTooltip:SetText("Prepare count", 1, 0.82, 0)
        GameTooltip:AddLine("Number of times to prepare the selected recipe's reagents. Press Enter here to withdraw needed reagents.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    quantityBox:SetScript("OnLeave", HideTooltip)
    self.tradeSkillQuantityBox = quantityBox

    local minusButton = self:CreateButton(panel, 22, 22, "-")
    minusButton:SetPoint("RIGHT", quantityBox, "LEFT", -8, 0)
    minusButton:SetScript("OnClick", function()
        RB:SetTradeSkillPrepareCount(RB:GetTradeSkillRepeatCount() - 1, true)
    end)
    minusButton:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Decrease prepare count", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    minusButton:SetScript("OnLeave", HideTooltip)
    self.tradeSkillMinusButton = minusButton

    ReagentBankUIDB = ReagentBankUIDB or {}
    local initialCount = tonumber(ReagentBankUIDB.tradeSkillPrepareCount) or self:GetNativeTradeSkillRepeatCount() or 1
    self:SetTradeSkillPrepareCount(initialCount, false)

    -- Presets only move the Crafts count. Withdraw Needed stays a separate,
    -- deliberate click, so a large pull is always previewed in the plan summary
    -- first -- withdrawing does not check free bag space.
    local presetWidth = math.floor((contentWidth - (PROFESSION_PRESET_GAP * 2)) / 3)
    self.tradeSkillPresetButtons = {}

    local presets = {
        {
            label = "x1",
            tooltip = "Back to a single craft.",
            count = function() return TRADE_SKILL_PREPARE_COUNT_MIN end,
        },
        {
            label = "x" .. tostring(PROFESSION_PRESET_BATCH_COUNT),
            tooltip = "Prepare " .. tostring(PROFESSION_PRESET_BATCH_COUNT) .. " crafts. Anything your bags and bank cannot cover shows up under Buy.",
            count = function() return PROFESSION_PRESET_BATCH_COUNT end,
        },
        {
            label = "Max",
            tooltip = "Prepare as many crafts as your bags and reagent bank can cover between them.",
            count = function() return RB:GetMaxCraftableCount() end,
        },
    }

    for presetIndex, preset in ipairs(presets) do
        local presetButton = self:CreateButton(panel, presetWidth, PROFESSION_PRESET_BUTTON_HEIGHT, preset.label)

        if presetIndex == 1 then
            presetButton:SetPoint("TOPLEFT", inset, -67)
        else
            presetButton:SetPoint("LEFT", self.tradeSkillPresetButtons[presetIndex - 1], "RIGHT", PROFESSION_PRESET_GAP, 0)
        end

        presetButton.tooltipTitle = preset.label == "Max" and "Max craftable" or ("Prepare " .. preset.label)
        presetButton.tooltipText = preset.tooltip

        presetButton:SetScript("OnClick", function()
            local count = preset.count()
            if count then
                RB:SetTradeSkillPrepareCount(count, true)
            end
        end)
        presetButton:SetScript("OnEnter", function(selfButton)
            GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
            GameTooltip:SetText(selfButton.tooltipTitle or "Prepare count", 1, 0.82, 0)
            GameTooltip:AddLine(selfButton.tooltipText or "", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        presetButton:SetScript("OnLeave", HideTooltip)

        self.tradeSkillPresetButtons[presetIndex] = presetButton
    end

    self.tradeSkillMaxButton = self.tradeSkillPresetButtons[3]

    local button = self:CreateButton(panel, PROFESSION_ACTION_BUTTON_WIDTH, PROFESSION_ACTION_BUTTON_HEIGHT, "Withdraw Needed")
    button:SetPoint("TOP", panel, "TOP", 0, -95)
    button:SetScript("OnClick", function()
        RB:WithdrawNeededForSelectedRecipe()
    end)
    button:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reagent Bank", 1, 0.82, 0)
        GameTooltip:AddLine(selfButton.tooltipText or "Withdraw missing reagents for the selected recipe.", 1, 1, 1, true)
        GameTooltip:AddLine("Set the Crafts box above to prepare multiple crafts in one click.", 0.82, 0.82, 0.82, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", HideTooltip)
    self.tradeSkillButton = button

    local shoppingButton = self:CreateButton(panel, PROFESSION_ACTION_BUTTON_WIDTH, PROFESSION_ACTION_BUTTON_HEIGHT, "Add to AH List")
    shoppingButton:SetPoint("TOP", button, "BOTTOM", 0, -6)
    shoppingButton:SetScript("OnClick", function()
        RB:NormalizeTradeSkillQuantityBox(false)
        RB:ImportSelectedRecipeToShoppingList()
    end)
    shoppingButton:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("AH Shopping List", 1, 0.82, 0)
        GameTooltip:AddLine(selfButton.tooltipText or "Add selected recipe reagents that still need to be bought.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    shoppingButton:SetScript("OnLeave", HideTooltip)
    self.tradeSkillShoppingButton = shoppingButton

    local check = CreateFrame("CheckButton", "ReagentBankUIAutoDepositLeftoversCheck", panel, "UICheckButtonTemplate")
    check:SetWidth(22)
    check:SetHeight(22)
    check:SetPoint("TOPLEFT", inset - 2, -151)
    check:SetScript("OnClick", function(selfCheck)
        ReagentBankUIDB = ReagentBankUIDB or {}
        ReagentBankUIDB.autoDepositLeftovers = selfCheck:GetChecked() and true or false
        if not ReagentBankUIDB.autoDepositLeftovers then
            RB.pendingAutoDepositLeftovers = nil
            RB.pendingAutoDepositAt = nil
        end
        RB:UpdateTradeSkillControls()
    end)
    check:SetScript("OnEnter", function(selfCheck)
        GameTooltip:SetOwner(selfCheck, "ANCHOR_RIGHT")
        GameTooltip:SetText("Auto-deposit leftovers", 1, 0.82, 0)
        GameTooltip:AddLine("When you close the profession window, deposit prepared reagent leftovers back into the reagent bank. It preserves the bag counts you had before Withdraw Needed.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    check:SetScript("OnLeave", HideTooltip)
    self.tradeSkillAutoDepositCheck = check

    panel.checkText = _G[check:GetName() .. "Text"]
    if panel.checkText then
        if _G.GameFontHighlightSmall then
            panel.checkText:SetFontObject(_G.GameFontHighlightSmall)
        end
        panel.checkText:SetText("Auto-deposit leftovers")
    end

    panel.statsLine = panel:CreateTexture(nil, "ARTWORK")
    panel.statsLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    panel.statsLine:SetPoint("TOPLEFT", inset, -182)
    panel.statsLine:SetPoint("TOPRIGHT", -inset, -182)
    panel.statsLine:SetHeight(1)
    SetTextureColor(panel.statsLine, DIVIDER_COLOR)

    panel.craftValue = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panel.craftValue:SetPoint("TOPLEFT", inset, -192)
    panel.craftValue:SetJustifyH("LEFT")
    panel.craftValue:SetText("-")

    panel.craftLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    panel.craftLabel:SetPoint("BOTTOMLEFT", panel.craftValue, "BOTTOMRIGHT", 6, 2)
    panel.craftLabel:SetJustifyH("LEFT")
    panel.craftLabel:SetText("")

    panel.craftNote = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.craftNote:SetWidth(contentWidth)
    panel.craftNote:SetPoint("TOPLEFT", inset, -PROFESSION_PANEL_NOTE_TOP)
    panel.craftNote:SetJustifyH("LEFT")
    panel.craftNote:SetJustifyV("TOP")
    panel.craftNote:SetText("")

    local statsText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statsText:SetWidth(contentWidth)
    statsText:SetPoint("TOPLEFT", panel.craftNote, "BOTTOMLEFT", 0, -10)
    statsText:SetJustifyH("LEFT")
    statsText:SetJustifyV("TOP")
    statsText:SetSpacing(3)
    statsText:SetText("")
    self.tradeSkillStatsText = statsText

    if hooksecurefunc and TradeSkillFrame_SetSelection and not self.tradeSkillSelectionHooked then
        hooksecurefunc("TradeSkillFrame_SetSelection", function()
            RB:UpdateTradeSkillControls()
        end)
        self.tradeSkillSelectionHooked = true
    end

    local nativeInput = _G.TradeSkillInputBox
    if nativeInput and nativeInput.HookScript and not self.tradeSkillNativeInputHooked then
        nativeInput:HookScript("OnTextChanged", function(inputBox)
            if RB.suppressNativeTradeSkillQuantityChanged then
                return
            end

            local value = nil
            if inputBox.GetNumber then
                value = tonumber(inputBox:GetNumber())
            end
            if (not value or value <= 0) and inputBox.GetText then
                value = tonumber(inputBox:GetText())
            end

            if value and value > 0 then
                RB:SetTradeSkillPrepareCount(value, false)
            end
        end)
        self.tradeSkillNativeInputHooked = true
    end

    self:UpdateTradeSkillControls()
end

function RB:DockTradeSkillPanel()
    local panel = self.tradeSkillPanel
    local parent = self:GetTradeSkillControlsHost()
    if not panel or not parent then
        return
    end

    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", parent, "TOPRIGHT", PROFESSION_PANEL_X, PROFESSION_PANEL_Y)
    panel:Show()
end

function RB:ApplyScale()
    if not self.frame then
        return
    end

    ReagentBankUIDB = ReagentBankUIDB or {}
    local scale = Clamp(ReagentBankUIDB.scale or DEFAULT_SCALE, 0.75, 1.20)

    ReagentBankUIDB.scale = scale
    self.frame:SetScale(scale)
end

function RB:SetScaleValue(scale, silent)
    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.scale = Clamp(tonumber(scale) or DEFAULT_SCALE, 0.75, 1.20)
    self:ApplyScale()
    self:UpdateSettingsPanel()

    if not silent then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ff99ReagentBankUI|r scale set to %.2f", ReagentBankUIDB.scale))
    end
end

-- Blizzard templates name their child regions after the nearest named
-- parent, so every templated widget gets a unique name of its own.
local widgetCount = 0

local function NextWidgetName(kind)
    widgetCount = widgetCount + 1
    return "ReagentBankUI" .. kind .. widgetCount
end

function RB:CreateButton(parent, width, height, label)
    local button = CreateFrame("Button", NextWidgetName("Button"), parent, "UIPanelButtonTemplate")
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetText(label or "")
    return button
end

-- InputBoxTemplate draws its border 5px outside the box on each side, so the
-- box itself is narrowed to keep the old footprint.
function RB:CreateEditBox(parent, width, height)
    local box = CreateFrame("EditBox", NextWidgetName("EditBox"), parent, "InputBoxTemplate")
    box:SetWidth(width - 10)
    box:SetHeight(20)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetScript("OnEscapePressed", function(selfBox)
        selfBox:ClearFocus()
    end)
    box:SetScript("OnEnterPressed", function(selfBox)
        selfBox:ClearFocus()
        RB:WithdrawItemExact()
    end)
    box:SetScript("OnTextChanged", function()
        RB:UpdateControls()
    end)

    return box
end

function RB:CreateCloseButton(parent)
    return CreateFrame("Button", NextWidgetName("CloseButton"), parent, "UIPanelCloseButton")
end

-- A small -/+ icon button for an AH list row; direction is -1 or 1.
function RB:CreateStepButton(row, kind, direction)
    local button = CreateFrame("Button", nil, row)
    button:SetWidth(AUCTION_STEP_BUTTON_SIZE)
    button:SetHeight(AUCTION_STEP_BUTTON_SIZE)
    button:SetNormalTexture("Interface\\Buttons\\UI-" .. kind .. "Button-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-" .. kind .. "Button-Down")
    button:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    button:Hide()

    button:SetScript("OnClick", function()
        if row.item and row.item.entry then
            RB:StepShoppingListItem(row.item.entry, direction)
        end
    end)
    button:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        if direction > 0 then
            GameTooltip:SetText("Buy 1 more")
            GameTooltip:AddLine("Shift-click: a full stack more", 0.78, 0.82, 0.88)
        else
            GameTooltip:SetText("Buy 1 fewer")
            GameTooltip:AddLine("Shift-click: a full stack fewer", 0.78, 0.82, 0.88)
            GameTooltip:AddLine("Shift-right-click the row to remove it", 0.78, 0.82, 0.88)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", HideTooltip)

    return button
end

function RB:CreateLabel(parent, text, template)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    label:SetText(text or "")
    label:SetJustifyH("LEFT")
    return label
end

function RB:CreateFrame()
    if self.frame then
        return
    end

    local f = CreateFrame("Frame", "ReagentBankUIFrame", UIParent)
    f:SetWidth(MAIN_FRAME_WIDTH)
    f:SetHeight(MAIN_FRAME_HEIGHT)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(selfFrame)
        selfFrame:StartMoving()
    end)
    f:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()

        ReagentBankUIDB = ReagentBankUIDB or {}
        local point, relativeTo, relativePoint, xOfs, yOfs = selfFrame:GetPoint(1)

        ReagentBankUIDB.point = point
        ReagentBankUIDB.relativePoint = relativePoint
        ReagentBankUIDB.xOfs = xOfs
        ReagentBankUIDB.yOfs = yOfs
    end)

    self:MakeBackdrop(f)

    f.header = CreateFrame("Frame", nil, f)
    f.header:SetPoint("TOPLEFT", 8, -8)
    f.header:SetPoint("TOPRIGHT", -8, -8)
    f.header:SetHeight(42)

    f.title = f.header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("LEFT", 12, 1)
    f.title:SetText("Reagent Bank")
    f.title:SetJustifyH("LEFT")

    f.modeText = f.header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.modeText:SetPoint("LEFT", f.title, "RIGHT", 14, -1)
    f.modeText:SetPoint("RIGHT", -44, 0)
    f.modeText:SetJustifyH("LEFT")
    f.modeText:SetText("")

    f.close = self:CreateCloseButton(f)
    f.close:SetPoint("TOPRIGHT", -4, -4)
    f.close:SetScript("OnClick", function()
        RB:Close()
    end)

    f.rootDeposit = self:CreateButton(f, ROOT_ACTION_BUTTON_WIDTH, ROOT_BUTTON_HEIGHT, "Deposit All")
    f.rootDeposit:SetPoint("TOPLEFT", ROOT_BUTTON_ROW_X, ROOT_BUTTON_ROW_Y)
    f.rootDeposit:SetScript("OnClick", function()
        RB:DepositAll()
    end)

    f.rootWithdraw = self:CreateButton(f, ROOT_ACTION_BUTTON_WIDTH, ROOT_BUTTON_HEIGHT, "Withdraw All")
    f.rootWithdraw:SetPoint("LEFT", f.rootDeposit, "RIGHT", ROOT_BUTTON_GAP, 0)
    f.rootWithdraw:SetScript("OnClick", function()
        RB:WithdrawAll()
    end)

    f.refresh = self:CreateButton(f, ROOT_REFRESH_BUTTON_WIDTH, ROOT_BUTTON_HEIGHT, "Refresh")
    f.refresh:SetPoint("LEFT", f.rootWithdraw, "RIGHT", ROOT_BUTTON_GAP, 0)
    f.refresh:SetScript("OnClick", function()
        if RB.currentView == "category" and RB.currentCategoryId then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage or 0)
        elseif RB.currentView == "detail" and RB.currentCategoryId then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage or 0)
        else
            RB:RequestRoot()
        end
    end)

    f.sortMode = self:CreateButton(f, ROOT_SORT_BUTTON_WIDTH, ROOT_BUTTON_HEIGHT, "Sort: ID")
    f.sortMode:SetPoint("LEFT", f.refresh, "RIGHT", ROOT_BUTTON_GAP, 0)
    f.sortMode:SetScript("OnClick", function()
        RB:CycleSortMode()
    end)
    f.sortMode:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reagent Bank Sorting", 1, 0.82, 0)
        GameTooltip:AddLine(selfButton.tooltipText or "Cycle sorting.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    f.sortMode:SetScript("OnLeave", HideTooltip)

    f.shoppingList = self:CreateButton(f, ROOT_SHOPPING_BUTTON_WIDTH, ROOT_BUTTON_HEIGHT, "AH List")
    f.shoppingList:SetPoint("LEFT", f.sortMode, "RIGHT", ROOT_BUTTON_GAP, 0)
    f.shoppingList:SetScript("OnClick", function()
        RB:RenderShoppingList()
    end)
    f.shoppingList:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("AH Shopping List", 1, 0.82, 0)
        GameTooltip:AddLine(selfButton.tooltipText or "Open your saved reagent buy list.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    f.shoppingList:SetScript("OnLeave", HideTooltip)

    f.previewToggle = self:CreateButton(f, ROOT_PREVIEW_TOGGLE_BUTTON_WIDTH, ROOT_BUTTON_HEIGHT, "Preview: On")
    f.previewToggle:SetPoint("LEFT", f.shoppingList, "RIGHT", ROOT_BUTTON_GAP, 0)
    f.previewToggle:SetScript("OnClick", function()
        RB:ToggleDepositPreviewEnabled()
    end)
    f.previewToggle:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Deposit Preview Confirmation", 1, 0.82, 0)
        GameTooltip:AddLine(selfButton.tooltipText or "Toggle deposit confirmation previews.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    f.previewToggle:SetScript("OnLeave", HideTooltip)

    f.back = self:CreateButton(f, CATEGORY_BACK_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Categories")
    f.back:SetPoint("TOPLEFT", CATEGORY_BUTTON_ROW_X, CATEGORY_BUTTON_ROW_Y)
    f.back:SetScript("OnClick", function()
        RB:RequestRoot()
    end)

    f.catDeposit = self:CreateButton(f, CATEGORY_ACTION_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Deposit Category")
    f.catDeposit:SetPoint("LEFT", f.back, "RIGHT", CATEGORY_BUTTON_GAP, 0)
    f.catDeposit:SetScript("OnClick", function()
        RB:DepositCategory()
    end)

    f.catWithdraw = self:CreateButton(f, CATEGORY_ACTION_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Withdraw Category")
    f.catWithdraw:SetPoint("LEFT", f.catDeposit, "RIGHT", CATEGORY_BUTTON_GAP, 0)
    f.catWithdraw:SetScript("OnClick", function()
        RB:WithdrawCategory()
    end)

    -- Paging sits flush against the right margin so the page counter lands in
    -- the same spot on every view instead of drifting with the button widths.
    f.pageText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.pageText:SetWidth(CATEGORY_PAGE_TEXT_WIDTH)
    f.pageText:SetPoint("RIGHT", f, "TOPRIGHT", -18, CATEGORY_BUTTON_ROW_Y - (CATEGORY_BUTTON_HEIGHT / 2))
    f.pageText:SetJustifyH("RIGHT")
    f.pageText:SetText("")

    f.next = self:CreateButton(f, CATEGORY_PAGE_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Next")
    f.next:SetPoint("RIGHT", f.pageText, "LEFT", -CATEGORY_PAGE_TEXT_GAP, 0)
    f.next:SetScript("OnClick", function()
        if RB.currentCategoryId and RB.currentPage and RB.totalPages and RB.currentPage + 1 < RB.totalPages then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage + 1)
        end
    end)

    f.prev = self:CreateButton(f, CATEGORY_PAGE_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Prev")
    f.prev:SetPoint("RIGHT", f.next, "LEFT", -CATEGORY_BUTTON_GAP, 0)
    f.prev:SetScript("OnClick", function()
        if RB.currentCategoryId and RB.currentPage and RB.currentPage > 0 then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage - 1)
        end
    end)

    f.shoppingImportRecipe = self:CreateButton(f, SHOPPING_RECIPE_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "From Recipe")
    f.shoppingImportRecipe:SetPoint("LEFT", f.back, "RIGHT", CATEGORY_BUTTON_GAP, 0)
    f.shoppingImportRecipe:SetScript("OnClick", function()
        RB:ImportSelectedRecipeToShoppingList()
    end)

    f.shoppingPrint = self:CreateButton(f, SHOPPING_PRINT_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Print List")
    f.shoppingPrint:SetPoint("LEFT", f.shoppingImportRecipe, "RIGHT", CATEGORY_BUTTON_GAP, 0)
    f.shoppingPrint:SetScript("OnClick", function()
        RB:PrintShoppingList()
    end)

    f.shoppingClear = self:CreateButton(f, SHOPPING_CLEAR_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Clear List")
    f.shoppingClear:SetPoint("LEFT", f.shoppingPrint, "RIGHT", CATEGORY_BUTTON_GAP, 0)
    f.shoppingClear:SetScript("OnClick", function()
        RB:ClearShoppingList()
    end)

    f.shoppingPageText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.shoppingPageText:SetWidth(CATEGORY_PAGE_TEXT_WIDTH)
    f.shoppingPageText:SetPoint("RIGHT", f, "TOPRIGHT", -18, CATEGORY_BUTTON_ROW_Y - (CATEGORY_BUTTON_HEIGHT / 2))
    f.shoppingPageText:SetJustifyH("RIGHT")
    f.shoppingPageText:SetText("")

    f.shoppingNext = self:CreateButton(f, CATEGORY_PAGE_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Next")
    f.shoppingNext:SetPoint("RIGHT", f.shoppingPageText, "LEFT", -CATEGORY_PAGE_TEXT_GAP, 0)
    f.shoppingNext:SetScript("OnClick", function()
        if RB.currentView == "shopping" and RB.currentPage and RB.totalPages and RB.currentPage + 1 < RB.totalPages then
            RB.currentPage = RB.currentPage + 1
            RB:RenderShoppingList(true)
        end
    end)

    f.shoppingPrev = self:CreateButton(f, CATEGORY_PAGE_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Prev")
    f.shoppingPrev:SetPoint("RIGHT", f.shoppingNext, "LEFT", -CATEGORY_BUTTON_GAP, 0)
    f.shoppingPrev:SetScript("OnClick", function()
        if RB.currentView == "shopping" and RB.currentPage and RB.currentPage > 0 then
            RB.currentPage = RB.currentPage - 1
            RB:RenderShoppingList(true)
        end
    end)

    f.list = CreateFrame("Frame", nil, f)
    f.list:SetPoint("TOPLEFT", 18, -118)
    f.list:SetPoint("BOTTOMRIGHT", -18, 54)
    self:MakeBackdrop(f.list, 0.78, true)

    f.listHeader = CreateFrame("Frame", nil, f.list)
    f.listHeader:SetHeight(24)
    f.listHeader:SetPoint("TOPLEFT", 8, -7)
    f.listHeader:SetPoint("RIGHT", -8, 0)

    f.listHeader.bg = f.listHeader:CreateTexture(nil, "BACKGROUND")
    f.listHeader.bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    f.listHeader.bg:SetAllPoints(f.listHeader)
    SetTextureColor(f.listHeader.bg, LIST_HEADER_COLOR)

    f.listHeader.line = f.listHeader:CreateTexture(nil, "ARTWORK")
    f.listHeader.line:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    f.listHeader.line:SetPoint("BOTTOMLEFT", 0, 0)
    f.listHeader.line:SetPoint("BOTTOMRIGHT", 0, 0)
    f.listHeader.line:SetHeight(1)
    SetTextureColor(f.listHeader.line, DIVIDER_COLOR)

    f.headerName = f.listHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.headerName:SetPoint("LEFT", 32, 0)
    f.headerName:SetJustifyH("LEFT")
    f.headerName:SetText("Name")

    f.headerCount = f.listHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.headerCount:SetWidth(LIST_COUNT_COLUMN_WIDTH)
    f.headerCount:SetPoint("RIGHT", -LIST_COUNT_COLUMN_INSET, 0)
    f.headerCount:SetJustifyH("RIGHT")
    f.headerCount:SetText("Stored")

    f.listHeader.split = f.listHeader:CreateTexture(nil, "ARTWORK")
    f.listHeader.split:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    f.listHeader.split:SetWidth(1)
    f.listHeader.split:SetPoint("TOP", f.listHeader, "TOPRIGHT", -LIST_COLUMN_SPLIT, -4)
    f.listHeader.split:SetPoint("BOTTOM", f.listHeader, "BOTTOMRIGHT", -LIST_COLUMN_SPLIT, 3)
    SetTextureColor(f.listHeader.split, DIVIDER_COLOR)

    f.rows = {}
    for i = 1, ROW_COUNT do
        local row = CreateFrame("Button", nil, f.list, "ReagentBankUIListRowTemplate")
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("LEFT", 8, 0)
        row:SetPoint("RIGHT", -8, 0)

        if i == 1 then
            row:SetPoint("TOP", f.listHeader, "BOTTOM", 0, -2)
        else
            row:SetPoint("TOP", f.rows[i - 1], "BOTTOM", 0, -ROW_SPACING)
        end

        if row.fill then
            row.fill:SetHeight(ROW_HEIGHT)
            row.fill:SetWidth(1)
            row.fill:Hide()
        end

        -- Lines up with the list header divider so stored amounts read as a
        -- column instead of numbers floating at the end of each name.
        row.split = row:CreateTexture(nil, "ARTWORK")
        row.split:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        row.split:SetWidth(1)
        row.split:SetPoint("TOP", row, "TOPRIGHT", -LIST_COLUMN_SPLIT, -3)
        row.split:SetPoint("BOTTOM", row, "BOTTOMRIGHT", -LIST_COLUMN_SPLIT, 3)

        if row.hover then
            row:SetHighlightTexture(row.hover)
        end

        self:StyleListRow(row, i)

        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function(selfRow, mouseButton)
            if selfRow.kind == "category" and selfRow.categoryId then
                RB:HideWithdrawPrompt()
                RB:RequestCategory(selfRow.categoryId, 0)
            elseif selfRow.kind == "item" and selfRow.item then
                if mouseButton == "RightButton" then
                    RB:ShowWithdrawPrompt(selfRow.item)
                else
                    RB:HideWithdrawPrompt()
                    RB:ShowDetail(selfRow.item)
                end
            elseif selfRow.kind == "shopping" and selfRow.item then
                if mouseButton == "RightButton" then
                    if IsShiftKeyDown and IsShiftKeyDown() then
                        RB:RemoveShoppingListItem(selfRow.item.entry)
                    else
                        RB:ShowShoppingAmountPrompt(selfRow.item)
                    end
                else
                    RB:SearchAuctionHouseForItem(selfRow.item.entry)
                end
            end
        end)

        row:SetScript("OnEnter", function(selfRow)
            if (selfRow.kind == "item" or selfRow.kind == "shopping") and selfRow.item and selfRow.item.entry then
                SetTooltipItem(selfRow.item.entry)
            end
        end)

        row:SetScript("OnLeave", HideTooltip)

        f.rows[i] = row
    end

    f.listScroll = CreateFrame("ScrollFrame", "ReagentBankUIListScrollFrame", f.list, "FauxScrollFrameTemplate")
    f.listScroll:SetPoint("TOP", f.rows[1], "TOP", 0, 0)
    f.listScroll:SetPoint("BOTTOM", f.rows[ROW_COUNT], "BOTTOM", 0, 0)
    f.listScroll:SetPoint("LEFT", f.list, "LEFT", LIST_ROW_INSET, 0)
    f.listScroll:SetPoint("RIGHT", f.list, "RIGHT", -LIST_SCROLL_ROW_INSET, 0)
    f.listScroll:SetScript("OnVerticalScroll", function(selfScroll, offset)
        FauxScrollFrame_OnVerticalScroll(selfScroll, offset, ROW_HEIGHT + ROW_SPACING, function()
            RB:RefreshListWindow()
        end)
    end)
    f.listScroll:Hide()

    f.detail = CreateFrame("Frame", nil, f)
    f.detail:SetPoint("TOPLEFT", 18, -118)
    f.detail:SetPoint("BOTTOMRIGHT", -18, 54)
    self:MakeBackdrop(f.detail, 0.78, true)

    f.detailIconBorder = CreateFrame("Frame", nil, f.detail)
    f.detailIconBorder:SetWidth(62)
    f.detailIconBorder:SetHeight(62)
    f.detailIconBorder:SetPoint("TOPLEFT", 16, -16)
    self:MakeBackdrop(f.detailIconBorder, 0.90, true)

    f.detailIcon = f.detailIconBorder:CreateTexture(nil, "ARTWORK")
    f.detailIcon:SetWidth(54)
    f.detailIcon:SetHeight(54)
    f.detailIcon:SetPoint("CENTER", 0, 0)

    f.detailName = f.detail:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.detailName:SetPoint("TOPLEFT", f.detailIconBorder, "TOPRIGHT", 14, -2)
    f.detailName:SetPoint("RIGHT", -18, 0)
    f.detailName:SetJustifyH("LEFT")

    f.detailStored = f.detail:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.detailStored:SetPoint("TOPLEFT", f.detailName, "BOTTOMLEFT", 0, -8)
    f.detailStored:SetJustifyH("LEFT")

    f.detailHint = f.detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.detailHint:SetPoint("TOPLEFT", f.detailStored, "BOTTOMLEFT", 0, -8)
    f.detailHint:SetPoint("RIGHT", -18, 0)
    f.detailHint:SetJustifyH("LEFT")
    f.detailHint:SetText("Withdraw one stack, all, or type an exact amount. Counts refresh from the server after each action.")

    f.withdrawOne = self:CreateButton(f.detail, 132, 28, "Withdraw 1")
    f.withdrawOne:SetPoint("TOPLEFT", 18, -112)
    f.withdrawOne:SetScript("OnClick", function()
        RB:WithdrawItem("one")
    end)

    f.withdrawStack = self:CreateButton(f.detail, 132, 28, "Withdraw Stack")
    f.withdrawStack:SetPoint("LEFT", f.withdrawOne, "RIGHT", 10, 0)
    f.withdrawStack:SetScript("OnClick", function()
        RB:WithdrawItem("stack")
    end)

    f.withdrawItemAll = self:CreateButton(f.detail, 132, 28, "Withdraw All")
    f.withdrawItemAll:SetPoint("LEFT", f.withdrawStack, "RIGHT", 10, 0)
    f.withdrawItemAll:SetScript("OnClick", function()
        RB:WithdrawItem("all")
    end)

    f.exactLabel = f.detail:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.exactLabel:SetPoint("TOPLEFT", 20, -154)
    f.exactLabel:SetText("Exact amount:")
    f.exactLabel:SetJustifyH("LEFT")

    f.exactBox = self:CreateEditBox(f.detail, 82, 24)
    f.exactBox:SetPoint("LEFT", f.exactLabel, "RIGHT", 10, 0)

    f.withdrawExact = self:CreateButton(f.detail, 132, 28, "Withdraw Exact")
    f.withdrawExact:SetPoint("LEFT", f.exactBox, "RIGHT", 10, 0)
    f.withdrawExact:SetScript("OnClick", function()
        RB:WithdrawItemExact()
    end)

    f.shoppingLabel = f.detail:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.shoppingLabel:SetPoint("TOPLEFT", 20, -194)
    f.shoppingLabel:SetText("AH list amount:")
    f.shoppingLabel:SetJustifyH("LEFT")

    f.shoppingAmountBox = self:CreateEditBox(f.detail, 82, 24)
    f.shoppingAmountBox:SetPoint("LEFT", f.shoppingLabel, "RIGHT", 10, 0)
    f.shoppingAmountBox:SetScript("OnEnterPressed", function(selfBox)
        selfBox:ClearFocus()
        RB:AddDetailItemToShoppingList()
    end)
    f.shoppingAmountBox:SetScript("OnTextChanged", function()
        RB:UpdateControls()
    end)

    f.addShopping = self:CreateButton(f.detail, 132, 28, "Add to AH List")
    f.addShopping:SetPoint("LEFT", f.shoppingAmountBox, "RIGHT", 10, 0)
    f.addShopping:SetScript("OnClick", function()
        RB:AddDetailItemToShoppingList()
    end)

    f.detailBack = self:CreateButton(f.detail, 132, 28, "Back to List")
    f.detailBack:SetPoint("LEFT", f.withdrawItemAll, "RIGHT", 10, 0)
    f.detailBack:SetScript("OnClick", function()
        if RB.currentCategoryId then
            RB:RenderCategory()
        else
            RB:RequestRoot()
        end
    end)

    f.detail:SetScript("OnEnter", function()
        if RB.detailItem and RB.detailItem.entry then
            SetTooltipItem(RB.detailItem.entry)
        end
    end)
    f.detail:SetScript("OnLeave", HideTooltip)

    f.quickWithdraw = CreateFrame("Frame", nil, f)
    f.quickWithdraw:SetWidth(QUICK_WITHDRAW_WIDTH)
    f.quickWithdraw:SetHeight(188)
    f.quickWithdraw:SetPoint("CENTER", f, "CENTER", 0, 18)
    f.quickWithdraw:SetFrameLevel((f:GetFrameLevel() or 1) + 80)
    f.quickWithdraw:EnableMouse(true)
    self:MakeBackdrop(f.quickWithdraw)
    f.quickWithdraw:Hide()

    f.quickWithdrawTitle = f.quickWithdraw:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.quickWithdrawTitle:SetPoint("TOPLEFT", 16, -13)
    f.quickWithdrawTitle:SetText("Withdraw Item")
    f.quickWithdrawTitle:SetTextColor(1.00, 0.82, 0.28)

    f.quickWithdrawClose = self:CreateCloseButton(f.quickWithdraw)
    f.quickWithdrawClose:SetPoint("TOPRIGHT", -4, -4)
    f.quickWithdrawClose:SetScript("OnClick", function()
        RB:HideWithdrawPrompt()
    end)

    f.quickWithdrawIcon = f.quickWithdraw:CreateTexture(nil, "ARTWORK")
    f.quickWithdrawIcon:SetWidth(38)
    f.quickWithdrawIcon:SetHeight(38)
    f.quickWithdrawIcon:SetPoint("TOPLEFT", 18, -44)

    f.quickWithdrawName = f.quickWithdraw:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.quickWithdrawName:SetPoint("TOPLEFT", f.quickWithdrawIcon, "TOPRIGHT", 10, -1)
    f.quickWithdrawName:SetPoint("RIGHT", -18, 0)
    f.quickWithdrawName:SetJustifyH("LEFT")

    f.quickWithdrawStored = f.quickWithdraw:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.quickWithdrawStored:SetPoint("TOPLEFT", f.quickWithdrawName, "BOTTOMLEFT", 0, -5)
    f.quickWithdrawStored:SetJustifyH("LEFT")

    f.quickWithdrawLabel = f.quickWithdraw:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.quickWithdrawLabel:SetPoint("TOPLEFT", 18, -94)
    f.quickWithdrawLabel:SetText("Amount:")
    f.quickWithdrawLabel:SetJustifyH("LEFT")

    f.quickWithdrawBox = self:CreateEditBox(f.quickWithdraw, 82, 24)
    f.quickWithdrawBox:SetPoint("LEFT", f.quickWithdrawLabel, "RIGHT", 10, 0)
    f.quickWithdrawBox:SetScript("OnEnterPressed", function(selfBox)
        selfBox:ClearFocus()
        RB:ConfirmWithdrawPrompt()
    end)
    f.quickWithdrawBox:SetScript("OnEscapePressed", function(selfBox)
        selfBox:ClearFocus()
        RB:HideWithdrawPrompt()
    end)
    f.quickWithdrawBox:SetScript("OnTextChanged", function()
        RB:UpdateQuickWithdrawControls()
    end)

    f.quickWithdrawButton = self:CreateButton(f.quickWithdraw, 112, 26, "Withdraw")
    f.quickWithdrawButton:SetPoint("LEFT", f.quickWithdrawBox, "RIGHT", 10, 0)
    f.quickWithdrawButton:SetScript("OnClick", function()
        RB:ConfirmWithdrawPrompt()
    end)

    f.quickWithdrawAll = self:CreateButton(f.quickWithdraw, 82, 26, "All")
    f.quickWithdrawAll:SetPoint("LEFT", f.quickWithdrawButton, "RIGHT", 8, 0)
    f.quickWithdrawAll:SetScript("OnClick", function()
        RB:SetWithdrawPromptAmountToAll()
    end)

    f.quickWithdrawShopping = self:CreateButton(f.quickWithdraw, 148, 26, "Add Missing to AH")
    f.quickWithdrawShopping:SetPoint("TOPLEFT", 18, -126)
    f.quickWithdrawShopping:SetScript("OnClick", function()
        RB:AddWithdrawPromptMissingToShoppingList()
    end)

    f.quickWithdrawCancel = self:CreateButton(f.quickWithdraw, 82, 26, "Cancel")
    f.quickWithdrawCancel:SetPoint("LEFT", f.quickWithdrawAll, "RIGHT", 8, 0)
    f.quickWithdrawCancel:SetScript("OnClick", function()
        RB:HideWithdrawPrompt()
    end)

    f.quickWithdrawHint = f.quickWithdraw:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.quickWithdrawHint:SetPoint("TOPLEFT", 18, -158)
    f.quickWithdrawHint:SetPoint("RIGHT", -18, 0)
    f.quickWithdrawHint:SetJustifyH("LEFT")
    f.quickWithdrawHint:SetText("")

    f.shoppingPrompt = CreateFrame("Frame", nil, f)
    f.shoppingPrompt:SetWidth(QUICK_WITHDRAW_WIDTH)
    f.shoppingPrompt:SetHeight(154)
    f.shoppingPrompt:SetPoint("CENTER", f, "CENTER", 0, 18)
    f.shoppingPrompt:SetFrameLevel((f:GetFrameLevel() or 1) + 82)
    f.shoppingPrompt:EnableMouse(true)
    self:MakeBackdrop(f.shoppingPrompt)
    f.shoppingPrompt:Hide()

    f.shoppingPromptTitle = f.shoppingPrompt:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.shoppingPromptTitle:SetPoint("TOPLEFT", 16, -13)
    f.shoppingPromptTitle:SetText("AH List Amount")
    f.shoppingPromptTitle:SetTextColor(1.00, 0.82, 0.28)

    f.shoppingPromptClose = self:CreateCloseButton(f.shoppingPrompt)
    f.shoppingPromptClose:SetPoint("TOPRIGHT", -4, -4)
    f.shoppingPromptClose:SetScript("OnClick", function()
        RB:HideShoppingAmountPrompt()
    end)

    f.shoppingPromptIcon = f.shoppingPrompt:CreateTexture(nil, "ARTWORK")
    f.shoppingPromptIcon:SetWidth(38)
    f.shoppingPromptIcon:SetHeight(38)
    f.shoppingPromptIcon:SetPoint("TOPLEFT", 18, -44)

    f.shoppingPromptName = f.shoppingPrompt:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.shoppingPromptName:SetPoint("TOPLEFT", f.shoppingPromptIcon, "TOPRIGHT", 10, -1)
    f.shoppingPromptName:SetPoint("RIGHT", -18, 0)
    f.shoppingPromptName:SetJustifyH("LEFT")

    f.shoppingPromptCurrent = f.shoppingPrompt:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.shoppingPromptCurrent:SetPoint("TOPLEFT", f.shoppingPromptName, "BOTTOMLEFT", 0, -5)
    f.shoppingPromptCurrent:SetJustifyH("LEFT")

    f.shoppingPromptLabel = f.shoppingPrompt:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.shoppingPromptLabel:SetPoint("TOPLEFT", 18, -94)
    f.shoppingPromptLabel:SetText("Amount:")
    f.shoppingPromptLabel:SetJustifyH("LEFT")

    f.shoppingPromptBox = self:CreateEditBox(f.shoppingPrompt, 82, 24)
    f.shoppingPromptBox:SetPoint("LEFT", f.shoppingPromptLabel, "RIGHT", 10, 0)
    f.shoppingPromptBox:SetScript("OnEnterPressed", function(selfBox)
        selfBox:ClearFocus()
        RB:ApplyShoppingAmountPrompt()
    end)
    f.shoppingPromptBox:SetScript("OnEscapePressed", function(selfBox)
        selfBox:ClearFocus()
        RB:HideShoppingAmountPrompt()
    end)
    f.shoppingPromptBox:SetScript("OnTextChanged", function()
        RB:UpdateShoppingAmountPromptControls()
    end)

    f.shoppingPromptUpdate = self:CreateButton(f.shoppingPrompt, 112, 26, "Update")
    f.shoppingPromptUpdate:SetPoint("LEFT", f.shoppingPromptBox, "RIGHT", 10, 0)
    f.shoppingPromptUpdate:SetScript("OnClick", function()
        RB:ApplyShoppingAmountPrompt()
    end)

    f.shoppingPromptRemove = self:CreateButton(f.shoppingPrompt, 82, 26, "Remove")
    f.shoppingPromptRemove:SetPoint("LEFT", f.shoppingPromptUpdate, "RIGHT", 8, 0)
    f.shoppingPromptRemove:SetScript("OnClick", function()
        RB:RemoveShoppingPromptItem()
    end)

    f.shoppingPromptCancel = self:CreateButton(f.shoppingPrompt, 82, 26, "Cancel")
    f.shoppingPromptCancel:SetPoint("LEFT", f.shoppingPromptRemove, "RIGHT", 8, 0)
    f.shoppingPromptCancel:SetScript("OnClick", function()
        RB:HideShoppingAmountPrompt()
    end)

    f.shoppingPromptHint = f.shoppingPrompt:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.shoppingPromptHint:SetPoint("TOPLEFT", 18, -126)
    f.shoppingPromptHint:SetPoint("RIGHT", -18, 0)
    f.shoppingPromptHint:SetJustifyH("LEFT")
    f.shoppingPromptHint:SetText("")

    f.depositPreview = CreateFrame("Frame", nil, f)
    f.depositPreview:SetWidth(520)
    f.depositPreview:SetHeight(370)
    f.depositPreview:SetPoint("CENTER", f, "CENTER", 0, 8)
    f.depositPreview:SetFrameLevel((f:GetFrameLevel() or 1) + 90)
    f.depositPreview:EnableMouse(true)
    self:MakeBackdrop(f.depositPreview)
    f.depositPreview:Hide()

    f.depositPreview.title = f.depositPreview:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.depositPreview.title:SetPoint("TOPLEFT", 16, -13)
    f.depositPreview.title:SetPoint("RIGHT", -48, 0)
    f.depositPreview.title:SetJustifyH("LEFT")
    f.depositPreview.title:SetTextColor(1.00, 0.82, 0.28)
    f.depositPreview.title:SetText("Deposit Preview")

    f.depositPreview.close = self:CreateCloseButton(f.depositPreview)
    f.depositPreview.close:SetPoint("TOPRIGHT", -4, -4)
    f.depositPreview.close:SetScript("OnClick", function()
        RB:HideDepositPreview()
    end)

    f.depositPreview.summary = f.depositPreview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.depositPreview.summary:SetPoint("TOPLEFT", 18, -42)
    f.depositPreview.summary:SetPoint("RIGHT", -18, 0)
    f.depositPreview.summary:SetJustifyH("LEFT")
    f.depositPreview.summary:SetTextColor(0.82, 0.82, 0.82)
    f.depositPreview.summary:SetText("")

    f.depositPreview.rows = {}
    for previewIndex = 1, DEPOSIT_PREVIEW_ROW_COUNT do
        local previewRow = CreateFrame("Frame", nil, f.depositPreview, "ReagentBankUIPreviewRowTemplate")
        previewRow:SetHeight(22)
        previewRow:SetPoint("LEFT", 18, 0)
        previewRow:SetPoint("RIGHT", -18, 0)

        if previewIndex == 1 then
            previewRow:SetPoint("TOP", f.depositPreview.summary, "BOTTOM", 0, -12)
        else
            previewRow:SetPoint("TOP", f.depositPreview.rows[previewIndex - 1], "BOTTOM", 0, -3)
        end

        self:StyleListRow(previewRow, previewIndex)
        if previewRow.name then
            previewRow.name:ClearAllPoints()
            previewRow.name:SetPoint("LEFT", previewRow.icon, "RIGHT", 8, 0)
            previewRow.name:SetPoint("RIGHT", -110, 0)
            previewRow.name:SetJustifyH("LEFT")
        end

        f.depositPreview.rows[previewIndex] = previewRow
    end

    f.depositPreview.more = f.depositPreview:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.depositPreview.more:SetPoint("TOPLEFT", f.depositPreview.rows[DEPOSIT_PREVIEW_ROW_COUNT], "BOTTOMLEFT", 2, -7)
    f.depositPreview.more:SetPoint("RIGHT", -18, 0)
    f.depositPreview.more:SetJustifyH("LEFT")
    f.depositPreview.more:SetText("")

    f.depositPreview.confirm = self:CreateButton(f.depositPreview, 132, 28, "Confirm")
    f.depositPreview.confirm:SetPoint("BOTTOMRIGHT", -154, 16)
    f.depositPreview.confirm:SetScript("OnClick", function()
        RB:ConfirmDepositPreview()
    end)

    f.depositPreview.cancel = self:CreateButton(f.depositPreview, 112, 28, "Cancel")
    f.depositPreview.cancel:SetPoint("LEFT", f.depositPreview.confirm, "RIGHT", 10, 0)
    f.depositPreview.cancel:SetScript("OnClick", function()
        RB:HideDepositPreview()
    end)

    f.footer = CreateFrame("Frame", nil, f)
    f.footer:SetPoint("BOTTOMLEFT", 18, 18)
    f.footer:SetPoint("BOTTOMRIGHT", -18, 18)
    f.footer:SetHeight(24)
    self:MakeBackdrop(f.footer, 0.58, true)

    f.undoLast = self:CreateButton(f.footer, UNDO_BUTTON_WIDTH, 20, "Reverse Last")
    f.undoLast:SetPoint("RIGHT", -3, 0)
    f.undoLast:SetScript("OnClick", function()
        RB:ReverseLastTransaction()
    end)
    f.undoLast:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reverse last reagent bank action", 1, 0.82, 0)
        GameTooltip:AddLine(selfButton.tooltipText or "No reversible transaction is available.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    f.undoLast:SetScript("OnLeave", HideTooltip)

    f.status = f.footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.status:SetPoint("LEFT", 8, 0)
    f.status:SetPoint("RIGHT", f.undoLast, "LEFT", -8, 0)
    f.status:SetJustifyH("LEFT")
    f.status:SetText("")

    f:Hide()

    self.frame = f
    self:ApplyScale()
    self:UpdateControls()
end

function RB:ApplySavedPosition()
    self:CreateFrame()

    ReagentBankUIDB = ReagentBankUIDB or {}
    if ReagentBankUIDB.point and ReagentBankUIDB.relativePoint and ReagentBankUIDB.xOfs and ReagentBankUIDB.yOfs then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(ReagentBankUIDB.point, UIParent, ReagentBankUIDB.relativePoint, ReagentBankUIDB.xOfs, ReagentBankUIDB.yOfs)
    end
end

function RB:SetCommonVisibility(view)
    self:CreateFrame()

    local f = self.frame
    local rootView = view == "root"
    local categoryView = view == "category"
    local detailView = view == "detail"
    local shoppingView = view == "shopping"

    f.rootDeposit:Show()
    f.rootWithdraw:Show()
    f.refresh:Show()
    f.shoppingList:Show()

    if categoryView or detailView or shoppingView then
        f.back:Show()
    else
        f.back:Hide()
    end

    if categoryView then
        f.catDeposit:Show()
        f.catWithdraw:Show()
        f.prev:Show()
        f.next:Show()
        f.pageText:Show()
    else
        f.catDeposit:Hide()
        f.catWithdraw:Hide()
        f.prev:Hide()
        f.next:Hide()
        f.pageText:Hide()
    end

    if shoppingView then
        f.shoppingImportRecipe:Show()
        f.shoppingPrint:Show()
        f.shoppingClear:Show()
        f.shoppingPrev:Show()
        f.shoppingNext:Show()
        f.shoppingPageText:Show()
    else
        f.shoppingImportRecipe:Hide()
        f.shoppingPrint:Hide()
        f.shoppingClear:Hide()
        f.shoppingPrev:Hide()
        f.shoppingNext:Hide()
        f.shoppingPageText:Hide()
    end

    if rootView or categoryView or shoppingView then
        f.list:Show()
    else
        f.list:Hide()
    end

    if detailView then
        f.detail:Show()
    else
        f.detail:Hide()
    end
end

function RB:UpdateControls()
    if not self.frame then
        return
    end

    local f = self.frame
    local busy = self.busyKind ~= nil
    local page = tonumber(self.currentPage) or 0
    local totalPages = math.max(tonumber(self.totalPages) or 1, 1)
    local inCategory = self.currentView == "category"
    local inDetail = self.currentView == "detail"
    local inShopping = self.currentView == "shopping"
    local hasCategory = self.currentCategoryId ~= nil

    if self.busyKind == "request" then
        f.refresh:SetText("Refreshing")
    else
        f.refresh:SetText("Refresh")
    end

    self:SetButtonEnabled(f.refresh, not busy)
    self:SetButtonEnabled(f.rootDeposit, not busy)
    self:SetButtonEnabled(f.rootWithdraw, not busy)
    self:SetButtonEnabled(f.sortMode, not busy and not inShopping)
    self:SetButtonEnabled(f.previewToggle, not busy)
    self:SetButtonEnabled(f.shoppingList, not busy)
    self:SetButtonEnabled(f.back, not busy)
    self:SetButtonEnabled(f.catDeposit, not busy and inCategory and hasCategory)
    self:SetButtonEnabled(f.catWithdraw, not busy and inCategory and hasCategory)
    self:SetButtonEnabled(f.prev, not busy and inCategory and page > 0)
    self:SetButtonEnabled(f.next, not busy and inCategory and page + 1 < totalPages)

    local shoppingTypes = 0
    if inShopping then
        shoppingTypes = self:GetShoppingListTotals()
    end

    self:SetButtonEnabled(f.shoppingImportRecipe, not busy)
    self:SetButtonEnabled(f.shoppingPrint, not busy and shoppingTypes > 0)
    self:SetButtonEnabled(f.shoppingClear, not busy and shoppingTypes > 0)
    self:SetButtonEnabled(f.shoppingPrev, not busy and inShopping and page > 0)
    self:SetButtonEnabled(f.shoppingNext, not busy and inShopping and page + 1 < totalPages)

    local stored = 0
    if self.detailItem then
        stored = tonumber(self.detailItem.amount) or 0
    end

    local exactAmount = self:GetExactWithdrawAmount()
    local shoppingAmount = self:GetDetailShoppingAmount()

    self:SetButtonEnabled(f.withdrawOne, not busy and inDetail and stored >= 1)
    self:SetButtonEnabled(f.withdrawStack, not busy and inDetail and stored >= 1)
    self:SetButtonEnabled(f.withdrawItemAll, not busy and inDetail and stored >= 1)
    self:SetButtonEnabled(f.withdrawExact, not busy and inDetail and stored >= 1 and exactAmount >= 1)
    self:SetButtonEnabled(f.addShopping, not busy and inDetail and shoppingAmount >= 1)
    self:SetButtonEnabled(f.detailBack, not busy)

    if f.depositPreview then
        self:SetButtonEnabled(f.depositPreview.confirm, not busy and self.depositPreview ~= nil)
        self:SetButtonEnabled(f.depositPreview.cancel, true)
    end

    self:UpdateSortButton()
    self:UpdatePreviewToggleButton()
    self:UpdateQuickWithdrawControls()
    self:UpdateShoppingAmountPromptControls()
    self:UpdateUndoButton()
end

function RB:SetListRowInset(inset)
    local f = self.frame
    local rowWidth = (f.list:GetWidth() or 0) - LIST_ROW_INSET - inset

    f.listHeader:SetPoint("RIGHT", -inset, 0)
    for _, row in ipairs(f.rows) do
        row:SetPoint("RIGHT", -inset, 0)
        row.fillWidth = rowWidth > 0 and rowWidth or nil
    end
end

function RB:ClearRows()
    local f = self.frame

    f.listScroll:Hide()
    self:SetListRowInset(LIST_ROW_INSET)

    for _, row in ipairs(f.rows) do
        row.kind = nil
        row.categoryId = nil
        row.item = nil
        if row.fill then
            row.fill:SetWidth(1)
            row.fill:Hide()
        end
        row.icon:Show()
        row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
        row.text:SetPoint("RIGHT", -170, 0)
        row.text:SetText("")
        row.count:SetText("")
        row:Hide()
    end
end

function RB:SetRowFill(row, value, maxValue)
    if not row or not row.fill then
        return
    end

    value = tonumber(value) or 0
    maxValue = tonumber(maxValue) or 0

    if value <= 0 or maxValue <= 0 then
        row.fill:SetWidth(1)
        row.fill:Hide()
        return
    end

    -- fillWidth is set when the row inset changes, because GetWidth can still
    -- report the old anchors until the next layout pass.
    local width = row.fillWidth or row:GetWidth() or 0
    if width <= 0 then
        width = 640
    end

    local pct = value / maxValue
    if pct < 0.04 then
        pct = 0.04
    elseif pct > 1.0 then
        pct = 1.0
    end

    row.fill:SetWidth(math.floor(width * pct))
    row.fill:Show()
end

function RB:SetEmptyRow(text)
    local f = self.frame
    local row = f.rows[1]

    row.kind = nil
    row.categoryId = nil
    row.item = nil
    if row.fill then
        row.fill:SetWidth(1)
        row.fill:Hide()
    end
    row.icon:Show()
    row.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
    row.text:ClearAllPoints()
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
    row.text:SetPoint("RIGHT", -170, 0)
    row.text:SetText(text or "Nothing to show.")
    row.count:SetText("")
    row:Show()
end

-- Shows ROW_COUNT entries of self.listEntries starting at the scroll offset.
-- scrollKey identifies what the list holds; a new key starts back at the top,
-- while re-rendering the same list (e.g. after a withdraw) keeps the position.
function RB:SetListEntries(entries, fillRow, scrollKey)
    local f = self.frame

    self.listEntries = entries or {}
    self.listFillRow = fillRow

    if self.listScrollKey ~= scrollKey then
        self.listScrollKey = scrollKey
        f.listScroll.offset = 0
        ReagentBankUIListScrollFrameScrollBar:SetValue(0)
    end

    self:RefreshListWindow()
end

function RB:RefreshListWindow()
    local f = self.frame
    local entries = self.listEntries or {}

    if self.refreshingListWindow or not self.listFillRow then
        return
    end

    -- FauxScrollFrame_Update can clamp the scrollbar, which fires
    -- OnVerticalScroll and would re-enter this function.
    self.refreshingListWindow = true
    self:ClearRows()
    FauxScrollFrame_Update(f.listScroll, #entries, ROW_COUNT, ROW_HEIGHT + ROW_SPACING)
    self.refreshingListWindow = false

    if f.listScroll:IsShown() then
        self:SetListRowInset(LIST_SCROLL_ROW_INSET)
    end

    local offset = tonumber(f.listScroll.offset) or 0
    offset = math.max(0, math.min(offset, math.max(#entries - ROW_COUNT, 0)))

    for rowIndex = 1, ROW_COUNT do
        local entry = entries[offset + rowIndex]
        if not entry then
            break
        end

        self.listFillRow(f.rows[rowIndex], entry)
        f.rows[rowIndex]:Show()
    end
end

function RB:RenderRoot(preserveStatus)
    self:HideWithdrawPrompt()
    self:HideShoppingAmountPrompt()
    self:CreateFrame()

    self.currentView = "root"
    self.currentCategoryId = nil
    self.currentPage = 0
    self.totalPages = 1
    self.detailItem = nil

    local f = self.frame
    f:Show()
    local grandTypes = 0
    local grandAmount = 0
    for _, info in pairs(self.categories or {}) do
        grandTypes = grandTypes + (tonumber(info.types) or 0)
        grandAmount = grandAmount + (tonumber(info.amount) or 0)
    end

    f.title:SetText("Reagent Bank")
    f.modeText:SetText((self.accountWide and "|cff80ff80Account-wide|r" or "|cffffcc80Character-only|r") ..
        "  |  " .. FormatCount(grandTypes) .. " types / " .. FormatCount(grandAmount) .. " reagents")
    f.pageText:SetText("")
    f.headerName:ClearAllPoints()
    f.headerName:SetPoint("LEFT", 32, 0)
    f.headerName:SetText("Category")
    f.headerCount:SetText("Types / Total")

    self:SetCommonVisibility("root")
    self:ClearRows()

    local categories = {}
    local maxCategoryAmount = 0

    for index, category in ipairs(CATEGORY_ORDER) do
        local info = self.categories and self.categories[category.id] or nil
        local types = info and info.types or 0
        local amount = info and info.amount or 0

        table.insert(categories, {
            id = category.id,
            name = category.name,
            sample = category.sample,
            order = index,
            types = types,
            amount = amount,
        })

        if amount > maxCategoryAmount then
            maxCategoryAmount = amount
        end
    end

    local categorySortMode = self:GetCategorySortMode()
    if categorySortMode ~= "order" then
        table.sort(categories, function(a, b)
            if categorySortMode == "name" then
                if a.name ~= b.name then
                    return a.name < b.name
                end
            elseif categorySortMode == "types" then
                if a.types ~= b.types then
                    return a.types > b.types
                end
            elseif categorySortMode == "amount" then
                if a.amount ~= b.amount then
                    return a.amount > b.amount
                end
            end

            return a.order < b.order
        end)
    end

    self:SetListEntries(categories, function(row, category)
        local icon = GetItemIcon(category.sample) or "Interface\\Icons\\INV_Misc_QuestionMark"

        row.kind = "category"
        row.categoryId = category.id
        row.item = nil
        row.icon:Show()
        row.icon:SetTexture(icon)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
        row.text:SetPoint("RIGHT", -170, 0)
        row.text:SetText(category.name)
        row.count:SetText(FormatCount(category.types) .. " types / " .. FormatCount(category.amount))
        RB:SetRowFill(row, category.amount, maxCategoryAmount)
    end, "root")

    self:UpdateControls()

    if not preserveStatus and not self.busyKind then
        self:Status("Updated " .. SafeDate() .. ".", 0.45, 1.00, 0.45)
    end
end

function RB:RenderCategory(preserveStatus)
    self:HideShoppingAmountPrompt()
    self:CreateFrame()

    self.currentView = "category"
    self.detailItem = nil

    local f = self.frame
    local category = CATEGORY_BY_ID[self.currentCategoryId]
    local categoryName = category and category.name or "Category"
    local typeCount = tonumber(self.categoryTypeCount) or 0
    local amount = tonumber(self.categoryAmount) or 0
    local page = tonumber(self.currentPage) or 0
    local totalPages = math.max(tonumber(self.totalPages) or 1, 1)

    f:Show()
    f.title:SetText(categoryName)
    f.modeText:SetText(FormatCount(typeCount) .. " types / " .. FormatCount(amount) .. " reagents")
    f.pageText:SetText("Page " .. tostring(page + 1) .. "/" .. tostring(totalPages))
    f.headerName:ClearAllPoints()
    f.headerName:SetPoint("LEFT", 32, 0)
    f.headerName:SetText("Item")
    f.headerCount:SetText("Stored")

    self:SetCommonVisibility("category")
    self:ClearRows()

    local missingItemInfo = false
    local maxItemAmount = 0

    for _, item in ipairs(self.items or {}) do
        local amountValue = tonumber(item.amount) or 0
        if amountValue > maxItemAmount then
            maxItemAmount = amountValue
        end
    end

    for _, item in ipairs(self.items or {}) do
        local _, _, _, _, missingInfo = GetItemDisplay(item.entry)
        if missingInfo then
            missingItemInfo = true
        end
    end

    self:SetListEntries(self.items, function(row, item)
        local icon, name, link = GetItemDisplay(item.entry)

        row.kind = "item"
        row.item = item
        row.icon:Show()
        row.icon:SetTexture(icon)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
        row.text:SetPoint("RIGHT", -170, 0)
        row.text:SetText(link or name)
        row.count:SetText("x" .. FormatCount(item.amount))
        RB:SetRowFill(row, item.amount, maxItemAmount)
    end, "category:" .. tostring(self.currentCategoryId) .. ":" .. tostring(page))

    if not self.items or #self.items == 0 then
        self:SetEmptyRow("No stored reagents in this category.")
        missingItemInfo = false
    end

    if missingItemInfo then
        self:QueueItemInfoRefresh()
    else
        self:ClearItemInfoRefresh()
    end

    self:UpdateControls()

    if not preserveStatus and not self.busyKind then
        self:Status("Updated " .. SafeDate() .. ".", 0.45, 1.00, 0.45)
    end
end

function RB:RenderShoppingList(preserveStatus)
    self:HideWithdrawPrompt()
    self:HideDepositPreview()
    self:CreateFrame()
    self:NormalizeShoppingList()

    local wasShoppingView = self.currentView == "shopping"
    self.currentView = "shopping"
    self.currentCategoryId = nil
    self.detailItem = nil

    local f = self.frame
    local items = self:GetShoppingListItems()
    local total = 0
    local maxAmount = 0

    for _, item in ipairs(items) do
        local amount = tonumber(item.amount) or 0
        total = total + amount
        if amount > maxAmount then
            maxAmount = amount
        end
    end

    local totalPages = math.max(math.ceil(#items / ROW_COUNT), 1)
    local page = wasShoppingView and (tonumber(self.currentPage) or 0) or 0
    if page < 0 then
        page = 0
    elseif page >= totalPages then
        page = totalPages - 1
    end

    self.currentPage = page
    self.totalPages = totalPages

    f:Show()
    f.title:SetText("AH Shopping List")
    local summary = FormatCount(total) .. " reagent(s) across " .. tostring(#items) .. " item type(s)"
    local boughtTotal = self:GetShoppingBoughtTotal()
    if boughtTotal > 0 then
        summary = summary .. ", " .. FormatCount(boughtTotal) .. " bought"
    end
    f.modeText:SetText(summary)
    f.pageText:SetText("")
    f.shoppingPageText:SetText("Page " .. tostring(page + 1) .. "/" .. tostring(totalPages))
    f.headerName:ClearAllPoints()
    f.headerName:SetPoint("LEFT", 32, 0)
    f.headerName:SetText("Item")
    f.headerCount:SetText("Left / Bought / Bags")

    self:SetCommonVisibility("shopping")
    self:ClearRows()
    -- The AH list pages on its own and always fits, so no scroll state.
    self.listFillRow = nil
    self.listScrollKey = nil

    local missingItemInfo = false
    local startIndex = (page * ROW_COUNT) + 1

    for rowIndex = 1, ROW_COUNT do
        local item = items[startIndex + rowIndex - 1]
        local row = f.rows[rowIndex]
        if row then
            if not item then
                break
            end

            local icon, name, link, stackCount, missingInfo = GetItemDisplay(item.entry)

            if missingInfo then
                missingItemInfo = true
            end

            local bagCount = 0
            if GetItemCount then
                bagCount = tonumber(GetItemCount(item.entry, false)) or 0
            end

            row.kind = "shopping"
            row.categoryId = nil
            row.item = item
            row.icon:Show()
            row.icon:SetTexture(icon)
            row.text:ClearAllPoints()
            row.text:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
            row.text:SetPoint("RIGHT", -170, 0)
            row.text:SetText(link or name)
            row.count:SetText("x" .. FormatCount(item.amount) .. " / " .. self:FormatShoppingBought(item.entry) .. " / x" .. FormatCount(bagCount))
            self:SetRowFill(row, item.amount, maxAmount)
            row:Show()
        end
    end

    if #items == 0 then
        self:SetEmptyRow("AH shopping list is empty.")
        missingItemInfo = false
    end

    if missingItemInfo then
        self:QueueItemInfoRefresh()
    else
        self:ClearItemInfoRefresh()
    end

    self:UpdateControls()

    if not preserveStatus and not self.busyKind then
        self:Status("Left-click searches the AH. Right-click edits amount. Ctrl+Shift-click any item to add it.", 0.82, 0.82, 0.82)
    end
end

function RB:ShowDetail(item, preserveStatus)
    self:HideWithdrawPrompt()
    self:HideShoppingAmountPrompt()
    if not item or not item.entry then
        return
    end

    self:CreateFrame()

    self.detailItem = item
    self.currentView = "detail"

    local f = self.frame
    local icon, name, link, stackCount, missingInfo = GetItemDisplay(item.entry)
    local stored = tonumber(item.amount) or 0

    f:Show()
    f.title:SetText("Withdraw")
    f.modeText:SetText("")
    self:SetCommonVisibility("detail")

    f.detailIcon:SetTexture(icon)
    f.detailName:SetText(link or name)
    f.detailStored:SetText("Stored: " .. FormatCount(stored))

    if f.exactBox then
        f.exactBox:SetText("")
        f.exactBox:ClearFocus()
    end

    if f.shoppingAmountBox then
        f.shoppingAmountBox:SetText("")
        f.shoppingAmountBox:ClearFocus()
    end

    if missingInfo then
        self:QueueItemInfoRefresh()
    else
        self:ClearItemInfoRefresh()
    end

    self:UpdateControls()

    if not preserveStatus and not self.busyKind then
        self:Status("Choose a withdraw amount.", 0.82, 0.82, 0.82)
    end
end

function RB:Close()
    self:HideWithdrawPrompt()
    self:HideShoppingAmountPrompt()
    self:HideDepositPreview()
    self.awaitingView = nil
    self.busyKind = nil
    self.busyText = nil
    self.busyStartedAt = nil
    self.pendingRefresh = nil
    self.mutationNeedsRefresh = nil
    self:ClearItemInfoRefresh()

    HideTooltip()

    if self.frame then
        self:UpdateControls()
        self.frame:Hide()
    end
end

function RB:HandleOK(okText)
    okText = Trim(okText or "")

    local lowerText = string.lower(okText)
    if string.find(lowerText, "refresh") then
        okText = "Refresh acknowledged. Waiting for server data..."
    end

    if okText == "" then
        okText = "Server acknowledged."
    end

    if self.lastTransaction and self.lastTransaction.updatedAt and GetTime() - self.lastTransaction.updatedAt <= 2.0 then
        okText = okText .. " " .. self:BuildTransactionSummary(self.lastTransaction)
    end

    -- Do not clear autoDepositQuietUntil here. Some server responses send OK first
    -- and then follow up with ROOT/CATEGORY data. Keeping the quiet window alive
    -- prevents the hidden main frame from being created and shown by that follow-up data.
    self:ClearBusy(okText, 0.45, 1.00, 0.45)
    self:UpdateUndoButton()

    if self.mutationNeedsRefresh then
        local refreshTarget = self.mutationNeedsRefresh
        self.mutationNeedsRefresh = nil

        if refreshTarget == "category" and self.currentCategoryId then
            self:ScheduleRefresh(0.25, "category", self.currentCategoryId, self.currentPage or 0)
        else
            self:ScheduleRefresh(0.25, "root", nil, 0)
        end
    end
end

function RB:HandleError(errText)
    errText = Trim(errText or "Server error.")

    if self:IsAutoDepositQuietActive() then
        self.autoDepositQuietUntil = nil
        self.autoDepositSuppressViewUntil = nil
        PrintAddon("periodic auto-deposit skipped: " .. errText)
        return
    end

    self.mutationNeedsRefresh = nil
    self:CreateFrame()
    self.frame:Show()
    self:ClearBusy(errText, 1.00, 0.35, 0.35)
end

function RB:HandleProtocol(message)
    if type(message) ~= "string" or string.sub(message, 1, 6) ~= "RBANK:" then
        return false
    end

    local okText = string.match(message, "^RBANK:OK:(.*)$")
    if okText then
        self:HandleOK(okText)
        return true
    end

    local errText = string.match(message, "^RBANK:ERR:(.*)$")
    if errText then
        self:HandleError(errText)
        return true
    end

    local parts = SplitColon(message)
    local recordType = parts[2]

    if not recordType then
        return true
    end

    if recordType == "PREVIEW" then
        local previewKind = parts[3]

        if previewKind == "BEGIN" then
            self.pendingDepositPreview = {
                scope = tostring(parts[4] or "all"),
                categoryId = tonumber(parts[5]) or 0,
                total = tonumber(parts[6]) or 0,
                expected = tonumber(parts[7]) or 0,
                items = {},
            }
            return true
        elseif previewKind == "ITEM" then
            if self.pendingDepositPreview then
                local itemEntry = tonumber(parts[4])
                local amount = tonumber(parts[5]) or 0

                if itemEntry and itemEntry > 0 and amount > 0 then
                    table.insert(self.pendingDepositPreview.items, {
                        entry = math.floor(itemEntry),
                        amount = math.floor(amount),
                    })
                end
            end
            return true
        elseif previewKind == "END" then
            local preview = self.pendingDepositPreview
            self.pendingDepositPreview = nil

            if preview then
                preview.scope = tostring(parts[4] or preview.scope or "all")
                preview.categoryId = tonumber(parts[5]) or preview.categoryId or 0
                preview.total = tonumber(parts[6]) or preview.total or 0
                self:ShowDepositPreview(preview)
            end

            return true
        end

        return true
    end

    if recordType == "CHECK" then
        local checkKind = parts[3]

        if checkKind == "BEGIN" then
            self.pendingBankCheck = {
                requestId = tonumber(parts[4]) or 0,
                expected = tonumber(parts[5]) or 0,
                counts = {},
            }
            return true
        elseif checkKind == "ITEM" then
            if self.pendingBankCheck then
                local itemEntry = tonumber(parts[4])
                local amount = tonumber(parts[5]) or 0

                if itemEntry and itemEntry > 0 then
                    local storedAmount = math.max(0, math.floor(amount))
                    self.pendingBankCheck.counts[math.floor(itemEntry)] = storedAmount
                    self:CacheBankItemCount(itemEntry, storedAmount)
                end
            end
            return true
        elseif checkKind == "END" then
            local check = self.pendingBankCheck
            self.pendingBankCheck = nil

            if check then
                local requestId = tonumber(parts[4]) or check.requestId or 0

                self:HandleProfessionPrefetchResponse(requestId, check.counts)
                local pending = self.pendingTradeSkillChecks and self.pendingTradeSkillChecks[requestId] or nil

                if pending then
                    self.tradeSkillBankCounts = check.counts or {}
                    self.tradeSkillBankCountsKey = pending.key
                    self.pendingTradeSkillChecks[requestId] = nil
                    if self.pendingTradeSkillCheckKey == pending.key then
                        self.pendingTradeSkillCheckKey = nil
                        self.pendingTradeSkillCheckUntil = nil
                    end

                    self:CompletePendingShoppingListImport(pending.key)
                    self:UpdateTradeSkillControls()
                end

                local pendingTooltip = self.pendingTooltipBankChecks and self.pendingTooltipBankChecks[requestId] or nil
                if pendingTooltip then
                    local itemEntry = tonumber(pendingTooltip.itemEntry)
                    if itemEntry and itemEntry > 0 then
                        itemEntry = math.floor(itemEntry)
                        self:CacheBankItemCount(itemEntry, tonumber(check.counts and check.counts[itemEntry]) or 0)
                        if self.tooltipBankCheckPendingByItem then
                            self.tooltipBankCheckPendingByItem[itemEntry] = nil
                        end
                        self:RefreshOpenBankCountTooltips(itemEntry)
                    end
                    self.pendingTooltipBankChecks[requestId] = nil
                end
            end

            return true
        end

        return true
    end

    if recordType == "TX" then
        local txKind = parts[3]

        if txKind == "BEGIN" then
            local action = self:NormalizeTransactionAction(parts[4])
            if action then
                local context = self:TakeTransactionContext(action)
                self.pendingTransaction = {
                    action = action,
                    source = SafeTransactionSource(parts[7] or (context and context.source) or "manual"),
                    label = context and context.label or nil,
                    total = tonumber(parts[5]) or 0,
                    expected = tonumber(parts[6]) or 0,
                    items = {},
                }
            else
                self.pendingTransaction = nil
            end

            return true
        elseif txKind == "ITEM" then
            if self.pendingTransaction then
                local itemEntry = tonumber(parts[4])
                local amount = tonumber(parts[5]) or 0

                if itemEntry and itemEntry > 0 and amount > 0 then
                    table.insert(self.pendingTransaction.items, {
                        entry = math.floor(itemEntry),
                        amount = math.floor(amount),
                    })
                end
            end

            return true
        elseif txKind == "SOURCE" then
            if self.pendingTransaction then
                self.pendingTransaction.source = SafeTransactionSource(parts[4] or self.pendingTransaction.source)
            end

            return true
        elseif txKind == "END" then
            local transaction = self.pendingTransaction
            self.pendingTransaction = nil

            if transaction then
                local action = self:NormalizeTransactionAction(parts[4])
                if action and action == transaction.action then
                    transaction.total = tonumber(parts[5]) or transaction.total or 0
                    self:FinalizeTransaction(transaction)
                end
            end

            return true
        end

        return true
    end

    if recordType == "BEGIN" then
        local view = parts[3]

        if view == "ROOT" then
            self.pendingView = "root"
            self.pendingCategories = {}
            self.accountWide = tonumber(parts[4]) == 1
        elseif view == "CATEGORY" then
            local categoryId = tonumber(parts[4])
            if categoryId then
                self.pendingView = "category"
                self.pendingItems = {}
                self.pendingCategoryId = categoryId
                self.pendingPage = tonumber(parts[5]) or 0
                self.pendingTotalPages = tonumber(parts[6]) or 1
                self.pendingTypeCount = tonumber(parts[7]) or 0
                self.pendingAmount = tonumber(parts[8]) or 0
                self.pendingSortMode = NormalizeItemSortMode(parts[9] or self:GetItemSortMode())
            end
        end

        return true
    end

    if recordType == "CAT" and self.pendingView == "root" then
        local categoryId = tonumber(parts[3])
        local sample = tonumber(parts[4]) or 0
        local types = tonumber(parts[5]) or 0
        local amount = tonumber(parts[6]) or 0

        if categoryId and CATEGORY_BY_ID[categoryId] then
            self.pendingCategories[categoryId] = {
                sample = sample,
                types = math.max(0, math.floor(types)),
                amount = math.max(0, math.floor(amount)),
            }
        end

        return true
    end

    if recordType == "ITEM" and self.pendingView == "category" then
        local itemEntry = tonumber(parts[3])
        local amount = tonumber(parts[4]) or 0

        if itemEntry and itemEntry > 0 then
            self:CacheBankItemCount(itemEntry, amount)
        end

        if itemEntry and itemEntry > 0 and amount > 0 then
            table.insert(self.pendingItems, {
                entry = math.floor(itemEntry),
                amount = math.floor(amount),
            })
        end

        return true
    end

    if recordType == "END" then
        local view = parts[3]

        if view == "ROOT" and self.pendingView == "root" then
            self.categories = self.pendingCategories or {}
            self.pendingCategories = nil
            self.pendingView = nil
            self.awaitingView = nil
            self.mutationNeedsRefresh = nil

            self:ClearBusy()

            if self:IsAutoDepositViewSuppressed() then
                self.autoDepositSuppressViewUntil = nil
                return true
            end

            self:RenderRoot(true)
            self:Status("Updated " .. SafeDate() .. ".", 0.45, 1.00, 0.45)
        elseif view == "CATEGORY" and self.pendingView == "category" then
            self.currentCategoryId = self.pendingCategoryId
            self.currentPage = self.pendingPage or 0
            self.totalPages = self.pendingTotalPages or 1
            self.categoryTypeCount = self.pendingTypeCount or 0
            self.categoryAmount = self.pendingAmount or 0
            self.currentSortMode = NormalizeItemSortMode(self.pendingSortMode or self:GetItemSortMode())
            self.items = self.pendingItems or {}
            self.pendingItems = nil
            self.pendingView = nil
            self.awaitingView = nil
            self.mutationNeedsRefresh = nil

            self:ClearBusy()

            if self:IsAutoDepositViewSuppressed() then
                self.autoDepositSuppressViewUntil = nil
                return true
            end

            self:RenderCategory(true)
            self:Status("Updated " .. SafeDate() .. ".", 0.45, 1.00, 0.45)
        end

        return true
    end

    return true
end

local function SystemMessageFilter(chatFrame, event, message, ...)
    if RB:HandleProtocol(message) then
        return true
    end

    return false
end

if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemMessageFilter)
else
    RB:RegisterEvent("CHAT_MSG_SYSTEM")
end

RB:InstallBankCountTooltipHooks()

-- Auction replies that mean a queued bid did not go through.
local AUCTION_BID_FAILED_MESSAGES = {}
for _, key in ipairs({
    "ERR_ITEM_NOT_FOUND",
    "ERR_NOT_ENOUGH_MONEY",
    "ERR_AUCTION_BID_OWN",
    "ERR_AUCTION_HIGHER_BID",
    "ERR_AUCTION_BID_INCREMENT",
    "ERR_AUCTION_DATABASE_ERROR",
    "ERR_RESTRICTED_ACCOUNT",
}) do
    local text = _G[key]
    if type(text) == "string" and text ~= "" then
        AUCTION_BID_FAILED_MESSAGES[text] = true
    end
end

-- Ctrl+Shift-click on any item (bags, Auction House, chat links) opens the AH
-- list amount popup. Alt is left alone because Auctionator uses Alt-click in
-- the bags while the Auction House is open.
if hooksecurefunc and HandleModifiedItemClick then
    hooksecurefunc("HandleModifiedItemClick", function(link)
        if IsControlKeyDown() and IsShiftKeyDown() and not IsAltKeyDown() then
            local itemEntry = ParseItemIdFromLink(link)
            if itemEntry then
                RB:ShowShoppingAmountPopup(itemEntry)
            end
        end
    end)
end

if hooksecurefunc and PlaceAuctionBid then
    hooksecurefunc("PlaceAuctionBid", function(listType, index, bid)
        RB:OnPlaceAuctionBid(listType, index, bid)
    end)
end

-- Kept off RB's own frame: RB only takes CHAT_MSG_SYSTEM as an event when the
-- chat filter is missing, and HandleProtocol must not run twice.
local auctionBidFrame = CreateFrame("Frame")
auctionBidFrame:RegisterEvent("CHAT_MSG_SYSTEM")
auctionBidFrame:RegisterEvent("UI_ERROR_MESSAGE")
auctionBidFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if not RB.pendingAuctionBids or #RB.pendingAuctionBids == 0 then
        return
    end

    if event == "CHAT_MSG_SYSTEM" then
        if ERR_AUCTION_BID_PLACED and arg1 == ERR_AUCTION_BID_PLACED then
            RB:HandleAuctionBidAccepted()
        end
    elseif event == "UI_ERROR_MESSAGE" then
        -- 3.3.5 passes the message first; later clients pass a type first.
        local message = type(arg2) == "string" and arg2 or arg1
        if AUCTION_BID_FAILED_MESSAGES[message] then
            RB:PopPendingAuctionBid()
        end
    end
end)

SLASH_REAGENTBANKUI1 = "/rbank"
SLASH_REAGENTBANKUI2 = "/reagentbank"
SLASH_REAGENTBANKUI3 = "/rbankui"
SlashCmdList["REAGENTBANKUI"] = function(msg)
    msg = Trim(msg or "")

    local command, value = string.match(msg, "^(%S+)%s*(.-)$")
    command = string.lower(command or "")

    if command == "" or command == "open" or command == "show" then
        RB:CreateFrame()
        RB.frame:Show()
        RB:RequestRoot()
        return
    end

    if command == "hide" or command == "close" then
        RB:Close()
        return
    end

    if command == "refresh" then
        if RB.currentView == "category" and RB.currentCategoryId then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage or 0)
        elseif RB.currentView == "detail" and RB.currentCategoryId then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage or 0)
        else
            RB:RequestRoot()
        end
        return
    end

    if command == "plan" then
        local count = tonumber(value)
        if count then
            RB:SetTradeSkillPrepareCount(count, true)
        end

        RB:PrintTradeSkillShoppingList()
        RB:UpdateTradeSkillControls()
        return
    end

    if command == "shopping" or command == "shoppinglist" or command == "ahlist" or command == "buy" then
        RB:HandleShoppingListSlash(value)
        return
    end

    if command == "craft" or command == "prepare" or command == "withdrawcraft" then
        local count = tonumber(value)
        if count then
            RB:SetTradeSkillPrepareCount(count, true)
        end

        RB:WithdrawNeededForSelectedRecipe()
        return
    end

    if command == "lowstock" or command == "restock" then
        local count = tonumber(value)
        if count then
            RB:SetLowStockCraftCount(count)
        else
            PrintAddon("low-stock alerts currently check enough reagents for " .. tostring(RB:GetLowStockCraftCount()) .. " craft(s).")
        end
        return
    end

    if command == "sort" then
        ReagentBankUIDB = ReagentBankUIDB or {}
        local lowerValue = string.lower(value or "")

        if lowerValue == "" or lowerValue == "cycle" then
            if RB.currentView == "root" or not RB.currentCategoryId then
                ReagentBankUIDB.categorySortMode = CycleCategorySortMode(ReagentBankUIDB.categorySortMode)
                RB:RenderRoot()
                PrintAddon("category sort set to " .. CategorySortLabel(ReagentBankUIDB.categorySortMode) .. ".")
            else
                ReagentBankUIDB.sortMode = CycleItemSortMode(ReagentBankUIDB.sortMode)
                RB:RequestCategory(RB.currentCategoryId, 0)
                PrintAddon("item sort set to " .. ItemSortLabel(ReagentBankUIDB.sortMode) .. ".")
            end
        else
            ReagentBankUIDB.sortMode = NormalizeItemSortMode(lowerValue)
            if RB.currentCategoryId then
                RB:RequestCategory(RB.currentCategoryId, 0)
            end
            PrintAddon("item sort set to " .. ItemSortLabel(ReagentBankUIDB.sortMode) .. ".")
        end

        return
    end

    if command == "preview" or command == "confirm" or command == "confirmation" then
        local lowerValue = string.lower(value or "")

        if lowerValue == "on" or lowerValue == "1" or lowerValue == "true" or lowerValue == "yes" then
            RB:SetDepositPreviewEnabled(true)
        elseif lowerValue == "off" or lowerValue == "0" or lowerValue == "false" or lowerValue == "no" then
            RB:SetDepositPreviewEnabled(false)
        else
            RB:ToggleDepositPreviewEnabled()
        end

        return
    end

    if command == "settings" or command == "options" or command == "config" then
        RB:OpenSettings()
        return
    end

    if command == "ticker" or command == "autoticker" or command == "periodic" then
        local lowerValue = string.lower(Trim(value or ""))

        if lowerValue == "" or lowerValue == "settings" or lowerValue == "options" then
            RB:OpenSettings()
        elseif lowerValue == "off" or lowerValue == "0" or lowerValue == "false" then
            RB:SetAutoDepositTickerSeconds(0)
        else
            local seconds = tonumber(lowerValue)
            if seconds then
                RB:SetAutoDepositTickerSeconds(seconds)
            else
                PrintAddon("usage: /rbank ticker 0|30-3600")
            end
        end

        return
    end

    if command == "autodeposit" then
        ReagentBankUIDB = ReagentBankUIDB or {}
        local lowerValue = string.lower(value or "")

        if lowerValue == "on" or lowerValue == "1" or lowerValue == "true" then
            ReagentBankUIDB.autoDepositLeftovers = true
        elseif lowerValue == "off" or lowerValue == "0" or lowerValue == "false" then
            ReagentBankUIDB.autoDepositLeftovers = false
        else
            ReagentBankUIDB.autoDepositLeftovers = not ReagentBankUIDB.autoDepositLeftovers
        end

        if not ReagentBankUIDB.autoDepositLeftovers then
            RB.pendingAutoDepositLeftovers = nil
            RB.pendingAutoDepositAt = nil
        end

        RB:UpdateTradeSkillControls()
        PrintAddon("auto-deposit leftovers on profession close " .. (ReagentBankUIDB.autoDepositLeftovers and "enabled." or "disabled."))
        return
    end

    if command == "undo" or command == "reverse" then
        RB:ReverseLastTransaction()
        return
    end

    if command == "scale" then
        local numberValue = tonumber(value)

        if numberValue then
            RB:SetScaleValue(numberValue)
            return
        end

        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99ReagentBankUI|r usage: /rbank scale 0.90")
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99ReagentBankUI|r commands:")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank refresh")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank hide")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank sort id|name|amount|amount_asc")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank preview on|off")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank plan 5")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank ahlist")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank ahlist recipe|add itemId amount|print|clear")
    DEFAULT_CHAT_FRAME:AddMessage("  Ctrl+Shift-click any item to add it to the AH list")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank craft 5")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank lowstock 5")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank undo")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank settings")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank scale 0.75 - 1.20")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank ticker 0|30-3600")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank autodeposit on|off")
end

RB:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...

        if addonName == ADDON_NAME then
            ReagentBankUIDB = ReagentBankUIDB or {}
            local savedScale = tonumber(ReagentBankUIDB.scale)
            if ReagentBankUIDB.scale == nil or (savedScale and math.abs(savedScale - 0.92) < 0.001) then
                ReagentBankUIDB.scale = DEFAULT_SCALE
            end
            -- Left over from the old custom skin.
            ReagentBankUIDB.colorTheme = nil
            ReagentBankUIDB.frameStyle = nil
            ReagentBankUIDB.settingsPoint = nil
            if ReagentBankUIDB.autoDepositLeftovers == nil then
                ReagentBankUIDB.autoDepositLeftovers = false
            end
            ReagentBankUIDB.autoDepositTickerSeconds = self:ClampAutoDepositTickerSeconds(ReagentBankUIDB.autoDepositTickerSeconds)
            self:RestartAutoDepositTicker()
            ReagentBankUIDB.sortMode = NormalizeItemSortMode(ReagentBankUIDB.sortMode)
            ReagentBankUIDB.categorySortMode = NormalizeCategorySortMode(ReagentBankUIDB.categorySortMode)
            self:NormalizeShoppingList()
            if ReagentBankUIDB.tradeSkillPrepareCount == nil then
                ReagentBankUIDB.tradeSkillPrepareCount = 1
            else
                ReagentBankUIDB.tradeSkillPrepareCount = self:ClampTradeSkillPrepareCount(ReagentBankUIDB.tradeSkillPrepareCount)
            end
            ReagentBankUIDB.lowStockCrafts = self:ClampTradeSkillPrepareCount(ReagentBankUIDB.lowStockCrafts or LOW_STOCK_DEFAULT_CRAFTS)
            self:ApplySavedPosition()
            self:ApplyScale()
            self:CreatePaperDollButton()
            self:CreateTradeSkillControls()
            self:FixAuctionatorShoppingListOptions()
        elseif addonName == "Blizzard_TradeSkillUI" then
            self:CreateTradeSkillControls()
        elseif addonName == "Auctionator" then
            self:FixAuctionatorShoppingListOptions()
        end
    elseif event == "PLAYER_LOGIN" then
        self:NormalizeShoppingList()
        self:RestartAutoDepositTicker()
        self:CreatePaperDollButton()
        self:CreateSettingsPanel()
        self:CreateTradeSkillControls()
        self:FixAuctionatorShoppingListOptions()
    elseif event == "TRADE_SKILL_SHOW" then
        self:CreateTradeSkillControls()
        self:DockTradeSkillPanel()
        self:PrefetchProfessionBankCounts()
        self:UpdateTradeSkillControls()
    elseif event == "TRADE_SKILL_UPDATE" then
        self:CreateTradeSkillControls()
        self:PrefetchProfessionBankCounts()
        self:UpdateTradeSkillControls()
    elseif event == "BAG_UPDATE" then
        self:ScheduleTradeSkillBagRefresh()
    elseif event == "TRADE_SKILL_CLOSE" then
        self.pendingTradeSkillBagRefreshAt = nil
        self:ResetProfessionBankPrefetch()
        self:HideReagentBankOverlays()
        self:HandleTradeSkillClosed()
    elseif event == "AUCTION_HOUSE_SHOW" then
        self.auctionShoppingFrameDismissed = false
        self:ShowAuctionShoppingFrame()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        self.auctionShoppingFrameDismissed = false
        self:HideAuctionShoppingFrame(false)
    elseif event == "CHAT_MSG_SYSTEM" then
        local message = ...
        self:HandleProtocol(message)
    end
end)

RB:RegisterEvent("ADDON_LOADED")
RB:RegisterEvent("PLAYER_LOGIN")
RB:RegisterEvent("TRADE_SKILL_SHOW")
RB:RegisterEvent("TRADE_SKILL_UPDATE")
RB:RegisterEvent("TRADE_SKILL_CLOSE")
RB:RegisterEvent("BAG_UPDATE")
RB:RegisterEvent("AUCTION_HOUSE_SHOW")
RB:RegisterEvent("AUCTION_HOUSE_CLOSED")
