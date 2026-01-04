--=====================================================
-- FX-RESTAURANT | DRIVE-THROUGH (SERVER)
--=====================================================

local Bridge = exports['fx-restaurant']:GetBridge()
local ActiveOrders = {} -- player orders

--=====================================================
-- NOTIFY STAFF
--=====================================================

RegisterNetEvent('fx-restaurant:drivethrough:notify', function(restaurant)
    local src = source
    local customerName = GetPlayerName(src)
    
    -- Find all staff members
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        
        if exports['fx-restaurant']:HasJob(targetId, restaurant) then
            TriggerClientEvent('fx-restaurant:drivethrough:staffNotify', targetId, restaurant, customerName)
        end
    end
end)

--=====================================================
-- GET MENU
--=====================================================

lib.callback.register('fx-restaurant:drivethrough:getMenu', function(src, restaurant)
    -- Get active recipes
    local recipes = exports['fx-restaurant']:GetRecipes(restaurant)
    local items = {}
    
    for id, recipe in pairs(recipes) do
        if recipe.active then
            table.insert(items, {
                item = recipe.name:lower():gsub(' ', '_'),
                name = recipe.name,
                price = recipe.price,
                recipeId = id
            })
        end
    end
    
    return items
end)

--=====================================================
-- PLACE ORDER
--=====================================================

lib.callback.register('fx-restaurant:drivethrough:placeOrder', function(src, restaurant, items)
    if not items or #items == 0 then
        return false, 'empty_order'
    end
    
    local Framework = Bridge.Framework
    if not Framework then
        return false, 'framework_error'
    end
    
    -- Calculate total
    local total = 0
    for _, item in ipairs(items) do
        total = total + (item.price * item.amount)
    end
    
    -- Check money
    local money = Framework.GetMoney(src, 'cash')
    if money < total then
        -- Try bank
        money = Framework.GetMoney(src, 'bank')
        if money < total then
            return false, 'insufficient_funds'
        end
        
        -- Pay from bank
        if not Framework.RemoveMoney(src, 'bank', total) then
            return false, 'payment_failed'
        end
    else
        -- Pay from cash
        if not Framework.RemoveMoney(src, 'cash', total) then
            return false, 'payment_failed'
        end
    end
    
    -- Generate order number
    local orderNumber = 'DT-' .. string.format('%04d', math.random(1, 9999))
    
    -- Get customer info
    local identifier = Framework.GetIdentifier(src)
    local name = GetPlayerName(src)
    
    -- Insert order
    local orderId = MySQL.insert.await([[
        INSERT INTO restaurant_orders
        (restaurant, order_number, customer_identifier, customer_name, items, total_price, status, order_type)
        VALUES (?, ?, ?, ?, ?, ?, 'preparing', 'drive_through')
    ]], {
        restaurant,
        orderNumber,
        identifier,
        name,
        json.encode(items),
        total
    })
    
    if not orderId then
        -- Refund on failure
        Framework.AddMoney(src, 'cash', total)
        return false, 'database_error'
    end
    
    -- Store active order
    ActiveOrders[src] = {
        orderId = orderId,
        orderNumber = orderNumber,
        restaurant = restaurant,
        items = items,
        total = total,
        timestamp = os.time()
    }
    
    -- Get pickup coords
    local configPath = ('shared/restaurants/%s/config.lua'):format(restaurant)
    local configData = LoadResourceFile(GetCurrentResourceName(), configPath)
    
    local pickupCoords = nil
    if configData then
        local env = { Restaurant = nil }
        local chunk = load(configData, configPath, 't', env)
        if chunk then pcall(chunk) end
        local config = env.Restaurant
        
        if config and config.zones and config.zones.drivethrough_pickup then
            pickupCoords = config.zones.drivethrough_pickup.coords
        end
    end
    
    -- Update statistics
    MySQL.insert.await([[
        INSERT INTO restaurant_stats (restaurant, stat_date, total_orders, total_revenue)
        VALUES (?, CURDATE(), 1, ?)
        ON DUPLICATE KEY UPDATE 
            total_orders = total_orders + 1,
            total_revenue = total_revenue + ?
    ]], { restaurant, total, total })
    
    return true, {
        orderId = orderId,
        orderNumber = orderNumber,
        total = total,
        pickupCoords = pickupCoords
    }
end)

--=====================================================
-- PICKUP ORDER
--=====================================================

lib.callback.register('fx-restaurant:drivethrough:pickup', function(src, restaurant)
    local order = ActiveOrders[src]
    
    if not order or order.restaurant ~= restaurant then
        return false, 'no_order'
    end
    
    -- Check if order is ready (simulate preparation time)
    local timePassed = os.time() - order.timestamp
    if timePassed < 30 then -- 30 seconds minimum
        return false, 'not_ready'
    end
    
    local Inventory = Bridge.Inventory
    if not Inventory then
        return false, 'inventory_error'
    end
    
    -- Give items to player
    for _, item in ipairs(order.items) do
        local itemName = item.item
        
        -- Check if item exists
        if not ItemExists(itemName) then
            itemName = 'burger' -- Fallback
        end
        
        if not Inventory.CanCarryItem(src, itemName, item.amount) then
            return false, 'inventory_full'
        end
        
        Inventory.AddItem(src, itemName, item.amount)
    end
    
    -- Update order status
    MySQL.update.await(
        'UPDATE restaurant_orders SET status = ?, completed_at = NOW() WHERE id = ?',
        { 'completed', order.orderId }
    )
    
    -- Remove active order
    ActiveOrders[src] = nil
    
    return true, {
        orderNumber = order.orderNumber
    }
end)

--=====================================================
-- GET ACTIVE ORDERS (For staff)
--=====================================================

lib.callback.register('fx-restaurant:drivethrough:getOrders', function(src, restaurant)
    if not exports['fx-restaurant']:HasJob(src, restaurant) then
        return {}
    end
    
    local orders = MySQL.query.await([[
        SELECT * FROM restaurant_orders
        WHERE restaurant = ? AND order_type = 'drive_through' AND status = 'preparing'
        ORDER BY created_at DESC
        LIMIT 10
    ]], { restaurant })
    
    return orders or {}
end)

--=====================================================
-- MARK ORDER READY
--=====================================================

lib.callback.register('fx-restaurant:drivethrough:markReady', function(src, orderId)
    -- Get order
    local order = MySQL.single.await(
        'SELECT restaurant FROM restaurant_orders WHERE id = ?',
        { orderId }
    )
    
    if not order then
        return false
    end
    
    -- Check permission
    if not exports['fx-restaurant']:HasJob(src, order.restaurant) then
        return false
    end
    
    -- Update status
    MySQL.update.await(
        'UPDATE restaurant_orders SET status = ? WHERE id = ?',
        { 'ready', orderId }
    )
    
    return true
end)

--=====================================================
-- CLEANUP ON DISCONNECT
--=====================================================

AddEventHandler('playerDropped', function()
    local src = source
    
    -- Cancel active order
    if ActiveOrders[src] then
        MySQL.update.await(
            'UPDATE restaurant_orders SET status = ? WHERE id = ?',
            { 'cancelled', ActiveOrders[src].orderId }
        )
        ActiveOrders[src] = nil
    end
end)