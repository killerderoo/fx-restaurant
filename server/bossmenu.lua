--=====================================================
-- FX-RESTAURANT | BOSS MENU (SERVER)
--=====================================================
-- Management, Recipes, Menu Images, Offline Shop
--=====================================================

local Bridge = exports['fx-restaurant']:GetBridge()

--=====================================================
-- PERMISSIONS CHECK
--=====================================================

local function HasPermission(src, restaurant, permission)
    local Framework = Bridge.Framework
    if not Framework then return false end
    
    if not Framework.HasJob(src, restaurant) then
        return false
    end
    
    -- Get restaurant config
    local config = GetRestaurantConfig(restaurant)
    if not config or not config.permissions then
        return false
    end
    
    local requiredGrade = config.permissions[permission]
    if not requiredGrade then return false end
    
    return Framework.HasJobGrade(src, restaurant, requiredGrade)
end

--=====================================================
-- OPEN BOSS MENU
--=====================================================

lib.callback.register('fx-restaurant:bossmenu:open', function(src, restaurant)
    if not HasPermission(src, restaurant, 'boss_menu') then
        return false, 'no_permission'
    end
    
    return true
end)

--=====================================================
-- GET MANAGEMENT DATA
--=====================================================

lib.callback.register('fx-restaurant:bossmenu:getManagement', function(src, restaurant)
    if not HasPermission(src, restaurant, 'boss_menu') then
        return false, 'no_permission'
    end
    
    -- Get employees
    local employees = MySQL.query.await(
        'SELECT * FROM restaurant_employees WHERE restaurant = ?',
        { restaurant }
    )
    
    -- Get statistics (last 30 days)
    local stats = MySQL.query.await([[
        SELECT 
            SUM(total_orders) as total_orders,
            SUM(total_revenue) as total_revenue,
            SUM(total_deliveries) as total_deliveries
        FROM restaurant_stats
        WHERE restaurant = ? AND stat_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    ]], { restaurant })
    
    -- Get today's stats
    local today = MySQL.query.await([[
        SELECT 
            COUNT(*) as orders_today,
            SUM(total_price) as revenue_today
        FROM restaurant_orders
        WHERE restaurant = ? AND DATE(created_at) = CURDATE() AND status = 'completed'
    ]], { restaurant })
    
    return {
        employees = employees or {},
        stats = {
            total_orders = stats[1] and stats[1].total_orders or 0,
            total_revenue = stats[1] and stats[1].total_revenue or 0,
            total_deliveries = stats[1] and stats[1].total_deliveries or 0,
            orders_today = today[1] and today[1].orders_today or 0,
            revenue_today = today[1] and today[1].revenue_today or 0
        }
    }
end)

--=====================================================
-- EMPLOYEE MANAGEMENT
--=====================================================

-- Hire Employee
lib.callback.register('fx-restaurant:bossmenu:hireEmployee', function(src, restaurant, targetId)
    if not HasPermission(src, restaurant, 'boss_menu') then
        return false, 'no_permission'
    end
    
    local Framework = Bridge.Framework
    local targetIdentifier = Framework.GetIdentifier(targetId)
    
    if not targetIdentifier then
        return false, 'player_not_found'
    end
    
    -- Check if already employed
    local existing = MySQL.scalar.await(
        'SELECT id FROM restaurant_employees WHERE restaurant = ? AND identifier = ?',
        { restaurant, targetIdentifier }
    )
    
    if existing then
        return false, 'already_employed'
    end
    
    -- Get player name
    local targetPlayer = Framework.GetPlayer(targetId)
    local name = targetPlayer and targetPlayer.getName() or 'Unknown'
    
    -- Insert employee
    MySQL.insert.await(
        'INSERT INTO restaurant_employees (restaurant, identifier, name, grade) VALUES (?, ?, ?, ?)',
        { restaurant, targetIdentifier, name, 0 }
    )
    
    -- Set job in framework
    if Config.Framework == 'esx' then
        TriggerEvent('esx:setJob', targetId, restaurant, 0)
    elseif Config.Framework == 'qb' then
        targetPlayer.Functions.SetJob(restaurant, 0)
    end
    
    return true, 'hired'
end)

