--=====================================================
-- FX-RESTAURANT | PROPS SYSTEM (SERVER)
--=====================================================

local Bridge = exports['fx-restaurant']:GetBridge()

--=====================================================
-- GET ALL PROPS
--=====================================================

lib.callback.register('fx-restaurant:props:getAll', function(src, restaurant)
    local props = MySQL.query.await(
        'SELECT * FROM restaurant_props WHERE restaurant = ?',
        { restaurant }
    )
    
    return props or {}
end)

--=====================================================
-- PLACE PROP
--=====================================================

lib.callback.register('fx-restaurant:props:place', function(src, restaurant, model, coords, heading)
    -- Check permission
    if not exports['fx-restaurant']:HasJobGrade(src, restaurant, 'boss_menu') then
        return false
    end
    
    local Framework = Bridge.Framework
    local identifier = Framework.GetIdentifier(src)
    
    -- Insert prop
    local propId = MySQL.insert.await([[
        INSERT INTO restaurant_props
        (restaurant, model, coords, heading, spawned_by)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        restaurant,
        model,
        json.encode({ x = coords.x, y = coords.y, z = coords.z }),
        heading,
        identifier
    })
    
    if not propId then
        return false
    end
    
    return true, propId
end)

--=====================================================
-- DELETE PROP
--=====================================================

lib.callback.register('fx-restaurant:props:delete', function(src, propId)
    -- Get prop restaurant
    local prop = MySQL.single.await(
        'SELECT restaurant FROM restaurant_props WHERE id = ?',
        { propId }
    )
    
    if not prop then
        return false
    end
    
    -- Check permission
    if not exports['fx-restaurant']:HasJobGrade(src, prop.restaurant, 'boss_menu') then
        return false
    end
    
    -- Delete prop
    MySQL.update.await(
        'DELETE FROM restaurant_props WHERE id = ?',
        { propId }
    )
    
    return true
end)

--=====================================================
-- CLEAR ALL PROPS (ADMIN)
--=====================================================

lib.callback.register('fx-restaurant:props:clearAll', function(src, restaurant)
    -- Check permission
    if not exports['fx-restaurant']:HasJobGrade(src, restaurant, 'boss_menu') then
        return false
    end
    
    -- Delete all props
    MySQL.update.await(
        'DELETE FROM restaurant_props WHERE restaurant = ?',
        { restaurant }
    )
    
    -- Trigger client refresh
    TriggerClientEvent('fx-restaurant:props:refresh', -1, restaurant)
    
    return true
end)