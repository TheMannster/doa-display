fx_version 'cerulean'
game 'gta5'

name 'tm-streetside'
description 'Modular display + ambient city vehicles'
author 'themannster'
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
    'server/modules/versioncheck.lua',
    'server/main.lua',
}
