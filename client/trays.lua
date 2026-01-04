--=====================================================
-- FX-RESTAURANT | SERVING TRAYS (CLIENT)
--=====================================================

local activeTray = nil

--=====================================================
-- OPEN TRAY
--=====================================================

function OpenTray(restaurant, trayId)
    lib.callback('fx-restaurant:tray:getContents', false, function(contents)
        local options = {}
        
        if contents and #contents > 0 then
            for _, item in ipairs(contents) do
                table.insert(options, {
                    title = item.label,
                    description = string.format('Aantal: %d (geplaatst door %s)', item.amount, item.placedBy),
                    icon = 'utensils',
                    onSelect = function()
                        TakeItemFromTray(restaurant, trayId, item.item, item.amount)
                    end
                })
            end
        else
            table.insert(options, {
                title = 'Leeg dienblad',
                description = 'Geen items op dit dienblad',
                icon = 'circle-xmark',
                disabled = true
            })
        end
        
        lib.registerContext({
            id = 'serving_tray',
            title = 'Dienblad #' .. trayId,
            options = options
        })
        
        lib.showContext('serving_tray')
    end, restaurant, trayId)
end

exports('OpenTray', OpenTray)

--=====================================================
-- PLACE ITEM ON TRAY
--=====================================================

function PlaceItemOnTray(restaurant, trayId, item, amount)
    lib.callback('fx-restaurant:tray:placeItem', false, function(success, error)
        if success then
            lib.notify({
                title = 'Item Geplaatst',
                description = 'Item is op het dienblad geplaatst',
                type = 'success'
            })
        else
            lib.notify({
                title = 'Fout',
                description = GetErrorMessage(error),
                type = 'error'
            })
        end
    end, restaurant, trayId, item, amount)
end

exports('PlaceItemOnTray', PlaceItemOnTray)

--=====================================================
-- TAKE ITEM FROM TRAY
--=====================================================

function TakeItemFromTray(restaurant, trayId, item, amount)
    local input = lib.inputDialog('Hoeveel nemen?', {
        {
            type = 'number',
            label = 'Aantal',
            default = 1,
            min = 1,
            max = amount,
            required = true
        }
    })
    
    if not input then return end
    
    lib.callback('fx-restaurant:tray:takeItem', false, function(success, error)
        if success then
            lib.notify({
                title = 'Item Genomen',
                description = 'Item is van het dienblad gehaald',
                type = 'success'
            })
        else
            lib.notify({
                title = 'Fout',
                description = GetErrorMessage(error),
                type = 'error'
            })
        end
    end, restaurant, trayId, item, input[1])
end

--=====================================================
-- UPDATE TRAY (From server sync)
--=====================================================

RegisterNetEvent('fx-restaurant:tray:update', function(trayId, contents)
    -- Update UI if open
    if activeTray == trayId then
        -- Refresh context menu
    end
end)

--=====================================================
-- ERROR MESSAGES
--=====================================================

function GetErrorMessage(error)
    local messages = {
        invalid_data = 'Ongeldige data',
        not_sellable = 'Dit item kan niet verkocht worden',
        missing_item = 'Je hebt dit item niet',
        remove_failed = 'Kon item niet verwijderen',
        empty_tray = 'Dienblad is leeg',
        insufficient_amount = 'Niet genoeg items',
        item_not_found = 'Item niet gevonden',
        inventory_full = 'Inventory vol',
        add_failed = 'Kon item niet toevoegen'
    }
    
    return messages[error] or 'Er is een fout opgetreden'
end

exports('OpenTray', OpenTray)
