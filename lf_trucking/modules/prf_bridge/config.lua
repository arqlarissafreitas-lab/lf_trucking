-- ==================== PRF BRIDGE CONFIGURATION ====================
-- Configurações específicas da integração com PRF

PRFBridgeConfig = {}

-- ==================== ATIVAÇÃO ====================

PRFBridgeConfig.Enabled = false -- Ativar/desativar bridge da PRF

-- ==================== RECURSO ====================

PRFBridgeConfig.ResourceName = 'job_prf'

-- ==================== FRAMEWORKS ====================

PRFBridgeConfig.ESX = {
    JobName = 'prf',
    JobLabel = 'Polícia Rodoviária Federal',
}

PRFBridgeConfig.QBCore = {
    JobName = 'prf',
    JobLabel = 'Polícia Rodoviária Federal',
}

-- ==================== AUTORIZAÇÃO ====================

-- Patentes/grades autorizadas para fiscalizar
PRFBridgeConfig.AuthorizedRanks = {
    'recruit',
    'officer',
    'sergeant',
    'corporal',
    'lieutenant',
    'captain',
    'commissioner',
    'chief',
}

-- Grupos de administração com acesso
PRFBridgeConfig.AuthorizedGroups = {
    'admin',
    'moderator',
    'prf_officer',
    'prf_supervisor',
}

-- ==================== CHECKPOINTS ESPECIAIS ====================

-- Checkpoints que EXIGEM presença de agente PRF
-- Se vazio, nenhum checkpoint exige PRF obrigatória
PRFBridgeConfig.CheckpointsRequiringPRF = {
    'checkpoint_special_001',
    'checkpoint_strategic_001',
}

-- ==================== COMPORTAMENTO ====================

-- Modo quando nenhum agente PRF está online
-- 'allow' = permite continuar normalmente
-- 'reagendar' = oferece reagendamento automático
-- 'block' = bloqueia até que agente esteja disponível
PRFBridgeConfig.NoAgentMode = 'allow'

-- Número mínimo de agentes PRF online para ativar fiscalização policial
PRFBridgeConfig.MinAgentsOnline = 0

-- Tempo máximo (ms) que uma inspeção pode ficar pendente antes de timeout
PRFBridgeConfig.InspectionTimeout = 300000 -- 5 minutos

-- ==================== COMUNICAÇÃO ====================

-- Nome do evento para notificar agentes sobre abordagens
PRFBridgeConfig.DispatchEventName = 'prf:dispatch:roadInspection'

-- Nome do evento para atualizar inspeções em tempo real
PRFBridgeConfig.InspectionUpdateEvent = 'prf:inspection:update'

-- ==================== PERMISSÕES DE INSPEÇÃO ====================

PRFBridgeConfig.InspectionPermissions = {
    -- Permissões básicas
    canInitiateInspection = true,
    canViewDocuments = true,
    canCheckCargo = true,
    canCheckVehicle = true,
    
    -- Permissões avançadas
    canIssueWarning = true,
    canRegisterIrregularity = true,
    canRetainDelivery = true,
    canBlockDelivery = true,
    canIssueFine = true,
    
    -- Permissões administrativas
    canOverrideInspection = false, -- Apenas admins
    canEditInspectionResult = false, -- Apenas admins
    canDeleteInspectionRecord = false, -- Apenas admins
}

-- ==================== RESULTADO DE INSPEÇÕES ====================

-- Configuração de quais resultados geram quais ações automáticas
PRFBridgeConfig.ResultActions = {
    no_irregularities = {
        autoApprove = true,
        requiresManualReview = false,
        blockDelivery = false,
        penalty = 0,
    },
    document_mismatch = {
        autoApprove = false,
        requiresManualReview = true,
        blockDelivery = false,
        penalty = 500,
    },
    cargo_mismatch = {
        autoApprove = false,
        requiresManualReview = true,
        blockDelivery = true,
        penalty = 2000,
    },
    missing_certification = {
        autoApprove = false,
        requiresManualReview = true,
        blockDelivery = true,
        penalty = 1500,
    },
    missing_invoice = {
        autoApprove = false,
        requiresManualReview = true,
        blockDelivery = true,
        penalty = 3000,
    },
    invalid_invoice = {
        autoApprove = false,
        requiresManualReview = true,
        blockDelivery = true,
        penalty = 2500,
    },
    suspected_irregularity = {
        autoApprove = false,
        requiresManualReview = true,
        blockDelivery = true,
        penalty = 4000,
    },
    cargo_damage = {
        autoApprove = false,
        requiresManualReview = true,
        blockDelivery = false,
        penalty = 1000,
    },
    inconclusive = {
        autoApprove = false,
        requiresManualReview = true,
        blockDelivery = false,
        penalty = 0,
    },
}

