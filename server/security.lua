--=====================================================
-- FX-RESTAURANT | SECURITY MODULE
--=====================================================
-- Anti-exploit, rate limiting, validation
--=====================================================

local RateLimits = {}
local SuspiciousActivity = {}
local Blacklist = {}

--=====================================================
-- CONFIG
--=====================================================

local SecurityConfig = {
    -- Rate limiting (requests per minute)
    rateLimits = {
        recipe_create = { max = 5, window = 60 },
        recipe_update = { max = 10, window = 60 },
        order_create = { max = 20, window = 60 },
        delivery_start = { max = 3, window = 300 },
        music_play = { max = 5, window = 300 },
        prop_place = { max = 20, window = 60 }
    },
    
    -- Maximum values
    maxValues = {
        recipe_price = 10000,
        recipe_ingredients = 15,
        order_items = 20,
        shop_stock = 500,
        music_volume = 100
    },
    
    -- Auto-ban thresholds
    suspicionThreshold = 10,    -- Points before auto-ban
    autoUnbanTime = 3600        -- 1 hour
}

--=====================================================
-- RATE LIMITING
--=====================================================

---Check rate limit for action
---@param src number Player source
---@param action string Action name
---@return boolean allowed
---@return number|nil timeLeft
function CheckRateLimit(src, action)
    local config = SecurityConfig.rateLimits[action]
    if not config then return true end
    
    local identifier = GetPlayerIdentifier(src, 0)
    if not identifier then return false end
    
    local key = identifier .. ':' .. action
    local now = os.time()
    
    -- Initialize if not exists
    if not RateLimits[key] then
        RateLimits[key] = {
            count = 0,
            resetTime = now + config.window
        }
    end
    
    local limit = RateLimits[key]
    
    -- Reset if window expired
    if now >= limit.resetTime then
        limit.count = 0
        limit.resetTime = now + config.window
    end
    
    -- Check limit
    if limit.count >= config.max then
        local timeLeft = limit.resetTime - now
        LogSuspiciousActivity(src, 'rate_limit_exceeded', action)
        return false, timeLeft
    end
    
    -- Increment counter
    limit.count = limit.count + 1
    return true
end

exports('CheckRateLimit', CheckRateLimit)

--=====================================================
-- VALIDATION
--=====================================================

---Validate recipe data
---@param data table
---@return boolean valid
---@return string|nil error
function ValidateRecipeData(data)
    -- Check required fields
    if not data.name or data.name == '' then
        return false, 'name_required'
    end
    
    if not data.price or type(data.price) ~= 'number' then
        return false, 'invalid_price'
    end
    
    if data.price <= 0 or data.price > SecurityConfig.maxValues.recipe_price then
        return false, 'price_out_of_range'
    end
    
    if not data.ingredients or type(data.ingredients) ~= 'table' then
        return false, 'invalid_ingredients'
    end
    
    if #data.ingredients > SecurityConfig.maxValues.recipe_ingredients then
        return false, 'too_many_ingredients'
    end
    
    -- Validate ingredients
    for _, ingredient in ipairs(data.ingredients) do
        if not ingredient.item or not ingredient.amount then
            return false, 'invalid_ingredient_data'
        end
        
        if type(ingredient.amount) ~= 'number' or ingredient.amount <= 0 then
            return false, 'invalid_ingredient_amount'
        end
        
        -- Check if item exists
        if not ItemExists(ingredient.item) then
            return false, 'unknown_item'
        end
    end
    
    -- Check name length
    if #data.name > 100 then
        return false, 'name_too_long'
    end
    
    -- Check description length
    if data.description and #data.description > 500 then
        return false, 'description_too_long'
    end
    
    return true
end

exports('ValidateRecipeData', ValidateRecipeData)

