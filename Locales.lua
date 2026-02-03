--[[
================================================================================
    Strix - Locales.lua
    Localization Module
================================================================================
    Description:
        Provides multi-language support for the Strix addon.
        Currently supports English (enUS) and Simplified Chinese (zhCN).

    Author: David W Zhang
    Version: 1.1.0
================================================================================
--]]

local _, addon = ...

addon.L = {}
local L = addon.L

-- ==============================================================================
-- 1. Default English (enUS)
-- ==============================================================================
local enUS = {
    -- Addon Info
    ADDON_TITLE = "Strix",

    -- Tooltip
    TOOLTIP_TITLE = "Strix",
    TOOLTIP_HINT = "Right-click: Open alt list",

    -- Menu Headers
    HEADER_RECIPIENTS = "Select Recipient",
    HEADER_MY_ALTS = "My Alts",
    HEADER_RECENT_RECIPIENTS = "Recent Recipients",

    -- Menu Items
    MENU_NO_RECORDS = "No records yet",
    MENU_MANAGE_LIST = "Manage List...",

    -- Options Panel
    OPTIONS_HEADER = "Strix Management",
    OPTIONS_DESC = "Drag to reorder, set display limit.",
    OPTIONS_SLIDER_ALTS = "My Alts Display Limit: %d",
    OPTIONS_SLIDER_RECENT = "Recent Recipients Limit: %d",

    -- Tab Names
    TAB_MY_ALTS = "My Alts",
    TAB_RECENT = "Recent Recipients",

    -- Level Display
    LEVEL_FORMAT = "Lv.%d",
    LEVEL_UNKNOWN = "Lv.?",

    -- Recent Recipients
    RECENT_NOTE = "(Cannot retrieve class/faction for other players)",
    CONFIRM_MOVE_TO_ALTS = "Move '%s' to My Alts list?",
    AUTO_REMOVE_IF_ALT = "Auto-remove when logged in as this character",

    -- Actions
    ACTION_DELETE = "Delete",
    ACTION_MOVE_TO_ALTS = "This is my alt",

    -- Messages
    MSG_RECIPIENT_SAVED = "Strix: Saved recipient %s.",
    MSG_MOVED_TO_ALTS = "Strix: Moved %s to My Alts.",
}

-- ==============================================================================
-- 2. Simplified Chinese (zhCN)
-- ==============================================================================
local zhCN = {
    -- Addon Info
    ADDON_TITLE = "Strix",

    -- Tooltip
    TOOLTIP_TITLE = "Strix",
    TOOLTIP_HINT = "右键点击: 打开小号列表",

    -- Menu Headers
    HEADER_RECIPIENTS = "选择收件人",
    HEADER_MY_ALTS = "我的小号",
    HEADER_RECENT_RECIPIENTS = "最近收件人",

    -- Menu Items
    MENU_NO_RECORDS = "暂无记录",
    MENU_MANAGE_LIST = "管理列表...",

    -- Options Panel
    OPTIONS_HEADER = "Strix 管理",
    OPTIONS_DESC = "拖拽调整顺序，设置显示数量。",
    OPTIONS_SLIDER_ALTS = "小号显示数量: %d",
    OPTIONS_SLIDER_RECENT = "最近收件人数量: %d",

    -- Tab Names
    TAB_MY_ALTS = "我的小号",
    TAB_RECENT = "最近收件人",

    -- Level Display
    LEVEL_FORMAT = "%d级",
    LEVEL_UNKNOWN = "等级未知",

    -- Recent Recipients
    RECENT_NOTE = "(无法获取其他玩家的职业/阵营信息)",
    CONFIRM_MOVE_TO_ALTS = "将 '%s' 移动到我的小号列表？",
    AUTO_REMOVE_IF_ALT = "登录该角色时自动移除",

    -- Actions
    ACTION_DELETE = "删除",
    ACTION_MOVE_TO_ALTS = "这是我的小号",

    -- Messages
    MSG_RECIPIENT_SAVED = "Strix: 已保存收件人 %s。",
    MSG_MOVED_TO_ALTS = "Strix: 已将 %s 移至我的小号。",
}

-- ==============================================================================
-- 3. Locale Detection and Application
-- ==============================================================================
local function ApplyLocale(source)
    if type(source) ~= "table" then return end
    for key, value in pairs(source) do
        L[key] = value
    end
end

ApplyLocale(enUS)

local clientLocale = GetLocale()
if clientLocale == "zhCN" or clientLocale == "zhTW" then
    ApplyLocale(zhCN)
end

-- ==============================================================================
-- 4. Metatable for Robustness
-- ==============================================================================
setmetatable(L, {
    __index = function(t, k)
        return tostring(k)
    end
})

-- ==============================================================================
-- 5. Locale API
-- ==============================================================================
function addon.GetLocale()
    return clientLocale or "enUS"
end
