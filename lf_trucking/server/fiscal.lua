-- ==================== FISCAL MANAGEMENT ====================
-- Gerenciamento de checkpoints fiscais

Fiscal = {}
Fiscal.Checkpoints = {}

-- Inicializar checkpoints
function Fiscal.LoadCheckpoints()
    local query = 'SELECT * FROM trucking_fiscal_checkpoints WHERE is_active = TRUE'
    local results = MySQL.query.await(query, {})
    
    if results then
        for _, checkpoint in ipairs(results) do
            Fiscal.Checkpoints[checkpoint.checkpoint_id] = checkpoint
        end
    end
    
    print('^2[LF_TRUCKING]^7 ' .. #Fiscal.Checkpoints .. ' postos fiscais carregados')
end

-- Obter checkpoint
function Fiscal.GetCheckpoint(checkpointId)
    return Fiscal.Checkpoints[checkpointId]
end

-- Processar passagem por checkpoint
function Fiscal.ProcessCheckpoint(deliveryId, checkpointId, vehicleNetId)
    local checkpoint = Fiscal.GetCheckpoint(checkpointId)
    
    if not checkpoint then
        return false, 'checkpoint_not_found'
    end
    
    -- Obter entrega
    local deliveryQuery = 'SELECT * FROM trucking_deliveries WHERE id = ?'
    local deliveryResult = MySQL.query.await(deliveryQuery, { deliveryId })
    
    if not deliveryResult or #deliveryResult == 0 then
        return false, 'delivery_not_found'
    end
    
    local delivery = deliveryResult[1]
    
    -- Verificações
    if checkpoint.requires_invoice and (not delivery.invoice_id or delivery.fiscal_status ~= 'cleared') then
        return false, 'invoice_required'
    end
    
    if checkpoint.requires_prf_agent then
        -- Verificar se PRF disponível
        if Config.PRF.Enabled and Config.PRF.MinAgentsOnline > 0 then
            -- Lógica de PRF será implementada no módulo PRF Bridge
            if Config.PRF.NoAgentMode == 'block' then
                return false, 'prf_required'
            end
        end
    end
    
    -- Atualizar checkpoint
    local updateQuery = [[
        UPDATE trucking_deliveries
        SET current_checkpoint = current_checkpoint + 1, last_checkpoint_passed_at = NOW()
        WHERE id = ?
    ]]
    
    MySQL.update.await(updateQuery, { deliveryId })
    
    -- Log auditoria
    Database.LogAudit(
        'checkpoint_passed',
        delivery.player_identifier,
        delivery.player_name,
        'checkpoint_' .. checkpointId,
        'checkpoint',
        checkpoint.id,
        { delivery_id = deliveryId },
        'approaching',
        'passed'
    )
    
    return true, checkpoint
end

-- Liberar checkpoint (fiscalização automática)
function Fiscal.ApproveCheckpoint(deliveryId)
    local updateQuery = [[
        UPDATE trucking_deliveries
        SET status = 'in_transit', fiscal_status = 'cleared'
        WHERE id = ?
    ]]
    
    MySQL.update.await(updateQuery, { deliveryId })
    
    return true
end

-- Bloquear checkpoint
function Fiscal.BlockCheckpoint(deliveryId, reason)
    local updateQuery = [[
        UPDATE trucking_deliveries
        SET status = 'blocked', fiscal_status = 'rejected'
        WHERE id = ?
    ]]
    
    MySQL.update.await(updateQuery, { deliveryId })
    
    Database.LogAudit(
        'checkpoint_blocked',
        'fiscal_system',
        'Fiscal System',
        'delivery_' .. deliveryId,
        'delivery',
        deliveryId,
        { reason = reason },
        'checkpoint_pending',
        'blocked'
    )
    
    return true
end

-- Verificar se checkpoint é obrigatório
function Fiscal.IsCheckpointMandatory(checkpointId)
    local checkpoint = Fiscal.GetCheckpoint(checkpointId)
    return checkpoint and checkpoint.is_mandatory or false
end

return Fiscal