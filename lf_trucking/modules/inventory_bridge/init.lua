-- ==================== INVENTORY BRIDGE ====================
-- Integração com sistemas de inventário (opcional)

InventoryBridge = {}
InventoryBridge.Type = Config.Inventory.Type or ''
InventoryBridge.Enabled = InventoryBridge.Type ~= ''

-- Inicializar
function InventoryBridge.Init()
    if not InventoryBridge.Enabled then
        print('^3[LF_TRUCKING]^7 Inventory Bridge desativado')
        return false
    end
    
    if InventoryBridge.Type == 'ox_inventory' then
        if GetResourceState('ox_inventory') ~= 'started' then
            print('^3[LF_TRUCKING]^7 ox_inventory não encontrado')
            InventoryBridge.Enabled = false
            return false
        end
    elseif InventoryBridge.Type == 'qb-inventory' then
        if GetResourceState('qb-inventory') ~= 'started' then
            print('^3[LF_TRUCKING]^7 qb-inventory não encontrado')
            InventoryBridge.Enabled = false
            return false
        end
    end
    
    print('^2[LF_TRUCKING]^7 Inventory Bridge inicializado: ' .. InventoryBridge.Type)
    
    return true
end

-- Adicionar item
function InventoryBridge.AddItem(source, itemName, amount, data)
    if not InventoryBridge.Enabled then
        return false
    end
    
    if InventoryBridge.Type == 'ox_inventory' then
        exports['ox_inventory']:AddItem(source, itemName, amount, data)
        return true
    elseif InventoryBridge.Type == 'qb-inventory' then
        local player = Framework.GetPlayer(source)
        if player then
            player.Functions.AddItem(itemName, amount, nil, data)
            return true
        end
    end
    
    return false
end

-- Remover item
function InventoryBridge.RemoveItem(source, itemName, amount)
    if not InventoryBridge.Enabled then
        return false
    end
    
    if InventoryBridge.Type == 'ox_inventory' then
        exports['ox_inventory']:RemoveItem(source, itemName, amount)
        return true
    elseif InventoryBridge.Type == 'qb-inventory' then
        local player = Framework.GetPlayer(source)
        if player then
            player.Functions.RemoveItem(itemName, amount)
            return true
        end
    end
    
    return false
end

-- Verificar item
function InventoryBridge.HasItem(source, itemName, amount)
    if not InventoryBridge.Enabled then
        return true
    end
    
    if InventoryBridge.Type == 'ox_inventory' then
        return exports['ox_inventory']:GetItemCount(source, itemName) >= (amount or 1)
    elseif InventoryBridge.Type == 'qb-inventory' then
        local player = Framework.GetPlayer(source)
        if player then
            return player.Functions.GetItemByName(itemName) and player.Functions.GetItemByName(itemName).amount >= (amount or 1) or false
        end
    end
    
    return false
end

print('^2[LF_TRUCKING]^7 Inventory Bridge carregado')

return InventoryBridge