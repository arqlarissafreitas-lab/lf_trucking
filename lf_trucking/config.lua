-- ==================== CONFIGURAÇÃO CENTRAL ====================
-- LF_TRUCKING v1.0.0

Config = {}

-- ==================== FRAMEWORK ====================

Config.Framework = 'qb' -- 'esx', 'qb', 'auto' (detecção automática)

-- ==================== BANCO DE DADOS ====================

Config.Database = {
    Adapter = '', -- '', 'oxmysql', 'mysql-async', 'ghmattimysql'
    Host = 'localhost',
    Username = 'root',
    Password = '',
    Database = 'gta5_rp',
}

-- ==================== NOTIFICAÇÕES ====================

Config.Notification = {
    Type = 'native', -- 'native', 'chat', 'ox_lib', 'esx_notify', 'qb_notify'
    Position = 'top-right', -- 'top-left', 'top-right', 'bottom-left', 'bottom-right'
}

-- ==================== SISTEMA DE INTERAÇÃO ====================

Config.Interaction = {
    Type = 'marker', -- 'marker', 'target', 'ox_target', 'interact'
    MarkerType = 27,
    MarkerScale = 0.5,
    MarkerColor = { r = 255, g = 165, b = 0, a = 200 },
    DrawDistance = 100,
}

-- ==================== INVENTÁRIO ====================

Config.Inventory = {
    Type = 'qb-inventory', -- '', 'ox_inventory', 'qb-inventory', 'custom'
}

-- ==================== GARAGEM ====================

Config.Garage = {
    Type = 'qb-garage', -- 'fallback', 't0sic', 'qb-garage', 'esx-carlock'
}

-- ==================== CHAVES ====================

Config.Keys = {
    Type = 'qb-vehiclekey', -- 'fallback', 'qb-vehiclekeys', 'esx-carlock'
}

-- ==================== INTEGRAÇÃO PRF ====================

Config.PRF = {
    Enabled = false,
    ResourceName = 'job_prf',
    ESX = {
        JobName = 'prf',
    },
    QBCore = {
        JobName = 'prf',
    },
    AuthorizedRanks = {
        'officer',
        'sergeant',
        'corporal',
        'commissioner',
    },
    AuthorizedGroups = {
        'admin',
        'prf_officer',
    },
    CheckpointsRequiringPRF = {},
    NoAgentMode = 'allow',
    MinAgentsOnline = 0,
}

-- ==================== IDIOMA ====================

Config.Language = 'pt-BR'

-- ==================== DEBUG ====================

Config.Debug = false

-- ==================== GERAL ====================

Config.General = {
    MaxSimultaneousDeliveries = 1,
    MaxSimultaneousGroupDeliveries = 3,
    DeliveryRecoveryTime = 1800000,
    RateLimitMs = 1000,
}

-- ==================== CAMINHÕES DISPONÍVEIS ====================

Config.Vehicles = {
    {
        model = 'hauler',
        name = 'Hauler Standard',
        price = 450000,
        capacity = 3000,
        fuel_consumption = 0.08,
        max_weight = 15000,
        image = 'assets/images/hauler.png',
        required_level = 1,
    },
    {
        model = 'rubble',
        name = 'Rubble Truck',
        price = 350000,
        capacity = 2500,
        fuel_consumption = 0.07,
        max_weight = 12000,
        image = 'assets/images/rubble.png',
        required_level = 5,
    },
    {
        model = 'mixer',
        name = 'Cement Mixer',
        price = 500000,
        capacity = 3500,
        fuel_consumption = 0.09,
        max_weight = 18000,
        image = 'assets/images/mixer.png',
        required_level = 10,
    },
    {
        model = 'tractor',
        name = 'Trator',
        price = 200000,
        capacity = 0,
        fuel_consumption = 0.05,
        max_weight = 5000,
        image = 'assets/images/tractor.png',
        required_level = 1,
    },
}

-- ==================== TIPOS DE CARGA ====================

