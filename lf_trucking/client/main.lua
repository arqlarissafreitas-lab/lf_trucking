-- ==================== MAIN CLIENT FILE ====================
-- Inicialização do cliente

print('^3[LF_TRUCKING]^7 Cliente iniciando...')

-- Variáveis globais
LocalPlayer = {}
LocalPlayer.Data = {}
LocalPlayer.InDelivery = false
LocalPlayer.CurrentDelivery = nil

-- Aguardar framework
if Config.Framework == 'esx' or (Config.Framework == 'auto' and GetResourceState('es_extended') == 'started') then
    ESX = nil
    TriggerEvent('esx:getSharedObject', function(obj)
        ESX = obj
    end)
    
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function()
        OnPlayerLoaded()
    end)
    
    RegisterNetEvent('esx:onPlayerLogout')
    AddEventHandler('esx:onPlayerLogout', function()
        OnPlayerLogout()
    end)
    
elseif Config.Framework == 'qb' or (Config.Framework == 'auto' and GetResourceState('qb-core') == 'started') then
    QBCore = exports['qb-core']:GetCoreObject()
    
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        OnPlayerLoaded()
    end)
    
    RegisterNetEvent('QBCore:Client:OnPlayerUnload')
    AddEventHandler('QBCore:Client:OnPlayerUnload', function()
        OnPlayerLogout()
    end)
end

-- Callback: Jogador carregado
function OnPlayerLoaded()
    print('^2[LF_TRUCKING]^7 Jogador carregado')
    
    NUI.LoadDashboard()
end

-- Callback: Jogador desconectado
function OnPlayerLogout()
    print('^2[LF_TRUCKING]^7 Jogador desconectado')
    
    LocalPlayer.Data = {}
    LocalPlayer.InDelivery = false
    LocalPlayer.CurrentDelivery = nil
    
    if NUI.IsOpen then
        NUI.Close()
    end
end

-- ==================== COMANDOS ====================

RegisterCommand('trucking', function()
    NUI.Open()
end, false)

RegisterCommand('trucking:info', function()
    TriggerEvent('chat:addMessage', {
        args = { 'Trucking', 'Use /trucking para abrir o menu' },
        color = { 0, 255, 0 }
    })
end, false)

-- ==================== KEY BINDINGS ====================

RegisterKeyMapping('trucking', 'Abrir menu de caminhoneiro', 'keyboard', 'F8')

-- Fechar menu com ESC
RegisterNUICallback('close', function(data, cb)
    NUI.Close()
    cb('ok')
end)

-- ==================== CALLBACKS ====================

function TriggerServerCallback(name, cb, ...)
    local args = {...}
    TriggerServerEvent('lf_trucking:serverCallback', name, args, function(result)
        cb(result)
    end)
end

print('^2[LF_TRUCKING]^7 Cliente inicializado com sucesso!')