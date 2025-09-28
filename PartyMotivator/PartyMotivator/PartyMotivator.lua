--[[
    PartyMotivator - World of Warcraft Addon
    Sends motivational messages at dungeon start and greets new group members
    Extended with Mythic+ support and options panel
]]

-- Create the main event frame for the addon and make it globally accessible
local PM = CreateFrame("Frame")
_G.PM = PM

-- Global variables for the addon
local addonName = "PartyMotivator"
PM.lastGroupSize = 0
PM.startPosted = false  -- remembers if the start message was already sent
PM.endPosted = false    -- remembers if the completion message was already sent
PM.addonReady = false   -- flag to indicate when addon is fully initialized

-- Export/Import constants
local SEP_FIELDS = "\30"   -- record separator
local SEP_LIST   = "\31"   -- unit separator
local SEP_KV     = "="
local HEADER     = "PMX1|" -- Export header/version

-- Zentraler Default (einmal definieren!)
DEFAULT_PROFILE = {
    startMessages = {
        "Let's time this key!",
        "Ready for some big pulls?",
        "Time to show what we're made of!",
        "Clean run incoming!",
        "Let's make this look easy.",
        "Focus up, we've got this!",
        "Smooth and steady wins.",
        "Time to upgrade that key!",
        "Let's get that loot!",
        "Perfect execution time!",
        "Ready to dominate?",
        "Let's make it count!",
        "Mechanics check, DPS check, let's go!",
        "Time for some serious business.",
        "Let's turn up the heat!",
        "Victory tastes better when earned.",
        "Ready to crush this timer?",
        "Let's show them how it's done!",
        "Time to make some magic happen!",
        "Flawless run incoming!",
        "Let's paint this dungeon gold!",
        "Ready for greatness?",
        "Time to earn those upgrades!",
        "Let's make every pull count!",
        "Precision beats panic every time.",
        "Ready to rewrite the leaderboards?",
        "Let's turn this key into treasure!",
        "Time for some legendary plays!",
        "Ready to make history?",
        "Let's show this dungeon who's boss!",
        "Time to prove our worth!",
        "Ready for the challenge?",
        "Let's make this run memorable!",
        "Time to unleash our potential!",
        "Ready to exceed expectations?",
        "Let's make every second count!",
        "Time for some next-level gameplay!",
        "Ready to dominate the timer?",
        "Let's create something beautiful!",
        "Time to make our mark!"
    },
    greetMessages = {
        "Hello",
        "Hi",
        "Hey",
        "Greetings",
        "Welcome",
        "GLHF",
        "Sup",
        "Yo",
        "Howdy",
        "o/",
        "Hiya",
        "What's up",
        "Hi there",
        "Hey all",
        "Hello team",
        "Hi everyone",
        "Salutations",
        "Ahoy",
        "Heya",
        "Hi all",
        "Hey there",
        "Hello folks",
        "Hi guys",
        "Hey team",
        "Wassup",
        "G'day",
        "Cheers",
        "Aloha"
    },
    useInstanceChat = false,
    minimap = {
        show = true,
        angle = 220,
        radius = 80
    },
    -- Default holiday structure (will be populated by Holiday system if loaded)
    holidays = {
        enabled = true,
        regions = { US = true, EU = true, ASIA = true },
        events = {}
    },
    mythicPlusMessages = {
        success = {
            "Perfectly timed! Key upgraded!",
            "Flawless execution! Key goes up!",
            "Outstanding teamwork! Key upgraded!",
            "That's how legends are made! Key up!",
            "Smooth as butter! Key upgraded!",
            "Incredible performance! Key goes higher!",
            "Masterclass in dungeon running! Key up!",
            "Textbook perfect! Key upgraded!",
            "Absolutely crushing it! Key up!",
            "Peak performance achieved! Key upgraded!",
            "Pure skill on display! Key goes up!",
            "Surgical precision! Key upgraded!",
            "Teamwork makes dreams work! Key up!",
            "Like watching art in motion! Key upgraded!",
            "Legendary run! Key goes higher!",
            "That's championship level! Key up!",
            "Incredible synergy! Key upgraded!",
            "Perfection personified! Key goes up!",
            "Absolutely magnificent! Key upgraded!",
            "Elite level gameplay! Key up!"
        },
        failure = {
            "Good run! We'll crush it next time.",
            "Thanks for the key! Learning experience gained.",
            "Close one! We're getting stronger.",
            "Great effort! Next run is ours.",
            "Thanks for the key! Progress is progress.",
            "Good attempt! We'll nail it next time.",
            "Thanks for the key! Building towards victory.",
            "Solid try! Next run will be legendary.",
            "Thanks for the key! We're improving fast.",
            "Good run! Victory is just around the corner.",
            "Thanks for the key! We're leveling up our game.",
            "Nice effort! Next time we dominate.",
            "Thanks for the key! Experience points earned.",
            "Good run! We're getting better every attempt.",
            "Thanks for the key! Next run is our moment.",
            "Solid attempt! We're building momentum.",
            "Thanks for the key! Learning and growing.",
            "Good effort! Next time we make history.",
            "Thanks for the key! We're on the right track.",
            "Great try! Victory tastes sweeter after effort."
        }
    }
}

-- Default database for the addon (using DEFAULT_PROFILE)
local defaultDB = DEFAULT_PROFILE

--[[
    Delta-Serialization helper functions
    For compact export/import with Base64 encoding
]]

local function listToStr(t)
    return table.concat(t or {}, SEP_LIST)
end

local function strToList(s)
    local out = {}
    if s and s ~= "" then
        for part in string.gmatch(s, "([^"..SEP_LIST.."]+)") do 
            table.insert(out, part) 
        end
    end
    return out
end

local function flattenToStrings(list)
    local out = {}
    if type(list) == "table" then
        for i, item in ipairs(list) do
            if type(item) == "string" then
                table.insert(out, item)
            elseif type(item) == "table" then
                -- Recursively flatten nested tables
                local flattened = flattenToStrings(item)
                for _, subItem in ipairs(flattened) do
                    table.insert(out, subItem)
                end
            end
        end
    end
    return out
