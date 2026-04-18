fx_version 'cerulean'
game 'gta5'

name 'doa-display'
description 'Modular display + ambient city vehicles'
author 'DOA'
version '1.1.0'

shared_scripts {
    'config.lua',
    'shared/logger.lua',
}

client_scripts {
    'client/modules/display.lua',
}

server_scripts {
    'server/modules/citycars.lua',
    'server/main.lua',
}