Config.CargoTypes = {
    {
        id = 'alimentos',
        name = 'Alimentos Perecíveis',
        description = 'Frutas, vegetais e alimentos frescos',
        damage_multiplier = 2.0,
        special_requirement = 'refrigerated',
        base_weight = 1000,
        value_per_unit = 50,
        image = 'assets/images/cargo_food.png',
    },
    {
        id = 'construcao',
        name = 'Materiais de Construção',
        description = 'Cimento, areia, tijolos',
        damage_multiplier = 1.0,
        special_requirement = nil,
        base_weight = 5000,
        value_per_unit = 20,
        image = 'assets/images/cargo_construction.png',
    },
    {
        id = 'industrial',
        name = 'Produtos Industriais',
        description = 'Máquinas, peças de metal',
        damage_multiplier = 1.5,
        special_requirement = nil,
        base_weight = 3000,
        value_per_unit = 100,
        image = 'assets/images/cargo_industrial.png',
    },
    {
        id = 'eletronicos',
        name = 'Eletrônicos',
        description = 'Computadores, TV, smartphones',
        damage_multiplier = 3.0,
        special_requirement = 'high_value',
        base_weight = 500,
        value_per_unit = 500,
        image = 'assets/images/cargo_electronics.png',
    },
    {
        id = 'quimicos',
        name = 'Produtos Químicos',
        description = 'Solventes, ácidos (fictícios)',
        damage_multiplier = 2.5,
        special_requirement = 'hazmat',
        base_weight = 1500,
        value_per_unit = 200,
        image = 'assets/images/cargo_chemicals.png',
    },
    {
        id = 'veiculos',
        name = 'Transporte de Veículos',
        description = 'Carros, motos em carga',
        damage_multiplier = 1.8,
        special_requirement = nil,
        base_weight = 2000,
        value_per_unit = 300,
        image = 'assets/images/cargo_vehicles.png',
    },
    {
        id = 'fragil',
        name = 'Cargas Frágeis',
        description = 'Vidro, cerâmica, espelhos',
        damage_multiplier = 4.0,
        special_requirement = 'fragile',
        base_weight = 800,
        value_per_unit = 150,
        image = 'assets/images/cargo_fragile.png',
    },
    {
        id = 'refrigerado',
        name = 'Transporte Refrigerado',
        description = 'Carnes, laticínios, congelados',
        damage_multiplier = 2.0,
        special_requirement = 'refrigerated',
        base_weight = 1200,
        value_per_unit = 80,
        image = 'assets/images/cargo_refrigerated.png',
    },
    {
        id = 'especial',
        name = 'Cargas Especiais',
        description = 'Combustível, equipamentos especializados',
        damage_multiplier = 3.0,
        special_requirement = 'specialized',
        base_weight = 2000,
        value_per_unit = 250,
        image = 'assets/images/cargo_special.png',
    },
    {
        id = 'alto_valor',
        name = 'Cargas de Alto Valor',
        description = 'Joias, ouro, metais preciosos',
        damage_multiplier = 2.0,
        special_requirement = 'high_value',
        base_weight = 100,
        value_per_unit = 5000,
        image = 'assets/images/cargo_highvalue.png',
    },
}

-- ==================== CERTIFICAÇÕES ====================

Config.Certifications = {
    {
        id = 'hazmat',
        name = 'Certificação HAZMAT',
        description = 'Autoriza transporte de produtos perigosos',
        cost = 50000,
        required_level = 15,
        validity_days = 365,
    },
    {
        id = 'refrigerated',
        name = 'Certificação de Transporte Refrigerado',
        description = 'Autoriza transporte de alimentos perecíveis',
        cost = 30000,
        required_level = 10,
        validity_days = 365,
    },
    {
        id = 'fragile',
        name = 'Certificação para Cargas Frágeis',
        description = 'Autoriza transporte de vidros e cerâmicas',
        cost = 25000,
        required_level = 8,
        validity_days = 365,
    },
    {
        id = 'high_value',
        name = 'Certificação para Cargas de Alto Valor',
        description = 'Autoriza transporte de valores',
        cost = 75000,
        required_level = 20,
        validity_days = 365,
    },
    {
        id = 'specialized',
        name = 'Certificação Especializada',
        description = 'Autoriza operações especializadas',
        cost = 60000,
        required_level = 18,
        validity_days = 365,
    },
}

-- ==================== CHECKPOINTS FISCAIS ====================

Config.FiscalCheckpoints = {
    {
        id = 'checkpoint_sp_rj',
        name = 'Posto Fiscal SP-RJ',
        coords = {
            x = 100.0,
            y = 100.0,
            z = 10.0,
        },
        radius = 50.0,
        requires_invoice = true,
        requires_prf_agent = false,
        is_mandatory = true,
        inspection_mode = 'auto',
        contingency_on_no_prf = 'allow',
        is_active = true,
    },
    {
        id = 'checkpoint_mg_sp',
        name = 'Posto Fiscal MG-SP',
        coords = {
            x = 200.0,
            y = 200.0,
            z = 10.0,
        },
        radius = 50.0,
        requires_invoice = true,
        requires_prf_agent = false,
        is_mandatory = true,
        inspection_mode = 'auto',
        contingency_on_no_prf = 'allow',
        is_active = true,
    },
}

