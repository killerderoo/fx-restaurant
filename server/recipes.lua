--=====================================================
-- FX-RESTAURANT | RECIPES SYSTEM
--=====================================================
-- Verantwoordelijkheden:
-- - Recepten laden uit database
-- - CRUD via bossmenu
-- - Volledige server-side validatie
-- - Limieten per restaurant afdwingen
--=====================================================

local Recipes = {}

--=====================================================
-- INTERNAL UTILS
--=====================================================

---Laadt restaurant config VEILIG
---@param restaurantId string
---@return table|nil
local function GetRestaurantConfig(restaurantId)
    local configPath = ('shared/restaurants/%s/config.lua'):format(restaurantId)
    local configData = LoadResourceFile(GetCurrentResourceName(), configPath)
    
    if not configData then
        return nil
    end
    
    -- VEILIGE SANDBOX ENVIRONMENT
    local env = {
        Restaurant = nil
    }
    
    local chunk, err = load(configData, configPath, 't', env)
    if not chunk then
        print('^1[ERROR] Failed to load config: ' .. err .. '^0')
        return nil
    end
    
    local success, result = pcall(chunk)
    if not success then
        print('^1[ERROR] Failed to execute config: ' .. result .. '^0')
        return nil
    end
    
    return env.Restaurant
end

---Valideert ingrediënten array
---@param ingredients table
---@param max number
---@return boolean, string?
local function ValidateIngredients(ingredients, max)
    if type(ingredients) ~= 'table' then 
        return false, 'invalid_ingredients' 
    end
    
    if #ingredients > max then 
        return false, 'too_many_ingredients' 
    end

    for _, data in pairs(ingredients) do
        if not data.item or not data.amount then
            return false, 'invalid_ingredient_data'
        end

        if not ItemExists(data.item) then
            return false, 'unknown_item'
        end

        if not IsItemType(data.item, 'ingredient')
            and not IsItemType(data.item, 'prepared') then
            return false, 'invalid_item_type'
        end
        
        -- Valideer amount
        if type(data.amount) ~= 'number' or data.amount <= 0 then
            return false, 'invalid_ingredient_amount'
        end
    end

    return true
end

---Tel recepten CORRECT (niet-sequentiële keys)
---@param restaurantTable table
---@return number
local function CountRecipes(restaurantTable)
    if not restaurantTable then return 0 end
    
    local count = 0
    for _ in pairs(restaurantTable) do
        count = count + 1
    end
    return count
end

--=====================================================
-- LOAD RECIPES
--=====================================================

CreateThread(function()
    local result = MySQL.query.await('SELECT * FROM restaurant_recipes')

    for _, row in pairs(result or {}) do
        Recipes[row.restaurant] = Recipes[row.restaurant] or {}
        Recipes[row.restaurant][row.id] = {
            id = row.id,
            name = row.name,
            description = row.description,
            image = row.image,
            animation = row.animation,
            station = row.station,
            type = row.type,
            price = row.price,
            ingredients = json.decode(row.ingredients),
            active = row.active == 1
        }
    end
    
    print('^2[FX-RESTAURANT] Loaded ' .. CountRecipes(Recipes) .. ' recipes^0')
end)

--=====================================================
-- GETTERS
--=====================================================

---Geeft alle recepten van restaurant
---@param restaurant string
---@return table
function GetRecipes(restaurant)
    return Recipes[restaurant] or {}
end

exports('GetRecipes', GetRecipes)

--=====================================================
-- CREATE RECIPE
--=====================================================

