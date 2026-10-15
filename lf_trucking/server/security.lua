-- ==================== SECURITY ====================
-- Validações de segurança e prevenção de exploits

Security = {}

-- Rate limiter
Security.RateLimits = {}

-- Verificar rate limit
function Security.CheckRateLimit(identifier, action, timeout)
    timeout = timeout or Config.General.RateLimitMs
    
    local key = identifier .. ':' .. action
    local now = Utils.GetTimestampMs()
    
    if Security.RateLimits[key] and (now - Security.RateLimits[key]) < timeout then
        return false
    end
    
    Security.RateLimits[key] = now
    return true
end

-- Validar distância
function Security.ValidateDistance(x1, y1, z1, x2, y2, z2, maxDistance)
    local distance = Utils.Distance(x1, y1, z1, x2, y2, z2)
    return distance <= maxDistance
end

-- Validar propriedade
function Security.ValidateVehicleOwnership(identifier, vehicleId)
    local query = 'SELECT owner_identifier FROM trucking_vehicles WHERE vehicle_id = ?'
    local result = MySQL.query.await(query, { vehicleId })
    
    if not result or #result == 0 then
        return false
    end
    
    return result[1].owner_identifier == identifier
end

-- Validar entrega
function Security.ValidateDeliveryOwnership(identifier, deliveryId)
    local query = 'SELECT player_identifier FROM trucking_deliveries WHERE id = ?'
    local result = MySQL.query.await(query, { deliveryId })
    
    if not result or #result == 0 then
        return false
    end
    
    return result[1].player_identifier == identifier
end

-- Validar estado de entrega
function Security.ValidateDeliveryState(deliveryId, expectedState)
    local query = 'SELECT status FROM trucking_deliveries WHERE id = ?'
    local result = MySQL.query.await(query, { deliveryId })
    
    if not result or #result == 0 then
        return false
    end
    
    return result[1].status == expectedState
end

-- Validar pagamento não duplicado
function Security.ValidateNoDoublePayment(deliveryId)
    local query = 'SELECT is_paid FROM trucking_deliveries WHERE id = ?'
    local result = MySQL.query.await(query, { deliveryId })
    
    if not result or #result == 0 then
        return false
    end
    
    return not result[1].is_paid
end

-- Sanitizar entrada
function Security.Sanitize(input)
    if type(input) == 'string' then
        return Utils.Trim(input)
    end
    
    return input
end

-- Log de segurança
function Security.LogSecurityEvent(eventType, identifier, details)
    Database.LogAudit(
        'security_event_' .. eventType,
        identifier,
        'Unknown',
        identifier,
        'security',
        nil,
        details or {},
        'normal',
        'flagged'
    )
    
    print('^1[LF_TRUCKING] SECURITY: ' .. eventType .. ' por ' .. (identifier or 'unknown') .. '^7')
end

return Security