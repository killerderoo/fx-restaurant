--=====================================================
-- FX-RESTAURANT | STATIONS (CLIENT)
--=====================================================
-- Preparation & Cooking stations
--=====================================================

local currentStation = nil
local isProcessing = false

--=====================================================
-- PREPARATION STATIONS
--=====================================================

---Open preparation menu
---@param stationType string Type of station (cutting, grinding, blending)
function OpenPreparationStation(stationType)
    if isProcessing then
        lib.notify({
            title = 'Bezig',
            description = 'Je bent al iets aan het voorbereiden',
            type = 'error'
        })
        return
    end
    
    local station = Config.PreparationStations[stationType]
    if not station then return end
    
    -- Build menu options
    local options = {}
    
    for _, recipe in ipairs(station.recipes) do
        local itemData = GetItemData(recipe.input)
        
        table.insert(options, {
            title = string.format('%s → %s', itemData.label or recipe.input, recipe.output),
            description = string.format('Verwerk %s', itemData.label or recipe.input),
            icon = station.icon,
            iconColor = '#3b82f6',
            onSelect = function()
                ProcessPreparation(stationType, recipe.input)
            end
        })
    end
    
    if #options == 0 then
        lib.notify({
            title = station.label,
            description = 'Geen recepten beschikbaar',
            type = 'info'
        })
        return
    end
    
    lib.registerContext({
        id = 'preparation_menu',
        title = station.label,
        options = options
    })
    
    lib.showContext('preparation_menu')
end

exports('OpenPreparationStation', OpenPreparationStation)

---Process preparation
---@param stationType string
---@param inputItem string
function ProcessPreparation(stationType, inputItem)
    if isProcessing then return end
    
    isProcessing = true
    
    local station = Config.PreparationStations[stationType]
    if not station then
        isProcessing = false
        return
    end
    
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Play animation
    if station.animation then
        lib.requestAnimDict(station.animation.dict)
        TaskPlayAnim(ped, station.animation.dict, station.animation.anim, 8.0, -8.0, -1, station.animation.flag, 0, false, false, false)
    end
    
    -- Progress bar
    if lib.progressBar({
        duration = station.duration,
        label = 'Voorbereiden...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        }
    }) then
        -- Complete
        lib.callback('fx-restaurant:preparation:process', false, function(success, result)
            ClearPedTasks(ped)
            isProcessing = false
            
            if success then
                lib.notify({
                    title = 'Voltooid',
                    description = string.format('Je hebt %dx %s gemaakt', result.amount, result.output),
                    type = 'success'
                })
            else
                lib.notify({
                    title = 'Fout',
                    description = GetErrorMessage(result),
                    type = 'error'
                })
            end
        end, stationType, inputItem)
    else
        -- Cancelled
        ClearPedTasks(ped)
        isProcessing = false
    end
end

--=====================================================
-- COOKING STATIONS
--=====================================================

---Open cooking station
---@param restaurant string Restaurant ID
---@param station string Station type (grill, fryer, oven, drinks)
function OpenCookingStation(restaurant, station)
    if isProcessing then
        lib.notify({
            title = 'Bezig',
            description = 'Je bent al iets aan het koken',
            type = 'error'
        })
        return
    end
    
    lib.callback('fx-restaurant:cooking:getRecipes', false, function(recipes)
        if not recipes or not next(recipes) then
            lib.notify({
                title = 'Geen Recepten',
                description = 'Er zijn geen recepten voor dit station',
                type = 'info'
            })
            return
        end
        
        -- Build menu
        local options = {}
        
        for id, recipe in pairs(recipes) do
            -- Build ingredients text
            local ingredientsText = ''
            for i, ingredient in ipairs(recipe.ingredients) do
                ingredientsText = ingredientsText .. string.format('%dx %s', ingredient.amount, ingredient.item)
                if i < #recipe.ingredients then
                    ingredientsText = ingredientsText .. ', '
                end
            end
            
            table.insert(options, {
                title = recipe.name,
                description = ingredientsText,
                icon = 'utensils',
                iconColor = '#10b981',
                metadata = {
                    { label = 'Prijs', value = '$' .. recipe.price },
                    { label = 'Type', value = recipe.type == 'food' and 'Eten' or 'Drinken' }
                },
                onSelect = function()
                    CookRecipe(restaurant, id, recipe)
                end
            })
        end
        
        lib.registerContext({
            id = 'cooking_menu',
            title = Config.CookingStations[station].label,
            options = options
        })
        
        lib.showContext('cooking_menu')
    end, restaurant, station)
