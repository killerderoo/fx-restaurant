--=====================================================
-- FX-RESTAURANT | INGREDIENT SHOP CONFIG
--=====================================================
-- Alle ingrediënten die in de shop verkocht worden
-- met hun prijzen en categorieën
--=====================================================

Config.IngredientShop = {
    -- Shop blip
    blip = {
        enabled = true,
        sprite = 52,
        color = 2,
        scale = 0.7,
        label = 'Restaurant Supplies'
    },
    
    -- NPC Model
    npc = {
        model = 's_m_m_postal_01',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        freeze = true,
        invincible = true,
        blockevents = true
    },
    
    -- Shop Categories & Items
    categories = {
        --=================================================
        -- MAIN INGREDIENTS
        --=================================================
        {
            label = 'Vlees & Vis',
            icon = 'fa-solid fa-drumstick-bite',
            items = {
                { item = 'meat', label = 'Vlees', price = 15 },
                { item = 'fish', label = 'Vis', price = 18 }
            }
        },
        
        {
            label = 'Groenten',
            icon = 'fa-solid fa-carrot',
            items = {
                { item = 'onion', label = 'Ui', price = 3 },
                { item = 'carrot', label = 'Wortel', price = 3 },
                { item = 'lettuce', label = 'Sla', price = 4 },
                { item = 'cucumber', label = 'Komkommer', price = 4 },
                { item = 'potato', label = 'Aardappel', price = 2 },
                { item = 'tomato', label = 'Tomaat', price = 3 },
                { item = 'corn', label = 'Maïs', price = 4 }
            }
        },
        
        {
            label = 'Fruit',
            icon = 'fa-solid fa-apple-whole',
            items = {
                { item = 'strawberry', label = 'Aardbei', price = 5 },
                { item = 'watermelon', label = 'Watermeloen', price = 8 },
                { item = 'pineapple', label = 'Ananas', price = 10 },
                { item = 'apple', label = 'Appel', price = 3 },
                { item = 'pear', label = 'Peer', price = 3 },
                { item = 'lemon', label = 'Citroen', price = 2 },
                { item = 'banana', label = 'Banaan', price = 2 },
                { item = 'orange', label = 'Sinaasappel', price = 3 },
                { item = 'peach', label = 'Perzik', price = 4 },
                { item = 'mango', label = 'Mango', price = 6 }
            }
        },
        
        {
            label = 'Granen & Specerijen',
            icon = 'fa-solid fa-wheat-awn',
            items = {
                { item = 'wheat', label = 'Tarwe', price = 5 },
                { item = 'coffee_beans', label = 'Koffiebonen', price = 8 },
                { item = 'soya', label = 'Sojabonen', price = 6 }
            }
        },
        
        --=================================================
        -- DRINKS (BASIS)
        --=================================================
        {
            label = 'Dranken',
            icon = 'fa-solid fa-bottle-water',
            items = {
                { item = 'water', label = 'Water', price = 2 },
                { item = 'cola', label = 'Cola', price = 5 },
                { item = 'sprite', label = 'Sprite', price = 5 }
            }
        }
    },
    
    -- Locations (kan uitgebreid worden per restaurant)
    locations = {
        {
            restaurant = 'default',
            coords = vector4(-44.42, -1748.35, 29.42, 140.0),
            label = 'Default Restaurant Supplies'
        },
        {
            restaurant = 'burgershot',
            coords = vector4(-1196.22, -894.45, 13.99, 124.0),
            label = 'BurgerShot Supplies'
        }
    }
}

--=====================================================
-- INGREDIENT DISCOUNTS (Bulk Buy)
--=====================================================

Config.IngredientDiscounts = {
    enabled = true,
    
    tiers = {
        { min = 10, max = 24, discount = 5 },   -- 5% korting bij 10-24 items
        { min = 25, max = 49, discount = 10 },  -- 10% korting bij 25-49 items
        { min = 50, max = 99, discount = 15 },  -- 15% korting bij 50-99 items
        { min = 100, discount = 20 }            -- 20% korting bij 100+ items
    }
}

--=====================================================
-- PREPARATION STATION CONFIG
--=====================================================

