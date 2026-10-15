-- ==================== FRAMEWORK ADAPTER ====================
-- Abstração para ESX e QBCore

Framework = {}
Framework.Type = nil
Framework.Ready = false

-- Detectar framework automaticamente
function Framework.Init()
    if Config.Framework == 'auto' then
        if GetResourceState('es_extended') == 'started' then
            Framework.Type = 'esx'
            TriggerEvent('esx:getSharedObject', function(obj)
                Framework.ESX = obj
                Framework.Ready = true
                print('^2[LF_TRUCKING]^7 ESX Framework detectado e inicializado')
            end)
        elseif GetResourceState('qb-core') == 'started' then
            Framework.Type = 'qb'
            Framework.QBCore = exports['qb-core']:GetCoreObject()
            Framework.Ready = true
            print('^2[LF_TRUCKING]^7 QBCore Framework detectado e inicializado')
        else
            print('^1[LF_TRUCKING] ERRO: Nenhum framework detectado!^7')
            return false
        end
    elseif Config.Framework == 'esx' then
        Framework.Type = 'esx'
        TriggerEvent('esx:getSharedObject', function(obj)
            Framework.ESX = obj
            Framework.Ready = true
            print('^2[LF_TRUCKING]^7 ESX Framework inicializado')
        end)
    elseif Config.Framework == 'qb' then
        Framework.Type = 'qb'
        Framework.QBCore = exports['qb-core']:GetCoreObject()
        Framework.Ready = true
        print('^2[LF_TRUCKING]^7 QBCore Framework inicializado')
    end
    
    return Framework.Ready
end

-- ==================== FUNÇÕES GENÉRICAS ====================

-- Aguardar framework estar pronto
function Framework.WaitReady(timeout)
    timeout = timeout or 5000
    local startTime = GetGameTimer()
    while not Framework.Ready and (GetGameTimer() - startTime) < timeout do
        Wait(100)
    end
    return Framework.Ready
end

-- Obter jogador ESX/QBCore
function Framework.GetPlayer(source)
    if Framework.Type == 'esx' then
        return Framework.ESX.GetPlayerFromId(source)
    elseif Framework.Type == 'qb' then
        return Framework.QBCore.Functions.GetPlayer(source)
    end
    return nil
end

-- Obter identificador único do jogador
function Framework.GetIdentifier(source)
    local player = Framework.GetPlayer(source)
    if not player then return nil end
    
    if Framework.Type == 'esx' then
        return player.identifier
    elseif Framework.Type == 'qb' then
        return player.PlayerData.citizenid
    end
    return nil
end

-- Obter nome do jogador
function Framework.GetName(source)
    local player = Framework.GetPlayer(source)
    if not player then return 'Unknown' end
    
    if Framework.Type == 'esx' then
        return player.getName()
    elseif Framework.Type == 'qb' then
        return player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    end
    return 'Unknown'
end

-- Obter dinheiro em banco
function Framework.GetBankMoney(source)
    local player = Framework.GetPlayer(source)
    if not player then return 0 end
    
    if Framework.Type == 'esx' then
        return player.getAccount('bank').money
    elseif Framework.Type == 'qb' then
        return player.PlayerData.money['bank']
    end
    return 0
end

-- Obter dinheiro em mão
function Framework.GetCashMoney(source)
    local player = Framework.GetPlayer(source)
    if not player then return 0 end
    
    if Framework.Type == 'esx' then
        return player.getAccount('cash').money
    elseif Framework.Type == 'qb' then
        return player.PlayerData.money['cash']
    end
    return 0
end

-- Remover dinheiro
function Framework.RemoveMoney(source, amount, account)
    account = account or 'bank'
    local player = Framework.GetPlayer(source)
    if not player then return false end
    
    if Framework.Type == 'esx' then
        if account == 'bank' then
            player.removeAccountMoney('bank', amount)
        else
            player.removeMoney(amount)
        end
        return true
    elseif Framework.Type == 'qb' then
        player.Functions.RemoveMoney(account, amount, 'trucking_payment')
        return true
    end
    return false
end

-- Adicionar dinheiro
function Framework.AddMoney(source, amount, account)
    account = account or 'bank'
    local player = Framework.GetPlayer(source)
    if not player then return false end
    
    if Framework.Type == 'esx' then
        if account == 'bank' then
            player.addAccountMoney('bank', amount)
        else
            player.addMoney(amount)
        end
        return true
    elseif Framework.Type == 'qb' then
        player.Functions.AddMoney(account, amount, 'trucking_payment')
        return true
    end
    return false
end

-- Verificar emprego (para PRF)
function Framework.GetPlayerJob(source)
    local player = Framework.GetPlayer(source)
    if not player then return nil end
    
    if Framework.Type == 'esx' then
        return {
            name = player.getJob().name,
            grade = player.getJob().grade,
            grade_name = player.getJob().grade_label,
        }
    elseif Framework.Type == 'qb' then
        return {
            name = player.PlayerData.job.name,
            grade = player.PlayerData.job.grade.level,
            grade_name = player.PlayerData.job.grade.name,
        }
    end
    return nil
end

-- Verificar se jogador está autorizado em grupo
function Framework.HasPlayerGroup(source, groupName)
    local player = Framework.GetPlayer(source)
    if not player then return false end
    
    if Framework.Type == 'esx' then
        local job = player.getJob()
        return job and job.name == groupName
    elseif Framework.Type == 'qb' then
        return player.PlayerData.job.name == groupName
    end
    return false
end

-- Notificar jogador
function Framework.Notify(source, message, type, duration)
    type = type or 'info'
    duration = duration or 5000
    
    if Config.Notification.Type == 'native' then
        TriggerClientEvent('chat:addMessage', source, {
            args = { 'Trucking', message },
            color = { 255, 165, 0 }
        })
    elseif Config.Notification.Type == 'ox_lib' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Trucking',
            description = message,
            type = type,
            duration = duration,
            position = Config.Notification.Position
        })
    elseif Config.Notification.Type == 'esx_notify' and Framework.Type == 'esx' then
        TriggerClientEvent('esx:showNotification', source, message)
    elseif Config.Notification.Type == 'qb_notify' and Framework.Type == 'qb' then
        TriggerClientEvent('QBCore:Notify', source, message, type, duration)
    else
        -- Fallback
        TriggerClientEvent('chat:addMessage', source, {
            args = { 'Trucking', message },
            color = { 255, 165, 0 }
        })
    end
end

-- Verificar permissão (admin)
function Framework.IsAdmin(source)
    local player = Framework.GetPlayer(source)
    if not player then return false end
    
    if Framework.Type == 'esx' then
        return player.getPermission() and player.getPermission() ~= 'user'
    elseif Framework.Type == 'qb' then
        return player.PlayerData.group ~= 'user'
    end
    return false
end

-- ==================== CALLBACKS ====================

-- Registrar callback de servidor
function Framework.RegisterCallback(name, callback)
    if Framework.Type == 'esx' then
        ESX.RegisterServerCallback(name, callback)
    elseif Framework.Type == 'qb' then
        local QBCore = Framework.QBCore
        QBCore.Functions.CreateCallback(name, callback)
    end
end

return Framework