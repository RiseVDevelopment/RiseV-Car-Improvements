fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'RiseV - Trayx & Freakz'
description 'Car Improvements'
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
