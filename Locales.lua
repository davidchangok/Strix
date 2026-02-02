local _, addon = ...

-- Initialize the Locale Table
addon.L = {}
local L = addon.L

-- ==========================================================
-- 1. Default English (enUS) - Fallback
-- ==========================================================
local enUS = {
    ADDON_TITLE = "Strix",
    BTN_TOOLTIP = "Open Strix Recipient Menu",
    
    -- Menu Headers
    HEADER_RECIPIENTS = "Select Recipient",
    HEADER_MANAGE = "Management",
    
    -- Submenus & Actions
    SUBMENU_DELETE = "Delete Character...",
    ACTION_DELETE = "Delete: %s",
    
    -- Feedback Messages
    MSG_ADDED = "Strix: Registered %s (%s).",
    MSG_DELETED = "Strix: Removed %s from database.",
    
    -- Formatting (For context, colors handled in Core)
    FACTION_ALLIANCE = "Alliance",
    FACTION_HORDE = "Horde",
    FACTION_UNKNOWN = "Unknown",
}

-- ==========================================================
-- 2. Simplified Chinese (zhCN)
-- ==========================================================
local zhCN = {
    ADDON_TITLE = "Strix (小号管家)",
    BTN_TOOLTIP = "打开 Strix 小号列表",
    
    -- Menu Headers
    HEADER_RECIPIENTS = "选择收件人",
    HEADER_MANAGE = "管理选项",
    
    -- Submenus & Actions
    SUBMENU_DELETE = "删除小号...",
    ACTION_DELETE = "删除： %s",
    
    -- Feedback Messages
    MSG_ADDED = "Strix: 已登记 %s (%s)。",
    MSG_DELETED = "Strix: 已从数据库移除 %s。",
    
    -- Formatting
    FACTION_ALLIANCE = "联盟",
    FACTION_HORDE = "部落",
    FACTION_UNKNOWN = "未知",
}

-- ==========================================================
-- 3. Logic: Metatable & Locale Detection
-- ==========================================================
-- Copy enUS to L first (Default)
for k, v in pairs(enUS) do
    L[k] = v
end

-- If client is zhCN, overwrite with zhCN values
if GetLocale() == "zhCN" then
    for k, v in pairs(zhCN) do
        L[k] = v
    end
end

-- Metatable to prevent nil errors (Robustness 6.2)
setmetatable(L, {
    __index = function(t, k)
        -- Fallback to key name if missing, helps debugging
        return k 
    end
})