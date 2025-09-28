--[[
    PartyMotivatorUI - World of Warcraft Addon
    Beautiful UI for PartyMotivator configuration
    Provides an intuitive interface for managing messages and settings
]]

-- Create the UI namespace
PartyMotivatorUI = {}

-- Default database for fallback display
local defaultDB = {
    startMessages = {
        "We've got this.",
        "One pull, one win.",
        "Strong start, stronger finish.",
        "Calm and clean.",
        "Play our game.",
        "Focus up—deliver.",
        "Do the basics right.",
        "Discipline > rush.",
        "Good habits, good timer.",
        "Trust the plan.",
        "Keep it steady.",
        "We finish strong.",
        "Reset and execute.",
        "Confidence + control.",
        "Clean play beats speed.",
        "Sharp minds, sharp pulls.",
        "Win the minute you're in.",
        "Small edges, big result.",
        "Mechanics first, success follows.",
        "Pressure makes diamonds.",
        "Eyes forward—next pack.",
        "We build momentum.",
        "Stay composed, play precise.",
        "Quality over chaos.",
        "Believe and execute.",
        "Own the pace.",
        "Strong comms, strong run.",
        "Do your job, trust the team.",
        "Consistency wins keys.",
        "We rise now.",
        "Let's make future-us proud.",
        "Timer looks nervous already.",
        "Mechanics are free—let's take them.",
        "Loot likes tidy players.",
        "Swirlies fear discipline.",
        "Kick now, thank yourself later.",
        "We brought skill—key is optional.",
        "Clean play = free rating.",
        "Floor DPS is zero—so we fly.",
        "Smile, then delete packs."
    },
    greetMessages = {
        "Hello.",
        "Hello—GLHF.",
        "Hello, GLHF.",
        "Hi.",
        "Hey.",
        "Yo.",
        "Sup.",
        "Greetings.",
        "Welcome.",
        "Hi team.",
        "Hey team.",
        "Hello team.",
        "Hi all.",
        "Hey all.",
        "GLHF.",
        "Good luck.",
        "Have fun.",
        "Let's go.",
        "Ready?",
        "Welcome aboard.",
        "o/"
    },
    useInstanceChat = false,
    mythicPlusMessages = {
        success = {
            "GG! We timed it and upgraded the key.",
            "Clean run! Key upgraded!",
            "Perfect timing! Well done team!",
            "Key upgraded! Great job everyone!",
            "Timed it! Excellent work!",
            "Success! Key level up!",
            "Flawless execution! Key upgraded!",
            "Team work makes the dream work! Key up!",
            "Smooth run! Key upgraded!",
            "Outstanding! Key level increased!"
        },
        failure = {
            "Thanks for the key! We'll get it next time.",
            "Good try! Next time we'll time it.",
            "Close one! We'll nail it next run.",
            "Thanks for the key! Practice makes perfect.",
            "Good effort! We'll get it next time.",
            "Thanks for the key! We're getting better.",
            "Nice try! Next run will be the one.",
            "Thanks for the key! We'll improve next time.",
            "Good attempt! We'll time it next run.",
            "Thanks for the key! We'll do better next time."
        }
    }
}

-- UI state variables
PartyMotivatorUI.isVisible = false
PartyMotivatorUI.mainFrame = nil
PartyMotivatorUI._initialized = false

--[[
    Checks if the main addon is loaded and ready
]]
function PartyMotivatorUI:IsAddonReady()
    return PM and PM.addonReady and PM.profile and PartyMotivatorDB and PartyMotivatorDB.profiles
end

--[[
    Ensures that mythic+ messages are properly structured as string arrays
]]
local function ensureMythicPlusTables()
    if not PM or not PM.profile then return end
    
    if not PM.profile.mythicPlusMessages then
        PM.profile.mythicPlusMessages = {success = {}, failure = {}}
    end
    
    if not PM.profile.mythicPlusMessages.success or type(PM.profile.mythicPlusMessages.success) ~= "table" then
        PM.profile.mythicPlusMessages.success = {}
    end
    
    if not PM.profile.mythicPlusMessages.failure or type(PM.profile.mythicPlusMessages.failure) ~= "table" then
        PM.profile.mythicPlusMessages.failure = {}
    end
    
    -- Ensure all items are strings and flatten nested structures
    local function ensureStringArray(arr)
        local result = {}
        for i, item in ipairs(arr) do
            if type(item) == "string" then
                table.insert(result, item)
            elseif type(item) == "table" then
                -- Flatten nested tables recursively
                local flattened = ensureStringArray(item)
                for _, subItem in ipairs(flattened) do
                    table.insert(result, subItem)
                end
            else
                -- Convert non-string, non-table items to strings
                table.insert(result, tostring(item))
            end
        end
        return result
    end
    
    PM.profile.mythicPlusMessages.success = ensureStringArray(PM.profile.mythicPlusMessages.success)
    PM.profile.mythicPlusMessages.failure = ensureStringArray(PM.profile.mythicPlusMessages.failure)
end

--[[
    Initializes default mythic+ messages if they don't exist
]]
local function initializeDefaultMythicPlusMessages()
    if not PM or not PM.profile then return end
    
    -- Ensure structure exists
    ensureMythicPlusTables()
    
    -- Initialize success messages if empty
    if #PM.profile.mythicPlusMessages.success == 0 then
        PM.profile.mythicPlusMessages.success = {
            "GG! We timed it and upgraded the key.",
            "Clean run! Key upgraded!",
            "Perfect timing! Well done team!",
            "Key upgraded! Great job everyone!",
            "Timed it! Excellent work!",
            "Success! Key level up!",
            "Flawless execution! Key upgraded!",
            "Team work makes the dream work! Key up!",
            "Smooth run! Key upgraded!",
            "Outstanding! Key level increased!"
        }
    end
    
    -- Initialize failure messages if empty
    if #PM.profile.mythicPlusMessages.failure == 0 then
        PM.profile.mythicPlusMessages.failure = {
            "Thanks for the key! We'll get it next time.",
            "Good try! Next time we'll time it.",
            "Close one! We'll nail it next run.",
            "Thanks for the key! Practice makes perfect.",
            "Good effort! We'll get it next time.",
            "Thanks for the key! We're getting better.",
            "Nice try! Next run will be the one.",
            "Thanks for the key! We'll improve next time.",
            "Good attempt! We'll time it next run.",
            "Thanks for the key! We'll do better next time."
        }
    end
end

--[[
    Initializes the beautiful UI
    Creates all UI elements and sets up the interface
]]
function PartyMotivatorUI:Initialize()
    -- Only initialize if not already done
    if self._initialized then
        return
    end
    
    -- Only initialize if addon is ready
    if not self:IsAddonReady() then
        return
    end
    
    -- Create main frame
    self:CreateMainFrame()
    -- Create tabs
    self:CreateTabs()
    -- Create content panels
    self:CreateContentPanels()
    -- Set up event handlers
    self:SetupEventHandlers()
    
    -- Mark as initialized
    self._initialized = true
end

--[[
    Creates the main UI frame
]]
function PartyMotivatorUI:CreateMainFrame()
    -- Create main frame (larger for better space utilization)
    self.mainFrame = CreateFrame("Frame", "PartyMotivatorUIMainFrame", UIParent, "BasicFrameTemplateWithInset")
    self.mainFrame:SetSize(850, 700) -- Much larger for better content visibility
    self.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    self.mainFrame:SetMovable(true)
    self.mainFrame:EnableMouse(true)
    self.mainFrame:RegisterForDrag("LeftButton")
    self.mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    self.mainFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    self.mainFrame:SetToplevel(true)
    self.mainFrame:SetFrameStrata("HIGH")
    self.mainFrame:SetClampedToScreen(true)
    
    -- Enable keyboard and propagate input to game (allows WASD movement)
    if self.mainFrame.SetPropagateKeyboardInput then
        self.mainFrame:EnableKeyboard(true)
        self.mainFrame:SetPropagateKeyboardInput(true) -- allows movement keys to pass through
    end
    
    self.mainFrame:Hide()
    
    -- Set title
    self.mainFrame.title = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.mainFrame.title:SetPoint("TOP", 0, -10)
    self.mainFrame.title:SetText("|cff00ff88Party|r|cffff6600Motivator|r |cff888888v1.3.0|r |cff666666by xMethface|r")
    
    -- Use the built-in close button from BasicFrameTemplateWithInset
    -- The template already provides a close button, we just need to hook it up
    if self.mainFrame.CloseButton then
        self.mainFrame.CloseButton:SetScript("OnClick", function() PartyMotivatorUI:HideUI() end)
    end
end

--[[
    Creates the tab system with scrolling support
]]
function PartyMotivatorUI:CreateTabs()
    self.tabContainer = CreateFrame("Frame", nil, self.mainFrame)
    self.tabContainer:SetPoint("TOPLEFT", 10, -40)
    self.tabContainer:SetPoint("TOPRIGHT", -50, -40) -- Leave space for scroll buttons
    self.tabContainer:SetHeight(35)
    
    -- Create scroll frame for tabs
    self.tabScrollFrame = CreateFrame("ScrollFrame", nil, self.tabContainer)
    self.tabScrollFrame:SetAllPoints()
    self.tabScrollFrame:SetClipsChildren(true)
    
    -- Create content frame for tabs
    self.tabContentFrame = CreateFrame("Frame", nil, self.tabScrollFrame)
    self.tabScrollFrame:SetScrollChild(self.tabContentFrame)
    
    -- Create scroll buttons
    local leftButton = CreateFrame("Button", nil, self.mainFrame, "UIPanelButtonTemplate")
    leftButton:SetSize(20, 25)
    leftButton:SetPoint("TOPLEFT", self.tabContainer, "TOPRIGHT", 5, 0)
    leftButton:SetText("<")
    leftButton:SetScript("OnClick", function()
        local current = self.tabScrollFrame:GetHorizontalScroll()
        self.tabScrollFrame:SetHorizontalScroll(math.max(0, current - 100))
    end)
    
    local rightButton = CreateFrame("Button", nil, self.mainFrame, "UIPanelButtonTemplate")
    rightButton:SetSize(20, 25)
    rightButton:SetPoint("LEFT", leftButton, "RIGHT", 5, 0)
    rightButton:SetText(">")
    rightButton:SetScript("OnClick", function()
        local current = self.tabScrollFrame:GetHorizontalScroll()
        local maxScroll = math.max(0, self.tabContentFrame:GetWidth() - self.tabScrollFrame:GetWidth())
        self.tabScrollFrame:SetHorizontalScroll(math.min(maxScroll, current + 100))
    end)
    
    self.tabScrollLeft = leftButton
    self.tabScrollRight = rightButton

    self.tabs = {}
    local tabNames = {"Start Messages", "Greetings", "Mythic+", "Holidays", "Profiles", "Settings"}

    for i, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", nil, self.tabContentFrame, "UIPanelButtonTemplate")
        tab:SetText(name)
        tab:SetScript("OnClick", function() self:SwitchTab(i) end)
        tab:SetNormalFontObject("GameFontNormalSmall")
        tab:SetHighlightFontObject("GameFontHighlightSmall")
        self.tabs[i] = tab
    end

    self.activeTab = 1
    self:UpdateTabAppearance()

    -- Relayout when sizes change
    self.tabContainer:SetScript("OnSizeChanged", function() self:LayoutTabs() end)
    self.mainFrame:SetScript("OnSizeChanged", function() self:LayoutTabs() end)

    self:LayoutTabs()
