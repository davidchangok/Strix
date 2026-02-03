--[[
================================================================================
    Strix - Core.lua
    Core UI and Event Module
================================================================================
    Description:
        Main module handling UI components, event processing, and user interaction.
        Features: mailbox hook, options panel with tabs, context menu.

    Author: David W Zhang
    Version: 1.1.0
================================================================================
--]]

local addonName, addon = ...
local L = addon.L
local Data = addon.Data

-- ==============================================================================
-- Race Atlas Mapping
-- ==============================================================================
local raceCorrections = {
    ["scourge"] = "undead",
    ["zandalaritroll"] = "zandalari",
    ["highmountaintauren"] = "highmountain",
    ["lightforgeddraenei"] = "lightforged",
    ["earthendwarf"] = "earthen",
    ["voidelf"] = "voidelf",
}

-- ==============================================================================
-- Icon Helper Functions
-- ==============================================================================
local FACTION_ICONS = {
    ["Alliance"] = "Interface\\PVPFrame\\PVP-Currency-Alliance",
    ["Horde"] = "Interface\\PVPFrame\\PVP-Currency-Horde",
}

local function GetRaceAtlas(race, sex)
    if not race or race == "" then
        return "raceicon128-human-male"
    end
    local gender = (sex == 3) and "female" or "male"
    local cleanRace = race:lower()
    cleanRace = raceCorrections[cleanRace] or cleanRace
    return string.format("raceicon128-%s-%s", cleanRace, gender)
end

local function SetFactionIcon(texture, faction)
    if not texture then return end
    local iconPath = FACTION_ICONS[faction]
    if iconPath then
        texture:SetTexture(iconPath)
        texture:SetTexCoord(0, 1, 0, 1)
        texture:Show()
    else
        texture:Hide()
    end
end

local function GetFactionIconString(faction)
    if faction == "Alliance" then
        return "|TInterface\\PVPFrame\\PVP-Currency-Alliance:14:14|t"
    elseif faction == "Horde" then
        return "|TInterface\\PVPFrame\\PVP-Currency-Horde:14:14|t"
    end
    return ""
end

local function GetLevelString(level)
    if level and level > 0 then
        return string.format(L.LEVEL_FORMAT, level)
    end
    return L.LEVEL_UNKNOWN
end

-- ==============================================================================
-- Core Frame and Event Handler
-- ==============================================================================
local Core = CreateFrame("Frame")

Core:RegisterEvent("ADDON_LOADED")
Core:RegisterEvent("PLAYER_LOGIN")
Core:RegisterEvent("MAIL_SHOW")
Core:RegisterEvent("MAIL_SEND_SUCCESS")

Core:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            Data:Init()
            self:SetupOptionsPanel()
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_LOGIN" then
        Data:RegisterCurrentCharacter()

    elseif event == "MAIL_SHOW" then
        self:HookMailBox()
        Data:RegisterCurrentCharacter()

    elseif event == "MAIL_SEND_SUCCESS" then
        self:OnMailSent()
    end
end)

-- ==============================================================================
-- Mail Send Hook - Capture Recipients
-- ==============================================================================
function Core:OnMailSent()
    if not SendMailNameEditBox then return end

    local recipient = SendMailNameEditBox:GetText()
    if not recipient or recipient == "" then return end

    -- Parse name-realm format
    local name, realm = strsplit("-", recipient)
    name = strtrim(name or "")
    realm = strtrim(realm or "")

    if name == "" then return end

    -- Add to recent recipients (will be skipped if it's an alt)
    Data:AddRecentRecipient(name, realm)
end

-- ==============================================================================
-- Mailbox Hook
-- ==============================================================================
function Core:HookMailBox()
    if self.isHooked then return end
    if not SendMailNameEditBox then return end

    SendMailNameEditBox:HookScript("OnMouseDown", function(editBox, button)
        if button == "RightButton" then
            local anchor = CreateFrame("Frame", nil, UIParent)
            anchor:SetSize(1, 1)
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            if scale and scale > 0 then
                anchor:SetPoint("BOTTOMLEFT", x / scale, y / scale)
            else
                anchor:SetPoint("BOTTOMLEFT", x, y)
            end
            MenuUtil.CreateContextMenu(anchor, function(owner, rootDescription)
                Core:BuildMenu(rootDescription)
            end)
        end
    end)

    SendMailNameEditBox:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:AddLine(L.TOOLTIP_TITLE, 0, 1, 0)
        GameTooltip:AddLine(L.TOOLTIP_HINT, 1, 1, 1)
        GameTooltip:Show()
    end)

    SendMailNameEditBox:HookScript("OnLeave", GameTooltip_Hide)

    self.isHooked = true
