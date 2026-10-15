-- ==================== PLAYER MANAGEMENT ====================
-- Gerenciamento de perfis e dados de jogadores

Players = {}
Players.Cache = {}

-- Inicializar jogador ao conectar
function Players.Initialize(source)
    local identifier = Framework.GetIdentifier(source)
    local playerName = Framework.GetName(source)
    
    if not identifier then
        print('^1[LF_TRUCKING] ERRO: Não foi possível obter identificador do jogador ' .. source .. '^7')
        return false
    end
    
    -- Verificar se perfil existe no banco
    local profile = Database.GetPlayerProfile(identifier)
    
    if not profile then
        -- Criar novo perfil
        Database.CreatePlayerProfile(identifier, playerName)
        profile = Database.GetPlayerProfile(identifier)
    end
    
    -- Cachear dados do jogador
    Players.Cache[identifier] = profile
    
    -- Inicializar skills se não existirem
    local skillsQuery = 'SELECT id FROM trucking_skills WHERE player_identifier = ?'
    local skillsResult = MySQL.query.await(skillsQuery, { identifier })
    
    if not skillsResult or #skillsResult == 0 then
        local insertSkillsQuery = 'INSERT INTO trucking_skills (player_identifier) VALUES (?)'
        MySQL.insert.await(insertSkillsQuery, { identifier })
    end
    
    print('^2[LF_TRUCKING]^7 Jogador ' .. playerName .. ' (' .. identifier .. ') inicializado')
    
    return true
end

-- Limpar cache ao desconectar
function Players.Cleanup(identifier)
    Players.Cache[identifier] = nil
end

-- Obter perfil do jogador (com cache)
function Players.GetProfile(identifier)
    if Players.Cache[identifier] then
        return Players.Cache[identifier]
    end
    
    local profile = Database.GetPlayerProfile(identifier)
    if profile then
        Players.Cache[identifier] = profile
    end
    
    return profile
end

-- Atualizar dinheiro do jogador
function Players.AddMoney(identifier, amount, reason)
    if amount < 0 then
        return false, 'amount_must_be_positive'
    end
    
    local success = Database.UpdatePlayerMoney(identifier, amount, 'credit', reason)
    
    if success then
        -- Atualizar cache
        local profile = Database.GetPlayerProfile(identifier)
        if profile then
            Players.Cache[identifier] = profile
        end
    end
    
    return success
end

-- Remover dinheiro do jogador
function Players.RemoveMoney(identifier, amount, reason)
    if amount < 0 then
        return false, 'amount_must_be_positive'
    end
    
    local profile = Players.GetProfile(identifier)
    if not profile then
        return false, 'player_not_found'
    end
    
    if profile.total_money < amount then
        return false, 'insufficient_funds'
    end
    
    local success = Database.UpdatePlayerMoney(identifier, -amount, 'debit', reason)
    
    if success then
        -- Atualizar cache
        local updatedProfile = Database.GetPlayerProfile(identifier)
        if updatedProfile then
            Players.Cache[identifier] = updatedProfile
        end
    end
    
    return success
end

-- Obter nível do jogador
function Players.GetLevel(identifier)
    local profile = Players.GetProfile(identifier)
    return profile and profile.level or 1
end

-- Adicionar XP ao jogador
function Players.AddXP(identifier, xpAmount)
    if xpAmount < 0 then
        return false
    end
    
    local profile = Players.GetProfile(identifier)
    if not profile then
        return false
    end
    
    local oldLevel = profile.level
    local success, leveledUp = Database.AddPlayerXP(identifier, xpAmount)
    
    if success then
        -- Atualizar cache
        local updatedProfile = Database.GetPlayerProfile(identifier)
        if updatedProfile then
            Players.Cache[identifier] = updatedProfile
        end
        
        -- Log auditoria
        Database.LogAudit(
            'xp_gained',
            identifier,
            profile.player_name,
            identifier,
            'player',
            profile.id,
            { xp_gained = xpAmount, reason = 'delivery_completion' },
            'level_' .. oldLevel,
            'level_' .. (updatedProfile and updatedProfile.level or oldLevel)
        )
    end
    
    return success, leveledUp
