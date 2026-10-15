-- ==================== INSPECTION MANAGEMENT ====================
-- Gerenciamento de inspeções rodoviárias (PRF)

Inspection = {}
Inspection.ActiveInspections = {}

-- Iniciar inspeção
function Inspection.Start(officerSource, deliveryId)
    local officerIdentifier = Framework.GetIdentifier(officerSource)
    local officerName = Framework.GetName(officerSource)
    
    if not officerIdentifier then
        return false, 'invalid_officer'
    end
    
    -- Verificar permissão (PRF)
    if Config.PRF.Enabled then
        local job = Framework.GetPlayerJob(officerSource)
        
        if not job or job.name ~= Config.PRF.ESX.JobName then
            return false, 'not_authorized'
        end
    end
    
    -- Obter entrega
    local deliveryQuery = 'SELECT * FROM trucking_deliveries WHERE id = ?'
    local deliveryResult = MySQL.query.await(deliveryQuery, { deliveryId })
    
    if not deliveryResult or #deliveryResult == 0 then
        return false, 'delivery_not_found'
    end
    
    local delivery = deliveryResult[1]
    
    -- Obter invoice
    local invoiceQuery = 'SELECT * FROM trucking_invoices WHERE delivery_id = ?'
    local invoiceResult = MySQL.query.await(invoiceQuery, { deliveryId })
    
    local invoice = invoiceResult and invoiceResult[1] or nil
    
    -- Criar inspeção
    local inspection = Database.CreateInspection(
        deliveryId,
        nil,
        officerIdentifier,
        officerName,
        Framework.GetPlayerJob(officerSource) and Framework.GetPlayerJob(officerSource).grade_name or 'Agente',
        delivery.vehicle_plate,
        delivery.player_identifier,
        delivery.player_name
    )
    
    if inspection then
        -- Registrar inspeção ativa
        Inspection.ActiveInspections[inspection.id] = {
            delivery_id = deliveryId,
            officer_identifier = officerIdentifier,
            started_at = os.time(),
            timeout = os.time() + 300000,
        }
        
        -- Log auditoria
        Database.LogAudit(
            'inspection_started',
            officerIdentifier,
            officerName,
            'delivery_' .. delivery.delivery_uuid,
            'delivery',
            deliveryId,
            { inspection_id = inspection.id },
            delivery.status,
            'inspection_active'
        )
        
        return true, inspection
    end
    
    return false, 'inspection_creation_failed'
end

-- Concluir inspeção
function Inspection.Complete(officerSource, inspectionId, result, notes, administrativeMeasure)
    local officerIdentifier = Framework.GetIdentifier(officerSource)
    
    if not officerIdentifier then
        return false, 'invalid_officer'
    end
    
    -- Verificar permissão
    if Config.PRF.Enabled then
        local job = Framework.GetPlayerJob(officerSource)
        
        if not job or job.name ~= Config.PRF.ESX.JobName then
            return false, 'not_authorized'
        end
    end
    
    -- Validar resultado
    if not TRUCKING.INSPECTION_RESULTS[result] then
        return false, 'invalid_result'
    end
    
    -- Obter inspeção
    local inspectionQuery = 'SELECT * FROM trucking_inspections WHERE id = ?'
    local inspectionResult = MySQL.query.await(inspectionQuery, { inspectionId })
    
    if not inspectionResult or #inspectionResult == 0 then
        return false, 'inspection_not_found'
    end
    
    local inspection = inspectionResult[1]
    local delivery_id = inspection.delivery_id
    
    -- Determinar se entrega será bloqueada
    local deliveryBlocked = false
    
    if result == TRUCKING.INSPECTION_RESULTS.MISSING_INVOICE or
       result == TRUCKING.INSPECTION_RESULTS.INVALID_INVOICE or
       result == TRUCKING.INSPECTION_RESULTS.DOCUMENT_MISMATCH then
        deliveryBlocked = true
    end
    
    -- Atualizar inspeção
    Database.CompleteInspection(inspectionId, result, notes, administrativeMeasure, deliveryBlocked)
    
    -- Atualizar entrega se necessário
    if deliveryBlocked then
        Deliveries.Block(delivery_id, 'Irregular encontrada em inspeção rodoviária')
    else
        -- Aprovar entrega
        Deliveries.ApproveFiscal(delivery_id)
    end
    
    -- Remover inspeção ativa
    Inspection.ActiveInspections[inspectionId] = nil
    
    -- Log auditoria
    Database.LogAudit(
        'inspection_completed',
        officerIdentifier,
        Framework.GetName(officerSource),
        'inspection_' .. inspection.inspection_uuid,
        'inspection',
        inspectionId,
        { result = result, administrative_measure = administrativeMeasure },
        'active',
        'completed'
    )
    
    return true
end

-- Obter inspeção
function Inspection.Get(inspectionId)
    local query = 'SELECT * FROM trucking_inspections WHERE id = ?'
    local result = MySQL.query.await(query, { inspectionId })
    return result and result[1] or nil
end

-- Obter histórico de inspeções
function Inspection.GetHistory(deliveryId)
    local query = 'SELECT * FROM trucking_inspections WHERE delivery_id = ? ORDER BY inspected_at DESC'
    local result = MySQL.query.await(query, { deliveryId })
    return result or {}
end

-- Limpar inspeções expiradas
function Inspection.CleanupExpired()
    local now = os.time()
    local expired = {}
    
    for inspectionId, inspection in pairs(Inspection.ActiveInspections) do
        if now > inspection.timeout then
            table.insert(expired, inspectionId)
        end
    end
    
    for _, inspectionId in ipairs(expired) do
        Inspection.ActiveInspections[inspectionId] = nil
        print('^3[LF_TRUCKING]^7 Inspeção ' .. inspectionId .. ' expirada')
    end
    
    return #expired
end

return Inspection