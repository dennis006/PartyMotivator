--[[
    PartyMotivatorUI - Schönes, modernes UI für PartyMotivator
    Eigenständiges Interface mit Animationen und professionellem Design
]]

-- UI Namespace
PartyMotivatorUI = {}

--[[
    Erstellt das Haupt-UI-Fenster
]]
function PartyMotivatorUI:CreateMainFrame()
    -- Hauptfenster
    self.mainFrame = CreateFrame("Frame", "PartyMotivatorMainFrame", UIParent)
    self.mainFrame:SetSize(700, 600)
    self.mainFrame:SetPoint("CENTER")
    self.mainFrame:SetFrameStrata("DIALOG")
    self.mainFrame:SetFrameLevel(100)
    self.mainFrame:Hide()
    
    -- Schöner Hintergrund mit Gradient
    local bg = self.mainFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.15, 0.95)
    
    -- Glowing Border
    local border = self.mainFrame:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetColorTexture(0.2, 0.4, 0.8, 0.3)
    
    -- Innerer Rahmen
    local innerBorder = self.mainFrame:CreateTexture(nil, "ARTWORK")
    innerBorder:SetPoint("TOPLEFT", 2, -2)
    innerBorder:SetPoint("BOTTOMRIGHT", -2, 2)
    innerBorder:SetColorTexture(0.1, 0.1, 0.2, 0.8)
    
    -- Titel-Bar mit schönem Design
    self:CreateTitleBar()
    
    -- Tab-System
    self:CreateTabSystem()
    
    -- Content-Bereich
    self:CreateContentArea()
    
    -- Animationen hinzufügen
    self:AddAnimations()
end

--[[
    Erstellt die Titel-Bar
]]
function PartyMotivatorUI:CreateTitleBar()
    self.titleBar = CreateFrame("Frame", nil, self.mainFrame)
    self.titleBar:SetSize(700, 50)
    self.titleBar:SetPoint("TOP")
    
    -- Titel-Hintergrund
    local titleBg = self.titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.1, 0.3, 0.6, 0.9)
    
    -- Titel-Text mit schöner Schrift
    self.titleText = self.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.titleText:SetPoint("CENTER", 0, 0)
    self.titleText:SetText("|cff00ff88Party|r|cffff6600Motivator|r |cff888888v1.0|r")
    self.titleText:SetTextColor(1, 1, 1)
    
    -- Schließen-Button mit Hover-Effekt
    self.closeBtn = CreateFrame("Button", nil, self.titleBar)
    self.closeBtn:SetSize(30, 30)
    self.closeBtn:SetPoint("TOPRIGHT", -10, -10)
    
    local closeTexture = self.closeBtn:CreateTexture(nil, "ARTWORK")
    closeTexture:SetAllPoints()
    closeTexture:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    
    self.closeBtn:SetScript("OnClick", function()
        self:CloseUI()
    end)
    
    self.closeBtn:SetScript("OnEnter", function()
        closeTexture:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    end)
    
    self.closeBtn:SetScript("OnLeave", function()
        closeTexture:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    end)
end

--[[
    Erstellt das Tab-System
]]
function PartyMotivatorUI:CreateTabSystem()
    self.tabFrame = CreateFrame("Frame", nil, self.mainFrame)
    self.tabFrame:SetSize(680, 40)
    self.tabFrame:SetPoint("TOP", 0, -55)
    
    -- Tab-Hintergrund
    local tabBg = self.tabFrame:CreateTexture(nil, "BACKGROUND")
    tabBg:SetAllPoints()
    tabBg:SetColorTexture(0.05, 0.05, 0.1, 0.8)
    
    -- Start-Sprüche Tab
    self.startTab = self:CreateTab("Start-Sprüche", 0, function() self:ShowStartMessagesTab() end)
    
    -- Begrüßungen Tab
    self.greetTab = self:CreateTab("Begrüßungen", 1, function() self:ShowGreetingsTab() end)
    
    -- Einstellungen Tab
    self.settingsTab = self:CreateTab("Einstellungen", 2, function() self:ShowSettingsTab() end)
    
    -- Statistiken Tab
    self.statsTab = self:CreateTab("Statistiken", 3, function() self:ShowStatsTab() end)
