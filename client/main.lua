QBCore = nil

Citizen.CreateThread(function()
    while QBCore == nil do
        TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
        Citizen.Wait(0)
    end
end)

local isVisible = false
local isOpening = false
local isLoading = false
local outfits = {}

-- Default controls

Citizen.CreateThread(function()
    while true do
        if isVisible then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
        end
        Citizen.Wait(0)
    end
end)

-- Main Thread

CreateThread(function()
    while true do
        Wait(1)
        local sleep = true
        local playerCoords = GetEntityCoords(PlayerPedId())

        for i=1, #Config.Locations do
            local loc = Config.Locations[i]
            local distance = #(playerCoords - vector3(loc[1], loc[2], loc[3]))
            if distance < 2.5 and not isVisible then
                sleep = false
                DisplayTooltip('Access Outfits')
                if IsControlJustPressed(1, 38) then
                    TriggerEvent('cui_wardrobe:open')
                end
            end
        end

        if sleep then
            Wait(500)
        end
    end
end)

-- Functions

function DisplayTooltip(suffix)
    SetTextComponentFormat('STRING')
    AddTextComponentString('Press ~INPUT_PICKUP~ To ' .. suffix)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function setVisible(visible)
    SetNuiFocus(visible, visible)
    SendNUIMessage({
        action = 'setVisible',
        value = visible
    })
    isVisible = visible
end

function refreshUI()
    local html = ''
    local emptyName = 'Empty slot'
    for i = 1, Config.SlotsNumber do
        if outfits[i] ~= nil then
            -- existing outfit
            local gender = nil
            --if outfits[i].data.sex == 0 then
            if QBCore.Functions.GetPlayerData().charinfo.gender == 0 then
                gender = 'male'
            else
                gender = 'female'
            end

            html = html .. '<div class="slot" data-number="' .. i .. '" data-gender="' .. gender .. '"><span class="slot-text">' .. outfits[i].name ..'</span><div class="controls"><button class="edit"></button><button class="clear"></button></div></div>'
        else
            -- empty slot
            html = html .. '<div class="slot empty" data-number="' .. i .. '"><span class="slot-text">' .. emptyName ..'</span><div class="controls"><button class="edit"></button></div></div>'
        end
    end

    local model = 'unknown'
    if GetEntityModel(PlayerPedId()) == GetHashKey('mp_m_freemode_01') then
        model = 'male'
    elseif GetEntityModel(PlayerPedId()) == GetHashKey('mp_f_freemode_01') then
        model = 'female'
    end

    SendNUIMessage({
        action = 'refresh',
        html = html,
        model = model
    })
end

-- Events

RegisterNetEvent('cui_wardrobe:open')
AddEventHandler('cui_wardrobe:open', function()
    if not isOpening then
        isOpening = true
        isDataLoaded = false
        RequestStreamedTextureDict('shared')
        QBCore.Functions.TriggerCallback('cui_wardrobe:getPlayerOutfits', function(data)
            if data ~= nil then
                outfits = data
            else
                outfits = {}
            end
            isDataLoaded = true
        end)

        while not HasStreamedTextureDictLoaded('shared') or not isDataLoaded do
            Wait(100)
        end

        refreshUI()
        setVisible(true)
        isOpening = false
    end
end)

RegisterNetEvent('cui_wardrobe:close')
AddEventHandler('cui_wardrobe:close', function()
    SetStreamedTextureDictAsNoLongerNeeded('shared')
    setVisible(false)
end)

-- NUI

RegisterNUICallback('close', function(data, cb)
    TriggerEvent('cui_wardrobe:close')
end)

RegisterNUICallback('save', function(data, cb)
    data['clothes'] = nil

    TriggerEvent('cui_character:getCurrentClothes', function(currentClothes)
        data['clothes'] = currentClothes
    end)

    while not data['clothes'] do
        Wait(100)
    end

    QBCore.Functions.TriggerCallback('cui_wardrobe:saveOutfit', function(callback)
        if callback then
            -- TODO: save success
            SendNUIMessage({
                action = 'completeEdit',
                slot = tonumber(data['slot']),
                name = data['name']
            })
        else
            -- TODO: save failure
            print('error: failed saving to the database.')
        end
    end, data)
end)

RegisterNUICallback('clear', function(data, cb)
    QBCore.Functions.TriggerCallback('cui_wardrobe:deleteOutfit', function(callback)
        if callback then
            SendNUIMessage({
                action = 'completeDeletion',
                slot = tonumber(data['slot'])
            })
        else
            SendNUIMessage({
                action = 'abortDeletion',
            })
        end
    end, tonumber(data['slot']))
end)

RegisterNUICallback('load', function(data, cb)
    if not isLoading then
        QBCore.Functions.TriggerCallback('cui_wardrobe:getOutfitInSlot', function(outfit)
            if outfit and outfit['data'] then
                -- Outfit data exists
                TriggerEvent('cui_character:updateClothes', outfit['data'], true, true, function()
                    isLoading = false
                end)
            else
                --Failure
                isLoading = false
            end
        end, tonumber(data['slot']))
    end
end)

RegisterNUICallback('playSound', function(data, cb)
    local sound = data['sound']
    if sound == 'changeoutfit' then
        PlaySoundFrontend(-1, 'Continue_Appears', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', 1)
    elseif sound == 'smallbuttonclick' then
        PlaySoundFrontend( -1, 'HACKING_MOVE_CURSOR', 0, 1 )
    elseif sound == 'panelbuttonclick' then
        PlaySoundFrontend(-1, 'Reset_Prop_Position', 'DLC_Dmod_Prop_Editor_Sounds', 0)
    elseif sound == 'error' then
        PlaySoundFrontend(-1, 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET', 1)
    end
end)