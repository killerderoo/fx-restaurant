--=====================================================
-- FX-RESTAURANT | MAIN CLIENT
--=====================================================
-- Core client functions, utilities & initialization
--=====================================================

--=====================================================
-- RESOURCE START/STOP
--=====================================================

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    print('^2[FX-RESTAURANT] Client initialized^0')
    
    -- Wait for player to spawn
    while not LocalPlayer.state.isLoggedIn do
        Wait(100)
    end
    
    -- Initialize player-specific systems
    InitializePlayerSystems()
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- Cleanup
    print('^3[FX-RESTAURANT] Client stopped^0')
end)

--=====================================================
-- PLAYER INITIALIZATION
--=====================================================

function InitializePlayerSystems()
    CreateThread(function()
        Wait(2000)
        
        -- Load restaurant zones
        -- This is handled by zones.lua
        
        -- Check for pending invoices
        CheckPendingInvoices()
        
        -- Initialize UI systems
        InitializeUI()
        
        print('^2[FX-RESTAURANT] Player systems initialized^0')
    end)
end

--=====================================================
-- UI INITIALIZATION
--=====================================================

function InitializeUI()
    -- Set NUI ready state
    SendNUIMessage({
        action = 'setReady',
        ready = true
    })
end

--=====================================================
-- PENDING INVOICES CHECK
--=====================================================

