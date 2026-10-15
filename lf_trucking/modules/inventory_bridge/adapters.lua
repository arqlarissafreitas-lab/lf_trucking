-- ==================== INVENTORY BRIDGE ADAPTERS ====================
-- Adaptadores para diferentes sistemas de inventário

InventoryAdapters = {}

-- ==================== FALLBACK (SEM INVENTÁRIO) ====================

InventoryAdapters.fallback = {
    name = 'Fallback (Sem Inventário Integrado)',
    
    addItem = function(source, itemName, amount, data)
        -- Sem integração, simular sucesso
        return true
    end,
    
    removeItem = function(source, itemName, amount)
        -- Sem integração
        return true
    end,
    
    hasItem = function(source, itemName, amount)
        -- Sem integração, assumir que tem
        return true
    end,
    
    getItemCount = function(source, itemName)
        -- Fallback não rastreia itens
        return 0
    end,
    
    getInventory = function(source)
        -- Sem inventário
        return {}
    end,
    
    notification = function(source, message, type)
        -- Notificação simples
        TriggerClientEvent('chat:addMessage', source, {
            args = { 'Inventário', message },
            color = { 255, 165, 0 }
        })
    end,
}

-- ==================== OX_INVENTORY ====================

InventoryAdapters['ox_inventory'] = {
    name = 'OX Inventory',
    
    addItem = function(source, itemName, amount, data)
        if GetResourceState('ox_inventory') ~= 'started' then
            return InventoryAdapters.fallback.addItem(source, itemName, amount, data)
        end
        
        local success, _ = pcall(function()
            exports['ox_inventory']:AddItem(source, itemName, amount, data)
        end)
        
        return success
    end,
    
    removeItem = function(source, itemName, amount)
        if GetResourceState('ox_inventory') ~= 'started' then
            return InventoryAdapters.fallback.removeItem(source, itemName, amount)
        end
        
        local success, _ = pcall(function()
            exports['ox_inventory']:RemoveItem(source, itemName, amount)
        end)
        
        return success
    end,
    
    hasItem = function(source, itemName, amount)
        if GetResourceState('ox_inventory') ~= 'started' then
            return InventoryAdapters.fallback.hasItem(source, itemName, amount)
        end
        
        local success, result = pcall(function()
            return exports['ox_inventory']:GetItemCount(source, itemName) >= (amount or 1)
        end)
        
        return success and result or false
    end,
    
    getItemCount = function(source, itemName)
        if GetResourceState('ox_inventory') ~= 'started' then
            return 0
        end
        
        local success, result = pcall(function()
            return exports['ox_inventory']:GetItemCount(source, itemName)
        end)
        
        return success and result or 0
    end,
    
    getInventory = function(source)
        if GetResourceState('ox_inventory') ~= 'started' then
            return {}
        end
        
        local success, result = pcall(function()
            return exports['ox_inventory']:GetInventory(source)
        end)
        
        return success and result or {}
    end,
    
    notification = function(source, message, type)
        type = type or 'info'
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Inventário',
            description = message,
            type = type,
            duration = 5000,
        })
    end,
}

-- ==================== QB-INVENTORY ====================

InventoryAdapters['qb-inventory'] = {
    name = 'QB Inventory',
    
    addItem = function(source, itemName, amount, data)
        if GetResourceState('qb-inventory') ~= 'started' then
            return InventoryAdapters.fallback.addItem(source, itemName, amount, data)
        end
        
        local player = Framework.GetPlayer(source)
        
        if not player then
            return false
        end
        
        local success, _ = pcall(function()
            player.Functions.AddItem(itemName, amount, nil, data)
        end)
        
        return success
    end,
    
    removeItem = function(source, itemName, amount)
        if GetResourceState('qb-inventory') ~= 'started' then
            return InventoryAdapters.fallback.removeItem(source, itemName, amount)
        end
        
        local player = Framework.GetPlayer(source)
        
        if not player then
            return false
        end
        
        local success, _ = pcall(function()
            player.Functions.RemoveItem(itemName, amount)
        end)
        
        return success
    end,
    
    hasItem = function(source, itemName, amount)
        if GetResourceState('qb-inventory') ~= 'started' then
            return InventoryAdapters.fallback.hasItem(source, itemName, amount)
        end
        
        local player = Framework.GetPlayer(source)
        
        if not player then
            return false
        end
        
        local item = player.Functions.GetItemByName(itemName)
        
        return item and item.amount >= (amount or 1) or false
    end,
    
    getItemCount = function(source, itemName)
        if GetResourceState('qb-inventory') ~= 'started' then
            return 0
        end
        
        local player = Framework.GetPlayer(source)
        
        if not player then
            return 0
        end
        
        local item = player.Functions.GetItemByName(itemName)
        
        return item and item.amount or 0
    end,
    
    getInventory = function(source)
        if GetResourceState('qb-inventory') ~= 'started' then
            return {}
        end
        
        local player = Framework.GetPlayer(source)
        
        if not player then
            return {}
        end
        
        return player.PlayerData.items or {}
    end,
    
    notification = function(source, message, type)
        type = type or 'primary'
        TriggerClientEvent('QBCore:Notify', source, message, type, 5000)
    end,
}

-- ==================== FUNCTION HELPER ====================

function InventoryAdapters.GetAdapter(adapterName)
    local adapter = InventoryAdapters[adapterName or Config.Inventory.Type]
    
    if not adapter then
        print('^1[LF_TRUCKING] Inventory adapter não encontrado: ' .. (adapterName or 'desconhecido') .. '^7')
        return InventoryAdapters.fallback
    end
    
    return adapter
end

return InventoryAdapters