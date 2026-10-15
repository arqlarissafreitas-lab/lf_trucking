-- ==================== KEYS BRIDGE ====================
-- Integração com sistemas de chaves (opcional)

KeysBridge = {}
KeysBridge.Type = Config.Keys.Type or 'fallback'
KeysBridge.Enabled = true

-- Inicializar
function KeysBridge.Init()
    print('^2[LF_TRUCKING]^7 Keys Bridge inicializado: ' .. KeysBridge.Type)
    return true
end

-- Dar chave do veículo
function KeysBridge.GiveKey(source, vehiclePlate, vehicleModel)
    if KeysBridge.Type == 'fallback' then
        -- Sem sistema de chaves
        return true
    elseif KeysBridge.Type == 'qb-vehiclekeys' then
        if GetResourceState('qb-vehiclekeys') == 'started' then
            exports['qb-vehiclekeys']:AddNewKey({
                plate = vehiclePlate,
                model = vehicleModel,
                citizen = GetPlayerIdentifier(source, 0),
            })
            return true
        end
    elseif KeysBridge.Type == 'esx-carlock' then
        if GetResourceState('esx-carlock') == 'started' then
            TriggerEvent('esx_carlock:giveVehicleKey', source, vehiclePlate)
            return true
        end
    end
    
    return false
end

-- Remover chave do veículo
function KeysBridge.RemoveKey(source, vehiclePlate)
    if KeysBridge.Type == 'fallback' then
        return true
    elseif KeysBridge.Type == 'qb-vehiclekeys' then
        if GetResourceState('qb-vehiclekeys') == 'started' then
            exports['qb-vehiclekeys']:RemoveKey({
                plate = vehiclePlate,
                citizen = GetPlayerIdentifier(source, 0),
            })
            return true
        end
    end
    
    return false
end

-- Verificar se tem chave
function KeysBridge.HasKey(source, vehiclePlate)
    if KeysBridge.Type == 'fallback' then
        return true
    elseif KeysBridge.Type == 'qb-vehiclekeys' then
        if GetResourceState('qb-vehiclekeys') == 'started' then
            local hasKey = exports['qb-vehiclekeys']:HasKey(vehiclePlate)
            return hasKey
        end
    end
    
    return false
end

return KeysBridge