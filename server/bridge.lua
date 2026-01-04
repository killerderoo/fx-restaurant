--=====================================================
-- FX-RESTAURANT | SERVER BRIDGE
-- Framework / Inventory abstraction layer (SERVER)
--=====================================================

local Bridge = {
    Framework = nil,
    Inventory = nil
}

--=====================================================
-- UTILS
--=====================================================

local function ResourceStarted(name)
    return GetResourceState(name) == 'started'
end

--=====================================================
-- FRAMEWORK DETECTION & SETUP
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

    print(('^2[FX-RESTAURANT] Framework: %s^0'):format(Config.Framework))

    --=================================================
    -- ESX FRAMEWORK
    --=================================================
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
            
            HasJobGrade = function(src, job, minGrade)
                local xPlayer = ESX.GetPlayerFromId(src)
                if not xPlayer or xPlayer.job.name ~= job then
                    return false
                end
                return xPlayer.job.grade >= minGrade
            end,

            AddMoney = function(src, account, amount)
                local xPlayer = ESX.GetPlayerFromId(src)
                if xPlayer then
                    xPlayer.addAccountMoney(account, amount)
                    return true
                end
                return false
            end,

            RemoveMoney = function(src, account, amount)
                local xPlayer = ESX.GetPlayerFromId(src)
                if xPlayer then
                    xPlayer.removeAccountMoney(account, amount)
                    return true
                end
                return false
            end,
            
            GetMoney = function(src, account)
                local xPlayer = ESX.GetPlayerFromId(src)
                if not xPlayer then return 0 end
                
                local acc = xPlayer.getAccount(account)
                return acc and acc.money or 0
            end
        }
    end

    --=================================================
    -- QBCORE FRAMEWORK
    --=================================================
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
            
            HasJobGrade = function(src, job, minGrade)
                local Player = QBCore.Functions.GetPlayer(src)
                if not Player or Player.PlayerData.job.name ~= job then
                    return false
                end
                return Player.PlayerData.job.grade.level >= minGrade
            end,

            AddMoney = function(src, account, amount)
                local Player = QBCore.Functions.GetPlayer(src)
                if Player then
                    Player.Functions.AddMoney(account, amount)
                    return true
                end
                return false
            end,

            RemoveMoney = function(src, account, amount)
                local Player = QBCore.Functions.GetPlayer(src)
                if Player then
                    Player.Functions.RemoveMoney(account, amount)
                    return true
                end
                return false
            end,
            
            GetMoney = function(src, account)
                local Player = QBCore.Functions.GetPlayer(src)
                if not Player then return 0 end
                return Player.Functions.GetMoney(account)
            end
        }
    end

    --=================================================
    -- STANDALONE
    --=================================================
    if Config.Framework == 'standalone' then
        Bridge.Framework = {
            GetPlayer = function(src) return src end,
            GetIdentifier = function(src) return tostring(src) end,
            HasJob = function() return true end,
            HasJobGrade = function() return true end,
            AddMoney = function() return true end,
            RemoveMoney = function() return true end,
            GetMoney = function() return 999999 end
        }
    end
end)

--=====================================================
-- INVENTORY DETECTION & SETUP
--=====================================================

CreateThread(function()
    if Config.Inventory == 'auto' then
        if ResourceStarted('ox_inventory') then
            Config.Inventory = 'ox'
        elseif ResourceStarted('qb-inventory') then
            Config.Inventory = 'qb'
        elseif ResourceStarted('qs-inventory') then
            Config.Inventory = 'qs'
        else
            Config.Inventory = 'none'
        end
    end

    print(('^2[FX-RESTAURANT] Inventory: %s^0'):format(Config.Inventory))

    --=================================================
    -- OX INVENTORY
    --=================================================
    if Config.Inventory == 'ox' then
        Bridge.Inventory = {
            AddItem = function(src, item, amount, metadata)
                return exports.ox_inventory:AddItem(src, item, amount, metadata)
            end,

            RemoveItem = function(src, item, amount, metadata, slot)
                return exports.ox_inventory:RemoveItem(src, item, amount, metadata, slot)
            end,

            HasItem = function(src, item, amount)
                return exports.ox_inventory:Search(src, 'count', item) >= (amount or 1)
            end,

            GetItemCount = function(src, item)
                return exports.ox_inventory:Search(src, 'count', item)
            end,
            
            CanCarryItem = function(src, item, amount)
                return exports.ox_inventory:CanCarryItem(src, item, amount)
            end
        }
    end

    --=================================================
    -- QB INVENTORY
    --=================================================
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
                if not Player then return false end
                
                local itemData = Player.Functions.GetItemByName(item)
                return itemData and itemData.amount >= (amount or 1)
            end,

            GetItemCount = function(src, item)
                local Player = QBCore.Functions.GetPlayer(src)
                if not Player then return 0 end
                
                local itemData = Player.Functions.GetItemByName(item)
                return itemData and itemData.amount or 0
            end,
            
            CanCarryItem = function(src, item, amount)
                -- QB heeft geen native cancarry, return altijd true
                return true
            end
        }
    end
    
    --=================================================
    -- QS INVENTORY
    --=================================================
    if Config.Inventory == 'qs' then
        Bridge.Inventory = {
            AddItem = function(src, item, amount, metadata)
                return exports['qs-inventory']:AddItem(src, item, amount, false, metadata)
            end,

            RemoveItem = function(src, item, amount)
                return exports['qs-inventory']:RemoveItem(src, item, amount)
            end,

            HasItem = function(src, item, amount)
                return exports['qs-inventory']:HasItem(src, item, amount or 1)
            end,

            GetItemCount = function(src, item)
                return exports['qs-inventory']:GetItemTotalAmount(src, item)
            end,
            
            CanCarryItem = function(src, item, amount)
                return exports['qs-inventory']:CanCarryItem(src, item, amount)
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

---Getter voor framework bridge
---@return table
function GetFrameworkBridge()
    return Bridge.Framework
end

---Getter voor inventory bridge
---@return table
function GetInventoryBridge()
    return Bridge.Inventory
end

exports('GetFrameworkBridge', GetFrameworkBridge)
exports('GetInventoryBridge', GetInventoryBridge)