end

-- Obter histórico financeiro
function Players.GetFinancialHistory(identifier, limit)
    limit = limit or 50
    local query = [[
        SELECT * FROM trucking_financial_history
        WHERE player_identifier = ?
        ORDER BY created_at DESC
        LIMIT ?
    ]]
    
    local result = MySQL.query.await(query, { identifier, limit })
    return result or {}
end

-- Obter entrega ativa do jogador
function Players.GetActiveDelivery(identifier)
    local query = [[
        SELECT * FROM trucking_deliveries
        WHERE player_identifier = ? AND status != 'completed' AND status != 'cancelled' AND status != 'failed'
        LIMIT 1
    ]]
    
    local result = MySQL.query.await(query, { identifier })
    return result and result[1] or nil
end

-- Verificar se jogador está em entrega
function Players.IsInDelivery(identifier)
    return Players.GetActiveDelivery(identifier) ~= nil
end

-- Obter habilidades do jogador
function Players.GetSkills(identifier)
    local query = 'SELECT * FROM trucking_skills WHERE player_identifier = ?'
    local result = MySQL.query.await(query, { identifier })
    return result and result[1] or {}
end

-- Aumentar habilidade do jogador
function Players.IncrementSkill(identifier, skillType, amount)
    amount = amount or 1
    
    local query = 'UPDATE trucking_skills SET ' .. skillType .. ' = ' .. skillType .. ' + ? WHERE player_identifier = ?'
    MySQL.update.await(query, { amount, identifier })
    
    return true
end

-- Obter certificações do jogador
function Players.GetCertifications(identifier)
    local query = 'SELECT * FROM trucking_certifications WHERE player_identifier = ?'
    local result = MySQL.query.await(query, { identifier })
    return result or {}
end

-- Conceder certificação
function Players.GrantCertification(identifier, certType, certName)
    Database.GrantCertification(identifier, certType, certName)
    
    Database.LogAudit(
        'certification_granted',
        'system',
        'System',
        identifier,
        'player',
        nil,
        { cert_type = certType, cert_name = certName },
        'no_cert',
        'certified'
    )
end

-- Obter estatísticas do jogador
function Players.GetStatistics(identifier)
    local profile = Players.GetProfile(identifier)
    
    if not profile then
        return nil
    end
    
    return {
        level = profile.level,
        experience = profile.experience,
        total_money = profile.total_money,
        money_earned = profile.money_earned,
        money_spent = profile.money_spent,
        total_distance = profile.total_distance,
        total_deliveries = profile.total_deliveries,
        completed_deliveries = profile.completed_deliveries,
        cancelled_deliveries = profile.cancelled_deliveries,
        failed_deliveries = profile.failed_deliveries,
        average_rating = profile.average_rating,
        company_id = profile.company_id,
        company_role = profile.company_role,
    }
end

-- Obter empréstimos do jogador
function Players.GetLoans(identifier)
    local query = [[
        SELECT * FROM trucking_loans
        WHERE player_identifier = ? AND status IN ('active', 'defaulted')
        ORDER BY created_at DESC
    ]]
    
    local result = MySQL.query.await(query, { identifier })
    return result or {}
end

-- Pagar empréstimo
function Players.PayLoanInstallment(identifier, loanId)
    local loanQuery = 'SELECT * FROM trucking_loans WHERE id = ? AND player_identifier = ?'
    local loanResult = MySQL.query.await(loanQuery, { loanId, identifier })
    
    if not loanResult or #loanResult == 0 then
        return false, 'loan_not_found'
    end
    
    local loan = loanResult[1]
    
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
        
        Database.LogAudit(
            'loan_payment',
            identifier,
            profile.player_name,
            identifier,
            'loan',
            loanId,
            { installment_amount = loan.installment_amount, installments_paid = newInstallmentsPaid },
            'active',
            newStatus
        )
    end
    
    return success
end

return Players