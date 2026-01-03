--=====================================================
-- FX-RESTAURANT | ITEMS REGISTRY
--=====================================================
-- Alle items die gebruikt worden door het restaurant
-- systeem moeten hier geregistreerd staan.
--
-- type:
-- ingredient  = raw ingredient
-- prepared    = voorbereid item (gesneden, gemalen)
-- drink       = drank
-- finished    = eindproduct (mag verkocht worden)
--
-- calories:
-- elke 100 calories = 10% hunger OF thirst
--
-- buffs (optioneel):
-- { stamina = 10, stress = -5, armor = 5 }
--=====================================================

Items = {

    --=================================================
    -- MAIN INGREDIENTS
    --=================================================
    meat        = { type = 'ingredient', calories = 120 },
    fish        = { type = 'ingredient', calories = 110 },
    onion       = { type = 'ingredient', calories = 40 },
    carrot      = { type = 'ingredient', calories = 35 },
    lettuce     = { type = 'ingredient', calories = 15 },
    cucumber    = { type = 'ingredient', calories = 16 },
    potato      = { type = 'ingredient', calories = 77 },
    tomato      = { type = 'ingredient', calories = 18 },
    wheat       = { type = 'ingredient', calories = 340 },

    strawberry  = { type = 'ingredient', calories = 32 },
    watermelon  = { type = 'ingredient', calories = 30 },
    pineapple   = { type = 'ingredient', calories = 50 },
    apple       = { type = 'ingredient', calories = 52 },
    pear        = { type = 'ingredient', calories = 57 },
    lemon       = { type = 'ingredient', calories = 29 },
    banana      = { type = 'ingredient', calories = 89 },
    orange      = { type = 'ingredient', calories = 47 },
    peach       = { type = 'ingredient', calories = 39 },
    mango       = { type = 'ingredient', calories = 60 },
    corn        = { type = 'ingredient', calories = 96 },

    coffee_beans = { type = 'ingredient', calories = 0 },

    --=================================================
    -- PREPARED ITEMS
    --=================================================
    cutted_meat        = { type = 'prepared', calories = 120 },
    cutted_fish        = { type = 'prepared', calories = 110 },
    cutted_onion       = { type = 'prepared', calories = 40 },
    cutted_carrot      = { type = 'prepared', calories = 35 },
    cutted_lettuce     = { type = 'prepared', calories = 15 },
    cutted_cucumber    = { type = 'prepared', calories = 16 },
    cutted_potato      = { type = 'prepared', calories = 77 },
    cutted_tomato      = { type = 'prepared', calories = 18 },

    flour              = { type = 'prepared', calories = 364 },

    cutted_strawberry  = { type = 'prepared', calories = 32 },
    cutted_watermelon  = { type = 'prepared', calories = 30 },
    cutted_pineapple   = { type = 'prepared', calories = 50 },
    cutted_apple       = { type = 'prepared', calories = 52 },
    cutted_pear        = { type = 'prepared', calories = 57 },
    cutted_lemon       = { type = 'prepared', calories = 29 },
    cutted_banana      = { type = 'prepared', calories = 89 },
    cutted_orange      = { type = 'prepared', calories = 47 },
    cutted_peach       = { type = 'prepared', calories = 39 },
    cutted_mango       = { type = 'prepared', calories = 60 },

    --=================================================
    -- DRINKS
    --=================================================
    cola        = { type = 'drink', calories = 150 },
    sprite      = { type = 'drink', calories = 140 },
    water       = { type = 'drink', calories = 0 },
    coffee      = {
        type = 'drink',
        calories = 5,
        buffs = {
            stamina = 10
        }
    },

    --=================================================
    -- FINISHED PRODUCTS (EINDPRODUCTEN)
    --=================================================
    burger = {
        type = 'finished',
        calories = 350,
        buffs = {
            stress = -5
        }
    },

    cheeseburger = {
        type = 'finished',
        calories = 420,
        buffs = {
            stress = -8
        }
    },

    fries = {
        type = 'finished',
        calories = 300
    },

    salad = {
        type = 'finished',
        calories = 180
    }
}

--=====================================================
-- HELPER FUNCTIONS (SERVER & CLIENT SAFE)
--=====================================================

---Check of item bestaat
---@param item string
---@return boolean
function ItemExists(item)
    return Items[item] ~= nil
end

---Geeft item data terug
---@param item string
---@return table|nil
function GetItemData(item)
    return Items[item]
end

---Check item type
---@param item string
---@param itemType string
---@return boolean
function IsItemType(item, itemType)
    return Items[item] and Items[item].type == itemType
end

---Check of item verkocht mag worden in offline shop
---@param item string
---@return boolean
function IsSellableItem(item)
    return Items[item] and Items[item].type == 'finished'
end

---Geeft calorieën terug (fail-safe)
---@param item string
---@return number
function GetItemCalories(item)
    return Items[item] and Items[item].calories or 0
end

---Geeft buffs terug (lege table als geen)
---@param item string
---@return table
function GetItemBuffs(item)
    return Items[item] and Items[item].buffs or {}
end
