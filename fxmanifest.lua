fx_version 'cerulean'
game 'gta5'

author 'RiseV'
description 'Driving Essentials: Blinker, CarLock, Windows, Engine Control, etc.'
version '1.0.0'

lua54 'yes'

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

shared_scripts {
    '@BetterSky/ai_module_fg-obfuscated.lua',
    '@BetterSky/shared_fg-obfuscated.lua',
    'config/config.lua'
}