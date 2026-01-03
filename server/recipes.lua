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

local function GetRestaurantConfig(restaurantId)
    local path = ('shared/restaurants/%s/config.lua'):format(restaurantId)
    if not LoadResourceFile(GetCurrentResourceName(), path) then
        return nil
    end
    return _G.Restaurant
end

local function ValidateIngredients(ingredients, max)
    if type(ingredients) ~= 'table' then return false, 'invalid_ingredients' end
    if #ingredients > max then return false, 'too_many_ingredients' end

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
    end

    return true
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
    local restaurant = data.restaurant
    local config = GetRestaurantConfig(restaurant)
    if not config or not config.enabled then
        return false, 'restaurant_disabled'
    end

    -- LIMIET CHECK
    local count = Recipes[restaurant] and #Recipes[restaurant] or 0
    if count >= config.limits.maxRecipes then
        return false, 'max_recipes_reached'
    end

    -- PRIJS CHECK
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

    -- INSERT
    local id = MySQL.insert.await([[
        INSERT INTO restaurant_recipes
        (restaurant, name, description, image, animation, station, type, price, ingredients, active)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        restaurant,
        data.name,
        data.description,
        data.image,
        data.animation,
        data.station,
        data.type,
        data.price,
        json.encode(data.ingredients),
        data.active and 1 or 0
    })

    Recipes[restaurant] = Recipes[restaurant] or {}
    Recipes[restaurant][id] = {
        id = id,
        name = data.name,
        description = data.description,
        image = data.image,
        animation = data.animation,
        station = data.station,
        type = data.type,
        price = data.price,
        ingredients = data.ingredients,
        active = data.active
    }

    return true
end)

--=====================================================
-- UPDATE RECIPE
--=====================================================

lib.callback.register('fx-restaurant:recipe:update', function(src, data)
    local restaurant = data.restaurant
    local config = GetRestaurantConfig(restaurant)
    if not config then return false end

    if not Recipes[restaurant] or not Recipes[restaurant][data.id] then
        return false, 'recipe_not_found'
    end

    if data.price > config.limits.maxPrice then
        return false, 'price_too_high'
    end

    local ok, err = ValidateIngredients(data.ingredients, config.limits.maxIngredients)
    if not ok then return false, err end

    MySQL.update.await([[
        UPDATE restaurant_recipes SET
        name = ?, description = ?, image = ?, animation = ?,
        station = ?, type = ?, price = ?, ingredients = ?, active = ?
        WHERE id = ?
    ]], {
        data.name,
        data.description,
        data.image,
        data.animation,
        data.station,
        data.type,
        data.price,
        json.encode(data.ingredients),
        data.active and 1 or 0,
        data.id
    })

    Recipes[restaurant][data.id] = data
    return true
end)

--=====================================================
-- DELETE RECIPE
--=====================================================

lib.callback.register('fx-restaurant:recipe:delete', function(src, restaurant, id)
    if not Recipes[restaurant] or not Recipes[restaurant][id] then
        return false
    end

    MySQL.update.await('DELETE FROM restaurant_recipes WHERE id = ?', { id })
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
    if not recipe or not recipe.active then return false end
    return recipe
end

exports('ValidateRecipeUse', ValidateRecipeUse)