---Validate order data
---@param data table
---@return boolean valid
---@return string|nil error
function ValidateOrderData(data)
    if not data.items or type(data.items) ~= 'table' or #data.items == 0 then
        return false, 'invalid_items'
    end
    
    if #data.items > SecurityConfig.maxValues.order_items then
        return false, 'too_many_items'
    end
    
    local totalPrice = 0
    
    for _, item in ipairs(data.items) do
        if not item.item or not item.amount or not item.price then
            return false, 'invalid_item_data'
        end
        
        if type(item.amount) ~= 'number' or item.amount <= 0 or item.amount > 100 then
            return false, 'invalid_item_amount'
        end
        
        if type(item.price) ~= 'number' or item.price < 0 or item.price > SecurityConfig.maxValues.recipe_price then
            return false, 'invalid_item_price'
        end
        
        totalPrice = totalPrice + (item.price * item.amount)
    end
    
    -- Check total price sanity
    if totalPrice > 1000000 then -- 1 million max
        return false, 'total_price_too_high'
    end
    
    return true
end

exports('ValidateOrderData', ValidateOrderData)

---Validate shop item data
---@param data table
---@return boolean valid
---@return string|nil error
function ValidateShopItemData(data)
    if not data.item or not data.price or not data.stock then
        return false, 'missing_data'
    end
    
    if not ItemExists(data.item) then
        return false, 'invalid_item'
    end
    
    if not IsSellableItem(data.item) then
        return false, 'not_sellable'
    end
    
    if type(data.price) ~= 'number' or data.price <= 0 or data.price > SecurityConfig.maxValues.recipe_price then
        return false, 'invalid_price'
    end
    
    if type(data.stock) ~= 'number' or data.stock < 0 or data.stock > SecurityConfig.maxValues.shop_stock then
        return false, 'invalid_stock'
    end
    
    return true
end

exports('ValidateShopItemData', ValidateShopItemData)

--=====================================================
-- URL VALIDATION
--=====================================================

---Validate image URL
---@param url string
---@return boolean valid
function ValidateImageURL(url)
    if not url or type(url) ~= 'string' then
        return false
    end
    
    -- Must be https
    if not string.match(url, '^https://') then
        return false
    end
    
    -- Check allowed domains
    local allowedDomains = {
        'i%.ibb%.co',
        'i%.imgur%.com',
        'imgur%.com'
    }
    
    for _, domain in ipairs(allowedDomains) do
        if string.match(url, domain) then
            return true
        end
    end
    
    return false
end

exports('ValidateImageURL', ValidateImageURL)

---Validate YouTube URL
---@param url string
---@return boolean valid
function ValidateYouTubeURL(url)
    if not url or type(url) ~= 'string' then
        return false
    end
    
    -- Check YouTube patterns
    local patterns = {
        'youtube%.com/watch%?v=',
        'youtu%.be/',
        'youtube%.com/embed/'
    }
    
    for _, pattern in ipairs(patterns) do
        if string.match(url, pattern) then
            return true
        end
    end
    
    return false
end

exports('ValidateYouTubeURL', ValidateYouTubeURL)

--=====================================================
-- SUSPICIOUS ACTIVITY LOGGING
--=====================================================

---Log suspicious activity
---@param src number
---@param activityType string
---@param details string|nil
function LogSuspiciousActivity(src, activityType, details)
    local identifier = GetPlayerIdentifier(src, 0)
    if not identifier then return end
    
    if not SuspiciousActivity[identifier] then
        SuspiciousActivity[identifier] = {
            points = 0,
            incidents = {}
        }
    end
    
    local activity = SuspiciousActivity[identifier]
    
    -- Add incident
    table.insert(activity.incidents, {
        type = activityType,
        details = details,
        timestamp = os.time()
    })
    
    -- Add points based on severity
    local points = {
        rate_limit_exceeded = 1,
        invalid_data = 2,
        exploit_attempt = 5,
        sql_injection = 10,
        unauthorized_access = 3
    }
    
    activity.points = activity.points + (points[activityType] or 1)
    
    -- Log to console
    print(('^3[SECURITY] Suspicious activity from %s (%s): %s - %s^0'):format(
        GetPlayerName(src), identifier, activityType, details or 'N/A'
    ))
    
    -- Check threshold
    if activity.points >= SecurityConfig.suspicionThreshold then
        BanPlayer(src, 'Suspicious activity detected', SecurityConfig.autoUnbanTime)
    end