function CheckPendingInvoices()
    lib.callback('fx-restaurant:cashier:getPendingInvoices', false, function(invoices)
        if invoices and #invoices > 0 then
            lib.notify({
                title = 'Openstaande Facturen',
                description = string.format('Je hebt %d openstaande factuur(en). Gebruik /myinvoices om te bekijken', #invoices),
                type = 'info',
                icon = 'fa-solid fa-file-invoice-dollar',
                duration = 10000
            })
        end
    end)
end

--=====================================================
-- KEYBINDS
--=====================================================

-- Open boss menu keybind (optional)
RegisterKeyMapping('openbossmenu', 'Open Restaurant Boss Menu', 'keyboard', '')

RegisterCommand('openbossmenu', function()
    -- Get player's restaurant
    lib.callback('fx-restaurant:getPlayerRestaurant', false, function(restaurant)
        if not restaurant then
            lib.notify({
                title = 'Boss Menu',
                description = 'Je werkt niet voor een restaurant',
                type = 'error'
            })
            return
        end
        
        exports['fx-restaurant']:OpenBossMenu(restaurant)
    end)
end, false)

--=====================================================
-- ADMIN COMMANDS (Client side)
--=====================================================

-- Test notification
RegisterCommand('testnotify', function(source, args)
    local type = args[1] or 'info'
    local message = table.concat(args, ' ', 2) or 'Test notification'
    
    lib.notify({
        title = 'Test',
        description = message,
        type = type
    })
end, false)

-- Test recipe validation
RegisterCommand('testrecipe', function(source, args)
    local restaurant = args[1] or 'burgershot'
    local recipeId = tonumber(args[2]) or 1
    
    lib.callback('fx-restaurant:recipe:getOne', false, function(recipe)
        if recipe then
            print(json.encode(recipe, { indent = true }))
            lib.notify({
                title = 'Recipe Found',
                description = recipe.name,
                type = 'success'
            })
        else
            lib.notify({
                title = 'Recipe Not Found',
                description = 'Recipe does not exist',
                type = 'error'
            })
        end
    end, restaurant, recipeId)
end, false)

--=====================================================
-- UTILITY FUNCTIONS
--=====================================================

---Get player coords
---@return vector3
function GetPlayerCoords()
    return GetEntityCoords(PlayerPedId())
end

exports('GetPlayerCoords', GetPlayerCoords)

---Get closest player
---@param maxDistance number
---@return number|nil playerId
---@return number|nil distance
function GetClosestPlayer(maxDistance)
    local players = GetActivePlayers()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    local closestPlayer = nil
    local closestDistance = maxDistance or 5.0
    
    for _, player in ipairs(players) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(coords - targetCoords)
            
            if distance < closestDistance then
                closestPlayer = player
                closestDistance = distance
            end
        end
    end
    
    return closestPlayer, closestDistance
end

exports('GetClosestPlayer', GetClosestPlayer)

---Draw 3D text (fallback voor target system)
---@param coords vector3
---@param text string
function Draw3DText(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(x, y)
        
        local factor = (string.len(text)) / 370
        DrawRect(x, y + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    end
end

exports('Draw3DText', Draw3DText)

---Check if player is in vehicle
---@return boolean inVehicle
---@return number|nil vehicle
function IsPlayerInVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle ~= 0 then
        return true, vehicle
    end
    
    return false, nil
end

exports('IsPlayerInVehicle', IsPlayerInVehicle)

---Get player heading
---@return number heading
function GetPlayerHeading()
    return GetEntityHeading(PlayerPedId())
end

exports('GetPlayerHeading', GetPlayerHeading)

---Teleport player
---@param coords vector3|vector4
function TeleportPlayer(coords)
    local ped = PlayerPedId()
    
    if coords.w then
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, coords.w)
    else
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    end
end

exports('TeleportPlayer', TeleportPlayer)

---Play animation
---@param dict string
---@param anim string
---@param duration number
---@param flag number
function PlayAnimation(dict, anim, duration, flag)
    local ped = PlayerPedId()
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
    
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, duration or -1, flag or 0, 0, false, false, false)
end

exports('PlayAnimation', PlayAnimation)

---Stop animation
function StopAnimation()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end

exports('StopAnimation', StopAnimation)

---Request model
---@param model string|number
---@return boolean success
function RequestModelSync(model)
    local hash = type(model) == 'string' and GetHashKey(model) or model
    
    if not IsModelValid(hash) then
        return false
    end
    
    RequestModel(hash)
    
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    
    return HasModelLoaded(hash)
end

exports('RequestModelSync', RequestModelSync)

---Get forward vector
---@param distance number
---@return vector3
function GetForwardVector(distance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    
    return coords + (forward * (distance or 2.0))
end

exports('GetForwardVector', GetForwardVector)

--=====================================================
-- ITEM DATA HELPERS
--=====================================================

---Get item data from shared
---@param item string
---@return table|nil
function GetItemData(item)
    return Items[item]
end

exports('GetItemData', GetItemData)

---Check if item exists
---@param item string
---@return boolean
function ItemExists(item)
    return Items[item] ~= nil
end

exports('ItemExists', ItemExists)

--=====================================================
-- NOTIFICATION WRAPPER
--=====================================================

---Show notification
---@param data table
function ShowNotification(data)
    lib.notify(data)
end

exports('ShowNotification', ShowNotification)

---Show success notification
---@param title string
---@param description string
function NotifySuccess(title, description)
    lib.notify({
        title = title,
        description = description,
        type = 'success'
    })
end

exports('NotifySuccess', NotifySuccess)

---Show error notification
---@param title string
---@param description string
function NotifyError(title, description)
    lib.notify({
        title = title,
        description = description,
        type = 'error'
    })
end

exports('NotifyError', NotifyError)

---Show info notification
---@param title string
---@param description string
function NotifyInfo(title, description)
    lib.notify({
        title = title,
        description = description,
        type = 'info'
    })
end

exports('NotifyInfo', NotifyInfo)

--=====================================================
-- PROGRESS BAR WRAPPER
--=====================================================

---Show progress bar
---@param data table
---@return boolean success
function ShowProgressBar(data)
    return lib.progressBar(data)
end

exports('ShowProgressBar', ShowProgressBar)

--=====================================================
-- INPUT DIALOG WRAPPER
--=====================================================

---Show input dialog
---@param title string
---@param fields table
---@return table|nil
function ShowInputDialog(title, fields)
    return lib.inputDialog(title, fields)
end

exports('ShowInputDialog', ShowInputDialog)

--=====================================================
-- ALERT DIALOG WRAPPER
--=====================================================

---Show alert dialog
---@param data table
---@return string|nil
function ShowAlertDialog(data)
    return lib.alertDialog(data)
end

exports('ShowAlertDialog', ShowAlertDialog)

--=====================================================
-- CONTEXT MENU WRAPPER
--=====================================================

---Register context menu
---@param data table
function RegisterContextMenu(data)
    lib.registerContext(data)
end

exports('RegisterContextMenu', RegisterContextMenu)

---Show context menu
---@param id string
function ShowContextMenu(id)
    lib.showContext(id)
end

exports('ShowContextMenu', ShowContextMenu)

--=====================================================
-- BLIP HELPERS
--=====================================================

---Create blip
---@param coords vector3
---@param sprite number
---@param color number
---@param label string
---@return number blip
function CreateBlipAt(coords, sprite, color, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
    
    return blip
end

exports('CreateBlipAt', CreateBlipAt)

---Remove blip
---@param blip number
function RemoveBlipSafe(blip)
    if DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
end

exports('RemoveBlipSafe', RemoveBlipSafe)

--=====================================================
-- SOUND HELPERS
--=====================================================

---Play sound frontend
---@param soundName string
---@param soundSet string
function PlaySound(soundName, soundSet)
    PlaySoundFrontend(-1, soundName, soundSet, 1)
end

exports('PlaySound', PlaySound)

--=====================================================
-- DEBUG HELPERS
--=====================================================

---Debug print (only if Config.Debug is true)
---@param message string
function DebugPrint(message)
    if Config and Config.Debug then
        print('^3[DEBUG] ' .. message .. '^0')
    end
end

exports('DebugPrint', DebugPrint)

---Draw debug text
---@param text string
function DrawDebugText(text)
    if not Config or not Config.Debug then return end
    
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.0, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.5, 0.9)
end

exports('DrawDebugText', DrawDebugText)

--=====================================================
-- VEHICLE HELPERS
--=====================================================

---Get vehicle in direction
---@param coordFrom vector3
---@param coordTo vector3
---@return number|nil vehicle
function GetVehicleInDirection(coordFrom, coordTo)
    local rayHandle = StartShapeTestRay(
        coordFrom.x, coordFrom.y, coordFrom.z,
        coordTo.x, coordTo.y, coordTo.z,
        10, PlayerPedId(), 0
    )
    
    local _, _, _, _, vehicle = GetShapeTestResult(rayHandle)
    
    if IsEntityAVehicle(vehicle) then
        return vehicle
    end
    
    return nil
end

exports('GetVehicleInDirection', GetVehicleInDirection)

--=====================================================
-- PERFORMANCE MONITORING (Debug)
--=====================================================

if Config and Config.Debug then
    CreateThread(function()
        while true do
            Wait(5000) -- Every 5 seconds
            
            local coords = GetPlayerCoords()
            local heading = GetPlayerHeading()
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            
            DebugPrint(string.format(
                'Pos: %.2f, %.2f, %.2f | Heading: %.2f | Vehicle: %s',
                coords.x, coords.y, coords.z, heading, vehicle ~= 0 and 'Yes' or 'No'
            ))
        end
    end)
end

--=====================================================
-- EXPORTS SUMMARY
--=====================================================

print('^2[FX-RESTAURANT] Client utilities loaded^0')
print('^2Available exports: GetPlayerCoords, GetClosestPlayer, Draw3DText, IsPlayerInVehicle, etc.^0')