--=====================================================
-- FX-RESTAURANT | BRIDGES
-- Framework / Inventory / Target abstraction layer
--=====================================================

Bridge = {
    Framework = nil,
    Inventory = nil,
    Target = nil
}

--=====================================================
-- UTILS
--=====================================================

local function ResourceStarted(name)
    return GetResourceState(name) == 'started'
end

--=====================================================
-- FRAMEWORK DETECTION
--=====================================================

CreateThread(function()
    -- AUTO DETECT FRAMEWORK
    if Config.Framework == 'auto' then
        if ResourceStarted('es_extended') then
            Config.Framework = 'esx'
        elseif ResourceStarted('qb-core') then
            Config.Framework = 'qb'
        else
            Config.Framework = 'standalone'
        end
    end

    -- ESX
    if Config.Framework == 'esx' then
        ESX = exports['es_extended']:getSharedObject()

        Bridge.Framework = {
            GetPlayer = function(src)
                return ESX.GetPlayerFromId(src)
            end,

            GetIdentifier = function(src)
                local xPlayer = ESX.GetPlayerFromId(src)
                return xPlayer and xPlayer.identifier
            end,

            HasJob = function(src, job)
                local xPlayer = ESX.GetPlayerFromId(src)
                return xPlayer and xPlayer.job.name == job
            end,

            AddMoney = function(src, account, amount)
                local xPlayer = ESX.GetPlayerFromId(src)
                if xPlayer then
                    xPlayer.addAccountMoney(account, amount)
                end
            end,

            RemoveMoney = function(src, account, amount)
                local xPlayer = ESX.GetPlayerFromId(src)
                if xPlayer then
                    xPlayer.removeAccountMoney(account, amount)
                end
            end
        }
    end

    -- QBCORE
    if Config.Framework == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()

        Bridge.Framework = {
            GetPlayer = function(src)
                return QBCore.Functions.GetPlayer(src)
            end,

            GetIdentifier = function(src)
                local Player = QBCore.Functions.GetPlayer(src)
                return Player and Player.PlayerData.citizenid
            end,

            HasJob = function(src, job)
                local Player = QBCore.Functions.GetPlayer(src)
                return Player and Player.PlayerData.job.name == job
            end,

            AddMoney = function(src, account, amount)
                local Player = QBCore.Functions.GetPlayer(src)
                if Player then
                    Player.Functions.AddMoney(account, amount)
                end
            end,

            RemoveMoney = function(src, account, amount)
                local Player = QBCore.Functions.GetPlayer(src)
                if Player then
                    Player.Functions.RemoveMoney(account, amount)
                end
            end
        }
    end

    -- STANDALONE
    if Config.Framework == 'standalone' then
        Bridge.Framework = {
            GetPlayer = function(src) return src end,
            GetIdentifier = function(src) return tostring(src) end,
            HasJob = function() return true end,
            AddMoney = function() end,
            RemoveMoney = function() end
        }
    end
end)

--=====================================================
-- INVENTORY DETECTION
--=====================================================

CreateThread(function()
    if Config.Inventory == 'auto' then
        if ResourceStarted('ox_inventory') then
            Config.Inventory = 'ox'
        elseif ResourceStarted('qb-inventory') then
            Config.Inventory = 'qb'
        else
            Config.Inventory = 'none'
        end
    end

    -- OX INVENTORY
    if Config.Inventory == 'ox' then
        Bridge.Inventory = {
            AddItem = function(src, item, amount, metadata)
                return exports.ox_inventory:AddItem(src, item, amount, metadata)
            end,

            RemoveItem = function(src, item, amount)
                return exports.ox_inventory:RemoveItem(src, item, amount)
            end,

            HasItem = function(src, item, amount)
                return exports.ox_inventory:Search(src, 'count', item) >= (amount or 1)
            end,

            GetItemCount = function(src, item)
                return exports.ox_inventory:Search(src, 'count', item)
            end
        }
    end

    -- QB INVENTORY
    if Config.Inventory == 'qb' then
        Bridge.Inventory = {
            AddItem = function(src, item, amount, metadata)
                return exports['qb-inventory']:AddItem(src, item, amount, false, metadata)
            end,

            RemoveItem = function(src, item, amount)
                return exports['qb-inventory']:RemoveItem(src, item, amount)
            end,

            HasItem = function(src, item, amount)
                local Player = QBCore.Functions.GetPlayer(src)
                local count = Player.Functions.GetItemByName(item)
                return count and count.amount >= (amount or 1)
            end,

            GetItemCount = function(src, item)
                local Player = QBCore.Functions.GetPlayer(src)
                local data = Player.Functions.GetItemByName(item)
                return data and data.amount or 0
            end
        }
    end
end)

--=====================================================
-- TARGET DETECTION
--=====================================================

CreateThread(function()
    if Config.Target == 'auto' then
        if ResourceStarted('ox_target') then
            Config.Target = 'ox'
        elseif ResourceStarted('qb-target') then
            Config.Target = 'qb'
        elseif ResourceStarted('interact') then
            Config.Target = 'interact'
        else
            Config.Target = 'none'
        end
    end

    -- OX TARGET
    if Config.Target == 'ox' then
        Bridge.Target = {
            AddBoxZone = function(data)
                exports.ox_target:addBoxZone(data)
            end
        }
    end

    -- QB TARGET
    if Config.Target == 'qb' then
        Bridge.Target = {
            AddBoxZone = function(data)
                exports['qb-target']:AddBoxZone(
                    data.name,
                    data.coords,
                    data.size.x,
                    data.size.y,
                    {
                        name = data.name,
                        heading = data.heading,
                        minZ = data.minZ,
                        maxZ = data.maxZ
                    },
                    {
                        options = data.options,
                        distance = data.distance or 2.0
                    }
                )
            end
        }
    end

    -- INTERACT
    if Config.Target == 'interact' then
        Bridge.Target = {
            AddBoxZone = function(data)
                exports.interact:AddBoxZone(data)
            end
        }
    end
end)

--=====================================================
-- EXPORT
--=====================================================

exports('GetBridge', function()
    return Bridge
end)
