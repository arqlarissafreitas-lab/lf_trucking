-- ==================== INVOICE MANAGEMENT ====================
-- Gerenciamento de notas fiscais fictícias

Invoices = {}
Invoices.Cache = {}

-- Emitir nota fiscal
function Invoices.Issue(source, deliveryId)
    local identifier = Framework.GetIdentifier(source)
    
    if not identifier then
        return false, 'invalid_player'
    end
    
    -- Obter entrega
    local deliveryQuery = 'SELECT * FROM trucking_deliveries WHERE id = ? AND player_identifier = ?'
    local deliveryResult = MySQL.query.await(deliveryQuery, { deliveryId, identifier })
    
    if not deliveryResult or #deliveryResult == 0 then
        return false, 'delivery_not_found'
    end
    
    local delivery = deliveryResult[1]
    
    -- Validações
    if delivery.status ~= 'invoice_pending' then
        return false, 'invalid_state'
    end
    
    -- Verificar se já tem invoice
    local invoiceCheckQuery = 'SELECT id FROM trucking_invoices WHERE delivery_id = ?'
    local invoiceCheckResult = MySQL.query.await(invoiceCheckQuery, { deliveryId })
    
    if invoiceCheckResult and #invoiceCheckResult > 0 then
        return false, 'invoice_already_exists'
    end
    
    -- Obter contrato
    local contract = Jobs.Get(delivery.contract_id)
    if not contract then
        return false, 'contract_not_found'
    end
    
    -- Obter perfil do jogador
    local profile = Players.GetProfile(identifier)
    if not profile then
        return false, 'player_not_found'
    end
    
    -- Preparar dados da invoice
    local invoiceData = {
        shipper_name = contract.shipper_name,
        carrier_name = profile.company_id and (Companies.Get(profile.company_id) and Companies.Get(profile.company_id).name or 'Transportadora') or 'Motorista Autônomo',
        carrier_cnpj = '00.000.000/0000-00',
        driver_name = profile.player_name,
        driver_id = identifier,
        vehicle_plate = delivery.vehicle_plate,
        vehicle_model = 'Caminhão Trator',
        cargo_type = contract.cargo_type,
        cargo_description = contract.cargo_description or '',
        cargo_weight = contract.cargo_weight,
        cargo_value = contract.cargo_value,
        origin_city = contract.origin_name,
        destination_city = contract.destination_name,
        issued_by = 'SISTEMA',
    }
    
    -- Criar invoice no banco
    local invoice = Database.CreateInvoice(deliveryId, delivery.contract_id, invoiceData)
    
    if invoice then
        -- Atualizar entrega
        local updateQuery = 'UPDATE trucking_deliveries SET invoice_id = ?, status = "fiscal_clearance_pending" WHERE id = ?'
        MySQL.update.await(updateQuery, { invoice.id, deliveryId })
        
        -- Log auditoria
        Database.LogAudit(
            'invoice_issued',
            identifier,
            profile.player_name,
            'invoice_' .. invoice.invoice_uuid,
            'invoice',
            invoice.id,
            { invoice_number = invoice.invoice_number, delivery_id = deliveryId },
            'pending',
            'issued'
        )
        
        Invoices.Cache[invoice.id] = invoice
        
        return true, invoice
    end
    
    return false, 'issuance_failed'
end

-- Obter invoice
function Invoices.Get(invoiceId)
    if Invoices.Cache[invoiceId] then
        return Invoices.Cache[invoiceId]
    end
    
    local invoice = Database.GetInvoiceById(invoiceId)
    if invoice then
        Invoices.Cache[invoiceId] = invoice
    end
    
    return invoice
end

-- Obter invoice da entrega
function Invoices.GetByDelivery(deliveryId)
    local query = 'SELECT * FROM trucking_invoices WHERE delivery_id = ?'
    local result = MySQL.query.await(query, { deliveryId })
    return result and result[1] or nil
end

-- Validar invoice
function Invoices.Validate(invoiceId)
    local invoice = Invoices.Get(invoiceId)
    
    if not invoice then
        return false, 'invoice_not_found'
    end
    
    if invoice.status == 'cancelled' or invoice.status == 'invalid' then
        return false, 'invoice_invalid'
    end
    
    if invoice.status == 'rejected' then
        return false, 'invoice_rejected'
    end
    
    return true
end

-- Limpar invoice
function Invoices.Cancel(source, invoiceId, reason)
    local identifier = Framework.GetIdentifier(source)
    
    if not identifier then
        return false, 'invalid_player'
    end
    
    -- Verificar permissão (apenas admin ou sistema)
    if not Framework.IsAdmin(source) then
        return false, 'unauthorized'
    end
    
    local invoice = Invoices.Get(invoiceId)
    if not invoice then
        return false, 'invoice_not_found'
    end
    
    -- Atualizar status
    local query = 'UPDATE trucking_invoices SET status = "cancelled", rejected_reason = ?, rejected_by = ? WHERE id = ?'
    MySQL.update.await(query, { reason, identifier, invoiceId })
    
    -- Limpar cache
    Invoices.Cache[invoiceId] = nil
    
    -- Log auditoria
    Database.LogAudit(
        'invoice_cancelled',
        identifier,
        'Admin',
        'invoice_' .. invoice.invoice_uuid,
        'invoice',
        invoice.id,
        { reason = reason },
        'issued',
        'cancelled'
    )
    
    return true
end

-- Formatar invoice para visualização
function Invoices.Format(invoice)
    if not invoice then
        return nil
    end
    
    return {
        id = invoice.id,
        number = invoice.invoice_number,
        uuid = invoice.invoice_uuid,
        status = invoice.status,
        validation_code = invoice.validation_code,
        shipper = invoice.shipper_name,
        carrier = invoice.carrier_name,
        driver = invoice.driver_name,
        vehicle_plate = invoice.vehicle_plate,
        cargo_type = invoice.cargo_type,
        cargo_description = invoice.cargo_description,
        cargo_weight = invoice.cargo_weight,
        cargo_value = Utils.FormatMoney(invoice.cargo_value),
        origin = invoice.origin_city,
        destination = invoice.destination_city,
        issued_at = Utils.FormatTimestamp(invoice.issued_at),
        issued_by = invoice.issued_by,
        cleared_at = invoice.cleared_at and Utils.FormatTimestamp(invoice.cleared_at) or 'Pendente',
        cleared_by = invoice.cleared_by or 'Pendente',
    }
end

return Invoices