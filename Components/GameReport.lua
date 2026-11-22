-- Bagshui Game Report
-- Exposes: BsGameReport (and Bagshui.components.GameReport)
--
-- Display information about the current WoW environment that can be useful for troubleshooting.

Bagshui:AddComponent(function()
  -- Initialize component.
  local GameReport = Bagshui.prototypes.ScrollableTextWindow:New({
    name = "GameReport",
    readOnly = true,
    selectAllOnFocus = true,
    title = L.GameReport,
    width = 400,
    height = 600,

    -- Used in OnEvent when receiving BAGSHUI_LOG_UPDATE events.
    allowUpdates = true,
  })
  Bagshui.components.GameReport = GameReport
  Bagshui.environment.BsGameReport = GameReport

  --- Open the Bagshui game report window.
  function GameReport:Open()
    local lines = {}
    local enabledAddons = {}
    local disabledAddons = {}

    local function addLine(text, tbl)
      table.insert(tbl or lines, text)
    end

    addLine("Bagshui Version: " .. BS_VERSION)
    if type(_G.UpdateAddOnMemoryUsage) == "function" and type(_G.GetAddOnMemoryUsage) == "function" then
      pcall(_G.UpdateAddOnMemoryUsage)
      local ok, memKb = pcall(_G.GetAddOnMemoryUsage, "Bagshui")
      if ok and type(memKb) == "number" then
        addLine(string.format("Bagshui Memory: %.1f KB", memKb))
      end
    end
    addLine("Game Version: " .. table.concat({ _G.GetBuildInfo() }, " ") .. BS_NEWLINE)
    addLine("<details><summary>Addons</summary>" .. BS_NEWLINE)
    addLine("**Client mods:**")
    for _, modLine in ipairs(BsClientMods:Describe()) do
      addLine("* " .. modLine)
    end
    addLine("")
    for i = 1, _G.GetNumAddOns() do
      local name, title, _, enabled, _, disabled = _G.GetAddOnInfo(i)
      local version = _G.GetAddOnMetadata(name, "Version") or ""
      addLine("* " .. title .. " " .. version, ((enabled and not disabled) and enabledAddons or disabledAddons))
    end
    addLine("**Enabled:**")
    addLine(table.concat(enabledAddons, BS_NEWLINE))
    addLine(BS_NEWLINE .. "<details><summary>Disabled:</summary>" .. BS_NEWLINE)
    addLine(table.concat(disabledAddons, BS_NEWLINE))
    addLine(BS_NEWLINE .. "</details></details>")

    self._super.Open(self, table.concat(lines, BS_NEWLINE))

    self.editBox:SetFocus()
  end

  --- Add customizations to the ScrollableTextWindow.
  function GameReport:InitUi()
    if self.uiFrame then
      return
    end
    self._super.InitUi(self)
    local instructions = self.uiFrame:CreateFontString(nil, nil, "GameFontHighlightSmall")
    instructions:SetPoint("TOPLEFT", self.uiFrame.bagshuiData.header, "BOTTOMLEFT", 0, -2)
    self.uiFrame.bagshuiData.scrollFrame:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -8)
    instructions:SetText(L.GameReport_Instructions)
  end

  -- Register slash handler.
  BsSlash:AddHandler("Report", function()
    GameReport:Open()
  end, true)
end)

