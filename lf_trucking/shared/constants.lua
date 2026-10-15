-- Constantes globais do sistema

TRUCKING = {}

-- ==================== ESTADOS ====================

TRUCKING.DELIVERY_STATES = {
    ACCEPTED = 'accepted',
    VEHICLE_ASSIGNED = 'vehicle_assigned',
    LOADING = 'loading',
    IN_TRANSIT = 'in_transit',
    CHECKPOINT_PENDING = 'checkpoint_pending',
    INVOICE_PENDING = 'invoice_pending',
    FISCAL_CLEARANCE_PENDING = 'fiscal_clearance_pending',
    DELIVERY_READY = 'delivery_ready',
    COMPLETED = 'completed',
    CANCELLED = 'cancelled',
    FAILED = 'failed',
    BLOCKED = 'blocked',
}

TRUCKING.CONTRACT_STATES = {
    AVAILABLE = 'available',
    ACTIVE = 'active',
    COMPLETED = 'completed',
    CANCELLED = 'cancelled',
    EXPIRED = 'expired',
}

TRUCKING.INVOICE_STATES = {
    PENDING = 'pending',
    ISSUED = 'issued',
    UNDER_REVIEW = 'under_review',
    CLEARED = 'cleared',
    REJECTED = 'rejected',
    CANCELLED = 'cancelled',
    INVALID = 'invalid',
}

TRUCKING.INSPECTION_RESULTS = {
    NO_IRREGULARITIES = 'no_irregularities',
    DOCUMENT_MISMATCH = 'document_mismatch',
    CARGO_MISMATCH = 'cargo_mismatch',
    MISSING_CERTIFICATION = 'missing_certification',
    MISSING_INVOICE = 'missing_invoice',
    INVALID_INVOICE = 'invalid_invoice',
    SUSPECTED_IRREGULARITY = 'suspected_irregularity',
    CARGO_DAMAGE = 'cargo_damage',
    INCONCLUSIVE = 'inconclusive',
}

TRUCKING.LOAN_STATES = {
    ACTIVE = 'active',
    PAID = 'paid',
    DEFAULTED = 'defaulted',
}

TRUCKING.GROUP_STATES = {
    FORMING = 'forming',
    ACTIVE = 'active',
    COMPLETED = 'completed',
    DISBANDED = 'disbanded',
}

-- ==================== TIPOS ====================

TRUCKING.CARGO_TYPES = {
    ALIMENTOS = 'alimentos',
    CONSTRUCAO = 'construcao',
    INDUSTRIAL = 'industrial',
    ELETRONICOS = 'eletronicos',
    QUIMICOS = 'quimicos',
    VEICULOS = 'veiculos',
    FRAGIL = 'fragil',
    REFRIGERADO = 'refrigerado',
    ESPECIAL = 'especial',
    ALTO_VALOR = 'alto_valor',
}

TRUCKING.COMPANY_ROLES = {
    OWNER = 'owner',
    DIRECTOR = 'director',
    MANAGER = 'manager',
    DRIVER = 'driver',
    TRAINEE = 'trainee',
}

TRUCKING.INSPECTION_MODES = {
    AUTO = 'auto',
    PRF_REQUIRED = 'prf_required',
    ROAD_INSPECTION = 'road_inspection',
}

TRUCKING.ADMINISTRATIVE_MEASURES = {
    WARNING = 'warning',
    REGISTER_IRREGULARITY = 'register_irregularity',
    REQUEST_DOCUMENTATION = 'request_documentation',
    TEMPORARY_RETENTION = 'temporary_retention',
    DELIVERY_BLOCKED = 'delivery_blocked',
    FICTIONAL_FINE = 'fictional_fine',
    FORWARD_TO_PROCEDURE = 'forward_to_procedure',
}

TRUCKING.OWNER_TYPES = {
    PLAYER = 'player',
    COMPANY = 'company',
}

TRUCKING.VEHICLE_CONDITIONS = {
    EXCELLENT = 'excellent',
    GOOD = 'good',
    FAIR = 'fair',
    POOR = 'poor',
    CRITICAL = 'critical',
}

TRUCKING.NPC_DRIVER_STATUS = {
    AVAILABLE = 'available',
    BUSY = 'busy',
    SICK = 'sick',
    FIRED = 'fired',
}

-- ==================== SKILLS ====================

TRUCKING.SKILLS = {
    FUEL_EFFICIENCY = 'fuel_efficiency',
    FRAGILE_CARGO = 'fragile_cargo',
    HIGH_VALUE_CARGO = 'high_value_cargo',
    LONG_DISTANCE = 'long_distance',
    URGENT_DELIVERIES = 'urgent_deliveries',
    SPECIAL_CARGO = 'special_cargo',
    EARNING_RATE = 'earning_rate',
    EXPENSE_REDUCTION = 'expense_reduction',
}

-- ==================== CERTIFICAÇÕES ====================

TRUCKING.CERTIFICATIONS = {
    HAZMAT = 'hazmat',
    REFRIGERATED = 'refrigerated',
    FRAGILE = 'fragile',
    HIGH_VALUE = 'high_value',
    LIVESTOCK = 'livestock',
    OVERSIZED = 'oversized',
}