end

--[[
    Erstellt einen einzelnen Tab
]]
function PartyMotivatorUI:CreateTab(text, index, onClick)
    local tab = CreateFrame("Button", nil, self.tabFrame)
    tab:SetSize(160, 35)
    tab:SetPoint("LEFT", 10 + (index * 170), 0)
    
    -- Tab-Hintergrund
    tab.bg = tab:CreateTexture(nil, "BACKGROUND")
    tab.bg:SetAllPoints()
    tab.bg:SetColorTexture(0.1, 0.2, 0.4, 0.6)
    
    -- Tab-Text
    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tab.text:SetPoint("CENTER")
    tab.text:SetText(text)
    tab.text:SetTextColor(0.8, 0.8, 0.8)
    
    -- Hover-Effekte
    tab:SetScript("OnEnter", function()
        tab.bg:SetColorTexture(0.2, 0.4, 0.8, 0.8)
        tab.text:SetTextColor(1, 1, 1)
    end)
    
    tab:SetScript("OnLeave", function()
        if self.activeTab ~= tab then
            tab.bg:SetColorTexture(0.1, 0.2, 0.4, 0.6)
            tab.text:SetTextColor(0.8, 0.8, 0.8)
        end
    end)
    
    tab:SetScript("OnClick", function()
        self:SetActiveTab(tab)
        onClick()
    end)
    
    return tab
end

--[[
    Setzt den aktiven Tab
]]
function PartyMotivatorUI:SetActiveTab(tab)
    -- Reset alle Tabs
    for _, t in pairs({self.startTab, self.greetTab, self.settingsTab, self.statsTab}) do
        if t and t.bg and t.text then
            t.bg:SetColorTexture(0.1, 0.2, 0.4, 0.6)
            t.text:SetTextColor(0.8, 0.8, 0.8)
        end
    end
    
    -- Aktiviere gewählten Tab
    if tab and tab.bg and tab.text then
        tab.bg:SetColorTexture(0.3, 0.6, 1, 0.9)
        tab.text:SetTextColor(1, 1, 1)
    end
    
    self.activeTab = tab
end

--[[
    Erstellt den Content-Bereich
]]
function PartyMotivatorUI:CreateContentArea()
    self.contentArea = CreateFrame("Frame", nil, self.mainFrame)
    self.contentArea:SetSize(680, 500)
    self.contentArea:SetPoint("TOP", 0, -100)
    
    -- Content-Hintergrund
    local contentBg = self.contentArea:CreateTexture(nil, "BACKGROUND")
    contentBg:SetAllPoints()
    contentBg:SetColorTexture(0.02, 0.02, 0.05, 0.8)
end

--[[
    Zeigt den Start-Sprüche Tab
]]
function PartyMotivatorUI:ShowStartMessagesTab()
    self:ClearContentArea()
    
    -- Titel
    local title = self.contentArea:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("|cffff6600Start-Sprüche|r")
    title:SetTextColor(1, 0.4, 0)
    
    -- Hinzufügen-Bereich
    local addFrame = CreateFrame("Frame", nil, self.contentArea)
    addFrame:SetSize(640, 60)
    addFrame:SetPoint("TOPLEFT", 20, -60)
    
    -- Eingabe-Feld mit schönem Design
    local editBox = CreateFrame("EditBox", nil, addFrame, "InputBoxTemplate")
    editBox:SetSize(450, 25)
    editBox:SetPoint("LEFT", 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetText("")
    
    -- Hinzufügen-Button mit Hover-Effekt
    local addBtn = self:CreateStyledButton(addFrame, "Hinzufügen", 100, 25)
    addBtn:SetPoint("LEFT", editBox, "RIGHT", 15, 0)
    addBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        if text ~= "" then
            if not PartyMotivatorDB.startMessages then
                PartyMotivatorDB.startMessages = {}
            end
            table.insert(PartyMotivatorDB.startMessages, text)
            editBox:SetText("")
            self:UpdateStartMessagesList()
        end
    end)
    
    -- Sprüche-Liste mit ScrollFrame
    self.startMessagesList = CreateFrame("ScrollFrame", nil, self.contentArea, "UIPanelScrollFrameTemplate")
    self.startMessagesList:SetSize(640, 350)
    self.startMessagesList:SetPoint("TOPLEFT", 20, -130)
    
    self.startMessagesContent = CreateFrame("Frame", nil, self.startMessagesList)
    self.startMessagesContent:SetSize(620, 1)
    self.startMessagesList:SetScrollChild(self.startMessagesContent)
    
    -- Update die Liste
    self:UpdateStartMessagesList()
