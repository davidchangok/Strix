local addonName, addon = ...
local L = addon.L
local Data = addon.Data

-- ==========================================================
-- Constants & Configuration
-- ==========================================================
local ICON_TEXTURE = "Interface\\Icons\\inv_summerfest_symbol_owl"
local BTN_SIZE = 22

-- Faction Colors (Hex)
local COLORS = {
    Alliance = "0070DE", -- Alliance Blue
    Horde    = "C41F3B", -- Horde Red
    Neutral  = "F0F0F0", -- Panda/Neutral Grey
}

-- ==========================================================
-- Event Handling (Event-Driven Architecture)
-- ==========================================================
local Core = CreateFrame("Frame")
Core:RegisterEvent("ADDON_LOADED")
Core:RegisterEvent("PLAYER_ENTERING_WORLD")
Core:RegisterEvent("MAIL_SHOW")

Core:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            Data:Init()
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- 8.1 Data Privacy: Accessing UnitName/Faction is safe here
        local success = Data:RegisterCurrentCharacter()
        -- We can unregister this to keep the event loop clean (Zero-overhead after login)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")

    elseif event == "MAIL_SHOW" then
        -- Lazy load the UI only when user actually visits a mailbox
        if not self.isUILoaded then
            self:CreateStrixUI()
        end
    end
end)

-- ==========================================================
-- UI Construction (Modern API 12.0+)
-- ==========================================================
function Core:CreateStrixUI()
    -- 6.1 Combat Lockdown Check
    if InCombatLockdown() then 
        print("|cffff0000Strix:|r Cannot initialize UI during combat.")
        return 
    end

    -- Anchor to the standard SendMailNameEditBox
    local parent = SendMailNameEditBox
    if not parent then return end -- Safety check

    local btn = CreateFrame("Button", "StrixContactButton", SendMailFrame)
    btn:SetSize(BTN_SIZE, BTN_SIZE)
    -- Position: Right of the "To:" input box
    btn:SetPoint("LEFT", parent, "RIGHT", 4, 0)
    
    -- Visuals
    btn:SetNormalTexture(ICON_TEXTURE)
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    btn:GetNormalTexture():SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Zoom in slightly
    
    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.ADDON_TITLE)
        GameTooltip:AddLine(L.BTN_TOOLTIP, 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)

    -- Interaction: Open Menu
    -- 8.5 Using MenuUtil (New Context Menu System in Retail)
    btn:SetScript("OnClick", function(self)
        MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
            Core:BuildMenu(rootDescription)
        end)
    end)

    self.isUILoaded = true
end

-- ==========================================================
-- Menu Logic
-- ==========================================================
function Core:BuildMenu(rootDescription)
    local alts = Data:GetAlts()
    
    -- 1. Section: Recipients (The Alts)
    rootDescription:CreateTitle(L.HEADER_RECIPIENTS)

    if #alts == 0 then
        local btn = rootDescription:CreateButton(L.MSG_NO_ALTS or "No alts recorded yet", function() end)
        btn:SetEnabled(false)
    else
        for _, alt in ipairs(alts) do
            -- Format: [Color]Name - Realm|r
            local color = COLORS[alt.faction] or "FFFFFF"
            local displayText = string.format("|cFF%s%s|r - |cFF888888%s|r", color, alt.name, alt.realm)

            rootDescription:CreateButton(displayText, function()
                -- Action: Fill text box
                SendMailNameEditBox:SetText(alt.name .. "-" .. alt.realm)
                -- Optional: Set focus to Subject field for better UX
                if SendMailSubjectEditBox then
                    SendMailSubjectEditBox:SetFocus()
                end
            end)
        end
    end

    rootDescription:CreateDivider()

    -- 2. Section: Management (Deletion)
    local manageMenu = rootDescription:CreateButton(L.HEADER_MANAGE)
    
    manageMenu:CreateTitle(L.SUBMENU_DELETE)
    
    for i, alt in ipairs(alts) do
        local color = COLORS[alt.faction] or "FFFFFF"
        local deleteText = string.format(L.ACTION_DELETE, string.format("|cFF%s%s|r", color, alt.name))
        
        manageMenu:CreateButton(deleteText, function()
            Data:DeleteAltByIndex(i)
            -- Note: Menu usually closes after action. 
            -- User re-opening it will see updated list.
        end)
    end
end