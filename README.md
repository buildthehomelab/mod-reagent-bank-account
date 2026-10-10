# Reagent Bank Account

A reagent bank system for AzerothCore with a required WotLK 3.3.5a UI addon.

This module adds a server-backed reagent bank for trade goods, gems, and crafting materials. The addon provides the full player-facing interface: browsing stored reagents, depositing, withdrawing, profession prep, and Auction House shopping-list support.

<img width="1273" height="1097" alt="Reagent1" src="https://github.com/user-attachments/assets/803a5f8d-50e2-495e-9169-692e12ff9c69" />

---

## Features

- Stores reagents and crafting materials server-side
- Account-wide or character-wide storage through config
- Required addon UI, no banker NPC needed
- Category browsing for common reagent types
- Deposit all reagents
- Deposit by category
- Withdraw all, category, stack, single item, or exact amount
- Optional deposit preview confirmation
- Reverse last deposit/withdraw transaction
- Sort categories and items by several modes
- Movable, scalable addon window built from the default Blizzard UI
- Periodic auto-deposit timer (default every 300 seconds; paused while a profession window is open)
- Character paperdoll launcher button

### What counts as a reagent

- Trade Goods and Gems that stack
- Quest- and Misc-class items that a profession recipe uses, such as Black Diamond, Shoveltusk Meat and Tough Ram Meat. Each one is filed under the category of the profession that uses it most (cooking items go under Meat). You don't need to know the recipe. Potions, food and other consumables stay in your bags even when a recipe uses them
- Anything listed in the world table `mod_reagent_bank_account_deposit_inclusions_zz_custom` (`item_entry`, `item_subclass` = bank category). It ships with Dark Iron Residue
- Items listed in `mod_reagent_bank_account_deposit_exclusions_zz_custom` are never deposited

Deposits skip any item a quest in your log asks for, so auto-deposit cannot take quest items before you turn them in.

---

## Profession Integration

The profession controls live in the profession window itself. With [RetailProfessions](https://github.com/buildthehomelab/wow-mod-retail-professions):

- **Create** and **Create All** count the reagent bank and take what your bags are missing out of it before crafting (**Use reagent bank**)
- **Deposit leftovers** puts reagents that came out of the bank and weren't used back when you close the window
- **Add to Shopping List** puts what bags and bank are short of, for the amount you chose, on the AH shopping list
- Each reagent shows what is waiting in the bank

The sidebar ReagentBankUI used to dock beside the profession window is gone: it repeated all of the above. On the Blizzard profession window you still get:

- Per-reagent `+N` badges on the recipe's reagent rows showing what is waiting in the bank, green when bags plus bank cover the craft and orange when they do not
- `/rbank craft [count]` withdraws the missing reagents for the selected recipe, `/rbank plan [count]` prints what to withdraw, what to buy and what is running low, and `/rbank autodeposit` turns the leftover deposit on or off
- Periodic auto-deposit pauses while the profession window is open and resumes when you close it
- Note that the UI icon is attached to the outside lower portion of the character frame by default.

Addon authors: a window registered with `RegisterRecipeProvider` supplies the selected recipe and craft count for the withdraw, the shopping list and the leftovers deposit, and brings its own buttons for them.

---

## Auction House Shopping List

ReagentBankUI includes an AH shopping list for missing crafting materials.

You can add items to the AH list from:

- The main reagent item detail screen
- The profession window with **Add to Shopping List** (RetailProfessions)
- The AH list **From Recipe** button
- **Ctrl+Shift-click** any item: in your bags, in Auction House results, or a linked item in chat. A popup asks how many to buy
- Dropping an item from your bags onto the AH list panel beside the Auction House
- Slash commands

Shopping list features:

- Edit item amounts directly in the AH list
- **-** and **+** buttons on each row of the AH panel change the amount by 1, or by a full stack with Shift. Minus stops at 1; Shift-right-click the row to remove an item
- Right-click an item to change its amount, in the main window or the AH panel. Ctrl+Shift-clicking an item already on the list also changes its amount; enter 0 to remove it
- Shift-right-click an item to remove it
- Left-click an item to search for it on the Auction House
- Print the list to chat
- Clear the list
- Shows the amount left to buy, how many you have bought, and current bag count
- Compact AH helper panel opens beside the Auction House frame. Drag it anywhere; it docks beside the Auction House again the next time you open it
- With [RetailAH](https://github.com/buildthehomelab/wow-mod-retail-ah), the list lives on its Buy tab instead of the helper panel: what's left to buy, prices, and purchases counted off as you make them (addon authors: `RegisterShoppingListView`)

Buying an item on the list takes it off the list. Each buyout the server accepts subtracts that stack from the amount left and adds it to the bought count. When the amount left reaches zero, the item is removed and the total bought is printed to chat. This works for buyouts from the default Auction House UI and from Auctionator. Plain bids are not counted, since you only get the item if you win the auction later.

### Auctionator

When [Auctionator](https://github.com/buildthehomelab/wow-addon-Auctionator) is loaded:

- Clicking an AH list row searches on Auctionator's **Buy** tab instead of the default Browse tab
- The AH list is mirrored into an Auctionator shopping list named **Reagent Bank**, kept up to date as items are added, bought, or removed
- On Auctionator 3.x, the **Shopping Lists** options page is fixed so its list box no longer stretches over the Delete, Edit and Rename buttons, and the shopping list Edit window can be dragged and has a close button

---

## Install

### Server

Place the module in:

```txt
modules/mod-reagent-bank-account/