end

--[[
    Responsive tab layout with wrapping
]]
do
    local TAB_H     = 26
    local TAB_GAP   = 6
    local PAD_X     = 12    -- text padding per side
    local MIN_W     = 90
    local MAX_W     = 140

    function PartyMotivatorUI:CalcTabWidth(tab)
        local fs = tab:GetFontString()
        local w  = fs and fs:GetStringWidth() or 80  -- FontString width of label
        return math.min(MAX_W, math.max(MIN_W, math.floor(w + PAD_X * 2)))
    end

    function PartyMotivatorUI:LayoutTabs()
        if not self.tabs or not self.tabContentFrame then return end

        local x = 0
        local rowH = TAB_H
        local prev

        -- Layout tabs in a single horizontal row for scrolling
        for i, tab in ipairs(self.tabs) do
            tab:ClearAllPoints()
            local w = self:CalcTabWidth(tab)
            tab:SetSize(w, rowH)

            if prev == nil then
                -- first tab
                tab:SetPoint("TOPLEFT", self.tabContentFrame, "TOPLEFT", 0, 0)
                x = w
            else
                tab:SetPoint("LEFT", prev, "RIGHT", TAB_GAP, 0)
                x = x + TAB_GAP + w
            end
            prev = tab
        end

        -- Set the content frame size to enable scrolling
        self.tabContentFrame:SetSize(x, rowH)
        
        -- Update scroll button visibility
        local needsScroll = x > (self.tabScrollFrame:GetWidth() or 0)
        if self.tabScrollLeft and self.tabScrollRight then
            if needsScroll then
                self.tabScrollLeft:Show()
                self.tabScrollRight:Show()
            else
                self.tabScrollLeft:Hide()
                self.tabScrollRight:Hide()
            end
        end

        -- keep content area directly under the tabs
        if self.contentArea then
            self.contentArea:ClearAllPoints()
            self.contentArea:SetPoint("TOPLEFT",  self.tabContainer, "BOTTOMLEFT", 0, -10)
            self.contentArea:SetPoint("BOTTOMRIGHT", self.mainFrame, "BOTTOMRIGHT", -10, 10)
        end
    end
end

--[[
    Creates the content panels for each tab
]]
function PartyMotivatorUI:CreateContentPanels()
    -- Content area
    self.contentArea = CreateFrame("Frame", nil, self.mainFrame)
    self.contentArea:SetPoint("TOPLEFT",  self.tabContainer, "BOTTOMLEFT", 0, -10)
    self.contentArea:SetPoint("BOTTOMRIGHT", self.mainFrame, "BOTTOMRIGHT", -10, 10)
    
    -- Create panels for each tab
    self.panels = {}
    
    -- Start Messages panel
    self.panels[1] = self:CreateStartMessagesPanel()
    
    -- Greetings panel
    self.panels[2] = self:CreateGreetingsPanel()
    
    -- Mythic+ panel
    self.panels[3] = self:CreateMythicPlusPanel()
    
    -- Holidays panel
    self.panels[4] = self:CreateHolidaysPanel()
    
    -- Profiles panel  
    self.panels[5] = self:CreateProfilesPanel()
    
    -- Settings panel
    self.panels[6] = self:CreateSettingsPanel()
    
    -- Show first panel
    self:ShowPanel(1)
end

--[[
    Creates the start messages panel
]]
function PartyMotivatorUI:CreateStartMessagesPanel()
    local panel = CreateFrame("Frame", nil, self.contentArea)
    panel:SetAllPoints()
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("|cff00ff00Start Messages|r")
    
    -- Add message section
    local addFrame = CreateFrame("Frame", nil, panel)
    addFrame:SetPoint("TOPLEFT", 10, -40)
    addFrame:SetPoint("TOPRIGHT", -10, -40)
    addFrame:SetHeight(40)
    
    local addLabel = addFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addLabel:SetPoint("LEFT", 0, 0)
    addLabel:SetText("Add new message:")
    
    local addEditBox = CreateFrame("EditBox", nil, addFrame, "InputBoxTemplate")
    addEditBox:SetPoint("LEFT", addLabel, "RIGHT", 10, 0)
    addEditBox:SetPoint("RIGHT", -100, 0)
    addEditBox:SetHeight(20)
    addEditBox:SetAutoFocus(false) -- Prevent automatic focus
    
    local addButton = CreateFrame("Button", nil, addFrame, "UIPanelButtonTemplate")
    addButton:SetSize(80, 25)
    addButton:SetPoint("RIGHT", 0, 0)
    addButton:SetText("Add")
    addButton:SetScript("OnClick", function()
        local text = addEditBox:GetText()
        if text and text ~= "" then
            if self:IsAddonReady() then
                if not PM.profile.startMessages then
                    PM.profile.startMessages = {}
                end
                table.insert(PM.profile.startMessages, text)
                addEditBox:SetText("")
                self:RefreshStartMessagesList()
                print("|cff00ff00PartyMotivator|r - Message added: " .. text)
            else
                print("|cffff0000PartyMotivator|r - Addon not ready! Please wait a moment and try again.")
                print("|cffffffffPartyMotivator|r - You can also use /pm add " .. text .. " in chat.")
            end
        end
    end)
    
    -- Messages list
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth() - 20, 0)
    scrollFrame:SetScrollChild(content)
    
    panel.scrollFrame = scrollFrame
    panel.content = content
    panel.addEditBox = addEditBox
    
    return panel
end

--[[
    Creates the greetings panel
]]
function PartyMotivatorUI:CreateGreetingsPanel()
    local panel = CreateFrame("Frame", nil, self.contentArea)
    panel:SetAllPoints()
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("|cff00ff00Greetings|r")
    
    -- Add greeting section
    local addFrame = CreateFrame("Frame", nil, panel)
    addFrame:SetPoint("TOPLEFT", 10, -40)
    addFrame:SetPoint("TOPRIGHT", -10, -40)
    addFrame:SetHeight(40)
    
    local addLabel = addFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addLabel:SetPoint("LEFT", 0, 0)
    addLabel:SetText("Add new greeting:")
    
    local addEditBox = CreateFrame("EditBox", nil, addFrame, "InputBoxTemplate")
    addEditBox:SetPoint("LEFT", addLabel, "RIGHT", 10, 0)
    addEditBox:SetPoint("RIGHT", -100, 0)
    addEditBox:SetHeight(20)
    addEditBox:SetAutoFocus(false) -- Prevent automatic focus
    
    local addButton = CreateFrame("Button", nil, addFrame, "UIPanelButtonTemplate")
    addButton:SetSize(80, 25)
    addButton:SetPoint("RIGHT", 0, 0)
    addButton:SetText("Add")
    addButton:SetScript("OnClick", function()
        local text = addEditBox:GetText()
        if text and text ~= "" then
            if self:IsAddonReady() then
                if not PM.profile.greetMessages then
                    PM.profile.greetMessages = {}
                end
                table.insert(PM.profile.greetMessages, text)
                addEditBox:SetText("")
                self:RefreshGreetingsList()
                print("|cff00ff00PartyMotivator|r - Greeting added: " .. text)
            else
                print("|cffff0000PartyMotivator|r - Addon not ready! Please wait a moment and try again.")
                print("|cffffffffPartyMotivator|r - You can also use /pm greet add " .. text .. " in chat.")
            end
        end
    end)
    
    -- Greetings list
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth() - 20, 0)
    scrollFrame:SetScrollChild(content)
    
    panel.scrollFrame = scrollFrame
    panel.content = content
    panel.addEditBox = addEditBox
    
    return panel
end

