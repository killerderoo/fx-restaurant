--=====================================================
-- FX-RESTAURANT | CALORIE & BUFF SYSTEM
--=====================================================
-- Regels:
-- - Elke 100 calorieën = 10% hunger OF thirst
-- - Drinks vullen thirst
-- - Food vult hunger
-- - Buffs zijn optioneel per item
-- - Server is altijd authoritative
--=====================================================

--=====================================================
-- CONFIG
--=====================================================

Calories = {}

Calories.StepCalories = 100      -- hoeveel calorieën per stap
Calories.StepValue    = 10       -- percentage hunger/thirst per stap
Calories.MaxValue     = 100      -- max hunger/thirst

--=====================================================
-- INTERNAL UTILS
--=====================================================

local function Clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

local function CalculateStep(calories)
    if not calories or calories <= 0 then return 0 end
    return math.floor(calories / Calories.StepCalories) * Calories.StepValue
end

--=====================================================
-- CALCULATION LOGIC
--=====================================================

---Berekent hunger/thirst op basis van item
---@param item string
---@return table { hunger?, thirst? }
function CalculateNeedsFromItem(item)
    if not ItemExists(item) then return {} end

    local data = GetItemData(item)
    if not data then return {} end

    local step = CalculateStep(data.calories)

    if step <= 0 then return {} end

    if data.type == 'drink' then
        return { thirst = step }
    end

    return { hunger = step }
end

--=====================================================
-- BUFF SYSTEM
--=====================================================

---Past buffs toe op speler
---@param src number
---@param buffs table
function ApplyBuffs(src, buffs)
    if not buffs or type(buffs) ~= 'table' then return end

    for buff, value in pairs(buffs) do
        if buff == 'stress' then
            TriggerEvent('hud:server:RelieveStress', src, math.abs(value))

        elseif buff == 'stamina' then
            TriggerClientEvent('fx-restaurant:buff:stamina', src, value)

        elseif buff == 'armor' then
            TriggerClientEvent('fx-restaurant:buff:armor', src, value)

        else
            -- custom buff hook
            TriggerEvent('fx-restaurant:buff:custom', src, buff, value)
        end
    end
end

--=====================================================
-- APPLY ITEM EFFECT (SERVER ONLY)
--=====================================================

---Gebruiken van eten/drinken
---@param src number
---@param item string
---@return boolean
function ApplyItemConsumption(src, item)
    if not ItemExists(item) then return false end

    local data = GetItemData(item)
    if not data then return false end

    local Bridge = exports['fx-restaurant']:GetBridge()

    --========================
    -- HUNGER / THIRST
    --========================
    local needs = CalculateNeedsFromItem(item)

    if needs.hunger then
        TriggerClientEvent('fx-restaurant:setHunger', src, needs.hunger)
    end

    if needs.thirst then
        TriggerClientEvent('fx-restaurant:setThirst', src, needs.thirst)
    end

    --========================
    -- BUFFS
    --========================
    if data.buffs then
        ApplyBuffs(src, data.buffs)
    end

    return true
end

--=====================================================
-- CLIENT SYNC EVENTS (OPTIONEEL)
--=====================================================

RegisterNetEvent('fx-restaurant:buff:stamina', function(value)
    local ped = PlayerPedId()
    RestorePlayerStamina(PlayerId(), 1.0)

    if value and value > 0 then
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0 + (value / 100))
        SetTimeout(10000, function()
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        end)
    end
end)

RegisterNetEvent('fx-restaurant:buff:armor', function(value)
    local ped = PlayerPedId()
    local armor = GetPedArmour(ped)
    SetPedArmour(ped, Clamp(armor + value, 0, 100))
end)

--=====================================================
-- EXPORTS
--=====================================================

exports('ApplyItemConsumption', ApplyItemConsumption)
exports('CalculateNeedsFromItem', CalculateNeedsFromItem)