end

--[[
    Zeigt den Begrüßungen Tab
]]
function PartyMotivatorUI:ShowGreetingsTab()
    self:ClearContentArea()
    
    -- Titel
    local title = self.contentArea:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("|cff00ff00Begrüßungen|r")
    title:SetTextColor(0, 1, 0)
    
    -- Hinzufügen-Bereich
    local addFrame = CreateFrame("Frame", nil, self.contentArea)
    addFrame:SetSize(640, 60)
    addFrame:SetPoint("TOPLEFT", 20, -60)
    
    -- Eingabe-Feld
    local editBox = CreateFrame("EditBox", nil, addFrame, "InputBoxTemplate")
    editBox:SetSize(450, 25)
    editBox:SetPoint("LEFT", 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetText("")
    
    -- Hinzufügen-Button
    local addBtn = self:CreateStyledButton(addFrame, "Hinzufügen", 100, 25)
    addBtn:SetPoint("LEFT", editBox, "RIGHT", 15, 0)
    addBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        if text ~= "" then
            if not PartyMotivatorDB.greetMessages then
                PartyMotivatorDB.greetMessages = {}
            end
            table.insert(PartyMotivatorDB.greetMessages, text)
            editBox:SetText("")
            self:UpdateGreetingsList()
        end
    end)
    
    -- Begrüßungen-Liste
    self.greetingsList = CreateFrame("ScrollFrame", nil, self.contentArea, "UIPanelScrollFrameTemplate")
    self.greetingsList:SetSize(640, 350)
    self.greetingsList:SetPoint("TOPLEFT", 20, -130)
    
    self.greetingsContent = CreateFrame("Frame", nil, self.greetingsList)
    self.greetingsContent:SetSize(620, 1)
    self.greetingsList:SetScrollChild(self.greetingsContent)
    
    -- Update die Liste
    self:UpdateGreetingsList()
end

