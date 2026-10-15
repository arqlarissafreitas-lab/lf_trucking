-- ==================== CLIENT INVOICE MANAGEMENT ====================
-- Gerenciamento de notas fiscais no cliente

ClientInvoice = {}

-- Emitir nota fiscal
function ClientInvoice.Issue(deliveryId)
    TriggerServerCallback('lf_trucking:issueInvoice', function(success, invoice)
        if success then
            ClientFramework.Notify('Nota Fiscal emitida com sucesso!', 'success')
            
            ClientInvoice.DisplayInvoice(invoice)
        else
            ClientFramework.Notify('Erro ao emitir NF: ' .. (invoice or 'Desconhecido'), 'error')
        end
    end, deliveryId)
end

-- Exibir nota fiscal
function ClientInvoice.DisplayInvoice(invoice)
    if not invoice then
        return
    end
    
    local message = [[
    ╔════════════════════════════════════════════════╗
    ║         NOTA FISCAL - SISTEMA DE RP           ║
    ║         [DOCUMENTO FICTÍCIO]                  ║
    ╠════════════════════════════════════════════════╣
    ║ Número: %s
    ║ Código: %s
    ║ Status: %s
    ║
    ║ Remetente: %s
    ║ Transportadora: %s
    ║ Motorista: %s
    ║
    ║ Veículo: %s
    ║ Carga: %s (%d kg)
    ║ Valor: %s
    ║
    ║ Origem: %s
    ║ Destino: %s
    ║ Emissão: %s
    ╚════════════════════════════════════════════════╝
    ]]:format(
        invoice.number,
        invoice.validation_code,
        invoice.status,
        invoice.shipper,
        invoice.carrier,
        invoice.driver,
        invoice.vehicle_plate,
        invoice.cargo_type,
        invoice.cargo_weight,
        invoice.cargo_value,
        invoice.origin,
        invoice.destination,
        invoice.issued_at
    )
    
    TriggerEvent('chat:addMessage', {
        args = { 'Nota Fiscal', message },
        color = { 0, 255, 0 }
    })
end

return ClientInvoice