--[[
    Creates the Mythic+ panel
]]
function PartyMotivatorUI:CreateMythicPlusPanel()
    local panel = CreateFrame("Frame", nil, self.contentArea)
    panel:SetAllPoints()
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("|cff9966ffMythic+ Messages|r")
    
    -- Create sub-tabs for Success and Failure
    local successTab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    successTab:SetSize(120, 30)
    successTab:SetPoint("TOPLEFT", 10, -40)
    successTab:SetText("Success Messages")
    successTab:SetScript("OnClick", function()
        self:ShowMythicPlusSubTab("success")
    end)
    
    local failureTab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    failureTab:SetSize(120, 30)
    failureTab:SetPoint("LEFT", successTab, "RIGHT", 10, 0)
    failureTab:SetText("Failure Messages")
    failureTab:SetScript("OnClick", function()
        self:ShowMythicPlusSubTab("failure")
    end)
    
    -- Content area for the sub-tabs
    local contentArea = CreateFrame("Frame", nil, panel)
    contentArea:SetPoint("TOPLEFT", 10, -80)
    contentArea:SetPoint("BOTTOMRIGHT", -10, 10)
    
    -- Success Messages Panel
    local successPanel = CreateFrame("Frame", nil, contentArea)
    successPanel:SetAllPoints()
    successPanel:Hide()
    
    local successTitle = successPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    successTitle:SetPoint("TOPLEFT", 0, 0)
    successTitle:SetText("|cff00ff00Success Messages|r")
    
    -- Add success message section
    local addSuccessFrame = CreateFrame("Frame", nil, successPanel)
    addSuccessFrame:SetPoint("TOPLEFT", 0, -30)
    addSuccessFrame:SetPoint("TOPRIGHT", 0, -30)
    addSuccessFrame:SetHeight(40)
    
    local addSuccessLabel = addSuccessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addSuccessLabel:SetPoint("LEFT", 0, 0)
    addSuccessLabel:SetText("Add success:")
    
    local addSuccessEditBox = CreateFrame("EditBox", nil, addSuccessFrame, "InputBoxTemplate")
    addSuccessEditBox:SetPoint("LEFT", addSuccessLabel, "RIGHT", 10, 0)
    addSuccessEditBox:SetPoint("RIGHT", -80, 0)
    addSuccessEditBox:SetHeight(20)
    addSuccessEditBox:SetAutoFocus(false)
    
    local addSuccessButton = CreateFrame("Button", nil, addSuccessFrame, "UIPanelButtonTemplate")
    addSuccessButton:SetSize(60, 25)
    addSuccessButton:SetPoint("RIGHT", 0, 0)
    addSuccessButton:SetText("Add")
    addSuccessButton:SetScript("OnClick", function()
        local text = addSuccessEditBox:GetText()
        if text and text ~= "" then
            if self:IsAddonReady() then
                ensureMythicPlusTables()
                table.insert(PM.profile.mythicPlusMessages.success, text)
                addSuccessEditBox:SetText("")
                self:RefreshMythicPlusSuccessList()
                print("|cff00ff00PartyMotivator|r - Success message added: " .. text)
            else
                print("|cffff0000PartyMotivator|r - Addon not ready! Please wait a moment and try again.")
            end
        end
    end)
    
    -- Success messages list
    local successScrollFrame = CreateFrame("ScrollFrame", nil, successPanel, "UIPanelScrollFrameTemplate")
    successScrollFrame:SetPoint("TOPLEFT", 0, -80)
    successScrollFrame:SetPoint("BOTTOMRIGHT", 0, 0)
    
    local successContent = CreateFrame("Frame", nil, successScrollFrame)
    successContent:SetSize(successScrollFrame:GetWidth() - 20, 0)
    successScrollFrame:SetScrollChild(successContent)
    
    -- Failure Messages Panel
    local failurePanel = CreateFrame("Frame", nil, contentArea)
    failurePanel:SetAllPoints()
    failurePanel:Hide()
    
    local failureTitle = failurePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    failureTitle:SetPoint("TOPLEFT", 0, 0)
    failureTitle:SetText("|cffff6600Failure Messages|r")
    
    -- Add failure message section
    local addFailureFrame = CreateFrame("Frame", nil, failurePanel)
    addFailureFrame:SetPoint("TOPLEFT", 0, -30)
    addFailureFrame:SetPoint("TOPRIGHT", 0, -30)
    addFailureFrame:SetHeight(40)
    
    local addFailureLabel = addFailureFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addFailureLabel:SetPoint("LEFT", 0, 0)
    addFailureLabel:SetText("Add failure:")
    
    local addFailureEditBox = CreateFrame("EditBox", nil, addFailureFrame, "InputBoxTemplate")
    addFailureEditBox:SetPoint("LEFT", addFailureLabel, "RIGHT", 10, 0)
    addFailureEditBox:SetPoint("RIGHT", -80, 0)
    addFailureEditBox:SetHeight(20)
    addFailureEditBox:SetAutoFocus(false)
    
    local addFailureButton = CreateFrame("Button", nil, addFailureFrame, "UIPanelButtonTemplate")
    addFailureButton:SetSize(60, 25)
    addFailureButton:SetPoint("RIGHT", 0, 0)
    addFailureButton:SetText("Add")
    addFailureButton:SetScript("OnClick", function()
        local text = addFailureEditBox:GetText()
        if text and text ~= "" then
            if self:IsAddonReady() then
                ensureMythicPlusTables()
                table.insert(PM.profile.mythicPlusMessages.failure, text)
                addFailureEditBox:SetText("")
                self:RefreshMythicPlusFailureList()
                print("|cff00ff00PartyMotivator|r - Failure message added: " .. text)
            else
                print("|cffff0000PartyMotivator|r - Addon not ready! Please wait a moment and try again.")
            end
        end
    end)
    
    -- Failure messages list
    local failureScrollFrame = CreateFrame("ScrollFrame", nil, failurePanel, "UIPanelScrollFrameTemplate")
    failureScrollFrame:SetPoint("TOPLEFT", 0, -80)
    failureScrollFrame:SetPoint("BOTTOMRIGHT", 0, 0)
    
    local failureContent = CreateFrame("Frame", nil, failureScrollFrame)
    failureContent:SetSize(failureScrollFrame:GetWidth() - 20, 0)
    failureScrollFrame:SetScrollChild(failureContent)
    
    -- Store references for refreshing
    panel.successTab = successTab
    panel.failureTab = failureTab
    panel.successPanel = successPanel
    panel.failurePanel = failurePanel
    panel.successScrollFrame = successScrollFrame
    panel.successContent = successContent
    panel.addSuccessEditBox = addSuccessEditBox
    panel.failureScrollFrame = failureScrollFrame
    panel.failureContent = failureContent
    panel.addFailureEditBox = addFailureEditBox
    panel.currentSubTab = "success" -- Default to success tab
    
    return panel
end

--[[
    Creates the holidays panel
]]
function PartyMotivatorUI:CreateHolidaysPanel()
    local panel = CreateFrame("Frame", nil, self.contentArea)
    panel:SetAllPoints()
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("|cff00ccffHoliday Messages|r")
    
    -- Holiday system check
    if not PartyMotivatorHolidays then
        local noHolidayText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noHolidayText:SetPoint("TOPLEFT", 10, -40)
        noHolidayText:SetText("|cffff0000Holiday system not loaded!|r")
        return panel
    end
    
    -- Settings section
    local settingsFrame = CreateFrame("Frame", nil, panel)
    settingsFrame:SetPoint("TOPLEFT", 10, -40)
    settingsFrame:SetPoint("TOPRIGHT", -10, -40)
    settingsFrame:SetHeight(80)
    
    -- Master checkbox
    local cbEnable = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    cbEnable:SetPoint("TOPLEFT", 0, 0)
    cbEnable.text:SetText("Enable holiday messages")
    cbEnable:SetChecked( (PM.profile.holidays and PM.profile.holidays.enabled) ~= false )
    cbEnable:SetScript("OnClick", function(self)
        if PartyMotivatorUI:IsAddonReady() then
            PM.profile.holidays = PM.profile.holidays or {}
            PM.profile.holidays.enabled = self:GetChecked()
        end
    end)

    -- Region checkboxes (second row to avoid overlap)
    local lblRegion = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lblRegion:SetPoint("TOPLEFT", 0, -25)
    lblRegion:SetText("Active regions:")

    local function makeRegionCB(anchor, text, key, dx, dy)
        local cb = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
        cb:SetPoint("LEFT", anchor, "RIGHT", dx or 6, dy or 0)
        cb.text:SetText(text)
        cb:SetChecked( not PM.profile.holidays or not PM.profile.holidays.regions or PM.profile.holidays.regions[key] ~= false )
        cb:SetScript("OnClick", function(self)
            if PartyMotivatorUI:IsAddonReady() then
                PM.profile.holidays = PM.profile.holidays or {}
                PM.profile.holidays.regions = PM.profile.holidays.regions or { US=true, EU=true, ASIA=true }
                PM.profile.holidays.regions[key] = self:GetChecked()
                -- Update holiday tab visibility based on new region settings
                PartyMotivatorUI:UpdateHolidayTabVisibility()
            end
        end)
        return cb
    end
    local cbUS   = makeRegionCB(lblRegion, "US",   "US",   10)
    local cbEU   = makeRegionCB(cbUS,      "EU",   "EU",   10)
    local cbASIA = makeRegionCB(cbEU,      "ASIA", "ASIA", 10)
    
    -- Create sub-tabs for different holidays (2 rows)
    local tabWidth = 90
    local tabHeight = 25
    local tabGap = 5
    
    -- First row
    local halloweenTab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    halloweenTab:SetSize(tabWidth, tabHeight)
    halloweenTab:SetPoint("TOPLEFT", 10, -130)
    halloweenTab:SetText("Halloween")
    halloweenTab:SetScript("OnClick", function() self:ShowHolidaySubTab("HALLOWEEN") end)
    
    local winterVeilTab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    winterVeilTab:SetSize(tabWidth, tabHeight)
    winterVeilTab:SetPoint("LEFT", halloweenTab, "RIGHT", tabGap, 0)
    winterVeilTab:SetText("Winter Veil")
    winterVeilTab:SetScript("OnClick", function() self:ShowHolidaySubTab("WINTER_VEIL") end)
    
    local loveTab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    loveTab:SetSize(tabWidth, tabHeight)
    loveTab:SetPoint("LEFT", winterVeilTab, "RIGHT", tabGap, 0)
    loveTab:SetText("Love/Valentine")
    loveTab:SetScript("OnClick", function() self:ShowHolidaySubTab("LOVE_IS_IN_THE_AIR") end)
    
    local brewfestTab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    brewfestTab:SetSize(tabWidth, tabHeight)
    brewfestTab:SetPoint("LEFT", loveTab, "RIGHT", tabGap, 0)
    brewfestTab:SetText("Brewfest")
    brewfestTab:SetScript("OnClick", function() self:ShowHolidaySubTab("BREWFEST") end)
    
    -- Second row
    local midsummerTab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    midsummerTab:SetSize(tabWidth, tabHeight)
    midsummerTab:SetPoint("TOPLEFT", halloweenTab, "BOTTOMLEFT", 0, -tabGap)
    midsummerTab:SetText("Midsummer")
    midsummerTab:SetScript("OnClick", function() self:ShowHolidaySubTab("MIDSUMMER") end)
    
    local harvestTab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    harvestTab:SetSize(tabWidth, tabHeight)
    harvestTab:SetPoint("LEFT", midsummerTab, "RIGHT", tabGap, 0)
    harvestTab:SetText("Harvest")
    harvestTab:SetScript("OnClick", function() self:ShowHolidaySubTab("HARVEST_FESTIVAL") end)
    
    local lunarTab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    lunarTab:SetSize(tabWidth, tabHeight)
    lunarTab:SetPoint("LEFT", harvestTab, "RIGHT", tabGap, 0)
    lunarTab:SetText("Lunar/NewYear")
    lunarTab:SetScript("OnClick", function() self:ShowHolidaySubTab("LUNAR_FESTIVAL") end)
    
    local noblegardenTab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    noblegardenTab:SetSize(tabWidth, tabHeight)
    noblegardenTab:SetPoint("LEFT", lunarTab, "RIGHT", tabGap, 0)
    noblegardenTab:SetText("Easter")
    noblegardenTab:SetScript("OnClick", function() self:ShowHolidaySubTab("NOBLEGARDEN") end)
    
    -- Content area for the sub-tabs (more space with larger window)
    local contentArea = CreateFrame("Frame", nil, panel)
    contentArea:SetPoint("TOPLEFT", 10, -190) -- Moved down to avoid overlap with sub-tabs
    contentArea:SetPoint("BOTTOMRIGHT", -10, 10)
    
    -- Create panels for all holidays
    local halloweenPanel = self:CreateHolidayMessagePanel(contentArea, "HALLOWEEN", "Halloween Messages", "|cffff6600")
    local winterVeilPanel = self:CreateHolidayMessagePanel(contentArea, "WINTER_VEIL", "Winter Veil Messages", "|cff00ccff")
    local lovePanel = self:CreateHolidayMessagePanel(contentArea, "LOVE_IS_IN_THE_AIR", "Love is in the Air", "|cffff69b4")
    local brewfestPanel = self:CreateHolidayMessagePanel(contentArea, "BREWFEST", "Brewfest Messages", "|cffdaa520")
    local midsummerPanel = self:CreateHolidayMessagePanel(contentArea, "MIDSUMMER", "Midsummer Fire Festival", "|cffff4500")
    local harvestPanel = self:CreateHolidayMessagePanel(contentArea, "HARVEST_FESTIVAL", "Harvest Festival", "|cffff8c00")
    local lunarPanel = self:CreateHolidayMessagePanel(contentArea, "LUNAR_FESTIVAL", "Lunar Festival", "|cffffd700")
    local noblegardenPanel = self:CreateHolidayMessagePanel(contentArea, "NOBLEGARDEN", "Noblegarden", "|cff98fb98")
    
    -- Store references for refreshing
    panel.cbEnable = cbEnable
    panel.cbUS = cbUS
    panel.cbEU = cbEU
    panel.cbASIA = cbASIA
    panel.tabs = {
        HALLOWEEN = halloweenTab,
        WINTER_VEIL = winterVeilTab,
        LOVE_IS_IN_THE_AIR = loveTab,
        BREWFEST = brewfestTab,
        MIDSUMMER = midsummerTab,
        HARVEST_FESTIVAL = harvestTab,
        LUNAR_FESTIVAL = lunarTab,
        NOBLEGARDEN = noblegardenTab
    }
    panel.panels = {
        HALLOWEEN = halloweenPanel,
        WINTER_VEIL = winterVeilPanel,
        LOVE_IS_IN_THE_AIR = lovePanel,
        BREWFEST = brewfestPanel,
        MIDSUMMER = midsummerPanel,
        HARVEST_FESTIVAL = harvestPanel,
        LUNAR_FESTIVAL = lunarPanel,
        NOBLEGARDEN = noblegardenPanel
    }
    panel.currentSubTab = "HALLOWEEN" -- Default to Halloween tab
    
    return panel
