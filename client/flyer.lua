--=====================================================
-- FX-RESTAURANT | FLYER SYSTEM (SERVER)
--=====================================================

local Bridge = exports['fx-restaurant']:GetBridge()

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
-- FX-RESTAURANT | MAIN SERVER
--=====================================================
