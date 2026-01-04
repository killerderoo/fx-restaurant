--=====================================================
-- FX-RESTAURANT | OFFLINE SHOP (SERVER)
--=====================================================
-- Klanten kunnen items kopen zonder staff
--=====================================================

local Bridge = exports['fx-restaurant']:GetBridge()

--=====================================================
-- GET SHOP INVENTORY
--=====================================================

lib.callback.register('fx-restaurant:offlineshop:getInventory', function(src, restaurant)
    if not restaurant then
        return false, { error = 'invalid_restaurant' }
    end
    
    -- Get active items
    local items = MySQL.query.await([[
        SELECT * FROM restaurant_shop_inventory 
        WHERE restaurant = ? AND active = 1 AND stock > 0
        ORDER BY label ASC
    ]], { restaurant })
    
    return true, {
        items = items or {},
        currency = 'cash' -- or 'bank'
    }
end)

--=====================================================
-- PURCHASE FROM OFFLINE SHOP
--=====================================================

lib.callback.register('fx-restaurant:offlineshop:purchase', function(src, restaurant, cart, paymentMethod)
    if not restaurant or not cart or #cart == 0 then
        return false, 'invalid_data'
    end
    
    local Framework = Bridge.Framework
    local Inventory = Bridge.Inventory
    
    if not Framework or not Inventory then
        return false, 'bridge_error'
    end
    
    -- Validate payment method
    if paymentMethod ~= 'cash' and paymentMethod ~= 'bank' then
        return false, 'invalid_payment'
    end
    
    -- Calculate total and check stock
    local total = 0
    local stockChecks = {}
    
    for _, item in ipairs(cart) do
        -- Get current stock
        local stock = MySQL.scalar.await(
            'SELECT stock FROM restaurant_shop_inventory WHERE restaurant = ? AND item = ? AND active = 1',
            { restaurant, item.item }
        )
        
        if not stock or stock < item.amount then
            return false, 'out_of_stock'
        end
        
        stockChecks[item.item] = stock
        total = total + (item.price * item.amount)
    end
    
    -- Check money
    local money = Framework.GetMoney(src, paymentMethod)
    if money < total then
        return false, 'insufficient_funds'
    end
    
    -- Check inventory space
    for _, item in ipairs(cart) do
        if not Inventory.CanCarryItem(src, item.item, item.amount) then
            return false, 'inventory_full'
        end
    end
    
    -- Process payment
    if not Framework.RemoveMoney(src, paymentMethod, total) then
        return false, 'payment_failed'
    end
    
    -- Give items and update stock
    for _, item in ipairs(cart) do
        -- Give item
        if not Inventory.AddItem(src, item.item, item.amount) then
            -- Refund on failure
            Framework.AddMoney(src, paymentMethod, total)
            return false, 'add_failed'
        end
        
        -- Update stock
        MySQL.update.await(
            'UPDATE restaurant_shop_inventory SET stock = stock - ? WHERE restaurant = ? AND item = ?',
            { item.amount, restaurant, item.item }
        )
    end
    
    -- Update statistics
    MySQL.insert.await([[
        INSERT INTO restaurant_stats (restaurant, stat_date, total_orders, total_revenue)
        VALUES (?, CURDATE(), 1, ?)
        ON DUPLICATE KEY UPDATE 
            total_orders = total_orders + 1,
            total_revenue = total_revenue + ?
    ]], { restaurant, total, total })
    
    -- Log transaction
    local identifier = Framework.GetIdentifier(src)
    local name = GetPlayerName(src)
    
    MySQL.insert.await([[
        INSERT INTO restaurant_orders
        (restaurant, order_number, customer_identifier, customer_name, items, total_price, status, order_type)
        VALUES (?, ?, ?, ?, ?, ?, 'completed', 'takeaway')
    ]], {
        restaurant,
        'SHOP-' .. string.format('%06d', math.random(1, 999999)),
        identifier,
        name,
        json.encode(cart),
        total
    })
    
    return true, {
        total = total,
        paymentMethod = paymentMethod
    }
end)

--=====================================================
-- RESTOCK (ADMIN/BOSS)
--=====================================================

lib.callback.register('fx-restaurant:offlineshop:restock', function(src, restaurant, item, amount)
    -- Check permission
    if not exports['fx-restaurant']:HasJobGrade(src, restaurant, 'manage_shop') then
        return false, 'no_permission'
    end
    
    if not item or not amount or amount <= 0 then
        return false, 'invalid_data'
    end
    
    -- Update stock
    local affected = MySQL.update.await(
        'UPDATE restaurant_shop_inventory SET stock = stock + ? WHERE restaurant = ? AND item = ?',
        { amount, restaurant, item }
    )
    
    if affected == 0 then
        return false, 'item_not_found'
    end
    
    return true, { item = item, amount = amount }
end)

--=====================================================
-- GET STOCK LEVELS (For staff)
--=====================================================

lib.callback.register('fx-restaurant:offlineshop:getStock', function(src, restaurant)
    if not exports['fx-restaurant']:HasJob(src, restaurant) then
        return {}
    end
    
    local items = MySQL.query.await(
        'SELECT * FROM restaurant_shop_inventory WHERE restaurant = ? ORDER BY label ASC',
        { restaurant }
    )
    
    return items or {}
end)