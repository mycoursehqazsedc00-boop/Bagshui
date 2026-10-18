-- Bagshui Client Mods
-- Exposes: BsClientMods (and Bagshui.components.ClientMods)
--
-- Optional integration with community client mods. Every feature in here is
-- strictly additive: when a mod is missing, Bagshui behaves exactly as it did
-- before and nothing in this file raises an error (all mod calls are pcall-wrapped).
--
-- Supported mods:
-- - SuperWoW      : file import/export fallback (ImportFile/ExportFile), charges (see Inventory.Cache.lua).
-- - Nampower      : item level via GetItemStatsField().
-- - ClassicAPI    : quest-starter detection via C_Container.GetContainerItemQuestInfo().
-- - UnitXP_SP3    : taskbar flash when bags fill while the game is in the background.
-- - VanillaHelpers: file import/export fallback (ReadFile/WriteFile).
-- - WeirdUtils    : DLL-only (no Lua surface), reported as not detectable.

Bagshui:AddComponent(function()
  local ClientMods = {
    -- Detection results. `true` when the mod's Lua surface was found.
    superwow = false,
    nampower = false,
    classicapi = false,
    unitxp = false,
    vanillahelpers = false,

    -- Human-readable version strings (when the mod exposes one).
    versions = {},

    -- Capability flags. These are what the rest of Bagshui should test.
    canGetItemLevel = false,
    canGetQuestInfo = false,
    canNotify = false,
    canReadWriteFiles = false,

    -- Item level cache (item IDs never change level).
    itemLevelCache = {},

    -- Last time the bags-full notification was sent.
    lastNotifyTime = 0,
  }
  Bagshui.environment.BsClientMods = ClientMods
  Bagshui.components.ClientMods = ClientMods

  -- Seconds between bags-full notifications.
  local NOTIFY_THROTTLE = 60

  --- Call a function inside pcall and return only its first result (or nil on error).
  ---@param func function
  ---@param a1 any?
  ---@param a2 any?
  ---@param a3 any?
  ---@return any
  local function safeCall(func, a1, a2, a3)
    if type(func) ~= "function" then
      return nil
    end
    local ok, result = pcall(func, a1, a2, a3)
    if ok then
      return result
    end
    return nil
  end

  --- Detect which client mods are present. Safe to call repeatedly.
  function ClientMods:Detect()
    -- SuperWoW (DLL injection; no addon to check for).
    self.superwow = BS_SUPER_WOW_LOADED and true or false
    self.versions.superwow = self.superwow and tostring(_G.SUPERWOW_VERSION or "?") or nil

    -- Nampower.
    self.nampower = (type(_G.GetNampowerVersion) == "function")
    if self.nampower then
      local ok, major, minor, patch = pcall(_G.GetNampowerVersion)
      if ok and major then
        self.versions.nampower = tostring(major) .. "." .. tostring(minor or 0) .. "." .. tostring(patch or 0)
      else
        self.versions.nampower = "?"
      end
    else
      self.versions.nampower = nil
    end

    -- ClassicAPI (CLASSIC_API_VERSION is X*10000 + Y*100 + Z).
    local capiVersion = tonumber(_G.CLASSIC_API_VERSION)
    self.classicapi = (capiVersion ~= nil)
    if capiVersion then
      if capiVersion >= 99999999 then
        self.versions.classicapi = "dev build"
      else
        local major = math.floor(capiVersion / 10000)
        local minor = math.floor((capiVersion - major * 10000) / 100)
        local patch = capiVersion - major * 10000 - minor * 100
        self.versions.classicapi = major .. "." .. minor .. "." .. patch
      end
    else
      self.versions.classicapi = nil
    end

    -- UnitXP_SP3: the mod's documented existence check is pcall(UnitXP, "nop", "nop").
    self.unitxp = false
    if type(_G.UnitXP) == "function" then
      local ok = pcall(_G.UnitXP, "nop", "nop")
      self.unitxp = ok and true or false
    end

    -- VanillaHelpers: ReadFile/WriteFile are generic names, so also require a more distinctive function.
    self.vanillahelpers = (
      type(_G.ReadFile) == "function"
      and type(_G.WriteFile) == "function"
      and type(_G.GetItemDisplayID) == "function"
    )

    -- Capabilities.
    self.canGetItemLevel = self.nampower and (type(_G.GetItemStatsField) == "function")
    self.canGetQuestInfo = self.classicapi
      and type(_G.C_Container) == "table"
      and type(_G.C_Container.GetContainerItemQuestInfo) == "function"
      and type(_G.C_Container.GetContainerItemID) == "function"
    self.canNotify = self.unitxp
    self.canReadWriteFiles = (
      (type(_G.ExportFile) == "function" and type(_G.ImportFile) == "function")
      or self.vanillahelpers
    )
  end

  --#region Item level (Nampower)

  --- Get an item's item level via Nampower's `GetItemStatsField()`.
  --- Vanilla's own API has no item level.
  ---@param itemId number|string
  ---@return number? itemLevel # `nil` when unavailable (no Nampower, unknown item, bad data).
  function ClientMods:GetItemLevel(itemId)
    if not self.canGetItemLevel then
      return nil
    end
    itemId = tonumber(itemId)
    if not itemId or itemId <= 0 then
      return nil
    end
    local cached = self.itemLevelCache[itemId]
    if cached ~= nil then
      -- `false` is stored for items that returned nothing so we don't keep asking.
      return cached or nil
    end
    -- GetItemStatsField returns a plain value for a single field.
    local ok, level = pcall(_G.GetItemStatsField, itemId, "itemLevel")
    level = ok and tonumber(level) or nil
    if level and level > 0 then
      self.itemLevelCache[itemId] = level
      return level
    end
    self.itemLevelCache[itemId] = false
    return nil
  end

  --#endregion Item level

  --#region Quest info (ClassicAPI)

  --- Determine whether the item in a bag slot starts a quest the player hasn't accepted.
  --- The slot is validated against the expected item ID so that stale or other-character
  --- data (offline bank, etc.) never produces a false positive.
  ---@param bagNum number
  ---@param slotNum number
  ---@param expectedItemId number? If provided, the live slot must hold this item.
  ---@return boolean? startsQuest # `nil` when unavailable/unknown.
  ---@return boolean? isQuestItem
  function ClientMods:GetQuestStarterInfo(bagNum, slotNum, expectedItemId)
    if not self.canGetQuestInfo or not bagNum or not slotNum then
      return nil
    end
    local liveId = safeCall(_G.C_Container.GetContainerItemID, bagNum, slotNum)
    if not liveId or (expectedItemId and tonumber(expectedItemId) ~= liveId) then
      return nil
    end
    local info = safeCall(_G.C_Container.GetContainerItemQuestInfo, bagNum, slotNum)
    if type(info) ~= "table" then
      return nil
    end
    return (info.questID ~= nil and not info.isActive), (info.isQuestItem and true or false)
  end

  --#endregion Quest info

  --#region File I/O (SuperWoW / VanillaHelpers)

  --- Reduce a user-supplied name to something safe to use as a file name.
  ---@param name string?
  ---@return string? sanitized # `nil` if nothing usable remains.
  function ClientMods:SanitizeFileName(name)
    if type(name) ~= "string" then
      return nil
    end
    name = string.gsub(name, "%.txt$", "")
    if string.len(name) == 0 or string.len(name) > 48 or string.find(name, "[^%w_%-]") then
      return nil
    end
    return "Bagshui_" .. name .. ".txt"
  end

  --- Read a text file using whichever mod provides it.
  ---@param fileName string Already-sanitized file name.
  ---@return string? text
  function ClientMods:ReadTextFile(fileName)
    local text
    if type(_G.ImportFile) == "function" then
      text = safeCall(_G.ImportFile, fileName)
    end
    if (type(text) ~= "string" or text == "") and self.vanillahelpers then
      text = safeCall(_G.ReadFile, fileName)
    end
    if type(text) == "string" and text ~= "" then
      return text
    end
    return nil
  end

  --- Write a text file using whichever mod provides it, and verify by reading it back.
  ---@param fileName string Already-sanitized file name.
  ---@param text string
  ---@return boolean success
  ---@return string? via Name of the mod that completed the write.
  function ClientMods:WriteTextFile(fileName, text)
    if type(text) ~= "string" or text == "" then
      return false
    end
    if type(_G.ExportFile) == "function" then
      pcall(_G.ExportFile, fileName, text)
      if self:ReadTextFile(fileName) == text then
        return true, "SuperWoW"
      end
    end
    if self.vanillahelpers then
      -- The write-mode argument isn't documented by VanillaHelpers; "w" is the conventional value.
      pcall(_G.WriteFile, fileName, "w", text)
      if safeCall(_G.ReadFile, fileName) == text then
        return true, "VanillaHelpers"
      end
    end
    return false
  end

  --#endregion File I/O

  --#region Bags-full notification (UnitXP_SP3)

  --- Flash the taskbar icon (only effective while the game is in the background).
  function ClientMods:NotifyBagsFull()
    if not self.canNotify then
      return
    end
    local now = _G.GetTime()
    if now - self.lastNotifyTime < NOTIFY_THROTTLE then
      return
    end
    self.lastNotifyTime = now
    pcall(_G.UnitXP, "notify", "taskbarIcon")
  end

  --#endregion Bags-full notification

  --- Produce lines describing client mod status (used by the game report and `/bagshui mods`).
  ---@return string[] lines
  function ClientMods:Describe()
    local lines = {}
    local function add(label, present, version, usedFor)
      table.insert(
        lines,
        label .. ": " .. (present and ("Yes" .. (version and (" (" .. version .. ")") or "")) or "No") .. usedFor
      )
    end
    add("SuperWoW", self.superwow, self.versions.superwow, " - item charges, file import/export")
    add("Nampower", self.nampower, self.versions.nampower, " - item level rule function")
    add("ClassicAPI", self.classicapi, self.versions.classicapi, " - quest-starter rule function")
    add("UnitXP_SP3", self.unitxp, nil, " - bags-full taskbar flash")
    add("VanillaHelpers", self.vanillahelpers, nil, " - file import/export fallback")
    table.insert(lines, "WeirdUtils: not detectable from Lua (DLL-only, no addon-facing API)")
    return lines
  end

  -- Detect immediately so that rule functions (loaded later) can use the capability
  -- flags in their `conditional` checks.
  ClientMods:Detect()

  --- Event handling: re-detect once the world is up (a mod may have finished initializing late)
  --- and watch for the "inventory is full" error.
  ---@param event string WoW API event.
  ---@param arg1 any First event argument.
  function ClientMods:OnEvent(event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
      self:Detect()
    elseif event == "UI_ERROR_MESSAGE" and arg1 and arg1 == _G.ERR_INV_FULL then
      self:NotifyBagsFull()
    end
  end
  Bagshui:RegisterEvent("PLAYER_ENTERING_WORLD", ClientMods)
  Bagshui:RegisterEvent("UI_ERROR_MESSAGE", ClientMods)

  -- Slash command: /bagshui mods
  BsSlash:AddHandler("Mods", function()
    for _, line in ipairs(ClientMods:Describe()) do
      Bagshui:PrintBare(line)
    end
  end, true)
end)
