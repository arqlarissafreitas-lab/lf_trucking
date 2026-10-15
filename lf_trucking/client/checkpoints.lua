-- ==================== CLIENT CHECKPOINTS ====================
-- Gerenciamento de checkpoints fiscais no cliente

ClientCheckpoints = {}
ClientCheckpoints.Active = {}

-- Criar checkpoint visual
function ClientCheckpoints.Create(checkpointId, coords, radius)
    if ClientCheckpoints.Active[checkpointId] then
        DeleteCheckpoint(ClientCheckpoints.Active[checkpointId])
    end
    
    local checkpoint = CreateCheckpoint(
        27,
        coords.x, coords.y, coords.z - 1.0,
        coords.x, coords.y, coords.z + 1.0,
        radius,
        255, 165, 0, 100, 0
    )
    
    ClientCheckpoints.Active[checkpointId] = checkpoint
    
    return checkpoint
end

-- Deletar checkpoint
function ClientCheckpoints.Delete(checkpointId)
    if ClientCheckpoints.Active[checkpointId] then
        DeleteCheckpoint(ClientCheckpoints.Active[checkpointId])
        ClientCheckpoints.Active[checkpointId] = nil
    end
end

-- Monitorar checkpoints
function ClientCheckpoints.Monitor()
    CreateThread(function()
        while true do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for checkpointId, checkpoint in pairs(ClientCheckpoints.Active) do
                local checkpointCoords = GetCheckpointCoords(checkpoint)
                local distance = Utils.Distance(playerCoords.x, playerCoords.y, playerCoords.z, checkpointCoords.x, checkpointCoords.y, checkpointCoords.z)
                
                if distance < 50 then
                    if distance < 10 then
                        TriggerServerEvent('lf_trucking:checkpointEntered', checkpointId)
                    end
                end
            end
            
            Wait(1000)
        end
    end)
end

-- Limpar todos os checkpoints
function ClientCheckpoints.ClearAll()
    for checkpointId, _ in pairs(ClientCheckpoints.Active) do
        ClientCheckpoints.Delete(checkpointId)
    end
    
    ClientCheckpoints.Active = {}
end

return ClientCheckpoints