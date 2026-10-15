-- ==================== DATABASE MANAGEMENT ====================
-- Gerenciamento de conexão MySQL

Database = {}
Database.Connected = false

-- Inicializar conexão com banco de dados
function Database.Init()
    local adapterName = Config.Database.Adapter or ''
    
    -- Auto-detect
    if adapterName == '' then
        if GetResourceState('oxmysql') == 'started' then
            adapterName = 'oxmysql'
        elseif GetResourceState('mysql-async') == 'started' then
            adapterName = 'mysql-async'
        elseif GetResourceState('ghmattimysql') == 'started' then
            adapterName = 'ghmattimysql'
        else
            print('^1[LF_TRUCKING] ERRO: Nenhum adaptador MySQL encontrado!^7')
            return false
        end
    end
    
    Database.Adapter = adapterName
    Database.Connected = true
    print('^2[LF_TRUCKING]^7 Banco de dados inicializado com ' .. adapterName)
    
    return true
end

-- ==================== QUERY EXECUTORS ====================

-- Executar query (SELECT, UPDATE, DELETE, INSERT)
function Database.Execute(query, params, callback)
    if not Database.Connected then
        if callback then callback(nil) end
        return
    end
    
    if Database.Adapter == 'oxmysql' then
        MySQL.Async.execute(query, params, callback)
    elseif Database.Adapter == 'mysql-async' then
        MySQL.Async.execute(query, params, callback)
    elseif Database.Adapter == 'ghmattimysql' then
        ghmattimysql.execute(query, params, callback)
    else
        if callback then callback(nil) end
    end
end

-- Executar query com resultado (SELECT)
function Database.Query(query, params, callback)
    if not Database.Connected then
        if callback then callback(nil) end
        return
    end
    
    if Database.Adapter == 'oxmysql' then
        local result = MySQL.query.await(query, params)
        if callback then callback(result) end
    elseif Database.Adapter == 'mysql-async' then
        MySQL.Async.fetchAll(query, params, callback)
    elseif Database.Adapter == 'ghmattimysql' then
        ghmattimysql.execute(query, params, function(result)
            if callback then callback(result) end
        end)
    else
        if callback then callback(nil) end
    end
end

-- ==================== PLAYER OPERATIONS ====================

-- Obter perfil do jogador
function Database.GetPlayerProfile(identifier)
    local query = 'SELECT * FROM trucking_players WHERE identifier = ?'
    local result = MySQL.query.await(query, { identifier })
    return result and result[1] or nil
end

-- Criar perfil do jogador
function Database.CreatePlayerProfile(identifier, playerName)
    local query = [[
        INSERT INTO trucking_players (identifier, player_name, level, experience, total_money)
        VALUES (?, ?, 1, 0, 0)
        ON DUPLICATE KEY UPDATE player_name = ?
    ]]
    MySQL.insert.await(query, { identifier, playerName, playerName })
end

-- Atualizar dinheiro do jogador
function Database.UpdatePlayerMoney(identifier, amount, transactionType, reason)
    local query = 'SELECT total_money FROM trucking_players WHERE identifier = ?'
    local result = MySQL.query.await(query, { identifier })
    
    if not result or not result[1] then return false end
    
    local previousBalance = result[1].total_money
    local newBalance = previousBalance + amount
    
    if newBalance < 0 then return false end
    
    local updateQuery = 'UPDATE trucking_players SET total_money = ? WHERE identifier = ?'
    MySQL.update.await(updateQuery, { newBalance, identifier })
    
    -- Registrar transação
    local historyQuery = [[
        INSERT INTO trucking_financial_history (player_identifier, transaction_type, amount, previous_balance, new_balance, reason)
        VALUES (?, ?, ?, ?, ?, ?)
    ]]
    MySQL.insert.await(historyQuery, { identifier, transactionType, amount, previousBalance, newBalance, reason })
    
    return true
end

-- Adicionar XP ao jogador
function Database.AddPlayerXP(identifier, xpAmount)
    local query = 'SELECT experience, level FROM trucking_players WHERE identifier = ?'
    local result = MySQL.query.await(query, { identifier })
    
    if not result or not result[1] then return false end
    
    local currentXP = result[1].experience
    local currentLevel = result[1].level
    local totalXP = currentXP + xpAmount
    
    -- Calcular novo nível
    local xpPerLevel = Config.Progression.XpPerLevel
    local newLevel = math.floor(totalXP / xpPerLevel) + 1
    newLevel = math.min(newLevel, 100) -- Cap no nível 100
    
    local updateQuery = 'UPDATE trucking_players SET experience = ?, level = ? WHERE identifier = ?'
    MySQL.update.await(updateQuery, { totalXP, newLevel, identifier })
    
    return true, newLevel > currentLevel
