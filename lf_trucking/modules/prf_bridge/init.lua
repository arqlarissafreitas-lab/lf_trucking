-- ==================== PRF BRIDGE ====================
-- Integração com sistema de PRF (opcional)

PRFBridge = {}
PRFBridge.Enabled = Config.PRF.Enabled
PRFBridge.Ready = false

-- Inicializar PRF Bridge
function PRFBridge.Init()
    if not PRFBridge.Enabled then
        print('^3[LF_TRUCKING]^7 PRF Bridge desativado')
        return false
    end
    
    local prfResource = Config.PRF.ResourceName
    
    if GetResourceState(prfResource) ~= 'started' then
        print('^3[LF_TRUCKING]^7 Recurso PRF (' .. prfResource .. ') não encontrado. PRF Bridge desativado.')
        return false
    end
    
    PRFBridge.Ready = true
    print('^2[LF_TRUCKING]^7 PRF Bridge inicializado')
    
    return true
end

-- Verificar se jogador é agente PRF autorizado
function PRFBridge.IsAuthorizedOfficer(source)
    if not PRFBridge.Ready then
        return false
    end
    
    local job = Framework.GetPlayerJob(source)
    
    if not job then
        return false
    end
    
    local prfJobName = Framework.Type == 'esx' and Config.PRF.ESX.JobName or Config.PRF.QBCore.JobName
    
    if job.name ~= prfJobName then
        return false
    end
    
    for _, rank in ipairs(Config.PRF.AuthorizedRanks) do
        if job.grade_name == rank or job.grade == rank then
            return true
        end
    end
    
    return false
end

-- Obter agentes PRF online
function PRFBridge.GetOnlineOfficers()
    if not PRFBridge.Ready then
        return {}
    end
    
    local officers = {}
    
    for source = 1, GetNumPlayerIndices() do
        if GetPlayerName(source) then
            if PRFBridge.IsAuthorizedOfficer(source) then
                table.insert(officers, {
                    source = source,
                    identifier = Framework.GetIdentifier(source),
                    name = Framework.GetName(source),
                })
            end
        end
    end
    
    return officers
end

-- Contar agentes PRF online
function PRFBridge.CountOnlineOfficers()
    return #PRFBridge.GetOnlineOfficers()
end

-- Verificar se PRF disponível para fiscalização
function PRFBridge.IsPRFAvailable()
    if not PRFBridge.Enabled or not PRFBridge.Ready then
        return false
    end
    
    return PRFBridge.CountOnlineOfficers() >= Config.PRF.MinAgentsOnline
end

-- Notificar agentes sobre inspeção solicitada
function PRFBridge.NotifyOfficersInspectionNeeded(deliveryId, vehiclePlate, driverName)
    if not PRFBridge.Ready then
        return false
    end
    
    local officers = PRFBridge.GetOnlineOfficers()
    
    for _, officer in ipairs(officers) do
        TriggerClientEvent('chat:addMessage', officer.source, {
            args = { 'PRF DISPATCH', 'Inspeção solicitada: ' .. vehiclePlate .. ' (' .. driverName .. ')' },
            color = { 255, 0, 0 }
        })
    end
    
    return #officers > 0
end

-- Registrar inspeção pela PRF
function PRFBridge.RegisterInspection(officerSource, deliveryId, result, notes)
    if not PRFBridge.IsAuthorizedOfficer(officerSource) then
        return false, 'not_authorized'
    end
    
    local success = Inspection.Complete(officerSource, deliveryId, result, notes, nil)
    
    return success
end

-- Exportar função para PRF acessar dados
exports('GetInspectionData', function(inspectionId)
    return Inspection.Get(inspectionId)
end)

exports('GetDeliveryForInspection', function(vehiclePlate)
    local query = 'SELECT * FROM trucking_deliveries WHERE vehicle_plate = ? AND status NOT IN ("completed", "cancelled", "failed")'
    local result = MySQL.query.await(query, { vehiclePlate })
    return result and result[1] or nil
end)

print('^2[LF_TRUCKING]^7 PRF Bridge carregado')

return PRFBridge