--[[
================================================================================
    Strix - DataManager.lua
    Data Management Module
================================================================================
    Description:
        Manages all persistent data storage and retrieval for the Strix addon.
        Handles character registration, alt list, recent recipients, and settings.

    Data Structure (StrixDB):
        {
            version = number,
            displayLimit = number,          -- Max alts shown in menu
            recentDisplayLimit = number,    -- Max recent recipients shown
            autoRemoveIfAlt = boolean,      -- Auto-remove from recent if logged in
            alts = {                        -- My alt characters
                {
                    name, realm, faction, classFile, race, sex, level, key
                },
            },
            recentRecipients = {            -- Other players I've mailed
                {
                    name, realm, key, timestamp
                },
            }
        }

    Author: David W Zhang
    Version: 1.1.0
================================================================================
--]]

local _, addon = ...
local L = addon.L

addon.Data = {}
local Data = addon.Data

-- Constants
local DB_VERSION = 5
local DEFAULT_DISPLAY_LIMIT = 99
local DEFAULT_RECENT_LIMIT = 10
local MAX_RECENT_RECIPIENTS = 50

-- ==============================================================================
-- Private Helper Functions
-- ==============================================================================

local function ValidateDatabase()
    if type(StrixDB) ~= "table" then
        StrixDB = {}
    end

    if type(StrixDB.alts) ~= "table" then
        StrixDB.alts = {}
    end

    if type(StrixDB.recentRecipients) ~= "table" then
        StrixDB.recentRecipients = {}
    end

    if type(StrixDB.displayLimit) ~= "number" then
        StrixDB.displayLimit = DEFAULT_DISPLAY_LIMIT
    end

    if type(StrixDB.recentDisplayLimit) ~= "number" then
        StrixDB.recentDisplayLimit = DEFAULT_RECENT_LIMIT
    end

    if type(StrixDB.autoRemoveIfAlt) ~= "boolean" then
        StrixDB.autoRemoveIfAlt = true
    end

    if type(StrixDB.version) ~= "number" or StrixDB.version < DB_VERSION then
        StrixDB.version = DB_VERSION
    end

    return true
end

local function ValidateAltRecord(record)
    if type(record) ~= "table" then return false end
    if type(record.name) ~= "string" or record.name == "" then return false end
    if type(record.realm) ~= "string" or record.realm == "" then return false end
    if type(record.key) ~= "string" or record.key == "" then return false end
    return true
end

local function CleanupDatabase()
    if not StrixDB then return 0 end

    local removed = 0

    -- Cleanup alts
    if type(StrixDB.alts) == "table" then
        local validAlts = {}
        for _, alt in ipairs(StrixDB.alts) do
            if ValidateAltRecord(alt) then
                table.insert(validAlts, alt)
            else
                removed = removed + 1
            end
        end
        StrixDB.alts = validAlts
    end

    -- Cleanup recent recipients
    if type(StrixDB.recentRecipients) == "table" then
        local validRecent = {}
        for _, r in ipairs(StrixDB.recentRecipients) do
            if type(r) == "table" and type(r.key) == "string" then
                table.insert(validRecent, r)
            else
                removed = removed + 1
            end
        end
        StrixDB.recentRecipients = validRecent
    end

    return removed
end

-- ==============================================================================
-- Public API: Initialization
-- ==============================================================================

function Data:Init()
    ValidateDatabase()
    CleanupDatabase()
end

-- ==============================================================================
-- Public API: Character Registration (My Alts)
-- ==============================================================================

