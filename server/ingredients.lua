--=====================================================
-- FX-RESTAURANT | INGREDIENT SHOP (SERVER)
--=====================================================
-- Purchase ingredients from NPC shop
-- With bulk discounts
--=====================================================

local Bridge = exports['fx-restaurant']:GetBridge()

--=====================================================
-- GET SHOP ITEMS
--=====================================================

lib.callback.register('fx-restaurant:ingredients:getShop', function(src)
    -- Return all categories and items from config
    return Config.IngredientShop.categories
end)

--=====================================================
-- PURCHASE ITEMS
--=====================================================

lib.callback.register('fx-restaurant:ingredients:purchase', function(src, items, totalAmount)
    if not items or #items == 0 then
        return false, 'no_items'
    end
    
    local Framework = Bridge.Framework
    local Inventory = Bridge.Inventory
    
    if not Framework or not Inventory then
        return false, 'bridge_error'
    end
    
    -- Calculate total price
    local totalPrice = 0
    local totalItems = 0
    
    for _, purchase in ipairs(items) do
        if not ItemExists(purchase.item) then
            return false, 'invalid_item'
        end
        
        if not IsItemType(purchase.item, 'ingredient') then
            return false, 'not_ingredient'
        end
        
        totalPrice = totalPrice + (purchase.price * purchase.amount)
        totalItems = totalItems + purchase.amount
    end
    
    -- Apply bulk discount
    if Config.IngredientDiscounts.enabled then
        local discount = 0
        
        for _, tier in ipairs(Config.IngredientDiscounts.tiers) do
            if totalItems >= tier.min then
                if not tier.max or totalItems <= tier.max then
                    discount = tier.discount
                end
            end
        end
        
        if discount > 0 then
            local discountAmount = math.floor(totalPrice * (discount / 100))
            totalPrice = totalPrice - discountAmount
            
            TriggerClientEvent('fx-restaurant:notify', src, {
                title = 'Korting Toegepast',
                description = string.format('%d%% korting! (-%s)', discount, discountAmount),
                type = 'success'
            })
        end
    end
    
    -- Check money
    local money = Framework.GetMoney(src, 'cash')
    if money < totalPrice then
        -- Try bank
        money = Framework.GetMoney(src, 'bank')
        if money < totalPrice then
            return false, 'insufficient_funds'
        end
        
        -- Pay from bank
        if not Framework.RemoveMoney(src, 'bank', totalPrice) then
            return false, 'payment_failed'
        end
    else
        -- Pay from cash
        if not Framework.RemoveMoney(src, 'cash', totalPrice) then
            return false, 'payment_failed'
        end
    end
    
    -- Give items
    for _, purchase in ipairs(items) do
        if not Inventory.CanCarryItem(src, purchase.item, purchase.amount) then
            -- Refund
            Framework.AddMoney(src, 'cash', totalPrice)
            return false, 'inventory_full'
        end
        
        Inventory.AddItem(src, purchase.item, purchase.amount)
    end
    
    return true, totalPrice
end)

--=====================================================
-- PREPARATION STATIONS
--=====================================================

lib.callback.register('fx-restaurant:preparation:process', function(src, stationType, inputItem)
    if not stationType or not inputItem then
        return false, 'invalid_data'
    end
    
    local Inventory = Bridge.Inventory
    if not Inventory then
        return false, 'inventory_error'
    end
    
    -- Get station config
    local station = Config.PreparationStations[stationType]
    if not station then
        return false, 'invalid_station'
    end
    
    -- Find recipe
    local recipe = nil
    for _, r in ipairs(station.recipes) do
        if r.input == inputItem then
            recipe = r
            break
        end
    end
    
    if not recipe then
        return false, 'no_recipe'
    end
    
    -- Check if player has input item
    if not Inventory.HasItem(src, recipe.input, 1) then
        return false, 'missing_ingredient'
    end
    
    -- Check if can carry output
    if not Inventory.CanCarryItem(src, recipe.output, recipe.amount) then
        return false, 'inventory_full'
    end
    
    -- Remove input
    if not Inventory.RemoveItem(src, recipe.input, 1) then
        return false, 'remove_failed'
    end
    
    -- Add output
    Wait(station.duration) -- Processing time
    
    if not Inventory.AddItem(src, recipe.output, recipe.amount) then
        -- Refund input if output fails
        Inventory.AddItem(src, recipe.input, 1)
        return false, 'add_failed'
    end
    
    return true, {
        output = recipe.output,
        amount = recipe.amount,
        duration = station.duration
    }
end)

--=====================================================
-- COOKING STATIONS
--=====================================================

lib.callback.register('fx-restaurant:cooking:getRecipes', function(src, restaurant, station)
    if not restaurant or not station then
        return {}
    end
    
    -- Get all recipes for this restaurant and station
    local recipes = exports['fx-restaurant']:GetRecipes(restaurant)
    local stationRecipes = {}
    
    for id, recipe in pairs(recipes) do
        if recipe.station == station and recipe.active then
            stationRecipes[id] = recipe
        end
    end
    
    return stationRecipes
end)

lib.callback.register('fx-restaurant:cooking:cook', function(src, restaurant, recipeId)
    if not restaurant or not recipeId then
        return false, 'invalid_data'
    end
    
    local Inventory = Bridge.Inventory
    if not Inventory then
        return false, 'inventory_error'
    end
    
    -- Validate recipe
    local recipe = exports['fx-restaurant']:ValidateRecipeUse(restaurant, recipeId)
    if not recipe then
        return false, 'invalid_recipe'
    end
    
    -- Check ingredients
    for _, ingredient in ipairs(recipe.ingredients) do
        if not Inventory.HasItem(src, ingredient.item, ingredient.amount) then
            return false, 'missing_ingredients'
        end
    end
    
    -- Check if can carry output
    local outputItem = recipe.name:lower():gsub(' ', '_')
    if not ItemExists(outputItem) then
        outputItem = 'burger' -- Fallback
    end
    
    if not Inventory.CanCarryItem(src, outputItem, 1) then
        return false, 'inventory_full'
    end
    
    -- Remove ingredients
    for _, ingredient in ipairs(recipe.ingredients) do
        if not Inventory.RemoveItem(src, ingredient.item, ingredient.amount) then
            -- Refund removed items
            return false, 'remove_failed'
        end
    end
    
    -- Get cooking duration from station config
    local duration = 10000 -- Default 10 seconds
    local stationConfig = Config.CookingStations[recipe.station]
    if stationConfig then
        duration = stationConfig.duration
    end
    
    Wait(duration)
    
    -- Give output
    if not Inventory.AddItem(src, outputItem, 1) then
        -- TODO: Refund ingredients
        return false, 'add_failed'
    end
    
    -- Update statistics
    MySQL.insert.await([[
        INSERT INTO restaurant_stats (restaurant, stat_date, total_orders)
        VALUES (?, CURDATE(), 1)
        ON DUPLICATE KEY UPDATE total_orders = total_orders + 1
    ]], { restaurant })
    
    return true, {
        output = outputItem,
        duration = duration
    }
end)