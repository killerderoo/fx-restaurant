--=====================================================
-- FX-RESTAURANT | MAIN SERVER
--=====================================================
-- Centralized server functions & utilities
--=====================================================

local Bridge = exports['fx-restaurant']:GetBridge()

--=====================================================
-- RESOURCE START/STOP
--=====================================================

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    print([[
    ^2
    ====================================
        FX-RESTAURANT v1.0.0
        Advanced Restaurant System
    ====================================
    ^0
    ]])
    
    -- Verify dependencies
    local dependencies = {
        'ox_lib',
        'oxmysql'
    }
    
    for _, dep in ipairs(dependencies) do
        if GetResourceState(dep) ~= 'started' then
            print(('^1[ERROR] Dependency "%s" is not started!^0'):format(dep))
        end
    end
    
    -- Check database tables
    CreateThread(function()
        Wait(2000)
        
        local tables = {
            'restaurant_recipes',
            'restaurant_orders',
            'restaurant_invoices',
            'restaurant_employees',
            'restaurant_deliveries',
            'restaurant_shop_inventory',
            'restaurant_menu_images',
            'restaurant_music',
            'restaurant_props',
            'restaurant_stats'
        }
        
        for _, table in ipairs(tables) do
            local result = MySQL.scalar.await(
                string.format("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = '%s'", table)
            )
            
            if result == 0 then
                print(('^3[WARNING] Table "%s" does not exist!^0'):format(table))
            end
        end
        
        print('^2[FX-RESTAURANT] Database check complete^0')
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    print('^3[FX-RESTAURANT] Resource stopped^0')
end)

--=====================================================
-- PLAYER CONNECT/DISCONNECT
--=====================================================

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    
    -- You can add restaurant-specific connection logic here
    -- Example: Check for bans, reservations, etc.
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    
    -- Cleanup player data
    print(('^3[FX-RESTAURANT] Player %s disconnected: %s^0'):format(GetPlayerName(src), reason))
    
    -- Cancel active orders/deliveries handled in respective modules
end)

--=====================================================
-- ITEM USAGE HANDLERS
--=====================================================

