-- lf_trucking / client / nui.lua
NUI = {}

function NUI.Open()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "show"
    })
end

function NUI.Close()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "hide"
    })
end

function NUI.Hide()
    NUI.Close()
end

RegisterNUICallback('close', function(data, cb)
    NUI.Close()
    cb('ok')
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        NUI.Close()
    end
end)

RegisterNetEvent('esx:playerLoaded', function()
    NUI.Close()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    NUI.Close()
end)