--[[
    Zeigt den Einstellungen Tab
]]
function PartyMotivatorUI:ShowSettingsTab()
    self:ClearContentArea()
    
    -- Titel
    local title = self.contentArea:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("|cff9966ffEinstellungen|r")
    title:SetTextColor(0.6, 0.4, 1)
    
    -- Chat-Kanal Einstellung
    local chatFrame = CreateFrame("Frame", nil, self.contentArea)
    chatFrame:SetSize(640, 50)
    chatFrame:SetPoint("TOPLEFT", 20, -80)
    
    local chatLabel = chatFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatLabel:SetPoint("LEFT", 0, 0)
    chatLabel:SetText("Chat-Kanal für Nachrichten:")
    chatLabel:SetTextColor(0.9, 0.9, 0.9)
    
    local chatCheckbox = CreateFrame("CheckButton", nil, chatFrame, "InterfaceOptionsCheckButtonTemplate")
    chatCheckbox:SetPoint("LEFT", chatLabel, "RIGHT", 15, 0)
    chatCheckbox.Text:SetText("Instanz-Chat statt Party-Chat nutzen")
    chatCheckbox:SetChecked(PartyMotivatorDB.useInstanceChat)
    chatCheckbox:SetScript("OnClick", function()
        PartyMotivatorDB.useInstanceChat = chatCheckbox:GetChecked()
    end)
    
    -- Reset-Button
    local resetBtn = self:CreateStyledButton(self.contentArea, "Auf Standard zurücksetzen", 200, 35)
    resetBtn:SetPoint("TOPLEFT", 20, -150)
    resetBtn:SetScript("OnClick", function()
        -- Lade die Standard-Daten aus der Hauptdatei
        local defaultDB = {
            startMessages = {
                "Let's go!",
                "Auf geht's, wir schaffen das!",
                "Zeit für Action!",
                "Bereit für den Kampf!",
                "Gemeinsam sind wir stark!",
                "Zeit zu glänzen!",
                "Los geht's, Abenteurer!",
                "Ready for battle!",
                "Time to shine!",
                "Let's do this!",
                "We got this!",
                "Time for action!",
                "Let's make it count!",
                "Here we go!",
                "Let's crush this!"
            },
            greetMessages = {
                "Hello!",
                "Hey there!",
                "Welcome!",
                "Nice to meet you!",
                "Hey, welcome aboard!",
                "Hello there!",
                "Welcome to the team!",
                "Hey, good to see you!",
                "Hello, welcome!",
                "Hey, nice to have you!",
                "Hey everyone, welcome aboard!",
                "Hello team! Ready to conquer this place?",
                "Welcome! Let's make this run legendary!",
                "Hi all — great to have you here!",
                "Greetings adventurers! Ready for some fun?"
            }
        }
        
        PartyMotivatorDB.startMessages = CopyTable(defaultDB.startMessages)
        PartyMotivatorDB.greetMessages = CopyTable(defaultDB.greetMessages)
        print("|cff00ff00PartyMotivator|r - Alle Einstellungen auf Standard zurückgesetzt!")
    end)
    
    -- Info-Text
    local infoText = self.contentArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoText:SetPoint("TOPLEFT", 20, -200)
    infoText:SetText("|cff888888Verwende /pm für Chat-Befehle oder /pmui für dieses schöne UI|r")
    infoText:SetTextColor(0.5, 0.5, 0.5)
end

--[[
    Zeigt den Statistiken Tab
]]
function PartyMotivatorUI:ShowStatsTab()
    self:ClearContentArea()
    
    -- Titel
    local title = self.contentArea:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("|cff88ff88Statistiken|r")
    title:SetTextColor(0.5, 1, 0.5)
    
    -- Statistiken anzeigen
    local startCount = #(PartyMotivatorDB.startMessages or {})
    local greetCount = #(PartyMotivatorDB.greetMessages or {})
    
    local statsText = self.contentArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsText:SetPoint("TOPLEFT", 20, -60)
    statsText:SetText(string.format("|cffff6600Start-Sprüche:|r %d\n|cff00ff00Begrüßungen:|r %d\n|cff9966ffChat-Kanal:|r %s", 
        startCount, greetCount, (PartyMotivatorDB.useInstanceChat and "INSTANCE_CHAT" or "PARTY")))
    statsText:SetTextColor(0.9, 0.9, 0.9)
end

--[[
    Erstellt einen schönen Button mit Hover-Effekten
]]
function PartyMotivatorUI:CreateStyledButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, height)
    
    -- Button-Text
    local btnText = btn:GetFontString()
    btnText:SetText(text)
    btnText:SetTextColor(1, 1, 1)
    
    -- Hover-Effekte
    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(0.3, 0.6, 1, 0.8)
        btnText:SetTextColor(1, 1, 0.8)
    end)
    
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(0.2, 0.4, 0.8, 0.6)
        btnText:SetTextColor(1, 1, 1)
    end)
    
    return btn
end

--[[
    Löscht den Content-Bereich
]]
function PartyMotivatorUI:ClearContentArea()
    if self.contentArea then
        local children = {self.contentArea:GetChildren()}
        for i = 1, #children do
            local child = children[i]
            if child then
                child:Hide()
                child:SetParent(nil)
            end
        end
    end
end

