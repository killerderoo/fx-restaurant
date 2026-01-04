--=====================================================
-- FX-RESTAURANT | DELIVERY SYSTEM (CLIENT)
--=====================================================
-- GPS routing, NPC interaction, vehicle spawning
--=====================================================

local activeDelivery = nil
local deliveryVehicle = nil
local deliveryBlip = nil
local deliveryNPC = nil
local isOnDelivery = false

--=====================================================
-- START DELIVERY
--=====================================================

---Start a delivery mission
---@param restaurant string Restaurant ID
function StartDelivery(restaurant)
    if isOnDelivery then
        lib.notify({
            title = 'Bezorging',
            description = 'Je bent al bezig met een bezorging',
            type = 'error'
        })
        return
    end
    
    -- Check cooldown
    lib.callback('fx-restaurant:delivery:checkCooldown', false, function(canDeliver, timeLeft)
        if not canDeliver then
            lib.notify({
                title = 'Bezorging',
                description = string.format('Wacht nog %d seconden', timeLeft),
                type = 'warning'
            })
            return
        end
        
        -- Start delivery
        lib.callback('fx-restaurant:delivery:start', false, function(success, result, extra)
            if not success then
                lib.notify({
                    title = 'Bezorging Mislukt',
                    description = GetErrorMessage(result),
                    type = 'error'
                })
                return
            end
            
            activeDelivery = result
            isOnDelivery = true
            
            -- Show order details
            ShowOrderDetails(result.order)
            
            -- Spawn vehicle
            Wait(1000)
            SpawnDeliveryVehicle(restaurant)
        end, restaurant)
    end)
end

exports('StartDelivery', StartDelivery)

--=====================================================
-- SHOW ORDER DETAILS
--=====================================================

function ShowOrderDetails(order)
    local itemsText = ''
    for i, item in ipairs(order.items) do
        itemsText = itemsText .. string.format('- %dx %s\n', item.amount, item.label)
    end
    
    lib.alertDialog({
        header = 'Nieuwe Bestelling!',
        content = string.format(
            '**Bestemming:** %s (%s)\n\n' ..
            '**Items:**\n%s\n' ..
            '**Betaling:** $%d\n' ..
            '**Fooi:** $%d\n' ..
            '**Totaal:** $%d',
            order.location.name,
            order.location.area,
            itemsText,
            order.payment,
            order.tip,
            order.total
        ),
        centered = true
    })
end

--=====================================================
-- SPAWN DELIVERY VEHICLE
--=====================================================

function SpawnDeliveryVehicle(restaurant)
    -- Get restaurant config for vehicle spawn
    local configPath = ('shared/restaurants/%s/config.lua'):format(restaurant)
    local configData = LoadResourceFile(GetCurrentResourceName(), configPath)
    
    if not configData then
        lib.notify({
            title = 'Fout',
            description = 'Kon restaurant config niet laden',
            type = 'error'
        })
        return
    end
    
    local env = { Restaurant = nil }
    local chunk = load(configData, configPath, 't', env)
    if chunk then pcall(chunk) end
    local config = env.Restaurant
    
    if not config or not config.delivery or not config.delivery.vehicle_spawn then
        lib.notify({
            title = 'Fout',
            description = 'Geen voertuig spawn geconfigureerd',
            type = 'error'
        })
        return
    end
    
    local spawn = config.delivery.vehicle_spawn
    local model = GetHashKey(spawn.model or 'faggio')
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    deliveryVehicle = CreateVehicle(
        model,
        spawn.coords.x, spawn.coords.y, spawn.coords.z, spawn.coords.w,
        true, false
    )
    
    SetVehicleNumberPlateText(deliveryVehicle, 'DELIVERY')
    SetVehicleCustomPrimaryColour(deliveryVehicle, 255, 150, 0)
    
    SetModelAsNoLongerNeeded(model)
    
    -- Give keys (framework dependent)
    if GetResourceState('qb-core') == 'started' then
        TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(deliveryVehicle))
    end
    
    lib.notify({
        title = 'Bezorgvoertuig',
        description = 'Je bezorgvoertuig is gespawned',
        type = 'success'
    })
    
    -- Update status
    lib.callback('fx-restaurant:delivery:updateStatus', false, function() end, 'preparing')
    
    -- Set GPS to destination
    Wait(2000)
    SetGPSToDestination()