-- ==================== PONTOS DE INTERESSE ====================

Config.Locations = {
    garage = {
        coords = { x = 500.0, y = -1000.0, z = 29.0 },
        heading = 0.0,
        radius = 30.0,
        blip = {
            sprite = 357,
            color = 2,
            scale = 0.8,
            label = 'Garagem de Caminhões',
        },
    },
    dealership = {
        coords = { x = 600.0, y = -1000.0, z = 29.0 },
        heading = 0.0,
        radius = 30.0,
        blip = {
            sprite = 227,
            color = 5,
            scale = 0.8,
            label = 'Concessionária de Caminhões',
        },
    },
    operations_center = {
        coords = { x = 713.1944, y = -982.2903, z = 138.0562 },
        heading = 0.0,
        radius = 30.0,
        blip = {
            sprite = 226,
            color = 3,
            scale = 0.8,
            label = 'Centro de Operações',
        },
    },
}

-- ==================== PERMISSÕES DE ROLES ====================

Config.RolePermissions = {
    owner = {
        'hire_employees',
        'fire_employees',
        'promote_employees',
        'demote_employees',
        'accept_contracts',
        'manage_fleet',
        'manage_finances',
        'manage_settings',
        'access_logs',
        'access_inspections',
    },
    director = {
        'hire_employees',
        'fire_employees',
        'promote_employees',
        'accept_contracts',
        'manage_fleet',
        'access_logs',
    },
    manager = {
        'accept_contracts',
        'manage_fleet',
        'access_logs',
    },
    driver = {
        'accept_contracts',
    },
    trainee = {},
}

-- ==================== MOTORISTAS NPC ====================

Config.NPCDrivers = {
    Enabled = false,
    MaxDriversPerCompany = 10,
    BaseSalary = 5000,
    ExpGainRate = 0.5,
}

-- ==================== GRUPOS DE ENTREGA ====================

Config.DeliveryGroups = {
    Enabled = true,
    MaxGroupSize = 5,
    RewardSplitModes = { 'equal', 'contribution', 'custom' },
}

-- ==================== ECONOMIA ====================

Config.Economy = {
    BaseMultiplier = 1.0,
    DistanceMultiplier = 1.5,
    DifficultyMultipliers = {
        easy = 0.8,
        normal = 1.0,
        hard = 1.5,
        extreme = 2.0,
    },
    TimeBonusPercent = 15,
    TimePenaltyPercent = 50,
    DamagePenaltyPercent = 20,
    DeviationPenaltyPercent = 10,
    FuelCostPerKm = 3.5,
    MaintenanceCostPercent = 2,
    DamageRepairCostPerPercent = 5000,
    VehicleLoanInterest = 0.08,
    BusinessLoanInterest = 0.10,
    MaxLoanMultiplier = 5.0,
}

-- ==================== XP ====================

Config.Progression = {
    XpPerKm = 1,
    XpPerDelivery = 500,
    XpTimeBonus = 200,
    XpNoDamageBonus = 300,
    XpHighDifficultyBonus = 400,
    XpPerLevel = 1000,
    MinLevel = 1,
    MaxLevel = 100,
}

-- ==================== EMPRESA ====================

Config.Company = {
    MinNameLength = 5,
    MaxNameLength = 50,
    CreationCost = 250000,
    MaxEmployees = 50,
    MaxFleet = 100,
}

-- ==================== NUI ====================

Config.NUI = {
    Enabled = true,
    DefaultLanguage = 'pt-BR',
    Theme = 'dark',
    AnimationDuration = 300,
}

-- ==================== VALIDAÇÕES ====================

Config.Validation = {
    MaxInteractionDistance = 50.0,
    MaxDestinationDistance = 50.0,
    MaxDeliveryTime = 1440,
    CheckpointSpeedLimit = 80,
    DamageThreshold = 0.5,
}

-- ==================== FEATURES FLAGS ====================

Config.Features = {
    Companies = true,
    Contracts = true,
    FiscalSystem = true,
    Invoices = true,
    Progression = true,
    Certifications = true,
    Dealership = true,
    Garage = true,
    Loans = true,
    NPCDrivers = false,
    CooperativeGroups = true,
    DamageSystem = true,
    FuelSystem = false,
}

-- ==================== LOGS ====================

Config.Logs = {
    Enabled = true,
    LogLevel = 'info',
    LogToConsole = true,
    LogToFile = false,
    LogDirectory = 'resources/lf_trucking/logs/',
}

print('✓ Config.lua carregado')