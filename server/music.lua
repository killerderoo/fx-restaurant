--=====================================================
-- FX-RESTAURANT | MUSIC PLAYER (SERVER)
--=====================================================
-- YouTube music met 3D audio
--=====================================================

local ActiveMusic = {} -- Per restaurant
local Cooldowns = {} -- Per player

local COOLDOWN_TIME = 60 -- 1 minute
local MAX_VOLUME = 100
local MAX_RADIUS = 50

--=====================================================
-- CAN USE MUSIC PLAYER
--=====================================================

lib.callback.register('fx-restaurant:music:canUse', function(src, restaurant)
    return exports['fx-restaurant']:HasJobGrade(src, restaurant, 'music')
end)

--=====================================================
-- GET CURRENT MUSIC
--=====================================================

lib.callback.register('fx-restaurant:music:getCurrent', function(src, restaurant)
    return ActiveMusic[restaurant]
end)

--=====================================================
-- PLAY MUSIC
--=====================================================

lib.callback.register('fx-restaurant:music:play', function(src, restaurant, url, volume)
    -- Check permission
    if not exports['fx-restaurant']:HasJobGrade(src, restaurant, 'music') then
        return false, 'no_permission'
    end
    
    -- Check cooldown
    if Cooldowns[src] and Cooldowns[src] > os.time() then
        return false, 'cooldown'
    end
    
    -- Validate URL (must be YouTube)
    if not string.match(url, 'youtube%.com/watch%?v=') and
       not string.match(url, 'youtu%.be/') then
        return false, 'invalid_url'
    end
    
    -- Validate volume
    if volume > MAX_VOLUME then
        return false, 'volume_too_high'
    end
    
    -- Get restaurant config for music coords
    local configPath = ('shared/restaurants/%s/config.lua'):format(restaurant)
    local configData = LoadResourceFile(GetCurrentResourceName(), configPath)
    
    if not configData then
        return false, 'config_error'
    end
    
    local env = { Restaurant = nil }
    local chunk = load(configData, configPath, 't', env)
    if chunk then pcall(chunk) end
    local config = env.Restaurant
    
    if not config or not config.zones or not config.zones.music then
        return false, 'no_music_zone'
    end
    
    local coords = config.zones.music.coords
    local radius = config.zones.music.radius or 30
    
    -- Store active music
    ActiveMusic[restaurant] = {
        url = url,
        volume = volume,
        radius = radius,
        coords = coords,
        playedBy = GetPlayerName(src),
        startTime = os.time()
    }
    
    -- Sync to all players
    TriggerClientEvent('fx-restaurant:music:sync', -1, restaurant, ActiveMusic[restaurant])
    
    -- Set cooldown
    Cooldowns[src] = os.time() + COOLDOWN_TIME
    
    -- Log to database
    MySQL.insert.await([[
        INSERT INTO restaurant_music
        (restaurant, url, volume, radius, played_by, playing)
        VALUES (?, ?, ?, ?, ?, 1)
    ]], {
        restaurant,
        url,
        volume,
        radius,
        exports['fx-restaurant']:GetBridge().Framework.GetIdentifier(src)
    })
    
    return true, ActiveMusic[restaurant]
end)

--=====================================================
-- STOP MUSIC
--=====================================================

lib.callback.register('fx-restaurant:music:stop', function(src, restaurant)
    -- Check permission
    if not exports['fx-restaurant']:HasJobGrade(src, restaurant, 'music') then
        return false, 'no_permission'
    end
    
    if not ActiveMusic[restaurant] then
        return false, 'not_playing'
    end
    
    -- Remove active music
    ActiveMusic[restaurant] = nil
    
    -- Sync to all players
    TriggerClientEvent('fx-restaurant:music:sync', -1, restaurant, nil)
    
    -- Update database
    MySQL.update.await(
        'UPDATE restaurant_music SET playing = 0 WHERE restaurant = ? AND playing = 1',
        { restaurant }
    )
    
    return true
end)

--=====================================================
-- UPDATE VOLUME
--=====================================================

lib.callback.register('fx-restaurant:music:updateVolume', function(src, restaurant, volume)
    -- Check permission
    if not exports['fx-restaurant']:HasJobGrade(src, restaurant, 'music') then
        return false
    end
    
    if not ActiveMusic[restaurant] then
        return false
    end
    
    -- Validate volume
    if volume > MAX_VOLUME then
        volume = MAX_VOLUME
    end
    
    ActiveMusic[restaurant].volume = volume
    
    -- Sync to all players
    TriggerClientEvent('fx-restaurant:music:sync', -1, restaurant, ActiveMusic[restaurant])
    
    return true
end)

--=====================================================
-- CLEANUP ON DISCONNECT
--=====================================================

AddEventHandler('playerDropped', function()
    local src = source
    Cooldowns[src] = nil
end)