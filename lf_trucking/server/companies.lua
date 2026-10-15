-- ==================== COMPANY MANAGEMENT ====================
-- Gerenciamento de transportadoras

Companies = {}
Companies.Cache = {}

-- Criar empresa
function Companies.Create(ownerIdentifier, ownerName, companyName)
    if not ownerIdentifier or not ownerName or not companyName then
        return false, 'missing_parameters'
    end
    
    -- Verificar se já possui empresa
    local checkQuery = 'SELECT id FROM trucking_companies WHERE owner_identifier = ?'
    local checkResult = MySQL.query.await(checkQuery, { ownerIdentifier })
    
    if checkResult and #checkResult > 0 then
        return false, 'already_has_company'
    end
    
    -- Verificar nome duplicado
    local nameCheckQuery = 'SELECT id FROM trucking_companies WHERE name = ?'
    local nameCheckResult = MySQL.query.await(nameCheckQuery, { companyName })
    
    if nameCheckResult and #nameCheckResult > 0 then
        return false, 'company_name_taken'
    end
    
    -- Criar empresa
    local company = Database.CreateCompany(companyName, ownerIdentifier, ownerName)
    
    if company then
        -- Adicionar proprietário como funcionário
        local employeeQuery = [[
            INSERT INTO trucking_company_employees
            (company_id, player_identifier, player_name, role, salary)
            VALUES (?, ?, ?, 'owner', 0)
        ]]
        
        MySQL.insert.await(employeeQuery, { company.id, ownerIdentifier, ownerName })
        
        -- Atualizar perfil do jogador
        local updatePlayerQuery = 'UPDATE trucking_players SET company_id = ?, company_role = ? WHERE identifier = ?'
        MySQL.update.await(updatePlayerQuery, { company.id, 'owner', ownerIdentifier })
        
        -- Log auditoria
        Database.LogAudit(
            'company_created',
            ownerIdentifier,
            ownerName,
            'company_' .. company.id,
            'company',
            company.id,
            { company_name = companyName },
            'not_exists',
            'created'
        )
        
        Companies.Cache[company.id] = company
        
        return true, company
    end
    
    return false, 'creation_failed'
end

-- Obter empresa por ID
function Companies.Get(companyId)
    if Companies.Cache[companyId] then
        return Companies.Cache[companyId]
    end
    
    local company = Database.GetCompany(companyId)
    if company then
        Companies.Cache[companyId] = company
    end
    
    return company
end

-- Obter empresa do jogador
function Companies.GetPlayerCompany(identifier)
    local query = 'SELECT company_id FROM trucking_players WHERE identifier = ?'
    local result = MySQL.query.await(query, { identifier })
    
    if not result or #result == 0 or not result[1].company_id then
        return nil
    end
    
    return Companies.Get(result[1].company_id)
end

-- Contratar funcionário
function Companies.HireEmployee(companyId, playerIdentifier, playerName, role)
    if not companyId or not playerIdentifier or not playerName or not role then
        return false, 'missing_parameters'
    end
    
    local company = Companies.Get(companyId)
    if not company then
        return false, 'company_not_found'
    end
    
    -- Verificar se já é funcionário
    local checkQuery = [[
        SELECT id FROM trucking_company_employees
        WHERE company_id = ? AND player_identifier = ? AND is_active = TRUE
    ]]
    
    local checkResult = MySQL.query.await(checkQuery, { companyId, playerIdentifier })
    
    if checkResult and #checkResult > 0 then
        return false, 'already_employee'
    end
    
    -- Contratar funcionário
    local query = [[
        INSERT INTO trucking_company_employees
        (company_id, player_identifier, player_name, role, salary)
        VALUES (?, ?, ?, ?, 0)
    ]]
    
    local result = MySQL.insert.await(query, { companyId, playerIdentifier, playerName, role })
    
    if result then
        -- Atualizar perfil do jogador
        local updatePlayerQuery = 'UPDATE trucking_players SET company_id = ?, company_role = ? WHERE identifier = ?'
        MySQL.update.await(updatePlayerQuery, { companyId, role, playerIdentifier })
        
        -- Atualizar contagem de funcionários
        local updateCountQuery = 'UPDATE trucking_companies SET employee_count = employee_count + 1 WHERE id = ?'
        MySQL.update.await(updateCountQuery, { companyId })
        
        -- Log auditoria
        Database.LogAudit(
            'employee_hired',
            playerIdentifier,
            playerName,
            playerIdentifier,
            'player',
            nil,
            { company_id = companyId, role = role },
            'not_employee',
            'employee'
        )
        
        return true
    end
    
    return false, 'hire_failed'
end

