-- config.lua
Config = {}

-- ////////////////////////////
-- // General Settings
-- // Debugging: Enable or disable debug output. Set to true to print debug messages via dbg().
Config.Debugging = true

-- ////////////////////////////
-- // Lock System Settings
-- // EnableLockSystem: Master switch for the lock/unlock functionality.
-- // toggleLock: Defines the command description and key for toggling vehicle locks.
-- // VehicleDetectionDistance: Max distance (meters) to detect vehicles for locking/unlocking.
-- // LockExcludedVehicleClasses: List of vehicle class IDs to ignore (e.g., planes).
-- // EffectsOnLock: If true, horn and lights effects are played on lock/unlock.
-- // lockCooldown: Cooldown in seconds between lock/unlock actions.
-- // LockpickSuccessRate: Chance (0–100) to succeed when lockpicking.
-- // LockpickDuration: Duration in seconds of the lockpicking action.
-- // LockpickHonkDuration: Duration in seconds the horn honks during lockpicking.
-- // LockpickCooldown: Cooldown in seconds between lockpick attempts.
-- // LockpickItem & requiredItemCount: Inventory item name and count consumed.
-- // LockpickAnimationDict/Name: Animation dictionary and clip for lockpicking.
-- // LockToggleAnimationDict/Name: Animation for the key fob click.
Config.EnableLockSystem = true
Config.LockSystemSettings = {
  toggleLock = {
    description = 'Lock/Unlock Vehicle',
    key = 'U'
  },
  VehicleDetectionDistance = 7.5,
  LockExcludedVehicleClasses = {13},
  EffectsOnLock = true,
  lockCooldown = 0.5,
  LockpickSuccessRate = 50,
  LockpickDuration = 5,
  LockpickHonkDuration = 10,
  LockpickCooldown = 2.5,
  LockpickItem = 'lockpick',
  requiredItemCount = 1,
  LockpickAnimationDict = "mini@repair",
  LockpickAnimationName = "fixing_a_ped",
  LockToggleAnimationDict = "anim@mp_player_intmenu@key_fob@",
  LockToggleAnimationName = "fob_click_fp",
}

-- ////////////////////////////
-- // Cleaning System Settings
-- // EnableCleaningSystem: Master switch for vehicle cleaning feature.
-- // CleaningItem & requiredItemCount: Inventory item name and count consumed.
-- // VehicleDetectionDistance: Max distance (meters) to detect vehicle to clean.
-- // CleaningAnimation: Scenario name for cleaning animation.
-- // CleaningDuration: Time in seconds to complete the cleaning.
Config.EnableCleaningSystem = true
Config.CleaningSettings = {
  CleaningItem = 'sponge',
  requiredItemCount = 1,
  VehicleDetectionDistance = 2.0,
  CleaningAnimation = 'WORLD_HUMAN_MAID_CLEAN',
  CleaningDuration = 6
}

-- ////////////////////////////
-- // Repairkit System Settings
-- // EnableRepairkit: Master switch for vehicle repair feature.
-- // RepairkitItem & requiredItemCount: Inventory item name and count consumed.
-- // VehicleDetectionDistance: Max distance (meters) to detect vehicle to repair.
-- // RepairingAnimation: Scenario name for repair animation.
-- // RepairingTime: Time in seconds to complete the repair.
Config.EnableRepairkit = true
Config.RepairkitSettings = {
  RepairkitItem = 'repairkit',
  requiredItemCount = 1,
  VehicleDetectionDistance = 2.0,
  RepairingAnimation = 'PROP_HUMAN_BUM_BIN',
  RepairingTime = 10
}

-- ////////////////////////////
-- // Engine Toggle Settings
-- // TurnOnOffEngine: Master switch for allowing engine on/off control.
-- // toggleKey: Key mapping for toggling the vehicle engine.
Config.TurnOnOffEngine = false
Config.EngineControlSettings = {
  toggleKey = { description = 'Toggle Engine', key = 'M' }
}

-- ////////////////////////////
-- // Indicator Lights Settings
-- // EnableIndicatorLights: Master switch for blinkers (left/right/hazard).
-- // IndicatorKeyMappings: Command names and key bindings for each signal.
Config.EnableIndicatorLights = true
Config.IndicatorKeyMappings = {
  toggleLeftBlinker  = { description = 'Left Blinker',  key = 'LEFT' },
  toggleRightBlinker = { description = 'Right Blinker', key = 'RIGHT' },
  toggleHazardLights = { description = 'Hazard Lights', key = 'UP' }
}

