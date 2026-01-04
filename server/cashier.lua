--=====================================================
-- FX-RESTAURANT | CASHIER SYSTEM (SERVER)
--=====================================================
-- Payment processing & invoice generation
--=====================================================

local Bridge = exports['fx-restaurant']:GetBridge()

--=====================================================
-- GET NEARBY PLAYERS
--=====================================================

lib.callback.register('fx-restaurant:cashier:getNearbyPlayers', function(src)
    local players = {}
    local srcCoords = GetEntityCoords(GetPlayerPed(src))
    
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        
        if targetId ~= src then
            local targetPed = GetPlayerPed(targetId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(srcCoords - targetCoords)
            
            if distance <= 5.0 then
                table.insert(players, {
                    id = targetId,
                    name = GetPlayerName(targetId),
                    distance = math.floor(distance * 100) / 100
                })
            end
        end
    end
    
    return players
end)

--=====================================================
-- CREATE INVOICE
--=====================================================

lib.callback.register('fx-restaurant:cashier:createInvoice', function(src, data)
    if not data.targetId or not data.items or not data.amount then
        return false, 'invalid_data'
    end
    
    local Framework = Bridge.Framework
    if not Framework then
        return false, 'framework_error'
    end
    
    -- Get issuer info
    local issuerIdentifier = Framework.GetIdentifier(src)
    local issuerName = GetPlayerName(src)
    
    -- Get recipient info
    local recipientIdentifier = Framework.GetIdentifier(data.targetId)
    local recipientName = GetPlayerName(data.targetId)
    
    if not recipientIdentifier then
        return false, 'player_not_found'
    end
    
    -- Generate invoice number
    local invoiceNumber = 'INV-' .. string.format('%06d', math.random(1, 999999))
    
    -- Insert invoice
    local invoiceId = MySQL.insert.await([[
        INSERT INTO restaurant_invoices
        (restaurant, invoice_number, issuer_identifier, issuer_name, 
         recipient_identifier, recipient_name, items, amount, status, payment_method)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?)
    ]], {
        data.restaurant,
        invoiceNumber,
        issuerIdentifier,
        issuerName,
        recipientIdentifier,
        recipientName,
        json.encode(data.items),
        data.amount,
        data.paymentMethod or 'cash'
    })
    
    if not invoiceId then
        return false, 'database_error'
    end
    
    -- Notify recipient
    TriggerClientEvent('fx-restaurant:invoice:receive', data.targetId, {
        invoiceId = invoiceId,
        invoiceNumber = invoiceNumber,
        from = issuerName,
        restaurant = data.restaurant,
        items = data.items,
        amount = data.amount,
        paymentMethod = data.paymentMethod
    })
    
    return true, {
        invoiceId = invoiceId,
        invoiceNumber = invoiceNumber
    }
end)

--=====================================================
-- PAY INVOICE
--=====================================================

lib.callback.register('fx-restaurant:cashier:payInvoice', function(src, invoiceId, paymentMethod)
    if not invoiceId or not paymentMethod then
        return false, 'invalid_data'
    end
    
    -- Get invoice
    local invoice = MySQL.single.await(
        'SELECT * FROM restaurant_invoices WHERE id = ?',
        { invoiceId }
    )
    
    if not invoice then
        return false, 'invoice_not_found'
    end
    
    if invoice.status ~= 'pending' then
        return false, 'already_paid'
    end
    
    local Framework = Bridge.Framework
    if not Framework then
        return false, 'framework_error'
    end
    
    -- Check if player is recipient
    local playerIdentifier = Framework.GetIdentifier(src)
    if playerIdentifier ~= invoice.recipient_identifier then
        return false, 'not_recipient'
    end
    
    -- Check money
    local accountType = paymentMethod == 'cash' and 'cash' or 'bank'
    local money = Framework.GetMoney(src, accountType)
    
    if money < invoice.amount then
        return false, 'insufficient_funds'
    end
    
    -- Remove money from customer
    if not Framework.RemoveMoney(src, accountType, invoice.amount) then
        return false, 'payment_failed'
    end
    
    -- Find issuer (if online) and add money
    local issuerOnline = false
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        local identifier = Framework.GetIdentifier(targetId)
        
        if identifier == invoice.issuer_identifier then
            issuerOnline = true
            -- Add to restaurant's account (or issuer's account)
            -- This could be society account for ESX/QBCore
            Framework.AddMoney(targetId, accountType, invoice.amount)
            
            -- Notify issuer
            TriggerClientEvent('fx-restaurant:invoice:paid', targetId, {
                invoiceNumber = invoice.invoice_number,
                amount = invoice.amount,
                from = invoice.recipient_name
            })
            break
        end
    end
    
    -- Update invoice
    MySQL.update.await([[
        UPDATE restaurant_invoices 
        SET status = 'paid', payment_method = ?, paid_at = NOW()
        WHERE id = ?
    ]], { paymentMethod, invoiceId })
    
    -- Update restaurant stats
    MySQL.insert.await([[
        INSERT INTO restaurant_stats (restaurant, stat_date, total_orders, total_revenue)
        VALUES (?, CURDATE(), 1, ?)
        ON DUPLICATE KEY UPDATE 
            total_orders = total_orders + 1,
            total_revenue = total_revenue + ?
    ]], { invoice.restaurant, invoice.amount, invoice.amount })
    
    return true, {
        invoiceNumber = invoice.invoice_number,
        amount = invoice.amount
    }
end)

--=====================================================
-- CANCEL INVOICE
--=====================================================

lib.callback.register('fx-restaurant:cashier:cancelInvoice', function(src, invoiceId)
    if not invoiceId then
        return false, 'invalid_data'
    end
    
    -- Get invoice
    local invoice = MySQL.single.await(
        'SELECT * FROM restaurant_invoices WHERE id = ?',
        { invoiceId }
    )
    
    if not invoice then
        return false, 'invoice_not_found'
    end
    
    local Framework = Bridge.Framework
    local playerIdentifier = Framework.GetIdentifier(src)
    
    -- Check if player is issuer or recipient
    if playerIdentifier ~= invoice.issuer_identifier and 
       playerIdentifier ~= invoice.recipient_identifier then
        return false, 'not_authorized'
    end
    
    if invoice.status ~= 'pending' then
        return false, 'cannot_cancel'
    end
    
    -- Update invoice
    MySQL.update.await(
        'UPDATE restaurant_invoices SET status = ? WHERE id = ?',
        { 'cancelled', invoiceId }
    )
    
    -- Notify both parties
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        local identifier = Framework.GetIdentifier(targetId)
        
        if identifier == invoice.issuer_identifier or 
           identifier == invoice.recipient_identifier then
            TriggerClientEvent('fx-restaurant:invoice:cancelled', targetId, {
                invoiceNumber = invoice.invoice_number
            })
        end
    end
    
    return true
end)

--=====================================================
-- GET PENDING INVOICES
--=====================================================

lib.callback.register('fx-restaurant:cashier:getPendingInvoices', function(src)
    local Framework = Bridge.Framework
    local identifier = Framework.GetIdentifier(src)
    
    if not identifier then
        return {}
    end
    
    local invoices = MySQL.query.await([[
        SELECT * FROM restaurant_invoices
        WHERE recipient_identifier = ? AND status = 'pending'
        ORDER BY created_at DESC
        LIMIT 10
    ]], { identifier })
    
    return invoices or {}
end)