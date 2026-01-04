--=====================================================
-- FX-RESTAURANT | ZONES SYSTEM (CLIENT)
--=====================================================
-- Spawnt alle zones voor restaurants
-- Boss Menu, Cashiers, Stations, etc.
--=====================================================

local Target = exports['fx-restaurant']:GetTargetBridge()
local activeZones = {}

--=====================================================
-- LOAD RESTAURANT ZONES
--=====================================================

---Load restaurant config
---@param restaurantId string
---@return table|nil
local function LoadRestaurantConfig(restaurantId)
    local path = ('shared/restaurants/%s/config.lua'):format(restaurantId)
    local configData = LoadResourceFile(GetCurrentResourceName(), path)
    
    if not configData then
        print('^3[WARNING] Could not load config for: ' .. restaurantId .. '^0')
        return nil
    end
    
    local env = { Restaurant = nil }
    local chunk = load(configData, path, 't', env)
    
    if not chunk then
        print('^1[ERROR] Failed to compile config: ' .. restaurantId .. '^0')
        return nil
    end
    
    pcall(chunk)
    return env.Restaurant
end

---Setup all zones for a restaurant
---@param restaurant table Restaurant config
function SetupRestaurantZones(restaurant)
    if not restaurant or not restaurant.enabled then return end
    
    local id = restaurant.id
    print(('^2[FX-RESTAURANT] Setting up zones for: %s^0'):format(restaurant.label))
    
    -- Boss Menu Zone
    if restaurant.zones.boss_menu and restaurant.features.bossmenu then
        SetupBossMenuZone(id, restaurant.zones.boss_menu)
    end
    
    -- Cashier Zones
    if restaurant.zones.cashiers then
        for i, cashier in ipairs(restaurant.zones.cashiers) do
            SetupCashierZone(id, cashier, i)
        end
    end
    
    -- Preparation Zone
    if restaurant.zones.preparation then
        SetupPreparationZone(id, restaurant.zones.preparation)
    end
    
    -- Cooking Stations
    if restaurant.zones.grill then
        SetupCookingZone(id, restaurant.zones.grill, 'grill')
    end
    
    if restaurant.zones.fryer then
        SetupCookingZone(id, restaurant.zones.fryer, 'fryer')
    end
    
    if restaurant.zones.oven then
        SetupCookingZone(id, restaurant.zones.oven, 'oven')
    end
    
    if restaurant.zones.drinks then
        SetupCookingZone(id, restaurant.zones.drinks, 'drinks')
    end
    
    -- Stash Zones
    if restaurant.zones.stash_fridge then
        SetupStashZone(id, restaurant.zones.stash_fridge, 'fridge')
    end
    
    if restaurant.zones.stash_freezer then
        SetupStashZone(id, restaurant.zones.stash_freezer, 'freezer')
    end
    
    if restaurant.zones.stash_storage then
        SetupStashZone(id, restaurant.zones.stash_storage, 'storage')
    end
    
    -- Serving Trays
    if restaurant.zones.trays and restaurant.features.serving_trays then
        for _, tray in ipairs(restaurant.zones.trays) do
            SetupTrayZone(id, tray)
        end
    end
    
    -- Offline Shop
    if restaurant.zones.offline_shop and restaurant.features.offlineShop then
        SetupOfflineShopZone(id, restaurant.zones.offline_shop)
    end
    
    -- Flyer Stand
    if restaurant.zones.flyer and restaurant.features.flyer then
        SetupFlyerZone(id, restaurant.zones.flyer)
    end
    
    -- Music Player
    if restaurant.zones.music and restaurant.features.music then
        SetupMusicZone(id, restaurant.zones.music)
    end
    
    -- Drive-Through
    if restaurant.zones.drivethrough_speaker and restaurant.features.driveThrough then
        SetupDriveThroughZone(id, restaurant.zones.drivethrough_speaker)
    end
end

--=====================================================
-- BOSS MENU ZONE
--=====================================================

function SetupBossMenuZone(restaurant, zone)
    local zoneName = restaurant .. '_bossmenu'
    
    Target.AddBoxZone({
        name = zoneName,
        coords = zone.coords,
        size = zone.size or vector3(1.0, 1.0, 2.0),
        heading = zone.heading or 0.0,
        minZ = zone.minZ or zone.coords.z - 1.0,
        maxZ = zone.maxZ or zone.coords.z + 1.0,
        distance = zone.distance or 2.0,
        options = {
            {
                icon = zone.icon or 'fa-solid fa-briefcase',
                label = zone.label or 'Boss Menu',
                canInteract = function()
                    return lib.callback.await('fx-restaurant:hasJobGrade', false, restaurant, 'boss_menu')
                end,
                onSelect = function()
                    exports['fx-restaurant']:OpenBossMenu(restaurant)
                end
            }
        }
    })
    
    activeZones[zoneName] = true
    print(('^2[ZONE] Boss Menu created: %s^0'):format(zoneName))
