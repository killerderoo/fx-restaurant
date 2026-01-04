--=====================================================
-- FX-RESTAURANT | CLIENT BRIDGE
-- Target system abstraction layer (CLIENT)
--=====================================================

local Bridge = {
    Target = nil
}

--=====================================================
-- UTILS
--=====================================================

local function ResourceStarted(name)
    return GetResourceState(name) == 'started'
end

--=====================================================
-- TARGET DETECTION & SETUP
--=====================================================

CreateThread(function()
    if Config.Target == 'auto' then
        if ResourceStarted('ox_target') then
            Config.Target = 'ox'
        elseif ResourceStarted('qb-target') then
            Config.Target = 'qb'
        elseif ResourceStarted('interact') then
            Config.Target = 'interact'
        else
            Config.Target = 'none'
        end
    end

    print(('^2[FX-RESTAURANT] Target: %s^0'):format(Config.Target))

    --=================================================
    -- OX TARGET
    --=================================================
    if Config.Target == 'ox' then
        Bridge.Target = {
            AddBoxZone = function(data)
                exports.ox_target:addBoxZone(data)
            end,
            
            AddEntityZone = function(data)
                exports.ox_target:addLocalEntity(data.entity, data.options)
            end,
            
            RemoveZone = function(name)
                exports.ox_target:removeZone(name)
            end
        }
    end

    --=================================================
    -- QB TARGET
    --=================================================
    if Config.Target == 'qb' then
        Bridge.Target = {
            AddBoxZone = function(data)
                exports['qb-target']:AddBoxZone(
                    data.name,
                    data.coords,
                    data.size.x,
                    data.size.y,
                    {
                        name = data.name,
                        heading = data.heading or 0,
                        minZ = data.minZ,
                        maxZ = data.maxZ
                    },
                    {
                        options = data.options,
                        distance = data.distance or 2.0
                    }
                )
            end,
            
            AddEntityZone = function(data)
                exports['qb-target']:AddTargetEntity(data.entity, {
                    options = data.options,
                    distance = data.distance or 2.0
                })
            end,
            
            RemoveZone = function(name)
                exports['qb-target']:RemoveZone(name)
            end
        }
    end

    --=================================================
    -- INTERACT
    --=================================================
    if Config.Target == 'interact' then
        Bridge.Target = {
            AddBoxZone = function(data)
                exports.interact:AddInteraction({
                    coords = data.coords,
                    distance = data.distance or 2.0,
                    interactDst = data.distance or 2.0,
                    id = data.name,
                    name = data.label or data.name,
                    options = data.options
                })
            end,
            
            AddEntityZone = function(data)
                exports.interact:AddEntityInteraction({
                    entity = data.entity,
                    distance = data.distance or 2.0,
                    interactDst = data.distance or 2.0,
                    options = data.options
                })
            end,
            
            RemoveZone = function(name)
                exports.interact:RemoveInteraction(name)
            end
        }
    end

    --=================================================
    -- NONE (FALLBACK NAAR 3D TEXT / KEYBIND)
    --=================================================
    if Config.Target == 'none' then
        local activeZones = {}
        
        Bridge.Target = {
            AddBoxZone = function(data)
                activeZones[data.name] = data
                
                CreateThread(function()
                    while activeZones[data.name] do
                        local playerCoords = GetEntityCoords(PlayerPedId())
                        local distance = #(playerCoords - data.coords)
                        
                        if distance < (data.distance or 2.0) then
                            -- Draw 3D text
                            local label = data.options[1] and data.options[1].label or data.name
                            DrawText3D(data.coords.x, data.coords.y, data.coords.z, label)
                            
                            -- Check for key press
                            if IsControlJustReleased(0, 38) then -- E key
                                if data.options[1] and data.options[1].onSelect then
                                    data.options[1].onSelect()
                                end
                            end
                        end
                        
                        Wait(0)
                    end
                end)
            end,
            
            AddEntityZone = function(data)
                -- Simplified entity targeting
                print('[FX-RESTAURANT] Entity targeting not fully supported without target system')
            end,
            
            RemoveZone = function(name)
                activeZones[name] = nil
            end
        }
    end
end)

--=====================================================
-- HELPER: 3D TEXT DRAWING
--=====================================================

---Draw 3D text at coordinates
---@param x number
---@param y number
---@param z number
---@param text string
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

--=====================================================
-- EXPORT
--=====================================================

exports('GetTargetBridge', function()
    return Bridge.Target
end)

---Getter voor target bridge
---@return table
function GetTargetBridge()
    return Bridge.Target
end

exports('GetTargetBridge', GetTargetBridge)