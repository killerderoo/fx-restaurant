--=====================================================
-- FX-RESTAURANT | MAIN CONFIG
--=====================================================

Config = {}

-- Framework: 'auto', 'esx', 'qb', 'standalone'
Config.Framework = 'auto'

-- Inventory: 'auto', 'ox', 'qb', 'qs'
Config.Inventory = 'auto'

-- Target: 'auto', 'ox', 'qb', 'interact', 'none'
Config.Target = 'auto'

-- Debug mode (extra console logs)
Config.Debug = false

--=====================================================
-- NOTIFICATIONS
--=====================================================

---Send notification to player
---@param src number Player source
---@param data table Notification data
RegisterNetEvent('fx-restaurant:notify', function(data)
    if IsDuplicityVersion() then
        -- Server side
        TriggerClientEvent('fx-restaurant:notify', source, data)
    else
        -- Client side
        lib.notify(data)
    end
end)
