Config = {}

-- ////////////////////////////
-- // General Settings
Config.Debugging             = true

-- ////////////////////////////
-- // Lock System Settings
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
  LockpickAnimationDict = "mini@repair", --you can find animations here: "https://forge.plebmasters.de/animations"
  LockpickAnimationName = "fixing_a_ped",
  LockToggleAnimationDict = "anim@mp_player_intmenu@key_fob@",
  LockToggleAnimationName = "fob_click_fp",
}

-- ////////////////////////////
-- // Cleaning System Settings
Config.EnableCleaningSystem = true
Config.CleaningSettings = {
  CleaningItem = 'sponge',         
  requiredItemCount = 1,       
  VehicleDetectionDistance = 2.0,
  CleaningAnimation = 'WORLD_HUMAN_MAID_CLEAN', --you can find animations here: "https://forge.plebmasters.de/animations"
  CleaningDuration = 6                 
}

-- ////////////////////////////
-- // Repairkit System Settings
Config.EnableRepairkit = true
Config.RepairkitSettings = {
  RepairkitItem = 'repairkit',
  requiredItemCount = 1,
  VehicleDetectionDistance = 2.0,
  RepairingAnimation = 'PROP_HUMAN_BUM_BIN', --you can find animations here: "https://forge.plebmasters.de/animations"
  RepairingTime = 10
}

-- ////////////////////////////
-- // Engine Toggle Settings
Config.TurnOnOffEngine = false
Config.EngineControlSettings = {
  toggleKey = { description = 'Toggle Engine', key = 'M' }
}

-- ////////////////////////////
-- // Indicator Key Mappings
Config.EnableIndicatorLights = true
Config.IndicatorKeyMappings = {
  toggleLeftBlinker  = { description = 'Left Blinker',  key = 'LEFT' },
  toggleRightBlinker = { description = 'Right Blinker', key = 'RIGHT' },
  toggleHazardLights = { description = 'Hazard Lights', key = 'UP' }
}

-- ////////////////////////////
-- // Window Key Mappings
Config.EnableWindowControls  = true
Config.WindowKeyMappings = {
  toggleWindowLeft      = { description = 'Left Window',       key = '1' },
  toggleWindowRight     = { description = 'Right Window',      key = '2' },
  toggleWindowRearLeft  = { description = 'Rear Left Window',  key = '3' },
  toggleWindowRearRight = { description = 'Rear Right Window', key = '4' }
}

-- ////////////////////////////
-- // Notification Settings
Config.NotificationSettings = {
  Server = {
    service = "TriggerClientEvent('RiP-Notify:Notify',{playerId},'{type}','{duration}','{title}','{text}')"
    -- or use "TriggerClientEvent('esx:showNotification',{playerId},'{text}','{type}',{duration},'{title}')"
  },
  Client = {
    service = "TriggerEvent('RiP-Notify:Notify','{type}',{duration},'{title}','{text}')"
    -- or use "ESX.ShowNotification('{text}','{type}',{duration},'{title}')"
  },
  Templates = {
    NotAuthorized     = { title = "Carlock", text = "Du bist nicht besitzer dieses Fahrzeugs.", type = "error",   duration = 3000 },
    VehicleLocked     = { title = "Carlock", text = "Fahrzeug wurde abgeschlossen.", type = "default", duration = 3000 },
    VehicleUnlocked   = { title = "Carlock", text = "Fahrzeug wurde aufgeschlossen.", type = "default", duration = 3000 },
    Lockpicked        = { title = "Lockpick",text = "Fahrzeug wurde aufgeknackt.", type = "default", duration = 3000 },
    ToggleCooldown    = { title = "Carlock", text = "Bitte warte bevor du das Schloss erneut benutzt.", type = "error",   duration = 3000 },
    LockpickCooldown  = { title = "Lockpick", text = "Bitte warte bevor du den Lockpick erneut verwendest.", type = "error", duration = 3000 },
    NoVehicle         = { title = "Lockpick", text = "Es wurde kein Fahrzeug in der Nähe gefunden.", type = "error",   duration = 3000 },
    AlreadyUnlocked   = { title = "Lockpick", text = "Das Fahrzeug ist bereits offen.", type = "error",   duration = 3000 },
    LockpickBroken    = { title = "Lockpick", text = "Dein Lockpick ist abgebrochen.", type = "error",   duration = 3000 },
    LockpickFail      = { title = "Lockpick", text = "Aufbrechen fehlgeschlagen.", type = "error",   duration = 3000 },
    Cleaned           = { title = "Schwamm", text = "Fahrzeug wurde gereinigt.", type = "default", duration = 3000 },
    CleanFail         = { title = "Schwamm", text = "Es wurde kein Fahrzeug in der Nähe gefunden.", type = "error",   duration = 3000 },
    RepairCompleted   = { title = "Reparatur", text = "Fahrzeug wurde erfolgreich repariert.", type = "default", duration = 3000 },
    NoVehicleNearby   = { title = "Reparatur", text = "Es wurde kein Fahrzeug in der Nähe gefunden.", type = "error",   duration = 3000 },
    EngineOn          = { title = "Motor", text = "Motor gestartet.", type = "default", duration = 3000 },
    EngineOff         = { title = "Motor", text = "Motor gestoppt.", type = "default", duration = 3000 },
    -- you may comment a notification if you don't want to use it, for example:
    -- EngineOff = { title = "Engine", text = "Motor stopped.", type = "default", duration = 3000 },
  } 
}
