```markdown
# RiseV Car Improvements

**Version:** 1.0.0  
**Author:** RiseV – Trayx & Freakz  
**Description:**  
A comprehensive FiveM script that enhances vehicle interactions in GTA V. Adds advanced lock/unlock, lockpicking, cleaning, repairing, blinkers, window controls, engine toggle, seatbelt ejection, cruise control, door control, and autopilot features—all fully configurable via `config.lua`.

---

## ⚙️ Requirements

- FiveM server (≥ FXServer `cerulean`)
- **ESX** framework (`es_extended`)
- **oxmysql** for database queries
- **BetterSky** modules (included via `shared_scripts`)

---

## 📦 Installation

1. Place the `RiseV-CarImprovements` folder in your server’s `resources` directory.
2. Add the following to your `server.cfg`:
   ```cfg
   ensure RiseV-CarImprovements
   ```
3. Restart your server or run `refresh` + `ensure RiseV-CarImprovements`.

---

## 📂 Resource Structure

```
RiseV-CarImprovements/
├── fxmanifest.lua
├── config/
│   └── config.lua
├── server/
│   └── server.lua
└── client/
    └── client.lua
```

---

## 🔧 Configuration

All settings are in **`config/config.lua`**. Key sections:

| Section                      | Description                                                      |
|------------------------------|------------------------------------------------------------------|
| `Debugging`                  | Toggle debug prints (`true` / `false`).                         |
| **Lock System**              | Enable/disable locks, lockpick rates, cooldowns, keybinds, etc.  |
| **Cleaning System**          | Enable/disable vehicle cleaning, required item, animation, time. |
| **Repairkit System**         | Enable/disable repair feature, item, animation, time.            |
| **Engine Toggle**            | Enable/disable engine on/off, keybind.                           |
| **Indicator Lights**         | Enable blinkers/hazard lights, key mappings.                    |
| **Window Controls**          | Enable roll-up/down windows, key mappings.                      |
| **Seatbelt System**          | Eject on crash if unbuckled, speed thresholds, toggle key.      |
| **Cruise Control**           | Enable cruise, max speed, cooldown, toggle key.                 |
| **Door Control**             | Enable individual door open/close, key mappings.                |
| **Autopilot**                | Enable autopilot, driving style, max speed, cooldown.           |
| **Notification Settings**    | Customize server/client notification templates and services.     |

> **Tip:** Carefully adjust distances, durations, and cooldowns to suit your server’s pace.

---

## 🚀 Features

1. **Lock & Unlock**  
   - Automatic initial locking based on vehicle class.  
   - Keypress (`U` by default) or `/toggleLock` command.  
   - Horn/light effects on lock/unlock.  
   - Lock cooldown and anti-spam.

2. **Lockpicking**  
   - Usable item (`lockpick`) with configurable success rate.  
   - Animated pick, honking alarm, item consumption on break/success.

3. **Cleaning**  
   - Usable item (`sponge`).  
   - Scenario animation and dirt-level reset.

4. **Repair**  
   - Usable item (`repairkit`).  
   - Scenario animation and full vehicle fix.

5. **Indicator Lights**  
   - Left, right, and hazard signals.  
   - Configurable key mappings (`←`, `→`, `↑`).

6. **Window Controls**  
   - Roll windows up/down individually.  
   - Four window keybinds (`1`–`4` by default).

7. **Engine Toggle**  
   - Start/stop engine with key (`M`).

8. **Seatbelt System**  
   - Toggle seatbelt (`B`).  
   - Eject player on high-speed crash if unbuckled.

9. **Cruise Control**  
   - Toggle cruise (`Z`).  
   - Maintains speed until brake/accelerate.

10. **Door Control**  
    - Open/close front/rear doors, trunk, hood (`5`–`0`).

11. **Autopilot**  
    - `/toggleAutoPilot` or `L` key when a waypoint is set.  
    - Vehicle drives to waypoint with adjustable driving style and speed.

---

## 📡 Exports

### Server-Side

- `ToggleLock(playerId, netId, plate)`
- `GetLockState(netId) → bool`
- `ConsumeLockpick(playerId)`
- `ForceUnlock(playerId, netId)`
- `CleanVehicle(playerId)`
- `RepairVehicle(playerId)`
- `SyncBlinker(netId, state)`
- `TurnOffComponents(playerId, netId)`

### Client-Side

- `ToggleLock()`  
- `AttemptLockpick()`  
- `ToggleBlinker()`  
- `ToggleWindow()`  
- `ToggleDoor()`  
- `ToggleEngine()`  
- `ToggleSeatbelt()`  
- `ToggleCruise()`  
- `ToggleAutoPilot()`  
- `CleanVehicle()`  
- `UseRepairkit()`  
- `TurnOffComponents()`

Use `exports['RiseV-CarImprovements']:<ExportName>(...)` to call from other scripts.

---

## 🔔 Events

### Server Events

| Event                                             | Payload                            | Description                                          |
|---------------------------------------------------|------------------------------------|------------------------------------------------------|
| `Car-Improvements:server:notify`                  | `(playerId, key)`                  | Internal notification hook.                          |
| `Car-Improvements:server:isAuthorized`            | `(playerId, plate, allowed)`       | Ownership/job check result.                          |
| `Car-Improvements:server:entityCreated`           | `(entity, netId, plate)`           | When a new vehicle spawns.                           |
| `Car-Improvements:server:initialLockState`        | `(netId, isLocked)`                | After initial lock setup.                           |
| `Car-Improvements:server:toggleLock`              | `(playerId, netId, isLocked)`      | On lock/unlock action.                               |
| `Car-Improvements:server:lockpickVehicle`         | `(playerId, netId)`                | On successful lockpick.                              |
| `Car-Improvements:server:consumeLockpick`         | `(playerId)`                       | When lockpick item is used up.                       |
| `Car-Improvements:server:cleanComplete`           | `(playerId)`                       | After cleaning finishes.                             |
| `Car-Improvements:server:repairkitRemove`         | `(playerId)`                       | After repairkit item is consumed.                    |
| `Car-Improvements:server:syncBlinker`             | `(netId, blinkerState)`            | Blinker sync broadcast.                              |
| `Car-Improvements:server:turnOffVehicleComponents`| `(playerId, netId)`                | Turn off engine/neon/radio etc.                      |
| `Car-Improvements:server:entityRemoved`           | `(entity, netId)`                  | Cleanup when vehicle despawns.                       |

### Client Events

| Event                                     | Payload                   | Description                                  |
|-------------------------------------------|---------------------------|----------------------------------------------|
| `Car-Improvements:client:notify`          | `(key)`                   | Internal notification hook.                  |
| `Car-Improvements:client:toggleBlinker`   | `(side, left, right, hz)` | When blinkers change.                        |
| `Car-Improvements:clean`                  | `()`                      | Trigger cleaning animation.                  |
| `Car-Improvements:useRepairkit`           | `()`                      | Trigger repair animation.                    |
| `Car-Improvements:syncBlinker`            | `(netId, state)`          | Update lights on clients.                    |
| `Car-Improvements:turnOffVehicleComponents`| `(netId)`                | Client-side component shutdown.              |
| `Car-Improvements:requestVehicleClass`    | `(netId)`                 | Ask server for vehicle class.                |
| `Car-Improvements:initialLockState`       | `(netId, isLocked)`       | Apply initial door lock.                     |
| `Car-Improvements:updateLockState`        | `(netId, isLocked)`       | Apply lock/unlock on client.                 |
| `Car-Improvements:vehicleHonk`            | `(netId)`                 | Honk loop on lockpick.                       |
| `Car-Improvements:client:toggleLock`      | `(netId, plate)`          | After user presses lock key.                 |
| `Car-Improvements:client:attempt`         | `()`                      | Start lockpick process.                      |
| `Car-Improvements:client:toggleEngine`    | `(state)`                 | After engine toggle.                         |
| `Car-Improvements:client:toggleSeatbelt`  | `(state)`                 | Seatbelt on/off.                             |
| `Car-Improvements:client:toggleCruise`    | `(state)`                 | Cruise engaged/disengaged.                   |
| `Car-Improvements:client:toggleDoor`      | `(idx)`                   | Open/close specific door.                    |
| `Car-Improvements:client:toggleAutoPilot` | `(state)`                 | Autopilot on/off.                            |

---

## 📝 License

This project is open-source. Feel free to modify and distribute under your own license.

---

> **Enjoy enhanced vehicular realism on your server with RiseV Car Improvements!**  
> Questions or feedback? Reach out to **Trayx** & **Freakz** on our Discord.  
```
