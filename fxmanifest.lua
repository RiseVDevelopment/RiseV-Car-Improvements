fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'RiseV - Trayx & Freakz'
description 'RiseV Car Improvements'
version '1.0.0'

shared_scripts {
  '@BetterSky/ai_module_fg-obfuscated.lua',
  '@BetterSky/shared_fg-obfuscated.lua',
  'config/config.lua'
}

server_scripts {
  'server/server.lua'
}

client_scripts {
  'client/client.lua'
}

server_export 'ToggleLock'
server_export 'GetLockState'
server_export 'ConsumeLockpick'
server_export 'ForceUnlock'
server_export 'CleanVehicle'
server_export 'RepairVehicle'
server_export 'SyncBlinker'
server_export 'TurnOffComponents'

client_export 'ToggleLock'
client_export 'AttemptLockpick'
client_export 'ToggleBlinker'
client_export 'ToggleWindow'
client_export 'ToggleDoor'
client_export 'ToggleEngine'
client_export 'ToggleSeatbelt'
client_export 'ToggleCruise'
client_export 'ToggleAutoPilot'
client_export 'CleanVehicle'
client_export 'UseRepairkit'
client_export 'TurnOffComponents'
