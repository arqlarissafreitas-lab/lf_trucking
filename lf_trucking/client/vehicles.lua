-- ==================== CLIENT VEHICLES MANAGEMENT ====================

ClientVehicles = {}

-- Despanar veículo
function ClientVehicles.Spawn(vehicleModel, coords, heading, callback)
    local modelHash = GetHashKey(vehicleModel)
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 10000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not HasModelLoaded(modelHash) then
        ClientFramework.Notify('Erro ao carregar modelo do veículo', 'error')
        return
    end
    
    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineHealth(vehicle, 1000.0)
    
    ReleaseModel(modelHash)
    
    if callback then
        callback(vehicle)
    end
    
    return vehicle
end

-- Deletar veículo
function ClientVehicles.Delete(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    
    if vehicle and DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end
end

-- Obter veículo mais próximo
function ClientVehicles.GetNearestVehicle(radius)
    radius = radius or 10.0
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicles = GetGamePool('CVehicle')
    
    local nearestVehicle = nil
    local nearestDistance = radius
    
    for _, vehicle in ipairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = Utils.Distance(playerCoords.x, playerCoords.y, playerCoords.z, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z)
        
        if distance < nearestDistance and GetPedInVehicleSeat(vehicle, -1) == 0 then
            nearestVehicle = vehicle
            nearestDistance = distance
        end
    end
    
    return nearestVehicle, nearestDistance
end

-- Entrar em veículo
function ClientVehicles.EnterVehicle(vehicle)
    local playerPed = PlayerPedId()
    local vehicle = vehicle or ClientVehicles.GetNearestVehicle()
    
    if not vehicle then
        ClientFramework.Notify('Nenhum veículo próximo.', 'error')
        return false
    end
    
    TaskStartScenarioInPlace(playerPed, 'PROP_HUMAN_SEAT_CHAIR', 0, true)
    Wait(1000)
    TaskEnterVehicle(playerPed, vehicle, -1, -1, 1.0, 1, 0)
    
    return true
end

-- Obter placa do veículo
function ClientVehicles.GetPlate(vehicle)
    return GetVehicleNumberPlateText(vehicle)
end

-- Verificar dano
function ClientVehicles.GetDamage(vehicle)
    local health = GetVehicleEngineHealth(vehicle)
    return math.floor((1000 - health) / 10)
end

return ClientVehicles