-- ==================== MEDIDAS ADMINISTRATIVAS ====================

PRFBridgeConfig.AdministrativeMeasures = {
    warning = {
        description = 'Advertência',
        requiresOfficer = true,
        affectsDelivery = false,
        recordsPenalty = true,
    },
    register_irregularity = {
        description = 'Registro de Irregularidade',
        requiresOfficer = true,
        affectsDelivery = false,
        recordsPenalty = true,
    },
    request_documentation = {
        description = 'Solicitação de Documentação',
        requiresOfficer = true,
        affectsDelivery = true,
        recordsPenalty = false,
    },
    temporary_retention = {
        description = 'Retenção Temporária',
        requiresOfficer = true,
        affectsDelivery = true,
        recordsPenalty = true,
    },
    delivery_blocked = {
        description = 'Bloqueio de Entrega',
        requiresOfficer = true,
        affectsDelivery = true,
        recordsPenalty = true,
    },
    fictional_fine = {
        description = 'Multa Fictícia de RP',
        requiresOfficer = true,
        affectsDelivery = false,
        recordsPenalty = true,
    },
}

-- ==================== ABORDAGEM RODOVIÁRIA ====================

PRFBridgeConfig.RoadInspection = {
    -- Ativar abordagens rodoviárias
    enabled = true,
    
    -- Probabilidade de abordagem (0.0 a 1.0)
    interceptionChance = 0.15,
    
    -- Distância mínima entre abordagens para o mesmo jogador
    minDistanceBetweenInspections = 5000,
    
    -- Tempo mínimo entre abordagens para o mesmo jogador (ms)
    minTimeBetweenInspections = 600000, -- 10 minutos
    
    -- Velocidade máxima permitida ao dirigir-se a um checkpoint
    maxApproachSpeed = 100,
    
    -- Raio de ação da abordagem
    interceptionRadius = 200.0,
    
    -- Usar modelo de ped para oficial durante a abordagem
    useOfficerModel = true,
    officerModel = 'a_m_m_business_2',
}

-- ==================== CONFIGURAÇÃO DE LOGGING ====================

PRFBridgeConfig.Logging = {
    enableLogging = true,
    logAllInspections = true,
    logAllIrregularities = true,
    logAdministrativeMeasures = true,
    logApprovedInspections = false,
    logToConsole = true,
    logToFile = true,
    logDirectory = 'resources/lf_trucking/logs/prf/',
}

-- ==================== NOTIFICAÇÕES ====================

PRFBridgeConfig.Notifications = {
    -- Notificar motorista quando fiscalização é iniciada
    notifyDriverOnInspection = true,
    
    -- Notificar motorista quando resultado da inspeção é definido
    notifyDriverOnResult = true,
    
    -- Notificar transportadora sobre irregularidades
    notifyCompanyOnIrregularity = true,
    
    -- Notificar admin sobre inspeções críticas
    notifyAdminOnCritical = true,
}

-- ==================== CONTINGÊNCIA ====================

-- Se nenhum agente PRF estiver disponível, qual é o comportamento?
PRFBridgeConfig.Contingency = {
    -- Auto-aprovação após timeout (em ms)
    autoApprovalTimeout = 300000, -- 5 minutos
    
    -- Permitir que servidor local aprove inspeções
    allowServerApproval = true,
    
    -- Penalidade por falta de fiscalização (em %)
    missingInspectionPenalty = 0.9,
}

-- ==================== DESENVOLVIMENTO ====================

PRFBridgeConfig.Debug = 