end

-- ==================== DELIVERY OPERATIONS ====================

-- Criar nova entrega
function Database.CreateDelivery(contractId, playerIdentifier, playerName, vehicleId, vehiclePlate, companyId)
    local deliveryUUID = Utils.GenerateDeliveryUUID()
    local deadline = os.time() + (24 * 3600) -- 24 horas
    
    local query = [[
        INSERT INTO trucking_deliveries 
        (delivery_uuid, contract_id, player_identifier, player_name, company_id, vehicle_id, vehicle_plate, deadline)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]]
    
    local result = MySQL.insert.await(query, { deliveryUUID, contractId, playerIdentifier, playerName, companyId, vehicleId, vehiclePlate, deadline })
    
    if result then
        return Database.GetDelivery(deliveryUUID)
    end
    
    return nil
end

-- Obter entrega por UUID
function Database.GetDelivery(deliveryUUID)
    local query = 'SELECT * FROM trucking_deliveries WHERE delivery_uuid = ?'
    local result = MySQL.query.await(query, { deliveryUUID })
    return result and result[1] or nil
end

-- Atualizar status da entrega
function Database.UpdateDeliveryStatus(deliveryId, newStatus)
    local query = 'UPDATE trucking_deliveries SET status = ?, updated_at = NOW() WHERE id = ?'
    MySQL.update.await(query, { newStatus, deliveryId })
end

-- Completar entrega
function Database.CompleteDelivery(deliveryId, finalReward, xpEarned)
    local query = [[
        UPDATE trucking_deliveries 
        SET status = 'completed', final_reward = ?, xp_earned = ?, is_paid = FALSE, completed_at = NOW()
        WHERE id = ?
    ]]
    MySQL.update.await(query, { finalReward, xpEarned, deliveryId })
end

-- ==================== INVOICE OPERATIONS ====================

-- Criar nota fiscal
function Database.CreateInvoice(deliveryId, contractId, invoiceData)
    local invoiceNumber = Utils.GenerateInvoiceNumber()
    local invoiceUUID = Utils.GenerateUUID()
    local validationCode = Utils.GenerateRandomCode(20)
    
    local query = [[
        INSERT INTO trucking_invoices
        (invoice_number, delivery_id, contract_id, invoice_uuid, shipper_name, carrier_name, carrier_cnpj,
         driver_name, driver_id, vehicle_plate, vehicle_model, cargo_type, cargo_description,
         cargo_weight, cargo_value, origin_city, destination_city, status, validation_code, issued_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'issued', ?, ?)
    ]]
    
    local params = {
        invoiceNumber, deliveryId, contractId, invoiceUUID,
        invoiceData.shipper_name, invoiceData.carrier_name, invoiceData.carrier_cnpj,
        invoiceData.driver_name, invoiceData.driver_id, invoiceData.vehicle_plate,
        invoiceData.vehicle_model, invoiceData.cargo_type, invoiceData.cargo_description,
        invoiceData.cargo_weight, invoiceData.cargo_value,
        invoiceData.origin_city, invoiceData.destination_city, validationCode, invoiceData.issued_by
    }
    
    local result = MySQL.insert.await(query, params)
    
    if result then
        return Database.GetInvoiceById(result)
    end
    
    return nil
end

-- Obter nota fiscal por ID
function Database.GetInvoiceById(invoiceId)
    local query = 'SELECT * FROM trucking_invoices WHERE id = ?'
    local result = MySQL.query.await(query, { invoiceId })
    return result and result[1] or nil
end

-- Atualizar status da nota fiscal
function Database.UpdateInvoiceStatus(invoiceId, newStatus, clearedBy)
    local query = [[
        UPDATE trucking_invoices 
        SET status = ?, cleared_at = NOW(), cleared_by = ?
        WHERE id = ?
    ]]
    MySQL.update.await(query, { newStatus, clearedBy, invoiceId })
end

-- ==================== INSPECTION OPERATIONS ====================