function Data:RegisterCurrentCharacter()
    local name = UnitName("player")
    local realm = GetRealmName()

    if not name or name == "" or not realm or realm == "" then
        return false
    end

    local faction = UnitFactionGroup("player")
    if not faction or faction == "Neutral" then
        return false
    end

    local _, classFile = UnitClass("player")
    local _, raceFile = UnitRace("player")
    local sex = UnitSex("player")
    local level = UnitLevel("player")

    local record = {
        name = name,
        realm = realm,
        faction = faction,
        classFile = classFile or "WARRIOR",
        race = raceFile or "Human",
        sex = sex or 2,
        level = level or 1,
        key = name .. "-" .. realm
    }

    ValidateDatabase()

    local db = StrixDB.alts
    local existingIndex = nil

    for i, alt in ipairs(db) do
        if alt.key == record.key then
            existingIndex = i
            break
        end
    end

    if existingIndex then
        db[existingIndex] = record
    else
        table.insert(db, record)
    end

    -- Auto-remove from recent recipients if enabled
    if StrixDB.autoRemoveIfAlt then
        self:RemoveRecentRecipient(record.key)
    end

    return true
end

function Data:GetAlts()
    if not StrixDB or type(StrixDB.alts) ~= "table" then
        return {}
    end
    return StrixDB.alts
end

function Data:GetAltByKey(key)
    if type(key) ~= "string" then return nil end
    for _, alt in ipairs(self:GetAlts()) do
        if alt.key == key then
            return alt
        end
    end
    return nil
end

function Data:IsMyAlt(key)
    return self:GetAltByKey(key) ~= nil
end

function Data:GetDisplayLimit()
    if not StrixDB or type(StrixDB.displayLimit) ~= "number" then
        return DEFAULT_DISPLAY_LIMIT
    end
    return StrixDB.displayLimit
end

function Data:SetDisplayLimit(value)
    if type(value) ~= "number" then return false end
    ValidateDatabase()
    StrixDB.displayLimit = math.max(1, math.min(99, math.floor(value)))
    return true
end

function Data:MoveAlt(fromIndex, toIndex)
    if type(fromIndex) ~= "number" or type(toIndex) ~= "number" then
        return false
    end

    fromIndex = math.floor(fromIndex)
    toIndex = math.floor(toIndex)

    if not StrixDB or type(StrixDB.alts) ~= "table" then
        return false
    end

    local db = StrixDB.alts
    local count = #db

    if fromIndex < 1 or fromIndex > count or toIndex < 1 or toIndex > count then
        return false
    end

    if fromIndex == toIndex then
        return true
    end

    local item = table.remove(db, fromIndex)
    if item then
        table.insert(db, toIndex, item)
        return true
    end

    return false
end

function Data:DeleteAltByIndex(index)
    if type(index) ~= "number" then return false end
    index = math.floor(index)

    if not StrixDB or type(StrixDB.alts) ~= "table" then
        return false
    end

    local db = StrixDB.alts
    if index < 1 or index > #db then
        return false
    end

    table.remove(db, index)
    return true
end

--[[
    Function: Data:PromoteAltToFirst
    Description: Moves an alt to the first position in the list
    Parameters:
        @param key (string) - The alt's key (name-realm)
    Returns:
        @return (boolean) - True if promoted, false if not found or already first
--]]
function Data:PromoteAltToFirst(key)
    if type(key) ~= "string" then return false end

    if not StrixDB or type(StrixDB.alts) ~= "table" then
        return false
    end

    local db = StrixDB.alts

    -- Find the alt's current index
    local foundIndex = nil
    for i, alt in ipairs(db) do
        if alt.key == key then
            foundIndex = i
            break
        end
    end

    -- Not found or already first
    if not foundIndex then return false end
    if foundIndex == 1 then return true end

    -- Remove and insert at first position
    local alt = table.remove(db, foundIndex)
    table.insert(db, 1, alt)

    return true
end

-- ==============================================================================
-- Public API: Recent Recipients (Non-Alt Players)
-- ==============================================================================

