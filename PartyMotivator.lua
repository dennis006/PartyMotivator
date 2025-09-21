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
    
    -- Stelle sicher, dass alle erforderlichen Tabellen existieren
    PartyMotivatorDB.startMessages = PartyMotivatorDB.startMessages or CopyTable(defaultDB.startMessages)
    PartyMotivatorDB.greetMessages = PartyMotivatorDB.greetMessages or CopyTable(defaultDB.greetMessages)
    PartyMotivatorDB.useInstanceChat = (PartyMotivatorDB.useInstanceChat ~= nil) and PartyMotivatorDB.useInstanceChat or defaultDB.useInstanceChat
    
    -- Zusätzliche Sicherheitsprüfung für Tabellen
    if type(PartyMotivatorDB.startMessages) ~= "table" then
        PartyMotivatorDB.startMessages = CopyTable(defaultDB.startMessages)
    end
    if type(PartyMotivatorDB.greetMessages) ~= "table" then
        PartyMotivatorDB.greetMessages = CopyTable(defaultDB.greetMessages)
    end
    
    -- Debug-Ausgabe
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
    Initialisiert das Options-Panel für das Interface-Menü
    Erstellt Checkbox, EditBox, Button und Sprüche-Liste
]]
function PM:InitializeOptions()
    -- Hauptpanel
    self.optionsPanel = CreateFrame("Frame")
    self.optionsPanel.name = "PartyMotivator"
    
    -- Titel
    local title = self.optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("PartyMotivator Einstellungen")
    
    -- Checkbox: Instanz-Chat
    local cb = CreateFrame("CheckButton", nil, self.optionsPanel, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -30)
    cb.Text:SetText("Instanz-Chat statt Party-Chat nutzen")
    cb:SetChecked(PartyMotivatorDB.useInstanceChat)
    cb:HookScript("OnClick", function()
        PartyMotivatorDB.useInstanceChat = cb:GetChecked()
    end)
    
    -- Eingabe-Feld für neue Sprüche
    local eb = CreateFrame("EditBox", nil, self.optionsPanel, "InputBoxTemplate")
    eb:SetSize(300, 20)
    eb:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 0, -40)
    eb:SetAutoFocus(false)
    eb:SetText("")
    
    -- Label für EditBox
    local ebLabel = self.optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ebLabel:SetPoint("BOTTOMLEFT", eb, "TOPLEFT", 0, 5)
    ebLabel:SetText("Neuen Spruch hinzufügen:")
    
    -- Button "Hinzufügen"
    local addBtn = CreateFrame("Button", nil, self.optionsPanel, "UIPanelButtonTemplate")
    addBtn:SetPoint("LEFT", eb, "RIGHT", 10, 0)
    addBtn:SetText("Hinzufügen")
    addBtn:SetScript("OnClick", function()
        local text = eb:GetText()
        if text ~= "" then
            -- Stelle sicher, dass die Tabelle existiert
            if not PartyMotivatorDB.startMessages then
                PartyMotivatorDB.startMessages = {}
            end
            table.insert(PartyMotivatorDB.startMessages, text)
            eb:SetText("")
            -- Aktualisiere die Anzeige
            PM:UpdateOptionsDisplay()
        end
    end)
    
    -- Anzeige der Anzahl gespeicherter Sprüche
    self.countText = self.optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.countText:SetPoint("TOPLEFT", eb, "BOTTOMLEFT", 0, -30)
    
    -- ScrollFrame für Sprüche-Liste
    local scrollFrame = CreateFrame("ScrollFrame", nil, self.optionsPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", self.countText, "BOTTOMLEFT", 0, -20)
    scrollFrame:SetSize(400, 200)
    
    -- Content-Frame für die Sprüche
    self.contentFrame = CreateFrame("Frame", nil, scrollFrame)
    self.contentFrame:SetSize(380, 1)
    scrollFrame:SetScrollChild(self.contentFrame)
    
    -- Slider für ScrollFrame
    local slider = scrollFrame.ScrollBar
    slider:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, -16)
    slider:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 16)
    
    -- Label für Sprüche-Liste
    local listLabel = self.optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    listLabel:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", 0, 5)
    listLabel:SetText("Gespeicherte Sprüche:")
    
    -- Panel mit neuer Settings-API registrieren
    local category = Settings.RegisterCanvasLayoutCategory(self.optionsPanel, self.optionsPanel.name)
    category.ID = self.optionsPanel.name   -- wichtig für das spätere Öffnen
    Settings.RegisterAddOnCategory(category)
    self.settingsCategory = category       -- speichere die Kategorie, falls benötigt
    
    -- Initiale Anzeige aktualisieren
    self:UpdateOptionsDisplay()
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
    if PM.optionsPanel and PM.optionsPanel.name then
        -- Öffnet das Panel über den Namen der Kategorie
        Settings.OpenToCategory(PM.optionsPanel.name)
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