lib.callback.register('fx-restaurant:recipe:create', function(src, data)
    -- SECURITY: Valideer source
    if not src or src <= 0 then
        return false, 'invalid_source'
    end
    
    local restaurant = data.restaurant
    local config = GetRestaurantConfig(restaurant)
    
    if not config or not config.enabled then
        return false, 'restaurant_disabled'
    end

    -- LIMIET CHECK (CORRECT TELLEN)
    local count = CountRecipes(Recipes[restaurant])
    if count >= config.limits.maxRecipes then
        return false, 'max_recipes_reached'
    end

    -- PRIJS CHECK
    if type(data.price) ~= 'number' or data.price <= 0 then
        return false, 'invalid_price'
    end
    
    if data.price > config.limits.maxPrice then
        return false, 'price_too_high'
    end

    -- INGREDIENTEN CHECK
    local ok, err = ValidateIngredients(data.ingredients, config.limits.maxIngredients)
    if not ok then
        return false, err
    end

    -- TYPE CHECK
    if data.type ~= 'food' and data.type ~= 'drink' then
        return false, 'invalid_type'
    end
    
    -- STATION CHECK
    if not data.station or data.station == '' then
        return false, 'invalid_station'
    end

    -- INSERT
    local id = MySQL.insert.await([[
        INSERT INTO restaurant_recipes
        (restaurant, name, description, image, animation, station, type, price, ingredients, active)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        restaurant,
        data.name,
        data.description or '',
        data.image or 'default.png',
        data.animation or 'none',
        data.station,
        data.type,
        data.price,
        json.encode(data.ingredients),
        data.active and 1 or 0
    })

    if not id then
        return false, 'database_error'
    end

    -- VOEG TOE AAN CACHE
    Recipes[restaurant] = Recipes[restaurant] or {}
    Recipes[restaurant][id] = {
        id = id,
        name = data.name,
        description = data.description or '',
        image = data.image or 'default.png',
        animation = data.animation or 'none',
        station = data.station,
        type = data.type,
        price = data.price,
        ingredients = data.ingredients,
        active = data.active or false
    }

    return true, id
end)

--=====================================================
-- UPDATE RECIPE
--=====================================================

lib.callback.register('fx-restaurant:recipe:update', function(src, data)
    -- SECURITY
    if not src or src <= 0 then
        return false, 'invalid_source'
    end
    
    local restaurant = data.restaurant
    local config = GetRestaurantConfig(restaurant)
    
    if not config then 
        return false, 'restaurant_not_found' 
    end

    if not Recipes[restaurant] or not Recipes[restaurant][data.id] then
        return false, 'recipe_not_found'
    end

    -- PRIJS CHECK
    if type(data.price) ~= 'number' or data.price <= 0 then
        return false, 'invalid_price'
    end
    
    if data.price > config.limits.maxPrice then
        return false, 'price_too_high'
    end

    -- INGREDIENTEN CHECK
    local ok, err = ValidateIngredients(data.ingredients, config.limits.maxIngredients)
    if not ok then 
        return false, err 
    end
    
    -- TYPE CHECK
    if data.type ~= 'food' and data.type ~= 'drink' then
        return false, 'invalid_type'
    end

    -- UPDATE
    local affected = MySQL.update.await([[
        UPDATE restaurant_recipes SET
        name = ?, description = ?, image = ?, animation = ?,
        station = ?, type = ?, price = ?, ingredients = ?, active = ?
        WHERE id = ? AND restaurant = ?
    ]], {
        data.name,
        data.description or '',
        data.image or 'default.png',
        data.animation or 'none',
        data.station,
        data.type,
        data.price,
        json.encode(data.ingredients),
        data.active and 1 or 0,
        data.id,
        restaurant
    })
    
    if affected == 0 then
        return false, 'update_failed'
    end

    -- UPDATE CACHE
    Recipes[restaurant][data.id] = {
        id = data.id,
        name = data.name,
        description = data.description or '',
        image = data.image or 'default.png',
        animation = data.animation or 'none',
        station = data.station,
        type = data.type,
        price = data.price,
        ingredients = data.ingredients,
        active = data.active or false
    }
    
    return true
end)

--=====================================================
-- DELETE RECIPE
--=====================================================

lib.callback.register('fx-restaurant:recipe:delete', function(src, restaurant, id)
    -- SECURITY
    if not src or src <= 0 then
        return false, 'invalid_source'
    end
    
    if not Recipes[restaurant] or not Recipes[restaurant][id] then
        return false, 'recipe_not_found'
    end

    local affected = MySQL.update.await(
        'DELETE FROM restaurant_recipes WHERE id = ? AND restaurant = ?', 
        { id, restaurant }
    )
    
    if affected == 0 then
        return false, 'delete_failed'
    end
    
    Recipes[restaurant][id] = nil

    return true
end)

--=====================================================
-- VALIDATE RECIPE USE (COOKING)
--=====================================================

---Checkt of recept gebruikt mag worden
---@param restaurant string
---@param recipeId number
---@return table|false
function ValidateRecipeUse(restaurant, recipeId)
    local recipe = Recipes[restaurant] and Recipes[restaurant][recipeId]
    if not recipe or not recipe.active then 
        return false 
    end
    return recipe
end

exports('ValidateRecipeUse', ValidateRecipeUse)