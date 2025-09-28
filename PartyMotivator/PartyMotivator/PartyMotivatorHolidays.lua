--[[
    PartyMotivatorHolidays - World of Warcraft Addon
    Holiday system for seasonal messages
    Handles holiday detection and message management
]]

-- Create the holiday namespace
PartyMotivatorHolidays = {}
local PMH = PartyMotivatorHolidays

-- Holiday system state
PMH.calendarReady = false

-- Holiday region mapping (which holidays are relevant for which regions)
PMH.HOLIDAY_REGIONS = {
    HALLOWEEN = { US = true, EU = true, ASIA = false },          -- Mainly Western
    WINTER_VEIL = { US = true, EU = true, ASIA = true },         -- Global Christmas
    LOVE_IS_IN_THE_AIR = { US = true, EU = true, ASIA = false }, -- Western Valentine's
    BREWFEST = { US = false, EU = true, ASIA = false },          -- European Oktoberfest
    MIDSUMMER = { US = true, EU = true, ASIA = true },           -- Global summer festivals
    HARVEST_FESTIVAL = { US = true, EU = false, ASIA = false },  -- US Thanksgiving
    LUNAR_FESTIVAL = { US = false, EU = false, ASIA = true },    -- Asian New Year
    NOBLEGARDEN = { US = true, EU = true, ASIA = false }         -- Western Easter
}

-- Default holiday configuration
PMH.DEFAULT_HOLIDAYS = {
    enabled = true,
    regions = { US = true, EU = true, ASIA = true },
    events = {
        HALLOWEEN = {
            enabled = true,
            messages = {
                "Spooky keys!",
                "Trick or treat, but mostly trick!",
                "Boo! Did I scare the timer?",
                "Halloween spirits guide us to victory!",
                "Ghoulish pulls ahead!",
                "Pumpkin spice and everything nice... including keys!",
                "Haunted dungeon, but we're the real monsters!",
                "Candy for loot, tricks for mobs!",
                "This dungeon is about to get spooked!",
                "Jack-o'-lanterns light our way to success!"
            }
        },
        WINTER_VEIL = {
            enabled = true,
            messages = {
                "Ho ho ho, keys for all!",
                "Santa's sleigh is faster!",
                "Jingle bells, dungeon smells, victory all the way!",
                "Making a list, checking it twice, timing keys is nice!",
                "Winter Veil magic in every pull!",
                "Rudolph would be proud of this run!",
                "Presents under the tree, upgrades for me!",
                "Frosty the Snowman couldn't chill this team!",
                "Deck the halls with upgraded keys!",
                "Silent night, holy night, all is calm, all is bright... except our DPS!"
            }
        },
        LOVE_IS_IN_THE_AIR = {
            enabled = true,
            messages = {
                "Love is in the air... and in our DPS!",
                "Cupid's arrows, dungeon sparrows!",
                "Romance and keys, what more do we need?",
                "Heart-shaped pulls ahead!",
                "Love conquers all... especially timers!",
                "Be mine... to carry this key!",
                "Sweet as chocolate, fast as love!",
                "Roses are red, violets are blue, this key's getting upgraded too!",
                "Love makes us stronger, keys make us richer!",
                "Valentine's victory incoming!"
            }
        },
        BREWFEST = {
            enabled = true,
            messages = {
                "Cheers to upgraded keys!",
                "Brewfest and best DPS!",
                "Ale and victory, the perfect combo!",
                "Drink responsibly, play legendarily!",
                "Oktoberfest vibes, dungeon drives!",
                "Beer goggles make the timer look better!",
                "Prost! To timing this key!",
                "Hops, malt, and mythic salt!",
                "Brewery fresh, dungeon blessed!",
                "Ein Prosit to our success!"
            }
        },
        MIDSUMMER = {
            enabled = true,
            messages = {
                "Fire Festival flames, dungeon games!",
                "Hot summer, hotter plays!",
                "Midsummer magic in every pull!",
                "Burning bright like our DPS!",
                "Fire and brimstone, keys and victory!",
                "Summer solstice, dungeon practice!",
                "Flame on! Key up!",
                "Bonfire night, key upgrade sight!",
                "Hot like fire, fast like lightning!",
                "Summer heat, winter loot!"
            }
        },
        HARVEST_FESTIVAL = {
            enabled = true,
            messages = {
                "Harvest time, key prime!",
                "Reaping what we sow... upgraded keys!",
                "Autumn leaves, dungeon achieves!",
                "Thanksgiving for this great team!",
                "Harvest moon, dungeon soon!",
                "Grateful for these pulls!",
                "Cornucopia of victory!",
                "Fall colors, spring forward!",
                "Pumpkin spice and everything precise!",
                "Thankful for timed keys!"
            }
        },
        LUNAR_FESTIVAL = {
            enabled = true,
            messages = {
                "Lunar blessings on our run!",
                "New year, new keys!",
                "Dragon dance, dungeon chance!",
                "Fireworks and key works!",
                "Lucky coins, timed joins!",
                "Year of the upgraded key!",
                "Lantern light, dungeon sight!",
                "Fortune favors the fast!",
                "Red envelopes, gold keys!",
                "Prosperity and victory!"
            }
        },
        NOBLEGARDEN = {
            enabled = true,
            messages = {
                "Easter eggs and upgraded keys!",
                "Bunny hops, boss drops!",
                "Spring has sprung, victory's won!",
                "Egg hunt complete, key elite!",
                "Chocolate and success!",
                "Hoppy Easter, fast disaster!",
                "Spring cleaning the dungeon!",
                "Fresh as spring, fast as wind!",
                "Pastel colors, epic dollars!",
                "Rebirth and key worth!"
            }
        }
    }
}

