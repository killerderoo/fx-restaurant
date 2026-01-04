--=====================================================
-- FX-RESTAURANT | BURGERSHOT CONFIG
--=====================================================
-- Voorbeeld van een tweede restaurant
-- Kopieer deze template voor nieuwe restaurants
--=====================================================

Restaurant = {
    id = 'burgershot',
    label = 'BurgerShot',
    job = 'burgershot', -- Framework job name (ESX/QBCore)
    
    -- Blip op map
    blip = {
        enabled = true,
        coords = vector3(-1196.22, -894.45, 13.99),
        sprite = 106,
        color = 5,
        scale = 0.8,
        label = 'BurgerShot'
    },
    
    enabled = true,
    
    --=================================================
    -- LIMIETEN
    --=================================================
    limits = {
        maxRecipes = 30,        -- Max recepten
        maxIngredients = 8,     -- Max ingrediënten per recept
        maxPrice = 750,         -- Max prijs per recept
        maxOfflineStock = 100   -- Max stock per item in offline shop
    },
    
    --=================================================
    -- FEATURES (Aan/Uit per restaurant)
    --=================================================
    features = {
        delivery = true,
        driveThrough = true,
        offlineShop = true,
        music = true,
        flyer = true,
        bossmenu = true,
        serving_trays = true
    },
    
    --=================================================
    -- ZONES (Alle interactie punten)
    --=================================================
    zones = {
        -- Boss Menu
        boss_menu = {
            coords = vector3(-1193.95, -895.85, 13.99),
            size = vector3(1.0, 1.0, 2.0),
            heading = 35.0,
            minZ = 12.99,
            maxZ = 14.99,
            distance = 2.0,
            label = 'Boss Menu',
            icon = 'fa-solid fa-briefcase',
            requiredGrade = 3 -- Minimum grade
        },
        
        -- Ingredient Shop NPC
        ingredient_shop = {
            coords = vector4(-1196.22, -894.45, 13.99, 124.0),
            npc = {
                model = 's_m_m_postal_01',
                scenario = 'WORLD_HUMAN_CLIPBOARD'
            },
            label = 'Inkopen',
            icon = 'fa-solid fa-shopping-cart'
        },
        
        -- Kassa's (meerdere mogelijk)
        cashiers = {
            {
                coords = vector3(-1195.24, -892.31, 13.99),
                size = vector3(1.0, 1.0, 2.0),
                heading = 35.0,
                minZ = 12.99,
                maxZ = 14.99,
                distance = 2.0,
                label = 'Kassa',
                icon = 'fa-solid fa-cash-register'
            },
            {
                coords = vector3(-1193.85, -894.09, 13.99),
                size = vector3(1.0, 1.0, 2.0),
                heading = 35.0,
                minZ = 12.99,
                maxZ = 14.99,
                distance = 2.0,
                label = 'Kassa',
                icon = 'fa-solid fa-cash-register'
            }
        },
        
        -- Preparation Station (snijden)
        preparation = {
            coords = vector3(-1200.64, -900.24, 13.99),
            size = vector3(2.0, 1.0, 1.5),
            heading = 35.0,
            minZ = 12.99,
            maxZ = 14.99,
            distance = 2.0,
            label = 'Snijplank',
            icon = 'fa-solid fa-knife'
        },
        
        -- Grill Station
        grill = {
            coords = vector3(-1202.31, -897.54, 13.99),
            size = vector3(2.0, 1.0, 1.5),
            heading = 35.0,
            minZ = 12.99,
            maxZ = 14.99,
            distance = 2.0,
            label = 'Grill',
            icon = 'fa-solid fa-fire-burner'
        },
        
        -- Frituur Station
        fryer = {
            coords = vector3(-1200.98, -898.76, 13.99),
            size = vector3(2.0, 1.0, 1.5),
            heading = 35.0,
            minZ = 12.99,
            maxZ = 14.99,
            distance = 2.0,
            label = 'Frituur',
            icon = 'fa-solid fa-fire'
        },
        
        -- Drinks Station
        drinks = {
            coords = vector3(-1199.23, -896.42, 13.99),
            size = vector3(1.5, 1.0, 1.5),
            heading = 35.0,
            minZ = 12.99,
            maxZ = 14.99,
            distance = 2.0,
            label = 'Dranken',
            icon = 'fa-solid fa-glass-water'
        },
        
        -- Stashes
        stash_fridge = {
            coords = vector3(-1203.12, -896.87, 13.99),
            size = vector3(1.5, 1.0, 2.0),
            heading = 35.0,
            minZ = 12.99,
            maxZ = 14.99,
            distance = 2.0,
            label = 'Koelkast',
            icon = 'fa-solid fa-temperature-arrow-down',
            stashId = 'burgershot_fridge'
        },
        
        stash_freezer = {
            coords = vector3(-1204.45, -898.12, 13.99),
            size = vector3(1.5, 1.0, 2.0),
            heading = 35.0,
            minZ = 12.99,
            maxZ = 14.99,
            distance = 2.0,
            label = 'Vriezer',
            icon = 'fa-solid fa-snowflake',
            stashId = 'burgershot_freezer'
        },
        
        stash_storage = {
            coords = vector3(-1197.34, -902.11, 13.99),
            size = vector3(2.0, 1.5, 2.0),
            heading = 35.0,
            minZ = 12.99,
            maxZ = 14.99,
            distance = 2.0,
            label = 'Opslag',
            icon = 'fa-solid fa-box',
            stashId = 'burgershot_storage'
        },
        
        -- Serving Trays (meerdere)
        trays = {
            {
                coords = vector3(-1194.58, -892.93, 14.10),
                size = vector3(1.0, 0.5, 0.3),
                heading = 35.0,
                minZ = 13.90,
                maxZ = 14.30,
                distance = 2.0,
                label = 'Dienblad',
                icon = 'fa-solid fa-utensils',
                trayId = 1
            },
            {
                coords = vector3(-1193.24, -894.71, 14.10),
                size = vector3(1.0, 0.5, 0.3),
                heading = 35.0,
                minZ = 13.90,
                maxZ = 14.30,
                distance = 2.0,
                label = 'Dienblad',
                icon = 'fa-solid fa-utensils',
                trayId = 2
            }
        },
        
        -- Offline Shop
        offline_shop = {
            coords = vector3(-1196.73, -893.28, 13.99),
            size = vector3(1.5, 1.0, 2.0),
            heading = 35.0,
            minZ = 12.99,
            maxZ = 14.99,
            distance = 2.0,
            label = 'Winkel',
            icon = 'fa-solid fa-store'
        },
        
        -- Flyer Stand
        flyer = {
            coords = vector3(-1190.45, -887.21, 13.99),
            size = vector3(0.5, 0.5, 1.0),
            heading = 35.0,
            minZ = 12.99,
            maxZ = 14.99,
            distance = 2.0,
            label = 'Menu Flyer',
            icon = 'fa-solid fa-file'
        },
        
        -- Music Player
        music = {
            coords = vector3(-1198.34, -895.12, 13.99),
            size = vector3(1.0, 1.0, 1.5),
            heading = 35.0,
            minZ = 12.99,
            maxZ = 14.99,
            distance = 2.0,
            label = 'Muziekspeler',
            icon = 'fa-solid fa-music',
            radius = 30 -- Max geluid radius
        },
        
        -- Drive-Through Speaker
        drivethrough_speaker = {
            coords = vector3(-1182.45, -883.67, 13.77),
            size = vector3(1.5, 1.5, 2.0),
            heading = 125.0,
            minZ = 12.77,
            maxZ = 14.77,
            distance = 3.0,
            label = 'Drive-Through',
            icon = 'fa-solid fa-car',
            notification_coords = vector3(-1195.24, -892.31, 13.99) -- Waar staff notificatie krijgt
        },
        
        -- Drive-Through Pickup
        drivethrough_pickup = {
            coords = vector3(-1188.32, -888.45, 13.85),
            size = vector3(2.0, 2.0, 2.0),
            heading = 35.0,
            minZ = 12.85,
            maxZ = 14.85,
            distance = 3.0,
            label = 'Ophalen',
            icon = 'fa-solid fa-hand-holding'
        }
    },
    
    --=================================================
    -- STASH CONFIGURATIE
    --=================================================
    stashes = {
        fridge = {
            slots = 50,
            weight = 100000,
            label = 'BurgerShot Koelkast'
        },
        freezer = {
            slots = 50,
            weight = 100000,
            label = 'BurgerShot Vriezer'
        },
        storage = {
            slots = 100,
            weight = 200000,
            label = 'BurgerShot Opslag'
        },
        box = {
            slots = 10,
            weight = 50000,
            label = 'Bezorgdoos'
        }
    },
    
    --=================================================
    -- DELIVERY CONFIGURATIE
    --=================================================
    delivery = {
        enabled = true,
        cooldown = 600, -- 10 minuten tussen deliveries
        
        -- Payment range
        payment = {
            min = 150,
            max = 400
        },
        
        -- Welke items kunnen besteld worden voor delivery
        available_items = {
            'burger',
            'cheeseburger',
            'fries',
            'cola',
            'sprite'
        },
        
        -- Vehicle spawn voor deliveries
        vehicle_spawn = {
            coords = vector4(-1180.23, -884.12, 13.77, 305.0),
            model = 'faggio' -- Scooter
        }
    },
    
    --=================================================
    -- DRIVE-THROUGH CONFIGURATIE
    --=================================================
    drivethrough = {
        enabled = true,
        
        -- Notification settings
        notification = {
            sound = true,
            duration = 30000 -- 30 seconden
        },
        
        -- Private voice channel radius
        voice_radius = 10.0
    },
    
    --=================================================
    -- MUSIC CONFIGURATIE
    --=================================================
    music = {
        enabled = true,
        maxVolume = 100,
        maxRadius = 50,
        cooldown = 60 -- 1 minuut tussen songs
    }
}

--=====================================================
-- PERMISSIONS (Grade based)
--=====================================================

Restaurant.permissions = {
    boss_menu = 3,          -- Grade 3+ voor boss menu
    manage_recipes = 2,     -- Grade 2+ voor recipes beheren
    manage_shop = 3,        -- Grade 3+ voor shop beheren
    use_stations = 0,       -- Grade 0+ (iedereen) kan stations gebruiken
    cashier = 1,            -- Grade 1+ voor kassa
    delivery = 0,           -- Grade 0+ voor deliveries
    music = 1               -- Grade 1+ voor muziek
}