end

-- ==============================================================================
-- Options Panel with Tabs
-- ==============================================================================

-- Helper: Create a simple tab button
local function CreateTabButton(parent, text)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(100, 24)

    -- Background
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    -- Text
    btn.text = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)

    -- Highlight
    btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    -- Selected state methods
    btn.SetSelected = function(self, selected)
        if selected then
            self.bg:SetColorTexture(0.3, 0.3, 0.5, 1)
            self.text:SetTextColor(1, 1, 1)
        else
            self.bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)
            self.text:SetTextColor(0.6, 0.6, 0.6)
        end
    end

    return btn
end

function Core:SetupOptionsPanel()
    local panel = CreateFrame("Frame")

    -- Header
    local header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    header:SetPoint("TOPLEFT", panel, 15, -10)
    header:SetText(L.OPTIONS_HEADER)

    -- Tab buttons (custom)
    local tabAlts = CreateTabButton(panel, L.TAB_MY_ALTS)
    tabAlts:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)

    local tabRecent = CreateTabButton(panel, L.TAB_RECENT)
    tabRecent:SetPoint("LEFT", tabAlts, "RIGHT", 5, 0)

    -- Content frames for each tab
    local altsFrame = CreateFrame("Frame", nil, panel)
    altsFrame:SetPoint("TOPLEFT", tabAlts, "BOTTOMLEFT", 0, -10)
    altsFrame:SetPoint("BOTTOMRIGHT", panel, -15, 15)

    local recentFrame = CreateFrame("Frame", nil, panel)
    recentFrame:SetPoint("TOPLEFT", tabAlts, "BOTTOMLEFT", 0, -10)
    recentFrame:SetPoint("BOTTOMRIGHT", panel, -15, 15)
    recentFrame:Hide()

    -- Tab switching
    local function SelectTab(tabNum)
        if tabNum == 1 then
            tabAlts:SetSelected(true)
            tabRecent:SetSelected(false)
            altsFrame:Show()
            recentFrame:Hide()
        else
            tabAlts:SetSelected(false)
            tabRecent:SetSelected(true)
            altsFrame:Hide()
            recentFrame:Show()
        end
    end

    tabAlts:SetScript("OnClick", function() SelectTab(1) end)
    tabRecent:SetScript("OnClick", function() SelectTab(2) end)

    -- ========== MY ALTS TAB ==========
    self:SetupAltsTab(altsFrame)

    -- ========== RECENT RECIPIENTS TAB ==========
    self:SetupRecentTab(recentFrame)

    -- Initial state
    SelectTab(1)

    panel:SetScript("OnShow", function()
        Data:RegisterCurrentCharacter()
        if altsFrame.UpdateList then altsFrame.UpdateList() end
        if recentFrame.UpdateList then recentFrame.UpdateList() end
    end)

    self.optionsCategory = Settings.RegisterCanvasLayoutCategory(panel, "Strix")
    Settings.RegisterAddOnCategory(self.optionsCategory)
end

