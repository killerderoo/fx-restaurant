--=====================================================
-- FX-RESTAURANT | DELIVERY SYSTEM (SERVER)
--=====================================================
-- Order generation, tracking & payment
--=====================================================

local Bridge = exports['fx-restaurant']:GetBridge()
local ActiveDeliveries = {} -- player deliveries
local DeliveryCooldowns = {} -- cooldown per player

--=====================================================
-- CONFIG
--=====================================================

local COOLDOWN_TIME = 600 -- 10 minutes in seconds
local MIN_ITEMS = 1
local MAX_ITEMS = 5
local TIP_CHANCE = 0.7 -- 70% chance
local TIP_MIN = 10
local TIP_MAX = 50

--=====================================================
-- GENERATE RANDOM ORDER
--=====================================================

---Generate random delivery order
---@param restaurant string
---@return table|false
local function GenerateRandomOrder(restaurant)
    -- Get restaurant config
    local configPath = ('shared/restaurants/%s/config.lua'):format(restaurant)
    local configData = LoadResourceFile(GetCurrentResourceName(), configPath)
    
    if not configData then
        return false
    end
    
    local env = { Restaurant = nil }
    local chunk = load(configData, configPath, 't', env)
    if not chunk then return false end
    
    pcall(chunk)
    local config = env.Restaurant
    
    if not config or not config.delivery or not config.delivery.enabled then
        return false
    end
    
    -- Get available items
    local availableItems = config.delivery.available_items or {}
    if #availableItems == 0 then
        return false
    end
    
    -- Generate items
    local itemCount = math.random(MIN_ITEMS, MAX_ITEMS)
    local items = {}
    
    for i = 1, itemCount do
        local item = availableItems[math.random(1, #availableItems)]
        local amount = math.random(1, 3)
        
        -- Check if item already in order
        local found = false
        for _, orderItem in ipairs(items) do
            if orderItem.item == item then
                orderItem.amount = orderItem.amount + amount
                found = true
                break
            end
        end
        
        if not found then
            local itemData = GetItemData(item)
            table.insert(items, {
                item = item,
                label = itemData.label or item,
                amount = amount
            })
        end
    end
    
    -- Select random location
    if not Config.DeliveryLocations or #Config.DeliveryLocations == 0 then
        return false
    end
    
    local location = Config.DeliveryLocations[math.random(1, #Config.DeliveryLocations)]
    
    -- Calculate payment
    local basePayment = math.random(config.delivery.payment.min, config.delivery.payment.max)
    
    -- Add tip chance
    local tip = 0
    if math.random() <= TIP_CHANCE then
        tip = math.random(TIP_MIN, TIP_MAX)
    end
    
    return {
        items = items,
        location = location,
        payment = basePayment,
        tip = tip,
        total = basePayment + tip
    }
end

--=====================================================
-- START DELIVERY
--=====================================================

lib.callback.register('fx-restaurant:delivery:start', function(src, restaurant)
    -- Check cooldown
    if DeliveryCooldowns[src] then
        local timeLeft = DeliveryCooldowns[src] - os.time()
        if timeLeft > 0 then
            return false, 'cooldown', timeLeft
        end
    end
    
    -- Check if already on delivery
    if ActiveDeliveries[src] then
        return false, 'already_active'
    end
    
    -- Check job
    if not exports['fx-restaurant']:HasJob(src, restaurant) then
        return false, 'no_job'
    end
    
    -- Generate order
    local order = GenerateRandomOrder(restaurant)
    if not order then
        return false, 'generation_failed'
    end
    
    -- Create delivery record
    local deliveryNumber = 'DEL-' .. string.format('%06d', math.random(1, 999999))
    
    local Framework = Bridge.Framework
    local driverIdentifier = Framework.GetIdentifier(src)
    local driverName = GetPlayerName(src)
    
    local deliveryId = MySQL.insert.await([[
        INSERT INTO restaurant_deliveries
        (restaurant, delivery_number, driver_identifier, driver_name, 
         items, location, coords, payment, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'assigned')
    ]], {
        restaurant,
        deliveryNumber,
        driverIdentifier,
        driverName,
        json.encode(order.items),
        order.location.name,
        json.encode({
            x = order.location.coords.x,
            y = order.location.coords.y,
            z = order.location.coords.z
        }),
        order.total
    })
    
    if not deliveryId then
        return false, 'database_error'
    end
    
    -- Store active delivery
    ActiveDeliveries[src] = {
        id = deliveryId,
        deliveryNumber = deliveryNumber,
        restaurant = restaurant,
        order = order,
        status = 'assigned',
        startTime = os.time()
    }
    
    return true, {
        deliveryId = deliveryId,
        deliveryNumber = deliveryNumber,
        order = order
    }
end)

--=====================================================
-- UPDATE DELIVERY STATUS
--=====================================================

lib.callback.register('fx-restaurant:delivery:updateStatus', function(src, status)
    local delivery = ActiveDeliveries[src]
    if not delivery then
        return false, 'no_active_delivery'
    end
    
    delivery.status = status
    
    MySQL.update.await(
        'UPDATE restaurant_deliveries SET status = ? WHERE id = ?',
        { status, delivery.id }
    )
    
    return true
end)

--=====================================================
-- COMPLETE DELIVERY
--=====================================================

lib.callback.register('fx-restaurant:delivery:complete', function(src, hasAllItems)
    local delivery = ActiveDeliveries[src]
    if not delivery then
        return false, 'no_active_delivery'
    end
    
    local Framework = Bridge.Framework
    local Inventory = Bridge.Inventory
    
    if not Framework or not Inventory then
        return false, 'bridge_error'
    end
    
    -- Check if player has all items
    if hasAllItems then
        for _, item in ipairs(delivery.order.items) do
            if not Inventory.HasItem(src, item.item, item.amount) then
                return false, 'missing_items'
            end
        end
        
        -- Remove items
        for _, item in ipairs(delivery.order.items) do
            Inventory.RemoveItem(src, item.item, item.amount)
        end
    end
    
    -- Calculate payment (reduced if missing items)
    local payment = delivery.order.total
    if not hasAllItems then
        payment = math.floor(payment * 0.5) -- 50% payment if incomplete
    end
    
    -- Give money
    Framework.AddMoney(src, 'cash', payment)
    
    -- Update database
    MySQL.update.await([[
        UPDATE restaurant_deliveries 
        SET status = 'delivered', completed_at = NOW()
        WHERE id = ?
    ]], { delivery.id })
    
    -- Update statistics
    MySQL.insert.await([[
        INSERT INTO restaurant_stats (restaurant, stat_date, total_deliveries)
        VALUES (?, CURDATE(), 1)
        ON DUPLICATE KEY UPDATE total_deliveries = total_deliveries + 1
    ]], { delivery.restaurant })
    
    -- Set cooldown
    DeliveryCooldowns[src] = os.time() + COOLDOWN_TIME
    
    -- Remove active delivery
    ActiveDeliveries[src] = nil
    
    return true, {
        payment = payment,
        tip = hasAllItems and delivery.order.tip or 0,
        deliveryNumber = delivery.deliveryNumber
    }
end)

--=====================================================
-- CANCEL DELIVERY
--=====================================================

lib.callback.register('fx-restaurant:delivery:cancel', function(src)
    local delivery = ActiveDeliveries[src]
    if not delivery then
        return false, 'no_active_delivery'
    end
    
    -- Update database
    MySQL.update.await(
        'UPDATE restaurant_deliveries SET status = ? WHERE id = ?',
        { 'failed', delivery.id }
    )
    
    -- Remove active delivery
    ActiveDeliveries[src] = nil
    
    -- Short cooldown for cancellation
    DeliveryCooldowns[src] = os.time() + 60 -- 1 minute
    
    return true
end)

--=====================================================
-- GET ACTIVE DELIVERY
--=====================================================

lib.callback.register('fx-restaurant:delivery:getActive', function(src)
    return ActiveDeliveries[src]
end)

--=====================================================
-- CHECK COOLDOWN
--=====================================================

lib.callback.register('fx-restaurant:delivery:checkCooldown', function(src)
    if not DeliveryCooldowns[src] then
        return true, 0
    end
    
    local timeLeft = DeliveryCooldowns[src] - os.time()
    if timeLeft <= 0 then
        DeliveryCooldowns[src] = nil
        return true, 0
    end
    
    return false, timeLeft
end)

--=====================================================
-- CLEANUP ON DISCONNECT
--=====================================================

AddEventHandler('playerDropped', function()
    local src = source
    
    -- Cancel active delivery
    if ActiveDeliveries[src] then
        MySQL.update.await(
            'UPDATE restaurant_deliveries SET status = ? WHERE id = ?',
            { 'failed', ActiveDeliveries[src].id }
        )
        ActiveDeliveries[src] = nil
    end
end)