Config.PreparationStations = {
    -- Snijden
    cutting = {
        label = 'Snijplank',
        icon = 'fa-solid fa-knife',
        animation = {
            dict = 'mini@repair',
            anim = 'fixing_a_player',
            flag = 16
        },
        duration = 5000, -- 5 seconden
        
        -- Wat kan er gesneden worden
        recipes = {
            { input = 'meat', output = 'cutted_meat', amount = 1 },
            { input = 'fish', output = 'cutted_fish', amount = 1 },
            { input = 'onion', output = 'cutted_onion', amount = 1 },
            { input = 'carrot', output = 'cutted_carrot', amount = 1 },
            { input = 'lettuce', output = 'cutted_lettuce', amount = 1 },
            { input = 'cucumber', output = 'cutted_cucumber', amount = 1 },
            { input = 'potato', output = 'cutted_potato', amount = 1 },
            { input = 'tomato', output = 'cutted_tomato', amount = 1 },
            { input = 'strawberry', output = 'cutted_strawberry', amount = 1 },
            { input = 'watermelon', output = 'cutted_watermelon', amount = 1 },
            { input = 'pineapple', output = 'cutted_pineapple', amount = 1 },
            { input = 'apple', output = 'cutted_apple', amount = 1 },
            { input = 'pear', output = 'cutted_pear', amount = 1 },
            { input = 'lemon', output = 'cutted_lemon', amount = 1 },
            { input = 'banana', output = 'cutted_banana', amount = 1 },
            { input = 'orange', output = 'cutted_orange', amount = 1 },
            { input = 'peach', output = 'cutted_peach', amount = 1 },
            { input = 'mango', output = 'cutted_mango', amount = 1 }
        }
    },
    
    -- Malen
    grinding = {
        label = 'Molen',
        icon = 'fa-solid fa-mortar-pestle',
        animation = {
            dict = 'mini@repair',
            anim = 'fixing_a_player',
            flag = 16
        },
        duration = 7000, -- 7 seconden
        
        recipes = {
            { input = 'wheat', output = 'flour', amount = 2 },
            { input = 'coffee_beans', output = 'ground_coffee', amount = 1 }
        }
    },
    
    -- Blenden (voor smoothies, sauzen)
    blending = {
        label = 'Blender',
        icon = 'fa-solid fa-blender',
        animation = {
            dict = 'mini@repair',
            anim = 'fixing_a_player',
            flag = 16
        },
        duration = 6000, -- 6 seconden
        
        recipes = {
            { input = 'cutted_strawberry', output = 'strawberry_puree', amount = 1 },
            { input = 'cutted_mango', output = 'mango_puree', amount = 1 }
        }
    }
}

--=====================================================
-- COOKING STATIONS CONFIG
--=====================================================

Config.CookingStations = {
    -- Grill
    grill = {
        label = 'Grill',
        icon = 'fa-solid fa-fire-burner',
        animation = {
            dict = 'amb@prop_human_bbq@male@base',
            anim = 'base',
            flag = 16
        },
        prop = {
            model = 'prop_fish_slice_01',
            bone = 28422,
            offset = vector3(0.0, 0.0, 0.0),
            rotation = vector3(0.0, 0.0, 0.0)
        },
        duration = 10000 -- 10 seconden
    },
    
    -- Frituur
    fryer = {
        label = 'Frituur',
        icon = 'fa-solid fa-fire',
        animation = {
            dict = 'mini@repair',
            anim = 'fixing_a_player',
            flag = 16
        },
        duration = 8000 -- 8 seconden
    },
    
    -- Oven
    oven = {
        label = 'Oven',
        icon = 'fa-solid fa-oven',
        animation = {
            dict = 'mini@repair',
            anim = 'fixing_a_player',
            flag = 16
        },
        duration = 12000 -- 12 seconden
    },
    
    -- Drinks Station
    drinks = {
        label = 'Drankstation',
        icon = 'fa-solid fa-glass-water',
        animation = {
            dict = 'mp_ped_interaction',
            anim = 'handshake_guy_a',
            flag = 16
        },
        duration = 4000 -- 4 seconden
    }
}
