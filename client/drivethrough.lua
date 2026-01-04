--=====================================================
-- FX-RESTAURANT | DRIVE-THROUGH (CLIENT)
--=====================================================
-- Complete drive-through systeem met voice
--=====================================================

local inDriveThrough = false
local currentRestaurant = nil
local driveThroughOrder = nil

--=====================================================
-- ENTER DRIVE-THROUGH ZONE
--=====================================================

---Check if player enters drive-through zone
---@param restaurant string
---@param coords vector3
function CheckDriveThroughZone(restaurant, coords)
    CreateThread(function()
        local checkZone = true
        
        while checkZone do
            Wait(500)
            
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if vehicle ~= 0 and not inDriveThrough then
                local vehCoords = GetEntityCoords(vehicle)
                local distance = #(vehCoords - coords)
                
                if distance < 5.0 then
                    -- Trigger drive-through
                    TriggerDriveThrough(restaurant)
                    checkZone = false
                end
            end
            
            if inDriveThrough then
                checkZone = false
            end
        end
    end)
end

exports('CheckDriveThroughZone', CheckDriveThroughZone)

--=====================================================
-- TRIGGER DRIVE-THROUGH
--=====================================================

function TriggerDriveThrough(restaurant)
    inDriveThrough = true
    currentRestaurant = restaurant
    
    -- Notify player
    lib.notify({
        title = 'Drive-Through',
        description = 'Welkom! Bestel via de intercom',
        type = 'info',
        duration = 5000
    })
    
    -- Play sound
    PlaySoundFrontend(-1, "Menu_Accept", "Phone_SoundSet_Default", 1)
    
    -- Notify staff
    TriggerServerEvent('fx-restaurant:drivethrough:notify', restaurant)
    
    -- Open ordering UI
    Wait(1000)
    OpenDriveThroughMenu(restaurant)
end

--=====================================================
-- OPEN DRIVE-THROUGH MENU
--=====================================================

function OpenDriveThroughMenu(restaurant)
    lib.callback('fx-restaurant:drivethrough:getMenu', false, function(items)
        if not items or #items == 0 then
            lib.notify({
                title = 'Drive-Through',
                description = 'Menu niet beschikbaar',
                type = 'error'
            })
            inDriveThrough = false
            return
        end
        
        -- Build menu options
        local options = {}
        
        for _, item in ipairs(items) do
            table.insert(options, {
                title = item.name,
                description = string.format('$%d', item.price),
                icon = 'utensils',
                onSelect = function()
                    AddToDriveThroughOrder(item)
                end
            })
        end
        
        table.insert(options, {
            title = '✅ Bestelling Bevestigen',
            description = 'Plaats je bestelling',
            icon = 'check',
            iconColor = '#10b981',
            onSelect = function()
                ConfirmDriveThroughOrder()
            end
        })
        
        table.insert(options, {
            title = '❌ Annuleren',
            icon = 'times',
            iconColor = '#ef4444',
            onSelect = function()
                CancelDriveThroughOrder()
            end
        })
        
        lib.registerContext({
            id = 'drivethrough_menu',
            title = 'Drive-Through Menu',
            options = options
        })
        
        lib.showContext('drivethrough_menu')
    end, restaurant)
end

--=====================================================
-- ORDER MANAGEMENT
--=====================================================

function AddToDriveThroughOrder(item)
    if not driveThroughOrder then
        driveThroughOrder = {}
    end
    
    -- Check if item already in order
    local found = false
    for i, orderItem in ipairs(driveThroughOrder) do
        if orderItem.item == item.item then
            driveThroughOrder[i].amount = driveThroughOrder[i].amount + 1
            found = true
            break
        end
    end
    
    if not found then
        table.insert(driveThroughOrder, {
            item = item.item,
            name = item.name,
            price = item.price,
            amount = 1
        })
    end
    
    lib.notify({
        title = 'Toegevoegd',
        description = string.format('%s toegevoegd aan bestelling', item.name),
        type = 'success'
    })
    
    -- Reopen menu
    Wait(500)
    OpenDriveThroughMenu(currentRestaurant)
end

function ConfirmDriveThroughOrder()
    if not driveThroughOrder or #driveThroughOrder == 0 then
        lib.notify({
            title = 'Bestelling',
            description = 'Je winkelwagen is leeg',
            type = 'error'
        })
        return
    end
    
    -- Calculate total
    local total = 0
    for _, item in ipairs(driveThroughOrder) do
        total = total + (item.price * item.amount)
    end
    
    -- Confirm with player
    local alert = lib.alertDialog({
        header = 'Bestelling Bevestigen',
        content = string.format('Totaal: $%d\n\nRijd door naar het afhaalvenster', total),
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        -- Place order
        lib.callback('fx-restaurant:drivethrough:placeOrder', false, function(success, result)
            if success then
                lib.notify({
                    title = 'Bestelling Geplaatst',
                    description = string.format('Ordernummer: %s', result.orderNumber),
                    type = 'success',
                    duration = 7000
                })
                
                -- Reset
                driveThroughOrder = nil
                
                -- Set waypoint to pickup
                if result.pickupCoords then
                    SetNewWaypoint(result.pickupCoords.x, result.pickupCoords.y)
                end
            else
                lib.notify({
                    title = 'Fout',
                    description = 'Kon bestelling niet plaatsen',
                    type = 'error'
                })
            end
        end, currentRestaurant, driveThroughOrder)
    end
end

function CancelDriveThroughOrder()
    driveThroughOrder = nil
    inDriveThrough = false
    currentRestaurant = nil
    
    lib.notify({
        title = 'Geannuleerd',
        description = 'Bestelling geannuleerd',
        type = 'info'
    })
end

--=====================================================
-- PICKUP ORDER
--=====================================================

---Pickup order from window
---@param restaurant string
function PickupDriveThroughOrder(restaurant)
    lib.callback('fx-restaurant:drivethrough:pickup', false, function(success, result)
        if success then
            lib.notify({
                title = 'Bestelling Ontvangen',
                description = 'Geniet van je maaltijd!',
                type = 'success'
            })
            
            PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", 1)
            
            inDriveThrough = false
            currentRestaurant = nil
        else
            lib.notify({
                title = 'Geen Bestelling',
                description = 'Je hebt geen actieve bestelling',
                type = 'error'
            })
        end
    end, restaurant)
end

exports('PickupDriveThroughOrder', PickupDriveThroughOrder)

--=====================================================
-- STAFF NOTIFICATION (Receive from server)
--=====================================================

RegisterNetEvent('fx-restaurant:drivethrough:staffNotify', function(restaurant, customer)
    lib.notify({
        title = 'Drive-Through',
        description = string.format('%s is bij de drive-through', customer),
        type = 'info',
        icon = 'fa-solid fa-car',
        duration = 10000
    })
    
    PlaySoundFrontend(-1, "Menu_Accept", "Phone_SoundSet_Default", 1)
end)