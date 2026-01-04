--=====================================================
-- FX-RESTAURANT | OFFLINE SHOP (CLIENT)
--=====================================================
-- Klanten kunnen items kopen zonder staff online
--=====================================================

local shopOpen = false
local currentRestaurant = nil
local cart = {}

--=====================================================
-- OPEN OFFLINE SHOP
--=====================================================

---Open offline shop voor klanten
---@param restaurant string
function OpenOfflineShop(restaurant)
    lib.callback('fx-restaurant:offlineshop:getInventory', false, function(success, data)
        if not success then
            lib.notify({
                title = 'Offline Shop',
                description = 'Kan winkel niet laden',
                type = 'error'
            })
            return
        end
        
        currentRestaurant = restaurant
        shopOpen = true
        cart = {}
        
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openOfflineShop',
            restaurant = restaurant,
            items = data.items,
            currency = data.currency or 'cash'
        })
    end, restaurant)
end

exports('OpenOfflineShop', OpenOfflineShop)

--=====================================================
-- NUI CALLBACKS
--=====================================================

-- Close shop
RegisterNUICallback('closeOfflineShop', function(data, cb)
    SetNuiFocus(false, false)
    shopOpen = false
    cart = {}
    currentRestaurant = nil
    cb('ok')
end)

-- Add to cart
RegisterNUICallback('addToOfflineCart', function(data, cb)
    local item = data.item
    local amount = data.amount or 1
    
    -- Check if item exists in cart
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
            label = data.label,
            price = data.price,
            amount = amount
        })
    end
    
    cb({ success = true, cart = cart })
end)

-- Remove from cart
RegisterNUICallback('removeFromOfflineCart', function(data, cb)
    for i, cartItem in ipairs(cart) do
        if cartItem.item == data.item then
            table.remove(cart, i)
            break
        end
    end
    
    cb({ success = true, cart = cart })
end)

-- Update cart item amount
RegisterNUICallback('updateOfflineCartAmount', function(data, cb)
    for i, cartItem in ipairs(cart) do
        if cartItem.item == data.item then
            cart[i].amount = data.amount
            if cart[i].amount <= 0 then
                table.remove(cart, i)
            end
            break
        end
    end
    
    cb({ success = true, cart = cart })
end)

-- Purchase
RegisterNUICallback('purchaseOfflineShop', function(data, cb)
    if #cart == 0 then
        cb({ success = false, error = 'empty_cart' })
        return
    end
    
    lib.callback('fx-restaurant:offlineshop:purchase', false, function(success, result)
        if success then
            lib.notify({
                title = 'Aankoop Voltooid',
                description = string.format('Betaald: $%d', result.total),
                type = 'success'
            })
            
            PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", 1)
            
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
    end, currentRestaurant, cart, data.paymentMethod)
end)

--=====================================================
-- ERROR MESSAGES
--=====================================================

function GetErrorMessage(error)
    local messages = {
        empty_cart = 'Winkelwagen is leeg',
        out_of_stock = 'Item is niet meer op voorraad',
        insufficient_funds = 'Niet genoeg geld',
        payment_failed = 'Betaling mislukt',
        inventory_full = 'Inventory vol',
        invalid_payment = 'Ongeldige betaalmethode'
    }
    
    return messages[error] or 'Er is een fout opgetreden'
end