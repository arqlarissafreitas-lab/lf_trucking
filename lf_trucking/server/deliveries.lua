-- ==================== DELIVERY MANAGEMENT ====================
-- Gerenciamento de entregas em tempo real

Deliveries = {}
Deliveries.Active = {}

-- Inicializar entrega
function Deliveries.Start(source, vehicleNetId)
    local identifier = Framework.GetIdentifier(source)
    
    if not identifier then
        return false, 'invalid_player'
    end
    
    -- Obter entrega ativa
    local delivery = Players.GetActiveDelivery(identifier)
    
    if not delivery then
        return false, 'no_active_delivery'
    end
    
    if delivery.status ~= 'accepted' then
        return false, 'invalid_state'
    end
    
    -- Registrar entrega ativa
    Deliveries.Active[delivery.delivery_uuid] = {
        id = delivery.id,
        player_identifier = identifier,
        vehicle_net_id = vehicleNetId,
        contract_id = delivery.contract_id,
        status = delivery.status,
        started_at = os.time(),
        last_position = nil,
        distance_traveled = 0,
    }
    
    -- Atualizar entrega
    Database.UpdateDeliveryStatus(delivery.id, 'in_transit')
    
    local updateQuery = 'UPDATE trucking_deliveries SET started_at = NOW() WHERE id = ?'
    MySQL.update.await(updateQuery, { delivery.id })
    
    return true, delivery
end

-- Rastrear posição
function Deliveries.TrackPosition(source, deliveryUUID, currentX, currentY, currentZ)
    local delivery = Deliveries.Active[deliveryUUID]
    
    if not delivery then
        return false
    end
    
    local currentPosition = { x = currentX, y = currentY, z = currentZ }
    
    if delivery.last_position then
        local distance = Utils.Distance(
            delivery.last_position.x, delivery.last_position.y, delivery.last_position.z,
            currentX, currentY, currentZ
        )
        delivery.distance_traveled = delivery.distance_traveled + distance
    end
    
    delivery.last_position = currentPosition
    
    return true
end

-- Verificar checkpoint
function Deliveries.CheckCheckpoint(deliveryUUID, checkpointId)
    local delivery = Deliveries.Active[deliveryUUID]
    
    if not delivery then
        return false, 'delivery_not_found'
    end
    
    -- Obter checkpoint
    local checkpointQuery = 'SELECT * FROM trucking_fiscal_checkpoints WHERE checkpoint_id = ?'
    local checkpointResult = MySQL.query.await(checkpointQuery, { checkpointId })
    
    if not checkpointResult or #checkpointResult == 0 then
        return false, 'checkpoint_not_found'
    end
    
    local checkpoint = checkpointResult[1]
    
    -- Atualizar entrega
    Database.UpdateDeliveryStatus(delivery.id, 'checkpoint_pending')
    
    local updateQuery = [[
        UPDATE trucking_deliveries
        SET current_checkpoint = current_checkpoint + 1, last_checkpoint_passed_at = NOW()
        WHERE id = ?
    ]]
    
    MySQL.update.await(updateQuery, { delivery.id })
    
    return true, checkpoint
end

-- Solicitar liberação fiscal
function Deliveries.RequestFiscalClearance(deliveryUUID)
    local delivery = Deliveries.Active[deliveryUUID]
    
    if not delivery then
        return false, 'delivery_not_found'
    end
    
    -- Verificar invoice
    local invoiceQuery = 'SELECT * FROM trucking_invoices WHERE delivery_id = ?'
    local invoiceResult = MySQL.query.await(invoiceQuery, { delivery.id })
    
    if not invoiceResult or #invoiceResult == 0 then
        return false, 'invoice_required'
    end
    
    local invoice = invoiceResult[1]
    
    if invoice.status ~= 'issued' then
        return false, 'invoice_not_issued'
    end
    
    -- Atualizar status
    Database.UpdateDeliveryStatus(delivery.id, 'fiscal_clearance_pending')
    
    return true
end

-- Liberar entrega fiscalmente (automático)
function Deliveries.ApproveFiscal(deliveryId)
    local query = 'SELECT * FROM trucking_deliveries WHERE id = ?'
    local result = MySQL.query.await(query, { deliveryId })
    
    if not result or #result == 0 then
        return false
    end
    
    local delivery = result[1]
    
    -- Atualizar invoice
    local invoiceQuery = 'UPDATE trucking_invoices SET status = "cleared" WHERE delivery_id = ?'
    MySQL.update.await(invoiceQuery, { deliveryId })
    
    -- Atualizar entrega
    Database.UpdateDeliveryStatus(deliveryId, 'delivery_ready')
    
    local updateQuery = 'UPDATE trucking_deliveries SET fiscal_status = "cleared" WHERE id = ?'
    MySQL.update.await(updateQuery, { deliveryId })
    
    return true
end

-- Bloquear entrega
function Deliveries.Block(deliveryId, reason)
    local query = 'UPDATE trucking_deliveries SET status = "blocked", fiscal_status = "rejected" WHERE id = ?'
    MySQL.update.await(query, { deliveryId })
    
    Database.LogAudit(
        'delivery_blocked',
        'system',
        'Fiscal System',
        'delivery_' .. deliveryId,
        'delivery',
        deliveryId,
        { reason = reason },
        'in_transit',
        'blocked'
    )
    
    return true
end

-- Falhar entrega
function Deliveries.Fail(deliveryId, reason)
    local query = 'UPDATE trucking_deliveries SET status = "failed" WHERE id = ?'
    MySQL.update.await(query, { deliveryId })
    
    Database.LogAudit(
        'delivery_failed',
        'system',
        'System',
        'delivery_' .. deliveryId,
        'delivery',
        deliveryId,
        { reason = reason },
        'in_transit',
        'failed'
    )
    
    return true
end

-- Limpar entrega ativa
function Deliveries.Cleanup(deliveryUUID)
    Deliveries.Active[deliveryUUID] = nil
end

-- Recuperar entregas ativas (pós-reinício)
function Deliveries.RecoverActive()
    local query = [[
        SELECT * FROM trucking_deliveries
        WHERE status NOT IN ('completed', 'cancelled', 'failed', 'blocked')
        AND updated_at > DATE_SUB(NOW(), INTERVAL 30 MINUTE)
    ]]
    
    local results = MySQL.query.await(query, {})
    local recovered = 0
    
    if results then
        for _, delivery in ipairs(results) do
            Deliveries.Active[delivery.delivery_uuid] = {
                id = delivery.id,
                player_identifier = delivery.player_identifier,
                contract_id = delivery.contract_id,
                status = delivery.status,
                recovered = true,
            }
            recovered = recovered + 1
        end
    end
    
    print('^2[LF_TRUCKING]^7 ' .. recovered .. ' entregas recuperadas')
    
    return recovered
end

return Deliveries