--[[
    Aktualisiert die Start-Sprüche Liste
]]
function PartyMotivatorUI:UpdateStartMessagesList()
    if not self.startMessagesContent then return end
    
    -- Lösche alte Einträge
    local children = {self.startMessagesContent:GetChildren()}
    for i = 1, #children do
        local child = children[i]
        if child then
            child:Hide()
            child:SetParent(nil)
        end
    end
    
    local startMessages = PartyMotivatorDB.startMessages or {}
    local yOffset = 0
    
    for i, message in ipairs(startMessages) do
        -- Spruch-Text
        local msgText = self.startMessagesContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        msgText:SetPoint("TOPLEFT", 0, -yOffset)
        msgText:SetText(string.format("|cffffcc00%d.|r %s", i, message))
        msgText:SetWidth(450)
        msgText:SetJustifyH("LEFT")
        
        -- Entfernen-Button
        local removeBtn = self:CreateStyledButton(self.startMessagesContent, "Entfernen", 80, 20)
        removeBtn:SetPoint("LEFT", msgText, "RIGHT", 15, 0)
        removeBtn:SetScript("OnClick", function()
            table.remove(PartyMotivatorDB.startMessages, i)
            self:UpdateStartMessagesList()
        end)
        
        yOffset = yOffset + 30
    end
    
    self.startMessagesContent:SetHeight(math.max(350, yOffset))
end

--[[
    Aktualisiert die Begrüßungen Liste
]]
function PartyMotivatorUI:UpdateGreetingsList()
    if not self.greetingsContent then return end
    
    -- Lösche alte Einträge
    local children = {self.greetingsContent:GetChildren()}
    for i = 1, #children do
        local child = children[i]
        if child then
            child:Hide()
            child:SetParent(nil)
        end
    end
    
    local greetMessages = PartyMotivatorDB.greetMessages or {}
    local yOffset = 0
    
    for i, message in ipairs(greetMessages) do
        -- Spruch-Text
        local msgText = self.greetingsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        msgText:SetPoint("TOPLEFT", 0, -yOffset)
        msgText:SetText(string.format("|cff00ff00%d.|r %s", i, message))
        msgText:SetWidth(450)
        msgText:SetJustifyH("LEFT")
        
        -- Entfernen-Button
        local removeBtn = self:CreateStyledButton(self.greetingsContent, "Entfernen", 80, 20)
        removeBtn:SetPoint("LEFT", msgText, "RIGHT", 15, 0)
        removeBtn:SetScript("OnClick", function()
            table.remove(PartyMotivatorDB.greetMessages, i)
            self:UpdateGreetingsList()
        end)
        
        yOffset = yOffset + 30
    end
    
    self.greetingsContent:SetHeight(math.max(350, yOffset))
end

--[[
    Fügt Animationen hinzu
]]
function PartyMotivatorUI:AddAnimations()
    -- Fade-In Animation beim Öffnen
    self.mainFrame.fadeIn = self.mainFrame:CreateAnimationGroup()
    local fadeIn = self.mainFrame.fadeIn:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.3)
    
    -- Fade-Out Animation beim Schließen
    self.mainFrame.fadeOut = self.mainFrame:CreateAnimationGroup()
    local fadeOut = self.mainFrame.fadeOut:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.2)
    
    fadeOut:SetScript("OnFinished", function()
        self.mainFrame:Hide()
    end)
end

--[[
    Öffnet das UI
]]
function PartyMotivatorUI:ShowUI()
    if not self.mainFrame then
        self:CreateMainFrame()
    end
    
    self.mainFrame:Show()
    self.mainFrame:SetAlpha(0)
    self.mainFrame.fadeIn:Play()
    
    -- Setze aktiven Tab
    self:SetActiveTab(self.startTab)
    self:ShowStartMessagesTab()
end

--[[
    Schließt das UI
]]
function PartyMotivatorUI:CloseUI()
    self.mainFrame.fadeOut:Play()
end

--[[
    Initialisiert das UI
]]
function PartyMotivatorUI:Initialize()
    -- Erstelle das UI beim ersten Aufruf
    self:CreateMainFrame()
end
