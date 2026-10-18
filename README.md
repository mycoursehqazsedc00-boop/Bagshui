<h1>
<img src="Images/Logo.svg" width="204" align="left" alt="Bagshui">
<div width="100%">&nbsp;<br></div>
</h1>

**Feng shui for your bags:** A Vanilla WoW 1.12 (and Turtle WoW) inventory addon.<br><sup>Not for Classic or Retail; you have [so](https://www.curseforge.com/wow/addons/better-bags) [many](https://www.curseforge.com/wow/addons/ark-inventory) [options](https://www.curseforge.com/wow/search?class=addons&categories=bags-inventory&sortBy=popularity).</sup>

<h4><picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/veechs/Bagshui/wiki/images/BagshuiScreenshots.png">
  <img alt="Bagshui Screenshots" src="https://github.com/veechs/Bagshui/wiki/images/BagshuiScreenshots.png">
</picture><br>
<a href="https://github.com/veechs/Bagshui/wiki/Screenshots">More Screenshots</a></h4>

<a href="https://www.buymeacoffee.com/veechs" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-orange.png" alt="Buy Me A Coffee" height="41" width="146"></a>

## Features

- Single window inventory for Bags, Bank, and Keyring.
- [Customizable layout and design](https://github.com/veechs/Bagshui/wiki/Profiles) with automatic grouping and sorting.
- [Categorization](https://github.com/veechs/Bagshui/wiki/Categories) via [rules](https://github.com/veechs/Bagshui/wiki/Rules) and item lists.
- Per-inventory and account-wide [search](https://github.com/veechs/Bagshui/wiki/Searching).
- Offline viewing of any character’s inventory and [item counts in tooltips](https://github.com/veechs/Bagshui/wiki/Item-Information#info-tooltip).
- Identification of [profession reagents and crafted items](https://github.com/veechs/Bagshui/wiki/Professions).<br><sup>Updated when the crafting window is opened.</sup>
- Color tinting of unusable items.
- Badges to indicate stock changes, quality, quest items, and unusability.
- Empty slot stacking and custom graphics for profession bag slots.
- Automated bag swapping – no more manual item shuffling!
- Selling protection to safeguard valuable items.
- Clam (Open Container), Disenchant, Pick Lock, and Hearthstone buttons.
- [Colorblind mode](https://github.com/veechs/Bagshui/wiki/Accessibility#colorblind-mode) to help identify item quality and unusability.
- Plenty of other little niceties like item restacking, pfUI skinning, and more.

<details>

<summary>Recommended if you like…</summary>

> AdiBags, ArkInventory, Baganator, Baggins, BetterBags, EngInventory/EngBags, TBag.
> And with “[OneBagshui](https://github.com/veechs/Bagshui/wiki/FAQ#how-do-i-switch-to-the-onebag-style-layout)”: Bagnon, Combuctor, Inventorian, LiteBag, OneBag3, SUCC-bag.

</details>

## Documentation

📕 [Wiki](https://github.com/veechs/Bagshui/wiki)
🙋 [FAQ](https://github.com/veechs/Bagshui/wiki/FAQ)
🐾 [Walkthroughs](https://github.com/veechs/Bagshui/wiki/Walkthroughs)
🕝 [Version history](Changelog.md)

## Client mod integration

This fork adds a small, optional integration layer (`Components/ClientMods.lua`, exposed as `BsClientMods`) for community client mods. **Every mod is optional.** Without them Bagshui behaves exactly like upstream: detection is pcall-guarded, rule functions that need a missing mod are simply not registered (`ilvl()` keeps an explanatory error), and nothing else changes.

| Client mod | Used for | How it's used |
|---|---|---|
| [SuperWoW](https://github.com/balakethelock/SuperWoW/wiki) | Item charges (upstream); **file import/export** (new) | Negative `GetContainerItemInfo` counts become charges. `ExportFile()` / `ImportFile()` move Share data through a text file. |
| [Nampower](https://github.com/brues-code/nampower) | **Item level** (new) | `GetItemStatsField(itemId, "itemLevel")`, cached per item ID, powers `ItemLevelStat()` / `ilvl()`. |
| [ClassicAPI](https://github.com/brues-code/ClassicAPI/releases/tag/v1.12.7) | **Quest-starter detection** (new) | `C_Container.GetContainerItemQuestInfo()` and `GetContainerItemID()` power `QuestStarter()`. Detected via `CLASSIC_API_VERSION`. |
| [UnitXP_SP3](https://codeberg.org/konaka/UnitXP_SP3/wiki) | **Bags-full taskbar flash** (new) | `UnitXP("notify", "taskbarIcon")`. Detected with the mod's own `pcall(UnitXP, "nop", "nop")` check. |
| [VanillaHelpers](https://github.com/isfir/VanillaHelpers) | **File import/export fallback** (new) | `ReadFile()` / `WriteFile()`, used when SuperWoW's file functions are missing or can't be verified. |
| [WeirdUtils](https://codeberg.org/MarcelineVQ/WeirdUtils/wiki) | Reviewed, **not used** | Its modules are DLL-only hooks with no addon-facing Lua API (only a C-level module API), and none touch bag logic. Reported as "not detectable from Lua". |

Check what was detected with `/bagshui mods` or in the Game Report (`/bagshui report`).

## What's new in this fork

### New rule functions

- **`ItemLevelStat(min [, max])`**, aliases `ilvl`, `itemlevel`, `statlevel` *(requires Nampower)*.
  Vanilla has no item levels, so upstream shipped this as a stub that always errored. It now works: `ilvl(60)` matches item level 60 and up, `ilvl(40, 55)` matches 40 through 55. Items whose level can't be read never match and never raise errors. Without Nampower the function still returns an explanatory error instead of "unknown function".
- **`QuestStarter()`**, alias `StartsQuest` *(requires ClassicAPI)*.
  Matches items that begin a quest you haven't accepted yet. The live bag slot is checked against the item's ID first, so stale or other-character (offline) data can never produce a false match.

Both appear in the Category Editor's rule function menu (with enUS and zhCN descriptions and examples) only when their mod is present.

### File-based sharing

- **`/bagshui share exportfile <name>`** writes every custom Profile, Category, and Sort Order (with dependencies) to a text file.
- **`/bagshui share importfile <name>`** reads one back through the normal import pipeline.
- Uses SuperWoW, falling back to VanillaHelpers. Every write is **read back and compared** before success is reported, so a silent failure is reported as a failure. File names are limited to letters, numbers, `-` and `_` (stored as `Bagshui_<name>.txt`) so they can't point outside the target directory.
- The existing copy/paste import and export dialogs are untouched.

### Bags-full taskbar flash

When the game is in the background and the "inventory is full" error fires, the taskbar icon flashes (UnitXP_SP3). Throttled to once per minute; flash only, no sound.

### Diagnostics

- `/bagshui mods` and the Game Report list each client mod with its detected version (SuperWoW, Nampower, ClassicAPI) and what Bagshui uses it for.
- Mods that appear late in startup are picked up when entering the world.

### Oversized window fix

Fixes the bag window growing absurdly wide (or taller than the screen) when a group holds a very large number of items, e.g. hundreds of stacks of the same item.

- **Cause 1, a wrong failsafe in the layout loop:** the loop that shrinks groups to fit `Max Columns` bailed out as soon as every group was "unshrinkable at the current row height", which is true almost immediately for a single large group. The row was never made taller, so 800 items stayed 400 columns wide. The check now bails out only when every group is truly one item wide (more groups than columns), which is the only case that can't be solved. Fixed in `UpdateWindow()` and `GetLayoutRowDimensions()`.
- **Cause 2, no awareness of screen size:** up to 30 columns at up to 205% scale can exceed the screen on its own. The new **Fit Window to Screen** setting (on by default) caps columns to what fits across the screen at the configured scale, then reduces the window scale only as far as needed (floor 20%) if it is still too large. It never raises your scale, skips docked windows, and can be turned off.

| 800 items in one group | Before | After |
|---|---|---|
| Layout at Max Columns 30 | 400 columns x 2 rows | 30 columns x 27 rows |
| Window size, scale 1.0, 1024x768 screen | about 1500% of screen width | 49% wide x 95% tall (scale 0.53) |
| Window size, scale 2.05, 1024x768 screen | about 3000% of screen width | 11% wide x 95% tall (scale 0.25) |

Layouts whose rows already fit within Max Columns are untouched. Rows that previously ended up wider than Max Columns now honor it, so some existing windows get slightly narrower and taller.

### Tooltip flicker fix

Fixes the bug where another item's tooltip appears on the item you're hovering and then jumps back and forth very quickly.

**Cause:** item slot buttons track "mouse is over me" in `bagshuiData.mouseIsOver`, but the client sends no `OnLeave` to a frame that gets hidden while the cursor is over it, and the code paths that call `ItemButton_OnEnter()` programmatically (the post-update mouse-over check, and the Open Container button's "highlight next openable item") never had a matching `OnLeave`. A button left in that state keeps refreshing the one shared `GameTooltip` from `ItemButton_OnUpdate()` (every frame in Edit Mode, and on every modifier-key change or cooldown tick otherwise). With two such buttons they take the tooltip back and forth.

**Fix** (`Inventory.Ui.ItemButton.lua`, `Inventory.Layout.lua`):

- Exactly one item slot button (`Inventory.hoveredButton`) may own the tooltip; entering a new one demotes the previous one.
- A button that still believes the mouse is over it but isn't the owner stands down on its next update.
- Hiding a button clears its hover state.
- `ItemSlotAndGroupMouseOverCheck()` now prefers the button that already owns the tooltip, so buttons sharing an edge no longer steal it on every window update.
- Only item slot buttons are affected; toolbar and bag buttons keep their own `mouseIsOver` handling.

**Bank and bags open together:** each window's post-refresh mouse-over check relied on `MouseIsOver()`, which also returns true for a button hidden behind another window. With the bank on top of the bags, the bag window kept "hovering" the item beneath the bank (a quest item, in the reported case) and stole the tooltip from the bank item under the cursor on every refresh, so the two flipped back and forth. Now:

- A window that is covered at the mouse position (per `GetMouseFocus()`, or, if unavailable, because another Bagshui window's button owns the hover and is still under the mouse) skips the check.
- Hover ownership is a single value shared by all Bagshui windows, so a button left over in the bag is demoted the moment a bank button is entered.

### Smaller changes

- `Share:ProcessImport()` now returns `true`/`false`, so callers can tell whether an import succeeded.
- New localization strings in enUS and zhCN; the `ItemLevelStat` error message now mentions Nampower.
- Changelog updated under **Unreleased**.

## Testing

No WoW client was available, so verification is static and mock-based. It was run under a Lua 5.3 interpreter with a small WoW-environment harness that loads the **real** Bagshui `Util`, `Rules`, `RuleFunctions`, `RuleFunctionTemplates`, and `Share` code (only the game and mod APIs are faked).

- **Syntax:** all 76 Lua files parse; the new code avoids constructs missing from the client's Lua 5.0 (`#`, `select`, `string.match`, varargs).
- **Unit tests (60):** detection with every mod absent, present, or broken; version decoding; caching; throttling; file round-trips and fallbacks; name sanitizing; erroring mod calls.
- **Rule integration (28):** the real rules engine evaluating `ilvl()` and `QuestStarter()` with no mods, Nampower only, and ClassicAPI only, including bounds, aliases, negation, mismatched slots, and category-editor validation.
- **Share integration (27):** the real serialize/compress/encode round-trip through the new file commands, error paths, and "not ready" guards.
- **Back-to-back regression:** 17 built-in rule expressions across 3 sample items produce byte-identical results on the original and modified code.
- **Oversized window (3 tests):** 20,000 random rows run through the real `GetLayoutRowDimensions()` and the real inline `UpdateWindow()` shrink loop extracted from the original and fixed files. Rows that already fit are identical; every changed row was over the column limit in the original (worst case 1,729 columns over); the fixed result fits in every case except rows with more groups than columns. Plus 13 assertions on the screen-fit functions (800 items at several scales and resolutions, typical layouts untouched, bad inputs, docked windows, setting off).
- **Tooltip simulation:** the real `Inventory.Ui.ItemButton.lua` (plus the real mouse-over check and `HighlightNextOpenable`) running against a fake frame/tooltip engine. Reproduced on the original code: 241 tooltip owner changes in 120 frames after a button was hidden under the cursor, and 360 after the Open Container highlight walked across three items (Edit Mode). With the fix: 1 and 0. Modifier-key refresh on a stale button: 4 owner changes before, 0 after.
- **Two overlapping windows:** bags behind, bank on top, a bag item hidden directly under a bank item, both windows refreshing every 5 frames. Original: 48 tooltip owner changes in 120 frames (bag item and bank item alternating). Fixed: 0, with and without `GetMouseFocus()`. Hovering a spot only one window covers behaves identically before and after.
- **Tooltip regression (7 scenarios):** enter/leave, Alt press/release refresh, cooldown refresh once per second, Edit Mode pick-up/put-down, layout moving an item under the cursor, hide/re-show in place, and sequential hovering produce identical output on the original and fixed code.

### Known limits

- Not run in a live client; the tooltip fix is proven against a simulation of the client's behavior (no `OnLeave` for hidden frames), not observed in-game. If you still see flicker after this, a different addon hooking `GameTooltip` is the next suspect.
- Three details come from mod documentation and are untested in-game: the return type of Nampower's `GetItemStatsField`, whether SuperWoW appends `.txt` itself (harmless, since reads and writes use the same name), and VanillaHelpers' `WriteFile` mode argument (`"w"` is assumed because the mode values aren't documented).
- `/bagshui share exportfile` exports all custom objects; per-object file export isn't included.
- A `QuestStarter()` category updates on the next inventory refresh after you accept a quest.

## Compatibility

### Functionality

<table>

<tr>
<td>

### Auction and Mail

<sup>Right-click/Alt+click attach</sup>

</td>
<td>

- Blizzard UI
- [aux](https://github.com/gwetchen/aux-addon)
- [Mail](https://github.com/EinBaum/Mail)
- [Postal Returned](https://github.com/veechs/Postal-Returned) / Postal / CT_MailMod

</td>
</tr>

<tr>
<td>

### Cooldown counts

</td>
<td>

- [OmniCC](https://github.com/Otari98/OmniCC)
- [pfUI](https://shagu.org/pfUI/)
- [ShaguTweaks](https://shagu.org/ShaguTweaks/)
- [Turtle Dragonflight](https://github.com/TheLinuxITGuy/Turtle-Dragonflight)

</td>
</tr>

<tr>
<td>

### Interface replacement

</td>
<td>

- [pfUI](https://shagu.org/pfUI/) skin
  <sup>Manage in **pfUI Config** (`/pfui`) > **Components** > **Skins**</sup>

</td>
</tr>

<tr>
<td>

### [Rule functions](https://github.com/veechs/Bagshui/wiki/Rules#available-rule-functions)

</td>
<td>

- `Outfit()` - [ItemRack](https://turtle-wow.fandom.com/wiki/ItemRack) and [Outfitter](https://github.com/pepopo978/Outfitter)
- `Wishlist()` - [AtlasLoot](https://turtle-wow.fandom.com/wiki/AtlasLoot)

</td>
</tr>

<tr>
<td>

### Turtle WoW

</td>
<td>

- **Guild Bank** right-click to deposit.
- [`Transmog()`](https://github.com/veechs/Bagshui/wiki/Rules#available-rule-functions) collection queries.<br><sup>Requires [Tmog](https://github.com/Otari98/Tmog) and [Bagshui-Tmog](https://github.com/veechs/Bagshui-Tmog).

</td>
</tr>

</table>

### Languages

If Bagshui has not been localized for your client, many items will not be correctly identified by the built-in categorization[^1]. Please consider [contributing a translation](Locale/Readme.md) if you'd like to have full functionality!

- English (enUS)
- Chinese (zhCN)

[^1]: In Vanilla, a _lot_ of item identification must be done either by parsing tooltips or hardcoding item IDs. Bagshui leans toward the former, and therefore is highly dependent on localization.

## Donations

Developing Bagshui is fun, but also a lot of work! Your support is hugely appreciated.
<a href="https://www.buymeacoffee.com/veechs" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-orange.png" alt="Buy Me A Coffee" height="41" width="146"></a>

## Credits

Bagshui owes [so much to so many people](Credits.md).

<br><br>
