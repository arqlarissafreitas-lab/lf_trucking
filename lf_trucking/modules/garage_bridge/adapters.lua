-- ==================== GARAGE BRIDGE ADAPTERS ====================
-- Adaptadores para diferentes sistemas de garagem

GarageAdapters = {}

-- ==================== FALLBACK (GARAGEM SIMPLES) ====================

GarageAdapters.fallback = {
    name = 'Fallback (Garagem Simples)',
    
    spawnVehicle = function(source, model, coords, heading, callback)
        TriggerClientEvent('lf_trucking:spawnVehicle', source, {
            model = model,
            coords = coords,
            heading = heading,
        })
        
        if callback then
            callback(true)
        end
    end,
    
    storeVehicle = function(source, vehicleNetId, callback)
        TriggerClientEvent('lf_trucking:storeVehicle', source, vehicleNetId)
        
        if callback then
            callback(true)
        end
    end,
    
    deleteVehicle = function(vehicleNetId)
        TriggerClientEvent('lf_trucking:deleteVehicle', -1, vehicleNetId)
    end,
    
    getVehicles = function(source, ownerIdentifier, callback)
        -- Fallback retorna lista do banco diretamente
        local query = 'SELECT * FROM trucking_vehicles WHERE owner_identifier = ? AND is_available = TRUE'
        local vehicles = MySQL.query.await(query, { ownerIdentifier })
        
        if callback then
            callback(vehicles or {})
        end
    end,
    
    isVehicleStored = function(vehicleNetId, callback)
        -- Fallback não rastreia estado de garagem
        if callback then
            callback(false)
        end
    end,
}

-- ==================== T0SIC'S ADVANCED GARAGE ====================

GarageAdapters['t0sic_garage'] = {
    name = 't0sic Advanced Garage',
    
    spawnVehicle = function(source, model, coords, heading, callback)
        if GetResourceState('t0sic_garage') ~= 'started' then
            return GarageAdapters.fallback.spawnVehicle(source, model, coords, heading, callback)
        end
        
        local success, _ = pcall(function()
            TriggerEvent('t0sic_garage:spawnVehicle', source, model, coords, heading, callback)
        end)
        
        if not success and callback then
            callback(false)
        end
    end,
    
    storeVehicle = function(source, vehicleNetId, callback)
        if GetResourceState('t0sic_garage') ~= 'started' then
            return GarageAdapters.fallback.storeVehicle(source, vehicleNetId, callback)
        end
        
        local success, _ = pcall(function()
            TriggerEvent('t0sic_garage:storeVehicle', source, vehicleNetId, callback)
        end)
        
        if not success and callback then
            callback(false)
        end
    end,
    
    deleteVehicle = function(vehicleNetId)
        if GetResourceState('t0sic_garage') == 'started' then
            TriggerEvent('t0sic_garage:deleteVehicle', vehicleNetId)
        end
    end,
    
    getVehicles = function(source, ownerIdentifier, callback)
        if GetResourceState('t0sic_garage') ~= 'started' then
            return GarageAdapters.fallback.getVehicles(source, ownerIdentifier, callback)
        end
        
        local success, result = pcall(function()
            return exports['t0sic_garage']:GetPlayerVehicles(ownerIdentifier)
        end)
        
        if callback then
            callback(success and result or {})
        end
    end,
    
    isVehicleStored = function(vehicleNetId, callback)
        if GetResourceState('t0sic_garage') ~= 'started' then
            return GarageAdapters.fallback.isVehicleStored(vehicleNetId, callback)
        end
        
        local success, result = pcall(function()
            return exports['t0sic_garage']:IsVehicleStored(vehicleNetId)
        end)
        
        if callback then
            callback(success and result or false)
        end
    end,
}

-- ==================== QB-GARAGE ====================

GarageAdapters['qb-garage'] = {
    name = 'QB-Garage',
    
    spawnVehicle 