fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'FX-RESTAURANT'
description 'Advanced Restaurant Management System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config/shared.lua',
    'config/restaurants/*.lua'
}

client_scripts {
    'client/main.js',
    'client/bossmenu.lua',
    'client/stations.lua',
    'client/delivery.lua',
    'client/cashier.lua',
    'client/music.lua',
    'client/drivethrough.lua',
    'client/zones.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/recipes.lua',
    'server/delivery.lua',
    'server/shop.lua',
    'server/callbacks.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/assets/*.png',
    'html/assets/*.jpg'
}

dependencies {
    'ox_lib',
    'oxmysql'
}
