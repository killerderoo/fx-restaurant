--=====================================================
-- FX-RESTAURANT | DELIVERY LOCATIONS
--=====================================================
-- Random delivery locaties voor het delivery system
--=====================================================

Config.DeliveryLocations = {
    --=================================================
    -- VINEWOOD AREA
    --=================================================
    {
        name = 'Vinewood Villa',
        coords = vector3(1346.98, 545.62, 89.77),
        area = 'Vinewood Hills',
        difficulty = 'easy'
    },
    {
        name = 'Vinewood Mansion',
        coords = vector3(-1294.74, 454.68, 97.08),
        area = 'Vinewood Hills',
        difficulty = 'medium'
    },
    {
        name = 'Vinewood House',
        coords = vector3(106.14, 563.21, 183.96),
        area = 'Vinewood Hills',
        difficulty = 'hard'
    },
    
    --=================================================
    -- ROCKFORD HILLS
    --=================================================
    {
        name = 'Rockford Hills Estate',
        coords = vector3(-897.34, -433.64, 39.60),
        area = 'Rockford Hills',
        difficulty = 'easy'
    },
    {
        name = 'Rockford Penthouse',
        coords = vector3(-795.03, -217.21, 37.08),
        area = 'Rockford Hills',
        difficulty = 'medium'
    },
    
    --=================================================
    -- WEST VINEWOOD
    --=================================================
    {
        name = 'West Vinewood Apartment',
        coords = vector3(-507.87, 427.35, 97.42),
        area = 'West Vinewood',
        difficulty = 'easy'
    },
    {
        name = 'West Vinewood House',
        coords = vector3(-762.24, 319.73, 85.66),
        area = 'West Vinewood',
        difficulty = 'medium'
    },
    
    --=================================================
    -- DEL PERRO
    --=================================================
    {
        name = 'Del Perro Apartment',
        coords = vector3(-1451.70, -519.55, 56.93),
        area = 'Del Perro',
        difficulty = 'easy'
    },
    {
        name = 'Del Perro Beach House',
        coords = vector3(-1915.82, -573.53, 11.44),
        area = 'Del Perro',
        difficulty = 'medium'
    },
    
    --=================================================
    -- VESPUCCI
    --=================================================
    {
        name = 'Vespucci Beach House',
        coords = vector3(-1083.82, -1637.93, 4.40),
        area = 'Vespucci',
        difficulty = 'easy'
    },
    {
        name = 'Vespucci Canals House',
        coords = vector3(-1001.23, -1476.43, 5.11),
        area = 'Vespucci',
        difficulty = 'medium'
    },
    
    --=================================================
    -- DOWNTOWN
    --=================================================
    {
        name = 'Downtown Office',
        coords = vector3(-71.31, -801.50, 44.23),
        area = 'Downtown',
        difficulty = 'easy'
    },
    {
        name = 'Downtown Apartment',
        coords = vector3(316.84, -229.21, 54.02),
        area = 'Downtown',
        difficulty = 'medium'
    },
    {
        name = 'Alta Street Apartment',
        coords = vector3(-269.04, -957.32, 31.22),
        area = 'Downtown',
        difficulty = 'easy'
    },
    
    --=================================================
    -- MIRROR PARK
    --=================================================
    {
        name = 'Mirror Park House',
        coords = vector3(1230.82, -725.16, 60.96),
        area = 'Mirror Park',
        difficulty = 'medium'
    },
    {
        name = 'Mirror Park Villa',
        coords = vector3(1109.30, -335.39, 66.95),
        area = 'Mirror Park',
        difficulty = 'medium'
    },
    
    --=================================================
    -- EAST LOS SANTOS
    --=================================================
    {
        name = 'East LS House',
        coords = vector3(492.09, -1321.23, 29.23),
        area = 'East Los Santos',
        difficulty = 'easy'
    },
    {
        name = 'Grove Street House',
        coords = vector3(29.57, -1854.40, 23.73),
        area = 'Grove Street',
        difficulty = 'easy'
    },
    {
        name = 'Strawberry House',
        coords = vector3(323.01, -1937.01, 24.89),
        area = 'Strawberry',
        difficulty = 'easy'
    },
    
    --=================================================
    -- RICHMAN
    --=================================================
    {
        name = 'Richman Mansion',
        coords = vector3(-1579.99, 35.28, 59.55),
        area = 'Richman',
        difficulty = 'hard'
    },
    {
        name = 'Richman Villa',
        coords = vector3(-1405.34, -98.97, 52.38),
        area = 'Richman',
        difficulty = 'hard'
    },
    
    --=================================================
    -- PACIFIC BLUFFS
    --=================================================
    {
        name = 'Pacific Bluffs House',
        coords = vector3(-2975.92, 372.73, 14.77),
        area = 'Pacific Bluffs',
        difficulty = 'hard'
    },
    {
        name = 'Chumash Beach House',
        coords = vector3(-3213.51, 826.79, 8.93),
        area = 'Chumash',
        difficulty = 'hard'
    },
    
    --=================================================
    -- PALETO BAY
    --=================================================
    {
        name = 'Paleto Bay House',
        coords = vector3(-363.31, 6334.49, 29.85),
        area = 'Paleto Bay',
        difficulty = 'hard'
    },
    {
        name = 'Paleto Bay Cabin',
        coords = vector3(9.83, 6578.99, 32.33),
        area = 'Paleto Bay',
        difficulty = 'hard'
    },
    
    --=================================================
    -- SANDY SHORES
    --=================================================
    {
        name = 'Sandy Shores Trailer',
        coords = vector3(1985.20, 3812.42, 32.18),
        area = 'Sandy Shores',
        difficulty = 'medium'
    },
    {
        name = 'Sandy Shores House',
        coords = vector3(1662.60, 4776.06, 42.01),
        area = 'Sandy Shores',
        difficulty = 'medium'
    }
}

--=====================================================
-- DELIVERY REWARDS BASED ON DIFFICULTY
--=====================================================

Config.DeliveryRewards = {
    easy = {
        min = 100,
        max = 200,
        experience = 10
    },
    medium = {
        min = 200,
        max = 350,
        experience = 20
    },
    hard = {
        min = 350,
        max = 500,
        experience = 35
    }
}

--=====================================================
-- DELIVERY NPC MESSAGES
--=====================================================

Config.DeliveryMessages = {
    greetings = {
        'Hallo! Bedankt voor het bezorgen!',
        'Eindelijk! Ik sterf van de honger!',
        'Perfect timing, dank je wel!',
        'Wat ruikt dat lekker!',
        'Geweldig, de bestelling is er!'
    },
    
    tips = {
        'Hier is een kleine tip voor je!',
        'Dit is voor de snelle service!',
        'Heel erg bedankt!',
        'Geweldige service!'
    },
    
    complaints = {
        'Het duurde wel erg lang...',
        'Hopelijk is het nog warm.',
        'Je bent wat laat.',
        'Volgende keer sneller graag.'
    }
}

--=====================================================
-- RANDOM ORDER GENERATOR CONFIG
--=====================================================

Config.RandomOrders = {
    -- Min/Max aantal items per order
    minItems = 1,
    maxItems = 5,
    
    -- Mogelijke items voor random orders
    -- Deze komen uit de restaurant recipes
    items = {
        'burger',
        'cheeseburger',
        'fries',
        'salad',
        'cola',
        'sprite',
        'water',
        'coffee'
    },
    
    -- Tips
    tipChance = 0.7, -- 70% kans op tip
    tipMin = 10,
    tipMax = 50
}