end

exports('OpenCookingStation', OpenCookingStation)

---Cook a recipe
---@param restaurant string
---@param recipeId number
---@param recipe table
function CookRecipe(restaurant, recipeId, recipe)
    if isProcessing then return end
    
    isProcessing = true
    
    local ped = PlayerPedId()
    local stationConfig = Config.CookingStations[recipe.station]
    
    -- Play animation
    if stationConfig and stationConfig.animation then
        lib.requestAnimDict(stationConfig.animation.dict)
        TaskPlayAnim(ped, stationConfig.animation.dict, stationConfig.animation.anim, 8.0, -8.0, -1, stationConfig.animation.flag, 0, false, false, false)
        
        -- Attach prop if configured
        if stationConfig.prop then
            local prop = CreateObject(GetHashKey(stationConfig.prop.model), 0, 0, 0, true, true, true)
            AttachEntityToEntity(
                prop, ped, 
                GetPedBoneIndex(ped, stationConfig.prop.bone),
                stationConfig.prop.offset.x, stationConfig.prop.offset.y, stationConfig.prop.offset.z,
                stationConfig.prop.rotation.x, stationConfig.prop.rotation.y, stationConfig.prop.rotation.z,
                true, true, false, true, 1, true
            )
            
            -- Delete prop after animation
            CreateThread(function()
                Wait(stationConfig.duration)
                DeleteObject(prop)
            end)
        end
    end
    
    -- Progress bar
    if lib.progressBar({
        duration = stationConfig and stationConfig.duration or 10000,
        label = string.format('Bereiden: %s...', recipe.name),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        }
    }) then
        -- Complete
        lib.callback('fx-restaurant:cooking:cook', false, function(success, result)
            ClearPedTasks(ped)
            isProcessing = false
            
            if success then
                lib.notify({
                    title = 'Klaar!',
                    description = string.format('Je hebt %s gemaakt', recipe.name),
                    type = 'success'
                })
                
                -- Play success sound
                PlaySoundFrontend(-1, "CLICK_BACK", "WEB_NAVIGATION_SOUNDS_PHONE", 1)
            else
                lib.notify({
                    title = 'Fout',
                    description = GetErrorMessage(result),
                    type = 'error'
                })
            end
        end, restaurant, recipeId)
    else
        -- Cancelled
        ClearPedTasks(ped)
        isProcessing = false
    end
end

--=====================================================
-- HELPER FUNCTIONS
--=====================================================

function GetErrorMessage(error)
    local messages = {
        invalid_data = 'Ongeldige data',
        invalid_station = 'Ongeldig station',
        no_recipe = 'Geen recept gevonden',
        missing_ingredient = 'Ingredient ontbreekt',
        missing_ingredients = 'Ingrediënten ontbreken',
        inventory_full = 'Inventory vol',
        remove_failed = 'Kon ingrediënten niet verwijderen',
        add_failed = 'Kon product niet toevoegen',
        invalid_recipe = 'Ongeldig recept'
    }
    
    return messages[error] or 'Er is een fout opgetreden'
end

--=====================================================
-- EXPORTS
--=====================================================

exports('OpenPreparationStation', OpenPreparationStation)
exports('OpenCookingStation', OpenCookingStation)