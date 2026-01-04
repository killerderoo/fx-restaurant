--=====================================================
-- FX-RESTAURANT | SERVING TRAYS (SERVER)
--=====================================================
-- Food placement and pickup system
--=====================================================

local Bridge = exports['fx-restaurant']:GetBridge()
local Trays = {} -- In-memory tray storage

--=====================================================
-- INITIALIZE TRAYS
--=====================================================

---Get tray ID for restaurant
---@param restaurant string
---@param trayNumber number
---@return string
local function GetTrayId(restaurant, trayNumber)
    return restaurant .. '_tray_' .. trayNumber
end

--=====================================================
-- PLACE ITEM ON TRAY
--=====================================================

lib.callback.register('fx-restaurant:tray:placeItem', function(src, restaurant, trayNumber, item, amount)
    if not restaurant or not trayNumber or not item or not amount then
        return false, 'invalid_data'
    end
    
    local Inventory = Bridge.Inventory
    if not Inventory then
        return false, 'inventory_error'
    end
    
    -- Check if item is sellable (finished product)
    if not IsSellableItem(item) then
        return false, 'not_sellable'
    end
    
    -- Check if player has item
    if not Inventory.HasItem(src, item, amount) then
        return false, 'missing_item'
    end
    
    -- Remove from player
    if not Inventory.RemoveItem(src, item, amount) then
        return false, 'remove_failed'
    end
    
    -- Add to tray storage
    local trayId = GetTrayId(restaurant, trayNumber)
    
    if not Trays[trayId] then
        Trays[trayId] = {}
    end
    
    -- Check if item already on tray
    local found = false
    for i, trayItem in ipairs(Trays[trayId]) do
        if trayItem.item == item then
            Trays[trayId][i].amount = Trays[trayId][i].amount + amount
            found = true
            break
        end
    end
    
    if not found then
        local itemData = GetItemData(item)
        table.insert(Trays[trayId], {
            item = item,
            label = itemData.label or item,
            amount = amount,
            placedBy = GetPlayerName(src),
            placedAt = os.time()
        })
    end
    
    -- Sync to all nearby players
    TriggerClientEvent('fx-restaurant:tray:update', -1, trayId, Trays[trayId])
    
    return true
end)

--=====================================================
-- TAKE ITEM FROM TRAY
--=====================================================

lib.callback.register('fx-restaurant:tray:takeItem', function(src, restaurant, trayNumber, item, amount)
    if not restaurant or not trayNumber or not item or not amount then
        return false, 'invalid_data'
    end
    
    local Inventory = Bridge.Inventory
    if not Inventory then
        return false, 'inventory_error'
    end
    
    local trayId = GetTrayId(restaurant, trayNumber)
    
    if not Trays[trayId] then
        return false, 'empty_tray'
    end
    
    -- Find item on tray
    local itemIndex = nil
    for i, trayItem in ipairs(Trays[trayId]) do
        if trayItem.item == item then
            if trayItem.amount >= amount then
                itemIndex = i
                break
            else
                return false, 'insufficient_amount'
            end
        end
    end
    
    if not itemIndex then
        return false, 'item_not_found'
    end
    
    -- Check if player can carry
    if not Inventory.CanCarryItem(src, item, amount) then
        return false, 'inventory_full'
    end
    
    -- Add to player
    if not Inventory.AddItem(src, item, amount) then
        return false, 'add_failed'
    end
    
    -- Remove from tray
    Trays[trayId][itemIndex].amount = Trays[trayId][itemIndex].amount - amount
    
    if Trays[trayId][itemIndex].amount <= 0 then
        table.remove(Trays[trayId], itemIndex)
    end
    
    -- Sync to all nearby players
    TriggerClientEvent('fx-restaurant:tray:update', -1, trayId, Trays[trayId])
    
    return true
end)

--=====================================================
-- GET TRAY CONTENTS
--=====================================================

lib.callback.register('fx-restaurant:tray:getContents', function(src, restaurant, trayNumber)
    local trayId = GetTrayId(restaurant, trayNumber)
    return Trays[trayId] or {}
end)

--=====================================================
-- CLEAR TRAY (ADMIN/BOSS)
--=====================================================

lib.callback.register('fx-restaurant:tray:clear', function(src, restaurant, trayNumber)
    -- Check permission
    if not exports['fx-restaurant']:HasJobGrade(src, restaurant, 'boss_menu') then
        return false, 'no_permission'
    end
    
    local trayId = GetTrayId(restaurant, trayNumber)
    Trays[trayId] = {}
    
    -- Sync to all nearby players
    TriggerClientEvent('fx-restaurant:tray:update', -1, trayId, {})
    
    return true
end)

--=====================================================
-- CLEANUP OLD ITEMS (Every 30 minutes)
--=====================================================

CreateThread(function()
    while true do
        Wait(30 * 60 * 1000) -- 30 minutes
        
        local currentTime = os.time()
        
        for trayId, items in pairs(Trays) do
            for i = #items, 1, -1 do
                -- Remove items older than 2 hours
                if currentTime - items[i].placedAt > (2 * 60 * 60) then
                    table.remove(items, i)
                end
            end
            
            -- Sync update
            if #items == 0 then
                Trays[trayId] = nil
            else
                TriggerClientEvent('fx-restaurant:tray:update', -1, trayId, items)
            end
        end
    end
end)