--=====================================================
-- FX-RESTAURANT | CASHIER (CLIENT)
--=====================================================
-- Kassier systeem voor bestellingen
--=====================================================

local cashierOpen = false
local currentRestaurant = nil

--=====================================================
-- OPEN CASHIER
--=====================================================

---Open kassier interface
---@param restaurant string
function OpenCashier(restaurant)
    lib.callback('fx-restaurant:cashier:canUse', false, function(canUse)
        if not canUse then
            lib.notify({
                title = 'Kassa',
                description = 'Je hebt geen toegang tot de kassa',
                type = 'error'
            })
            return
        end
        
        currentRestaurant = restaurant
        cashierOpen = true
        
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openCashier',
            restaurant = restaurant
        })
    end, restaurant)
end

exports('OpenCashier', OpenCashier)

--=====================================================
-- NUI CALLBACKS
--=====================================================

-- Close cashier
RegisterNUICallback('closeCashier', function(data, cb)
    SetNuiFocus(false, false)
    cashierOpen = false
    currentRestaurant = nil
    cb('ok')
end)

-- Get nearby players
RegisterNUICallback('getNearbyPlayers', function(data, cb)
    lib.callback('fx-restaurant:cashier:getNearbyPlayers', false, function(players)
        cb({ players = players })
    end)
end)

-- Create invoice
RegisterNUICallback('createInvoice', function(data, cb)
    if not data.targetId or not data.amount then
        cb({ success = false, error = 'invalid_data' })
        return
    end
    
    lib.callback('fx-restaurant:cashier:createInvoice', false, function(success, result)
        if success then
            lib.notify({
                title = 'Factuur Verzonden',
                description = string.format('Factuur #%s verzonden naar %s', result.invoiceNumber, data.targetName),
                type = 'success',
                duration = 5000
            })
            
            PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 1)
            
            cb({ success = true, data = result })
        else
            local errorMsg = GetErrorMessage(result)
            lib.notify({
                title = 'Fout',
                description = errorMsg,
                type = 'error'
            })
            cb({ success = false, error = result })
        end
    end, currentRestaurant, data)
end)

--=====================================================
-- RECEIVE INVOICE (Customer side)
--=====================================================

RegisterNetEvent('fx-restaurant:invoice:receive', function(invoiceData)
    -- Show invoice to customer
    local alert = lib.alertDialog({
        header = 'Factuur Ontvangen',
        content = string.format(
            '**Van:** %s\n' ..
            '**Restaurant:** %s\n' ..
            '**Bedrag:** $%d\n' ..
            '**Betaalmethode:** %s\n\n' ..
            'Wil je deze factuur betalen?',
            invoiceData.from,
            invoiceData.restaurant,
            invoiceData.amount,
            invoiceData.paymentMethod == 'cash' and 'Contant' or 'Bank'
        ),
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Betalen',
            cancel = 'Weigeren'
        }
    })
    
    if alert == 'confirm' then
        -- Pay invoice
        lib.callback('fx-restaurant:cashier:payInvoice', false, function(success, result)
            if success then
                lib.notify({
                    title = 'Betaling Voltooid',
                    description = string.format('Factuur #%s betaald: $%d', result.invoiceNumber, result.amount),
                    type = 'success',
                    duration = 5000
                })
                
                PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", 1)
            else
                local errorMsg = GetErrorMessage(result)
                lib.notify({
                    title = 'Betaling Mislukt',
                    description = errorMsg,
                    type = 'error'
                })
            end
        end, invoiceData.invoiceId, invoiceData.paymentMethod)
    else
        -- Cancel invoice
        lib.callback('fx-restaurant:cashier:cancelInvoice', false, function(success)
            if success then
                lib.notify({
                    title = 'Factuur Geweigerd',
                    description = 'Je hebt de factuur geweigerd',
                    type = 'info'
                })
            end
        end, invoiceData.invoiceId)
    end
end)

--=====================================================
-- INVOICE PAID NOTIFICATION (Staff side)
--=====================================================

