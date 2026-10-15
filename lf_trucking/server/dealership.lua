-- ==================== DEALERSHIP MANAGEMENT ====================
-- Gerenciamento de concessionária de caminhões

Dealership = {}

-- Obter catálogo de veículos
function Dealership.GetCatalog()
    local catalog = {}
    
    for _, vehicle in ipairs(Config.Vehicles) do
        table.insert(catalog, {
            model = vehicle.model,
            name = vehicle.name,
            price = vehicle.price,
            capacity = vehicle.capacity,
            fuel_consumption = vehicle.fuel_consumption,
            max_weight = vehicle.max_weight,
            image = vehicle.image,
            required_level = vehicle.required_level,
        })
    end
    
    return catalog
end

-- Comprar veículo
function Dealership.BuyVehicle(source, vehicleModel)
    local identifier = Framework.GetIdentifier(source)
    
    if not identifier then
        return false, 'invalid_player'
    end
    
    -- Encontrar veículo no catálogo
    local vehicleData = nil
    for _, vehicle in ipairs(Config.Vehicles) do
        if vehicle.model == vehicleModel then
            vehicleData = vehicle
            break
        end
    end
    
    if not vehicleData then
        return false, 'vehicle_not_found'
    end
    
    -- Obter perfil do jogador
    local profile = Players.GetProfile(identifier)
    if not profile then
        return false, 'player_not_found'
    end
    
    -- Verificar nível
    if profile.level < vehicleData.required_level then
        return false, 'insufficient_level'
    end
    
    -- Verificar dinheiro
    if profile.total_money < vehicleData.price then
        return false, 'insufficient_funds'
    end
    
    -- Remover dinheiro
    local success = Players.RemoveMoney(identifier, vehicleData.price, 'vehicle_purchase')
    
    if success then
        -- Criar registro de veículo
        local vehicleId = 'VEH-' .. Utils.GenerateRandomCode(12)
        local plate = 'LF' .. string.format('%06d', math.random(1, 999999))
        
        local insertQuery = [[
            INSERT INTO trucking_vehicles
            (vehicle_id, model_name, owner_type, owner_identifier, plate, purchase_price, 
             fuel_consumption, cargo_capacity, max_weight, current_health)
            VALUES (?, ?, 'player', ?, ?, ?, ?, ?, ?, 1000)
        ]]
        
        local insertResult = MySQL.insert.await(insertQuery, {
            vehicleId,
            vehicleModel,
            identifier,
            plate,
            vehicleData.price,
            vehicleData.fuel_consumption,
            vehicleData.capacity,
            vehicleData.max_weight,
        })
        
        if insertResult then
            -- Log auditoria
            Database.LogAudit(
                'vehicle_purchased',
                identifier,
                profile.player_name,
                vehicleId,
                'vehicle',
                insertResult,
                { model = vehicleModel, price = vehicleData.price, plate = plate },
                'not_owned',
                'owned'
            )
            
            Framework.Notify(source, 'Veículo comprado com sucesso! Placa: ' .. plate, 'success', 5000)
            
            return true, {
                vehicle_id = vehicleId,
                plate = plate,
                model = vehicleModel,
            }
        end
    end
    
    return false, 'purchase_failed'
end

-- Financiar veículo
function Dealership.FinanceVehicle(source, vehicleModel, months)
    local identifier = Framework.GetIdentifier(source)
    
    if not identifier then
        return false, 'invalid_player'
    end
    
    months = math.max(1, math.min(months, 60))
    
    -- Encontrar veículo
    local vehicleData = nil
    for _, vehicle in ipairs(Config.Vehicles) do
        if vehicle.model == vehicleModel then
            vehicleData = vehicle
            break
        end
    end
    
    if not vehicleData then
        return false, 'vehicle_not_found'
    end
    
    -- Obter perfil
    local profile = Players.GetProfile(identifier)
    if not profile then
        return false, 'player_not_found'
    end
    
    -- Calcular financiamento
    local interestRate = Config.Economy.VehicleLoanInterest
    local principal = vehicleData.price
    local totalAmount = principal * (1 + (interestRate * months))
    local monthlyPayment = math.floor(totalAmount / months)
    
    -- Criar empréstimo
    local loanUUID = Utils.GenerateUUID()
    local dueDate = os.time() + (months * 30 * 24 * 3600)
    
    local loanQuery = [[
        INSERT INTO trucking_loans
        (loan_uuid, player_identifier, loan_type, principal_amount, interest_rate,
         total_amount, installment_amount, installments_total, status, due_date)
        VALUES (?, ?, 'vehicle', ?, ?, ?, ?, ?, 'active', ?)
    ]]
    
    local loanResult = MySQL.insert.await(loanQuery, {
        loanUUID,
        identifier,
        principal,
        interestRate,
        totalAmount,
        monthlyPayment,
        months,
        dueDate,
    })
    
    if loanResult then
        -- Criar veículo (sem cobrar, empréstimo foi criado)
        local vehicleId = 'VEH-' .. Utils.GenerateRandomCode(12)
        local plate = 'LF' .. string.format('%06d', math.random(1, 999999))
        
        local insertQuery = [[
            INSERT INTO trucking_vehicles
            (vehicle_id, model_name, owner_type, owner_identifier, plate, purchase_price,
             fuel_consumption, cargo_capacity, max_weight, current_health)
            VALUES (?, ?, 'player', ?, ?, ?, ?, ?, ?, 1000)
        ]]
        
        local vehicleInsertResult = MySQL.insert.await(insertQuery, {
            vehicleId,
            vehicleModel,
            identifier,
            plate,
            vehicleData.price,
            vehicleData.fuel_consumption,
            vehicleData.capacity,
            vehicleData.max_weight,
        })
        
        if vehicleInsertResult then
            -- Log auditoria
            Database.LogAudit(
                'vehicle_financed',
                identifier,
                profile.player_name,
                vehicleId,
                'vehicle',
                vehicleInsertResult,
                { model = vehicleModel, price = vehicleData.price, monthly_payment = monthlyPayment, months = months },
                'not_owned',
                'financed'
            )
            
            Framework.Notify(source, 'Veículo financiado! Parcela: ' .. Utils.FormatMoney(monthlyPayment), 'success', 5000)
            
            return true, {
                loan_id = loanResult,
                vehicle_id = vehicleId,
                plate = plate,
                monthly_payment = monthlyPayment,
                months = months,
            }
        end
    end
    
    return false, 'financing_failed'
end

return Dealership