-- Fire Employee
lib.callback.register('fx-restaurant:bossmenu:fireEmployee', function(src, restaurant, employeeId)
    if not HasPermission(src, restaurant, 'boss_menu') then
        return false, 'no_permission'
    end
    
    local employee = MySQL.single.await(
        'SELECT * FROM restaurant_employees WHERE id = ? AND restaurant = ?',
        { employeeId, restaurant }
    )
    
    if not employee then
        return false, 'not_found'
    end
    
    -- Delete from database
    MySQL.update.await(
        'DELETE FROM restaurant_employees WHERE id = ?',
        { employeeId }
    )
    
    -- Update framework job if online
    local Framework = Bridge.Framework
    local players = GetPlayers()
    
    for _, playerId in pairs(players) do
        local identifier = Framework.GetIdentifier(tonumber(playerId))
        if identifier == employee.identifier then
            if Config.Framework == 'esx' then
                TriggerEvent('esx:setJob', tonumber(playerId), 'unemployed', 0)
            elseif Config.Framework == 'qb' then
                local Player = Framework.GetPlayer(tonumber(playerId))
                if Player then
                    Player.Functions.SetJob('unemployed', 0)
                end
            end
            break
        end
    end
    
    return true, 'fired'
end)

-- Set Employee Grade
lib.callback.register('fx-restaurant:bossmenu:setEmployeeGrade', function(src, restaurant, employeeId, grade)
    if not HasPermission(src, restaurant, 'boss_menu') then
        return false, 'no_permission'
    end
    
    if grade < 0 or grade > 4 then
        return false, 'invalid_grade'
    end
    
    local employee = MySQL.single.await(
        'SELECT * FROM restaurant_employees WHERE id = ? AND restaurant = ?',
        { employeeId, restaurant }
    )
    
    if not employee then
        return false, 'not_found'
    end
    
    -- Update database
    MySQL.update.await(
        'UPDATE restaurant_employees SET grade = ? WHERE id = ?',
        { grade, employeeId }
    )
    
    -- Update framework job if online
    local Framework = Bridge.Framework
    local players = GetPlayers()
    
    for _, playerId in pairs(players) do
        local identifier = Framework.GetIdentifier(tonumber(playerId))
        if identifier == employee.identifier then
            if Config.Framework == 'esx' then
                TriggerEvent('esx:setJob', tonumber(playerId), restaurant, grade)
            elseif Config.Framework == 'qb' then
                local Player = Framework.GetPlayer(tonumber(playerId))
                if Player then
                    Player.Functions.SetJob(restaurant, grade)
                end
            end
            break
        end
    end
    
    return true, 'updated'
end)

--=====================================================
-- MENU IMAGES MANAGEMENT
--=====================================================

-- Get Menu Images
lib.callback.register('fx-restaurant:bossmenu:getMenuImages', function(src, restaurant)
    if not HasPermission(src, restaurant, 'boss_menu') then
        return false, 'no_permission'
    end
    
    local images = MySQL.query.await(
        'SELECT * FROM restaurant_menu_images WHERE restaurant = ?',
        { restaurant }
    )
    
    return images or {}
end)

