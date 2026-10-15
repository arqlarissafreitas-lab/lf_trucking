-- ==================== JOB/CONTRACT MANAGEMENT ====================
-- Gerenciamento de contratos e fretes

Jobs = {}
Jobs.Cache = {}

-- Gerar contratos para o mercado
function Jobs.GenerateMarketContracts(quantity)
    quantity = quantity or 5
    
    local locations = Config.Locations
    local cargoTypes = Config.CargoTypes
    local companies = MySQL.query.await('SELECT id FROM trucking_companies LIMIT 5', {})
    
    if not companies or #companies == 0 then
        print('^1[LF_TRUCKING] Nenhuma empresa disponível para gerar contratos^7')
        return false
    end
    
    for i = 1, quantity do
        local companyId = companies[math.random(1, #companies)].id
        local cargoType = cargoTypes[math.random(1, #cargoTypes)]
        local contractNumber = 'CT-' .. os.date('%Y%m%d') .. string.format('%04d', i)
        
        local baseReward = cargoType.base_weight * cargoType.value_per_unit
        local timeBonus = math.floor(baseReward * 0.15)
        
        local query = [[
            INSERT INTO trucking_contracts
            (contract_number, company_id, shipper_name, origin_name, origin_x, origin_y, origin_z,
             destination_name, dest_x, dest_y, dest_z, estimated_distance, estimated_time_hours,
             cargo_type, cargo_weight, cargo_value, is_fragile, requires_certification,
             base_reward, time_bonus, difficulty_multiplier, status, expires_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]]
        
        local expiresAt = os.time() + (48 * 3600) -- 48 horas
        
        local params = {
            contractNumber,
            companyId,
            'Remetente ' .. i,
            'Origem ' .. i,
            math.random(100, 900),
            math.random(100, 900),
            10.0,
            'Destino ' .. i,
            math.random(100, 900),
            math.random(100, 900),
            10.0,
            math.random(50, 500),
            math.random(2, 24),
            cargoType.id,
            cargoType.base_weight,
            baseReward,
            cargoType.damage_multiplier > 2.0 or false,
            cargoType.special_requirement,
            baseReward,
            timeBonus,
            1.0,
            'available',
            expiresAt
        }
        
        MySQL.insert.await(query, params)
    end
    
    print('^2[LF_TRUCKING]^7 ' .. quantity .. ' contratos gerados')
    return true
end

-- Obter contratos disponíveis
function Jobs.GetAvailable(limit)
    limit = limit or 10
    return Database.GetAvailableContracts(limit)
end

-- Obter contrato
function Jobs.Get(contractId)
    if Jobs.Cache[contractId] then
        return Jobs.Cache[contractId]
    end
    
    local contract = Database.GetContract(contractId)
    if contract then
        Jobs.Cache[contractId] = contract
    end
    
    return contract
end

-- Aceitar contrato
function Jobs.Accept(source, contractId)
    local identifier = Framework.GetIdentifier(source)
    
    if not identifier then
        return false, 'invalid_player'
    end
    
    -- Obter contrato
    local contract = Jobs.Get(contractId)
    
    if not contract then
        return false, 'contract_not_found'
    end
    
    if contract.status ~= 'available' then
        return false, 'contract_not_available'
    end
    
    if contract.expires_at < os.time() then
        return false, 'contract_expired'
    end
    
    -- Obter perfil do jogador
    local profile = Players.GetProfile(identifier)
    
    if not profile then
        return false, 'player_not_found'
    end
    
    -- Verificar nível
    if profile.level < 1 then
        return false, 'insufficient_level'
    end
    
    -- Verificar certificação
    if contract.requires_certification then
        local hasCert = Database.HasCertification(identifier, contract.requires_certification)
        if not hasCert then
            return false, 'missing_certification'
        end
    end
    
    -- Verificar se já está em entrega
    if Players.IsInDelivery(identifier) then
        return false, 'already_in_delivery'
    end
    
    -- Criar entrega
    local delivery = Database.CreateDelivery(
        contractId,
        identifier,
        profile.player_name,
        'unknown_vehicle',
        'UNKNOWN',
        profile.company_id
    )
    
    if delivery then
        -- Atualizar contrato para ativo
        local updateQuery = 'UPDATE trucking_contracts SET status = "active" WHERE id = ?'
        MySQL.update.await(updateQuery, { contractId })
        
        -- Log auditoria
        Database.LogAudit(
            'delivery_accepted',
            identifier,
            profile.player_name,
            'delivery_' .. delivery.delivery_uuid,
            'delivery',
            delivery.id,
            { contract_id = contractId },
            'available',
            'accepted'
        )
        
        Framework.Notify(source, 'Contrato aceito! Selecione um veículo.', 'success', 5000)
        
        return true, delivery
    end
    
    return false, 'accept_failed'
end

-- Cancelar contrato
function Jobs.Cancel(source, deliveryId, reason)
    local identifier = Framework.GetIdentifier(source)
    
    if not identifier then
        return false, 'invalid_player'
    end
    
    -- Obter entrega
    local deliveryQuery = 'SELECT * FROM trucking_deliveries WHERE id = ? AND player_identifier = ?'
    local deliveryResult = MySQL.query.await(deliveryQuery, { deliveryId, identifier })
    
    if not deliveryResult or #deliveryResult == 0 then
        return false, 'delivery_not_found'
    end
    
    local delivery = deliveryResult[1]
    
    if delivery.status == 'completed' or delivery.status == 'failed' or delivery.status == 'cancelled' then
        return false, 'invalid_state'
    end
    
    -- Atualizar delivery
    local updateQuery = 'UPDATE trucking_deliveries SET status = "cancelled" WHERE id = ?'
    MySQL.update.await(updateQuery, { deliveryId })
    
    -- Log auditoria
    Database.LogAudit(
        'delivery_cancelled',
        identifier,
        '',
        'delivery_' .. delivery.delivery_uuid,
        'delivery',
        delivery.id,
        { reason = reason },
        delivery.status,
        'cancelled'
    )
    
    Framework.Notify(source, 'Entrega cancelada.', 'info', 5000)
    
    return true
end

-- Obter entrega
function Jobs.GetDelivery(deliveryUUID)
    local delivery = Database.GetDelivery(deliveryUUID)
    return delivery
end

-- Atualizar status da entrega
function Jobs.UpdateStatus(deliveryId, newStatus)
    Database.UpdateDeliveryStatus(deliveryId, newStatus)
    return true
end

-- Completar entrega
function Jobs.Complete(source, deliveryId)
    local identifier = Framework.GetIdentifier(source)
    
    if not identifier then
        return false, 'invalid_player'
    end
    
    -- Obter entrega
    local deliveryQuery = 'SELECT * FROM trucking_deliveries WHERE id = ? AND player_identifier = ?'
    local deliveryResult = MySQL.query.await(deliveryQuery, { deliveryId, identifier })
    
    if not deliveryResult or #deliveryResult == 0 then
        return false, 'delivery_not_found'
    end
    
    local delivery = deliveryResult[1]
    
    -- Validações
    if delivery.status ~= 'delivery_ready' then
        return false, 'invalid_state'
    end
    
    if delivery.is_paid then
        return false, 'payment_already_made'
    end
    
    -- Obter contrato
    local contract = Jobs.Get(delivery.contract_id)
    if not contract then
        return false, 'contract_not_found'
    end
    
    -- Obter invoice
    local invoiceQuery = 'SELECT * FROM trucking_invoices WHERE delivery_id = ?'
    local invoiceResult = MySQL.query.await(invoiceQuery, { deliveryId })
    
    if not invoiceResult or #invoiceResult == 0 then
        return false, 'invoice_required'
    end
    
    local invoice = invoiceResult[1]
    
    if invoice.status ~= 'cleared' then
        return false, 'fiscal_clearance_required'
    end
    
    -- Calcular pagamento
    local payment = Jobs.CalculatePayment(delivery, contract)
    local xp = Jobs.CalculateXP(delivery, contract)
    
    -- Iniciar transação
    local transactionSuccess = false
    
    -- Processar pagamento em transação
    local profile = Players.GetProfile(identifier)
    
    if profile then
        -- Remover taxa operacional
        local operationalCost = math.floor(payment * 0.1) -- 10%
        local finalPayment = payment - operationalCost
        
        -- Adicionar dinheiro ao jogador
        Players.AddMoney(identifier, finalPayment, 'delivery_payment')
        
        -- Adicionar XP
        Players.AddXP(identifier, xp)
        
        -- Atualizar entrega
        Database.CompleteDelivery(deliveryId, finalPayment, xp)
        
        -- Atualizar estatísticas do jogador
        local updatePlayerQuery = [[
            UPDATE trucking_players SET
            total_deliveries = total_deliveries + 1,
            completed_deliveries = completed_deliveries + 1,
            total_distance = total_distance + ?,
            money_earned = money_earned + ?,
            updated_at = NOW()
            WHERE identifier = ?
        ]]
        
        MySQL.update.await(updatePlayerQuery, { contract.estimated_distance, finalPayment, identifier })
        
        -- Log auditoria
        Database.LogAudit(
            'delivery_completed',
            identifier,
            profile.player_name,
            'delivery_' .. delivery.delivery_uuid,
            'delivery',
            delivery.id,
            { payment = finalPayment, xp = xp, contract_id = contract.id },
            'delivery_ready',
            'completed'
        )
        
        transactionSuccess = true
    end
    
    if transactionSuccess then
        Framework.Notify(source, 'Entrega concluída! Você recebeu: ' .. Utils.FormatMoney(payment), 'success', 5000)
        return true, { payment = payment, xp = xp }
    end
    
    return false, 'completion_failed'
end

-- Calcular pagamento
function Jobs.CalculatePayment(delivery, contract)
    local basePayment = contract.base_reward
    
    -- Bônus de tempo
    if delivery.completed_at and delivery.started_at then
        local deliveryTime = delivery.completed_at - delivery.started_at
        local estimatedSeconds = contract.estimated_time_hours * 3600
        
        if deliveryTime <= estimatedSeconds then
            basePayment = basePayment * 1.15 -- 15% bônus
        else
            basePayment = basePayment * 0.5 -- 50% penalidade
        end
    end
    
    -- Penalidade por danos
    if delivery.vehicle_damage > 0 then
        local damagePercent = delivery.vehicle_damage / 100
        basePayment = basePayment * (1 - (damagePercent * 0.2))
    end
    
    -- Bônus por ausência de danos
    if delivery.cargo_intact then
        basePayment = basePayment * 1.1 -- 10% bônus
    end
    
    return math.floor(basePayment)
end

-- Calcular XP
function Jobs.CalculateXP(delivery, contract)
    local baseXP = Config.Progression.XpPerDelivery
    
    -- XP por distância
    local distanceXP = math.floor(contract.estimated_distance * Config.Progression.XpPerKm)
    
    -- Bônus por tempo
    if delivery.completed_at and delivery.started_at then
        local deliveryTime = delivery.completed_at - delivery.started_at
        local estimatedSeconds = contract.estimated_time_hours * 3600
        
        if deliveryTime <= estimatedSeconds then
            baseXP = baseXP + Config.Progression.XpTimeBonus
        end
    end
    
    -- Bônus por sem danos
    if delivery.cargo_intact then
        baseXP = baseXP + Config.Progression.XpNoDamageBonus
    end
    
    return baseXP + distanceXP
end

return Jobs