--=====================================================
-- FX-RESTAURANT | NPC SPAWNING (CLIENT)
--=====================================================
-- Spawns ingredient shop NPCs
--=====================================================

local spawnedNPCs = {}

--=====================================================
-- SPAWN NPC
--=====================================================

---Spawn an NPC at location
---@param data table NPC data
---@return number entity Ped entity
local function SpawnNPC(data)
    local model = GetHashKey(data.model)
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    local coords = data.coords
    local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w or 0.0, false, true)
    
    -- Set properties
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    -- Set scenario
    if data.scenario then
        TaskStartScenarioInPlace(ped, data.scenario, 0, true)
    end
    
    SetModelAsNoLongerNeeded(model)
    
    return ped
end

--=====================================================
-- SPAWN INGREDIENT SHOP NPCS
--=====================================================

CreateThread(function()
    Wait(2000) -- Wait for resource to fully load
    
    if not Config.IngredientShop or not Config.IngredientShop.locations then
        return
    end
    
    for _, location in ipairs(Config.IngredientShop.locations) do
        -- Spawn NPC
        local npcData = {
            model = Config.IngredientShop.npc.model,
            coords = location.coords,
            scenario = Config.IngredientShop.npc.scenario
        }
        
        local ped = SpawnNPC(npcData)
        
        table.insert(spawnedNPCs, {
            entity = ped,
            location = location.restaurant
        })
        
        -- Add target
        local Target = exports['fx-restaurant']:GetTargetBridge()
        if Target and Target.AddEntityZone then
            Target.AddEntityZone({
                entity = ped,
                distance = 3.0,
                options = {
                    {
                        icon = 'fa-solid fa-shopping-cart',
                        label = 'Ingrediënten Inkopen',
                        onSelect = function()
                            OpenIngredientShop()
                        end
                    }
                }
            })
        end
        
        print(string.format('^2[NPC] Spawned ingredient shop NPC for: %s^0', location.restaurant))
    end
    
    -- Blip
    if Config.IngredientShop.blip.enabled then
        for _, location in ipairs(Config.IngredientShop.locations) do
            local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
            SetBlipSprite(blip, Config.IngredientShop.blip.sprite)
            SetBlipColour(blip, Config.IngredientShop.blip.color)
            SetBlipScale(blip, Config.IngredientShop.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(location.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

--=====================================================
-- CLEANUP ON RESOURCE STOP
--=====================================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    for _, npc in ipairs(spawnedNPCs) do
        if DoesEntityExist(npc.entity) then
            DeleteEntity(npc.entity)
        end
    end
end)