end

--=====================================================
-- CASHIER ZONE
--=====================================================

function SetupCashierZone(restaurant, zone, index)
    local zoneName = restaurant .. '_cashier_' .. index
    
    Target.AddBoxZone({
        name = zoneName,
        coords = zone.coords,
        size = zone.size or vector3(1.0, 1.0, 2.0),
        heading = zone.heading or 0.0,
        minZ = zone.minZ or zone.coords.z - 1.0,
        maxZ = zone.maxZ or zone.coords.z + 1.0,
        distance = zone.distance or 2.0,
        options = {
            {
                icon = zone.icon or 'fa-solid fa-cash-register',
                label = zone.label or 'Kassa',
                canInteract = function()
                    return lib.callback.await('fx-restaurant:hasJobGrade', false, restaurant, 'cashier')
                end,
                onSelect = function()
                    exports['fx-restaurant']:OpenCashier(restaurant)
                end
            }
        }
    })
    
    activeZones[zoneName] = true
end

--=====================================================
-- PREPARATION ZONE
--=====================================================

function SetupPreparationZone(restaurant, zone)
    local zoneName = restaurant .. '_preparation'
    
    Target.AddBoxZone({
        name = zoneName,
        coords = zone.coords,
        size = zone.size or vector3(2.0, 1.0, 1.5),
        heading = zone.heading or 0.0,
        minZ = zone.minZ or zone.coords.z - 1.0,
        maxZ = zone.maxZ or zone.coords.z + 1.0,
        distance = zone.distance or 2.0,
        options = {
            {
                icon = zone.icon or 'fa-solid fa-knife',
                label = zone.label or 'Snijplank',
                canInteract = function()
                    return lib.callback.await('fx-restaurant:hasJob', false, restaurant)
                end,
                onSelect = function()
                    exports['fx-restaurant']:OpenPreparationStation('cutting')
                end
            }
        }
    })
    
    activeZones[zoneName] = true
end

--=====================================================
-- COOKING ZONE
--=====================================================

function SetupCookingZone(restaurant, zone, stationType)
    local zoneName = restaurant .. '_' .. stationType
    
    Target.AddBoxZone({
        name = zoneName,
        coords = zone.coords,
        size = zone.size or vector3(2.0, 1.0, 1.5),
        heading = zone.heading or 0.0,
        minZ = zone.minZ or zone.coords.z - 1.0,
        maxZ = zone.maxZ or zone.coords.z + 1.0,
        distance = zone.distance or 2.0,
        options = {
            {
                icon = zone.icon or 'fa-solid fa-fire-burner',
                label = zone.label or 'Koken',
                canInteract = function()
                    return lib.callback.await('fx-restaurant:hasJob', false, restaurant)
                end,
                onSelect = function()
                    exports['fx-restaurant']:OpenCookingStation(restaurant, stationType)
                end
            }
        }
    })
    
    activeZones[zoneName] = true
end

--=====================================================
-- STASH ZONE
--=====================================================

function SetupStashZone(restaurant, zone, stashType)
    local zoneName = restaurant .. '_stash_' .. stashType
    local stashId = zone.stashId or zoneName
    
    Target.AddBoxZone({
        name = zoneName,
        coords = zone.coords,
        size = zone.size or vector3(1.5, 1.0, 2.0),
        heading = zone.heading or 0.0,
        minZ = zone.minZ or zone.coords.z - 1.0,
        maxZ = zone.maxZ or zone.coords.z + 1.0,
        distance = zone.distance or 2.0,
        options = {
            {
                icon = zone.icon or 'fa-solid fa-box',
                label = zone.label or 'Opslag',
                canInteract = function()
                    return lib.callback.await('fx-restaurant:hasJob', false, restaurant)
                end,
                onSelect = function()
                    -- Open ox_inventory stash
                    if GetResourceState('ox_inventory') == 'started' then
                        exports.ox_inventory:openInventory('stash', stashId)
                    else
                        lib.notify({
                            title = 'Opslag',
                            description = 'Inventory systeem niet gevonden',
                            type = 'error'
                        })
                    end
                end
            }
        }
    })
    
    activeZones[zoneName] = true
end

--=====================================================
-- TRAY ZONE
--=====================================================

function SetupTrayZone(restaurant, zone)
    local zoneName = restaurant .. '_tray_' .. zone.trayId
    
    Target.AddBoxZone({
        name = zoneName,
        coords = zone.coords,
        size = zone.size or vector3(1.0, 0.5, 0.3),
        heading = zone.heading or 0.0,
        minZ = zone.minZ or zone.coords.z - 0.1,
        maxZ = zone.maxZ or zone.coords.z + 0.3,
        distance = zone.distance or 2.0,
        options = {
            {
                icon = zone.icon or 'fa-solid fa-utensils',
                label = zone.label or 'Dienblad',
                onSelect = function()
                    exports['fx-restaurant']:OpenTray(restaurant, zone.trayId)
                end
            }
        }
    })
    
    activeZones[zoneName] = true
