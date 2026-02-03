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
    -- Tooltip
    TOOLTIP_TITLE = "Strix",
    TOOLTIP_HINT = "Right-click: Open alt list",

    -- Menu Headers
    HEADER_MY_ALTS = "My Alts",
    HEADER_RECENT_RECIPIENTS = "Recent Recipients",

    -- Menu Items
    MENU_NO_RECORDS = "No records yet",
    MENU_MANAGE_LIST = "Manage List...",

    -- Options Panel
    OPTIONS_HEADER = "Strix Management",
    OPTIONS_SLIDER_ALTS = "My Alts Display Limit: %d",
    OPTIONS_SLIDER_RECENT = "Recent Recipients Limit: %d",

    -- Tab Names
    TAB_MY_ALTS = "My Alts",
    TAB_RECENT = "Recent Recipients",

    -- Level Display
    LEVEL_FORMAT = "Lv.%d",
    LEVEL_UNKNOWN = "Lv.?",

    -- Recent Recipients Tab
    RECENT_NOTE = "(Cannot retrieve class/faction for other players)",
    AUTO_REMOVE_IF_ALT = "Auto-remove when logged in as this character",

    -- Actions
    ACTION_MOVE_TO_ALTS = "This is my alt",
}

-- ==============================================================================
-- 2. Simplified Chinese (zhCN)
-- ==============================================================================
local zhCN = {
    -- Tooltip
    TOOLTIP_TITLE = "Strix",
    TOOLTIP_HINT = "右键点击: 打开小号列表",

    -- Menu Headers
    HEADER_MY_ALTS = "我的小号",
    HEADER_RECENT_RECIPIENTS = "最近收件人",

    -- Menu Items
    MENU_NO_RECORDS = "暂无记录",
    MENU_MANAGE_LIST = "管理列表...",

    -- Options Panel
    OPTIONS_HEADER = "Strix 管理",
    OPTIONS_SLIDER_ALTS = "小号显示数量: %d",
    OPTIONS_SLIDER_RECENT = "最近收件人数量: %d",

    -- Tab Names
    TAB_MY_ALTS = "我的小号",
    TAB_RECENT = "最近收件人",

    -- Level Display
    LEVEL_FORMAT = "%d级",
    LEVEL_UNKNOWN = "等级未知",

    -- Recent Recipients Tab
    RECENT_NOTE = "(无法获取其他玩家的职业/阵营信息)",
    AUTO_REMOVE_IF_ALT = "登录该角色时自动移除",

    -- Actions
    ACTION_MOVE_TO_ALTS = "这是我的小号",
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

-- Apply English as base
ApplyLocale(enUS)

-- Override with client locale if available
local clientLocale = GetLocale()
if clientLocale == "zhCN" or clientLocale == "zhTW" then
    ApplyLocale(zhCN)
end

-- ==============================================================================
-- 4. Metatable for Robustness (returns key name if translation missing)
-- ==============================================================================
setmetatable(L, {
    __index = function(_, key)
        return tostring(key)
    end
})
