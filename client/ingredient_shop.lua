--=====================================================
-- FX-RESTAURANT | INGREDIENT SHOP (CLIENT)
--=====================================================
-- UI voor het kopen van ingrediënten
--=====================================================

local shopOpen = false
local cart = {}

--=====================================================
-- OPEN INGREDIENT SHOP
--=====================================================

function OpenIngredientShop()
    lib.callback('fx-restaurant:ingredients:getShop', false, function(categories)
        if not categories then
            lib.notify({
                title = 'Fout',
                description = 'Kon winkel niet laden',
                type = 'error'
            })
            return
        end
        
        shopOpen = true
        cart = {}
        
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openIngredientShop',
            categories = categories
        })
    end)
end

exports('OpenIngredientShop', OpenIngredientShop)

--=====================================================
-- NUI CALLBACKS
--=====================================================

-- Close shop
RegisterNUICallback('closeIngredientShop', function(data, cb)
    SetNuiFocus(false, false)
    shopOpen = false
    cart = {}
    cb('ok')
end)

-- Add to cart
RegisterNUICallback('addToCart', function(data, cb)
    local item = data.item
    local amount = data.amount
    
    if not item or not amount or amount <= 0 then
        cb({ success = false })
        return
    end
    
    -- Add to cart or update amount
    local found = false
    for i, cartItem in ipairs(cart) do
        if cartItem.item == item then
            cart[i].amount = cart[i].amount + amount
            found = true
            break
        end
    end
    
    if not found then
        table.insert(cart, {
            item = item,
            price = data.price,
            amount = amount,
            label = data.label
        })
    end
    
    cb({ success = true, cart = cart })
end)

-- Remove from cart
RegisterNUICallback('removeFromCart', function(data, cb)
    for i, cartItem in ipairs(cart) do
        if cartItem.item == data.item then
            table.remove(cart, i)
            break
        end
    end
    
    cb({ success = true, cart = cart })
end)

-- Purchase
RegisterNUICallback('purchaseItems', function(data, cb)
    if #cart == 0 then
        cb({ success = false, error = 'no_items' })
        return
    end
    
    lib.callback('fx-restaurant:ingredients:purchase', false, function(success, result)
        if success then
            lib.notify({
                title = 'Aankoop Voltooid',
                description = string.format('Totaal betaald: $%d', result),
                type = 'success'
            })
            
            cart = {}
            cb({ success = true })
        else
            local errorMsg = GetErrorMessage(result)
            lib.notify({
                title = 'Aankoop Mislukt',
                description = errorMsg,
                type = 'error'
            })
            cb({ success = false, error = result })
        end
    end, cart, data.total)
end)

--=====================================================
-- ERROR MESSAGES
--=====================================================

function GetErrorMessage(error)
    local messages = {
        no_items = 'Geen items geselecteerd',
        invalid_item = 'Ongeldig item',
        not_ingredient = 'Dit is geen ingredient',
        insufficient_funds = 'Niet genoeg geld',
        payment_failed = 'Betaling mislukt',
        inventory_full = 'Inventory vol'
    }
    
    return messages[error] or 'Er is een fout opgetreden'
end