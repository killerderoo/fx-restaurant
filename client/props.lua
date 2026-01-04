--=====================================================
-- FX-RESTAURANT | PROPS SYSTEM (CLIENT)
--=====================================================
-- Decoratie props plaatsen/verwijderen
--=====================================================

local spawnedProps = {}

--=====================================================
-- SPAWN PROP
--=====================================================

---Spawn een prop op locatie
---@param model string
---@param coords vector3
---@param heading number
---@return number entity
local function SpawnProp(model, coords, heading)
    local hash = GetHashKey(model)
    
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    
    local prop = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(prop, heading or 0.0)
    FreezeEntityPosition(prop, true)
    SetEntityAsMissionEntity(prop, true, true)
    
    SetModelAsNoLongerNeeded(hash)
    
    return prop
end

--=====================================================
-- LOAD RESTAURANT PROPS
--=====================================================

---Load all props voor restaurant
---@param restaurant string
function LoadRestaurantProps(restaurant)
    lib.callback('fx-restaurant:props:getAll', false, function(props)
        if not props or #props == 0 then return end
        
        for _, propData in ipairs(props) do
            local coords = json.decode(propData.coords)
            local entity = SpawnProp(
                propData.model,
                vector3(coords.x, coords.y, coords.z),
                propData.heading
            )
            
            table.insert(spawnedProps, {
                id = propData.id,
                entity = entity,
                restaurant = restaurant
            })
        end
        
        print(string.format('^2[PROPS] Loaded %d props for %s^0', #props, restaurant))
    end, restaurant)
end

exports('LoadRestaurantProps', LoadRestaurantProps)

--=====================================================
-- PLACE PROP (ADMIN/BOSS)
--=====================================================

---Plaats een nieuwe prop
---@param restaurant string
---@param model string
function PlaceProp(restaurant, model)
    -- Get player coords
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    -- Forward offset
    local forward = GetEntityForwardVector(ped)
    coords = coords + (forward * 2.0)
    
    -- Spawn preview
    local preview = SpawnProp(model, coords, heading)
    
    lib.notify({
        title = 'Prop Plaatsen',
        description = 'Druk op E om te plaatsen, X om te annuleren',
        type = 'info'
    })
    
    -- Wait for confirmation
    local placing = true
    local confirmed = false
    
    CreateThread(function()
        while placing do
            Wait(0)
            
            -- Draw marker
            DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                       0.3, 0.3, 0.3, 0, 255, 0, 100, false, true, 2, false, nil, nil, false)
            
            -- Move controls
            if IsControlPressed(0, 32) then -- W
                coords = coords + GetEntityForwardVector(ped) * 0.01
                SetEntityCoords(preview, coords.x, coords.y, coords.z, false, false, false, false)
            end
            
            if IsControlPressed(0, 33) then -- S
                coords = coords - GetEntityForwardVector(ped) * 0.01
                SetEntityCoords(preview, coords.x, coords.y, coords.z, false, false, false, false)
            end
            
            -- Rotate
            if IsControlPressed(0, 34) then -- A
                heading = heading - 1.0
                SetEntityHeading(preview, heading)
            end
            
            if IsControlPressed(0, 35) then -- D
                heading = heading + 1.0
                SetEntityHeading(preview, heading)
            end
            
            -- Confirm
            if IsControlJustReleased(0, 38) then -- E
                confirmed = true
                placing = false
            end
            
            -- Cancel
            if IsControlJustReleased(0, 73) then -- X
                placing = false
            end
        end
    end)
    
    -- Wait for result
    while placing do
        Wait(100)
    end
    
    if confirmed then
        -- Save to database
        lib.callback('fx-restaurant:props:place', false, function(success, propId)
            if success then
                lib.notify({
                    title = 'Prop Geplaatst',
                    description = 'Prop is succesvol geplaatst',
                    type = 'success'
                })
                
                table.insert(spawnedProps, {
                    id = propId,
                    entity = preview,
                    restaurant = restaurant
                })
            else
                DeleteObject(preview)
                lib.notify({
                    title = 'Fout',
                    description = 'Kon prop niet plaatsen',
                    type = 'error'
                })
            end
        end, restaurant, model, coords, heading)
    else
        DeleteObject(preview)
    end
end

exports('PlaceProp', PlaceProp)

--=====================================================
-- DELETE NEAREST PROP
--=====================================================

---Verwijder dichtstbijzijnde prop
---@param restaurant string
function DeleteNearestProp(restaurant)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    local nearest = nil
    local nearestDist = 5.0
    
    for _, prop in ipairs(spawnedProps) do
        if prop.restaurant == restaurant then
            local propCoords = GetEntityCoords(prop.entity)
            local dist = #(coords - propCoords)
            
            if dist < nearestDist then
                nearest = prop
                nearestDist = dist
            end
        end
    end
    
    if not nearest then
        lib.notify({
            title = 'Geen Prop',
            description = 'Geen prop in de buurt gevonden',
            type = 'error'
        })
        return
    end
    
    -- Confirm
    local alert = lib.alertDialog({
        header = 'Prop Verwijderen',
        content = 'Weet je zeker dat je deze prop wilt verwijderen?',
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        lib.callback('fx-restaurant:props:delete', false, function(success)
            if success then
                DeleteObject(nearest.entity)
                
                for i, prop in ipairs(spawnedProps) do
                    if prop.id == nearest.id then
                        table.remove(spawnedProps, i)
                        break
                    end
                end
                
                lib.notify({
                    title = 'Prop Verwijderd',
                    description = 'Prop is verwijderd',
                    type = 'success'
                })
            end
        end, nearest.id)
    end
end

exports('DeleteNearestProp', DeleteNearestProp)

--=====================================================
-- CLEANUP ON RESOURCE STOP
--=====================================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    for _, prop in ipairs(spawnedProps) do
        if DoesEntityExist(prop.entity) then
            DeleteObject(prop.entity)
        end
    end
end)

--=====================================================
-- AUTO-LOAD PROPS ON START
--=====================================================

CreateThread(function()
    Wait(5000) -- Wait for resource to load
    
    local restaurants = { 'default', 'burgershot' } -- Add your restaurants
    
    for _, restaurant in ipairs(restaurants) do
        LoadRestaurantProps(restaurant)
    end
end)