-- Criar inspeção
function Database.CreateInspection(deliveryId, checkpointId, officerIdentifier, officerName, officerRank, vehiclePlate, driverIdentifier, driverName)
    local inspectionUUID = Utils.GenerateUUID()
    
    local query = [[
        INSERT INTO trucking_inspections
        (inspection_uuid, delivery_id, checkpoint_id, prf_officer_identifier, prf_officer_name, prf_officer_rank,
         vehicle_plate, driver_identifier, driver_name)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]
    
    local result = MySQL.insert.await(query, {
        inspectionUUID, deliveryId, checkpointId, officerIdentifier, officerName, officerRank,
        vehiclePlate, driverIdentifier, driverName
    })
    
    if result then
        return Database.GetInspectionById(result)
    end
    
    return nil
end

-- Obter inspeção por ID
function Database.GetInspectionById(inspectionId)
    local query = 'SELECT * FROM trucking_inspections WHERE id = ?'
    local result = MySQL.query.await(query, { inspectionId })
    return result and result[1] or nil
end

-- Finalizar inspeção
function Database.CompleteInspection(inspectionId, result, notes, administrativeMeasure, deliveryBlocked)
    local query = [[
        UPDATE trucking_inspections
        SET inspection_result = ?, officer_notes = ?, administrative_measure = ?, 
            delivery_blocked = ?, completed_at = NOW()
        WHERE id = ?
    ]]
    
    MySQL.update.await(query, { result, notes, administrativeMeasure, deliveryBlocked, inspectionId })
end

-- ==================== COMPANY OPERATIONS ====================

-- Criar empresa
function Database.CreateCompany(name, ownerIdentifier, ownerName)
    local identifier = 'company_' .. Utils.GenerateRandomCode(10)
    
    local query = [[
        INSERT INTO trucking_companies (name, identifier, owner_identifier, owner_name, balance, level, reputation)
        VALUES (?, ?, ?, ?, 0, 1, 5.0)
    ]]
    
    local result = MySQL.insert.await(query, { name, identifier, ownerIdentifier, ownerName })
    
    if result then
        return Database.GetCompany(result)
    end
    
    return nil
end

-- Obter empresa por ID
function Database.GetCompany(companyId)
    local query = 'SELECT * FROM trucking_companies WHERE id = ?'
    local result = MySQL.query.await(query, { companyId })
    return result and result[1] or nil
end

-- Atualizar saldo da empresa
function Database.UpdateCompanyBalance(companyId, amount, transactionType, reason)
    local query = 'SELECT balance FROM trucking_companies WHERE id = ?'
    local result = MySQL.query.await(query, { companyId })
    
    if not result or not result[1] then return false end
    
    local previousBalance = result[1].balance
    local newBalance = previousBalance + amount
    
    local updateQuery = 'UPDATE trucking_companies SET balance = ? WHERE id = ?'
    MySQL.update.await(updateQuery, { newBalance, companyId })
    
    return true
end

-- ==================== CONTRACT OPERATIONS ====================

-- Obter contratos disponíveis
function Database.GetAvailableContracts(limit)
    limit = limit or 10
    local query = [[
        SELECT * FROM trucking_contracts 
        WHERE status = 'available' AND expires_at > NOW()
        ORDER BY created_at DESC
        LIMIT ?
    ]]
    
    local result = MySQL.query.await(query, { limit })
    return result or {}
end

-- Obter contrato por ID
function Database.GetContract(contractId)
    local query = 'SELECT * FROM trucking_contracts WHERE id = ?'
    local result = MySQL.query.await(query, { contractId })
    return result and result[1] or nil
end

-- ==================== CERTIFICATION OPERATIONS ====================

-- Verificar se jogador possui certificação
function Database.HasCertification(identifier, certType)
    local query = 'SELECT id FROM trucking_certifications WHERE player_identifier = ? AND certification_type = ? AND status = "active"'
    local result = MySQL.query.await(query, { identifier, certType })
    return result and #result > 0
end

-- Conceder certificação
function Database.GrantCertification(identifier, certType, certName)
    local expiresAt = os.time() + (365 * 24 * 3600) -- 1 ano
    
    local query = [[
        INSERT INTO trucking_certifications (player_identifier, certification_type, certification_name, status, expires_at)
        VALUES (?, ?, ?, 'active', ?)
        ON DUPLICATE KEY UPDATE status = 'active', expires_at = ?
    ]]
    
    MySQL.insert.await(query, { identifier, certType, certName, expiresAt, expiresAt })
end

-- ==================== AUDIT LOGGING ====================

-- Registrar auditoria
function Database.LogAudit(actionType, actorIdentifier, actorName, targetIdentifier, targetType, targetId, details, statusBefore, statusAfter)
    local detailsJson = Utils.EncodeJSON(details or {})
    
    local query = [[
        INSERT INTO trucking_audit_logs
        (action_type, actor_identifier, actor_name, target_identifier, target_type, target_id, action_details, status_before, status_after)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]
    
    MySQL.insert.await(query, {
        actionType, actorIdentifier, actorName, targetIdentifier, targetType, targetId, detailsJson, statusBefore, statusAfter
    })
end

return Database