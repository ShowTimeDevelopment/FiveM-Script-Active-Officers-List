
# ShowTime Active Officers

**Advanced Emergency Services Management System** - Exclusively for QBCore and QBox servers.

Real-time officer tracking with radio integration, panic button system, and a highly customizable UI.

---

## Features

- ✅ **Framework Selection**: Optimized for QBCore and QBox.
- ✅ **Real-time Officer List**: Visible HUD with units grouped by their current radio channels.
- ✅ **Optimized Voice Sync**: Integrated with `pma-voice`, `saltychat`, and `mumble-voip`. Minimal CPU usage.
- ✅ **Panic Button System**: Global emergency alert with visual SOS markers and audio notifications.
- ✅ **Radio Management**: Browse and join authorized channels directly from the terminal.
- ✅ **GPS Integration**: Click any officer on the list to set a GPS waypoint to their location.
- ✅ **Customizable UI**: Adjust themes (Dark/Neutral), opacity, scale, and list position on your screen.
- ✅ **Security**: Built-in protection against long callsigns and unauthorized radio access.
- ✅ **Database Support**: Persistent settings (callsign, UI position, opacity) using `oxmysql`.
- ✅ **Extremely Optimized**: Runs at **0.00ms** on idle. Uses state-verification to prevent NUI lag.

---

## Installation

See **[INSTALLATION.md](INSTALLATION.md)** for detailed setup instructions.

### Quick Start

1. Extract the folder to your `resources` directory.
2. Import the `sql/sql_qbcore.sql` file to your database. (Required)
3. Add `ensure ShowTime_ActiveOfficers` to your `server.cfg`.

---

## Usage

### Opening the Terminal
The method of opening the terminal depends on your `shared/config.lua` settings:
- **If `Config.RequireItem = false`**: Use the **`=`** key or type **`/activeofficers`**.
- **If `Config.RequireItem = true`**: You must use the item **`emergencytablet`** from your inventory.

### Key Controls
- **Click item or `=`**: Opens the Officer Terminal/Settings.
- **Click Officer Row**: Sets a GPS waypoint to that officer.
- **Click Channel Header**: Collapses or expands that radio group.
- **Join Button**: Quickly join a radio channel from the list.

### Commands
- **`/panic`**: Triggers a 7-second emergency alert for all units.
- **`/activeofficers`**: Opens the management terminal to adjust callsigns, UI settings, and view active units.

---

## Configuration

Settings are found in `shared/config.lua`.

```lua
Config.Framework = "auto"        -- Framework: auto, qbcore, qbox
Config.RequireItem = false       -- Use tablet item to open or '=' key
Config.UpdateInterval = 5000     -- Refresh rate for the list (ms)
Config.EnablePanicButton = true  -- Enable the /panic command
Config.Theme = "Dark"            -- Options: "Dark", "Neutral"
```

---

## Technical Details

| Requirement | Supported Version / Resource |
|-------------|----------------------------|
| **Server** | FXServer 5848+ |
| **Framework** | QBCore / QBox |
| **Database** | oxmysql (Required) |
| **Inventory** | Generic QBCore support (ox_inventory optional) |
| **Voice System** | pma-voice / saltychat / mumble-voip / none (Auto-detection) |

---

## Support

For issues or questions, contact **ShowTime Development**.

---

**Version:** 1.0.0
**© 2026 ShowTime Development. All rights reserved.**
