-- ==================== CLIENT PARTY MANAGEMENT ====================
-- Gerenciamento de grupos cooperativos

ClientParty = {}
ClientParty.CurrentGroup = nil

-- Criar grupo
function ClientParty.Create()
    TriggerServerEvent('lf_trucking:createGroup')
end

-- Convidar jogador
function ClientParty.Invite(targetPlayer)
    TriggerServerEvent('lf_trucking:inviteToGroup', targetPlayer)
end

-- Aceitar convite
function ClientParty.AcceptInvite(groupId)
    TriggerServerEvent('lf_trucking:acceptGroupInvite', groupId)
end

-- Deixar grupo
function ClientParty.Leave()
    if not ClientParty.CurrentGroup then
        return
    end
    
    TriggerServerEvent('lf_trucking:leaveGroup', ClientParty.CurrentGroup.id)
    ClientParty.CurrentGroup = nil
end

-- Evento: Convite recebido
RegisterNetEvent('lf_trucking:groupInviteReceived')
AddEventHandler('lf_trucking:groupInviteReceived', function(groupId, leaderName)
    ClientFramework.Notify('Convite para grupo de ' .. leaderName, 'info')
end)

-- Evento: Grupo criado
RegisterNetEvent('lf_trucking:groupCreated')
AddEventHandler('lf_trucking:groupCreated', function(group)
    ClientParty.CurrentGroup = group
    ClientFramework.Notify('Grupo criado! ID: ' .. group.id, 'success')
end)

return ClientParty