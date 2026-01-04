-- Default Restaurant Example Configuration
-- Copy this file and modify it to create new restaurants

Restaurants = Restaurants or {}

Restaurants['burgershot'] = {
    -- Basic Information
    name = "Burger Shot",
    label = "Burger Shot Restaurant",

    -- Blip Settings
    blip = {
        enabled = true,
        coords = vector3(-1196.0, -894.0, 14.0),
        sprite = 52,
        color = 47,
        scale = 0.8
    },

    -- Job Requirement (set to nil for no job requirement)
    job = 'burgershot', -- Only players with this job can access boss menu and stations

    -- Feature Toggles
    features = {
        bossmenu = true,
        recipes = true,
        preparation = true,
        cooking = true,
        cashier = true,
        delivery = true,
        drivethrough = true,
        offlineshop = true,
        music = true,
        stashes = true,
        props = true
    },

    -- Limits
    maxRecipes = 30,
    maxIngredientsPerRecipe = 8,
    maxRecipePrice = 500,

    -- Boss Menu Location
    bossmenu = {
        coords = vector3(-1199.5, -897.5, 14.0),
        heading = 0.0,
        distance = 2.0,
        jobGrade = 3 -- Minimum grade to access boss menu
    },

    -- Preparation Stations
    preparation = {
        {
            type = 'cutting', -- Type of preparation
            label = 'Cutting Board',
            coords = vector3(-1201.0, -897.0, 14.0),
            heading = 123.0,
            distance = 1.5,
            animation = {
                dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
                anim = 'machinic_loop_mechandplayer',
                flag = 16
            },
            -- What can be prepared here
            recipes = {
                {input = 'meat', output = 'cutted_meat', amount = 1, time = 5000},
                {input = 'fish', output = 'cutted_fish', amount = 1, time = 5000},
                {input = 'onion', output = 'cutted_onion', amount = 1, time = 3000},
                {input = 'carrot', output = 'cutted_carrot', amount = 1, time = 3000},
                {input = 'lettuce', output = 'cutted_lettuce', amount = 1, time = 3000},
                {input = 'cucumber', output = 'cutted_cucumber', amount = 1, time = 3000},
                {input = 'potato', output = 'cutted_potato', amount = 1, time = 3000},
                {input = 'tomato', output = 'cutted_tomato', amount = 1, time = 3000},
                {input = 'strawberry', output = 'cutted_strawberry', amount = 1, time = 3000},
                {input = 'watermelon', output = 'cutted_watermelon', amount = 1, time = 4000},
                {input = 'soya', output = 'cutted_tofu', amount = 1, time = 5000},
                {input = 'pineapple', output = 'cutted_pineapple', amount = 1, time = 4000},
                {input = 'apple', output = 'cutted_apple', amount = 1, time = 3000},
                {input = 'pear', output = 'cutted_pear', amount = 1, time = 3000},
                {input = 'lemon', output = 'cutted_lemon', amount = 1, time = 3000},
                {input = 'banana', output = 'cutted_banana', amount = 1, time = 3000},
                {input = 'orange', output = 'cutted_orange', amount = 1, time = 3000},
                {input = 'peach', output = 'cutted_peach', amount = 1, time = 3000},
                {input = 'mango', output = 'cutted_mango', amount = 1, time = 3000},
                {input = 'wheat', output = 'flour', amount = 1, time = 5000}
            }
        }
    },

    -- Cooking/Grill Stations
    cooking = {
        {
            type = 'grill',
            label = 'Grill Station',
            coords = vector3(-1202.0, -897.0, 14.0),
            heading = 123.0,
            distance = 1.5,
            animation = {
                dict = 'amb@prop_human_bbq@male@base',
                anim = 'base',
                flag = 16
            }
            -- Recipes are loaded from database
        },
        {
            type = 'fryer',
            label = 'Deep Fryer',
            coords = vector3(-1203.0, -897.0, 14.0),
            heading = 123.0,
            distance = 1.5,
            animation = {
                dict = 'amb@prop_human_bbq@male@base',
                anim = 'base',
                flag = 16
            }
        }
    },

    -- Storage/Stash Locations
    stashes = {
        {
            id = 'burgershot_fridge',
            label = 'Restaurant Fridge',
            coords = vector3(-1203.5, -896.0, 14.0),
            distance = 2.0,
            slots = 50,
            weight = 100000
        },
        {
            id = 'burgershot_freezer',
            label = 'Restaurant Freezer',
            coords = vector3(-1204.0, -896.0, 14.0),
            distance = 2.0,
            slots = 50,
            weight = 100000
        },
        {
            id = 'burgershot_storage',
            label = 'Delivery Box Storage',
            coords = vector3(-1204.5, -896.0, 14.0),
            distance = 2.0,
            slots = 30,
            weight = 50000
        }
    },

    -- Cashier/Register Locations
    cashiers = {
        {
            coords = vector3(-1196.0, -892.0, 14.0),
            heading = 213.0,
            distance = 2.0
        },
        {
            coords = vector3(-1195.0, -893.0, 14.0),
            heading = 213.0,
            distance = 2.0
        }
    },

    -- Tray Locations (for customer orders)
    trays = {
        {
            coords = vector3(-1195.0, -892.0, 14.0),
            distance = 1.5,
            slots = 10,
            weight = 10000
        }
    },

    -- Menu Flyer Location
    flyer = {
        coords = vector3(-1197.0, -893.0, 14.0),
        distance = 1.5,
        item = 'burgershot_menu'
    },

    -- Drive Through
    drivethrough = {
        enabled = true,
        trigger = vector3(-1180.0, -890.0, 14.0),
        radius = 5.0,
        speaker = vector3(-1183.0, -892.0, 14.0),
        window = vector3(-1194.0, -893.0, 14.0)
    },

    -- Offline Shop
    offlineshop = {
        enabled = true,
        coords = vector3(-1198.0, -893.0, 14.0),
        distance = 2.0,
        label = 'Burger Shot Shop',
        -- Items are managed via boss menu
        items = {}
    },

    -- Music Player
    music = {
        coords = vector3(-1200.0, -895.0, 14.0),
        distance = 2.0,
        radius = 30.0,
        jobGrade = 1 -- Minimum grade to control music
    },

    -- Delivery System
    delivery = {
        enabled = true,
        start = vector3(-1199.0, -894.0, 14.0),
        distance = 2.0,
        cooldown = 300, -- seconds
        -- Random delivery locations
        locations = {
            {coords = vector3(134.0, -1061.0, 29.0), label = 'Grove Street'},
            {coords = vector3(-68.0, -1822.0, 26.0), label = 'Davis Avenue'},
            {coords = vector3(421.0, -1510.0, 29.0), label = 'Strawberry Ave'},
            {coords = vector3(-1158.0, -1424.0, 4.0), label = 'Vespucci Beach'},
            {coords = vector3(-1486.0, -379.0, 40.0), label = 'Morningwood'},
            {coords = vector3(-626.0, -236.0, 38.0), label = 'Rockford Hills'},
            {coords = vector3(101.0, -1912.0, 21.0), label = 'Davis'},
            {coords = vector3(1138.0, -982.0, 46.0), label = 'Mirror Park'}
        }
    },

    -- Ingredient Shop NPC
    ingredientshop = {
        enabled = true,
        coords = vector3(-1205.0, -895.0, 14.0),
        heading = 35.0,
        model = 's_m_m_linecook',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        items = {
            -- Main Ingredients
            {item = 'meat', price = 10, label = 'Raw Meat'},
            {item = 'fish', price = 12, label = 'Raw Fish'},
            {item = 'onion', price = 3, label = 'Onion'},
            {item = 'carrot', price = 3, label = 'Carrot'},
            {item = 'lettuce', price = 3, label = 'Lettuce'},
            {item = 'cucumber', price = 3, label = 'Cucumber'},
            {item = 'potato', price = 3, label = 'Potato'},
            {item = 'tomato', price = 3, label = 'Tomato'},
            {item = 'wheat', price = 5, label = 'Wheat'},
            {item = 'strawberry', price = 4, label = 'Strawberry'},
            {item = 'watermelon', price = 6, label = 'Watermelon'},
            {item = 'soya', price = 5, label = 'Soya Beans'},
            {item = 'pineapple', price = 5, label = 'Pineapple'},
            {item = 'apple', price = 3, label = 'Apple'},
            {item = 'pear', price = 3, label = 'Pear'},
            {item = 'lemon', price = 3, label = 'Lemon'},
            {item = 'banana', price = 3, label = 'Banana'},
            {item = 'orange', price = 3, label = 'Orange'},
            {item = 'peach', price = 4, label = 'Peach'},
            {item = 'mango', price = 5, label = 'Mango'},
            {item = 'corn', price = 4, label = 'Corn'},
            {item = 'coffee_beans', price = 8, label = 'Coffee Beans'},
            -- Drinks
            {item = 'cola_soda', price = 5, label = 'Cola Soda'},
            {item = 'sprite_soda', price = 5, label = 'Sprite Soda'},
            {item = 'water_bottle', price = 3, label = 'Water Bottle'},
            {item = 'orange_juice', price = 6, label = 'Orange Juice'},
            {item = 'apple_juice', price = 6, label = 'Apple Juice'}
        }
    },

    -- Props to Spawn
    props = {
        -- Example props
        -- {model = 'prop_table_01', coords = vector3(-1200.0, -900.0, 14.0), heading = 0.0}
    },

    -- Restaurant Zone (for entering/leaving)
    zone = {
        points = {
            vector3(-1210.0, -905.0, 14.0),
            vector3(-1210.0, -885.0, 14.0),
            vector3(-1190.0, -885.0, 14.0),
            vector3(-1190.0, -905.0, 14.0)
        },
        thickness = 10.0
    }
}
