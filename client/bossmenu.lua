--=====================================================
-- FX-RESTAURANT | BOSS MENU (CLIENT)
--=====================================================
-- UI Interface voor Boss Menu
--=====================================================

local currentRestaurant = nil
local bossMenuOpen = false

--=====================================================
-- OPEN BOSS MENU
--=====================================================

---Open het boss menu
---@param restaurant string Restaurant ID
function OpenBossMenu(restaurant)
    lib.callback('fx-restaurant:bossmenu:open', false, function(success, error)
        if not success then
            lib.notify({
                title = 'Boss Menu',
                description = 'Je hebt geen toegang tot het boss menu',
                type = 'error'
            })
            return
        end
        
        currentRestaurant = restaurant
        bossMenuOpen = true
        
        -- Open NUI
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openBossMenu',
            restaurant = restaurant
        })
    end, restaurant)
end

exports('OpenBossMenu', OpenBossMenu)

--=====================================================
-- NUI CALLBACKS
--=====================================================

-- Close menu
RegisterNUICallback('closeBossMenu', function(data, cb)
    SetNuiFocus(false, false)
    bossMenuOpen = false
    currentRestaurant = nil
    cb('ok')
end)

--=================================================
-- MANAGEMENT TAB
--=================================================

-- Get management data
RegisterNUICallback('getManagementData', function(data, cb)
    lib.callback('fx-restaurant:bossmenu:getManagement', false, function(result)
        cb(result)
    end, currentRestaurant)
end)

-- Hire employee
RegisterNUICallback('hireEmployee', function(data, cb)
    local input = lib.inputDialog('Medewerker Aannemen', {
        {
            type = 'number',
            label = 'Speler ID',
            description = 'De server ID van de speler',
            required = true,
            min = 1
        }
    })
    
    if not input then
        cb({ success = false })
        return
    end
    
    lib.callback('fx-restaurant:bossmenu:hireEmployee', false, function(success, message)
        if success then
            lib.notify({
                title = 'Medewerker Aangenomen',
                description = 'De medewerker is succesvol aangenomen',
                type = 'success'
            })
        else
            lib.notify({
                title = 'Fout',
                description = GetErrorMessage(message),
                type = 'error'
            })
        end
        
        cb({ success = success })
    end, currentRestaurant, input[1])
end)

