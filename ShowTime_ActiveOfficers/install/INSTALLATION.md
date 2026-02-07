# ShowTime Active Officers - Installation Guide

## Prerequisites
- **Framework:** QBCore or QBox
- **Database:** oxmysql (Required)
- **Inventory (Optional):** ox_inventory (for item-based access)
- **Voice System:** pma-voice, saltychat, mumble-voip, or none

---

## Step 1: Extract Files

1. Download the resource.
2. Place the `ShowTime_ActiveOfficers` folder in your server's `resources` directory.

---

### Database Setup

Import the SQL file from the `sql/` folder:

- Import: `sql/sql_qbcore.sql`

> **Note:** Persistence settings require a working database connection via `oxmysql`.

---

## Step 3: Item Integration (Optional - Ox Inventory)

To restrict access to the terminal via an item, you must add the `emergencytablet` item to your inventory system.

### Item Definition
Add the following to your `ox_inventory/data/items.lua`:

```lua
['emergencytablet'] = {
	label = 'Emergency Tablet',
	weight = 500,
	stack = false,
	close = true,
	description = 'A specialized tablet for emergency personnel to track active units.',
	client = {
		image = 'emergencytablet.png'
	}
}
```

### Item Image
1. Locate the `emergencytablet.png` provided in this `install/` folder.
2. Copy it to your inventory resource at: `ox_inventory/web/images/`.

---

## Step 4: Configuration

Edit `shared/config.lua`:

```lua
Config.Framework = "auto"        -- Leave as "auto" for auto-detection
Config.RequireItem = false       -- true: needs 'emergencytablet' item | false: use '=' key
Config.UpdateInterval = 5000     -- How often the list updates (ms)
Config.VoiceSystem = "auto"      -- Auto-detects pma-voice, saltychat, etc.
```

### Key Configuration Options:
- **`Config.RequireItem`**: 
  - `true` = Players need the `emergencytablet` item to open the terminal
  - `false` = Players can use the `=` key or `/activeofficers` command
- **`Config.Departments`**: Add your server's job names to the appropriate department
- **`Config.DepartmentRadioChannels`**: Configure radio channels per department

---

## Step 5: Start the Resource

Add to your `server.cfg`:

```cfg
ensure ShowTime_ActiveOfficers
```

---

## Step 6: Verify Installation

Check your server console for:

```
[ShowTime_ActiveOfficers] Framework Bridge Initialized
[ShowTime_ActiveOfficers] Framework: qbcore (or qbox)
[ShowTime_ActiveOfficers] Voice System: pma-voice (or saltychat/mumble-voip/none)
[ShowTime_ActiveOfficers] Database: Enabled
```

---

## Usage Guide

### Opening the Panel
- **Key Method**: Press the **`=`** key (only if `Config.RequireItem = false`).
- **Command Method**: Type **`/activeofficers`** in the chat (only if `Config.RequireItem = false`).
- **Item Method**: Use the **`emergencytablet`** item from your inventory (if `Config.RequireItem = true`).

### Controls
- **Click Header**: Opens the settings/terminal panel.
- **Click Officer Row**: Sets GPS waypoint to the officer's location.
- **Click Join Button**: Joins the radio channel for that department.
- **Collapse Header**: Click a department/channel header to hide/show the list.
- **Drag List**: Click and drag the header to reposition the HUD.

### Admin Commands
- **`/stress_test [count] [department]`**: Spawns mock units to test UI performance.
  - Example: `/stress_test 20 police`
- **`/test_panic [department]`**: Simulates a panic alert for testing.
  - Example: `/test_panic ambulance`

---

## Troubleshooting

### Officers not showing
- Ensure players are **On Duty**.
- Check if their job names are in `Config.Departments.jobs`.
- Verify the player's job is correctly set in the framework.

### Database errors
- Import the correct SQL file for your framework.
- Ensure `oxmysql` is started **before** this resource in `server.cfg`.
- Check database connection credentials.

### UI not opening
- If using `Config.RequireItem = true`, ensure the player has the `emergencytablet` item.
- If using `Config.RequireItem = false`, ensure the player is in an authorized job.
- Check F8 console for errors.

### Radio channels not working
- Ensure your voice system (pma-voice, etc.) is properly configured.
- Check that `Config.VoiceSystem` is set correctly (or use "auto").
- Verify radio channel numbers match your voice system configuration.

---

**Version:** 2.1.0  
**© 2026 ShowTime Development**