end

local function joinStrings(list, sep)
    local out = {}
    if type(list) ~= "table" then return "" end
    for _, v in ipairs(list) do 
        table.insert(out, tostring(v)) 
    end
    return table.concat(out, sep or " | ")
end

--[[
    Normalizes Mythic+ message tables to ensure they are always string arrays
]]
local function NormalizeMythicPlusTables(profile)
    profile.mythicPlusMessages = profile.mythicPlusMessages or { success = {}, failure = {} }
    local mp = profile.mythicPlusMessages
    
    -- Convert strings to arrays
    if type(mp.success) == "string" then 
        mp.success = { mp.success } 
    end
    if type(mp.failure) == "string" then 
        mp.failure = { mp.failure } 
    end
    
    -- Ensure they are tables
    if type(mp.success) ~= "table" then 
        mp.success = {} 
    end
    if type(mp.failure) ~= "table" then 
        mp.failure = {} 
    end
    
    -- Convert non-strings to strings (safety)
    for i, v in ipairs(mp.success) do 
        if type(v) ~= "string" then 
            mp.success[i] = tostring(v) 
        end 
    end
    for i, v in ipairs(mp.failure) do 
        if type(v) ~= "string" then 
            mp.failure[i] = tostring(v) 
        end 
    end
end

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

local function diffProfile(p, d)
    local diff = {}
    
    -- Compare start messages
    if not equalsList(p.startMessages or {}, d.startMessages or {}) then 
        diff.s = listToStr(p.startMessages or {}) 
    end
    
    -- Compare greet messages
    if not equalsList(p.greetMessages or {}, d.greetMessages or {}) then 
        diff.g = listToStr(p.greetMessages or {}) 
    end
    
    -- Compare useInstanceChat
    if (p.useInstanceChat and 1 or 0) ~= (d.useInstanceChat and 1 or 0) then 
        diff.i = p.useInstanceChat and "1" or "0" 
    end
    
    -- Compare mythic+ messages
    local ps, ds = (p.mythicPlusMessages or {}), (d.mythicPlusMessages or {})
    if not equalsList(ps.success or {}, ds.success or {}) then 
        diff.ms = listToStr(ps.success or {}) 
    end
    if not equalsList(ps.failure or {}, ds.failure or {}) then 
        diff.mf = listToStr(ps.failure or {}) 
    end
    
    -- Holidays (if holiday system is loaded)
    if PartyMotivatorHolidays then
        PartyMotivatorHolidays:AddHolidaysToDiff(diff, p, d)
    end
    
    return diff
end

local function applyDelta(delta)
    local p = {
        startMessages = {unpack(DEFAULT_PROFILE.startMessages)},
        greetMessages = {unpack(DEFAULT_PROFILE.greetMessages)},
        useInstanceChat = DEFAULT_PROFILE.useInstanceChat,
        mythicPlusMessages = {
            success = DEFAULT_PROFILE.mythicPlusMessages.success,
            failure = DEFAULT_PROFILE.mythicPlusMessages.failure,
        },
    }
    
    if delta.s then 
        p.startMessages = strToList(delta.s) 
    end
    if delta.g then 
        p.greetMessages = strToList(delta.g) 
    end
    if delta.i then 
        p.useInstanceChat = (delta.i == "1") 
    end
    if delta.ms then 
        p.mythicPlusMessages.success = strToList(delta.ms) 
    end
    if delta.mf then 
        p.mythicPlusMessages.failure = strToList(delta.mf) 
    end
    
    -- Apply holidays delta (if holiday system is loaded)
    if PartyMotivatorHolidays then
        PartyMotivatorHolidays:ApplyHolidaysDelta(p, delta)
    end
    
    return p
end

local function serializeDelta(delta)
    local parts = { "v"..SEP_KV.."1" }
    for k, v in pairs(delta) do 
        table.insert(parts, k..SEP_KV..v) 
    end
    return table.concat(parts, SEP_FIELDS)
end

local function deserializeDelta(raw)
    local t = {}
    for field in string.gmatch(raw, "([^"..SEP_FIELDS.."]+)") do
        local k, v = field:match("^([^"..SEP_KV.."]+)"..SEP_KV.."(.*)$")
        if k and v then 
            t[k] = v 
        end
    end
    return t
end

--[[
    Simple database initialization function
    Called on ADDON_LOADED to ensure SavedVariables are available
]]
local function InitializeDatabase()
    PartyMotivatorDB = PartyMotivatorDB or {}
    PartyMotivatorDB.profiles = PartyMotivatorDB.profiles or {}
    PartyMotivatorDB.activeProfile = PartyMotivatorDB.activeProfile or "Default"
    
    -- Create default profile if it doesn't exist
    if not PartyMotivatorDB.profiles[PartyMotivatorDB.activeProfile] then
        PartyMotivatorDB.profiles[PartyMotivatorDB.activeProfile] = {
            startMessages = CopyTable(defaultDB.startMessages),
            greetMessages = CopyTable(defaultDB.greetMessages),
            useInstanceChat = defaultDB.useInstanceChat,
            mythicPlusMessages = CopyTable(defaultDB.mythicPlusMessages)
        }
    end
    
    -- Set PM.profile to point to the active profile
    PM.profile = PartyMotivatorDB.profiles[PartyMotivatorDB.activeProfile]
end