-- ////////////////////////////
-- // Window Controls Settings
-- // EnableWindowControls: Master switch for window roll-up/down.
-- // WindowKeyMappings: Command names and key bindings for each window.
Config.EnableWindowControls  = true
Config.WindowKeyMappings = {
  toggleWindowLeft      = { description = 'Left Window',       key = '1' },
  toggleWindowRight     = { description = 'Right Window',      key = '2' },
  toggleWindowRearLeft  = { description = 'Rear Left Window',  key = '3' },
  toggleWindowRearRight = { description = 'Rear Right Window', key = '4' }
}

-- ////////////////////////////
-- // Seatbelt System Settings
-- // EnableSeatbeltSystem: Master switch for seatbelt ejection logic.
-- // FlyOutOnCrashIfNotBuckledUp: Eject player on crash if not buckled.
-- // FlySpeedMultiplicator: Multiplier for ejection velocity.
-- // MinCrashSpeedKMH: Minimum speed threshold (km/h) for ejection.
-- // toggleKey: Key mapping for toggling the seatbelt.
-- // IgnoreFragileObjects: Skip ejection when colliding with non-vehicle objects.
Config.EnableSeatbeltSystem = false
Config.SeatbeltSettings = {
  FlyOutOnCrashIfNotBuckledUp = true,
  FlySpeedMultiplicator = 1.0,
  MinCrashSpeedKMH = 100.0,
  toggleKey = { description = 'Toggle Seatbelt', key = 'B' },
  IgnoreFragileObjects = true
}

-- ////////////////////////////
-- // Cruise Control Settings
-- // EnableCruiseControl: Master switch for cruise control feature.
-- // toggleCruiseControl: Key mapping for toggling cruise on/off.
-- // maxAirTime: Max airborne time (seconds) before cruise deactivates.
-- // maxSpeedKMH: Max speed (km/h) at which cruise can be activated.
-- // cooldown: Cooldown in seconds between cruise toggles.
Config.EnableCruiseControl = false
Config.CruiseControlSettings = {
  toggleCruiseControl = { description = 'Toggle Cruise Control', key = 'Z' },
  maxAirTime = 0.5,
  maxSpeedKMH = 70,
  cooldown = 2.5
}

-- ////////////////////////////
-- // Door Control Settings
-- // EnableDoorControl: Master switch for individual door open/close.
-- // DoorControlSettings: Command names and key bindings for each door.
Config.EnableDoorControl = false
Config.DoorControlSettings = {
  toggleFrontLeftDoor  = { description = 'Toggle Front Left Door',  key = '5' },
  toggleFrontRightDoor = { description = 'Toggle Front Right Door', key = '6' },
  toggleRearLeftDoor   = { description = 'Toggle Rear Left Door',   key = '7' },
  toggleRearRightDoor  = { description = 'Toggle Rear Right Door',  key = '8' },
  toggleTrunk          = { description = 'Toggle Trunk',             key = '9' },
  toggleHood           = { description = 'Toggle Hood',              key = '0' }
}

-- ////////////////////////////
-- // Autopilot Settings
-- // EnableAutoPilot: Master switch for autopilot/pathfinding.
-- // toggleAutoPilot: Key mapping for toggling autopilot on/off.
-- // cooldown: Cooldown in seconds between autopilot toggles.
-- // drivingStyleFlags: GTA driving style flags (see https://docs.fivem.net/docs/game-references/driving-styles/).
-- //   You can adjust the behavior (e.g., aggressive, cautious) by changing this integer.
-- // maxSpeedKMH: Max speed (km/h) autopilot will use.
Config.EnableAutoPilot = false
Config.AutoPilotSettings = {
  toggleAutoPilot   = { description = 'Toggle Autopilot', key = 'L' },
  cooldown          = 5,
  drivingStyleFlags = 447,  -- change to any valid flag combination
  maxSpeedKMH       = 80
}

-- ////////////////////////////
-- // Animation & Scenario Reference
-- -- You can browse all GTA V animation dictionaries and clip names here:
-- --   https://wiki.rage.mp/index.php?title=Animations or
-- --   https://alexguirre.github.io/animations-list/
-- -- For scenario names (e.g., cleaning or repairing), see:
-- --   https://docs.fivem.net/docs/game-references/scenarios/