end

--[[
    Creates a holiday message panel for a specific holiday
]]
function PartyMotivatorUI:CreateHolidayMessagePanel(parent, holidayKey, title, titleColor)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    local panelTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panelTitle:SetPoint("TOPLEFT", 0, 0)
    panelTitle:SetText(titleColor .. title .. "|r")
    
    -- Enable checkbox for this specific holiday (moved down to avoid overlap)
    local enableCB = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    enableCB:SetPoint("TOPLEFT", 0, -25) -- Moved below the title
    enableCB.text:SetText("Enabled")
    enableCB:SetScript("OnClick", function(self)
        if PartyMotivatorUI:IsAddonReady() then
            PM.profile.holidays.events = PM.profile.holidays.events or {}
            PM.profile.holidays.events[holidayKey] = PM.profile.holidays.events[holidayKey] or { enabled=true, messages={} }
            PM.profile.holidays.events[holidayKey].enabled = self:GetChecked()
        end
    end)
    
    -- Add message section (moved further down to accommodate checkbox)
    local addFrame = CreateFrame("Frame", nil, panel)
    addFrame:SetPoint("TOPLEFT", 0, -55) -- Moved down from -30 to -55
    addFrame:SetPoint("TOPRIGHT", 0, -55)
    addFrame:SetHeight(40)
    
    local addLabel = addFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addLabel:SetPoint("LEFT", 0, 0)
    addLabel:SetText("Add new message:")
    
    local addEditBox = CreateFrame("EditBox", nil, addFrame, "InputBoxTemplate")
    addEditBox:SetPoint("LEFT", addLabel, "RIGHT", 10, 0)
    addEditBox:SetPoint("RIGHT", -100, 0)
    addEditBox:SetHeight(20)
    addEditBox:SetAutoFocus(false)
    
    local addButton = CreateFrame("Button", nil, addFrame, "UIPanelButtonTemplate")
    addButton:SetSize(80, 25)
    addButton:SetPoint("RIGHT", 0, 0)
    addButton:SetText("Add")
    addButton:SetScript("OnClick", function()
        local text = addEditBox:GetText()
        if text and text ~= "" then
            if self:IsAddonReady() then
                PM.profile.holidays.events = PM.profile.holidays.events or {}
                PM.profile.holidays.events[holidayKey] = PM.profile.holidays.events[holidayKey] or { enabled=true, messages={} }
                PM.profile.holidays.events[holidayKey].messages = PM.profile.holidays.events[holidayKey].messages or {}
                table.insert(PM.profile.holidays.events[holidayKey].messages, text)
                addEditBox:SetText("")
                self:RefreshHolidayMessagesList(holidayKey)
                print("|cff00ff00PartyMotivator|r - Holiday message added: " .. text)
            else
                print("|cffff0000PartyMotivator|r - Addon not ready! Please wait a moment and try again.")
            end
        end
    end)
    
    -- Messages list (larger scroll area for better visibility)
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, -105) -- Moved down from -80 to -105
    scrollFrame:SetPoint("BOTTOMRIGHT", -20, 0)
    
    -- Add scroll background for better visibility
    local scrollBg = scrollFrame:CreateTexture(nil, "BACKGROUND")
    scrollBg:SetAllPoints(scrollFrame)
    scrollBg:SetColorTexture(0, 0, 0, 0.3) -- Semi-transparent black background
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth() - 20, 0)
    scrollFrame:SetScrollChild(content)
    
    panel.enableCB = enableCB
    panel.scrollFrame = scrollFrame
    panel.content = content
    panel.addEditBox = addEditBox
    panel.holidayKey = holidayKey
    
    return panel
end

