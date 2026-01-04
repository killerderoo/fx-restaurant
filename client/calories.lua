--=====================================================
-- FX-RESTAURANT | CALORIE & BUFF SYSTEM (CLIENT)
--=====================================================
-- Verantwoordelijkheden:
-- - Ontvangen van hunger/thirst updates van server
-- - Appliceren van buffs (stamina, armor)
-- - Visuele feedback
--=====================================================

local Config = {
    MaxValue = 100
}

--=====================================================
-- UTILS
--=====================================================

---Klem waarde tussen min en max
---@param value number
---@param min number
---@param max number
---@return number
local function Clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

--=====================================================
-- NEEDS HANDLERS (HUNGER/THIRST)
--=====================================================

---Verhoog hunger waarde
---@param amount number
RegisterNetEvent('fx-restaurant:needs:addHunger', function(amount)
    if not amount or amount <= 0 then return end
    
    -- FRAMEWORK SPECIFIEK
    if GetResourceState('es_extended') == 'started' then
        TriggerEvent('esx_status:add', 'hunger', amount * 10000)
        
    elseif GetResourceState('qb-core') == 'started' then
        TriggerServerEvent('QBCore:Server:SetMetaData', 'hunger', amount)
        
    else
        -- CUSTOM FRAMEWORK
        TriggerEvent('fx-restaurant:custom:addHunger', amount)
    end
end)

---Verhoog thirst waarde
---@param amount number
RegisterNetEvent('fx-restaurant:needs:addThirst', function(amount)
    if not amount or amount <= 0 then return end
    
    -- FRAMEWORK SPECIFIEK
    if GetResourceState('es_extended') == 'started' then
        TriggerEvent('esx_status:add', 'thirst', amount * 10000)
        
    elseif GetResourceState('qb-core') == 'started' then
        TriggerServerEvent('QBCore:Server:SetMetaData', 'thirst', amount)
        
    else
        -- CUSTOM FRAMEWORK
        TriggerEvent('fx-restaurant:custom:addThirst', amount)
    end
end)

--=====================================================
-- BUFF HANDLERS
--=====================================================

---Stamina buff (tijdelijk sneller rennen)
---@param value number Percentage boost (bijv. 10 = 10% boost)
RegisterNetEvent('fx-restaurant:buff:stamina', function(value)
    if not value or value <= 0 then return end
    
    local ped = PlayerPedId()
    
    -- Herstel stamina volledig
    RestorePlayerStamina(PlayerId(), 1.0)
    
    -- Geef tijdelijke snelheidsboost
    local multiplier = 1.0 + (value / 100)
    SetRunSprintMultiplierForPlayer(PlayerId(), multiplier)
    
    -- Visuele feedback
    lib.notify({
        title = 'Stamina Boost',
        description = ('Je voelt je energieker! (+%d%%)'):format(value),
        type = 'success',
        icon = 'fa-solid fa-bolt',
        duration = 3000
    })
    
    -- Reset na 10 seconden
    SetTimeout(10000, function()
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        
        lib.notify({
            description = 'Stamina boost is verlopen',
            type = 'info',
            duration = 2000
        })
    end)
end)

---Armor buff
---@param value number Hoeveelheid armor om toe te voegen
RegisterNetEvent('fx-restaurant:buff:armor', function(value)
    if not value then return end
    
    local ped = PlayerPedId()
    local currentArmor = GetPedArmour(ped)
    local newArmor = Clamp(currentArmor + value, 0, 100)
    
    SetPedArmour(ped, newArmor)
    
    -- Visuele feedback
    if value > 0 then
        lib.notify({
            title = 'Armor',
            description = ('Armor verhoogd met %d'):format(value),
            type = 'success',
            icon = 'fa-solid fa-shield',
            duration = 3000
        })
    end
end)

---Custom buff handler (voor andere scripts)
---@param buffName string
---@param value number
RegisterNetEvent('fx-restaurant:buff:custom', function(buffName, value)
    -- Hook voor andere resources
    print(('[FX-RESTAURANT] Custom buff: %s = %s'):format(buffName, value))
end)