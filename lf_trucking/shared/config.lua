-- ==================== SHARED CONFIG ====================
-- Configurações compartilhadas entre server e client

SharedConfig = {}

-- ==================== FRAMEWORK ====================

SharedConfig.Framework = 'qb' -- 'esx', 'qb', 'auto'

-- ==================== DEBUG ====================

SharedConfig.Debug = false
SharedConfig.DebugNUI = false
SharedConfig.DebugDatabase = false
SharedConfig.DebugSecurity = false

-- ==================== IDIOMA ====================

SharedConfig.Language = 'pt-BR'

-- ==================== CONSTANTES GLOBAIS ====================

SharedConfig.MaxPlayers = 128
SharedConfig.UpdateInterval = 100 -- ms
SharedConfig.CheckpointUpdateInterval = 500 -- ms

-- ==================== COORDENADAS PADRÃO ====================

-- CUSTOMIZE_THIS: Substitua com coordenadas do seu servidor

SharedConfig.DefaultSpawnCoords = {
    x = 425.4,
    y = -979.5,
    z = 29.4,
    heading = 0.0
}

SharedConfig.PoliceStationCoord = {
    x = 425.4,
    y = -979.5,
    z = 29.4
}

-- ==================== VERSÃO ====================

SharedConfig.Version = '1.0.0'
SharedConfig.BuildDate = '2024-01-15'

-- ==================== FEATURE FLAGS ====================

SharedConfig.Features = {
    enableCompanies = true,
    enableContracts = true,
    enableFiscal = true,
    enableInvoices = true,
    enableProgression = true,
    enableCertifications = true,
    enableDealership = true,
    enableGarage = true,
    enableLoans = true,
    enableNPCDrivers = false,
    enableCooperativeGroups = true,
    enableDamageSystem = true,
    enableFuelSystem = false,
    enablePRFIntegration = false,
}

-- ==================== VALIDAÇÃO ====================

SharedConfig.Validation = {
    minCompanyNameLength = 5,
    maxCompanyNameLength = 50,
    minContractDistance = 100,
    maxContractDistance = 5000,
    checkpointSpeedLimit = 80,
    maxInteractionDistance = 50.0,
    maxDestinationDistance = 50.0,
    damageThreshold = 50,
}

-- ==================== TIMES ====================

SharedConfig.Timeouts = {
    checkpointClearance = 60000,
    invoiceEmission = 30000,
    deliveryReconnect = 1800000,
    rateLimit = 1000,
    inspectionTimeout = 300000,
    paymentTimeout = 5000,
    npcDriverTimeout = 60000,
}

-- ==================== MULTIPLIERS ====================

SharedConfig.Multipliers = {
    xpPerKm = 1,
    xpPerDelivery = 500,
    xpTimeBonus = 200,
    xpNoDamageBonus = 300,
    paymentPerKm = 1.5,
    difficultyEasy = 0.8,
    difficultyNormal = 1.0,
    difficultyHard = 1.5,
    difficultyExtreme = 2.0,
}

-- ==================== THRESHOLDS ====================

SharedConfig.Thresholds = {
    minLevelForCompany = 5,
    minLevelForSpecialCargo = 15,
    minLevelForCertification = 8,
    xpPerLevel = 1000,
}

return SharedConfig