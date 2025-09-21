# PartyMotivator

Ein World of Warcraft Addon, das automatisch motivierende Sprüche beim Betreten von Dungeons und Mythic-Plus-Runs sendet und neue Gruppenmitglieder begrüßt.

## Features

- **Automatische Motivationssprüche** beim Betreten von 5-Spieler-Dungeons
- **Mythic-Plus-Unterstützung** mit Sprüchen beim Keystone-Start
- **Begrüßung neuer Gruppenmitglieder** mit zufälligen Nachrichten
- **Anpassbare Sprüche** über Chat-Befehle oder Options-Panel
- **Chat-Kanal-Auswahl** zwischen INSTANCE_CHAT und PARTY
- **Moderne Settings-API** für The War Within

## Installation

1. Lade die neueste Version von [GitHub Releases](https://github.com/xMethface/PartyMotivator/releases) herunter
2. Entpacke die Dateien in dein WoW AddOns-Verzeichnis:
   - Windows: `World of Warcraft\_retail_\Interface\AddOns\`
   - Mac: `Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Starte WoW neu oder verwende `/reload`

## Verwendung

### Chat-Befehle

- `/pm` - Zeigt alle verfügbaren Befehle an
- `/pm list` - Zeigt alle gespeicherten Sprüche und Begrüßungen an
- `/pm add <spruch>` - Fügt einen neuen Spruch hinzu
- `/pm remove <nummer>` - Entfernt einen Spruch
- `/pm greet add <nachricht>` - Fügt eine neue Begrüßung hinzu
- `/pm greet remove <nummer>` - Entfernt eine Begrüßung
- `/pm chat` - Wechselt zwischen INSTANCE_CHAT und PARTY
- `/pmoptions` - Öffnet das Options-Panel

### Options-Panel

Das Addon fügt sich automatisch in das Interface-Menü ein:
- Interface → AddOns → PartyMotivator

Hier kannst du:
- Chat-Kanal umschalten
- Neue Sprüche hinzufügen
- Bestehende Sprüche anzeigen und entfernen
- Anzahl der gespeicherten Sprüche sehen

## Kompatibilität

- **WoW-Version:** The War Within (Interface 120000)
- **Sprachen:** Deutsch, Englisch
- **Addon-Manager:** WoWUp, CurseForge, etc.

## Standard-Sprüche

Das Addon kommt mit 15 vordefinierten motivierenden Sprüchen und 15 Begrüßungsnachrichten in deutscher und englischer Sprache.

## Entwicklung

### Repository-Struktur
```
PartyMotivator/
├── PartyMotivator.toc    # Addon-Metadaten
├── PartyMotivator.lua    # Haupt-Logik
├── README.md             # Diese Datei
└── .gitignore           # Git-Ignore-Datei
```

### Beitragen

1. Forke das Repository
2. Erstelle einen Feature-Branch
3. Committe deine Änderungen
4. Erstelle einen Pull Request

## Lizenz

MIT License - siehe LICENSE-Datei für Details.

## Autor

xMethface

## Changelog

### Version 1.0
- Initiale Veröffentlichung
- Mythic-Plus-Unterstützung
- Options-Panel mit moderner Settings-API
- Robuste Fehlerbehandlung
- Mehrsprachige Sprüche