--[[
    Calendar and Holiday System Functions
]]

local function PMH_OpenCalendar()
    C_Calendar.OpenCalendar()   -- lädt Daten asynchron
end

local function PMH_CurrentRegionKey()
    local id = GetCurrentRegion() -- 1=US, 2=KR, 3=EU, 4=TW, 5=CN (historisch)
    if id == 3 then return "EU" end
    if id == 1 then return "US" end
    return "ASIA" -- bündele KR/TW/CN als ASIA
end

local function PMH_TodayHolidayTag()
    local cfg = PM.profile and PM.profile.holidays
    if not cfg or not cfg.enabled then return nil end

    -- Region-Filter
    local rk = PMH_CurrentRegionKey()
    if cfg.regions and cfg.regions[rk] == false then return nil end

    if not PMH.calendarReady then
        PMH_OpenCalendar() -- erneut anstoßen, falls noch nicht ready
        return nil
    end

    local cal = C_DateAndTime.GetCurrentCalendarTime()
    local day  = cal.monthDay
    local n = C_Calendar.GetNumDayEvents(0, day) or 0
    for i = 1, n do
        local e = C_Calendar.GetDayEvent(0, day, i)
        if e and e.calendarType == "HOLIDAY" then
            local hi = C_Calendar.GetHolidayInfo(0, day, i)
            local name = (hi and hi.name) or (e.title or "")
            -- Hinweis: Namen sind lokalisiert; robuste Keyword-Checks:
            local lower = name:lower()
            
            -- Halloween / Hallow's End
            if (cfg.events.HALLOWEEN and cfg.events.HALLOWEEN.enabled)
               and (lower:find("hallow") or lower:find("allerseel") or lower:find("allhall")) then
                return "HALLOWEEN"
            end
            
            -- Winter Veil / Christmas
            if (cfg.events.WINTER_VEIL and cfg.events.WINTER_VEIL.enabled)
               and (lower:find("winter veil") or lower:find("winterveil") or lower:find("winterhauch") or lower:find("great-winter") or lower:find("christmas") or lower:find("weihnacht")) then
                return "WINTER_VEIL"
            end
            
            -- Love is in the Air / Valentine's Day
            if (cfg.events.LOVE_IS_IN_THE_AIR and cfg.events.LOVE_IS_IN_THE_AIR.enabled)
               and (lower:find("love is in the air") or lower:find("valentine") or lower:find("liebe liegt in der luft")) then
                return "LOVE_IS_IN_THE_AIR"
            end
            
            -- Brewfest / Oktoberfest
            if (cfg.events.BREWFEST and cfg.events.BREWFEST.enabled)
               and (lower:find("brewfest") or lower:find("oktoberfest") or lower:find("bierfest")) then
                return "BREWFEST"
            end
            
            -- Midsummer Fire Festival
            if (cfg.events.MIDSUMMER and cfg.events.MIDSUMMER.enabled)
               and (lower:find("midsummer") or lower:find("fire festival") or lower:find("sonnenwende") or lower:find("feuerfest")) then
                return "MIDSUMMER"
            end
            
            -- Harvest Festival / Thanksgiving
            if (cfg.events.HARVEST_FESTIVAL and cfg.events.HARVEST_FESTIVAL.enabled)
               and (lower:find("harvest") or lower:find("thanksgiving") or lower:find("erntedank") or lower:find("pilgrim")) then
                return "HARVEST_FESTIVAL"
            end
            
            -- Lunar Festival / Chinese New Year
            if (cfg.events.LUNAR_FESTIVAL and cfg.events.LUNAR_FESTIVAL.enabled)
               and (lower:find("lunar") or lower:find("new year") or lower:find("mondfest") or lower:find("neujahr")) then
                return "LUNAR_FESTIVAL"
            end
            
            -- Noblegarden / Easter
            if (cfg.events.NOBLEGARDEN and cfg.events.NOBLEGARDEN.enabled)
               and (lower:find("noblegarden") or lower:find("easter") or lower:find("ostern") or lower:find("egg")) then
                return "NOBLEGARDEN"
            end
        end
    end
    return nil
