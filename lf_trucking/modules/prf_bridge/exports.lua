-- ==================== PRF EXPORTS ====================
-- Exports públicos para integração com PRF

-- Obter informações de entrega para inspeção
exports('GetDeliveryInspectionData', function(deliveryId)
    local deliveryQuery = 'SELECT * FROM trucking_deliveries WHERE id = ?'
    local deliveryResult = MySQL.query.await(deliveryQuery, { deliveryId })
    
    if not deliveryResult or #deliveryResult == 0 then
        return nil
    end
    
    local delivery = deliveryResult[1]
    
    -- Obter contrato
    local contractQuery = 'SELECT * FROM trucking_contracts WHERE id = ?'
    local contractResult = MySQL.query.await(contractQuery, { delivery.contract_id })
    local contract = contractResult and contractResult[1] or nil
    
    -- Obter nota fiscal
    local invoiceQuery = 'SELECT * FROM trucking_invoices WHERE delivery_id = ?'
    local invoiceResult = MySQL.query.await(invoiceQuery, { deliveryId })
    local invoice = invoiceResult and invoiceResult[1] or nil
    
    return {
        delivery = delivery,
        contract = contract,
        invoice = invoice,
    }
end)

-- Iniciar inspeção rodoviária
exports('StartRoadInspection', function(officerSource, vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    
    if not vehicle or not DoesEntityExist(vehicle) then
        return false, 'vehicle_not_found'
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    
    -- Procurar entrega ativa com essa placa
    local deliveryQuery = 'SELECT * FROM trucking_deliveries WHERE vehicle_plate = ? AND status NOT IN ("completed", "cancelled", "failed", "blocked")'
    local deliveryResult = MySQL.query.await(deliveryQuery, { plate })
    
    if not deliveryResult or #deliveryResult == 0 then
        return false, 'no_active_delivery'
    end
    
    local delivery = deliveryResult[1]
    
    -- Iniciar inspeção
    local success, inspection = Inspection.Start(officerSource, delivery.id)
    
    if success then
        return true, inspection
    end
    
    return false, 'inspection_start_failed'
end)

-- Completar inspeção rodoviária
exports('CompleteRoadInspection', function(officerSource, inspectionId, result, notes, administrativeMeasure)
    if not PRFBridge.IsAuthorizedOfficer(officerSource) then
        return false, 'not_authorized'
    end
    
    if not TRUCKING.INSPECTION_RESULTS[result] then
        return false, 'invalid_result'
    end
    
    local success = Inspection.Complete(officerSource, inspectionId, result, notes or '', administrativeMeasure or nil)
    
    return success
end)

-- Obter histórico de inspeções
exports('GetInspectionHistory', function(deliveryId)
    return Inspection.GetHistory(deliveryId)
end)

-- Bloquear entrega por irregularidade
exports('BlockDeliveryForIrregularity', function(officerSource, deliveryId, reason)
    if not PRFBridge.IsAuthorizedOfficer(officerSource) then
        return false, 'not_authorized'
    end
    
    Deliveries.Block(deliveryId, reason or 'Bloqueado pela PRF')
    
    return true
end)

-- Obter agentes PRF online
exports('GetOnlinePRFOfficers', function()
    return PRFBridge.GetOnlineOfficers()
end)

-- Contar agentes PRF
exports('GetPRFOfficerCount', function()
    return PRFBridge.CountOnlineOfficers()
end)

print('^2[LF_TRUCKING]^7 PRF Exports carregados')

return true