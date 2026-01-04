fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'FX-RESTAURANT'
description 'Advanced Restaurant Management System'
version '1.0.0'

--=====================================================
-- SHARED FILES
--=====================================================
shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/items.lua',
    'config/ingredients.lua',       -- Ingredient shop config ✅ NIEUW
    'config/locations.lua'          -- Delivery locations ✅ NIEUW
}

--=====================================================
-- CLIENT FILES
--=====================================================
client_scripts {
    'client/bridge.lua',            -- Target system bridge
    'client/calories.lua',          -- Client-side buffs/needs
    'client/bossmenu.lua',          -- Boss menu UI
    'client/zones.lua',             -- Zone spawning
    'client/npc.lua',               -- NPC spawning
    'client/ingredient_shop.lua',   -- Ingredient shop UI
    'client/stations.lua',          -- Stations (prep/cooking)
    'client/cashier.lua',           -- Cashier UI ✅ UPDATED
    'client/trays.lua',             -- Serving trays ✅ NIEUW
    'client/main.lua',
    'client/delivery.lua',
    'client/music.lua',
    'client/flyer.lua',
    'client/props.lua'
}

--=====================================================
-- SERVER FILES
--=====================================================
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bridge.lua',            -- Framework/Inventory bridge
    'server/calories.lua',          -- Calorie & buff system
    'server/permissions.lua',       -- Permission system
    'server/main.lua',
    'server/recipes.lua',           -- Recipe CRUD
    'server/bossmenu.lua',          -- Boss menu backend
    'server/ingredients.lua',       -- Ingredient shop & stations
    'server/cashier.lua',           -- Cashier system ✅ UPDATED
    'server/trays.lua',             -- Serving trays ✅ NIEUW
    'server/delivery.lua',
    'server/offline_shop.lua',
    'server/security.lua'
}

--=====================================================
-- UI FILES
--=====================================================
--=====================================================
-- UI FILES
--=====================================================
ui_page 'html/bossmenu/index.html'

files {
    -- Boss Menu UI
    'html/bossmenu/index.html',
    'html/bossmenu/style.css',
    'html/bossmenu/script.js',
    
    -- Ingredient Shop UI
    'html/ingredient_shop/index.html',
    'html/ingredient_shop/style.css',
    'html/ingredient_shop/script.js',
    
    -- Cashier UI ✅ NIEUW
    'html/cashier/index.html',
    'html/cashier/style.css',
    'html/cashier/script.js',
    
    -- Other UIs (to be implemented)
    'html/music/*.html',
    'html/flyer/*.html',
    
    -- Restaurant configs (loaded dynamically)
    'shared/restaurants/*/config.lua',
    'shared/restaurants/*/zones.lua',
    'shared/restaurants/*/stations.lua'
}

--=====================================================
-- DEPENDENCIES
--=====================================================
dependencies {
    'ox_lib',
    'oxmysql'
}
