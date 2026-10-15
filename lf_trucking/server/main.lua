-- ==================== MAIN SERVER FILE ====================
-- Inicialização do servidor

-- Carregar módulos
print('^3[LF_TRUCKING]^7 Iniciando servidor...')

-- Verificar framework
if not Framework.Init() then
    print('^1[LF_TRUCKING] ERRO: Framework não inicializado!^7')
    return
end

-- Aguardar framework ficar pronto
if not Framework.WaitReady() then
    print('^1[LF_TRUCKING] ERRO: Timeout ao aguardar framework!^7')
    return
end

-- Inicializar banco de dados
if not Database.Init() then
    print('^1[LF_TRUCKING] ERRO: Banco de dados não inicializado!^7')
    return
end

-- Carregar checkpoints fiscais
Fiscal.LoadCheckpoints()

-- Recuperar entregas ativas
Deliveries.RecoverActive()

-- Registrar callbacks
RegisterCallbacks()

-- ==================== EVENTOS DO SERVIDOR ====================

-- Evento: Jogador conectado
AddEventHandler('playerJoining', function(source)
    Players.Initialize(source)
end)

-- Evento: Jogador desconectado
AddEventHandler('playerDropped', function(source)
    local identifier = Framework.GetIdentifier(source)
    if identifier then
        Players.Cleanup(identifier)
    end
end)

-- ==================== COMANDOS ====================

-- Comando: Gerar contratos (Admin)
RegisterCommand('trucking:gen_contracts', function(source, args)
    if not Framework.IsAdmin(source) then
        Framework.Notify(source, 'Você não tem permissão.', 'error')
        return
    end
    
    local quantity = tonumber(args[1]) or 5
    Jobs.GenerateMarketContracts(quantity)
    Framework.Notify(source, quantity .. ' contratos gerados!', 'success')
end, false)

-- Comando: Teste de entrega
RegisterCommand('trucking:test_delivery', function(source, args)
    if not Framework.IsAdmin(source) then
        Framework.Notify(source, 'Você não tem permissão.', 'error')
        return
    end
    
    print('^2[LF_TRUCKING]^7 Comando de teste executado')
end, false)

-- Comando: Info
RegisterCommand('trucking:info', function(source)
    TriggerClientEvent('chat:addMessage', source, {
        args = { 'LF_TRUCKING', 'v1.0.0 - Sistema de Caminhoneiros' },
        color = { 0, 255, 0 }
    })
end, false)

-- ==================== TIMERS ====================

-- Timer: Verificar inspeções expiradas (minuto)
SetInterval(function()
    Inspection.CleanupExpired()
end, 60000)

-- Timer: Limpar rate limits (5 minutos)
SetInterval(function()
    local now = Utils.GetTimestampMs()
    for key, timestamp in pairs(Security.RateLimits) do
        if (now - timestamp) > 300000 then
            Security.RateLimits[key] = nil
        end
    end
end, 300000)

-- ==================== EXPORTS ====================

exports('GetPlayerProfile', function(identifier)
    return Players.GetProfile(identifier)
end)

exports('GetDeliveryStatus', function(deliveryId)
    local query = 'SELECT status FROM trucking_deliveries WHERE id = ?'
    local result = MySQL.query.await(query, { deliveryId })
    return result and result[1] and result[1].status or nil
end)

exports('GetDeliveryInvoice', function(deliveryId)
    return Invoices.GetByDelivery(deliveryId)
end)

exports('ValidateDeliveryDocuments', function(deliveryId)
    local delivery = Database.GetDelivery(deliveryId)
    if not delivery then return false end
    
    return delivery.invoice_id ~= nil and delivery.fiscal_status == 'cleared'
end)

exports('GetVehicleActiveDelivery', function(vehicleId)
    local query = 'SELECT * FROM trucking_deliveries WHERE vehicle_id = ? AND status != "completed"'
    local result = MySQL.query.await(query, { vehicleId })
    return result and result[1] or nil
end)

exports('GetFiscalCheckpoint', function(checkpointId)
    return Fiscal.GetCheckpoint(checkpointId)
end)

exports('IsPlayerInDelivery', function(identifier)
    return Players.IsInDelivery(identifier)
end)

exports('GetCompanyData', function(companyId)
    return Companies.GetStatistics(companyId)
end)

print('^2[LF_TRUCKING]^7 Servidor iniciado com sucesso!')