--[[
    Extended database initialization with migration and updates
    This function is called after the basic initialization
]]
local function initializeDatabase()
    if not PartyMotivatorDB then
        PartyMotivatorDB = {}
    end
    
    -- Initialize profile system
    PartyMotivatorDB.profiles = PartyMotivatorDB.profiles or {}
    PartyMotivatorDB.activeProfile = PartyMotivatorDB.activeProfile or "Default"
    
    -- Create default profile if it doesn't exist
    if not PartyMotivatorDB.profiles[PartyMotivatorDB.activeProfile] then
        PartyMotivatorDB.profiles[PartyMotivatorDB.activeProfile] = {
            startMessages = CopyTable(defaultDB.startMessages),
            greetMessages = CopyTable(defaultDB.greetMessages),
            useInstanceChat = defaultDB.useInstanceChat,
            mythicPlusMessages = CopyTable(defaultDB.mythicPlusMessages)
        }
    end
    
    -- Migrate old data structure to profile system
    local needsUpdate = false
    
    -- Check if we need to migrate from old structure
    if PartyMotivatorDB.startMessages and not PartyMotivatorDB.profiles[PartyMotivatorDB.activeProfile].startMessages then
        PartyMotivatorDB.profiles[PartyMotivatorDB.activeProfile].startMessages = CopyTable(PartyMotivatorDB.startMessages)
        needsUpdate = true
    end
    
    if PartyMotivatorDB.greetMessages and not PartyMotivatorDB.profiles[PartyMotivatorDB.activeProfile].greetMessages then
        PartyMotivatorDB.profiles[PartyMotivatorDB.activeProfile].greetMessages = CopyTable(PartyMotivatorDB.greetMessages)
        needsUpdate = true
    end
    
    if PartyMotivatorDB.useInstanceChat ~= nil and PartyMotivatorDB.profiles[PartyMotivatorDB.activeProfile].useInstanceChat == nil then
        PartyMotivatorDB.profiles[PartyMotivatorDB.activeProfile].useInstanceChat = PartyMotivatorDB.useInstanceChat
        needsUpdate = true
    end
    
    if PartyMotivatorDB.mythicPlusMessages and not PartyMotivatorDB.profiles[PartyMotivatorDB.activeProfile].mythicPlusMessages then
        PartyMotivatorDB.profiles[PartyMotivatorDB.activeProfile].mythicPlusMessages = CopyTable(PartyMotivatorDB.mythicPlusMessages)
        needsUpdate = true
    end
    
    -- Set PM.profile to point to the active profile
    PM.profile = PartyMotivatorDB.profiles[PartyMotivatorDB.activeProfile]
    
    -- Initialize holidays system (if holiday system is loaded)
    if PartyMotivatorHolidays then
        PartyMotivatorHolidays:InitializeHolidays()
    end
    
    -- Normalize Mythic+ tables for all profiles
    for name, profile in pairs(PartyMotivatorDB.profiles) do
        NormalizeMythicPlusTables(profile)
    end
    
    -- Initialize holidays for all profiles (if holiday system is loaded)
    -- This ensures existing profiles get the latest holiday messages
    if PartyMotivatorHolidays then
        PartyMotivatorHolidays:InitializeAllProfileHolidays()
    end
    
    -- Check start messages - update if less than 40 messages (new default count)
    if not PM.profile.startMessages or type(PM.profile.startMessages) ~= "table" or #PM.profile.startMessages < 40 then
        PM.profile.startMessages = CopyTable(defaultDB.startMessages)
        needsUpdate = true
    end
    
    -- Check greetings - update if less than 29 messages (new default count)
    if not PM.profile.greetMessages or type(PM.profile.greetMessages) ~= "table" or #PM.profile.greetMessages < 29 then
        PM.profile.greetMessages = CopyTable(defaultDB.greetMessages)
        needsUpdate = true
    end
    
    -- Check chat setting
    if type(PM.profile.useInstanceChat) ~= "boolean" then
        PM.profile.useInstanceChat = defaultDB.useInstanceChat
        needsUpdate = true
    end
    
    -- Mythic+ messages are now handled by NormalizeMythicPlusTables above
    
    -- Check Mythic+ messages
    if not PM.profile.mythicPlusMessages or type(PM.profile.mythicPlusMessages) ~= "table" then
        PM.profile.mythicPlusMessages = CopyTable(defaultDB.mythicPlusMessages)
        needsUpdate = true
    end
    
    -- Check minimap settings
    if not PM.profile.minimap or type(PM.profile.minimap) ~= "table" then
        PM.profile.minimap = CopyTable(defaultDB.minimap)
        needsUpdate = true
    end
    
    -- Debug output
    if needsUpdate then
        print("|cff00ff00PartyMotivator|r - Database updated with new messages!")
    end
    print(string.format("|cff00ff00PartyMotivator|r - Database initialized: %d start messages, %d greetings, Mythic+ messages", 
        #PM.profile.startMessages, #PM.profile.greetMessages))
    print(string.format("|cff00ff00PartyMotivator|r - Active profile: %s", PartyMotivatorDB.activeProfile))
    
    -- Mark addon as ready
    PM.addonReady = true
end

--[[
    Minimap Button Functions
    Creates and manages the minimap button for PartyMotivator
]]

--[[
    Creates the minimap button
]]
local function PM_CreateMinimapButton()
    if PM.MinimapButton then return end
    
    local b = CreateFrame("Button", "PM_MinimapButton", Minimap)
    b:SetSize(32, 32)
    b:SetFrameStrata("MEDIUM")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Icon + Ring
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\PartyMotivator\\media\\pm_icon")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    b.icon = icon

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")

    -- Tooltip
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("PartyMotivator")
        GameTooltip:AddLine("Left-Click: Open UI", 1,1,1)
        GameTooltip:AddLine("Right-Drag: Move", 1,1,1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Klick: UI öffnen
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", function(_, btn)
        if btn == "LeftButton" then
            if PartyMotivatorUI and PartyMotivatorUI.Toggle then
                PartyMotivatorUI:Toggle()
            elseif PartyMotivatorUI and PartyMotivatorUI.ShowUI then
                PartyMotivatorUI:ShowUI()
            end
        end
    end)

    -- Drag rund um die Minimap (Cursor -> Winkel -> Position)
    b:RegisterForDrag("RightButton")
    b:SetScript("OnDragStart", function(self) 
        self.isDragging = true
        self:LockHighlight() 
    end)
    b:SetScript("OnDragStop", function(self) 
        self.isDragging = nil
        self:UnlockHighlight() 
    end)
    b:SetScript("OnUpdate", function(self)
        if not self.isDragging then return end
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        cx, cy = cx/scale, cy/scale
        local angle = math.atan2(cy - my, cx - mx) -- radians
        PM.profile.minimap.angle = math.deg(angle)
        PM_UpdateMinimapButtonPosition()
    end)

    b:SetClampedToScreen(true)
    PM.MinimapButton = b
end

--[[
    Updates the minimap button position based on saved settings
]]
function PM_UpdateMinimapButtonPosition()
    if not (PM and PM.MinimapButton) then return end
    PM.profile.minimap = PM.profile.minimap or { show = true, angle = 220, radius = 80 }
    local angle = (PM.profile.minimap.angle or 220) * math.pi/180
    local r = PM.profile.minimap.radius or 80
    local x = math.cos(angle) * r
    local y = math.sin(angle) * r
    PM.MinimapButton:ClearAllPoints()
    PM.MinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

--[[
    Updates the minimap button visibility based on saved settings
]]
function PM_UpdateMinimapButtonVisibility()
    if not PM.MinimapButton then return end
    if PM.profile.minimap.show ~= false then
        PM.MinimapButton:Show()
    else
        PM.MinimapButton:Hide()
    end
end

--[[
    Initializes the minimap button system
]]
function PM:InitMinimap()
    PM_CreateMinimapButton()
    PM_UpdateMinimapButtonPosition()
    PM_UpdateMinimapButtonVisibility()
end


--[[
    Sends a motivational start message
    This function is used for dungeon start and Mythic+ countdown
    Now supports holiday messages with fallback to regular messages
]]
function PM:SendStartMessage()
    local msg
    
    -- Try holiday message first (if holiday system is loaded)
    if PartyMotivatorHolidays then
        msg = PartyMotivatorHolidays:PickStartMessageWithHoliday()
    else
        -- Fallback: normale Start-Messages
        local msgs = PM.profile.startMessages or {}
        if #msgs > 0 then 
            msg = msgs[math.random(#msgs)] 
        end
    end
    
    if msg then
        local channel = PM.profile.useInstanceChat and "INSTANCE_CHAT" or "PARTY"
        C_ChatInfo.SendChatMessage(msg, channel)
        return true
    end
    return false
end

--[[
    Sends a greeting message to new group members
    This function is called when the group composition changes
]]
local function greetNewMembers()
    local greetings = PM.profile.greetMessages or {}
    if #greetings == 0 then
        return
    end
    
    local currentGroupSize = GetNumGroupMembers()
    
    -- Check if group size increased (new members)
    if currentGroupSize > PM.lastGroupSize and currentGroupSize > 1 then
        -- Choose a random greeting from the list
        local randomIndex = math.random(1, #greetings)
        local selectedGreeting = greetings[randomIndex]
        
        C_ChatInfo.SendChatMessage(selectedGreeting, "PARTY")
    end
    
    -- Update the stored group size
    PM.lastGroupSize = currentGroupSize
end

--[[
    Profile management functions
    Handles saving, loading, deleting, exporting and importing profiles
]]

--[[
    Saves the current profile with the given name
]]
function PM:SaveProfile(name)
    if not name or name == "" then
        print("|cffff0000Error:|r Please provide a profile name")
        return false
    end
    
    PartyMotivatorDB.profiles[name] = CopyTable(self.profile)
    print(string.format("|cff00ff00PartyMotivator|r - Profile '%s' saved!", name))
    return true
end

--[[
    Loads a profile with the given name
]]
function PM:LoadProfile(name)
    if not name or name == "" then
        print("|cffff0000Error:|r Please provide a profile name")
        return false
    end
    
    if not PartyMotivatorDB.profiles[name] then
        print(string.format("|cffff0000Error:|r Profile '%s' not found", name))
        return false
    end
    
    PartyMotivatorDB.activeProfile = name
    self.profile = PartyMotivatorDB.profiles[name]
    print(string.format("|cff00ff00PartyMotivator|r - Profile '%s' loaded!", name))
    return true
end

--[[
    Deletes a profile with the given name
]]
function PM:DeleteProfile(name)
    if not name or name == "" then
        print("|cffff0000Error:|r Please provide a profile name")
        return false
    end
    
    if name == PartyMotivatorDB.activeProfile then
        print("|cffff0000Error:|r Cannot delete the active profile")
        return false
    end
    
    if not PartyMotivatorDB.profiles[name] then
        print(string.format("|cffff0000Error:|r Profile '%s' not found", name))
        return false
    end
    
    PartyMotivatorDB.profiles[name] = nil
    print(string.format("|cff00ff00PartyMotivator|r - Profile '%s' deleted!", name))
    return true
end

--[[
    Lists all available profiles
]]
function PM:ListProfiles()
    local profiles = {}
    for name, _ in pairs(PartyMotivatorDB.profiles) do
        table.insert(profiles, name)
    end
    
    if #profiles == 0 then
        print("|cffff0000PartyMotivator|r - No profiles found")
        return
    end
    
    table.sort(profiles)
    print("|cff00ff00PartyMotivator|r - Available profiles:")
    for i, name in ipairs(profiles) do
        local marker = (name == PartyMotivatorDB.activeProfile) and "|cff00ff00[ACTIVE]|r" or ""
        print(string.format("|cffffffff%d.|r %s %s", i, name, marker))
    end
end

--[[
    Exports a profile to a string format
]]
function PM:ExportProfile(name)
    local profile = PartyMotivatorDB.profiles[name]
    if not profile then
        print(("|cffff0000Error:|r Profile '%s' not found"):format(tostring(name)))
        return
    end
    
    local delta = diffProfile(profile, DEFAULT_PROFILE)
    local payload = serializeDelta(delta)
    
    -- Base64 via Blizzard API (keine Abhängigkeit)
    local b64 = C_EncodingUtil.EncodeBase64(payload)
    return HEADER .. (b64 or "")
end

--[[
    Imports a profile from a string format
]]
function PM:ImportProfile(name, data)
    if not name or name == "" or not data or data == "" then
        print("|cffff0000Error:|r Please provide profile name and data")
        return false
    end
    
    if data:sub(1, #HEADER) ~= HEADER then
        print("|cffff0000Error:|r Unsupported or old format")
        return false
    end
    
    local raw = C_EncodingUtil.DecodeBase64(data:sub(#HEADER+1))
    if not raw then
        print("|cffff0000Error:|r Invalid base64 data")
        return false
    end
    
    local delta = deserializeDelta(raw)
    local prof = applyDelta(delta)
    PartyMotivatorDB.profiles[name] = prof
    
    print(("|cff00ff00PartyMotivator|r - Profile '%s' imported."):format(name))
    return true
end

--[[
    Slash-Command Handler for /pm
    Allows addon configuration via chat commands
]]
local function handleSlashCommand(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end
    
    if #args == 0 then
        print("|cff00ff00PartyMotivator|r - Available commands:")
        print("|cffffffff/pm list|r - Show all messages")
        print("|cffffffff/pm add <message>|r - Add a new message")
        print("|cffffffff/pm remove <number>|r - Remove a message")
        print("|cffffffff/pm chat|r - Toggle between INSTANCE_CHAT and PARTY")
        print("|cffffffff/pm greet add <message>|r - Add a new greeting")
        print("|cffffffff/pm greet remove <number>|r - Remove a greeting")
        print("|cffffffff/pm mythic success <message>|r - Set success message")
        print("|cffffffff/pm mythic failure <message>|r - Set failure message")
        print("|cffffffff/pm reset|r - Reset messages to default")
        print("|cffffffff/pm resetpos|r - Reset UI position")
        print("|cffffffff/pm profile save <name>|r - Save current profile")
        print("|cffffffff/pm profile load <name>|r - Load profile")
        print("|cffffffff/pm profile delete <name>|r - Delete profile")
        print("|cffffffff/pm profile list|r - List all profiles")
        print("|cffffffff/pm profile export <name>|r - Export profile")
        print("|cffffffff/pm profile import <name> <data>|r - Import profile")
        return
    end
    
    local command = args[1]:lower()
    
    if command == "list" then
        print("|cff00ff00PartyMotivator|r - Current messages:")
        for i, msg in ipairs(PM.profile.startMessages or {}) do
            print(string.format("|cffffffff%d.|r %s", i, tostring(msg)))
        end

        print("|cff00ff00PartyMotivator|r - Greetings:")
        for i, msg in ipairs(PM.profile.greetMessages or {}) do
            print(string.format("|cffffffff%d.|r %s", i, tostring(msg)))
        end

        print("|cff9966ffPartyMotivator|r - Mythic+ messages:")
        local mp = PM.profile.mythicPlusMessages or { success = {}, failure = {} }
        mp.success = flattenToStrings(mp.success)
        mp.failure = flattenToStrings(mp.failure)
        
        if #mp.success > 0 then
            print("|cff00ff00Success messages:|r " .. joinStrings(mp.success, " | "))
        else
            print("|cff888888No success messages configured|r")
        end
        if #mp.failure > 0 then
            print("|cffff6600Failure messages:|r " .. joinStrings(mp.failure, " | "))
        else
            print("|cff888888No failure messages configured|r")
        end

        print(string.format("|cffffffffChat channel:|r %s", PM.profile.useInstanceChat and "INSTANCE_CHAT" or "PARTY"))
        print(string.format("|cffffffffActive profile:|r %s", PartyMotivatorDB.activeProfile))
        return
        
    elseif command == "add" then
        if #args < 2 then
            print("|cffff0000Error:|r Please provide a message: /pm add <message>")
            return
        end
        
        local newMessage = table.concat(args, " ", 2)
        if not PM.profile.startMessages then
            PM.profile.startMessages = {}
        end
        table.insert(PM.profile.startMessages, newMessage)
        print(string.format("|cff00ff00PartyMotivator|r - Message added: %s", newMessage))
        print(string.format("|cff00ff00PartyMotivator|r - Currently %d start messages saved", #PM.profile.startMessages))
        
    elseif command == "remove" then
        if #args < 2 then
            print("|cffff0000Error:|r Please provide a number: /pm remove <number>")
            return
        end
        
        local messages = PM.profile.startMessages or {}
        local index = tonumber(args[2])
        if not index or index < 1 or index > #messages then
            print("|cffff0000Error:|r Invalid number")
            return
        end
        
        local removedMessage = table.remove(messages, index)
        print(string.format("|cff00ff00PartyMotivator|r - Message removed: %s", removedMessage))
        print(string.format("|cff00ff00PartyMotivator|r - Currently %d start messages saved", #messages))
        
    elseif command == "chat" then
        PM.profile.useInstanceChat = not PM.profile.useInstanceChat
        local chatType = PM.profile.useInstanceChat and "INSTANCE_CHAT" or "PARTY"
        print(string.format("|cff00ff00PartyMotivator|r - Chat channel changed to: %s", chatType))
        
    elseif command == "greet" then
        if #args < 3 then
            print("|cffff0000Error:|r Please provide a command: /pm greet add <message> or /pm greet remove <number>")
            return
        end
        
        local subCommand = args[2]:lower()
        
        if subCommand == "add" then
            if #args < 3 then
                print("|cffff0000Error:|r Please provide a message: /pm greet add <message>")
                return
            end
            
            local newGreeting = table.concat(args, " ", 3)
            if not PM.profile.greetMessages then
                PM.profile.greetMessages = {}
            end
            table.insert(PM.profile.greetMessages, newGreeting)
            print(string.format("|cff00ff00PartyMotivator|r - Greeting added: %s", newGreeting))
            print(string.format("|cff00ff00PartyMotivator|r - Currently %d greetings saved", #PM.profile.greetMessages))
            
        elseif subCommand == "remove" then
            if #args < 3 then
                print("|cffff0000Error:|r Please provide a number: /pm greet remove <number>")
                return
            end
            
            local greetings = PM.profile.greetMessages or {}
            local index = tonumber(args[3])
            if not index or index < 1 or index > #greetings then
                print("|cffff0000Error:|r Invalid number")
                return
            end
            
            local removedGreeting = table.remove(greetings, index)
            print(string.format("|cff00ff00PartyMotivator|r - Greeting removed: %s", removedGreeting))
            print(string.format("|cff00ff00PartyMotivator|r - Currently %d greetings saved", #greetings))
            
        else
            print("|cffff0000Error:|r Unknown command. Use 'add' or 'remove'")
        end
        
    elseif command == "mythic" then
        if #args < 3 then
            print("|cffff0000Error:|r Use /pm mythic success <msg> or /pm mythic failure <msg>")
            return
        end
        
        local sub = args[2]:lower()
        local text = table.concat(args, " ", 3)
        
        PM.profile.mythicPlusMessages = PM.profile.mythicPlusMessages or { success = {}, failure = {} }
        
        if sub == "success" then
            PM.profile.mythicPlusMessages.success = PM.profile.mythicPlusMessages.success or {}
            table.insert(PM.profile.mythicPlusMessages.success, text)
            print(string.format("|cff00ff00PartyMotivator|r - Success message added: %s", text))
            
        elseif sub == "failure" then
            PM.profile.mythicPlusMessages.failure = PM.profile.mythicPlusMessages.failure or {}
            table.insert(PM.profile.mythicPlusMessages.failure, text)
            print(string.format("|cff00ff00PartyMotivator|r - Failure message added: %s", text))
        else
            print("|cffff0000Error:|r Unknown: success|failure")
        end
        
    elseif command == "reset" then
        -- Reset messages to default
        PM.profile.startMessages = CopyTable(defaultDB.startMessages)
        PM.profile.greetMessages = CopyTable(defaultDB.greetMessages)
        PM.profile.mythicPlusMessages = CopyTable(defaultDB.mythicPlusMessages)
        -- Reset holidays (if holiday system is loaded)
        if PartyMotivatorHolidays then
            PM.profile.holidays = CopyTable(PartyMotivatorHolidays.DEFAULT_HOLIDAYS)
            print("|cff00ff00PartyMotivator|r - Holiday settings reset.")
        end
        print("|cff00ff00PartyMotivator|r - Messages reset to default!")
        print(string.format("|cff00ff00PartyMotivator|r - %d start messages, %d greetings, Mythic+ messages loaded", 
            #PM.profile.startMessages, #PM.profile.greetMessages))
        
    elseif command == "resetpos" then
        -- Reset UI position
        if PartyMotivatorUI and PartyMotivatorUI.mainFrame then
            PartyMotivatorUI.mainFrame:ClearAllPoints()
            PartyMotivatorUI.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            print("|cff00ff00PartyMotivator|r - UI position reset!")
        else
            print("|cffff0000PartyMotivator|r - UI is not loaded!")
        end
        
    elseif command == "testexport" then
        -- Test export window directly with real export
        if PartyMotivatorUI and PartyMotivatorUI.ShowExportWindow then
            local activeProfile = PartyMotivatorDB.activeProfile or "Default"
            local exportCode = PM:ExportProfile(activeProfile)
            if exportCode then
                PartyMotivatorUI:ShowExportWindow(activeProfile, exportCode)
            else
                print("|cffff0000PartyMotivator|r - Failed to generate export code!")
            end
        else
            print("|cffff0000PartyMotivator|r - UI is not loaded!")
        end
        
    elseif command == "updateholidays" then
        -- Update holiday messages for all profiles
        if PartyMotivatorHolidays then
            PartyMotivatorHolidays:InitializeAllProfileHolidays()
            print("|cff00ff00PartyMotivator|r - Holiday messages updated for all profiles!")
        else
            print("|cffff0000PartyMotivator|r - Holiday system not loaded!")
        end
        
    elseif command == "profile" then
        if #args < 2 then
            print("|cffff0000Error:|r Please provide a profile command: /pm profile <save|load|delete|list|export|import>")
            return
        end
        
        local subCommand = args[2]:lower()
        
        if subCommand == "save" then
            if #args < 3 then
                print("|cffff0000Error:|r Please provide a profile name: /pm profile save <name>")
                return
            end
            PM:SaveProfile(args[3])
            
        elseif subCommand == "load" then
            if #args < 3 then
                print("|cffff0000Error:|r Please provide a profile name: /pm profile load <name>")
                return
            end
            PM:LoadProfile(args[3])
            
        elseif subCommand == "delete" then
            if #args < 3 then
                print("|cffff0000Error:|r Please provide a profile name: /pm profile delete <name>")
                return
            end
            PM:DeleteProfile(args[3])
            
        elseif subCommand == "list" then
            PM:ListProfiles()
            
        elseif subCommand == "export" then
            if #args < 3 then
                print("|cffff0000Error:|r Please provide a profile name: /pm profile export <name>")
                return
            end
            local exportCode = PM:ExportProfile(args[3])
            if exportCode then
                print("|cff00ff00PartyMotivator|r - Export code for profile '" .. args[3] .. "':")
                print(exportCode)
            end
            
        elseif subCommand == "import" then
            if #args < 4 then
                print("|cffff0000Error:|r Please provide profile name and data: /pm profile import <name> <data>")
                return
            end
            local profileName = args[3]
            local profileData = table.concat(args, " ", 4)
            PM:ImportProfile(profileName, profileData)
            
        else
            print("|cffff0000Error:|r Unknown profile command. Use 'save', 'load', 'delete', 'list', 'export', or 'import'")
        end
        
    else
        print("|cffff0000Error:|r Unknown command. Use /pm for help.")
    end
end

-- Event-Handler Funktion
local function onEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            -- Initialize database first (SavedVariables are guaranteed available)
            InitializeDatabase()
            
            -- Now we are ready
            PM.addonReady = true
            
            -- Debug output
            print("ADDON_LOADED for PartyMotivator; ready=", PM.addonReady)
            
            -- Initialize extended database features
            initializeDatabase()
            
            -- Initialize options panel
            PM:InitializeOptions()
            
            -- Initialize UI after database is ready (optional, lazy initialization)
            if PartyMotivatorUI and PartyMotivatorUI.Initialize and not PartyMotivatorUI._initialized then
                PartyMotivatorUI:Initialize()
            end
            
            -- Initialize minimap button
            PM:InitMinimap()
            
            -- Initialize holiday system
            if PartyMotivatorHolidays then
                PartyMotivatorHolidays:InitializeDefaultProfile(DEFAULT_PROFILE)
                PartyMotivatorHolidays:Initialize()
            end
            
            print("|cff00ff00PartyMotivator|r - Addon loaded! Use /pm or /pmoptions for options.")
        end
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Reset flags when entering/leaving an instance
        PM.startPosted = false
        PM.endPosted = false
        
        -- Check if player is in a 5-player instance
        local isInInstance, instanceType = IsInInstance()
        if isInInstance and instanceType == "party" then
            local _, _, difficultyID = GetInstanceInfo()
            
            
            -- Only motivate immediately for Normal (1) or Heroic (2)
            -- All other Difficulty-IDs (including 23 and 8) are ignored
            if difficultyID == 1 or difficultyID == 2 then
                if PM:SendStartMessage() then
                    PM.startPosted = true
                    local difficultyName = difficultyID == 1 and "Normal" or "Heroic"
                    print(string.format("|cff00ff00PartyMotivator|r - %s Dungeon entered! Motivational message sent.", difficultyName))
                end
            else
                -- For all other Difficulty-IDs (23, 8, etc.) wait for the timer
                PM.startPosted = false
                local difficultyName = "Unknown"
                if difficultyID == 23 then
                    difficultyName = "Mythic"
                elseif difficultyID == 8 then
                    difficultyName = "Mythic+"
                else
                    difficultyName = "Difficulty " .. tostring(difficultyID)
                end
                print(string.format("|cff00ff00PartyMotivator|r - %s Dungeon entered! Waiting for countdown...", difficultyName))
            end
        end
        
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Greet new group members
        greetNewMembers()
        
    elseif event == "START_TIMER" then
        -- Timer started -> send motivational message
        local timerType, timeRemaining, totalTime = ...
        
        -- Check if it's the Mythic+ countdown (Enum.StartTimerType.ChallengeModeCountdown == 1)
        if timerType == Enum.StartTimerType.ChallengeModeCountdown and not PM.startPosted then
            if PM:SendStartMessage() then
                PM.startPosted = true
                print("|cff00ff00PartyMotivator|r - Mythic+ countdown started! Motivational message sent.")
            end
        end
        
    elseif event == "CHALLENGE_MODE_START" then
        -- Mythic+ run begins (timer at 0) -> additional message possible
        local mapID = ...
        -- Reset flags for new run
        PM.endPosted = false
        -- Only post if no message was sent yet
        if not PM.startPosted then
            local msgs = PM.profile.startMessages
            if msgs and #msgs > 0 then
                local msg = msgs[math.random(#msgs)]
                local channel = PM.profile.useInstanceChat and "INSTANCE_CHAT" or "PARTY"
                C_ChatInfo.SendChatMessage(msg, channel)
                PM.startPosted = true
                print("|cff00ff00PartyMotivator|r - Mythic+ run started! Motivational message sent.")
            end
        else
            print("|cff00ff00PartyMotivator|r - Mythic+ run started! (Message already sent)")
        end
        
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        -- Mythic+ run completed -> reset flags
        PM.startPosted = false
        PM.endPosted = false
        print("|cff00ff00PartyMotivator|r - Mythic+ run completed! Flags reset.")
    end
end

-- Registriere die Events
PM:RegisterEvent("ADDON_LOADED")
PM:RegisterEvent("PLAYER_ENTERING_WORLD")
PM:RegisterEvent("GROUP_ROSTER_UPDATE")
PM:RegisterEvent("START_TIMER")
PM:RegisterEvent("CHALLENGE_MODE_START")
PM:RegisterEvent("CHALLENGE_MODE_COMPLETED")

-- Setze den Event-Handler
PM:SetScript("OnEvent", onEvent)

--[[
    Initializes the options panel for the interface menu (for compatibility)
]]
function PM:InitializeOptions()
    -- Create the beautiful UI
    PartyMotivatorUI:Initialize()
    
    -- Also create the standard panel for compatibility
    self.optionsPanel = CreateFrame("Frame")
    self.optionsPanel.name = "PartyMotivator"
    
    -- Create content for the options panel
    local title = self.optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("|cff00ff88Party|r|cffff6600Motivator|r |cff888888v1.3.0|r |cff666666by xMethface|r")
    title:SetTextColor(1, 1, 1)
    
    -- Description
    local description = self.optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    description:SetPoint("TOPLEFT", 20, -50)
    description:SetText("Sends motivational messages at dungeon start and greets new group members.\nExtended with Mythic+ completion messages, holiday messages and profile management.")
    description:SetTextColor(0.9, 0.9, 0.9)
    description:SetJustifyH("LEFT")
    description:SetWidth(650)
    
    -- Open UI button
    local openUIButton = CreateFrame("Button", nil, self.optionsPanel, "UIPanelButtonTemplate")
    openUIButton:SetSize(150, 30)
    openUIButton:SetPoint("TOPLEFT", 20, -100)
    openUIButton:SetText("Open Configuration UI")
    openUIButton:SetScript("OnClick", function()
        if PartyMotivatorUI and PartyMotivatorUI.ShowUI then
            PartyMotivatorUI:ShowUI()
        else
            print("|cffff0000PartyMotivator|r - UI could not be loaded!")
        end
    end)
    
    -- Chat commands info
    local commandsTitle = self.optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    commandsTitle:SetPoint("TOPLEFT", 20, -150)
    commandsTitle:SetText("Available Commands")
    commandsTitle:SetTextColor(1, 0.8, 0)
    
    -- Basic Commands
    local basicCommandsLabel = self.optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    basicCommandsLabel:SetPoint("TOPLEFT", 20, -175)
    basicCommandsLabel:SetText("Basic Commands:")
    basicCommandsLabel:SetTextColor(1, 1, 0.8)
    
    local basicCommandsText = self.optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    basicCommandsText:SetPoint("TOPLEFT", 20, -195)
    basicCommandsText:SetText("/pm - Show all available commands\n/pmui - Open the configuration UI\n/pmoptions - Open this options panel\n/pm list - Display all current messages and settings\n/pm chat - Toggle between INSTANCE_CHAT and PARTY channel\n/pm reset - Reset all messages to default values\n/pm resetpos - Reset UI window position to center")
    basicCommandsText:SetTextColor(0.9, 0.9, 0.9)
    basicCommandsText:SetJustifyH("LEFT")
    basicCommandsText:SetWidth(650)
    
    -- Message Management Commands
    local messageCommandsLabel = self.optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    messageCommandsLabel:SetPoint("TOPLEFT", 20, -315)
    messageCommandsLabel:SetText("Message Management:")
    messageCommandsLabel:SetTextColor(1, 1, 0.8)
    
    local messageCommandsText = self.optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    messageCommandsText:SetPoint("TOPLEFT", 20, -335)
    messageCommandsText:SetText("/pm add <message> - Add a new start message\n/pm remove <number> - Remove a start message by number\n/pm greet add <message> - Add a new greeting message\n/pm greet remove <number> - Remove a greeting by number\n/pm mythic success <message> - Add a Mythic+ success message\n/pm mythic failure <message> - Add a Mythic+ failure message")
    messageCommandsText:SetTextColor(0.9, 0.9, 0.9)
    messageCommandsText:SetJustifyH("LEFT")
    messageCommandsText:SetWidth(650)
    
    -- Profile Management Commands
    local profileCommandsLabel = self.optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileCommandsLabel:SetPoint("TOPLEFT", 20, -455)
    profileCommandsLabel:SetText("Profile Management:")
    profileCommandsLabel:SetTextColor(1, 1, 0.8)
    
    local profileCommandsText = self.optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileCommandsText:SetPoint("TOPLEFT", 20, -475)
    profileCommandsText:SetText("/pm profile save <name> - Save current settings as a profile\n/pm profile load <name> - Load a saved profile\n/pm profile delete <name> - Delete a profile\n/pm profile list - List all available profiles\n/pm profile export <name> - Export a profile as text string\n/pm profile import <name> <data> - Import a profile from text string")
    profileCommandsText:SetTextColor(0.9, 0.9, 0.9)
    profileCommandsText:SetJustifyH("LEFT")
    profileCommandsText:SetWidth(650)
    
    -- Register panel with new Settings API
    local category = Settings.RegisterCanvasLayoutCategory(self.optionsPanel, self.optionsPanel.name)
    category.ID = self.optionsPanel.name
    Settings.RegisterAddOnCategory(category)
    self.settingsCategory = category
end

-- Registriere die Slash-Commands
SLASH_PARTYMOTIVATOR1 = "/pm"
SlashCmdList["PARTYMOTIVATOR"] = handleSlashCommand

SLASH_PMOPTIONS1 = "/pmoptions"
SlashCmdList["PMOPTIONS"] = function()
    if PartyMotivatorUI and PartyMotivatorUI.ShowUI then
        -- Open the beautiful custom UI
        PartyMotivatorUI:ShowUI()
    elseif PM.optionsPanel and PM.optionsPanel.name then
        -- Fallback: Open the standard panel
        Settings.OpenToCategory(PM.optionsPanel.name)
    else
        print("|cffff0000PartyMotivator|r - UI could not be loaded!")
    end
end

-- Additional slash command for the beautiful UI
SLASH_PARTYMOTIVATORUI1 = "/pmui"
SlashCmdList["PARTYMOTIVATORUI"] = function()
    if PartyMotivatorUI and PartyMotivatorUI.ShowUI then
        PartyMotivatorUI:ShowUI()
    else
        print("|cffff0000PartyMotivator|r - UI could not be loaded!")
    end
end

--[[
    Addon Compartment Callback Functions
    These functions are called by the Addon Compartment system
]]

--[[
    Called when the addon compartment button is clicked
]]
function PartyMotivator_OnAddonCompartmentClick(addonName, button)
    if PartyMotivatorUI and PartyMotivatorUI.Toggle then
        PartyMotivatorUI:Toggle()
    elseif PartyMotivatorUI and PartyMotivatorUI.ShowUI then
        PartyMotivatorUI:ShowUI()
    end
end

--[[
    Called when the mouse enters the addon compartment button
]]
function PartyMotivator_OnAddonCompartmentEnter(addonName, button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:AddLine("PartyMotivator")
    GameTooltip:AddLine("Click to toggle UI", 1,1,1)
    GameTooltip:Show()
end

--[[
    Called when the mouse leaves the addon compartment button
]]
function PartyMotivator_OnAddonCompartmentLeave(addonName, button)
    GameTooltip:Hide()
end

--[[
    EVENT EXPLANATIONS:
    
    ADDON_LOADED: Fired when an addon is fully loaded.
    Here we initialize the database, options panel and show a confirmation.
    
    PLAYER_ENTERING_WORLD: Fired when the player enters the world
    or a new zone/instance. Here we check if we are in a
    5-player dungeon and use GetInstanceInfo() to determine the difficulty ID.
    Only for Normal (ID 1) and Heroic (ID 2) we send an immediate
    motivational message. For Mythic (ID 23) and Mythic+ (ID 8) we wait for
    the countdown, as both are recognized as ID 23 when entering.
    
    GROUP_ROSTER_UPDATE: Fired when the group composition changes
    (players join or leave the group). Here we greet
    new members and update the group size.
    
    START_TIMER: Fired when a timer starts (since patch 11.0.2).
    Here we check if it's the Mythic+ countdown
    (Enum.StartTimerType.ChallengeModeCountdown) and send a motivational
    message exactly when the 10-second countdown begins.
    
    CHALLENGE_MODE_START: Fired when a Mythic+ run begins
    (timer runs to 0). Here we send an additional motivational message
    for the actual start of the Mythic+ run.
    
    CHALLENGE_MODE_COMPLETED: Fired when a Mythic+ run is completed.
    Here we reset the startPosted flag so that the next run can
    post correctly again.
    
    SLASH-COMMANDS:
    /pm - Shows all available chat commands
    /pmoptions - Opens the options panel in the interface menu
    /pmui - Opens the beautiful custom UI
]]
