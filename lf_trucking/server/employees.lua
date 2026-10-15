-- ==================== EMPLOYEE MANAGEMENT ====================
-- Gerenciamento de funcionários de empresa

Employees = {}

-- Contratar funcionário
function Employees.Hire(source, companyId, playerIdentifier, playerName, role)
    local managerIdentifier = Framework.GetIdentifier(source)
    
    if not managerIdentifier then
        return false, 'invalid_manager'
    end
    
    -- Verificar permissão
    if not Companies.HasPermission(companyId, managerIdentifier, 'hire_employees') then
        return false, 'no_permission'
    end
    
    -- Verificar se empresa existe
    local company = Companies.Get(companyId)
    if not company then
        return false, 'company_not_found'
    end
    
    -- Verificar se já é funcionário
    local query = [[
        SELECT id FROM trucking_company_employees
        WHERE company_id = ? AND player_identifier = ? AND is_active = TRUE
    ]]
    
    local checkResult = MySQL.query.await(query, { companyId, playerIdentifier })
    
    if checkResult and #checkResult > 0 then
        return false, 'already_employee'
    end
    
    -- Validar role
    if not TRUCKING.COMPANY_ROLES[role] then
        role = 'driver'
    end
    
    -- Contratar
    return Companies.HireEmployee(companyId, playerIdentifier, playerName, role)
end

-- Demitir funcionário
function Employees.Fire(source, companyId, employeeIdentifier)
    local managerIdentifier = Framework.GetIdentifier(source)
    
    if not managerIdentifier then
        return false, 'invalid_manager'
    end
    
    -- Verificar permissão
    if not Companies.HasPermission(companyId, managerIdentifier, 'fire_employees') then
        return false, 'no_permission'
    end
    
    -- Demitir
    return Companies.FireEmployee(companyId, employeeIdentifier, managerIdentifier)
end

-- Promover funcionário
function Employees.Promote(source, companyId, employeeIdentifier, newRole)
    local managerIdentifier = Framework.GetIdentifier(source)
    
    if not managerIdentifier then
        return false, 'invalid_manager'
    end
    
    -- Verificar permissão
    if not Companies.HasPermission(companyId, managerIdentifier, 'promote_employees') then
        return false, 'no_permission'
    end
    
    -- Validar role
    if not TRUCKING.COMPANY_ROLES[newRole] then
        return false, 'invalid_role'
    end
    
    -- Promover
    local success = Companies.PromoteEmployee(companyId, employeeIdentifier, newRole)
    
    if success then
        -- Log auditoria
        local profile = Players.GetProfile(managerIdentifier)
        
        Database.LogAudit(
            'employee_promoted',
            managerIdentifier,
            profile and profile.player_name or 'Unknown',
            employeeIdentifier,
            'player',
            nil,
            { company_id = companyId, new_role = newRole },
            'employee',
            'promoted'
        )
    end
    
    return success
end

-- Obter funcionários de empresa
function Employees.GetCompanyEmployees(companyId)
    return Companies.GetEmployees(companyId)
end

-- Definir salário
function Employees.SetSalary(source, companyId, employeeIdentifier, salary)
    local managerIdentifier = Framework.GetIdentifier(source)
    
    if not managerIdentifier then
        return false, 'invalid_manager'
    end
    
    -- Verificar permissão
    if not Companies.HasPermission(companyId, managerIdentifier, 'manage_finances') then
        return false, 'no_permission'
    end
    
    -- Validar salário
    if salary < 0 then
        return false, 'invalid_salary'
    end
    
    -- Atualizar salário
    local query = [[
        UPDATE trucking_company_employees
        SET salary = ?
        WHERE company_id = ? AND player_identifier = ?
    ]]
    
    MySQL.update.await(query, { salary, companyId, employeeIdentifier })
    
    return true
end

-- Pagar funcionários (semanal)
function Employees.PayWeekly(companyId)
    local company = Companies.Get(companyId)
    if not company then
        return false, 'company_not_found'
    end
    
    -- Obter funcionários
    local employees = Companies.GetEmployees(companyId)
    local totalCost = 0
    
    for _, employee in ipairs(employees) do
        totalCost = totalCost + (employee.salary or 0)
    end
    
    -- Verificar saldo
    if company.balance < totalCost then
        return false, 'insufficient_balance'
    end
    
    -- Pagar cada funcionário
    for _, employee in ipairs(employees) do
        if employee.salary and employee.salary > 0 then
            Players.AddMoney(employee.player_identifier, employee.salary, 'company_salary')
        end
    end
    
    -- Remover saldo da empresa
    Companies.RemoveBalance(companyId, totalCost, 'employee_payroll')
    
    return true
end

return Employees