-- Update Menu Image
lib.callback.register('fx-restaurant:bossmenu:updateMenuImage', function(src, restaurant, imageUrl, title)
    if not HasPermission(src, restaurant, 'boss_menu') then
        return false, 'no_permission'
    end
    
    -- Validate URL (must be ibb.co or imgur)
    if not string.match(imageUrl, 'https://i%.ibb%.co/') and 
       not string.match(imageUrl, 'https://i%.imgur%.com/') then
        return false, 'invalid_url'
    end
    
    -- Check if exists
    local existing = MySQL.scalar.await(
        'SELECT id FROM restaurant_menu_images WHERE restaurant = ?',
        { restaurant }
    )
    
    if existing then
        -- Update
        MySQL.update.await(
            'UPDATE restaurant_menu_images SET image_url = ?, title = ?, updated_at = NOW() WHERE restaurant = ?',
            { imageUrl, title or 'Menu', restaurant }
        )
    else
        -- Insert
        MySQL.insert.await(
            'INSERT INTO restaurant_menu_images (restaurant, image_url, title) VALUES (?, ?, ?)',
            { restaurant, imageUrl, title or 'Menu' }
        )
    end
    
    return true
end)

--=====================================================
-- OFFLINE SHOP MANAGEMENT
--=====================================================

-- Get Shop Inventory
lib.callback.register('fx-restaurant:bossmenu:getShopInventory', function(src, restaurant)
    if not HasPermission(src, restaurant, 'manage_shop') then
        return false, 'no_permission'
    end
    
    local inventory = MySQL.query.await(
        'SELECT * FROM restaurant_shop_inventory WHERE restaurant = ?',
        { restaurant }
    )
    
    return inventory or {}
end)

-- Add Item to Shop
lib.callback.register('fx-restaurant:bossmenu:addShopItem', function(src, restaurant, item, price, stock)
    if not HasPermission(src, restaurant, 'manage_shop') then
        return false, 'no_permission'
    end
    
    -- Check if item is a finished product
    if not IsSellableItem(item) then
        return false, 'not_sellable'
    end
    
    -- Get restaurant config for limits
    local config = GetRestaurantConfig(restaurant)
    if stock > config.limits.maxOfflineStock then
        return false, 'stock_too_high'
    end
    
    -- Get item data
    local itemData = GetItemData(item)
    if not itemData then
        return false, 'invalid_item'
    end
    
    -- Check if already exists
    local existing = MySQL.scalar.await(
        'SELECT id FROM restaurant_shop_inventory WHERE restaurant = ? AND item = ?',
        { restaurant, item }
    )
    
    if existing then
        return false, 'already_exists'
    end
    
    -- Insert
    MySQL.insert.await(
        'INSERT INTO restaurant_shop_inventory (restaurant, item, label, stock, price, active) VALUES (?, ?, ?, ?, ?, ?)',
        { restaurant, item, itemData.label or item, stock, price, 1 }
    )
    
    return true
end)

-- Update Shop Item
lib.callback.register('fx-restaurant:bossmenu:updateShopItem', function(src, restaurant, itemId, price, stock)
    if not HasPermission(src, restaurant, 'manage_shop') then
        return false, 'no_permission'
    end
    
    -- Get restaurant config for limits
    local config = GetRestaurantConfig(restaurant)
    if stock > config.limits.maxOfflineStock then
        return false, 'stock_too_high'
    end
    
    MySQL.update.await(
        'UPDATE restaurant_shop_inventory SET price = ?, stock = ? WHERE id = ? AND restaurant = ?',
        { price, stock, itemId, restaurant }
    )
    
    return true
end)

-- Remove Item from Shop
lib.callback.register('fx-restaurant:bossmenu:removeShopItem', function(src, restaurant, itemId)
    if not HasPermission(src, restaurant, 'manage_shop') then
        return false, 'no_permission'
    end
    
    MySQL.update.await(
        'DELETE FROM restaurant_shop_inventory WHERE id = ? AND restaurant = ?',
        { itemId, restaurant }
    )
    
    return true
end)

-- Toggle Shop Item Active
lib.callback.register('fx-restaurant:bossmenu:toggleShopItem', function(src, restaurant, itemId, active)
    if not HasPermission(src, restaurant, 'manage_shop') then
        return false, 'no_permission'
    end
    
    MySQL.update.await(
        'UPDATE restaurant_shop_inventory SET active = ? WHERE id = ? AND restaurant = ?',
        { active and 1 or 0, itemId, restaurant }
    )
    
    return true
end)