end

--=====================================================
-- SET GPS TO DESTINATION
--=====================================================

function SetGPSToDestination()
    if not activeDelivery then return end
    
    local coords = activeDelivery.order.location.coords
    
    -- Create blip
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
    end
    
    deliveryBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(deliveryBlip, 1)
    SetBlipColour(deliveryBlip, 5)
    SetBlipRoute(deliveryBlip, true)
    SetBlipRouteColour(deliveryBlip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Bezorg Locatie')
    EndTextCommandSetBlipName(deliveryBlip)
    
    -- Set waypoint
    SetNewWaypoint(coords.x, coords.y)
    
    lib.notify({
        title = 'GPS Ingesteld',
        description = string.format('Ga naar %s', activeDelivery.order.location.name),
        type = 'info',
        duration = 5000
    })
    
    -- Start distance check
    CheckDeliveryDistance()
end

--=====================================================
-- CHECK DISTANCE TO DESTINATION
--=====================================================

function CheckDeliveryDistance()
    CreateThread(function()
        while isOnDelivery and activeDelivery do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local targetCoords = activeDelivery.order.location.coords
            local distance = #(playerCoords - vector3(targetCoords.x, targetCoords.y, targetCoords.z))
            
            if distance < 50.0 then
                -- Update status
                lib.callback('fx-restaurant:delivery:updateStatus', false, function() end, 'in_transit')
                
                -- Spawn NPC
                SpawnDeliveryNPC()
                break
            end
            
            Wait(1000)
        end
    end)
end

--=====================================================
-- SPAWN DELIVERY NPC
--=====================================================

function SpawnDeliveryNPC()
    if deliveryNPC then return end
    
    local coords = activeDelivery.order.location.coords
    local model = GetHashKey('a_m_m_business_01')
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    deliveryNPC = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, 0.0, false, true)
    
    FreezeEntityPosition(deliveryNPC, true)
    SetEntityInvincible(deliveryNPC, true)
    SetBlockingOfNonTemporaryEvents(deliveryNPC, true)
    
    -- Play scenario
    TaskStartScenarioInPlace(deliveryNPC, 'WORLD_HUMAN_STAND_MOBILE', 0, true)
    
    SetModelAsNoLongerNeeded(model)
    
    -- Add target
    local Target = exports['fx-restaurant']:GetTargetBridge()
    if Target and Target.AddEntityZone then
        Target.AddEntityZone({
            entity = deliveryNPC,
            distance = 3.0,
            options = {
                {
                    icon = 'fa-solid fa-box',
                    label = 'Bestelling Afleveren',
                    onSelect = function()
                        DeliverOrder()
                    end
                }
            }
        })
    end
    
    lib.notify({
        title = 'Klant Gevonden',
        description = 'Lever de bestelling af bij de klant',
        type = 'success'
    })
end

--=====================================================
-- DELIVER ORDER
--=====================================================