-- Register useable items for consumption
CreateThread(function()
    if not Bridge.Inventory then
        print('^3[WARNING] Inventory bridge not initialized^0')
        return
    end
    
    -- Food & drink items
    local consumables = {
        'burger', 'cheeseburger', 'fries', 'salad',
        'cola', 'sprite', 'water', 'coffee'
    }
    
    for _, item in ipairs(consumables) do
        -- Register with framework
        if Config.Framework == 'esx' then
            ESX.RegisterUsableItem(item, function(source)
                UseConsumableItem(source, item)
            end)
        elseif Config.Framework == 'qb' then
            QBCore.Functions.CreateUseableItem(item, function(source, item)
                UseConsumableItem(source, item.name)
            end)
        end
    end
    
    print('^2[FX-RESTAURANT] Registered ' .. #consumables .. ' consumable items^0')
end)

---Handle item consumption
---@param src number
---@param item string
function UseConsumableItem(src, item)
    local Inventory = Bridge.Inventory
    if not Inventory then return end
    
    -- Check if player has item
    if not Inventory.HasItem(src, item, 1) then
        return
    end
    
    -- Remove item
    if not Inventory.RemoveItem(src, item, 1) then
        return
    end
    
    -- Apply effects
    if exports['fx-restaurant']:ApplyItemConsumption(src, item) then
        TriggerClientEvent('fx-restaurant:notify', src, {
            title = 'Consumptie',
            description = 'Je hebt iets gegeten/gedronken',
            type = 'success'
        })
    end
end

--=====================================================
-- HELPER: GET RESTAURANT CONFIG
--=====================================================

---Load restaurant config from file
---@param restaurantId string
---@return table|nil
function GetRestaurantConfig(restaurantId)
    local configPath = ('shared/restaurants/%s/config.lua'):format(restaurantId)
    local configData = LoadResourceFile(GetCurrentResourceName(), configPath)
    
    if not configData then
        return nil
    end
    
    local env = { Restaurant = nil }
    local chunk, err = load(configData, configPath, 't', env)
    
    if not chunk then
        print(('^1[ERROR] Failed to load restaurant config: %s^0'):format(err))
        return nil
    end
    
    local success, result = pcall(chunk)
    if not success then
        print(('^1[ERROR] Failed to execute restaurant config: %s^0'):format(result))
        return nil
    end
    
    return env.Restaurant
end

exports('GetRestaurantConfig', GetRestaurantConfig)

--=====================================================
-- HELPER: GET ITEM DATA
--=====================================================

---Get item data from shared items
---@param item string
---@return table|nil
function GetItemData(item)
    return Items[item]
end

exports('GetItemData', GetItemData)

--=====================================================
-- HELPER: ITEM EXISTS
--=====================================================

---Check if item exists
---@param item string
---@return boolean
function ItemExists(item)
    return Items[item] ~= nil
end

exports('ItemExists', ItemExists)

--=====================================================
-- HELPER: IS SELLABLE ITEM
--=====================================================

---Check if item can be sold in offline shop
---@param item string
---@return boolean
function IsSellableItem(item)
    local data = Items[item]
    return data and data.type == 'finished'
end

exports('IsSellableItem', IsSellableItem)

--=====================================================
-- HELPER: IS ITEM TYPE
--=====================================================

---Check item type
---@param item string
---@param itemType string
---@return boolean
function IsItemType(item, itemType)
    local data = Items[item]
    return data and data.type == itemType
end

exports('IsItemType', IsItemType)

--=====================================================
-- FLYER SYSTEM
--=====================================================

-- Get flyer (give item)
lib.callback.register('fx-restaurant:flyer:get', function(src, restaurant)
    local Inventory = Bridge.Inventory
    if not Inventory then return false end
    
    local flyerItem = restaurant .. '_menu'
    
    -- Check if item exists
    if not ItemExists(flyerItem) then
        flyerItem = 'restaurant_menu' -- Fallback
    end
    
    -- Give flyer
    if Inventory.AddItem(src, flyerItem, 1) then
        return true
    end
    
    return false
end)

-- Open flyer (get menu image)
lib.callback.register('fx-restaurant:flyer:open', function(src, flyerItem)
    -- Extract restaurant from item name
    local restaurant = flyerItem:gsub('_menu', '')
    
    -- Get menu image
    local menuImage = MySQL.single.await(
        'SELECT * FROM restaurant_menu_images WHERE restaurant = ? AND active = 1',
        { restaurant }
    )
    
    if not menuImage then
        return false
    end
    
    return true, {
        restaurant = restaurant,
        image = menuImage.image_url,
        title = menuImage.title or 'Menu'
    }
end)

--=====================================================
-- NOTIFICATION HANDLER
--=====================================================

RegisterNetEvent('fx-restaurant:notify', function(data)
    -- Server-side notification handler
    -- Can be extended for logging, etc.
end)

--=====================================================
-- ADMIN COMMANDS
--=====================================================

-- Reset restaurant
RegisterCommand('resetrestaurant', function(source, args)
    if source ~= 0 then
        -- Check admin permission
        if not IsPlayerAceAllowed(source, 'command.resetrestaurant') then
            return
        end
    end
    
    local restaurant = args[1]
    if not restaurant then
        print('^3Usage: /resetrestaurant [restaurant_id]^0')
        return
    end
    
    -- Call stored procedure
    MySQL.query.await('CALL sp_reset_restaurant(?)', { restaurant })
    
    print(('^2[FX-RESTAURANT] Reset restaurant: %s^0'):format(restaurant))
    
    if source ~= 0 then
        TriggerClientEvent('fx-restaurant:notify', source, {
            title = 'Restaurant Reset',
            description = restaurant .. ' has been reset',
            type = 'success'
        })
    end
end, true)

-- Give menu flyer
RegisterCommand('giveflyer', function(source, args)
    if source == 0 then return end
    
    if not IsPlayerAceAllowed(source, 'command.giveflyer') then
        return
    end
    
    local targetId = tonumber(args[1])
    local restaurant = args[2] or 'burgershot'
    
    if not targetId then
        TriggerClientEvent('fx-restaurant:notify', source, {
            title = 'Error',
            description = 'Usage: /giveflyer [player_id] [restaurant]',
            type = 'error'
        })
        return
    end
    
    local flyerItem = restaurant .. '_menu'
    if not ItemExists(flyerItem) then
        flyerItem = 'restaurant_menu'
    end
    
    if Bridge.Inventory.AddItem(targetId, flyerItem, 1) then
        TriggerClientEvent('fx-restaurant:notify', source, {
            title = 'Flyer Given',
            description = 'Menu flyer given to player',
            type = 'success'
        })
    end
end, true)

-- Stop music
RegisterCommand('stopmusic', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'command.stopmusic') then
        return
    end
    
    local restaurant = args[1]
    if not restaurant then
        print('^3Usage: /stopmusic [restaurant]^0')
        return
    end
    
    -- Trigger music stop
    TriggerClientEvent('fx-restaurant:music:sync', -1, restaurant, nil)
    
    -- Update database
    MySQL.update.await(
        'UPDATE restaurant_music SET playing = 0 WHERE restaurant = ?',
        { restaurant }
    )
    
    print(('^2[FX-RESTAURANT] Stopped music for: %s^0'):format(restaurant))
end, true)

--=====================================================
-- STATISTICS TRACKING
--=====================================================

CreateThread(function()
    while true do
        Wait(60000) -- Every minute
        
        -- Update daily stats
        local restaurants = { 'default', 'burgershot' } -- Add your restaurants
        
        for _, restaurant in ipairs(restaurants) do
            -- This is handled by individual modules, but can be centralized here
        end
    end
end)

--=====================================================
-- EXPORTS
--=====================================================

exports('GetRestaurantConfig', GetRestaurantConfig)
exports('GetItemData', GetItemData)
exports('ItemExists', ItemExists)
exports('IsSellableItem', IsSellableItem)
exports('IsItemType', IsItemType)

--=====================================================
-- CALLBACKS REGISTRATION
--=====================================================

-- Register global callbacks here if needed
lib.callback.register('fx-restaurant:getServerTime', function()
    return os.time()
end)

lib.callback.register('fx-restaurant:getRestaurantInfo', function(src, restaurant)
    local config = GetRestaurantConfig(restaurant)
    if not config then return nil end
    
    return {
        id = config.id,
        label = config.label,
        enabled = config.enabled,
        features = config.features
    }
end)

--=====================================================
-- READY
--=====================================================

print('^2[FX-RESTAURANT] Server-side initialized successfully^0')