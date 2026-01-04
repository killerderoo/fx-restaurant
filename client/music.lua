--=====================================================
-- FX-RESTAURANT | MUSIC PLAYER (CLIENT)
--=====================================================
-- YouTube music integration voor restaurants
--=====================================================

local musicOpen = false
local currentRestaurant = nil
local activeMusic = {}

--=====================================================
-- OPEN MUSIC PLAYER
--=====================================================

---Open music player UI
---@param restaurant string
function OpenMusicPlayer(restaurant)
    lib.callback('fx-restaurant:music:canUse', false, function(canUse)
        if not canUse then
            lib.notify({
                title = 'Muziekspeler',
                description = 'Je hebt geen toegang tot de muziekspeler',
                type = 'error'
            })
            return
        end
        
        -- Get current playing
        lib.callback('fx-restaurant:music:getCurrent', false, function(current)
            currentRestaurant = restaurant
            musicOpen = true
            
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openMusicPlayer',
                restaurant = restaurant,
                current = current
            })
        end, restaurant)
    end, restaurant)
end

exports('OpenMusicPlayer', OpenMusicPlayer)

--=====================================================
-- NUI CALLBACKS
--=====================================================

-- Close music player
RegisterNUICallback('closeMusicPlayer', function(data, cb)
    SetNuiFocus(false, false)
    musicOpen = false
    currentRestaurant = nil
    cb('ok')
end)

-- Play music
RegisterNUICallback('playMusic', function(data, cb)
    lib.callback('fx-restaurant:music:play', false, function(success, result)
        if success then
            lib.notify({
                title = 'Muziek',
                description = 'Muziek wordt afgespeeld',
                type = 'success'
            })
            cb({ success = true, data = result })
        else
            lib.notify({
                title = 'Fout',
                description = GetErrorMessage(result),
                type = 'error'
            })
            cb({ success = false, error = result })
        end
    end, currentRestaurant, data.url, data.volume)
end)

-- Stop music
RegisterNUICallback('stopMusic', function(data, cb)
    lib.callback('fx-restaurant:music:stop', false, function(success)
        if success then
            lib.notify({
                title = 'Muziek',
                description = 'Muziek gestopt',
                type = 'info'
            })
        end
        cb({ success = success })
    end, currentRestaurant)
end)

-- Update volume
RegisterNUICallback('updateVolume', function(data, cb)
    lib.callback('fx-restaurant:music:updateVolume', false, function(success)
        cb({ success = success })
    end, currentRestaurant, data.volume)
end)

--=====================================================
-- SYNC MUSIC (From server)
--=====================================================

RegisterNetEvent('fx-restaurant:music:sync', function(restaurant, musicData)
    if not musicData then
        -- Stop music
        SendNUIMessage({
            action = 'stopMusic',
            restaurant = restaurant
        })
        activeMusic[restaurant] = nil
        return
    end
    
    -- Start/Update music
    SendNUIMessage({
        action = 'syncMusic',
        restaurant = restaurant,
        url = musicData.url,
        volume = musicData.volume,
        position = musicData.position
    })
    
    activeMusic[restaurant] = musicData
end)

--=====================================================
-- DISTANCE CHECK (3D Audio)
--=====================================================

CreateThread(function()
    while true do
        Wait(1000)
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for restaurant, music in pairs(activeMusic) do
            if music.coords then
                local distance = #(playerCoords - vector3(music.coords.x, music.coords.y, music.coords.z))
                local maxDistance = music.radius or 30.0
                
                if distance <= maxDistance then
                    -- Calculate volume based on distance
                    local distanceVolume = math.floor((1 - (distance / maxDistance)) * music.volume)
                    
                    SendNUIMessage({
                        action = 'updateDistance',
                        restaurant = restaurant,
                        volume = distanceVolume
                    })
                else
                    -- Out of range, mute
                    SendNUIMessage({
                        action = 'updateDistance',
                        restaurant = restaurant,
                        volume = 0
                    })
                end
            end
        end
    end
end)

--=====================================================
-- ERROR MESSAGES
--=====================================================

function GetErrorMessage(error)
    local messages = {
        no_permission = 'Geen toestemming',
        invalid_url = 'Ongeldige YouTube URL',
        cooldown = 'Wacht even voordat je weer muziek afspeelt',
        already_playing = 'Er wordt al muziek afgespeeld',
        volume_too_high = 'Volume te hoog'
    }
    
    return messages[error] or 'Er is een fout opgetreden'
end