TRUCKING.CERTIFICATION_STATES = {
    ACTIVE = 'active',
    EXPIRED = 'expired',
    REVOKED = 'revoked',
}

-- ==================== COMPANY PERMISSIONS ====================

TRUCKING.PERMISSIONS = {
    OWNER = {
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
    DIRECTOR = {
        'hire_employees',
        'fire_employees',
        'promote_employees',
        'accept_contracts',
        'manage_fleet',
        'access_logs',
    },
    MANAGER = {
        'accept_contracts',
        'manage_fleet',
        'access_logs',
    },
    DRIVER = {
        'accept_contracts',
    },
    TRAINEE = {},
}

-- ==================== XP E LEVELS ====================

TRUCKING.XP_PER_LEVEL = 1000
TRUCKING.MIN_LEVEL = 1
TRUCKING.MAX_LEVEL = 100

-- ==================== VALORES MONETÁRIOS ====================

TRUCKING.PAYMENT_MULTIPLIERS = {
    BASE = 1.0,
    DIFFICULTY = {
        easy = 0.8,
        normal = 1.0,
        hard = 1.5,
        extreme = 2.0,
    },
    TIME_BONUS = 1.15,
    TIME_PENALTY = 0.5,
    DAMAGE_PENALTY = 0.8,
    DEVIATION_PENALTY = 0.9,
}

-- ==================== CHECKPOINTS ====================

TRUCKING.CONTINGENCY_MODES = {
    ALLOW = 'allow',
    REAGENDAR = 'reagendar',
    BLOCK = 'block',
}

-- ==================== ERRROS ====================

TRUCKING.ERRORS = {
    PLAYER_NOT_FOUND = 'player_not_found',
    CONTRACT_NOT_FOUND = 'contract_not_found',
    DELIVERY_NOT_FOUND = 'delivery_not_found',
    INVALID_STATE = 'invalid_state',
    INSUFFICIENT_LEVEL = 'insufficient_level',
    MISSING_CERTIFICATION = 'missing_certification',
    VEHICLE_NOT_AVAILABLE = 'vehicle_not_available',
    INSUFFICIENT_DISTANCE = 'insufficient_distance',
    PAYMENT_ALREADY_MADE = 'payment_already_made',
    INVOICE_REQUIRED = 'invoice_required',
    FISCAL_CLEARANCE_REQUIRED = 'fiscal_clearance_required',
    UNAUTHORIZED = 'unauthorized',
    INVALID_PARAMETER = 'invalid_parameter',
    DATABASE_ERROR = 'database_error',
}

-- ==================== TIMEOUTS ====================

TRUCKING.TIMEOUTS = {
    CHECKPOINT_CLEARANCE = 60000,
    INVOICE_EMISSION = 30000,
    DELIVERY_RECONNECT = 1800000,
    RATE_LIMIT = 1000,
    INSPECTION_TIMEOUT = 300000,
    PAYMENT_TIMEOUT = 5000,
}

-- ==================== DISTÂNCIAS ====================

TRUCKING.DISTANCES = {
    CHECKPOINT_INTERACTION = 50.0,
    DELIVERY_ORIGIN = 50.0,
    DELIVERY_DESTINATION = 50.0,
    FISCAL_OFFICER_INTERACTION = 50.0,
    VEHICLE_PROXIMITY = 5.0,
}

-- ==================== NOTIFICAÇÃO ====================

TRUCKING.NOTIFICATION_TYPES = {
    SUCCESS = 'success',
    ERROR = 'error',
    WARNING = 'warning',
    INFO = 'info',
}

-- ==================== EVENTOS DE AUDITORIA ====================

TRUCKING.AUDIT_ACTIONS = {
    DELIVERY_ACCEPTED = 'delivery_accepted',
    DELIVERY_COMPLETED = 'delivery_completed',
    DELIVERY_CANCELLED = 'delivery_cancelled',
    DELIVERY_FAILED = 'delivery_failed',
    DELIVERY_BLOCKED = 'delivery_blocked',
    INVOICE_ISSUED = 'invoice_issued',
    INVOICE_CLEARED = 'invoice_cleared',
    INVOICE_REJECTED = 'invoice_rejected',
    INSPECTION_STARTED = 'inspection_started',
    INSPECTION_COMPLETED = 'inspection_completed',
    PAYMENT_PROCESSED = 'payment_processed',
    COMPANY_CREATED = 'company_created',
    EMPLOYEE_HIRED = 'employee_hired',
    EMPLOYEE_FIRED = 'employee_fired',
    EMPLOYEE_PROMOTED = 'employee_promoted',
    VEHICLE_PURCHASED = 'vehicle_purchased',
    VEHICLE_SOLD = 'vehicle_sold',
    LOAN_CREATED = 'loan_created',
    LOAN_PAID = 'loan_paid',
    CERTIFICATION_GRANTED = 'certification_granted',
    CERTIFICATION_REVOKED = 'certification_revoked',
}

return TRUCKING