end

--=====================================================
-- OFFLINE SHOP ZONE
--=====================================================

function SetupOfflineShopZone(restaurant, zone)
    local zoneName = restaurant .. '_offline_shop'
    
    Target.AddBoxZone({
        name = zoneName,
        coords = zone.coords,
        size = zone.size or vector3(1.5, 1.0, 2.0),
        heading = zone.heading or 0.0,
        minZ = zone.minZ or zone.coords.z - 1.0,
        maxZ = zone.maxZ or zone.coords.z + 1.0,
        distance = zone.distance or 2.0,
        options = {
            {
                icon = zone.icon or 'fa-solid fa-store',
                label = zone.label or 'Winkel',
                onSelect = function()
                    -- TODO: Open Offline Shop
                    lib.notify({
                        title = 'Winkel',
                        description = 'Offline shop komt binnenkort',
                        type = 'info'
                    })
                end
            }
        }
    })
    
    activeZones[zoneName] = true
end

--=====================================================
-- FLYER ZONE
--=====================================================

function SetupFlyerZone(restaurant, zone)
    local zoneName = restaurant .. '_flyer'
    
    Target.AddBoxZone({
        name = zoneName,
        coords = zone.coords,
        size = zone.size or vector3(0.5, 0.5, 1.0),
        heading = zone.heading or 0.0,
        minZ = zone.minZ or zone.coords.z - 1.0,
        maxZ = zone.maxZ or zone.coords.z + 1.0,
        distance = zone.distance or 2.0,
        options = {
            {
                icon = zone.icon or 'fa-solid fa-file',
                label = zone.label or 'Menu Flyer',
                onSelect = function()
                    -- TODO: Give Flyer Item
                    lib.notify({
                        title = 'Menu Flyer',
                        description = 'Flyer systeem komt binnenkort',
                        type = 'info'
                    })
                end
            }
        }
    })
    
    activeZones[zoneName] = true
end

--=====================================================
-- MUSIC ZONE
--=====================================================

function SetupMusicZone(restaurant, zone)
    local zoneName = restaurant .. '_music'
    
    Target.AddBoxZone({
        name = zoneName,
        coords = zone.coords,
        size = zone.size or vector3(1.0, 1.0, 1.5),
        heading = zone.heading or 0.0,
        minZ = zone.minZ or zone.coords.z - 1.0,
        maxZ = zone.maxZ or zone.coords.z + 1.0,
        distance = zone.distance or 2.0,
        options = {
            {
                icon = zone.icon or 'fa-solid fa-music',
                label = zone.label or 'Muziekspeler',
                canInteract = function()
                    return lib.callback.await('fx-restaurant:hasJobGrade', false, restaurant, 'music')
                end,
                onSelect = function()
                    -- TODO: Open Music UI
                    lib.notify({
                        title = 'Muziekspeler',
                        description = 'Muziek systeem komt binnenkort',
                        type = 'info'
                    })
                end
            }
        }
    })
    
    activeZones[zoneName] = true
end

--=====================================================
-- DRIVE-THROUGH ZONE
--=====================================================

function SetupDriveThroughZone(restaurant, zone)
    local zoneName = restaurant .. '_drivethrough'
    
    Target.AddBoxZone({
        name = zoneName,
        coords = zone.coords,
        size = zone.size or vector3(1.5, 1.5, 2.0),
        heading = zone.heading or 0.0,
        minZ = zone.minZ or zone.coords.z - 1.0,
        maxZ = zone.maxZ or zone.coords.z + 1.0,
        distance = zone.distance or 3.0,
        options = {
            {
                icon = zone.icon or 'fa-solid fa-car',
                label = zone.label or 'Drive-Through',
                onSelect = function()
                    -- TODO: Trigger Drive-Through
                    lib.notify({
                        title = 'Drive-Through',
                        description = 'Drive-through systeem komt binnenkort',
                        type = 'info'
                    })
                end
            }
        }
    })
    
    activeZones[zoneName] = true
end

--=====================================================
-- INITIALIZE ALL RESTAURANTS
--=====================================================

CreateThread(function()
    Wait(1000) -- Wait for resources to load
    
    local restaurants = { 'default', 'burgershot' } -- Add more as needed
    
    for _, restaurantId in ipairs(restaurants) do
        local config = LoadRestaurantConfig(restaurantId)
        if config then
            SetupRestaurantZones(config)
        end
    end
    
    print('^2[FX-RESTAURANT] All zones initialized^0')
end)

--=====================================================
-- CLEANUP ON RESOURCE STOP
--=====================================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- Remove all zones
    for zoneName, _ in pairs(activeZones) do
        if Target and Target.RemoveZone then
            Target.RemoveZone(zoneName)
        end
    end
end)