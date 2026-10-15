fx_version 'cerulean'
game 'gta5'

author 'LF Scripts'
description 'Sistema Avançado de Caminhoneiro'
version '1.0.0'

shared_scripts {
    'shared/config.lua',
    'shared/constants.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/nui.lua', -- Carregado primeiro para definir o objeto global NUI
    'client/framework.lua',
    'client/main.lua',
    'client/jobs.lua',
    'client/routes.lua',
    'client/deliveries.lua',
    'client/garage.lua',
    'client/inspection.lua',
    'client/fiscal.lua',
    'client/invoice.lua',
    'client/party.lua',
    'client/damage.lua',
    'client/vehicles.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/main.lua',
    'server/database.lua',
    'server/jobs.lua',
    'server/deliveries.lua',
    'server/companies.lua',
    'server/employees.lua',
    'server/fiscal.lua',
    'server/invoices.lua',
    'server/loans.lua',
    'server/progression.lua',
    'server/security.lua',
    'server/callbacks.lua',
    'server/dealership.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/components/*.js'
}