-- Fire employee
RegisterNUICallback('fireEmployee', function(data, cb)
    local alert = lib.alertDialog({
        header = 'Medewerker Ontslaan',
        content = 'Weet je zeker dat je deze medewerker wilt ontslaan?',
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        lib.callback('fx-restaurant:bossmenu:fireEmployee', false, function(success, message)
            if success then
                lib.notify({
                    title = 'Medewerker Ontslagen',
                    description = 'De medewerker is ontslagen',
                    type = 'success'
                })
            else
                lib.notify({
                    title = 'Fout',
                    description = GetErrorMessage(message),
                    type = 'error'
                })
            end
            
            cb({ success = success })
        end, currentRestaurant, data.employeeId)
    else
        cb({ success = false })
    end
end)

-- Set employee grade
RegisterNUICallback('setEmployeeGrade', function(data, cb)
    lib.callback('fx-restaurant:bossmenu:setEmployeeGrade', false, function(success, message)
        if success then
            lib.notify({
                title = 'Rang Gewijzigd',
                description = 'De rang van de medewerker is gewijzigd',
                type = 'success'
            })
        else
            lib.notify({
                title = 'Fout',
                description = GetErrorMessage(message),
                type = 'error'
            })
        end
        
        cb({ success = success })
    end, currentRestaurant, data.employeeId, data.grade)
end)

--=================================================
-- RECIPES TAB
--=================================================

-- Get recipes
RegisterNUICallback('getRecipes', function(data, cb)
    lib.callback('fx-restaurant:recipe:getAll', false, function(recipes)
        cb({ recipes = recipes })
    end, currentRestaurant)
end)

-- Create recipe
RegisterNUICallback('createRecipe', function(data, cb)
    lib.callback('fx-restaurant:recipe:create', false, function(success, error)
        if success then
            lib.notify({
                title = 'Recept Aangemaakt',
                description = 'Het recept is succesvol aangemaakt',
                type = 'success'
            })
        else
            lib.notify({
                title = 'Fout',
                description = GetErrorMessage(error),
                type = 'error'
            })
        end
        
        cb({ success = success })
    end, data)
end)

-- Update recipe
RegisterNUICallback('updateRecipe', function(data, cb)
    lib.callback('fx-restaurant:recipe:update', false, function(success, error)
        if success then
            lib.notify({
                title = 'Recept Bijgewerkt',
                description = 'Het recept is succesvol bijgewerkt',
                type = 'success'
            })
        else
            lib.notify({
                title = 'Fout',
                description = GetErrorMessage(error),
                type = 'error'
            })
        end
        
        cb({ success = success })
    end, data)
end)

-- Delete recipe
RegisterNUICallback('deleteRecipe', function(data, cb)
    local alert = lib.alertDialog({
        header = 'Recept Verwijderen',
        content = 'Weet je zeker dat je dit recept wilt verwijderen?',
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        lib.callback('fx-restaurant:recipe:delete', false, function(success)
            if success then
                lib.notify({
                    title = 'Recept Verwijderd',
                    description = 'Het recept is verwijderd',
                    type = 'success'
                })
            else
                lib.notify({
                    title = 'Fout',
                    description = 'Het recept kon niet worden verwijderd',
                    type = 'error'
                })
            end
            
            cb({ success = success })
        end, currentRestaurant, data.recipeId)
    else
        cb({ success = false })
    end
end)

--=================================================
-- MENU IMAGES TAB
--=================================================

-- Get menu images
RegisterNUICallback('getMenuImages', function(data, cb)
    lib.callback('fx-restaurant:bossmenu:getMenuImages', false, function(images)
        cb({ images = images })
    end, currentRestaurant)
end)

-- Update menu image
RegisterNUICallback('updateMenuImage', function(data, cb)
    local input = lib.inputDialog('Menu Afbeelding', {
        {
            type = 'input',
            label = 'Afbeelding URL',
            description = 'Gebruik https://ibb.co/ of imgur links',
            placeholder = 'https://i.ibb.co/xxxxxx/menu.png',
            required = true
        },
        {
            type = 'input',
            label = 'Titel',
            placeholder = 'Menu',
            required = false
        }
    })
    
    if not input then
        cb({ success = false })
        return
    end
    
    lib.callback('fx-restaurant:bossmenu:updateMenuImage', false, function(success, error)
        if success then
            lib.notify({
                title = 'Menu Afbeelding',
                description = 'De menu afbeelding is bijgewerkt',
                type = 'success'
            })
        else
            lib.notify({
                title = 'Fout',
                description = GetErrorMessage(error),
                type = 'error'
            })
        end
        
        cb({ success = success })
    end, currentRestaurant, input[1], input[2])
end)

--=================================================
-- OFFLINE SHOP TAB
--=================================================

-- Get shop inventory
RegisterNUICallback('getShopInventory', function(data, cb)
    lib.callback('fx-restaurant:bossmenu:getShopInventory', false, function(inventory)
        cb({ inventory = inventory })
    end, currentRestaurant)
end)

-- Add shop item
RegisterNUICallback('addShopItem', function(data, cb)
    local input = lib.inputDialog('Item Toevoegen', {
        {
            type = 'input',
            label = 'Item Naam',
            description = 'De naam van het item (bijv. burger)',
            required = true
        },
        {
            type = 'number',
            label = 'Prijs',
            description = 'Prijs per stuk',
            required = true,
            min = 1
        },
        {
            type = 'number',
            label = 'Voorraad',
            description = 'Aantal items in stock',
            required = true,
            min = 1
        }
    })
    
    if not input then
        cb({ success = false })
        return
    end
    
    lib.callback('fx-restaurant:bossmenu:addShopItem', false, function(success, error)
        if success then
            lib.notify({
                title = 'Item Toegevoegd',
                description = 'Het item is toegevoegd aan de shop',
                type = 'success'
            })
        else
            lib.notify({
                title = 'Fout',
                description = GetErrorMessage(error),
                type = 'error'
            })
        end
        
        cb({ success = success })
    end, currentRestaurant, input[1], input[2], input[3])
end)

-- Update shop item
RegisterNUICallback('updateShopItem', function(data, cb)
    lib.callback('fx-restaurant:bossmenu:updateShopItem', false, function(success, error)
        if success then
            lib.notify({
                title = 'Item Bijgewerkt',
                description = 'Het item is bijgewerkt',
                type = 'success'
            })
        else
            lib.notify({
                title = 'Fout',
                description = GetErrorMessage(error),
                type = 'error'
            })
        end
        
        cb({ success = success })
    end, currentRestaurant, data.itemId, data.price, data.stock)
end)

-- Remove shop item
RegisterNUICallback('removeShopItem', function(data, cb)
    local alert = lib.alertDialog({
        header = 'Item Verwijderen',
        content = 'Weet je zeker dat je dit item wilt verwijderen?',
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        lib.callback('fx-restaurant:bossmenu:removeShopItem', false, function(success)
            if success then
                lib.notify({
                    title = 'Item Verwijderd',
                    description = 'Het item is verwijderd uit de shop',
                    type = 'success'
                })
            else
                lib.notify({
                    title = 'Fout',
                    description = 'Het item kon niet worden verwijderd',
                    type = 'error'
                })
            end
            
            cb({ success = success })
        end, currentRestaurant, data.itemId)
    else
        cb({ success = false })
    end
end)

-- Toggle shop item
RegisterNUICallback('toggleShopItem', function(data, cb)
    lib.callback('fx-restaurant:bossmenu:toggleShopItem', false, function(success)
        cb({ success = success })
    end, currentRestaurant, data.itemId, data.active)
end)

--=====================================================
-- HELPER FUNCTIONS
--=====================================================

local function GetErrorMessage(error)
    local messages = {
        no_permission = 'Je hebt geen toestemming',
        invalid_url = 'Ongeldige URL (gebruik ibb.co of imgur)',
        not_sellable = 'Dit item kan niet verkocht worden',
        stock_too_high = 'Te veel voorraad',
        already_exists = 'Dit item bestaat al',
        invalid_item = 'Ongeldig item',
        max_recipes_reached = 'Maximum aantal recepten bereikt',
        price_too_high = 'Prijs te hoog',
        too_many_ingredients = 'Te veel ingrediënten',
        recipe_not_found = 'Recept niet gevonden'
    }
    
    return messages[error] or 'Er is een fout opgetreden'
end

--=====================================================
-- EXPORTS
--=====================================================

exports('OpenBossMenu', OpenBossMenu)