function DeliverOrder()
    if not activeDelivery then return end
    
    -- Check if player has all items
    local Inventory = exports['fx-restaurant']:GetBridge().Inventory
    local hasAllItems = true
    
    for _, item in ipairs(activeDelivery.order.items) do
        if not Inventory.HasItem(PlayerId(), item.item, item.amount) then
            hasAllItems = false
            break
        end
    end
    
    -- Confirmation
    local itemsText = ''
    for _, item in ipairs(activeDelivery.order.items) do
        local status = Inventory.HasItem(PlayerId(), item.item, item.amount) and '✅' or '❌'
        itemsText = itemsText .. string.format('%s %dx %s\n', status, item.amount, item.label)
    end
    
    local alert = lib.alertDialog({
        header = 'Bestelling Afleveren',
        content = string.format(
            '**Items:**\n%s\n' ..
            '%s',
            itemsText,
            hasAllItems and '**Volledige bestelling!**' or '**WAARSCHUWING:** Ontbrekende items = 50% betaling'
        ),
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Afleveren',
            cancel = 'Annuleren'
        }
    })
    
    if alert ~= 'confirm' then return end
    
    -- Delivery animation
    local ped = PlayerPedId()
    lib.requestAnimDict('mp_common')
    TaskPlayAnim(ped, 'mp_common', 'givetake1_a', 8.0, -8.0, 2000, 0, 0, false, false, false)
    
    Wait(2000)
    
    -- Complete delivery
    lib.callback('fx-restaurant:delivery:complete', false, function(success, result)
        if success then
            -- Show NPC reaction
            PlayNPCReaction(hasAllItems)
            
            lib.notify({
                title = 'Bezorging Voltooid!',
                description = string.format(
                    'Betaling: $%d%s\nFactuur: %s',
                    result.payment,
                    result.tip > 0 and string.format(' (+ $%d fooi!)', result.tip) or '',
                    result.deliveryNumber
                ),
                type = 'success',
                duration = 7000
            })
            
            PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", 1)
            
            -- Cleanup
            Wait(3000)
            CleanupDelivery()
        else
            lib.notify({
                title = 'Fout',
                description = GetErrorMessage(result),
                type = 'error'
            })
        end
    end, hasAllItems)
end

--=====================================================
-- NPC REACTION
--=====================================================

function PlayNPCReaction(success)
    if not deliveryNPC then return end
    
    local anim = success and 'WORLD_HUMAN_CHEERING' or 'WORLD_HUMAN_CLIPBOARD'
    TaskStartScenarioInPlace(deliveryNPC, anim, 0, true)
    
    -- Play sound
    if success then
        PlayAmbientSpeech1(deliveryNPC, "GENERIC_THANKS", "SPEECH_PARAMS_FORCE")
    else
        PlayAmbientSpeech1(deliveryNPC, "GENERIC_WHATEVER", "SPEECH_PARAMS_FORCE")
    end
end

--=====================================================
-- CLEANUP DELIVERY
--=====================================================

function CleanupDelivery()
    isOnDelivery = false
    activeDelivery = nil
    
    -- Remove blip
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
    
    -- Delete NPC
    if deliveryNPC then
        DeleteEntity(deliveryNPC)
        deliveryNPC = nil
    end
    
    -- Delete vehicle
    if deliveryVehicle and DoesEntityExist(deliveryVehicle) then
        DeleteVehicle(deliveryVehicle)
        deliveryVehicle = nil
    end
end

--=====================================================
-- CANCEL DELIVERY
--=====================================================

RegisterCommand('canceldelivery', function()
    if not isOnDelivery then
        lib.notify({
            title = 'Bezorging',
            description = 'Je bent niet bezig met een bezorging',
            type = 'error'
        })
        return
    end
    
    local alert = lib.alertDialog({
        header = 'Bezorging Annuleren',
        content = 'Weet je zeker dat je deze bezorging wilt annuleren?',
        centered = true,
        cancel = true
    })
    
    if alert ~= 'confirm' then return end
    
    lib.callback('fx-restaurant:delivery:cancel', false, function(success)
        if success then
            lib.notify({
                title = 'Bezorging Geannuleerd',
                description = 'Je kunt over 1 minuut weer een bezorging doen',
                type = 'info'
            })
            CleanupDelivery()
        end
    end)
end)

--=====================================================
-- ERROR MESSAGES
--=====================================================

function GetErrorMessage(error)
    local messages = {
        cooldown = 'Je moet nog wachten',
        already_active = 'Je bent al bezig met een bezorging',
        no_job = 'Je hebt geen restaurant baan',
        generation_failed = 'Kon geen bestelling genereren',
        database_error = 'Database fout',
        no_active_delivery = 'Geen actieve bezorging',
        missing_items = 'Je mist items',
        bridge_error = 'Bridge fout'
    }
    
    return messages[error] or 'Er is een fout opgetreden'
end

--=====================================================
-- CLEANUP ON RESOURCE STOP
--=====================================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CleanupDelivery()
end)
