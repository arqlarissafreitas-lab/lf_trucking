-- ==================== LOAN MANAGEMENT ====================
-- Gerenciamento de empréstimos

Loans = {}
Loans.Cache = {}

-- Obter empréstimo
function Loans.Get(loanId)
    if Loans.Cache[loanId] then
        return Loans.Cache[loanId]
    end
    
    local query = 'SELECT * FROM trucking_loans WHERE id = ?'
    local result = MySQL.query.await(query, { loanId })
    
    if result and result[1] then
        Loans.Cache[loanId] = result[1]
        return result[1]
    end
    
    return nil
end

-- Obter empréstimos do jogador
function Loans.GetPlayerLoans(identifier)
    local query = 'SELECT * FROM trucking_loans WHERE player_identifier = ? ORDER BY created_at DESC'
    local result = MySQL.query.await(query, { identifier })
    return result or {}
end

-- Criar empréstimo
function Loans.Create(identifier, loanType, amount, months)
    loanType = loanType or 'vehicle'
    months = months or 12
    
    local profile = Players.GetProfile(identifier)
    if not profile then
        return false, 'player_not_found'
    end
    
    -- Determinar taxa de juros
    local interestRate = Config.Economy.VehicleLoanInterest
    if loanType == 'business' then
        interestRate = Config.Economy.BusinessLoanInterest
    end
    
    -- Calcular totais
    local totalAmount = math.floor(amount * (1 + (interestRate * months)))
    local monthlyPayment = math.floor(totalAmount / months)
    
    -- Criar empréstimo
    local loanUUID = Utils.GenerateUUID()
    local dueDate = os.time() + (months * 30 * 24 * 3600)
    
    local query = [[
        INSERT INTO trucking_loans
        (loan_uuid, player_identifier, loan_type, principal_amount, interest_rate,
         total_amount, installment_amount, installments_total, status, due_date)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active', ?)
    ]]
    
    local result = MySQL.insert.await(query, {
        loanUUID,
        identifier,
        loanType,
        amount,
        interestRate,
        totalAmount,
        monthlyPayment,
        months,
        dueDate,
    })
    
    if result then
        -- Log auditoria
        Database.LogAudit(
            'loan_created',
            identifier,
            profile.player_name,
            'loan_' .. loanUUID,
            'loan',
            result,
            { loan_type = loanType, amount = amount, monthly_payment = monthlyPayment },
            'not_exists',
            'active'
        )
        
        return true, { loan_id = result, monthly_payment = monthlyPayment }
    end
    
    return false, 'creation_failed'
end

-- Pagar parcela
function Loans.PayInstallment(identifier, loanId)
    local loan = Loans.Get(loanId)
    
    if not loan then
        return false, 'loan_not_found'
    end
    
    if loan.player_identifier ~= identifier then
        return false, 'unauthorized'
    end
    
    if loan.status ~= 'active' then
        return false, 'loan_not_active'
    end
    
    -- Verificar saldo
    local profile = Players.GetProfile(identifier)
    if profile.total_money < loan.installment_amount then
        return false, 'insufficient_funds'
    end
    
    -- Processar pagamento
    local success = Players.RemoveMoney(identifier, loan.installment_amount, 'loan_payment')
    
    if success then
        local newInstallmentsPaid = loan.installments_paid + 1
        local newStatus = newInstallmentsPaid >= loan.installments_total and 'paid' or 'active'
        
        local updateQuery = [[
            UPDATE trucking_loans
            SET installments_paid = ?, status = ?, last_payment_at = NOW()
            WHERE id = ?
        ]]
        
        MySQL.update.await(updateQuery, { newInstallmentsPaid, newStatus, loanId })
        
        -- Limpar cache
        Loans.Cache[loanId] = nil
        
        -- Log auditoria
        Database.LogAudit(
            'loan_payment',
            identifier,
            profile.player_name,
            'loan_' .. loan.loan_uuid,
            'loan',
            loanId,
            { installment_amount = loan.installment_amount, installments_paid = newInstallmentsPaid },
            'active',
            newStatus
        )
        
        return true, { status = newStatus, installments_paid = newInstallmentsPaid }
    end
    
    return false, 'payment_failed'
end

-- Verificar empréstimos pendentes
function Loans.CheckPendingLoans(identifier)
    local loans = Loans.GetPlayerLoans(identifier)
    local overdue = {}
    
    for _, loan in ipairs(loans) do
        if loan.status == 'active' and loan.due_date < os.time() then
            table.insert(overdue, loan)
        end
    end
    
    return overdue
end

return Loans