-- ==================== CLIENT FISCAL MANAGEMENT ====================
-- Gerenciamento de sistema fiscal no cliente

ClientFiscal = {}

-- Checkpoint fiscal próximo
function ClientFiscal.CheckNearbyCheckpoints()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Aqui seria integrado com checkpoints do servidor
end

-- Apresentar documentos
function ClientFiscal.PresentDocuments(deliveryId)
    ClientFramework.Notify('Apresentando documentação...', 'info')
    
    Wait(2000)
    
    ClientFramework.Notify('Documentação aceita! Prossiga.', 'success')
end

-- Liberar checkpoint
function ClientFiscal.ClearCheckpoint(checkpointId)
    TriggerServerEvent('lf_trucking:clearCheckpoint', checkpointId)
end

return ClientFiscal