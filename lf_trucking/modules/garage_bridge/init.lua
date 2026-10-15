-- ==================== GARAGE BRIDGE ====================
-- Integração com sistemas de garagem (opcional)

GarageBridge = {}
GarageBridge.Type = Config.Garage.Type or 'fallback'
GarageBridge.Enabled = true

-- Inicializar
function GarageBridge.Init()
    print('^2[LF_TRUCKING]^7 Garage Bridge inicializado: ' .. GarageBridge.Type)
    return true
end

-- Retirar veículo
function GarageBridge.SpawnVehicle(source, vehicleModel, coords, heading, callback)
    local identifier = Framework.GetIdentifier(source)
    
    if GarageBridge.Type == 'fallback' then
        TriggerClientEvent('lf_trucking:spawnVehicle', source, {
            model = vehicleModel,
            coords = coords,
            heading = heading,
        })
    else
        -- Integração específica com garage
    end
    
    if callback then
        callback(true)
    end
end

-- Guardar veículo
function GarageBridge.StoreVehicle(source, vehicleNetId, callback)
    if GarageBridge.Type == 'fallback' then
        TriggerClientEvent('lf_trucking:storeVehicle', source, vehicleNetId)
    else
        -- Integração específica
    end
    
    if callback then
        callback(true)
    end
end

-- Deletar veículo
function GarageBridge.DeleteVehicle(vehicleNetId)
    TriggerClientEvent('lf_trucking:deleteVehicle', -1, vehicleNetId)
end

print('^2[LF_TRUCKING]^7 Garage Bridge carregado')

return GarageBridge