--[[
    PartyMotivator - World of Warcraft Addon
    Sendet motivierende Sprüche beim Dungeon-Start und begrüßt neue Gruppenmitglieder
    Erweitert um Mythic-Plus-Unterstützung und Options-Panel
]]

-- Erstelle das Haupt-Event-Frame für das Addon
local PM = CreateFrame("Frame")

-- Globale Variablen für das Addon
local addonName = "PartyMotivator"
PM.lastGroupSize = 0

-- Standard-Datenbank für das Addon
local defaultDB = {
    -- Standard motivierende Sprüche für Dungeon-Start
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
    -- Begrüßungsnachrichten für neue Gruppenmitglieder
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
    },
    -- Option für Chat-Kanal (true = INSTANCE_CHAT, false = PARTY)
    useInstanceChat = true
}

--[[
    Initialisiert die Standard-Datenbank für das Addon
    Diese Funktion wird beim Laden des Addons aufgerufen
]]
local function initializeDatabase()
    if not PartyMotivatorDB then
        PartyMotivatorDB = {}
    end
    
    -- Prüfe, ob die Datenbank leer ist oder nur alte Daten hat
    local needsUpdate = false
    
    -- Prüfe Start-Sprüche
    if not PartyMotivatorDB.startMessages or type(PartyMotivatorDB.startMessages) ~= "table" or #PartyMotivatorDB.startMessages < 10 then
        PartyMotivatorDB.startMessages = CopyTable(defaultDB.startMessages)
        needsUpdate = true
    end
    
    -- Prüfe Begrüßungen
    if not PartyMotivatorDB.greetMessages or type(PartyMotivatorDB.greetMessages) ~= "table" or #PartyMotivatorDB.greetMessages < 10 then
        PartyMotivatorDB.greetMessages = CopyTable(defaultDB.greetMessages)
        needsUpdate = true
    end
    
    -- Prüfe Chat-Einstellung
    if type(PartyMotivatorDB.useInstanceChat) ~= "boolean" then
        PartyMotivatorDB.useInstanceChat = defaultDB.useInstanceChat
        needsUpdate = true
    end
    
    -- Debug-Ausgabe
    if needsUpdate then
        print("|cff00ff00PartyMotivator|r - Datenbank aktualisiert mit neuen Sprüchen!")
    end
    print(string.format("|cff00ff00PartyMotivator|r - Datenbank initialisiert: %d Start-Sprüche, %d Begrüßungen", 
        #PartyMotivatorDB.startMessages, #PartyMotivatorDB.greetMessages))
end

--[[
    Sendet eine zufällige motivierende Nachricht beim Dungeon-Start
    Diese Funktion wird aufgerufen, wenn der Spieler eine Instanz betritt
]]
local function sendMotivationalMessage()
    local messages = PartyMotivatorDB.startMessages or {}
    if #messages == 0 then
        return
    end
    
    local randomIndex = math.random(1, #messages)
    local selectedMessage = messages[randomIndex]
    
    -- Wähle den Chat-Kanal basierend auf der Einstellung
    local chatType = (PartyMotivatorDB.useInstanceChat == true) and "INSTANCE_CHAT" or "PARTY"
    
    -- Sende die Nachricht über die moderne API
    C_ChatInfo.SendChatMessage(selectedMessage, chatType)
end

--[[
    Sendet eine Begrüßungsnachricht an neue Gruppenmitglieder
    Diese Funktion wird aufgerufen, wenn sich die Gruppenzusammensetzung ändert
]]
local function greetNewMembers()
    local greetings = PartyMotivatorDB.greetMessages or {}
    if #greetings == 0 then
        return
    end
    
    local currentGroupSize = GetNumGroupMembers()
    
    -- Prüfe, ob die Gruppengröße gestiegen ist (neue Mitglieder)
    if currentGroupSize > PM.lastGroupSize and currentGroupSize > 1 then
        -- Wähle eine zufällige Begrüßung aus der Liste
        local randomIndex = math.random(1, #greetings)
        local selectedGreeting = greetings[randomIndex]
        
        C_ChatInfo.SendChatMessage(selectedGreeting, "PARTY")
    end
    
    -- Aktualisiere die gespeicherte Gruppengröße
    PM.lastGroupSize = currentGroupSize
end

--[[
    Slash-Command Handler für /pm
    Ermöglicht die Konfiguration des Addons über Chat-Befehle
]]
local function handleSlashCommand(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end
    
    if #args == 0 then
        print("|cff00ff00PartyMotivator|r - Verfügbare Befehle:")
        print("|cffffffff/pm list|r - Zeige alle Sprüche an")
        print("|cffffffff/pm add <spruch>|r - Füge einen neuen Spruch hinzu")
        print("|cffffffff/pm remove <nummer>|r - Entferne einen Spruch")
        print("|cffffffff/pm chat|r - Wechsle zwischen INSTANCE_CHAT und PARTY")
        print("|cffffffff/pm greet add <nachricht>|r - Füge eine neue Begrüßung hinzu")
        print("|cffffffff/pm greet remove <nummer>|r - Entferne eine Begrüßung")
        print("|cffffffff/pm reset|r - Setze Sprüche auf Standard zurück")
        print("|cffffffff/pmoptions|r oder |cffffffff/pmui|r - Öffne das schöne UI")
        return
    end
    
    local command = args[1]:lower()
    
    if command == "list" then
        print("|cff00ff00PartyMotivator|r - Aktuelle Sprüche:")
        for i, message in ipairs(PartyMotivatorDB.startMessages or {}) do
            print(string.format("|cffffffff%d.|r %s", i, message))
        end
        print("|cff00ff00PartyMotivator|r - Begrüßungen:")
        for i, message in ipairs(PartyMotivatorDB.greetMessages or {}) do
            print(string.format("|cffffffff%d.|r %s", i, message))
        end
        print(string.format("|cffffffffChat-Kanal:|r %s", (PartyMotivatorDB.useInstanceChat == true) and "INSTANCE_CHAT" or "PARTY"))
        
    elseif command == "add" then
        if #args < 2 then
            print("|cffff0000Fehler:|r Bitte gib einen Spruch an: /pm add <spruch>")
            return
        end
        
        local newMessage = table.concat(args, " ", 2)
        if not PartyMotivatorDB.startMessages then
            PartyMotivatorDB.startMessages = {}
        end
        table.insert(PartyMotivatorDB.startMessages, newMessage)
        print(string.format("|cff00ff00PartyMotivator|r - Spruch hinzugefügt: %s", newMessage))
        print(string.format("|cff00ff00PartyMotivator|r - Aktuell %d Start-Sprüche gespeichert", #PartyMotivatorDB.startMessages))
        
    elseif command == "remove" then
        if #args < 2 then
            print("|cffff0000Fehler:|r Bitte gib eine Nummer an: /pm remove <nummer>")
            return
        end
        
        local messages = PartyMotivatorDB.startMessages or {}
        local index = tonumber(args[2])
        if not index or index < 1 or index > #messages then
            print("|cffff0000Fehler:|r Ungültige Nummer")
            return
        end
        
        local removedMessage = table.remove(messages, index)
        print(string.format("|cff00ff00PartyMotivator|r - Spruch entfernt: %s", removedMessage))
        print(string.format("|cff00ff00PartyMotivator|r - Aktuell %d Start-Sprüche gespeichert", #messages))
        
    elseif command == "chat" then
        PartyMotivatorDB.useInstanceChat = not PartyMotivatorDB.useInstanceChat
        local chatType = PartyMotivatorDB.useInstanceChat and "INSTANCE_CHAT" or "PARTY"
        print(string.format("|cff00ff00PartyMotivator|r - Chat-Kanal geändert zu: %s", chatType))
        
    elseif command == "greet" then
        if #args < 3 then
            print("|cffff0000Fehler:|r Bitte gib einen Befehl an: /pm greet add <nachricht> oder /pm greet remove <nummer>")
            return
        end
        
        local subCommand = args[2]:lower()
        
        if subCommand == "add" then
            if #args < 3 then
                print("|cffff0000Fehler:|r Bitte gib eine Nachricht an: /pm greet add <nachricht>")
                return
            end
            
            local newGreeting = table.concat(args, " ", 3)
            if not PartyMotivatorDB.greetMessages then
                PartyMotivatorDB.greetMessages = {}
            end
            table.insert(PartyMotivatorDB.greetMessages, newGreeting)
            print(string.format("|cff00ff00PartyMotivator|r - Begrüßung hinzugefügt: %s", newGreeting))
            print(string.format("|cff00ff00PartyMotivator|r - Aktuell %d Begrüßungen gespeichert", #PartyMotivatorDB.greetMessages))
            
        elseif subCommand == "remove" then
            if #args < 3 then
                print("|cffff0000Fehler:|r Bitte gib eine Nummer an: /pm greet remove <nummer>")
                return
            end
            
            local greetings = PartyMotivatorDB.greetMessages or {}
            local index = tonumber(args[3])
            if not index or index < 1 or index > #greetings then
                print("|cffff0000Fehler:|r Ungültige Nummer")
                return
            end
            
            local removedGreeting = table.remove(greetings, index)
            print(string.format("|cff00ff00PartyMotivator|r - Begrüßung entfernt: %s", removedGreeting))
            print(string.format("|cff00ff00PartyMotivator|r - Aktuell %d Begrüßungen gespeichert", #greetings))
            
        else
            print("|cffff0000Fehler:|r Unbekannter Befehl. Verwende 'add' oder 'remove'")
        end
        
    elseif command == "reset" then
        -- Setze Sprüche auf Standard zurück
        PartyMotivatorDB.startMessages = CopyTable(defaultDB.startMessages)
        PartyMotivatorDB.greetMessages = CopyTable(defaultDB.greetMessages)
        print("|cff00ff00PartyMotivator|r - Sprüche auf Standard zurückgesetzt!")
        print(string.format("|cff00ff00PartyMotivator|r - %d Start-Sprüche, %d Begrüßungen geladen", 
            #PartyMotivatorDB.startMessages, #PartyMotivatorDB.greetMessages))
        
    else
        print("|cffff0000Fehler:|r Unbekannter Befehl. Verwende /pm für Hilfe.")
    end
end

-- Event-Handler Funktion
local function onEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            -- Initialisiere die Datenbank beim Laden des Addons
            initializeDatabase()
            -- Initialisiere das Options-Panel
            PM:InitializeOptions()
            print("|cff00ff00PartyMotivator|r - Addon geladen! Verwende /pm oder /pmoptions für Optionen.")
        end
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Prüfe, ob der Spieler sich in einer 5-Spieler-Instanz befindet
        local isInInstance, instanceType = IsInInstance()
        if isInInstance and instanceType == "party" then
            -- Sende eine motivierende Nachricht beim Betreten des Dungeons
            sendMotivationalMessage()
        end
        
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Begrüße neue Gruppenmitglieder
        greetNewMembers()
        
    elseif event == "CHALLENGE_MODE_START" then
        -- Mythic-Plus-Run beginnt -> zufälligen Spruch senden
        local mapID = ...
        local msgs = PartyMotivatorDB.startMessages
        local msg = msgs[math.random(#msgs)]
        local channel = PartyMotivatorDB.useInstanceChat and "INSTANCE_CHAT" or "PARTY"
        C_ChatInfo.SendChatMessage(msg, channel)
    end
end

-- Registriere die Events
PM:RegisterEvent("ADDON_LOADED")
PM:RegisterEvent("PLAYER_ENTERING_WORLD")
PM:RegisterEvent("GROUP_ROSTER_UPDATE")
PM:RegisterEvent("CHALLENGE_MODE_START")

-- Setze den Event-Handler
PM:SetScript("OnEvent", onEvent)

--[[
    Erstellt ein schönes, eigenes UI für PartyMotivator
    Moderne Optik mit Animationen und besserem Layout
]]
function PM:CreateCustomUI()
    -- Hauptfenster
    self.mainFrame = CreateFrame("Frame", "PartyMotivatorMainFrame", UIParent)
    self.mainFrame:SetSize(600, 500)
    self.mainFrame:SetPoint("CENTER")
    self.mainFrame:SetFrameStrata("DIALOG")
    self.mainFrame:SetFrameLevel(100)
    self.mainFrame:Hide()
    
    -- Hintergrund mit schönem Design
    local bg = self.mainFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.2, 0.95)
    
    -- Rahmen
    local border = self.mainFrame:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetColorTexture(0.3, 0.3, 0.6, 1)
    
    -- Titel-Bar
    local titleBar = CreateFrame("Frame", nil, self.mainFrame)
    titleBar:SetSize(600, 40)
    titleBar:SetPoint("TOP")
    titleBar:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Header",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    
    -- Titel-Text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("CENTER")
    titleText:SetText("|cff00ff00Party|r|cffff6600Motivator|r")
    titleText:SetTextColor(1, 1, 1)
    
    -- Schließen-Button
    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        self.mainFrame:Hide()
    end)
    
    -- Tab-System
    self:CreateTabs()
    
    -- Content-Bereich
    self.contentArea = CreateFrame("Frame", nil, self.mainFrame)
    self.contentArea:SetSize(580, 420)
    self.contentArea:SetPoint("TOP", 0, -50)
    
    -- Initiale Anzeige
    self:ShowStartMessagesTab()
end

--[[
    Erstellt das Tab-System für verschiedene Bereiche
]]
function PM:CreateTabs()
    self.tabFrame = CreateFrame("Frame", nil, self.mainFrame)
    self.tabFrame:SetSize(580, 30)
    self.tabFrame:SetPoint("TOP", 0, -45)
    
    -- Start-Sprüche Tab
    self.startTab = CreateFrame("Button", nil, self.tabFrame)
    self.startTab:SetSize(120, 25)
    self.startTab:SetPoint("LEFT", 10, 0)
    self.startTab:SetText("Start-Sprüche")
    self.startTab:SetNormalFontObject("GameFontNormal")
    self.startTab:SetHighlightFontObject("GameFontHighlight")
    self.startTab:SetScript("OnClick", function()
        self:ShowStartMessagesTab()
    end)
    
    -- Begrüßungen Tab
    self.greetTab = CreateFrame("Button", nil, self.tabFrame)
    self.greetTab:SetSize(120, 25)
    self.greetTab:SetPoint("LEFT", self.startTab, "RIGHT", 5, 0)
    self.greetTab:SetText("Begrüßungen")
    self.greetTab:SetNormalFontObject("GameFontNormal")
    self.greetTab:SetHighlightFontObject("GameFontHighlight")
    self.greetTab:SetScript("OnClick", function()
        self:ShowGreetingsTab()
    end)
    
    -- Einstellungen Tab
    self.settingsTab = CreateFrame("Button", nil, self.tabFrame)
    self.settingsTab:SetSize(120, 25)
    self.settingsTab:SetPoint("LEFT", self.greetTab, "RIGHT", 5, 0)
    self.settingsTab:SetText("Einstellungen")
    self.settingsTab:SetNormalFontObject("GameFontNormal")
    self.settingsTab:SetHighlightFontObject("GameFontHighlight")
    self.settingsTab:SetScript("OnClick", function()
        self:ShowSettingsTab()
    end)
end

--[[
    Zeigt den Start-Sprüche Tab
]]
function PM:ShowStartMessagesTab()
    -- Lösche vorherigen Content
    self:ClearContentArea()
    
    -- Titel
    local title = self.contentArea:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("|cffff6600Start-Sprüche|r")
    title:SetTextColor(1, 0.4, 0)
    
    -- Hinzufügen-Bereich
    local addFrame = CreateFrame("Frame", nil, self.contentArea)
    addFrame:SetSize(560, 60)
    addFrame:SetPoint("TOPLEFT", 20, -60)
    
    -- Eingabe-Feld
    local editBox = CreateFrame("EditBox", nil, addFrame, "InputBoxTemplate")
    editBox:SetSize(400, 25)
    editBox:SetPoint("LEFT", 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetText("")
    
    -- Hinzufügen-Button
    local addBtn = CreateFrame("Button", nil, addFrame, "UIPanelButtonTemplate")
    addBtn:SetSize(100, 25)
    addBtn:SetPoint("LEFT", editBox, "RIGHT", 10, 0)
    addBtn:SetText("Hinzufügen")
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
    
    -- Sprüche-Liste
    self.startMessagesList = CreateFrame("ScrollFrame", nil, self.contentArea, "UIPanelScrollFrameTemplate")
    self.startMessagesList:SetSize(560, 300)
    self.startMessagesList:SetPoint("TOPLEFT", 20, -130)
    
    self.startMessagesContent = CreateFrame("Frame", nil, self.startMessagesList)
    self.startMessagesContent:SetSize(540, 1)
    self.startMessagesList:SetScrollChild(self.startMessagesContent)
    
    -- Update die Liste
    self:UpdateStartMessagesList()
end

--[[
    Zeigt den Begrüßungen Tab
]]
function PM:ShowGreetingsTab()
    -- Lösche vorherigen Content
    self:ClearContentArea()
    
    -- Titel
    local title = self.contentArea:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("|cff00ff00Begrüßungen|r")
    title:SetTextColor(0, 1, 0)
    
    -- Hinzufügen-Bereich
    local addFrame = CreateFrame("Frame", nil, self.contentArea)
    addFrame:SetSize(560, 60)
    addFrame:SetPoint("TOPLEFT", 20, -60)
    
    -- Eingabe-Feld
    local editBox = CreateFrame("EditBox", nil, addFrame, "InputBoxTemplate")
    editBox:SetSize(400, 25)
    editBox:SetPoint("LEFT", 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetText("")
    
    -- Hinzufügen-Button
    local addBtn = CreateFrame("Button", nil, addFrame, "UIPanelButtonTemplate")
    addBtn:SetSize(100, 25)
    addBtn:SetPoint("LEFT", editBox, "RIGHT", 10, 0)
    addBtn:SetText("Hinzufügen")
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
    self.greetingsList:SetSize(560, 300)
    self.greetingsList:SetPoint("TOPLEFT", 20, -130)
    
    self.greetingsContent = CreateFrame("Frame", nil, self.greetingsList)
    self.greetingsContent:SetSize(540, 1)
    self.greetingsList:SetScrollChild(self.greetingsContent)
    
    -- Update die Liste
    self:UpdateGreetingsList()
end

--[[
    Zeigt den Einstellungen Tab
]]
function PM:ShowSettingsTab()
    -- Lösche vorherigen Content
    self:ClearContentArea()
    
    -- Titel
    local title = self.contentArea:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("|cff9966ffEinstellungen|r")
    title:SetTextColor(0.6, 0.4, 1)
    
    -- Chat-Kanal Einstellung
    local chatFrame = CreateFrame("Frame", nil, self.contentArea)
    chatFrame:SetSize(560, 40)
    chatFrame:SetPoint("TOPLEFT", 20, -60)
    
    local chatLabel = chatFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatLabel:SetPoint("LEFT", 0, 0)
    chatLabel:SetText("Chat-Kanal für Nachrichten:")
    
    local chatCheckbox = CreateFrame("CheckButton", nil, chatFrame, "InterfaceOptionsCheckButtonTemplate")
    chatCheckbox:SetPoint("LEFT", chatLabel, "RIGHT", 10, 0)
    chatCheckbox.Text:SetText("Instanz-Chat statt Party-Chat nutzen")
    chatCheckbox:SetChecked(PartyMotivatorDB.useInstanceChat)
    chatCheckbox:SetScript("OnClick", function()
        PartyMotivatorDB.useInstanceChat = chatCheckbox:GetChecked()
    end)
    
    -- Reset-Button
    local resetBtn = CreateFrame("Button", nil, self.contentArea, "UIPanelButtonTemplate")
    resetBtn:SetSize(150, 30)
    resetBtn:SetPoint("TOPLEFT", 20, -120)
    resetBtn:SetText("Auf Standard zurücksetzen")
    resetBtn:SetScript("OnClick", function()
        PartyMotivatorDB.startMessages = CopyTable(defaultDB.startMessages)
        PartyMotivatorDB.greetMessages = CopyTable(defaultDB.greetMessages)
        print("|cff00ff00PartyMotivator|r - Alle Einstellungen auf Standard zurückgesetzt!")
    end)
    
    -- Info-Text
    local infoText = self.contentArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoText:SetPoint("TOPLEFT", 20, -170)
    infoText:SetText("|cffccccccVerwende /pm für Chat-Befehle oder /pmoptions für dieses UI|r")
    infoText:SetTextColor(0.8, 0.8, 0.8)
end

--[[
    Löscht den Content-Bereich
]]
function PM:ClearContentArea()
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
function PM:UpdateStartMessagesList()
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
        msgText:SetWidth(400)
        msgText:SetJustifyH("LEFT")
        
        -- Entfernen-Button
        local removeBtn = CreateFrame("Button", nil, self.startMessagesContent, "UIPanelButtonTemplate")
        removeBtn:SetSize(80, 20)
        removeBtn:SetPoint("LEFT", msgText, "RIGHT", 10, 0)
        removeBtn:SetText("Entfernen")
        removeBtn:SetScript("OnClick", function()
            table.remove(PartyMotivatorDB.startMessages, i)
            self:UpdateStartMessagesList()
        end)
        
        yOffset = yOffset + 25
    end
    
    self.startMessagesContent:SetHeight(math.max(300, yOffset))
end

--[[
    Aktualisiert die Begrüßungen Liste
]]
function PM:UpdateGreetingsList()
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
        msgText:SetWidth(400)
        msgText:SetJustifyH("LEFT")
        
        -- Entfernen-Button
        local removeBtn = CreateFrame("Button", nil, self.greetingsContent, "UIPanelButtonTemplate")
        removeBtn:SetSize(80, 20)
        removeBtn:SetPoint("LEFT", msgText, "RIGHT", 10, 0)
        removeBtn:SetText("Entfernen")
        removeBtn:SetScript("OnClick", function()
            table.remove(PartyMotivatorDB.greetMessages, i)
            self:UpdateGreetingsList()
        end)
        
        yOffset = yOffset + 25
    end
    
    self.greetingsContent:SetHeight(math.max(300, yOffset))
end

--[[
    Initialisiert das Options-Panel für das Interface-Menü (für Kompatibilität)
]]
function PM:InitializeOptions()
    -- Erstelle das schöne UI
    self:CreateCustomUI()
    
    -- Erstelle auch das Standard-Panel für Kompatibilität
    self.optionsPanel = CreateFrame("Frame")
    self.optionsPanel.name = "PartyMotivator"
    
    -- Panel mit neuer Settings-API registrieren
    local category = Settings.RegisterCanvasLayoutCategory(self.optionsPanel, self.optionsPanel.name)
    category.ID = self.optionsPanel.name
    Settings.RegisterAddOnCategory(category)
    self.settingsCategory = category
end

--[[
    Aktualisiert die Anzeige im Options-Panel
    Zeigt Anzahl der Sprüche und erstellt die Sprüche-Liste
]]
function PM:UpdateOptionsDisplay()
    if not self.optionsPanel then return end
    
    local startMessages = PartyMotivatorDB.startMessages or {}
    local greetMessages = PartyMotivatorDB.greetMessages or {}
    
    -- Aktualisiere Anzahl-Text
    self.countText:SetText(string.format("Start-Sprüche: %d | Begrüßungen: %d", #startMessages, #greetMessages))
    
    -- Debug-Ausgabe
    print(string.format("|cff00ff00PartyMotivator|r - UI Update: %d Start-Sprüche, %d Begrüßungen", #startMessages, #greetMessages))
    
    -- Lösche alte Sprüche-Anzeige komplett
    if self.contentFrame then
        -- Alle Kinder des Content-Frames löschen
        local children = {self.contentFrame:GetChildren()}
        for i = 1, #children do
            local child = children[i]
            if child then
                child:Hide()
                child:SetParent(nil)
            end
        end
    end
    
    -- Erstelle neue Sprüche-Anzeige
    local yOffset = 0
    
    -- Start-Sprüche Label
    local startLabel = self.contentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    startLabel:SetPoint("TOPLEFT", 0, -yOffset)
    startLabel:SetText("Start-Sprüche:")
    startLabel:SetTextColor(1, 1, 0)
    yOffset = yOffset + 25
    
    -- Start-Sprüche anzeigen
    for i, message in ipairs(startMessages) do
        -- Spruch-Text
        local msgText = self.contentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        msgText:SetPoint("TOPLEFT", 0, -yOffset)
        msgText:SetText(string.format("%d. %s", i, message))
        msgText:SetWidth(300)
        msgText:SetJustifyH("LEFT")
        
        -- Entfernen-Button
        local removeBtn = CreateFrame("Button", nil, self.contentFrame, "UIPanelButtonTemplate")
        removeBtn:SetPoint("LEFT", msgText, "RIGHT", 10, 0)
        removeBtn:SetSize(60, 20)
        removeBtn:SetText("Entfernen")
        removeBtn:SetScript("OnClick", function()
            table.remove(PartyMotivatorDB.startMessages, i)
            self:UpdateOptionsDisplay()
        end)
        
        yOffset = yOffset + 25
    end
    
    -- Begrüßungen Label
    yOffset = yOffset + 10
    local greetLabel = self.contentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    greetLabel:SetPoint("TOPLEFT", 0, -yOffset)
    greetLabel:SetText("Begrüßungen:")
    greetLabel:SetTextColor(0, 1, 1)
    yOffset = yOffset + 25
    
    -- Begrüßungen anzeigen
    for i, message in ipairs(greetMessages) do
        -- Spruch-Text
        local msgText = self.contentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        msgText:SetPoint("TOPLEFT", 0, -yOffset)
        msgText:SetText(string.format("%d. %s", i, message))
        msgText:SetWidth(300)
        msgText:SetJustifyH("LEFT")
        
        -- Entfernen-Button
        local removeBtn = CreateFrame("Button", nil, self.contentFrame, "UIPanelButtonTemplate")
        removeBtn:SetPoint("LEFT", msgText, "RIGHT", 10, 0)
        removeBtn:SetSize(60, 20)
        removeBtn:SetText("Entfernen")
        removeBtn:SetScript("OnClick", function()
            table.remove(PartyMotivatorDB.greetMessages, i)
            self:UpdateOptionsDisplay()
        end)
        
        yOffset = yOffset + 25
    end
    
    -- Aktualisiere Content-Frame Größe
    self.contentFrame:SetHeight(math.max(200, yOffset))
end

-- Registriere die Slash-Commands
SLASH_PARTYMOTIVATOR1 = "/pm"
SlashCmdList["PARTYMOTIVATOR"] = handleSlashCommand

SLASH_PMOPTIONS1 = "/pmoptions"
SlashCmdList["PMOPTIONS"] = function()
    if PM.mainFrame then
        -- Öffne das schöne Custom UI
        PM.mainFrame:Show()
    elseif PM.optionsPanel and PM.optionsPanel.name then
        -- Fallback: Öffne das Standard-Panel
        Settings.OpenToCategory(PM.optionsPanel.name)
    end
end

-- Zusätzlicher Slash-Command für das schöne UI
SLASH_PARTYMOTIVATORUI1 = "/pmui"
SlashCmdList["PARTYMOTIVATORUI"] = function()
    if PM.mainFrame then
        PM.mainFrame:Show()
    end
end

--[[
    ERKLÄRUNG DER EVENTS:
    
    ADDON_LOADED: Wird ausgelöst, wenn ein Addon vollständig geladen wurde.
    Hier initialisieren wir die Datenbank, das Options-Panel und zeigen eine Bestätigung an.
    
    PLAYER_ENTERING_WORLD: Wird ausgelöst, wenn der Spieler die Welt betritt
    oder eine neue Zone/Instanz betritt. Hier prüfen wir, ob wir uns in einem
    5-Spieler-Dungeon befinden und senden eine motivierende Nachricht.
    
    GROUP_ROSTER_UPDATE: Wird ausgelöst, wenn sich die Gruppenzusammensetzung
    ändert (Spieler treten bei oder verlassen die Gruppe). Hier begrüßen wir
    neue Mitglieder und aktualisieren die Gruppengröße.
    
    CHALLENGE_MODE_START: Wird ausgelöst, wenn ein Mythic-Plus-Run beginnt
    (Keystone wird aktiviert und Countdown endet). Hier senden wir eine
    motivierende Nachricht für den Mythic-Plus-Start.
    
    SLASH-COMMANDS:
    /pm - Zeigt alle verfügbaren Chat-Befehle an
    /pmoptions - Öffnet das Options-Panel im Interface-Menü
]]
