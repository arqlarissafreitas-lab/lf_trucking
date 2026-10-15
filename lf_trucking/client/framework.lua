-- ==================== CLIENT FRAMEWORK ADAPTER ====================

ClientFramework = {}

-- Obter objeto do framework
function ClientFramework.GetESX()
    return ESX
end

function ClientFramework.GetQBCore()
    return QBCore
end

-- Notificar
function ClientFramework.Notify(message, type, duration)
    type = type or 'info'
    duration = duration or 5000
    
    if Config.Notification.Type == 'native' then
        TriggerEvent('chat:addMessage', {
            args = { 'Trucking', message },
            color = { 255, 165, 0 }
        })
    elseif Config.Notification.Type == 'ox_lib' then
        if lib and lib.notify then
            lib.notify({
                title = 'Trucking',
                description = message,
                type = type,
                duration = duration,
                position = Config.Notification.Position
            })
        else
            TriggerEvent('chat:addMessage', {
                args = { 'Trucking', message },
                color = { 255, 165, 0 }
            })
        end
    elseif Config.Notification.Type == 'esx_notify' then
        TriggerEvent('esx:showNotification', message)
    elseif Config.Notification.Type == 'qb_notify' then
        TriggerEvent('QBCore:Notify', message, type, duration)
    else
        TriggerEvent('chat:addMessage', {
            args = { 'Trucking', message },
            color = { 255, 165, 0 }
        })
    end
end

-- Progressbar
function ClientFramework.Progressbar(label, duration, callback)
    if lib and lib.progressBar then
        lib.progressBar({
            duration = duration,
            label = label,
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
            },
        }, function(cancelled)
            if not cancelled and callback then
                callback()
            end
        end)
    else
        Wait(duration)
        if callback then
            callback()
        end
    end
end

return ClientFramework