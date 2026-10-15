-- ==================== CLIENT INSPECTION MANAGEMENT ====================
-- Gerenciamento de inspeções (PRF)

ClientInspection = {}

-- Iniciar inspeção
function ClientInspection.Start(vehicleNetId)
    TriggerServerEvent('lf_trucking:requestInspection', vehicleNetId)
end

-- Evento: Inspeção iniciada (recebe do servidor)
RegisterNetEvent('lf_trucking:inspectionStarted')
AddEventHandler('lf_trucking:inspectionStarted', function(inspection)
    ClientFramework.Notify('Inspeção rodoviária iniciada pela PRF', 'warning')
    
    SendReactMessage('showInspectionPanel', {
        inspection = inspection
    })
end)

-- Evento: Inspeção concluída
RegisterNetEvent('lf_trucking:inspectionCompleted')
AddEventHandler('lf_trucking:inspectionCompleted', function(result, message)
    if result == 'approved' then
        ClientFramework.Notify('Inspeção aprovada! Prossiga.', 'success')
    else
        ClientFramework.Notify('Inspeção bloqueada: ' .. (message or 'Motivo não especificado'), 'error')
    end
end)

return ClientInspection