end

function PMH:PickStartMessageWithHoliday()
    -- 1) Holiday first
    local tag = PMH_TodayHolidayTag()
    if tag then
        local list = PM.profile.holidays.events[tag].messages or {}
        if #list > 0 then
            return list[math.random(#list)]
        end
    end
    -- 2) Fallback: normale Start-Messages
    local msgs = PM.profile.startMessages or {}
    if #msgs > 0 then return msgs[math.random(#msgs)] end
    return nil
end

--[[
    Holiday system initialization
]]
function PMH:InitializeHolidays()
    if not PM or not PM.profile then return end
    
    -- Initialize holidays system
    PM.profile.holidays = PM.profile.holidays or CopyTable(self.DEFAULT_HOLIDAYS)
    
    -- Robustheit: Felder auffüllen, falls alt
    local h = PM.profile.holidays
    h.enabled = (h.enabled ~= false)
    h.regions = h.regions or { US = true, EU = true, ASIA = true }
    h.events = h.events or {}
    h.events.HALLOWEEN         = h.events.HALLOWEEN         or CopyTable(self.DEFAULT_HOLIDAYS.events.HALLOWEEN)
    h.events.WINTER_VEIL       = h.events.WINTER_VEIL       or CopyTable(self.DEFAULT_HOLIDAYS.events.WINTER_VEIL)
    h.events.LOVE_IS_IN_THE_AIR = h.events.LOVE_IS_IN_THE_AIR or CopyTable(self.DEFAULT_HOLIDAYS.events.LOVE_IS_IN_THE_AIR)
    h.events.BREWFEST          = h.events.BREWFEST          or CopyTable(self.DEFAULT_HOLIDAYS.events.BREWFEST)
    h.events.MIDSUMMER         = h.events.MIDSUMMER         or CopyTable(self.DEFAULT_HOLIDAYS.events.MIDSUMMER)
    h.events.HARVEST_FESTIVAL  = h.events.HARVEST_FESTIVAL  or CopyTable(self.DEFAULT_HOLIDAYS.events.HARVEST_FESTIVAL)
    h.events.LUNAR_FESTIVAL    = h.events.LUNAR_FESTIVAL    or CopyTable(self.DEFAULT_HOLIDAYS.events.LUNAR_FESTIVAL)
    h.events.NOBLEGARDEN       = h.events.NOBLEGARDEN       or CopyTable(self.DEFAULT_HOLIDAYS.events.NOBLEGARDEN)
end

function PMH:InitializeAllProfileHolidays()
    if not PartyMotivatorDB or not PartyMotivatorDB.profiles then return end
    
    -- Initialize holidays for all profiles
    for name, profile in pairs(PartyMotivatorDB.profiles) do
        profile.holidays = profile.holidays or CopyTable(self.DEFAULT_HOLIDAYS)
        local ph = profile.holidays
        ph.enabled = (ph.enabled ~= false)
        ph.regions = ph.regions or { US = true, EU = true, ASIA = true }
        ph.events = ph.events or {}
        
        -- Force refresh of all holiday events with default messages
        ph.events.HALLOWEEN         = self:EnsureHolidayMessages(ph.events.HALLOWEEN, self.DEFAULT_HOLIDAYS.events.HALLOWEEN)
        ph.events.WINTER_VEIL       = self:EnsureHolidayMessages(ph.events.WINTER_VEIL, self.DEFAULT_HOLIDAYS.events.WINTER_VEIL)
        ph.events.LOVE_IS_IN_THE_AIR = self:EnsureHolidayMessages(ph.events.LOVE_IS_IN_THE_AIR, self.DEFAULT_HOLIDAYS.events.LOVE_IS_IN_THE_AIR)
        ph.events.BREWFEST          = self:EnsureHolidayMessages(ph.events.BREWFEST, self.DEFAULT_HOLIDAYS.events.BREWFEST)
        ph.events.MIDSUMMER         = self:EnsureHolidayMessages(ph.events.MIDSUMMER, self.DEFAULT_HOLIDAYS.events.MIDSUMMER)
        ph.events.HARVEST_FESTIVAL  = self:EnsureHolidayMessages(ph.events.HARVEST_FESTIVAL, self.DEFAULT_HOLIDAYS.events.HARVEST_FESTIVAL)
        ph.events.LUNAR_FESTIVAL    = self:EnsureHolidayMessages(ph.events.LUNAR_FESTIVAL, self.DEFAULT_HOLIDAYS.events.LUNAR_FESTIVAL)
        ph.events.NOBLEGARDEN       = self:EnsureHolidayMessages(ph.events.NOBLEGARDEN, self.DEFAULT_HOLIDAYS.events.NOBLEGARDEN)
    end
end

--[[
    Ensures a holiday event has all default messages
]]
function PMH:EnsureHolidayMessages(existingEvent, defaultEvent)
    local event = existingEvent or {}
    event.enabled = (event.enabled ~= false)
    event.messages = event.messages or {}
    
    -- Add missing default messages
    local existingMessages = {}
    for _, msg in ipairs(event.messages) do
        existingMessages[msg] = true
    end
    
    for _, defaultMsg in ipairs(defaultEvent.messages) do
        if not existingMessages[defaultMsg] then
            table.insert(event.messages, defaultMsg)
        end
    end
    
    return event
end

--[[
    Export/Import Delta functions for holidays
]]
function PMH:AddHolidaysToDiff(diff, p, d)
    -- Holidays (booleans/bitmask + message lists, nur wenn vom Default abweichend)
    local ph, dh = p.holidays or {}, d.holidays or {}
    
    -- Master + Regions
    if (ph.enabled and 1 or 0) ~= (dh.enabled and 1 or 0) then 
        diff.he = ph.enabled and "1" or "0" 
    end
    
    local function regionMask(h)
        local r = h.regions or {}
        local m = 0
        if r.US then m = m + 1 end
        if r.EU then m = m + 2 end
        if r.ASIA then m = m + 4 end
        return tostring(m)
    end
    
    if (ph.regions and regionMask(ph)) ~= (dh.regions and regionMask(dh)) then 
        diff.hr = regionMask(ph) 
    end
    
    -- Event flags
    if (ph.events and ph.events.HALLOWEEN and ph.events.HALLOWEEN.enabled) ~= (dh.events and dh.events.HALLOWEEN and dh.events.HALLOWEEN.enabled) then
        diff.hh = (ph.events.HALLOWEEN.enabled and "1" or "0")
    end
    if (ph.events and ph.events.WINTER_VEIL and ph.events.WINTER_VEIL.enabled) ~= (dh.events and dh.events.WINTER_VEIL and dh.events.WINTER_VEIL.enabled) then
        diff.hc = (ph.events.WINTER_VEIL.enabled and "1" or "0")
    end
    
    -- Local helper function to compare two lists
    local function equalsList(a, b)
        if type(a) ~= "table" or type(b) ~= "table" or #a ~= #b then 
            return false 
        end
        for i = 1, #a do 
            if a[i] ~= b[i] then 
                return false 
            end 
        end
        return true
    end

    -- Message lists (nur wenn geändert)
    local function listStrOrNil(list, def)
        list = list or {}
        def  = def  or {}
        if not equalsList(list, def) then 
            return table.concat(list, "\31") -- SEP_LIST
        end
        return nil
    end
    
    local dHE = dh.events and dh.events.HALLOWEEN    and dh.events.HALLOWEEN.messages    or {}
    local dWV = dh.events and dh.events.WINTER_VEIL  and dh.events.WINTER_VEIL.messages  or {}
    local pHE = ph.events and ph.events.HALLOWEEN    and ph.events.HALLOWEEN.messages    or {}
    local pWV = ph.events and ph.events.WINTER_VEIL  and ph.events.WINTER_VEIL.messages  or {}
    
    local sHE = listStrOrNil(pHE, dHE)
    local sWV = listStrOrNil(pWV, dWV)
    
    if sHE then diff.hmh = sHE end
    if sWV then diff.hmc = sWV end
end

function PMH:ApplyHolidaysDelta(p, delta)
    -- Holidays Grundstruktur
    p.holidays = {
        enabled = self.DEFAULT_HOLIDAYS.enabled,
        regions = CopyTable(self.DEFAULT_HOLIDAYS.regions),
        events  = {
            HALLOWEEN   = { 
                enabled = self.DEFAULT_HOLIDAYS.events.HALLOWEEN.enabled,
                messages = CopyTable(self.DEFAULT_HOLIDAYS.events.HALLOWEEN.messages) 
            },
            WINTER_VEIL = { 
                enabled = self.DEFAULT_HOLIDAYS.events.WINTER_VEIL.enabled,
                messages = CopyTable(self.DEFAULT_HOLIDAYS.events.WINTER_VEIL.messages) 
            },
            LOVE_IS_IN_THE_AIR = { 
                enabled = self.DEFAULT_HOLIDAYS.events.LOVE_IS_IN_THE_AIR.enabled,
                messages = CopyTable(self.DEFAULT_HOLIDAYS.events.LOVE_IS_IN_THE_AIR.messages) 
            },
            BREWFEST = { 
                enabled = self.DEFAULT_HOLIDAYS.events.BREWFEST.enabled,
                messages = CopyTable(self.DEFAULT_HOLIDAYS.events.BREWFEST.messages) 
            },
            MIDSUMMER = { 
                enabled = self.DEFAULT_HOLIDAYS.events.MIDSUMMER.enabled,
                messages = CopyTable(self.DEFAULT_HOLIDAYS.events.MIDSUMMER.messages) 
            },
            HARVEST_FESTIVAL = { 
                enabled = self.DEFAULT_HOLIDAYS.events.HARVEST_FESTIVAL.enabled,
                messages = CopyTable(self.DEFAULT_HOLIDAYS.events.HARVEST_FESTIVAL.messages) 
            },
            LUNAR_FESTIVAL = { 
                enabled = self.DEFAULT_HOLIDAYS.events.LUNAR_FESTIVAL.enabled,
                messages = CopyTable(self.DEFAULT_HOLIDAYS.events.LUNAR_FESTIVAL.messages) 
            },
            NOBLEGARDEN = { 
                enabled = self.DEFAULT_HOLIDAYS.events.NOBLEGARDEN.enabled,
                messages = CopyTable(self.DEFAULT_HOLIDAYS.events.NOBLEGARDEN.messages) 
            },
        },
    }
    
    if delta.he then p.holidays.enabled = (delta.he == "1") end
    if delta.hr then
        local m = tonumber(delta.hr) or 7
        p.holidays.regions.US   = (bit.band(m,1) ~= 0)
        p.holidays.regions.EU   = (bit.band(m,2) ~= 0)
        p.holidays.regions.ASIA = (bit.band(m,4) ~= 0)
    end
    if delta.hh then p.holidays.events.HALLOWEEN.enabled   = (delta.hh == "1") end
    if delta.hc then p.holidays.events.WINTER_VEIL.enabled = (delta.hc == "1") end
    if delta.hmh then 
        -- Use existing strToList functionality
        local out = {}
        for part in string.gmatch(delta.hmh, "([^\31]+)") do 
            table.insert(out, part) 
        end
        p.holidays.events.HALLOWEEN.messages = out
    end
    if delta.hmc then 
        -- Use existing strToList functionality
        local out = {}
        for part in string.gmatch(delta.hmc, "([^\31]+)") do 
            table.insert(out, part) 
        end
        p.holidays.events.WINTER_VEIL.messages = out
    end
end

--[[
    Event handling for holiday system
]]
local function onHolidayEvent(self, event, ...)
    if event == "CALENDAR_UPDATE_EVENT_LIST" then
        PMH.calendarReady = true
    end
end

-- Create event frame for holiday system
local holidayEventFrame = CreateFrame("Frame")
holidayEventFrame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
holidayEventFrame:SetScript("OnEvent", onHolidayEvent)

--[[
    Initialize calendar on addon load
]]
--[[
    Check if a holiday should be visible based on active regions
]]
function PMH:IsHolidayVisibleForRegions(holidayKey, activeRegions)
    if not self.HOLIDAY_REGIONS[holidayKey] then return true end -- Unknown holidays are always visible
    
    local holidayRegions = self.HOLIDAY_REGIONS[holidayKey]
    activeRegions = activeRegions or { US = true, EU = true, ASIA = true }
    
    -- Holiday is visible if at least one of its regions is active
    for region, isHolidayRegion in pairs(holidayRegions) do
        if isHolidayRegion and activeRegions[region] then
            return true
        end
    end
    
    return false
end

--[[
    Get list of visible holidays based on active regions
]]
function PMH:GetVisibleHolidays(activeRegions)
    local visible = {}
    local allHolidays = {"HALLOWEEN", "WINTER_VEIL", "LOVE_IS_IN_THE_AIR", "BREWFEST", 
                        "MIDSUMMER", "HARVEST_FESTIVAL", "LUNAR_FESTIVAL", "NOBLEGARDEN"}
    
    for _, holiday in ipairs(allHolidays) do
        if self:IsHolidayVisibleForRegions(holiday, activeRegions) then
            table.insert(visible, holiday)
        end
    end
    
    return visible
end

function PMH:Initialize()
    PMH_OpenCalendar()
    print("|cff00ff00PartyMotivator|r - Holiday system initialized")
end

--[[
    Initialize DEFAULT_PROFILE with holiday data
]]
function PMH:InitializeDefaultProfile(defaultProfile)
    if not defaultProfile.holidays.events then
        defaultProfile.holidays.events = CopyTable(self.DEFAULT_HOLIDAYS.events)
    end
end
