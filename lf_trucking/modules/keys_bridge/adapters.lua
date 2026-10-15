-- ==================== KEYS BRIDGE ADAPTERS ====================
-- Adaptadores para diferentes sistemas de chaves de veículos

KeysAdapters = {}

-- ==================== FALLBACK (SEM SISTEMA DE CHAVES) ====================

KeysAdapters.fallback = {
    name = 'Fallback (Sem Sistema)',
    
    giveKey = function(source, plate, model)
        -- Sem integração, permitir acesso livre
        return true
    end,
    
    removeKey = function(source, plate)
        -- Sem integração
        return true
    end,
    
    hasKey = function(source, plate)
        -- Sem integração, sempre retorna true
        return true
    end,
    
    getKeys = function(source)
        -- Retorna lista vazia
        return {}
    end,
    
    canEnterVehicle = function(source, plate)
        -- Sem integração, sempre permite
        return true
    end,
}

-- ==================== QB-VEHICLEKEYS ====================

KeysAdapters['qb-vehiclekeys'] = {
    name = 'QB VehicleKeys',
    
    giveKey = function(source, plate, model)
        if GetResourceState('qb-vehiclekeys') ~= 'started' then
            return false
        end
        
        local citizen = GetPlayerIdentifier(source, 0)
        
        local success, _ = pcall(function()
            exports['qb-vehiclekeys']:AddNewKey({
                plate = plate,
                model = model,
                citizen = citizen,
            })
        end)
        
        return success
    end,
    
    removeKey = function(source, plate)
        if GetResourceState('qb-vehiclekeys') ~= 'started' then
            return false
        end
        
        local citizen = GetPlayerIdentifier(source, 0)
        
        local success, _ = pcall(function()
            exports['qb-vehiclekeys']:RemoveKey({
                plate = plate,
                citizen = citizen,
            })
        end)
        
        return success
    end,
    
    hasKey = function(source, plate)
        if GetResourceState('qb-vehiclekeys') ~= 'started' then
            return true
        end
        
        local success, result = pcall(function()
            return exports['qb-vehiclekeys']:HasKey(plate)
        end)
        
        return success and result or false
    end,
    
    getKeys = function(source)
        if GetResourceState('qb-vehiclekeys') ~= 'started' then
            return {}
        end
        
        local success, result = pcall(function()
            return exports['qb-vehiclekeys']:GetKeys()
        end)
        
        return success and result or {}
    end,
    
    canEnterVehicle = function(source, plate)
        -- QB permite enter se tiver chave
        return KeysAdapters['qb-vehiclekeys'].hasKey(source, plate)
    end,
}

-- ==================== ESX-CARLOCK ====================

KeysAdapters['esx-carlock'] = {
    name = 'ESX CarLock',
    
    giveKey = function(source, plate, model)
        if GetResourceState('esx-carlock') ~= 'started' then
            return false
        end
        
        local success, _ = pcall(function()
            TriggerEvent('esx_carlock:giveVehicleKey', source, plate)
        end)
        
        return success
    end,
    
    removeKey = function(source, plate)
        if GetResourceState('esx-carlock') ~= 'started' then
            return false
        end
        
        local success, _ = pcall(function()
            TriggerEvent('esx_carlock:removeVehicleKey', source, plate)
        end)
        
        return success
    end,
    
    hasKey = function(source, plate)
        if GetResourceState('esx-carlock') ~= 'started' then
            return true
        end
        
        -- ESX carlock não exporta função de verificação
        -- Retorna true por segurança
        return true
    end,
    
    getKeys = function(source)
        -- ESX carlock não fornece lista de chaves
        return {}
    end,
    
    canEnterVehicle = function(source, plate)
        return KeysAdapters['esx-carlock'].hasKey(source, plate)
    end,
}

-- ==================== ADVANCED CARLOCK ====================

KeysAdapters['advanced-carlock'] = {
    name = 'Advanced CarLock',
    
    giveKey = function(source, plate, model)
        if GetResourceState('advanced-carlock') ~= 'started' then
            return false
        end
        
        local success, _ = pcall(function()
            TriggerEvent('advancedcarlock:giveKey', source, plate)
        end)
        
        return success
    end,
    
    removeKey = function(source, plate)
        if GetResourceState('advanced-carlock') ~= 'started' then
            return false
        end
        
        local success, _ = pcall(function()
            TriggerEvent('advancedcarlock:removeKey', source, plate)
        end)
        
        return success
    end,
    
    hasKey = function(source, plate)
        if GetResourceState('advanced-carlock') ~= 'started' then
            return true
        end
        
        local success, result = pcall(function()
            return exports['advanced-carlock']:hasKey(plate)
        end)
        
        return success and result or false
    end,
    
    getKeys = function(source)
        if GetResourceState('advanced-carlock') ~= 'started' then
            return {}
        end
        
        local success, result = pcall(function()
            return exports['advanced-carlock']:getKeys(source)
        end)
        
        return success and result or {}
    end,
    
    canEnterVehicle = function(source, plate)
        return KeysAdapters['advanced-carlock'].hasKey(source, plate)
    end,
}

-- ==================== FUNCTION HELPER ====================

function KeysAdapters.GetAdapter(adapterName)
    local adapter = KeysAdapters[adapterName or Config.Keys.Type]
    
    if not adapter then
        print('^1[LF_TRUCKING] Chaves bridge não encontrado: ' .. (adapterName or 'desconhecido') .. '^7')
        return KeysAdapters.fallback
    end
    
    return adapter