--[[
    Creates the profiles panel
]]
function PartyMotivatorUI:CreateProfilesPanel()
    local panel = CreateFrame("Frame", nil, self.contentArea)
    panel:SetAllPoints()
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("|cff9966ffProfile Management|r")
    
    -- Current profile info
    local currentProfileLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    currentProfileLabel:SetPoint("TOPLEFT", 10, -40)
    currentProfileLabel:SetText("Current profile:")
    
    local currentProfileText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    currentProfileText:SetPoint("LEFT", currentProfileLabel, "RIGHT", 10, 0)
    currentProfileText:SetText((PartyMotivatorDB and PartyMotivatorDB.activeProfile) or "Default")
    
    -- Profile management section
    local profileFrame = CreateFrame("Frame", nil, panel)
    profileFrame:SetPoint("TOPLEFT", 10, -70)
    profileFrame:SetPoint("TOPRIGHT", -10, -70)
    profileFrame:SetHeight(200)
    
    -- Save profile
    local saveFrame = CreateFrame("Frame", nil, profileFrame)
    saveFrame:SetPoint("TOPLEFT", 0, 0)
    saveFrame:SetPoint("TOPRIGHT", 0, 0)
    saveFrame:SetHeight(30)
    
    local saveLabel = saveFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    saveLabel:SetPoint("LEFT", 0, 0)
    saveLabel:SetText("Save current profile as:")
    
    local saveEditBox = CreateFrame("EditBox", nil, saveFrame, "InputBoxTemplate")
    saveEditBox:SetPoint("LEFT", saveLabel, "RIGHT", 10, 0)
    saveEditBox:SetPoint("RIGHT", -80, 0)
    saveEditBox:SetHeight(20)
    saveEditBox:SetAutoFocus(false)
    
    local saveButton = CreateFrame("Button", nil, saveFrame, "UIPanelButtonTemplate")
    saveButton:SetSize(60, 25)
    saveButton:SetPoint("RIGHT", 0, 0)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        local name = saveEditBox:GetText()
        if name and name ~= "" then
            if self:IsAddonReady() then
                if PM.SaveProfile then
                    PM:SaveProfile(name)
                else
                    -- Fallback: Direct database access
                    PartyMotivatorDB.profiles[name] = CopyTable(PM.profile)
                    print("|cff00ff00PartyMotivator|r - Profile '" .. name .. "' saved!")
                end
                saveEditBox:SetText("")
                self:RefreshProfilesList()
            else
                print("|cffff0000PartyMotivator|r - Addon not ready! Please wait a moment and try again.")
                print("|cffffffffPartyMotivator|r - You can also use /pm profile save " .. name .. " in chat.")
            end
        end
    end)
    
    -- Load profile
    local loadFrame = CreateFrame("Frame", nil, profileFrame)
    loadFrame:SetPoint("TOPLEFT", 0, -40)
    loadFrame:SetPoint("TOPRIGHT", 0, -40)
    loadFrame:SetHeight(30)
    
    local loadLabel = loadFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    loadLabel:SetPoint("LEFT", 0, 0)
    loadLabel:SetText("Load profile:")
    
    local loadDropdown = CreateFrame("Frame", nil, loadFrame, "UIDropDownMenuTemplate")
    loadDropdown:SetPoint("LEFT", loadLabel, "RIGHT", 10, 0)
    loadDropdown:SetWidth(200)
    loadDropdown:SetFrameStrata("DIALOG") -- Ensure dropdown appears above other UI elements
    
    local loadButton = CreateFrame("Button", nil, loadFrame, "UIPanelButtonTemplate")
    loadButton:SetSize(60, 25)
    loadButton:SetPoint("RIGHT", 0, 0)
    loadButton:SetText("Load")
    loadButton:SetScript("OnClick", function()
        local selectedProfile = UIDropDownMenu_GetSelectedValue(loadDropdown)
        if selectedProfile then
            if self:IsAddonReady() then
                if PM.LoadProfile then
                    PM:LoadProfile(selectedProfile)
                else
                    -- Fallback: Direct database access
                    if PartyMotivatorDB.profiles[selectedProfile] then
                        PartyMotivatorDB.activeProfile = selectedProfile
                        PM.profile = PartyMotivatorDB.profiles[selectedProfile]
                        print("|cff00ff00PartyMotivator|r - Profile '" .. selectedProfile .. "' loaded!")
                    else
                        print("|cffff0000PartyMotivator|r - Profile '" .. selectedProfile .. "' not found!")
                        return
                    end
                end
                currentProfileText:SetText((PartyMotivatorDB and PartyMotivatorDB.activeProfile) or "Default")
                self:RefreshAllLists()
            else
                print("|cffff0000PartyMotivator|r - Addon not ready! Please wait a moment and try again.")
                print("|cffffffffPartyMotivator|r - You can also use /pm profile load " .. selectedProfile .. " in chat.")
            end
        end
    end)
    
    -- Export/Import section
    local exportFrame = CreateFrame("Frame", nil, profileFrame)
    exportFrame:SetPoint("TOPLEFT", 0, -80)
    exportFrame:SetPoint("TOPRIGHT", 0, -80)
    exportFrame:SetHeight(30)
    
    local exportLabel = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    exportLabel:SetPoint("LEFT", 0, 0)
    exportLabel:SetText("Export profile:")
    
    local exportDropdown = CreateFrame("Frame", nil, exportFrame, "UIDropDownMenuTemplate")
    exportDropdown:SetPoint("LEFT", exportLabel, "RIGHT", 10, 0)
    exportDropdown:SetWidth(200)
    exportDropdown:SetFrameStrata("DIALOG") -- Ensure dropdown appears above other UI elements
    
    local exportButton = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    exportButton:SetSize(60, 25)
    exportButton:SetPoint("RIGHT", 0, 0)
    exportButton:SetText("Export")
    exportButton:SetScript("OnClick", function()
        if not PartyMotivatorUI:IsAddonReady() then
            print("|cffff0000PartyMotivator|r - Addon not ready! Please try again.")
            return
        end
        
        -- Ensure dropdown has a selection - auto-select first profile if none selected
        local selectedProfile = UIDropDownMenu_GetSelectedValue(exportDropdown)
        if not selectedProfile then
            -- Auto-select the first available profile
            local firstProfile = nil
            for profileName, _ in pairs(PartyMotivatorDB.profiles) do
                firstProfile = profileName
                break
            end
            if firstProfile then
                UIDropDownMenu_SetSelectedValue(exportDropdown, firstProfile)
                selectedProfile = firstProfile
            end
        end
        
        if not selectedProfile then 
            print("|cffff0000PartyMotivator|r - No profiles available to export!")
            return 
        end
        
        -- Use pcall to catch any errors in export
        local success, result = pcall(PM.ExportProfile, PM, selectedProfile)
        if success and result then
            PartyMotivatorUI:ShowExportWindow(selectedProfile, result)
        else
            print("|cffff0000PartyMotivator|r - Export failed: " .. tostring(result or "Unknown error"))
        end
    end)
    
    -- Delete button
    local deleteButton = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    deleteButton:SetSize(70, 25)
    deleteButton:SetPoint("RIGHT", exportButton, "LEFT", -5, 0)
    deleteButton:SetText("Delete")
    deleteButton:SetScript("OnClick", function()
        if not PartyMotivatorUI:IsAddonReady() then
            print("|cffff0000PartyMotivator|r - Addon not ready! Please try again.")
            return
        end
        local selectedProfile = UIDropDownMenu_GetSelectedValue(exportDropdown)
        if not selectedProfile then return end
        
        if selectedProfile == PartyMotivatorDB.activeProfile then
            print("|cffff0000You cannot delete the active profile.|r")
            return
        end
        
        PartyMotivatorDB.profiles[selectedProfile] = nil
        print(("Profile '%s' deleted."):format(selectedProfile))
        
        -- Refresh dropdowns and lists
        self:RefreshProfilesList()
    end)
    
    -- Import section
    local importFrame = CreateFrame("Frame", nil, profileFrame)
    importFrame:SetPoint("TOPLEFT", 0, -120)
    importFrame:SetPoint("TOPRIGHT", 0, -120)
    importFrame:SetHeight(30)
    
    local importLabel = importFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importLabel:SetPoint("LEFT", 0, 0)
    importLabel:SetText("Import as:")
    
    local importEditBox = CreateFrame("EditBox", nil, importFrame, "InputBoxTemplate")
    importEditBox:SetPoint("LEFT", importLabel, "RIGHT", 10, 0)
    importEditBox:SetPoint("RIGHT", -120, 0)
    importEditBox:SetHeight(20)
    importEditBox:SetAutoFocus(false)
    importEditBox:SetText("NewProfile")
    
    local importButton = CreateFrame("Button", nil, importFrame, "UIPanelButtonTemplate")
    importButton:SetSize(60, 25)
    importButton:SetPoint("RIGHT", -60, 0)
    importButton:SetText("Import")
    importButton:SetScript("OnClick", function()
        local name = importEditBox:GetText()
        if not name or name == "" then return end
        PartyMotivatorUI:ShowImportWindow(name, function(profileName, data)
            if PM.ImportProfile and PartyMotivatorUI:IsAddonReady() then
                PM:ImportProfile(profileName, data)
                importEditBox:SetText("NewProfile")
                PartyMotivatorUI:RefreshProfilesList()
            else
                print("|cffff0000PartyMotivator|r - Addon not ready!")
            end
        end)
    end)
    
    -- This delete button is for the LOAD dropdown, not import
    local loadDeleteButton = CreateFrame("Button", nil, loadFrame, "UIPanelButtonTemplate")
    loadDeleteButton:SetSize(60, 25)
    loadDeleteButton:SetPoint("RIGHT", loadButton, "LEFT", -5, 0)
    loadDeleteButton:SetText("Delete")
    loadDeleteButton:SetScript("OnClick", function()
        local selectedProfile = UIDropDownMenu_GetSelectedValue(loadDropdown)
        if selectedProfile then
            if self:IsAddonReady() then
                if PM.DeleteProfile then
                    PM:DeleteProfile(selectedProfile)
                else
                    -- Fallback: Direct database access
                    if selectedProfile == PartyMotivatorDB.activeProfile then
                        print("|cffff0000PartyMotivator|r - Cannot delete the active profile")
                        return
                    end
                    if PartyMotivatorDB.profiles[selectedProfile] then
                        PartyMotivatorDB.profiles[selectedProfile] = nil
                        print("|cff00ff00PartyMotivator|r - Profile '" .. selectedProfile .. "' deleted!")
                    else
                        print("|cffff0000PartyMotivator|r - Profile '" .. selectedProfile .. "' not found!")
                        return
                    end
                end
                self:RefreshProfilesList()
            else
                print("|cffff0000PartyMotivator|r - Addon not ready! Please wait a moment and try again.")
                print("|cffffffffPartyMotivator|r - You can also use /pm profile delete " .. selectedProfile .. " in chat.")
            end
        end
    end)
    
    -- Initialize dropdowns
    UIDropDownMenu_Initialize(loadDropdown, function() end)
    UIDropDownMenu_Initialize(exportDropdown, function() end)
    UIDropDownMenu_SetWidth(loadDropdown, 180)
    UIDropDownMenu_SetWidth(exportDropdown, 180)
    
    -- Store references for refreshing
    panel.loadDropdown = loadDropdown
    panel.exportDropdown = exportDropdown
    panel.currentProfileText = currentProfileText
    
    return panel
end

--[[
    Creates the settings panel
]]
function PartyMotivatorUI:CreateSettingsPanel()
    local panel = CreateFrame("Frame", nil, self.contentArea)
    panel:SetAllPoints()
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("|cffff6600Settings|r")
    
    -- Chat channel setting
    local chatFrame = CreateFrame("Frame", nil, panel)
    chatFrame:SetPoint("TOPLEFT", 10, -40)
    chatFrame:SetPoint("TOPRIGHT", -10, -40)
    chatFrame:SetHeight(30)
    
    local chatLabel = chatFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatLabel:SetPoint("LEFT", 0, 0)
    chatLabel:SetText("Chat channel:")
    
    local chatCheckbox = CreateFrame("CheckButton", nil, chatFrame, "UICheckButtonTemplate")
    chatCheckbox:SetPoint("LEFT", chatLabel, "RIGHT", 10, 0)
    chatCheckbox:SetChecked((PM and PM.profile and PM.profile.useInstanceChat) or defaultDB.useInstanceChat)
    chatCheckbox:SetScript("OnClick", function(self)
        if PartyMotivatorUI:IsAddonReady() then
            PM.profile.useInstanceChat = self:GetChecked()
            print("|cff00ff00PartyMotivator|r - Chat channel changed to: " .. (PM.profile.useInstanceChat and "INSTANCE_CHAT" or "PARTY"))
        else
            print("|cffff0000PartyMotivator|r - Addon not ready! Please wait a moment and try again.")
            print("|cffffffffPartyMotivator|r - You can also use /pm chat in chat.")
        end
    end)
    
    local chatText = chatFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatText:SetPoint("LEFT", chatCheckbox, "RIGHT", 5, 0)
    chatText:SetText("Use INSTANCE_CHAT (unchecked = PARTY)")
    
    -- Minimap button setting
    local minimapFrame = CreateFrame("Frame", nil, panel)
    minimapFrame:SetPoint("TOPLEFT", 10, -80)
    minimapFrame:SetPoint("TOPRIGHT", -10, -80)
    minimapFrame:SetHeight(30)
    
    local minimapLabel = minimapFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minimapLabel:SetPoint("LEFT", 0, 0)
    minimapLabel:SetText("Show minimap button:")
    
    local minimapCheckbox = CreateFrame("CheckButton", nil, minimapFrame, "UICheckButtonTemplate")
    minimapCheckbox:SetPoint("LEFT", minimapLabel, "RIGHT", 10, 0)
    minimapCheckbox:SetChecked(PM and PM.profile and PM.profile.minimap and PM.profile.minimap.show ~= false)
    minimapCheckbox:SetScript("OnClick", function(self)
        if not PartyMotivatorUI:IsAddonReady() then
            print("|cffff0000PartyMotivator|r - Addon not ready!")
            self:SetChecked(PM and PM.profile and PM.profile.minimap and PM.profile.minimap.show ~= false)
            return
        end
        PM.profile.minimap = PM.profile.minimap or { show = true, angle = 220, radius = 80 }
        PM.profile.minimap.show = self:GetChecked()
        PM_UpdateMinimapButtonVisibility()
    end)
    
    local minimapText = minimapFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minimapText:SetPoint("LEFT", minimapCheckbox, "RIGHT", 5, 0)
    minimapText:SetText("Show minimap button")
    
    -- Reset button
    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetSize(150, 30)
    resetButton:SetPoint("TOPLEFT", 10, -120)
    resetButton:SetText("Reset to Default")
    resetButton:SetScript("OnClick", function()
        if PartyMotivatorUI:IsAddonReady() then
            -- Use the actual DEFAULT_PROFILE (now global)
            if not DEFAULT_PROFILE then
                print("|cffff0000PartyMotivator|r - Error: DEFAULT_PROFILE not found!")
                return
            end
            
            PM.profile.startMessages = CopyTable(DEFAULT_PROFILE.startMessages)
            PM.profile.greetMessages = CopyTable(DEFAULT_PROFILE.greetMessages)
            PM.profile.mythicPlusMessages = CopyTable(DEFAULT_PROFILE.mythicPlusMessages)
            PM.profile.minimap = CopyTable(DEFAULT_PROFILE.minimap)
            -- Reset holidays (if holiday system is loaded)
            if PartyMotivatorHolidays then
                PM.profile.holidays = CopyTable(PartyMotivatorHolidays.DEFAULT_HOLIDAYS)
            end
            print("|cff00ff00PartyMotivator|r - All settings and messages reset to default!")
            PartyMotivatorUI:RefreshAllLists()
            -- Update minimap button visibility
            PM_UpdateMinimapButtonVisibility()
            -- Update minimap checkbox
            minimapCheckbox:SetChecked(PM.profile.minimap.show ~= false)
        else
            print("|cffff0000PartyMotivator|r - Addon not ready! Please wait a moment and try again.")
            print("|cffffffffPartyMotivator|r - You can also use /pm reset in chat.")
        end
    end)
    
    return panel
end

--[[
    Sets up event handlers
]]
function PartyMotivatorUI:SetupEventHandlers()
    -- Handle escape key - all other keys are automatically propagated to game
    self.mainFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
            return true -- Consume the ESC key
        end
        -- All other keys are automatically propagated to the game due to SetPropagateKeyboardInput(true)
        return false
    end)
