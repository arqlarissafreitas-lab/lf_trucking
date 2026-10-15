-- ==================== CLIENT DAMAGE MANAGEMENT ====================
-- Gerenciamento de danos a veículo e carga

ClientDamage = {}

-- Rastrear dano
function ClientDamage.Track(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        return 0
    end
    
    local health = GetVehicleEngineHealth(vehicle)
    local damagePercent = math.floor((1000 - health) / 10)
    
    return math.max(0, damagePercent)
end

-- Monitorar integridade de carga
function ClientDamage.MonitorCargo(deliveryId)
    CreateThread(function()
        while ClientJobs.ActiveDelivery and ClientJobs.ActiveDelivery.id == deliveryId do
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            if vehicle ~= 0 then
                local damage = ClientDamage.Track(vehicle)
                
                if damage > 50 then
                    TriggerServerEvent('lf_trucking:updateCargoIntegrity', deliveryId, false)
                end
            end
            
            Wait(5000)
        end
    end)
end

-- Calcular penalidade por danos
function ClientDamage.GetDamageMultiplier(damagePercent)
    if damagePercent == 0 then
        return 1.1 -- 10% bônus
    elseif damagePercent < 25 then
        return 1.0
    elseif damagePercent < 50 then
        return 0.9 -- 10% penalidade
    elseif damagePercent < 75 then
        return 0.7 -- 30% penalidade
    else
        return 0.5 -- 50% penalidade
    end
end

return ClientDamage