end

exports('LogSuspiciousActivity', LogSuspiciousActivity)

--=====================================================
-- BLACKLIST SYSTEM
--=====================================================

---Check if player is blacklisted
---@param src number
---@return boolean blacklisted
function IsBlacklisted(src)
    local identifier = GetPlayerIdentifier(src, 0)
    if not identifier then return false end
    
    local ban = Blacklist[identifier]
    if not ban then return false end
    
    -- Check if ban expired
    if ban.expiresAt and os.time() >= ban.expiresAt then
        Blacklist[identifier] = nil
        return false
    end
    
    return true
end

exports('IsBlacklisted', IsBlacklisted)

---Ban player
---@param src number
---@param reason string
---@param duration number|nil Seconds (nil = permanent)
function BanPlayer(src, reason, duration)
    local identifier = GetPlayerIdentifier(src, 0)
    if not identifier then return end
    
    local expiresAt = duration and (os.time() + duration) or nil
    
    Blacklist[identifier] = {
        reason = reason,
        bannedAt = os.time(),
        expiresAt = expiresAt,
        playerName = GetPlayerName(src)
    }
    
    print(('^1[SECURITY] Banned %s (%s): %s^0'):format(
        GetPlayerName(src), identifier, reason
    ))
    
    -- Kick player
    DropPlayer(src, string.format(
        'You have been banned from this restaurant.\nReason: %s\nExpires: %s',
        reason,
        expiresAt and os.date('%Y-%m-%d %H:%M:%S', expiresAt) or 'Never'
    ))
end

exports('BanPlayer', BanPlayer)

---Unban player
---@param identifier string
function UnbanPlayer(identifier)
    if Blacklist[identifier] then
        Blacklist[identifier] = nil
        print(('^2[SECURITY] Unbanned %s^0'):format(identifier))
    end
end

exports('UnbanPlayer', UnbanPlayer)

--=====================================================
-- SQL INJECTION PREVENTION
--=====================================================

---Check for SQL injection attempts
---@param input string
---@return boolean safe
function CheckSQLInjection(input)
    if type(input) ~= 'string' then return true end
    
    local patterns = {
        '%-%-',         -- SQL comments
        '/%*',          -- Multi-line comments
        'union',        -- UNION attacks
        'select.*from', -- SELECT FROM
        'insert.*into', -- INSERT INTO
        'delete.*from', -- DELETE FROM
        'drop.*table',  -- DROP TABLE
        'exec%(',       -- EXEC
        'execute%(',    -- EXECUTE
        'script',       -- XSS
        '<script'       -- XSS
    }
    
    local lowerInput = input:lower()
    
    for _, pattern in ipairs(patterns) do
        if string.match(lowerInput, pattern) then
            return false
        end
    end
    
    return true
end

exports('CheckSQLInjection', CheckSQLInjection)

--=====================================================
-- INPUT SANITIZATION
--=====================================================

---Sanitize string input
---@param input string
---@return string sanitized
function SanitizeInput(input)
    if type(input) ~= 'string' then return '' end
    
    -- Remove dangerous characters
    input = input:gsub('[<>"\']', '')
    
    -- Trim whitespace
    input = input:match('^%s*(.-)%s*$')
    
    return input
end

exports('SanitizeInput', SanitizeInput)

--=====================================================
-- ANTI-DUPLICATION
--=====================================================

local RecentActions = {}

---Check for duplicate actions
---@param src number
---@param action string
---@param data any
---@return boolean isDuplicate
function CheckDuplicateAction(src, action, data)
    local identifier = GetPlayerIdentifier(src, 0)
    if not identifier then return false end
    
    local key = identifier .. ':' .. action
    local dataHash = json.encode(data)
    
    if not RecentActions[key] then
        RecentActions[key] = {}
    end
    
    local recent = RecentActions[key]
    local now = os.time()
    
    -- Check last 5 seconds
    for i = #recent, 1, -1 do
        if now - recent[i].timestamp > 5 then
            table.remove(recent, i)
        elseif recent[i].hash == dataHash then
            -- Duplicate detected
            LogSuspiciousActivity(src, 'duplicate_action', action)
            return true
        end
    end
    
    -- Add new action
    table.insert(recent, {
        hash = dataHash,
        timestamp = now
    })
    
    return false