-- ==============================================================================
-- My Alts Tab Setup
-- ==============================================================================
function Core:SetupAltsTab(parent)
    local container = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    container:SetPoint("TOPLEFT", 0, 0)
    container:SetPoint("BOTTOMRIGHT", 0, 60)

    local scrollBar = CreateFrame("EventFrame", nil, container, "MinimalScrollBar")
    scrollBar:SetPoint("TOPRIGHT", -10, -5)
    scrollBar:SetPoint("BOTTOMRIGHT", -10, 5)

    local scrollBox = CreateFrame("Frame", nil, container, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", 2, -2)
    scrollBox:SetPoint("BOTTOMRIGHT", scrollBar, "BOTTOMLEFT", -3, 0)

    -- Slider
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, -30)
    slider:SetPoint("TOPRIGHT", container, "BOTTOMRIGHT", 0, -30)
    slider:SetMinMaxValues(1, 20)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider.Low:SetText("1")
    slider.High:SetText("20")

    local function UpdateSliderText(val)
        if slider.Text then
            slider.Text:SetText(string.format(L.OPTIONS_SLIDER_ALTS, val))
        end
    end

    slider:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value)
        Data:SetDisplayLimit(val)
        UpdateSliderText(val)
    end)

    slider:SetScript("OnShow", function(self)
        local val = Data:GetDisplayLimit()
        self:SetValue(val)
        UpdateSliderText(val)
    end)

    -- Update list function
    local function UpdateList()
        local alts = Data:GetAlts()
        local maxVal = math.max(#alts, 1)
        slider:SetMinMaxValues(1, maxVal)
        slider.High:SetText(tostring(maxVal))

        local dataProvider = CreateDataProvider()
        for index, alt in ipairs(alts) do
            dataProvider:Insert({ index = index, data = alt, listType = "alts" })
        end
        scrollBox:SetDataProvider(dataProvider, true)
    end

    parent.UpdateList = UpdateList

    -- Drag and drop
    local function OnDragStart(frame)
        if not frame.itemIndex then return end
        addon.draggingIndex = frame.itemIndex

        local ghost = CreateFrame("Frame", nil, UIParent)
        ghost:SetSize(250, 28)
        ghost:SetFrameStrata("TOOLTIP")
        ghost:EnableMouse(false)

        local tex = ghost:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints()
        tex:SetColorTexture(0.2, 0.6, 1, 0.5)

        local text = ghost:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        if frame.text then
            text:SetText(frame.text:GetText() or "")
        end

        ghost:SetScript("OnUpdate", function(self)
            local cx, cy = GetCursorPosition()
            local s = UIParent:GetEffectiveScale()
            if s and s > 0 then
                self:ClearAllPoints()
                self:SetPoint("BOTTOMLEFT", cx / s + 10, cy / s - 10)
            end
        end)

        addon.dragGhost = ghost
    end

    local function GetRowUnderMouse()
        local cursorX, cursorY = GetCursorPosition()
        local frames = scrollBox:GetFrames()
        if not frames then return nil end

        for _, f in ipairs(frames) do
            if f:IsVisible() and f.itemIndex then
                local scale = f:GetEffectiveScale()
                local left, bottom, width, height = f:GetRect()
                if left and bottom and width and height and scale and scale > 0 then
                    local sL, sR = left * scale, (left + width) * scale
                    local sB, sT = bottom * scale, (bottom + height) * scale
                    if cursorX >= sL and cursorX <= sR and cursorY >= sB and cursorY <= sT then
                        return f
                    end
                end
            end
        end
        return nil
    end

    local function OnDragStop(frame)
        addon.draggingIndex = nil
        if addon.dragGhost then
            addon.dragGhost:Hide()
            addon.dragGhost = nil
        end

        local targetFrame = GetRowUnderMouse()
        if targetFrame and targetFrame.itemIndex and frame.itemIndex then
            local from, to = frame.itemIndex, targetFrame.itemIndex
            if from ~= to then
                Data:MoveAlt(from, to)
                C_Timer.After(0.01, UpdateList)
            end
        end
    end

    -- View
    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(28)

    view:SetElementInitializer("Button", function(frame, elementData)
        if not frame.initialized then
            frame:SetNormalFontObject(GameFontHighlight)
            frame:SetHighlightAtlas("search-highlight")
            frame:RegisterForDrag("LeftButton")
            frame:SetScript("OnDragStart", OnDragStart)
            frame:SetScript("OnDragStop", OnDragStop)

            frame.factionIcon = frame:CreateTexture(nil, "ARTWORK")
            frame.factionIcon:SetSize(18, 18)
            frame.factionIcon:SetPoint("LEFT", 5, 0)

            frame.raceIcon = frame:CreateTexture(nil, "ARTWORK")
            frame.raceIcon:SetSize(18, 18)
            frame.raceIcon:SetPoint("LEFT", frame.factionIcon, "RIGHT", 4, 0)

            frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            frame.text:SetPoint("LEFT", frame.raceIcon, "RIGHT", 8, 0)

            frame.levelText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            frame.levelText:SetPoint("RIGHT", -30, 0)
            frame.levelText:SetTextColor(0.7, 0.7, 0.7)

            local delBtn = CreateFrame("Button", nil, frame)
            delBtn:SetNormalAtlas("transmog-icon-remove")
            delBtn:SetPoint("RIGHT", -5, 0)
            delBtn:SetSize(14, 14)
            delBtn:SetScript("OnClick", function()
                if frame.itemIndex then
                    Data:DeleteAltByIndex(frame.itemIndex)
                    UpdateList()
                end
            end)
            delBtn:SetScript("OnEnter", function()
                if not addon.draggingIndex then
                    GameTooltip:SetOwner(delBtn, "ANCHOR_RIGHT")
                    GameTooltip:SetText(DELETE)
                    GameTooltip:Show()
                end
            end)
            delBtn:SetScript("OnLeave", GameTooltip_Hide)
            frame.delBtn = delBtn

            frame.initialized = true
        end

        local alt = elementData.data
        frame.itemIndex = elementData.index

        if frame.factionIcon then
            SetFactionIcon(frame.factionIcon, alt.faction)
        end

        if frame.raceIcon then
            if alt.race then
                frame.raceIcon:SetAtlas(GetRaceAtlas(alt.race, alt.sex))
                frame.raceIcon:Show()
            else
                frame.raceIcon:Hide()
            end
        end

        local colorStr = "|cFFFFFFFF"
        if alt.classFile then
            local c = C_ClassColor.GetClassColor(alt.classFile)
            if c then colorStr = "|c" .. c:GenerateHexColor() end
        end

        if frame.text and alt.name and alt.realm then
            frame.text:SetText(string.format("%s%s|r |cFF888888(%s)|r", colorStr, alt.name, alt.realm))
        end

        if frame.levelText then
            frame.levelText:SetText(GetLevelString(alt.level))
        end
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
end

-- ==============================================================================
-- Recent Recipients Tab Setup
-- ==============================================================================
function Core:SetupRecentTab(parent)
    -- Note about limitations
    local note = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    note:SetPoint("TOPLEFT", 5, 0)
    note:SetText(L.RECENT_NOTE)
    note:SetTextColor(0.6, 0.6, 0.6)

    local container = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    container:SetPoint("TOPLEFT", 0, -20)
    container:SetPoint("BOTTOMRIGHT", 0, 90)

    local scrollBar = CreateFrame("EventFrame", nil, container, "MinimalScrollBar")
    scrollBar:SetPoint("TOPRIGHT", -10, -5)
    scrollBar:SetPoint("BOTTOMRIGHT", -10, 5)

    local scrollBox = CreateFrame("Frame", nil, container, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", 2, -2)
    scrollBox:SetPoint("BOTTOMRIGHT", scrollBar, "BOTTOMLEFT", -3, 0)

    -- Slider for recent display limit
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, -30)
    slider:SetPoint("TOPRIGHT", container, "BOTTOMRIGHT", 0, -30)
    slider:SetMinMaxValues(1, 50)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider.Low:SetText("1")
    slider.High:SetText("50")

    local function UpdateSliderText(val)
        if slider.Text then
            slider.Text:SetText(string.format(L.OPTIONS_SLIDER_RECENT, val))
        end
    end

    slider:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value)
        Data:SetRecentDisplayLimit(val)
        UpdateSliderText(val)
    end)

    slider:SetScript("OnShow", function(self)
        local val = Data:GetRecentDisplayLimit()
        self:SetValue(val)
        UpdateSliderText(val)
    end)

    -- Auto-remove checkbox
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -10)
    checkbox.text:SetText(L.AUTO_REMOVE_IF_ALT)
    checkbox:SetScript("OnClick", function(self)
        Data:SetAutoRemoveIfAlt(self:GetChecked())
    end)
    checkbox:SetScript("OnShow", function(self)
        self:SetChecked(Data:GetAutoRemoveIfAlt())
    end)

    local function UpdateList()
        local recipients = Data:GetRecentRecipients()
        local dataProvider = CreateDataProvider()
        for index, r in ipairs(recipients) do
            dataProvider:Insert({ index = index, data = r, listType = "recent" })
        end
        scrollBox:SetDataProvider(dataProvider, true)
    end

    parent.UpdateList = UpdateList

    -- View
    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(28)

    view:SetElementInitializer("Button", function(frame, elementData)
        if not frame.initialized then
            frame:SetNormalFontObject(GameFontHighlight)
            frame:SetHighlightAtlas("search-highlight")

            frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            frame.text:SetPoint("LEFT", 10, 0)

            -- "Move to alts" button
            local moveBtn = CreateFrame("Button", nil, frame)
            moveBtn:SetNormalAtlas("communities-icon-addgroupplus")
            moveBtn:SetPoint("RIGHT", -25, 0)
            moveBtn:SetSize(16, 16)
            moveBtn:SetScript("OnClick", function()
                if frame.itemIndex then
                    Data:MoveRecentToAlts(frame.itemIndex)
                    UpdateList()
                end
            end)
            moveBtn:SetScript("OnEnter", function()
                GameTooltip:SetOwner(moveBtn, "ANCHOR_RIGHT")
                GameTooltip:SetText(L.ACTION_MOVE_TO_ALTS)
                GameTooltip:Show()
            end)
            moveBtn:SetScript("OnLeave", GameTooltip_Hide)
            frame.moveBtn = moveBtn

            -- Delete button
            local delBtn = CreateFrame("Button", nil, frame)
            delBtn:SetNormalAtlas("transmog-icon-remove")
            delBtn:SetPoint("RIGHT", -5, 0)
            delBtn:SetSize(14, 14)
            delBtn:SetScript("OnClick", function()
                if frame.itemIndex then
                    Data:RemoveRecentByIndex(frame.itemIndex)
                    UpdateList()
                end
            end)
            delBtn:SetScript("OnEnter", function()
                GameTooltip:SetOwner(delBtn, "ANCHOR_RIGHT")
                GameTooltip:SetText(DELETE)
                GameTooltip:Show()
            end)
            delBtn:SetScript("OnLeave", GameTooltip_Hide)
            frame.delBtn = delBtn

            frame.initialized = true
        end

        local r = elementData.data
        frame.itemIndex = elementData.index

        if frame.text and r.name then
            local display = r.name
            if r.realm and r.realm ~= "" then
                display = display .. " |cFF888888(" .. r.realm .. ")|r"
            end
            frame.text:SetText(display)
        end
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
end

-- ==============================================================================
-- Context Menu Builder
-- ==============================================================================
function Core:BuildMenu(rootDescription)
    local alts = Data:GetAlts()
    local altLimit = Data:GetDisplayLimit()
    local recent = Data:GetRecentRecipients()
    local recentLimit = Data:GetRecentDisplayLimit()

    -- My Alts Section
    rootDescription:CreateTitle(L.HEADER_MY_ALTS)

    if #alts == 0 then
        local btn = rootDescription:CreateButton(L.MENU_NO_RECORDS, function() end)
        if btn and btn.SetEnabled then btn:SetEnabled(false) end
    else
        local count = 0
        for _, alt in ipairs(alts) do
            count = count + 1
            if count > altLimit then break end

            local colorStr = "|cFFFFFFFF"
            if alt.classFile then
                local c = C_ClassColor.GetClassColor(alt.classFile)
                if c then colorStr = "|c" .. c:GenerateHexColor() end
            end

            local factionIcon = GetFactionIconString(alt.faction)
            local levelStr = alt.level and alt.level > 0 and string.format(" [%d]", alt.level) or ""
            local display = string.format("%s %s%s|r%s - %s",
                factionIcon, colorStr, alt.name or "", levelStr, alt.realm or "")

            rootDescription:CreateButton(display, function()
                if SendMailNameEditBox and alt.name and alt.realm then
                    SendMailNameEditBox:SetText(alt.name .. "-" .. alt.realm)
                    if SendMailSubjectEditBox then
                        SendMailSubjectEditBox:SetFocus()
                    end
                end
            end)
        end
    end

    -- Recent Recipients Section (if any)
    if #recent > 0 then
        rootDescription:CreateDivider()
        rootDescription:CreateTitle(L.HEADER_RECENT_RECIPIENTS)

        local count = 0
        for _, r in ipairs(recent) do
            count = count + 1
            if count > recentLimit then break end

            local display = r.name or ""
            if r.realm and r.realm ~= "" then
                display = display .. " - " .. r.realm
            end

            rootDescription:CreateButton(display, function()
                if SendMailNameEditBox and r.name then
                    local text = r.name
                    if r.realm and r.realm ~= "" then
                        text = text .. "-" .. r.realm
                    end
                    SendMailNameEditBox:SetText(text)
                    if SendMailSubjectEditBox then
                        SendMailSubjectEditBox:SetFocus()
                    end
                end
            end)
        end
    end

    rootDescription:CreateDivider()
    rootDescription:CreateButton(L.MENU_MANAGE_LIST, function()
        if Core.optionsCategory then
            Settings.OpenToCategory(Core.optionsCategory:GetID())
        end
    end)
end

-- ==============================================================================
-- Slash Command
-- ==============================================================================
SLASH_STRIX1 = "/strix"
SlashCmdList["STRIX"] = function(msg)
    if Core.optionsCategory then
        Settings.OpenToCategory(Core.optionsCategory:GetID())
    end
end
