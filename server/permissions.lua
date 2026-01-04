--=====================================================
-- FX-RESTAURANT | PERMISSIONS SYSTEM (SERVER)
--=====================================================
-- Centralized permission checking
--=====================================================

local Bridge = exports['fx-restaurant']:GetBridge()

--=====================================================
-- HELPER: Load Restaurant Config
--=====================================================

local configCache = {}

---Load restaurant config (with caching)
---@param restaurantId string
---@return table|nil
local function GetRestaurantConfig(restaurantId)
    if configCache[restaurantId] then
        return configCache[restaurantId]
    end
    
    local path = ('shared/restaurants/%s/config.lua'):format(restaurantId)
    local configData = LoadResourceFile(GetCurrentResourceName(), path)
    
    if not configData then
        return nil
    end
    
    local env = { Restaurant = nil }
    local chunk = load(configData, path, 't', env)
    
    if not chunk then
        return nil
    end
    
    pcall(chunk)
    configCache[restaurantId] = env.Restaurant
    return env.Restaurant
end

--=====================================================
-- PERMISSION CHECKS
--=====================================================

---Check if player has job
---@param src number Player source
---@param restaurant string Restaurant ID
---@return boolean
function HasJob(src, restaurant)
    local Framework = Bridge.Framework
    if not Framework then return false end
    
    return Framework.HasJob(src, restaurant)
end

---Check if player has minimum job grade
---@param src number Player source
---@param restaurant string Restaurant ID
---@param permission string Permission name
---@return boolean
function HasJobGrade(src, restaurant, permission)
    local Framework = Bridge.Framework
    if not Framework then return false end
    
    if not Framework.HasJob(src, restaurant) then
        return false
    end
    
    local config = GetRestaurantConfig(restaurant)
    if not config or not config.permissions then
        return false
    end
    
    local requiredGrade = config.permissions[permission]
    if not requiredGrade then return false end
    
    return Framework.HasJobGrade(src, restaurant, requiredGrade)
end

--=====================================================
-- CALLBACKS
--=====================================================

-- Check if player has job
lib.callback.register('fx-restaurant:hasJob', function(src, restaurant)
    return HasJob(src, restaurant)
end)

-- Check if player has job grade
lib.callback.register('fx-restaurant:hasJobGrade', function(src, restaurant, permission)
    return HasJobGrade(src, restaurant, permission)
end)

-- Get player's restaurant
lib.callback.register('fx-restaurant:getPlayerRestaurant', function(src)
    local Framework = Bridge.Framework
    if not Framework then return nil end
    
    local Player = Framework.GetPlayer(src)
    if not Player then return nil end
    
    -- Check against all known restaurants
    local restaurants = { 'default', 'burgershot' } -- TODO: Make dynamic
    
    for _, restaurant in ipairs(restaurants) do
        if Framework.HasJob(src, restaurant) then
            return restaurant
        end
    end
    
    return nil
end)

-- Get player's grade
lib.callback.register('fx-restaurant:getPlayerGrade', function(src, restaurant)
    local Framework = Bridge.Framework
    if not Framework then return 0 end
    
    if not Framework.HasJob(src, restaurant) then
        return 0
    end
    
    local Player = Framework.GetPlayer(src)
    if not Player then return 0 end
    
    if Config.Framework == 'esx' then
        return Player.job.grade
    elseif Config.Framework == 'qb' then
        return Player.PlayerData.job.grade.level
    end
    
    return 0
end)

--=====================================================
-- EXPORTS
--=====================================================

exports('HasJob', HasJob)
exports('HasJobGrade', HasJobGrade)