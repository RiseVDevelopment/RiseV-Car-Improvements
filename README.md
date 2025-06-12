**Überlegen der Codeblock-Formatierung**

Der Benutzer möchte, dass der gesamte README in einem einzigen Codeblock dargestellt wird

Nachgedacht für ein paar Sekunden

```markdown
# RiseV Car Improvements

**Version:** 1.0.0  
**Author:** RiseV – Trayx & Freakz  
**Description:** A comprehensive FiveM script to enhance vehicle interactions in GTA V / FiveM servers. Features include locking/unlocking, lockpicking, cleaning, repairs, blinkers, windows, engine control, seatbelts, cruise control, door control, and autopilot.

---

## 📋 Table of Contents

- [Features](#-features)  
- [Requirements](#-requirements)  
- [Installation](#-installation)  
- [Configuration](#-configuration)  
- [Commands & Key Mappings](#-commands--key-mappings)  
- [Exports](#-exports)  
- [Events](#-events)  
- [Notifications](#-notifications)  
- [Contributing](#-contributing)  
- [License](#-license)  

---

## 🔥 Features

1. **Lock System**  
   - Toggle lock/unlock on nearby vehicles  
   - Lock cooldown and animation  
   - Horn & light effects on lock/unlock  
   - Configurable excluded vehicle classes  

2. **Lockpick System**  
   - Chance-based lockpicking  
   - Lockpick item consumption  
   - Lockpick animation & honk effects  
   - Lockpick cooldown and success rate  

3. **Cleaning System**  
   - Use a sponge item to clean vehicles  
   - Configurable cleaning distance, animation, and duration  

4. **Repair Kit System**  
   - Use a repair kit item to fix vehicles  
   - Configurable repair distance, animation, and duration  

5. **Indicator Lights**  
   - Left/right blinkers and hazards  
   - Key mappings for easy control  
   - Network sync for all players  

6. **Window Controls**  
   - Roll windows up/down individually  
   - Key mappings for each window  

7. **Engine Toggle**  
   - Turn engine on/off  
   - Configurable key mapping  

8. **Seatbelt System** *(Optional)*  
   - Eject player on high-speed crash if not buckled  
   - Configurable speed threshold and multiplier  

9. **Cruise Control** *(Optional)*  
   - Maintain current speed  
   - Auto-disable on brake/acceleration or airborne  

10. **Door Control** *(Optional)*  
    - Open/close individual doors, hood, and trunk  

11. **Autopilot** *(Optional)*  
    - Auto-drive to waypoint  
    - Configurable driving style and max speed  

---

## ⚙️ Requirements

- **FiveM** server with `fxserver`  
- **ESX Framework** (`es_extended` resource)  
- **BetterSky** AI module dependency (provided in fxmanifest)  
- **oxmysql** or compatible MySQL library for ownership checks  

---

## 🚀 Installation

1. **Clone or download** this resource into your `resources` folder:
   ```bash
   resources/[local]/risev-car-improvements
   ```
2. **Add** to your `server.cfg`:
   ```
   ensure risev-car-improvements
   ```
3. **Restart** your server or use `refresh` + `ensure risev-car-improvements`.

---

## ⚙️ Configuration

All settings live in `config/config.lua`. Key sections:

```lua
Config.Debugging = true
```

### Lock System (`Config.LockSystemSettings`)
- `toggleLock` – description & key (default `U`)  
- `VehicleDetectionDistance` – meters  
- `LockExcludedVehicleClasses` – array of class IDs (e.g., `{13}` for planes)  
- `EffectsOnLock` – horn & light effects  
- `lockCooldown` – seconds  
- `LockpickSuccessRate` – 0–100%  
- `LockpickDuration` – seconds  
- `LockpickHonkDuration` – seconds  
- `LockpickCooldown` – seconds  
- `LockpickItem` & `requiredItemCount`  
- Animations: `LockpickAnimationDict/Name`, `LockToggleAnimationDict/Name`

### Cleaning System (`Config.CleaningSettings`)
- `CleaningItem`, `requiredItemCount`  
- `VehicleDetectionDistance`  
- `CleaningAnimation` (scenario)  
- `CleaningDuration` (seconds)

### Repair Kit System (`Config.RepairkitSettings`)
- `RepairkitItem`, `requiredItemCount`  
- `VehicleDetectionDistance`  
- `RepairingAnimation` (scenario)  
- `RepairingTime` (seconds)

### Engine Control (`Config.EngineControlSettings`)
- `toggleKey` – description & key (default `M`)  
- Master switch: `Config.TurnOnOffEngine`

### Indicator Lights (`Config.IndicatorKeyMappings`)
- `toggleLeftBlinker`, `toggleRightBlinker`, `toggleHazardLights`  
- Each with `description` & `key`

### Window Controls (`Config.WindowKeyMappings`)
- `toggleWindowLeft`, `toggleWindowRight`, `toggleWindowRearLeft`, `toggleWindowRearRight`  
- Each with `description` & `key`

### Seatbelt System (`Config.SeatbeltSettings`)
- `FlyOutOnCrashIfNotBuckledUp`  
- `FlySpeedMultiplicator`  
- `MinCrashSpeedKMH`  
- `toggleKey` – description & key (default `B`)  
- `IgnoreFragileObjects`

### Cruise Control (`Config.CruiseControlSettings`)
- `toggleCruiseControl` – description & key (default `Z`)  
- `maxAirTime`, `maxSpeedKMH`, `cooldown`

### Door Control (`Config.DoorControlSettings`)
- `toggleFrontLeftDoor`, `toggleFrontRightDoor`, `toggleRearLeftDoor`, `toggleRearRightDoor`, `toggleTrunk`, `toggleHood`  
- Each with `description` & `key`

### Autopilot (`Config.AutoPilotSettings`)
- `toggleAutoPilot` – description & key (default `L`)  
- `cooldown`, `drivingStyleFlags`, `maxSpeedKMH`

### Notification Settings (`Config.NotificationSettings`)
- **Server** & **Client** services: call patterns  
- Templates per key (title, text, type, duration)

---

## ⌨️ Commands & Key Mappings

| Feature             | Command           | Default Key | Description                    |
|---------------------|-------------------|-------------|--------------------------------|
| Lock/Unlock         | `toggleLock`      | `U`         | Lock or unlock nearest vehicle |
| Lockpick            | *(auto via item)* | —           | Requires `lockpick` item       |
| Clean Vehicle       | *(auto via item)* | —           | Requires `sponge` item         |
| Repair Vehicle      | *(auto via item)* | —           | Requires `repairkit` item      |
| Left Blinker        | `toggleLeftBlinker`   | `←`       | Toggle left indicator          |
| Right Blinker       | `toggleRightBlinker`  | `→`       | Toggle right indicator         |
| Hazard Lights       | `toggleHazardLights`  | `↑`       | Toggle hazard lights           |
| Toggle Window Left  | `toggleWindowLeft`    | `1`       | Roll left window up/down       |
| Toggle Window Right | `toggleWindowRight`   | `2`       | Roll right window up/down      |
| Toggle Window R.Left| `toggleWindowRearLeft`| `3`       | Roll rear-left window          |
| Toggle Window R.Right| `toggleWindowRearRight`| `4`      | Roll rear-right window         |
| Toggle Engine       | `toggleEngine`       | `M`       | Turn engine on/off             |
| Toggle Seatbelt     | `toggleSeatbelt`     | `B`       | Buckle/unbuckle seatbelt       |
| Toggle Cruise Control| `toggleCruise`      | `Z`       | Activate/deactivate cruise     |
| Toggle Door (FL)    | `toggleFrontLeftDoor` | `5`       | Open/close front-left door     |
| Toggle Door (FR)    | `toggleFrontRightDoor`| `6`       | Open/close front-right door    |
| Toggle Door (RL)    | `toggleRearLeftDoor`  | `7`       | Open/close rear-left door      |
| Toggle Door (RR)    | `toggleRearRightDoor` | `8`       | Open/close rear-right door     |
| Toggle Trunk        | `toggleTrunk`         | `9`       | Open/close trunk               |
| Toggle Hood         | `toggleHood`          | `0`       | Open/close hood                |
| Toggle Autopilot    | `toggleAutoPilot`     | `L`       | Start/stop autopilot to waypoint |

---

## 🧩 Exports

### Server Exports
```lua
ToggleLock(playerId, netId, plate)
GetLockState(netId) → bool
ConsumeLockpick(playerId)
ForceUnlock(playerId, netId)
CleanVehicle(playerId)
RepairVehicle(playerId)
SyncBlinker(netId, state)
TurnOffComponents(playerId, netId)
```

### Client Exports
```lua
ToggleLock()
AttemptLockpick()
ToggleBlinker()
ToggleWindow()
ToggleDoor()
ToggleEngine()
ToggleSeatbelt()
ToggleCruise()
ToggleAutoPilot()
CleanVehicle()
UseRepairkit()
TurnOffComponents()
```

---

## 📡 Events

### Server Events
- `Car-Improvements:server:toggleLock`  
- `Car-Improvements:server:getLockState`  
- `Car-Improvements:server:useLockpickItem`  
- `Car-Improvements:server:consumeLockpick`  
- `Car-Improvements:server:lockpickVehicle`  
- `Car-Improvements:server:cleanComplete`  
- `Car-Improvements:server:notify(playerId, key)`  
- and more under the `Car-Improvements:server:*` namespace.

### Client Events
- `Car-Improvements:client:toggleLock`  
- `Car-Improvements:client:notify(key)`  
- `Car-Improvements:client:toggleBlinker`  
- `Car-Improvements:client:turnOffComponents`  
- `Car-Improvements:client:toggleEngine`  
- `Car-Improvements:client:toggleSeatbelt`  
- `Car-Improvements:client:toggleCruise`  
- `Car-Improvements:client:toggleAutoPilot`  
- and more under the `Car-Improvements:client:*` namespace.

Use these to hook into or extend the script’s behavior.

---

## 🔔 Notifications

All user notifications use the `RiP-Notify` resource by default. You can swap to any notification system by editing the `Config.NotificationSettings` service strings.

---

## 🤝 Contributing

1. Fork this repository.  
2. Create a feature branch: `git checkout -b feature-name`.  
3. Commit your changes: `git commit -m "Add new feature"`.  
4. Push to the branch: `git push origin feature-name`.  
5. Open a Pull Request.

Please adhere to the existing code style and include clear commit messages.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---
```