end

--[[
    Scrolls to make a tab visible
]]
function PartyMotivatorUI:ScrollToTab(tabIndex)
    if not self.tabs[tabIndex] or not self.tabScrollFrame then return end
    
    local tab = self.tabs[tabIndex]
    local tabLeft = tab:GetLeft() or 0
    local tabRight = tab:GetRight() or 0
    local scrollFrameLeft = self.tabScrollFrame:GetLeft() or 0
    local scrollFrameRight = self.tabScrollFrame:GetRight() or 0
    
    local currentScroll = self.tabScrollFrame:GetHorizontalScroll()
    local viewLeft = scrollFrameLeft + currentScroll
    local viewRight = scrollFrameRight + currentScroll
    
    -- Check if tab is outside visible area
    if tabLeft < viewLeft then
        -- Tab is to the left, scroll left
        self.tabScrollFrame:SetHorizontalScroll(math.max(0, tabLeft - scrollFrameLeft))
    elseif tabRight > viewRight then
        -- Tab is to the right, scroll right
        local maxScroll = math.max(0, self.tabContentFrame:GetWidth() - self.tabScrollFrame:GetWidth())
        local newScroll = tabRight - scrollFrameRight + currentScroll
        self.tabScrollFrame:SetHorizontalScroll(math.min(maxScroll, newScroll))
    end
end

--[[
    Switches between tabs
]]
function PartyMotivatorUI:SwitchTab(tabIndex)
    self.activeTab = tabIndex
    self:ScrollToTab(tabIndex) -- Ensure tab is visible
    self:UpdateTabAppearance()
    self:ShowPanel(tabIndex)
end

--[[
    Updates tab appearance
]]
function PartyMotivatorUI:UpdateTabAppearance()
    for i, tab in ipairs(self.tabs) do
        if i == self.activeTab then
            tab:GetFontString():SetTextColor(1, 1, 0) -- Yellow for active
        else
            tab:GetFontString():SetTextColor(1, 1, 1) -- White for inactive
        end
    end
end

--[[
    Shows a specific panel
]]
function PartyMotivatorUI:ShowPanel(panelIndex)
    for i, panel in ipairs(self.panels) do
        if i == panelIndex then
            panel:Show()
        else
            panel:Hide()
        end
    end
    
    -- Refresh lists when switching to them
    if panelIndex == 1 then
        self:RefreshStartMessagesList()
    elseif panelIndex == 2 then
        self:RefreshGreetingsList()
    elseif panelIndex == 3 then
        self:RefreshMythicPlusSuccessList()
        self:RefreshMythicPlusFailureList()
    elseif panelIndex == 4 then
        self:UpdateHolidayTabVisibility() -- Update tab visibility first
        self:ShowHolidaySubTab("HALLOWEEN") -- Default to Halloween tab
    elseif panelIndex == 5 then
        self:RefreshProfilesList()
    end
end

--[[
    Refreshes the start messages list
]]
function PartyMotivatorUI:RefreshStartMessagesList()
    local panel = self.panels[1]
    local content = panel.content
    
    -- Clear existing content
    for i = content:GetNumChildren(), 1, -1 do
        local child = select(i, content:GetChildren())
        child:Hide()
        child:SetParent(nil)
    end
    
    local messages = (PM and PM.profile and PM.profile.startMessages) or defaultDB.startMessages
    local yOffset = 0
    
    for i, message in ipairs(messages) do
        local itemFrame = CreateFrame("Frame", nil, content)
        itemFrame:SetSize(content:GetWidth(), 25)
        itemFrame:SetPoint("TOPLEFT", 0, -yOffset)
        
        local text = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", 0, 0)
        local display = string.format("%d. %s", i, tostring(message))
        text:SetText(display)
        text:SetWidth(content:GetWidth() - 80)
        
        local editButton = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
        editButton:SetSize(50, 20)
        editButton:SetPoint("RIGHT", -70, 0)
        editButton:SetText("Edit")
        editButton:SetScript("OnClick", function()
            self:ShowEditMessageWindow("Edit Start Message", message, function(newText)
                messages[i] = newText
                self:RefreshStartMessagesList()
            end)
        end)
        
        local removeButton = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
        removeButton:SetSize(60, 20)
        removeButton:SetPoint("RIGHT", 0, 0)
        removeButton:SetText("Remove")
        removeButton:SetScript("OnClick", function()
            table.remove(messages, i)
            self:RefreshStartMessagesList()
            print("|cff00ff00PartyMotivator|r - Message removed: " .. message)
        end)
        
        yOffset = yOffset + 25
    end
    
    content:SetHeight(yOffset)
end

--[[
    Refreshes the greetings list
]]
function PartyMotivatorUI:RefreshGreetingsList()
    local panel = self.panels[2]
    local content = panel.content
    
    -- Clear existing content
    for i = content:GetNumChildren(), 1, -1 do
        local child = select(i, content:GetChildren())
        child:Hide()
        child:SetParent(nil)
    end
    
    local greetings = (PM and PM.profile and PM.profile.greetMessages) or defaultDB.greetMessages
    local yOffset = 0
    
    for i, greeting in ipairs(greetings) do
        local itemFrame = CreateFrame("Frame", nil, content)
        itemFrame:SetSize(content:GetWidth(), 25)
        itemFrame:SetPoint("TOPLEFT", 0, -yOffset)
        
        local text = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", 0, 0)
        text:SetText(string.format("%d. %s", i, greeting))
        text:SetWidth(content:GetWidth() - 80)
        
        local editButton = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
        editButton:SetSize(50, 20)
        editButton:SetPoint("RIGHT", -70, 0)
        editButton:SetText("Edit")
        editButton:SetScript("OnClick", function()
            self:ShowEditMessageWindow("Edit Greeting", greeting, function(newText)
                greetings[i] = newText
                self:RefreshGreetingsList()
            end)
        end)
        
        local removeButton = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
        removeButton:SetSize(60, 20)
        removeButton:SetPoint("RIGHT", 0, 0)
        removeButton:SetText("Remove")
        removeButton:SetScript("OnClick", function()
            table.remove(greetings, i)
            self:RefreshGreetingsList()
            print("|cff00ff00PartyMotivator|r - Greeting removed: " .. greeting)
        end)
        
        yOffset = yOffset + 25
    end
    
    content:SetHeight(yOffset)
end

--[[
    Refreshes the Mythic+ success messages list
]]
function PartyMotivatorUI:RefreshMythicPlusSuccessList()
    local panel = self.panels[3]
    local content = panel.successContent
    
    -- Ensure tables are properly structured
    ensureMythicPlusTables()
    
    -- Clear existing content
    for i = content:GetNumChildren(), 1, -1 do
        local child = select(i, content:GetChildren())
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Initialize default messages if needed
    initializeDefaultMythicPlusMessages()
    
    local messages = {}
    if PM and PM.profile and PM.profile.mythicPlusMessages and PM.profile.mythicPlusMessages.success then
        messages = PM.profile.mythicPlusMessages.success
    else
        -- Fallback to default messages from main addon
        messages = {
            "GG! We timed it and upgraded the key.",
            "Clean run! Key upgraded!",
            "Perfect timing! Well done team!",
            "Key upgraded! Great job everyone!",
            "Timed it! Excellent work!",
            "Success! Key level up!",
            "Flawless execution! Key upgraded!",
            "Team work makes the dream work! Key up!",
            "Smooth run! Key upgraded!",
            "Outstanding! Key level increased!"
        }
    end
    local yOffset = 0
    
    for i, message in ipairs(messages) do
        local itemFrame = CreateFrame("Frame", nil, content)
        itemFrame:SetSize(content:GetWidth(), 25)
        itemFrame:SetPoint("TOPLEFT", 0, -yOffset)
        
        local text = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", 0, 0)
        local display = string.format("%d. %s", i, tostring(message))
        text:SetText(display)
        text:SetWidth(content:GetWidth() - 80)
        
        local editButton = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
        editButton:SetSize(50, 20)
        editButton:SetPoint("RIGHT", -70, 0)
        editButton:SetText("Edit")
        editButton:SetScript("OnClick", function()
            self:ShowEditMessageWindow("Edit Success Message", message, function(newText)
                if PM and PM.profile and PM.profile.mythicPlusMessages and PM.profile.mythicPlusMessages.success then
                    PM.profile.mythicPlusMessages.success[i] = newText
                    self:RefreshMythicPlusSuccessList()
                end
            end)
        end)
        
        local removeButton = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
        removeButton:SetSize(60, 20)
        removeButton:SetPoint("RIGHT", 0, 0)
        removeButton:SetText("Remove")
        removeButton:SetScript("OnClick", function()
            if PM and PM.profile and PM.profile.mythicPlusMessages and PM.profile.mythicPlusMessages.success then
                table.remove(PM.profile.mythicPlusMessages.success, i)
                self:RefreshMythicPlusSuccessList()
                print("|cff00ff00PartyMotivator|r - Success message removed: " .. message)
            end
        end)
        
        yOffset = yOffset + 25
    end
    
    content:SetHeight(yOffset)
end

--[[
    Refreshes the Mythic+ failure messages list
]]
function PartyMotivatorUI:RefreshMythicPlusFailureList()
    local panel = self.panels[3]
    local content = panel.failureContent
    
    -- Ensure tables are properly structured
    ensureMythicPlusTables()
    
    -- Clear existing content
    for i = content:GetNumChildren(), 1, -1 do
        local child = select(i, content:GetChildren())
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Initialize default messages if needed
    initializeDefaultMythicPlusMessages()
    
    local messages = {}
    if PM and PM.profile and PM.profile.mythicPlusMessages and PM.profile.mythicPlusMessages.failure then
        messages = PM.profile.mythicPlusMessages.failure
    else
        -- Fallback to default messages from main addon
        messages = {
            "Thanks for the key! We'll get it next time.",
            "Good try! Next time we'll time it.",
            "Close one! We'll nail it next run.",
            "Thanks for the key! Practice makes perfect.",
            "Good effort! We'll get it next time.",
            "Thanks for the key! We're getting better.",
            "Nice try! Next run will be the one.",
            "Thanks for the key! We'll improve next time.",
            "Good attempt! We'll time it next run.",
            "Thanks for the key! We'll do better next time."
        }
    end
    local yOffset = 0
    
    for i, message in ipairs(messages) do
        local itemFrame = CreateFrame("Frame", nil, content)
        itemFrame:SetSize(content:GetWidth(), 25)
        itemFrame:SetPoint("TOPLEFT", 0, -yOffset)
        
        local text = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", 0, 0)
        local display = string.format("%d. %s", i, tostring(message))
        text:SetText(display)
        text:SetWidth(content:GetWidth() - 80)
        
        local editButton = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
        editButton:SetSize(50, 20)
        editButton:SetPoint("RIGHT", -70, 0)
        editButton:SetText("Edit")
        editButton:SetScript("OnClick", function()
            self:ShowEditMessageWindow("Edit Failure Message", message, function(newText)
                if PM and PM.profile and PM.profile.mythicPlusMessages and PM.profile.mythicPlusMessages.failure then
                    PM.profile.mythicPlusMessages.failure[i] = newText
                    self:RefreshMythicPlusFailureList()
                end
            end)
        end)
        
        local removeButton = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
        removeButton:SetSize(60, 20)
        removeButton:SetPoint("RIGHT", 0, 0)
        removeButton:SetText("Remove")
        removeButton:SetScript("OnClick", function()
            if PM and PM.profile and PM.profile.mythicPlusMessages and PM.profile.mythicPlusMessages.failure then
                table.remove(PM.profile.mythicPlusMessages.failure, i)
                self:RefreshMythicPlusFailureList()
                print("|cff00ff00PartyMotivator|r - Failure message removed: " .. message)
            end
        end)
        
        yOffset = yOffset + 25
    end
    
    content:SetHeight(yOffset)