--[[
    Function: Data:AddRecentRecipient
    Description: Adds a mail recipient to the recent list (if not an alt)
    Parameters:
        @param name (string) - Character name
        @param realm (string) - Realm name
    Returns:
        @return (boolean) - True if added, false if skipped (is an alt)
--]]
function Data:AddRecentRecipient(name, realm)
    if type(name) ~= "string" or name == "" then return false end

    -- Default to current realm if not specified
    if type(realm) ~= "string" or realm == "" then
        realm = GetRealmName() or ""
    end

    local key = name .. "-" .. realm

    -- Skip if this is one of my alts
    if self:IsMyAlt(key) then
        return false
    end

    ValidateDatabase()

    local db = StrixDB.recentRecipients

    -- Check if already exists, update timestamp
    for i, r in ipairs(db) do
        if r.key == key then
            -- Move to front (most recent)
            table.remove(db, i)
            table.insert(db, 1, {
                name = name,
                realm = realm,
                key = key,
                timestamp = time()
            })
            return true
        end
    end

    -- Add new entry at front
    table.insert(db, 1, {
        name = name,
        realm = realm,
        key = key,
        timestamp = time()
    })

    -- Trim to max size
    while #db > MAX_RECENT_RECIPIENTS do
        table.remove(db)
    end

    return true
end

function Data:GetRecentRecipients()
    if not StrixDB or type(StrixDB.recentRecipients) ~= "table" then
        return {}
    end
    return StrixDB.recentRecipients
end

function Data:GetRecentDisplayLimit()
    if not StrixDB or type(StrixDB.recentDisplayLimit) ~= "number" then
        return DEFAULT_RECENT_LIMIT
    end
    return StrixDB.recentDisplayLimit
end

function Data:SetRecentDisplayLimit(value)
    if type(value) ~= "number" then return false end
    ValidateDatabase()
    StrixDB.recentDisplayLimit = math.max(1, math.min(MAX_RECENT_RECIPIENTS, math.floor(value)))
    return true
end

function Data:RemoveRecentRecipient(key)
    if type(key) ~= "string" then return false end

    if not StrixDB or type(StrixDB.recentRecipients) ~= "table" then
        return false
    end

    local db = StrixDB.recentRecipients
    for i, r in ipairs(db) do
        if r.key == key then
            table.remove(db, i)
            return true
        end
    end
    return false
end

function Data:RemoveRecentByIndex(index)
    if type(index) ~= "number" then return false end
    index = math.floor(index)

    if not StrixDB or type(StrixDB.recentRecipients) ~= "table" then
        return false
    end

    local db = StrixDB.recentRecipients
    if index < 1 or index > #db then
        return false
    end

    table.remove(db, index)
    return true
end

--[[
    Function: Data:MoveRecentToAlts
    Description: Moves a recent recipient to the alts list (user confirmed it's their alt)
    Parameters:
        @param index (number) - Index in recent recipients list
    Returns:
        @return (boolean) - True if moved successfully
--]]
function Data:MoveRecentToAlts(index)
    if type(index) ~= "number" then return false end
    index = math.floor(index)

    if not StrixDB or type(StrixDB.recentRecipients) ~= "table" then
        return false
    end

    local db = StrixDB.recentRecipients
    if index < 1 or index > #db then
        return false
    end

    local recipient = db[index]
    if not recipient then return false end

    -- Create a basic alt record (without class/faction/level since we don't know)
    local altRecord = {
        name = recipient.name,
        realm = recipient.realm,
        key = recipient.key,
        faction = nil,      -- Unknown
        classFile = nil,    -- Unknown
        race = nil,         -- Unknown
        sex = nil,          -- Unknown
        level = nil,        -- Unknown
    }

    -- Add to alts
    ValidateDatabase()
    table.insert(StrixDB.alts, altRecord)

    -- Remove from recent
    table.remove(db, index)

    return true
end

-- ==============================================================================
-- Public API: Settings
-- ==============================================================================

function Data:GetAutoRemoveIfAlt()
    if not StrixDB then return true end
    return StrixDB.autoRemoveIfAlt ~= false
end

function Data:SetAutoRemoveIfAlt(value)
    ValidateDatabase()
    StrixDB.autoRemoveIfAlt = (value == true)
    return true
end
