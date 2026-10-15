-- ==================== CLIENT ROUTES MANAGEMENT ====================
-- Gerenciamento de rotas e waypoints

Routes = {}
Routes.CurrentRoute = nil
Routes.Waypoints = {}

-- Criar rota
function Routes.Create(origin, destination, checkpoints)
    Routes.CurrentRoute = {
        origin = origin,
        destination = destination,
        checkpoints = checkpoints or {},
        current_checkpoint = 0,
    }
    
    return Routes.CurrentRoute
end

-- Definir waypoint para origem
function Routes.SetOriginWaypoint()
    if not Routes.CurrentRoute then
        return false
    end
    
    local origin = Routes.CurrentRoute.origin
    SetNewWaypoint(origin.x, origin.y)
    
    return true
end

-- Definir waypoint para destino
function Routes.SetDestinationWaypoint()
    if not Routes.CurrentRoute then
        return false
    end
    
    local destination = Routes.CurrentRoute.destination
    SetNewWaypoint(destination.x, destination.y)
    
    return true
end

-- Definir waypoint para próximo checkpoint
function Routes.SetCheckpointWaypoint()
    if not Routes.CurrentRoute or #Routes.CurrentRoute.checkpoints == 0 then
        return false
    end
    
    local nextCheckpoint = Routes.CurrentRoute.checkpoints[Routes.CurrentRoute.current_checkpoint + 1]
    
    if nextCheckpoint then
        SetNewWaypoint(nextCheckpoint.x, nextCheckpoint.y)
        return true
    end
    
    return false
end

-- Próximo checkpoint
function Routes.NextCheckpoint()
    if not Routes.CurrentRoute then
        return false
    end
    
    Routes.CurrentRoute.current_checkpoint = Routes.CurrentRoute.current_checkpoint + 1
    
    if Routes.CurrentRoute.current_checkpoint > #Routes.CurrentRoute.checkpoints then
        Routes.SetDestinationWaypoint()
        return true
    end
    
    Routes.SetCheckpointWaypoint()
    return true
end

-- Limpar rota
function Routes.Clear()
    ClearGPS()
    Routes.CurrentRoute = nil
    Routes.Waypoints = {}
end

return Routes