end

--[[
    Refreshes the profiles list
]]
function PartyMotivatorUI:RefreshProfilesList()
    local panel = self.panels[5] -- Profiles panel is now index 5 (was 4 before holidays)
    if not panel then return end
    
    -- Update current profile text
    if panel.currentProfileText then
        panel.currentProfileText:SetText((PartyMotivatorDB and PartyMotivatorDB.activeProfile) or "Default")
    end
    
    -- Update load dropdown
    if panel.loadDropdown then
        local profiles = {}
        if PartyMotivatorDB and PartyMotivatorDB.profiles then
            for name, _ in pairs(PartyMotivatorDB.profiles) do
                table.insert(profiles, name)
            end
        end
        table.sort(profiles)
        
        UIDropDownMenu_Initialize(panel.loadDropdown, function(self, level)
            for i, name in ipairs(profiles) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = name
                info.value = name
                info.func = function(self)
                    UIDropDownMenu_SetSelectedValue(panel.loadDropdown, self.value)
                    UIDropDownMenu_SetText(panel.loadDropdown, self.value)
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        
        -- Auto-select first profile if none selected and profiles exist
        if #profiles > 0 then
            local currentSelection = UIDropDownMenu_GetSelectedValue(panel.loadDropdown)
            if not currentSelection then
                UIDropDownMenu_SetSelectedValue(panel.loadDropdown, profiles[1])
                UIDropDownMenu_SetText(panel.loadDropdown, profiles[1])
            else
                UIDropDownMenu_SetText(panel.loadDropdown, currentSelection)
            end
        else
            UIDropDownMenu_SetText(panel.loadDropdown, "No Profiles")
        end
        UIDropDownMenu_Refresh(panel.loadDropdown)
    end
    
    -- Update export dropdown
    if panel.exportDropdown then
        local exportProfiles = {}
        if PartyMotivatorDB and PartyMotivatorDB.profiles then
            for name, _ in pairs(PartyMotivatorDB.profiles) do
                table.insert(exportProfiles, name)
            end
        end
        table.sort(exportProfiles)
        
        UIDropDownMenu_Initialize(panel.exportDropdown, function(self, level)
            for i, name in ipairs(exportProfiles) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = name
                info.value = name
                info.func = function(self)
                    UIDropDownMenu_SetSelectedValue(panel.exportDropdown, self.value)
                    UIDropDownMenu_SetText(panel.exportDropdown, self.value)
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        
        -- Auto-select first profile if none selected and profiles exist
        if #exportProfiles > 0 then
            local currentSelection = UIDropDownMenu_GetSelectedValue(panel.exportDropdown)
            if not currentSelection then
                UIDropDownMenu_SetSelectedValue(panel.exportDropdown, exportProfiles[1])
                UIDropDownMenu_SetText(panel.exportDropdown, exportProfiles[1])
            else
                UIDropDownMenu_SetText(panel.exportDropdown, currentSelection)
            end
        else
            UIDropDownMenu_SetText(panel.exportDropdown, "No Profiles")
        end
        UIDropDownMenu_Refresh(panel.exportDropdown)
    end
end

--[[
    Refreshes a specific holiday messages list
]]
function PartyMotivatorUI:RefreshHolidayMessagesList(holidayKey)
    if not PartyMotivatorHolidays then return end
    
    local panel = self.panels[4] -- Holiday panel
    if not panel then return end
    
    local holidayPanel = panel.panels and panel.panels[holidayKey]
    if not holidayPanel then return end
    
    local content = holidayPanel.content
    
    -- Clear existing content
    for i = content:GetNumChildren(), 1, -1 do
        local child = select(i, content:GetChildren())
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Get messages for this holiday
    local messages = {}
    if PM and PM.profile and PM.profile.holidays and PM.profile.holidays.events and PM.profile.holidays.events[holidayKey] then
        messages = PM.profile.holidays.events[holidayKey].messages or {}
    else
        -- Fallback to default messages
        messages = PartyMotivatorHolidays.DEFAULT_HOLIDAYS.events[holidayKey].messages or {}
    end
    
    local yOffset = 0
    
    for i, message in ipairs(messages) do
        local itemFrame = CreateFrame("Frame", nil, content)
        itemFrame:SetSize(content:GetWidth(), 35) -- Increased height for better visibility
        itemFrame:SetPoint("TOPLEFT", 0, -yOffset)
        
        -- Add background for better visibility
        local bg = itemFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(itemFrame)
        if i % 2 == 0 then
            bg:SetColorTexture(0.1, 0.1, 0.1, 0.3) -- Alternating background
        else
            bg:SetColorTexture(0.2, 0.2, 0.2, 0.2)
        end
        
        local text = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", 5, 0) -- Small left padding
        local display = string.format("%d. %s", i, tostring(message))
        text:SetText(display)
        text:SetWidth(content:GetWidth() - 125) -- Adjusted for padding
        
        local editButton = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
        editButton:SetSize(50, 20)
        editButton:SetPoint("RIGHT", -70, 0)
        editButton:SetText("Edit")
        editButton:SetScript("OnClick", function()
            self:ShowEditMessageWindow("Edit Holiday Message", message, function(newText)
                PM.profile.holidays.events[holidayKey].messages[i] = newText
                self:RefreshHolidayMessagesList(holidayKey)
            end)
        end)
        
        local removeButton = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
        removeButton:SetSize(60, 20)
        removeButton:SetPoint("RIGHT", 0, 0)
        removeButton:SetText("Remove")
        removeButton:SetScript("OnClick", function()
            table.remove(PM.profile.holidays.events[holidayKey].messages, i)
            self:RefreshHolidayMessagesList(holidayKey)
            print("|cff00ff00PartyMotivator|r - Holiday message removed: " .. message)
        end)
        
        yOffset = yOffset + 35 -- Match the increased item height
    end
    
    content:SetHeight(yOffset)
    
    -- Update enable checkbox
    if holidayPanel.enableCB then
        local enabled = PM.profile.holidays and PM.profile.holidays.events and PM.profile.holidays.events[holidayKey] and PM.profile.holidays.events[holidayKey].enabled
        holidayPanel.enableCB:SetChecked(enabled ~= false)
    end
end

--[[
    Updates holiday tab visibility based on active regions
]]
function PartyMotivatorUI:UpdateHolidayTabVisibility()
    if not PartyMotivatorHolidays then return end
    
    local panel = self.panels[4] -- Holiday panel
    if not panel or not panel.tabs then return end
    
    -- Get active regions from profile
    local activeRegions = PM.profile.holidays and PM.profile.holidays.regions or { US = true, EU = true, ASIA = true }
    
    -- Update tab visibility
    for holidayKey, tab in pairs(panel.tabs) do
        if PartyMotivatorHolidays:IsHolidayVisibleForRegions(holidayKey, activeRegions) then
            tab:Show()
        else
            tab:Hide()
            -- If current active tab is being hidden, switch to a visible one
            if panel.currentSubTab == holidayKey then
                local visibleHolidays = PartyMotivatorHolidays:GetVisibleHolidays(activeRegions)
                if #visibleHolidays > 0 then
                    self:ShowHolidaySubTab(visibleHolidays[1])
                end
            end
        end
    end
end

--[[
    Shows a specific Holiday sub-tab
]]
function PartyMotivatorUI:ShowHolidaySubTab(holidayKey)
    local panel = self.panels[4] -- Holiday panel
    if not panel then return end
    
    -- Hide all sub-panels
    for key, subPanel in pairs(panel.panels) do
        subPanel:Hide()
    end
    
    -- Reset all button styles
    for key, tab in pairs(panel.tabs) do
        tab:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Up")
    end
    
    -- Show the selected sub-panel and update button style
    if panel.panels[holidayKey] and panel.tabs[holidayKey] then
        panel.panels[holidayKey]:Show()
        panel.tabs[holidayKey]:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Down")
        panel.currentSubTab = holidayKey
        self:RefreshHolidayMessagesList(holidayKey)
    end
end

--[[
    Refreshes holiday settings (checkboxes) when switching profiles
]]
function PartyMotivatorUI:RefreshHolidaySettings()
    local panel = self.panels[4] -- Holiday panel
    if not panel or not PartyMotivatorHolidays then return end
    
    -- Update main enable checkbox
    if panel.cbEnable then
        panel.cbEnable:SetChecked((PM.profile.holidays and PM.profile.holidays.enabled) ~= false)
    end
    
    -- Update region checkboxes
    if panel.cbUS then
        panel.cbUS:SetChecked(not PM.profile.holidays or not PM.profile.holidays.regions or PM.profile.holidays.regions.US ~= false)
    end
    if panel.cbEU then
        panel.cbEU:SetChecked(not PM.profile.holidays or not PM.profile.holidays.regions or PM.profile.holidays.regions.EU ~= false)
    end
    if panel.cbASIA then
        panel.cbASIA:SetChecked(not PM.profile.holidays or not PM.profile.holidays.regions or PM.profile.holidays.regions.ASIA ~= false)
    end
    
    -- Update tab visibility based on new region settings
    self:UpdateHolidayTabVisibility()
end

--[[
    Refreshes all lists
]]
function PartyMotivatorUI:RefreshAllLists()
    self:RefreshStartMessagesList()
    self:RefreshGreetingsList()
    self:RefreshMythicPlusSuccessList()
    self:RefreshMythicPlusFailureList()
    self:RefreshProfilesList()
    -- Refresh holiday settings and messages if holiday system is loaded
    if PartyMotivatorHolidays then
        self:RefreshHolidaySettings() -- NEW: Refresh the checkboxes!
        self:RefreshHolidayMessagesList("HALLOWEEN")
        self:RefreshHolidayMessagesList("WINTER_VEIL")
        self:RefreshHolidayMessagesList("LOVE_IS_IN_THE_AIR")
        self:RefreshHolidayMessagesList("BREWFEST")
        self:RefreshHolidayMessagesList("MIDSUMMER")
        self:RefreshHolidayMessagesList("HARVEST_FESTIVAL")
        self:RefreshHolidayMessagesList("LUNAR_FESTIVAL")
        self:RefreshHolidayMessagesList("NOBLEGARDEN")
    end
end

--[[
    Shows the UI
]]
function PartyMotivatorUI:ShowUI()
    -- Lazy initialization if needed
    if not self._initialized then
        if not self:IsAddonReady() then
            print("|cffff0000PartyMotivator|r - Addon not ready yet. Please try again in a moment.")
            return
        end
        self:Initialize()
    end
    
    -- Show the UI
    if self.mainFrame then
        self.mainFrame:Show()
        self.isVisible = true
        self.mainFrame:SetFrameStrata("HIGH")
    end
end

--[[
    Hides the UI
]]
function PartyMotivatorUI:HideUI()
    if self.mainFrame then
        self.mainFrame:Hide()
        self.isVisible = false
    end
end

--[[
    Shows the Import Window with scrollable EditBox
    @param profileName string - Name of the profile to import
    @param onConfirm function - Callback function when import is confirmed
]]
function PartyMotivatorUI:ShowImportWindow(profileName, onConfirm)
    local f = CreateFrame("Frame", "PM_ImportDialog", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(620, 420)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)

    -- Make movable (official pattern)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Import Profile Data")

    -- Hint
    local help = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    help:SetPoint("TOPLEFT", 12, -42)
    help:SetText("Paste the exported profile string below (starts with PMX1|):")
    help:SetTextColor(1, 0.82, 0)

    -- ScrollFrame + multi-line EditBox (standard pattern)
    local scroll = CreateFrame("ScrollFrame", "PM_ImportScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -68)
    scroll:SetPoint("BOTTOMRIGHT", -36, 46)

    local edit = CreateFrame("EditBox", "PM_ImportEditBox", scroll, "InputBoxTemplate")
    edit:SetMultiLine(true)
    edit:SetAutoFocus(true)
    edit:SetMaxLetters(0)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(scroll:GetWidth())   -- needed for proper scrollbar layout
    edit:SetText("")
    edit:HighlightText()
    edit:SetFocus()
    scroll:SetScrollChild(edit)

    -- Buttons
    local importBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    importBtn:SetSize(90, 24)
    importBtn:SetPoint("BOTTOMLEFT", 10, 12)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function()
        local data = edit:GetText()
        if data and data ~= "" and PartyMotivatorUI:IsAddonReady() then
            if onConfirm then onConfirm(profileName, data) end
            f:Hide()
        else
            print("|cffff0000PartyMotivator|r - Addon not ready or empty data.")
        end
    end)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBtn:SetSize(90, 24)
    closeBtn:SetPoint("BOTTOMRIGHT", -10, 12)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- ESC to close; let movement keys pass through
    f:EnableKeyboard(true)
    if f.SetPropagateKeyboardInput then f:SetPropagateKeyboardInput(true) end
    f:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then self:Hide() end
    end)
end

--[[
    Shows the Edit Message Window in foreground with drag support
    @param title string - Title of the edit window
    @param message string - Current message text to edit
    @param onSave function - Callback function when message is saved
]]
function PartyMotivatorUI:ShowEditMessageWindow(title, message, onSave)
    -- Close any existing edit window first
    local existingFrame = _G["PM_EditDialog"]
    if existingFrame then
        existingFrame:Hide()
        existingFrame = nil
    end
    
    local editFrame = CreateFrame("Frame", "PM_EditDialog", UIParent, "BasicFrameTemplateWithInset")
    editFrame:SetSize(500, 180)
    editFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    editFrame:SetFrameStrata("DIALOG")
    editFrame:SetToplevel(true)
    editFrame:SetClampedToScreen(true)

    -- Make movable (official pattern)
    editFrame:SetMovable(true)
    editFrame:EnableMouse(true)
    editFrame:RegisterForDrag("LeftButton")
    editFrame:SetScript("OnDragStart", editFrame.StartMoving)
    editFrame:SetScript("OnDragStop", editFrame.StopMovingOrSizing)

    -- Title
    local frameTitle = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frameTitle:SetPoint("TOP", 0, -10)
    frameTitle:SetText(title or "Edit Message")

    -- Edit box
    local editBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
    editBox:SetPoint("TOPLEFT", 15, -50)
    editBox:SetPoint("TOPRIGHT", -15, -50)
    editBox:SetHeight(25)
    editBox:SetText(message or "")
    editBox:SetAutoFocus(true)
    editBox:SetFocus()
    editBox:HighlightText()

    -- Save button
    local saveButton = CreateFrame("Button", nil, editFrame, "UIPanelButtonTemplate")
    saveButton:SetSize(80, 25)
    saveButton:SetPoint("BOTTOMLEFT", 15, 15)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        local newText = editBox:GetText()
        if newText and newText ~= "" then
            if onSave then 
                onSave(newText) 
            end
            editFrame:Hide()
            print("|cff00ff00PartyMotivator|r - Message updated: " .. newText)
        end
    end)

    -- Cancel button
    local cancelButton = CreateFrame("Button", nil, editFrame, "UIPanelButtonTemplate")
    cancelButton:SetSize(80, 25)
    cancelButton:SetPoint("BOTTOMRIGHT", -15, 15)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        editFrame:Hide()
    end)

    -- ESC to close; let movement keys pass through
    editFrame:EnableKeyboard(true)
    if editFrame.SetPropagateKeyboardInput then 
        editFrame:SetPropagateKeyboardInput(true) 
    end
    editFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then 
            self:Hide() 
        end
    end)

    -- Connect the built-in close button
    if editFrame.CloseButton then
        editFrame.CloseButton:SetScript("OnClick", function() editFrame:Hide() end)
    end

    editFrame:Show()