end

exports('CheckDuplicateAction', CheckDuplicateAction)

--=====================================================
-- CLEANUP
--=====================================================

CreateThread(function()
    while true do
        Wait(300000) -- Every 5 minutes
        
        local now = os.time()
        
        -- Cleanup rate limits
        for key, limit in pairs(RateLimits) do
            if now >= limit.resetTime then
                RateLimits[key] = nil
            end
        end
        
        -- Cleanup suspicious activity (older than 1 hour)
        for identifier, activity in pairs(SuspiciousActivity) do
            local oldIncidents = {}
            for _, incident in ipairs(activity.incidents) do
                if now - incident.timestamp < 3600 then
                    table.insert(oldIncidents, incident)
                end
            end
            
            if #oldIncidents == 0 then
                SuspiciousActivity[identifier] = nil
            else
                activity.incidents = oldIncidents
                -- Decay points
                activity.points = math.max(0, activity.points - 1)
            end
        end
        
        -- Cleanup recent actions
        for key, actions in pairs(RecentActions) do
            for i = #actions, 1, -1 do
                if now - actions[i].timestamp > 60 then
                    table.remove(actions, i)
                end
            end
            
            if #actions == 0 then
                RecentActions[key] = nil
            end
        end
    end
end)

--=====================================================
-- PLAYER CONNECT CHECK
--=====================================================

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    if not identifier then
        setKickReason('Could not verify identity')
        CancelEvent()
        return
    end
    
    -- Check blacklist
    if IsBlacklisted(src) then
        local ban = Blacklist[identifier]
        setKickReason(string.format(
            'You are banned from this restaurant.\nReason: %s\nExpires: %s',
            ban.reason,
            ban.expiresAt and os.date('%Y-%m-%d %H:%M:%S', ban.expiresAt) or 'Never'
        ))
        CancelEvent()
    end
end)

--=====================================================
-- ADMIN COMMANDS
--=====================================================

RegisterCommand('unbanrestaurant', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'command.unbanrestaurant') then
        return
    end
    
    local identifier = args[1]
    if not identifier then
        print('^3Usage: /unbanrestaurant [identifier]^0')
        return
    end
    
    UnbanPlayer(identifier)
end, true)

RegisterCommand('viewsuspicious', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'command.viewsuspicious') then
        return
    end
    
    print('^3=== Suspicious Activity Report ===^0')
    
    for identifier, activity in pairs(SuspiciousActivity) do
        print(string.format('^3%s: %d points, %d incidents^0', identifier, activity.points, #activity.incidents))
        
        for _, incident in ipairs(activity.incidents) do
            print(string.format('  - %s: %s (%s)', incident.type, incident.details or 'N/A', os.date('%Y-%m-%d %H:%M:%S', incident.timestamp)))
        end
    end
end, true)

--=====================================================
-- EXPORTS
--=====================================================

exports('CheckRateLimit', CheckRateLimit)
exports('ValidateRecipeData', ValidateRecipeData)
exports('ValidateOrderData', ValidateOrderData)
exports('ValidateShopItemData', ValidateShopItemData)
exports('ValidateImageURL', ValidateImageURL)
exports('ValidateYouTubeURL', ValidateYouTubeURL)
exports('LogSuspiciousActivity', LogSuspiciousActivity)
exports('IsBlacklisted', IsBlacklisted)
exports('BanPlayer', BanPlayer)
exports('UnbanPlayer', UnbanPlayer)
exports('CheckSQLInjection', CheckSQLInjection)
exports('SanitizeInput', SanitizeInput)
exports('CheckDuplicateAction', CheckDuplicateAction)

print('^2[FX-RESTAURANT] Security module initialized^0')