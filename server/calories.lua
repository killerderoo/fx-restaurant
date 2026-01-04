--=====================================================
-- FX-RESTAURANT | CALORIE & BUFF SYSTEM (SERVER)
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

local CalorieConfig = {
    StepCalories = 100,      -- hoeveel calorieën per stap
    StepValue    = 10,       -- percentage hunger/thirst per stap
    MaxValue     = 100       -- max hunger/thirst
}

--=====================================================
-- INTERNAL UTILS
--=====================================================

---Klem waarde tussen min en max
---@param value number
---@param min number
---@param max number
---@return number
local function Clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

---Bereken stapwaarde uit calorieën
---@param calories number
---@return number
local function CalculateStep(calories)
    if not calories or calories <= 0 then return 0 end
    return math.floor(calories / CalorieConfig.StepCalories) * CalorieConfig.StepValue
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

    if data.type == 'drink' or data.type == 'finished' then
        -- Finished items kunnen BEIDE vullen
        if data.type == 'finished' then
            return { 
                hunger = step,
                thirst = math.floor(step * 0.3) -- 30% thirst
            }
        end
        
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
        -- Valideer value type
        if type(value) ~= 'number' then
            print('^3[WARNING] Invalid buff value for ' .. buff .. '^0')
            goto continue
        end
        
        if buff == 'stress' then
            -- Stress verminderen (negatieve waarde = vermindering)
            if value < 0 then
                TriggerEvent('hud:server:RelieveStress', src, math.abs(value))
            end

        elseif buff == 'stamina' then
            TriggerClientEvent('fx-restaurant:buff:stamina', src, value)

        elseif buff == 'armor' then
            TriggerClientEvent('fx-restaurant:buff:armor', src, value)

        else
            -- Custom buff hook voor andere scripts
            TriggerEvent('fx-restaurant:buff:custom', src, buff, value)
        end
        
        ::continue::
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
    if not src or src <= 0 then 
        return false 
    end
    
    if not ItemExists(item) then 
        return false 
    end

    local data = GetItemData(item)
    if not data then 
        return false 
    end

    --========================
    -- HUNGER / THIRST
    --========================
    local needs = CalculateNeedsFromItem(item)

    if needs.hunger then
        TriggerClientEvent('fx-restaurant:needs:addHunger', src, needs.hunger)
    end

    if needs.thirst then
        TriggerClientEvent('fx-restaurant:needs:addThirst', src, needs.thirst)
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
-- EXPORTS
--=====================================================

exports('ApplyItemConsumption', ApplyItemConsumption)
exports('CalculateNeedsFromItem', CalculateNeedsFromItem)
exports('ApplyBuffs', ApplyBuffs)