end

--[[
    Shows the Export Window with Base64 export string
    @param profileName string - Name of the profile being exported
    @param exportString string - The Base64 encoded export string
]]
function PartyMotivatorUI:ShowExportWindow(profileName, exportString)
    -- Validate input parameters
    if not profileName or not exportString then
        print("|cffff0000PartyMotivator|r - Invalid export data!")
        return
    end
    
    -- Close any existing export window first
    local existingFrame = _G["PM_ExportDialog"]
    if existingFrame then
        existingFrame:Hide()
        existingFrame = nil
    end
    
    local frame = CreateFrame("Frame", "PM_ExportDialog", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(560, 340)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)

    -- Make movable (official pattern)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Export Profile: " .. (profileName or ""))

    local help = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    help:SetPoint("TOPLEFT", 10, -40)
    help:SetText("Copy the string below (Ctrl-A, Ctrl-C).")

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -70)
    scroll:SetPoint("BOTTOMRIGHT", -30, 46)

    local edit = CreateFrame("EditBox", nil, scroll, "InputBoxTemplate")
    edit:SetMultiLine(true)                   -- Multi-line EditBox
    edit:SetFontObject(ChatFontNormal)        -- gängige UI-Schrift
    edit:SetAutoFocus(true)
    edit:SetMaxLetters(0)
    edit:SetText(exportString or "")
    edit:HighlightText()
    edit:SetFocus()
    edit:SetWidth(scroll:GetWidth())          -- wichtig, damit der ScrollFrame korrekt funktioniert
    scroll:SetScrollChild(edit)

    local copyBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    copyBtn:SetSize(80, 24)
    copyBtn:SetPoint("BOTTOMLEFT", 10, 12)
    copyBtn:SetText("Copy")
    copyBtn:SetScript("OnClick", function() 
        edit:SetFocus()
        edit:HighlightText() 
    end)

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBtn:SetSize(80, 24)
    closeBtn:SetPoint("BOTTOMRIGHT", -10, 12)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() 
        frame:Hide() 
    end)

    -- ESC to close; let movement keys pass through
    frame:EnableKeyboard(true)
    if frame.SetPropagateKeyboardInput then frame:SetPropagateKeyboardInput(true) end
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then self:Hide() end
    end)
    
    frame:Show() -- Explicitly show the frame
end

--[[
    Switches to a specific tab
]]
function PartyMotivatorUI:SwitchTab(tabIndex)
    if not self.tabs or not self.panels then return end
    
    -- Hide all panels
    for i, panel in ipairs(self.panels) do
        panel:Hide()
    end
    
    -- Show the selected panel
    if self.panels[tabIndex] then
        self.panels[tabIndex]:Show()
        
        -- Refresh lists when switching to specific panels
        if tabIndex == 1 then -- Start Messages
            self:RefreshStartMessagesList()
        elseif tabIndex == 2 then -- Greetings
            self:RefreshGreetingsList()
        elseif tabIndex == 3 then -- Mythic+
            self:ShowMythicPlusSubTab("success") -- Default to success tab
        elseif tabIndex == 4 then -- Holidays
            self:RefreshHolidaySettings() -- Refresh checkboxes first
            self:UpdateHolidayTabVisibility() -- Update tab visibility first
            self:ShowHolidaySubTab("HALLOWEEN") -- Default to Halloween tab
        elseif tabIndex == 5 then -- Profiles
            self:RefreshProfilesList()
        end
    end
    
    -- Update tab appearance
    self.activeTab = tabIndex
    self:UpdateTabAppearance()
end

--[[
    Shows a specific Mythic+ sub-tab
]]
function PartyMotivatorUI:ShowMythicPlusSubTab(subTab)
    local panel = self.panels[3] -- Mythic+ panel
    if not panel then return end
    
    -- Hide both sub-panels
    panel.successPanel:Hide()
    panel.failurePanel:Hide()
    
    -- Reset button styles
    panel.successTab:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Up")
    panel.failureTab:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Up")
    
    -- Show the selected sub-panel and update button style
    if subTab == "success" then
        panel.successPanel:Show()
        panel.successTab:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Down")
        panel.currentSubTab = "success"
        self:RefreshMythicPlusSuccessList()
    elseif subTab == "failure" then
        panel.failurePanel:Show()
        panel.failureTab:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Down")
        panel.currentSubTab = "failure"
        self:RefreshMythicPlusFailureList()
    end
end

--[[
    Updates the appearance of tabs
]]
function PartyMotivatorUI:UpdateTabAppearance()
    if not self.tabs then return end
    
    for i, tab in ipairs(self.tabs) do
        if i == self.activeTab then
            tab:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Down")
        else
            tab:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Up")
        end
    end
end

--[[
    Toggles the UI visibility
]]
function PartyMotivatorUI:ToggleUI()
    if self.isVisible then
        self:HideUI()
    else
        self:ShowUI()
    end
end

--[[
    Alias for ToggleUI for compatibility with minimap button and compartment
]]
function PartyMotivatorUI:Toggle()
    self:ToggleUI()
end
