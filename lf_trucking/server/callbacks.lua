-- ==================== SERVER CALLBACKS ====================
-- Callbacks para comunicação com cliente

-- Registro de callbacks
function RegisterCallbacks()
    -- Obter perfil
    Framework.RegisterCallback('lf_trucking:getProfile', function(source, cb)
        local identifier = Framework.GetIdentifier(source)
        if not identifier then
            cb(nil)
            return
        end
        
        local profile = Players.GetProfile(identifier)
        cb(profile)
    end)
    
    -- Obter contratos disponíveis
    Framework.RegisterCallback('lf_trucking:getAvailableContracts', function(source, cb, limit)
        local contracts = Jobs.GetAvailable(limit or 10)
        cb(contracts)
    end)
    
    -- Aceitar contrato
    Framework.RegisterCallback('lf_trucking:acceptContract', function(source, cb, contractId)
        if not Security.CheckRateLimit(Framework.GetIdentifier(source), 'accept_contract') then
            cb(false, 'rate_limited')
            return
        end
        
        local success, result = Jobs.Accept(source, contractId)
        cb(success, result)
    end)
    
    -- Cancelar entrega
    Framework.RegisterCallback('lf_trucking:cancelDelivery', function(source, cb, deliveryId)
        local identifier = Framework.GetIdentifier(source)
        
        if not Security.ValidateDeliveryOwnership(identifier, deliveryId) then
            cb(false, 'unauthorized')
            return
        end
        
        local success, error = Jobs.Cancel(source, deliveryId, 'Cancelamento do jogador')
        cb(success, error)
    end)
    
    -- Completar entrega
    Framework.RegisterCallback('lf_trucking:completeDelivery', function(source, cb, deliveryId)
        local identifier = Framework.GetIdentifier(source)
        
        if not Security.ValidateDeliveryOwnership(identifier, deliveryId) then
            cb(false, 'unauthorized')
            return
        end
        
        if not Security.CheckRateLimit(identifier, 'complete_delivery') then
            cb(false, 'rate_limited')
            return
        end
        
        if not Security.ValidateNoDoublePayment(deliveryId) then
            cb(false, 'payment_already_made')
            return
        end
        
        local success, result = Jobs.Complete(source, deliveryId)
        cb(success, result)
    end)
    
    -- Emitir nota fiscal
    Framework.RegisterCallback('lf_trucking:issueInvoice', function(source, cb, deliveryId)
        local identifier = Framework.GetIdentifier(source)
        
        if not Security.ValidateDeliveryOwnership(identifier, deliveryId) then
            cb(false, 'unauthorized')
            return
        end
        
        if not Security.CheckRateLimit(identifier, 'issue_invoice') then
            cb(false, 'rate_limited')
            return
        end
        
        local success, result = Invoices.Issue(source, deliveryId)
        
        if success then
            cb(true, Invoices.Format(result))
        else
            cb(false, result)
        end
    end)
    
    -- Obter estatísticas
    Framework.RegisterCallback('lf_trucking:getStatistics', function(source, cb)
        local identifier = Framework.GetIdentifier(source)
        local stats = Players.GetStatistics(identifier)
        cb(stats)
    end)
    
    -- Obter habilidades
    Framework.RegisterCallback('lf_trucking:getSkillTree', function(source, cb)
        local identifier = Framework.GetIdentifier(source)
        local skills = Progression.GetSkillTree(identifier)
        cb(skills)
    end)
    
    -- Desbloquear habilidade
    Framework.RegisterCallback('lf_trucking:unlockSkill', function(source, cb, skillId)
        local identifier = Framework.GetIdentifier(source)
        
        if not Security.CheckRateLimit(identifier, 'unlock_skill') then
            cb(false, 'rate_limited')
            return
        end
        
        local success, error = Progression.UnlockSkill(identifier, skillId)
        cb(success, error)
    end)
    
    -- Obter certificações
    Framework.RegisterCallback('lf_trucking:getCertifications', function(source, cb)
        local identifier = Framework.GetIdentifier(source)
        local certs = Players.GetCertifications(identifier)
        cb(certs)
    end)
    
    -- Obter empréstimos
    Framework.RegisterCallback('lf_trucking:getLoans', function(source, cb)
        local identifier = Framework.GetIdentifier(source)
        local loans = Players.GetLoans(identifier)
        cb(loans)
    end)
    
    -- Pagar empréstimo
    Framework.RegisterCallback('lf_trucking:payLoan', function(source, cb, loanId)
        local identifier = Framework.GetIdentifier(source)
        
        if not Security.CheckRateLimit(identifier, 'pay_loan') then
            cb(false, 'rate_limited')
            return
        end
        
        local success, error = Players.PayLoanInstallment(identifier, loanId)
        cb(success, error)
    end)
    
    -- Obter empresa
    Framework.RegisterCallback('lf_trucking:getCompany', function(source, cb)
        local identifier = Framework.GetIdentifier(source)
        local company = Companies.GetPlayerCompany(identifier)
        cb(company)
    end)
    
    -- Criar empresa
    Framework.RegisterCallback('lf_trucking:createCompany', function(source, cb, companyName)
        local identifier = Framework.GetIdentifier(source)
        local playerName = Framework.GetName(source)
        
        if not Security.CheckRateLimit(identifier, 'create_company', 5000) then
            cb(false, 'rate_limited')
            return
        end
        
        if string.len(companyName) < Config.Company.MinNameLength or string.len(companyName) > Config.Company.MaxNameLength then
            cb(false, 'invalid_name_length')
            return
        end
        
        local success, result = Companies.Create(identifier, playerName, companyName)
        cb(success, result)
    end)
    
    -- Obter catálogo de veículos
    Framework.RegisterCallback('lf_trucking:getDealershipCatalog', function(source, cb)
        local catalog = Dealership.GetCatalog()
        cb(catalog)
    end)
    
    -- Comprar veículo
    Framework.RegisterCallback('lf_trucking:buyVehicle', function(source, cb, vehicleModel)
        if not Security.CheckRateLimit(Framework.GetIdentifier(source), 'buy_vehicle', 5000) then
            cb(false, 'rate_limited')
            return
        end
        
        local success, result = Dealership.BuyVehicle(source, vehicleModel)
        cb(success, result)
    end)
    
    print('^2[LF_TRUCKING]^7 Callbacks registrados com sucesso')
end

return RegisterCallbacks