-- Demitir funcionário
function Companies.FireEmployee(companyId, employeeIdentifier, firedByIdentifier)
    local query = [[
        UPDATE trucking_company_employees
        SET is_active = FALSE, fired_at = NOW()
        WHERE company_id = ? AND player_identifier = ?
    ]]
    
    MySQL.update.await(query, { companyId, employeeIdentifier })
    
    -- Remover de perfil
    local updatePlayerQuery = 'UPDATE trucking_players SET company_id = NULL, company_role = NULL WHERE identifier = ?'
    MySQL.update.await(updatePlayerQuery, { employeeIdentifier })
    
    -- Atualizar contagem
    local updateCountQuery = 'UPDATE trucking_companies SET employee_count = employee_count - 1 WHERE id = ?'
    MySQL.update.await(updateCountQuery, { companyId })
    
    -- Log auditoria
    Database.LogAudit(
        'employee_fired',
        firedByIdentifier,
        'Unknown',
        employeeIdentifier,
        'player',
        nil,
        { company_id = companyId },
        'employee',
        'fired'
    )
    
    return true
end

-- Promover funcionário
function Companies.PromoteEmployee(companyId, employeeIdentifier, newRole)
    local query = [[
        UPDATE trucking_company_employees
        SET role = ?
        WHERE company_id = ? AND player_identifier = ?
    ]]
    
    MySQL.update.await(query, { newRole, companyId, employeeIdentifier })
    
    -- Atualizar perfil
    local updatePlayerQuery = 'UPDATE trucking_players SET company_role = ? WHERE identifier = ?'
    MySQL.update.await(updatePlayerQuery, { newRole, employeeIdentifier })
    
    return true
end

-- Obter funcionários da empresa
function Companies.GetEmployees(companyId)
    local query = [[
        SELECT * FROM trucking_company_employees
        WHERE company_id = ? AND is_active = TRUE
        ORDER BY role DESC
    ]]
    
    local result = MySQL.query.await(query, { companyId })
    return result or {}
end

-- Obter frota da empresa
function Companies.GetFleet(companyId)
    local query = [[
        SELECT * FROM trucking_vehicles
        WHERE company_id = ? AND owner_type = 'company'
        ORDER BY created_at DESC
    ]]
    
    local result = MySQL.query.await(query, { companyId })
    return result or {}
end

-- Adicionar veículo à empresa
function Companies.AddVehicle(companyId, vehicleData)
    -- TODO: Implementar quando integrar com garagem
    return true
end

-- Obter contratos da empresa
function Companies.GetContracts(companyId, status)
    local query = 'SELECT * FROM trucking_contracts WHERE company_id = ?'
    local params = { companyId }
    
    if status then
        query = query .. ' AND status = ?'
        table.insert(params, status)
    end
    
    query = query .. ' ORDER BY created_at DESC'
    
    local result = MySQL.query.await(query, params)
    return result or {}
end

-- Obter entregas da empresa
function Companies.GetDeliveries(companyId, status)
    local query = 'SELECT * FROM trucking_deliveries WHERE company_id = ?'
    local params = { companyId }
    
    if status then
        query = query .. ' AND status = ?'
        table.insert(params, status)
    end
    
    query = query .. ' ORDER BY created_at DESC LIMIT 100'
    
    local result = MySQL.query.await(query, params)
    return result or {}
end

-- Atualizar saldo da empresa
function Companies.AddBalance(companyId, amount, reason)
    return Database.UpdateCompanyBalance(companyId, amount, 'credit', reason)
end

-- Remover saldo da empresa
function Companies.RemoveBalance(companyId, amount, reason)
    local company = Companies.Get(companyId)
    if not company then
        return false
    end
    
    if company.balance < amount then
        return false
    end
    
    return Database.UpdateCompanyBalance(companyId, -amount, 'debit', reason)
end

-- Obter estatísticas da empresa
function Companies.GetStatistics(companyId)
    local company = Companies.Get(companyId)
    
    if not company then
        return nil
    end
    
    return {
        name = company.name,
        level = company.level,
        balance = company.balance,
        reputation = company.reputation,
        total_deliveries = company.total_deliveries,
        completed_deliveries = company.completed_deliveries,
        failed_deliveries = company.failed_deliveries,
        total_revenue = company.total_revenue,
        total_expenses = company.total_expenses,
        employee_count = company.employee_count,
        fleet_count = company.fleet_count,
    }
end

-- Verificar permissão de funcionário
function Companies.HasPermission(companyId, employeeIdentifier, permission)
    local query = [[
        SELECT role FROM trucking_company_employees
        WHERE company_id = ? AND player_identifier = ? AND is_active = TRUE
    ]]
    
    local result = MySQL.query.await(query, { companyId, employeeIdentifier })
    
    if not result or #result == 0 then
        return false
    end
    
    local role = result[1].role
    local permissions = TRUCKING.PERMISSIONS[role] or {}
    
    for _, perm in ipairs(permissions) do
        if perm == permission then
            return true
        end
    end
    
    return false
end

return Companies