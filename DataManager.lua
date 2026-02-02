local _, addon = ...
local L = addon.L

-- ==========================================================
-- Module: DataManager
-- Purpose: Handles database CRUD operations (Create, Read, Update, Delete)
-- ==========================================================

addon.Data = {}
local Data = addon.Data

-- Sort Comparator: Realm -> Faction -> Name
local function SortAlts(a, b)
    if a.realm ~= b.realm then
        return a.realm < b.realm
    elseif a.faction ~= b.faction then
        return a.faction < b.faction
    else
        return a.name < b.name
    end
end

-- ==========================================================
-- Public Methods
-- ==========================================================

--- Initialize the database structure if it doesn't exist.
-- Called by Core on ADDON_LOADED.
function Data:Init()
    if not StrixDB then StrixDB = {} end
    if not StrixDB.alts then StrixDB.alts = {} end
    
    -- Future proofing: Metadata about DB version
    if not StrixDB.version then StrixDB.version = 1 end
end

--- Register or Update the current character.
-- @return boolean true if data was changed/added
function Data:RegisterCurrentCharacter()
    -- 1. Secure Data Retrieval (Robustness 6.1 & 8.1)
    local name = UnitName("player")
    local realm = GetRealmName()
    local faction = UnitFactionGroup("player") -- "Alliance", "Horde", or "Neutral"
    local _, classFile = UnitClass("player")   -- "WARRIOR", etc.

    -- 2. Validation (Robustness 6.2)
    -- If faction is nil (loading) or Neutral (Pandaren starter), do not register yet to avoid bad data.
    if not name or not realm or not faction or not classFile then 
        return false 
    end
    if faction == "Neutral" then 
        return false 
    end

    -- 3. Construct the record
    local record = {
        name = name,
        realm = realm,
        faction = faction,
        classFile = classFile, -- Store class for potential future coloring
        key = name .. "-" .. realm -- Unique Identifier
    }

    -- 4. Update or Insert
    local db = StrixDB.alts
    local exists = false
    
    for i, alt in ipairs(db) do
        if alt.key == record.key then
            -- Update existing entry (in case faction/race changed)
            db[i] = record
            exists = true
            break
        end
    end

    if not exists then
        table.insert(db, record)
        print(string.format(L.MSG_ADDED, name, realm))
    end

    -- 5. Sort the DB to keep menu organized
    table.sort(db, SortAlts)

    return true
end

--- Retrieve the full list of alts.
-- @return table indexed array of alt records
function Data:GetAlts()
    return StrixDB and StrixDB.alts or {}
end

--- Delete a character from the database.
-- @param index number The index in the StrixDB.alts table
-- @return boolean true if successful
function Data:DeleteAltByIndex(index)
    local db = StrixDB and StrixDB.alts
    if not db or not db[index] then return false end

    local name = db[index].name
    table.remove(db, index)
    
    print(string.format(L.MSG_DELETED, name))
    return true
end