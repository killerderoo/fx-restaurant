Config = {}

-- Framework Detection
Config.Framework = 'qb-core' -- 'qb-core' or 'esx'

-- Inventory System
Config.Inventory = 'ox_inventory' -- 'ox_inventory' or 'qb-inventory'

-- Target System
Config.Target = 'ox_target' -- 'ox_target', 'qb-target', or 'interact'

-- General Settings
Config.CalorieSystem = true -- Enable calorie system (100 calories = 10% hunger/thirst)
Config.CaloriesPerPercent = 10 -- Calories needed per 1% hunger/thirst

-- Global Limits (can be overridden per restaurant)
Config.MaxIngredientsPerRecipe = 10
Config.MaxRecipesPerRestaurant = 50
Config.MaxRecipePrice = 1000

-- Delivery System
Config.DeliveryEnabled = true
Config.DeliveryCooldown = 300 -- seconds (5 minutes)
Config.DeliveryPay = {min = 50, max = 150}
Config.DeliveryRadius = 500.0

-- Drive Through
Config.DriveThruNotificationDistance = 10.0

-- Music System
Config.MusicEnabled = true
Config.MaxMusicVolume = 100
Config.MaxMusicRadius = 50.0

-- Default Restaurant Box Item
Config.RestaurantBoxItem = 'restaurant_box'

-- Debug Mode
Config.Debug = false

-- Blips
Config.ShowRestaurantBlips = true
Config.BlipSprite = 52
Config.BlipColor = 2
Config.BlipScale = 0.8

-- Notification Function
function Notify(source, message, type, duration)
    if IsDuplicityVersion() then -- Server
        TriggerClientEvent('ox_lib:notify', source, {
            description = message,
            type = type or 'info',
            duration = duration or 5000
        })
    else -- Client
        lib.notify({
            description = message,
            type = type or 'info',
            duration = duration or 5000
        })
    end
end
