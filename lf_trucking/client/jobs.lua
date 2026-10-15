-- ==================== CLIENT JOBS MANAGEMENT ====================
-- Gerenciamento de contratos no cliente

ClientJobs = {}
ClientJobs.ActiveDelivery = nil

-- Aceitar contrato
function ClientJobs.Accept(contractId)
    TriggerServerCallback('lf_trucking:acceptContract', function(success, delivery)
        if success then
            ClientJobs.ActiveDelivery = delivery
            LocalPlayer.InDelivery = true
            LocalPlayer.CurrentDelivery = delivery
            
            ClientFramework.Notify('Contrato aceito! Dirija-se ao ponto de coleta.', 'success')
            
            ClientJobs.SetWaypoint(delivery.contract_id)
        else
            ClientFramework.Notify('Erro ao aceitar contrato: ' .. (delivery or 'Desconhecido'), 'error')
        end
    end, contractId)
end

-- Definir waypoint para origem
function ClientJobs.SetWaypoint(contractId)
    TriggerServerEvent('lf_trucking:getContractDetails', contractId, function(contract)
        if contract then
            SetNewWaypoint(contract.origin_x, contract.origin_y)
            ClientFramework.Notify('Waypoint definido para: ' .. contract.origin_name, 'info')
        end
    end)
end

-- Rastrear posição durante entrega
function ClientJobs.TrackPosition()
    if not ClientJobs.ActiveDelivery then
        return
    end
    
    local thread = CreateThread(function()
        while ClientJobs.ActiveDelivery do
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            
            TriggerServerEvent('lf_trucking:trackPosition', {
                delivery_uuid = ClientJobs.ActiveDelivery.delivery_uuid,
                x = coords.x,
                y = coords.y,
                z = coords.z,
            })
            
            Wait(5000)
        end
    end)
end

-- Completar entrega
function ClientJobs.Complete(deliveryId)
    TriggerServerCallback('lf_trucking:completeDelivery', function(success, result)
        if success then
            ClientFramework.Notify('Entrega concluída! Recompensa: ' .. Utils.FormatMoney(result.payment), 'success')
            
            ClientJobs.ActiveDelivery = nil
            LocalPlayer.InDelivery = false
            LocalPlayer.CurrentDelivery = nil
            
            ClearGPS()
        else
            ClientFramework.Notify('Erro: ' .. (result or 'Desconhecido'), 'error')
        end
    end, deliveryId)
end

-- Cancelar entrega
function ClientJobs.Cancel(deliveryId)
    TriggerServerCallback('lf_trucking:cancelDelivery', function(success, error)
        if success then
            ClientFramework.Notify('Entrega cancelada.', 'info')
            
            ClientJobs.ActiveDelivery = nil
            LocalPlayer.InDelivery = false
            LocalPlayer.CurrentDelivery = nil
            
            ClearGPS()
        else
            ClientFramework.Notify('Erro ao cancelar: ' .. (error or 'Desconhecido'), 'error')
        end
    end, deliveryId)
end

return ClientJobs