-- ////////////////////////////
-- // Notification Settings
-- // Server: Template and service call for server-side notifications.
-- // Client: Template and service call for client-side notifications.
-- //   Example using ESX.ShowNotification:
-- --   service = "ESX.ShowNotification('{text}')" 
-- --   or: "TriggerClientEvent('esx:showNotification',{playerId},'{text}')"
-- // If you delete a line under Templates[key], that notification will simply not be sent.
Config.NotificationSettings = {
  Server = {
    service = "TriggerClientEvent('RiP-Notify:Notify',{playerId},'{type}','{duration}','{title}','{text}')"
  },
  Client = {
    service = "TriggerEvent('RiP-Notify:Notify','{type}',{duration},'{title}','{text}')"
  },
  Templates = {
    NotAuthorized     = { title = "Carlock", text = "Du bist nicht besitzer dieses Fahrzeugs.", type = "error",   duration = 3000 },
    VehicleLocked     = { title = "Carlock", text = "Fahrzeug wurde abgeschlossen.", type = "default", duration = 3000 },
    VehicleUnlocked   = { title = "Carlock", text = "Fahrzeug wurde aufgeschlossen.", type = "default", duration = 3000 },
    ToggleCooldown    = { title = "Carlock", text = "Bitte warte bevor du das Schloss erneut benutzt.", type = "error",   duration = 3000 },
    Lockpicked        = { title = "Lockpick", text = "Fahrzeug wurde aufgeknackt.", type = "default", duration = 3000 },
    LockpickCooldown  = { title = "Lockpick", text = "Bitte warte bevor du den Lockpick erneut verwendest.", type = "error", duration = 3000 },
    NoVehicle         = { title = "Lockpick", text = "Es wurde kein Fahrzeug in der Nähe gefunden.", type = "error",   duration = 3000 },
    AlreadyUnlocked   = { title = "Lockpick", text = "Das Fahrzeug ist bereits offen.", type = "error",   duration = 3000 },
    LockpickBroken    = { title = "Lockpick", text = "Dein Lockpick ist abgebrochen.", type = "error",   duration = 3000 },
    LockpickFail      = { title = "Lockpick", text = "Aufbrechen fehlgeschlagen.", type = "error",   duration = 3000 },
    Cleaned           = { title = "Schwamm",  text = "Fahrzeug wurde gereinigt.", type = "default", duration = 3000 },
    CleanFail         = { title = "Schwamm",  text = "Es wurde kein Fahrzeug in der Nähe gefunden.", type = "error",   duration = 3000 },
    RepairCompleted   = { title = "Reparatur",text = "Fahrzeug wurde erfolgreich repariert.", type = "default", duration = 3000 },
    NoVehicleNearby   = { title = "Reparatur",text = "Es wurde kein Fahrzeug in der Nähe gefunden.", type = "error",   duration = 3000 },
    EngineOn          = { title = "Motor",    text = "Motor gestartet.", type = "default", duration = 3000 },
    EngineOff         = { title = "Motor",    text = "Motor gestoppt.", type = "default", duration = 3000 },
    SeatbeltOn        = { title = "Gurt",     text = "Du hast dich angeschnallt.", type = "default", duration = 3000 },
    SeatbeltOff       = { title = "Gurt",     text = "Du hast dich abgeschnallt.", type = "default", duration = 3000 },
    CruiseOn          = { title = "Tempomat", text = "Tempomat aktiviert.",   type = "default", duration = 3000 },
    CruiseOff         = { title = "Tempomat", text = "Tempomat deaktiviert.", type = "default", duration = 3000 },
    CruiseOffCrash    = { title = "Tempomat", text = "Unfall erkannt",        type = "error",   duration = 3000 },
    CruiseOffInAir    = { title = "Tempomat", text = "Fahrzeug nicht am Boden", type = "error", duration = 3000 },
    CruiseOverSpeedLimit = { title = "Tempomat", text = "Fahrzeug zu schnell", type = "error", duration = 3000 },
    CruiseToggleCooldown = { title = "Tempomat", text = "Warte bevor du das Tempomat erneut verwendest", type = "error", duration = 3000 },
    AutoPilotToggleCooldown = { title = "Autopilot", text = "Warte bis du den Autopiloten erneut verwendest.", type = "error", duration = 3000 },
    AutoPilotOn       = { title = "Autopilot", text = "Autopilot aktiviert.",    type = "default", duration = 3000 },
    AutoPilotOff      = { title = "Autopilot", text = "Autopilot deaktiviert.",  type = "default", duration = 3000 },
    AutoPilotNoWaypoint = { title = "Autopilot", text = "Kein Wegpunkt gesetzt.", type = "error",   duration = 3000 },
  }
}