RegisterNetEvent('fx-restaurant:invoice:paid', function(data)
    lib.notify({
        title = 'Factuur Betaald',
        description = string.format('%s heeft factuur #%s betaald ($%d)', data.from, data.invoiceNumber, data.amount),
        type = 'success',
        icon = 'fa-solid fa-money-bill-wave',
        duration = 7000
    })
    
    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 1)
end)

--=====================================================
-- INVOICE CANCELLED NOTIFICATION
--=====================================================

RegisterNetEvent('fx-restaurant:invoice:cancelled', function(data)
    lib.notify({
        title = 'Factuur Geannuleerd',
        description = string.format('Factuur #%s is geannuleerd', data.invoiceNumber),
        type = 'warning'
    })
end)

--=====================================================
-- VIEW PENDING INVOICES
--=====================================================

RegisterCommand('myinvoices', function()
    lib.callback('fx-restaurant:cashier:getPendingInvoices', false, function(invoices)
        if not invoices or #invoices == 0 then
            lib.notify({
                title = 'Geen Facturen',
                description = 'Je hebt geen openstaande facturen',
                type = 'info'
            })
            return
        end
        
        -- Build menu
        local options = {}
        
        for _, invoice in ipairs(invoices) do
            local items = json.decode(invoice.items)
            local itemsText = ''
            
            for i, item in ipairs(items) do
                itemsText = itemsText .. string.format('%dx %s', item.amount, item.name)
                if i < #items then
                    itemsText = itemsText .. ', '
                end
            end
            
            table.insert(options, {
                title = string.format('Factuur #%s', invoice.invoice_number),
                description = string.format('Van: %s | Bedrag: $%d', invoice.issuer_name, invoice.amount),
                icon = 'file-invoice-dollar',
                metadata = {
                    { label = 'Items', value = itemsText },
                    { label = 'Betaalmethode', value = invoice.payment_method == 'cash' and 'Contant' or 'Bank' },
                    { label = 'Datum', value = invoice.created_at }
                },
                onSelect = function()
                    -- Open payment dialog
                    local alert = lib.alertDialog({
                        header = 'Factuur Betalen',
                        content = string.format(
                            '**Bedrag:** $%d\n**Items:** %s\n\nWil je deze factuur betalen?',
                            invoice.amount,
                            itemsText
                        ),
                        centered = true,
                        cancel = true
                    })
                    
                    if alert == 'confirm' then
                        lib.callback('fx-restaurant:cashier:payInvoice', false, function(success, result)
                            if success then
                                lib.notify({
                                    title = 'Betaling Voltooid',
                                    description = string.format('Factuur betaald: $%d', result.amount),
                                    type = 'success'
                                })
                                
                                PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", 1)
                            else
                                local errorMsg = GetErrorMessage(result)
                                lib.notify({
                                    title = 'Betaling Mislukt',
                                    description = errorMsg,
                                    type = 'error'
                                })
                            end
                        end, invoice.id, invoice.payment_method)
                    end
                end
            })
        end
        
        lib.registerContext({
            id = 'pending_invoices',
            title = 'Openstaande Facturen',
            options = options
        })
        
        lib.showContext('pending_invoices')
    end)
end, false)

--=====================================================
-- ERROR MESSAGES
--=====================================================

function GetErrorMessage(error)
    local messages = {
        invalid_data = 'Ongeldige data',
        player_not_found = 'Speler niet gevonden',
        invoice_not_found = 'Factuur niet gevonden',
        already_paid = 'Factuur is al betaald',
        not_recipient = 'Je bent niet de ontvanger van deze factuur',
        insufficient_funds = 'Niet genoeg geld',
        payment_failed = 'Betaling mislukt',
        cannot_cancel = 'Kan factuur niet annuleren',
        not_authorized = 'Niet geautoriseerd',
        framework_error = 'Framework fout'
    }
    
    return messages[error] or 'Er is een fout opgetreden'
end

--=====================================================
-- EXPORTS
--=====================================================

exports('OpenCashier', OpenCashier)
