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

---

## Profession Integration

Open a profession window and ReagentBankUI docks a reagent bank sidebar to its right edge.

- A craftable count for the selected recipe, counting bags and reagent bank together
- **Withdraw Needed** pulls missing reagents for the selected recipe
- A **Crafts** stepper for multi-craft amounts, with **x1**, **x100** and **Max** presets. **Max** fills in however many crafts your bags and reagent bank cover between them
- Per-reagent `+N` badges on the recipe's reagent rows showing what is waiting in the bank, green when bags plus bank cover the craft and orange when they do not
- A plan summary listing what to withdraw, what to buy, and which reagents are running low
- Optional leftover auto-deposit when closing the profession window
- Periodic auto-deposit pauses while the profession window is open and resumes when you close it
- **Add to AH List** adds missing recipe reagents to the shopping list
- Note that the UI icon is attached to the outside lower portion of the character frame by default.

<img width="1305" height="906" alt="Reagent2" src="https://github.com/user-attachments/assets/ee0a2073-7406-4137-885d-034b2ca0104f" />

---

## Auction House Shopping List

ReagentBankUI includes an AH shopping list for missing crafting materials.

You can add items to the AH list from:

- The main reagent item detail screen
- The profession window with **Add to AH List**
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
