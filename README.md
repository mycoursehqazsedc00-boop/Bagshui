<h1>
<img src="Images/Logo.svg" width="204" align="left" alt="Bagshui">
<div width="100%">&nbsp;<br></div>
</h1>

# Bagshui (Patched for WoW 1.12 / Turtle WoW)

> **Feng shui for your bags:** All-in-one autosorting inventory replacement for Vanilla WoW 1.12 and Turtle WoW, enhanced with optional client-mod integration and layout/tooltip fixes.

<h4><picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/veechs/Bagshui/wiki/images/BagshuiScreenshots.png">
  <img alt="Bagshui Screenshots" src="https://github.com/veechs/Bagshui/wiki/images/BagshuiScreenshots.png">
</picture><br>
<a href="https://github.com/veechs/Bagshui/wiki/Screenshots">More Screenshots</a></h4>

## Client Mods Used

All client mods are **optional** and `pcall`-guarded (`Components/ClientMods.lua`, exposed as `BsClientMods`). Without them, Bagshui behaves like upstream.

| Mod | Purpose in this addon | Required? |
|---|---|---|
| **SuperWoW** | Negative `GetContainerItemInfo` item charges; `ExportFile()` / `ImportFile()` for Share file export/import | Optional |
| **Nampower** | `GetItemStatsField(itemId, "itemLevel")` for `ilvl()` rule & `Ctrl+Alt` Item Properties tooltip; `WriteCustomFile()` / `ReadCustomFile()` fallback for Share file export/import | Optional |
| **ClassicAPI** | `C_Container.GetContainerItemQuestInfo()` & `GetContainerItemID()` for `QuestStarter()` rule; `C_Item.RequestLoadItemDataByID()` item cache preload; `GetAddOnMemoryUsage()` in `/bagshui report` | Optional |
| **UnitXP SP3** | `UnitXP("notify", "taskbarIcon")` taskbar flash when `ERR_INV_FULL` fires while the client is in the background (throttled to 60s) | Optional |
| **VanillaHelpers** | `WriteFile()` / `ReadFile()` fallback for Share file export/import | Optional |

## Features

- Single-window inventory for **Bags**, **Bank**, and **Keyring**.
- [Customizable layout and design](https://github.com/veechs/Bagshui/wiki/Profiles) with automatic grouping and sorting.
- [Categorization](https://github.com/veechs/Bagshui/wiki/Categories) via [rules](https://github.com/veechs/Bagshui/wiki/Rules) and item lists.
- Per-inventory and account-wide [search](https://github.com/veechs/Bagshui/wiki/Searching).
- Offline viewing of any character's inventory and [item counts in tooltips](https://github.com/veechs/Bagshui/wiki/Item-Information#info-tooltip).
- Identification of [profession reagents and crafted items](https://github.com/veechs/Bagshui/wiki/Professions).
- Color tinting of unusable items and badges for stock changes, quality, quest items, and unusability.
- Empty slot stacking, custom graphics for profession bag slots, automated bag swapping, and selling protection.
- Clam (Open Container), Disenchant, Pick Lock, Hearthstone, and item restacking tools.
- [Colorblind mode](https://github.com/veechs/Bagshui/wiki/Accessibility#colorblind-mode) and pfUI skinning.

## What Was Added / Improved

- **Added (`ClientMods.lua` & integrations):**
  - `ItemLevelStat(min [, max])` (`ilvl`, `itemlevel`, `statlevel`) rule function powered by Nampower, plus **Item Level** display in the `Ctrl+Alt` Item Properties tooltip (`ItemInfo:AddTooltipInfo()`).
  - `QuestStarter()` (`StartsQuest`) rule function powered by ClassicAPI, validated against the live container slot so offline data never produces false positives.
  - File-based Share export/import (`/bagshui share exportfile <name>` and `importfile <name>`) using SuperWoW, VanillaHelpers, or Nampower `CustomData/` with read-back verification.
  - Bags-full taskbar flash via UnitXP SP3 on `ERR_INV_FULL` (60s throttle).
  - ClassicAPI `C_Item.RequestLoadItemDataByID()` preload in `ItemInfo:LoadItemIntoLocalGameCache()` and addon memory reporting in `/bagshui report`.
  - `/bagshui mods` diagnostic command and expanded `/bagshui report` client-mod summary.
- **Improved:**
  - Added **Fit Window to Screen** setting (on by default) to cap columns and scale down oversized windows cleanly without exceeding screen bounds.
  - Throttled `Bagshui.Tooltips` `OnUpdate` to `0.05s` and avoided redundant per-frame table writes in `ItemButton_OnUpdate`.
  - `Share:ProcessImport()` now returns `true`/`false`.
- **Fixed:**
  - Fixed oversized bag windows caused by the layout shrink loop bailing out prematurely when groups were unshrinkable at the current row height (`UpdateWindow()`, `GetLayoutRowDimensions()`).
  - Fixed tooltip flicker between hidden/stale item buttons and between overlapping Bags and Bank windows (`Bagshui.hoveredItemSlotButton`, `IsMouseOverWindowOccluded()`).
  - Fixed `ClientMods:GetItemLevel()` permanently caching `false` when an item was not yet in the client WDB cache or when `pcall` failed.
  - Fixed `WriteTextFile()` verifying SuperWoW `ExportFile()` via `ImportFile()` directly instead of falling back to another mod's reader.
  - Replaced `string.gmatch` with Lua 5.0 `string.gfind` in `Slash:Tokenize()`.

## Usage

- `/bagshui` or `/bs` — Open slash command help.
- `/bagshui mods` — Print detected client mods, versions, and active integrations.
- `/bagshui report` — Open the Game Report window (includes client mods and memory usage when ClassicAPI is loaded).
- `/bagshui share exportfile <name>` — Export all custom Profiles, Categories, and Sort Orders to `Bagshui_<name>.txt`.
- `/bagshui share importfile <name>` — Import from `Bagshui_<name>.txt`.

## Compatibility & Languages

- **Auction & Mail:** Blizzard UI, aux, Mail, Postal Returned / Postal / CT_MailMod.
- **Cooldown Counts:** OmniCC, pfUI, ShaguTweaks, Turtle Dragonflight.
- **Interface & Rules:** pfUI skin, `Outfit()` (ItemRack / Outfitter), `Wishlist()` (AtlasLoot), Turtle WoW Guild Bank deposit, `Transmog()` (Tmog + Bagshui-Tmog).
- **Localizations:** English (`enUS`) and Chinese (`zhCN`).

## Documentation

- [Wiki](https://github.com/veechs/Bagshui/wiki)
- [FAQ](https://github.com/veechs/Bagshui/wiki/FAQ)
- [Walkthroughs](https://github.com/veechs/Bagshui/wiki/Walkthroughs)
- [Changelog](Changelog.md)

## Credits & License

- Original addon: **veechs** ([Bagshui](https://github.com/veechs/Bagshui)) and [contributors](Credits.md)
- Upstream support: <a href="https://www.buymeacoffee.com/veechs" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-orange.png" alt="Buy Me A Coffee" height="28"></a>
- License: Same as original addon ([LICENSE](LICENSE)).
