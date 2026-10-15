-- ==================== CRIAÇÃO DE TABELAS ====================
-- LF_TRUCKING v1.0.0
-- Importar este arquivo no seu banco de dados

SET FOREIGN_KEY_CHECKS = 0;

-- ==================== TABELA: trucking_players ====================

CREATE TABLE IF NOT EXISTS `trucking_players` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `identifier` VARCHAR(100) UNIQUE NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `level` INT DEFAULT 1 CHECK (`level` >= 1 AND `level` <= 100),
    `experience` BIGINT DEFAULT 0,
    `total_money` BIGINT DEFAULT 0,
    `money_earned` BIGINT DEFAULT 0,
    `money_spent` BIGINT DEFAULT 0,
    `total_distance` FLOAT DEFAULT 0,
    `total_deliveries` INT DEFAULT 0,
    `completed_deliveries` INT DEFAULT 0,
    `cancelled_deliveries` INT DEFAULT 0,
    `failed_deliveries` INT DEFAULT 0,
    `average_rating` FLOAT DEFAULT 5.0,
    `company_id` INT NULL,
    `company_role` VARCHAR(50) DEFAULT 'driver',
    `is_active` BOOLEAN DEFAULT TRUE,
    `last_login` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`company_id`) REFERENCES `trucking_companies`(`id`) ON DELETE SET NULL,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_company_id` (`company_id`),
    INDEX `idx_level` (`level`),
    INDEX `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_companies ====================

CREATE TABLE IF NOT EXISTS `trucking_companies` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(100) UNIQUE NOT NULL,
    `identifier` VARCHAR(100) UNIQUE NOT NULL,
    `owner_identifier` VARCHAR(100) NOT NULL,
    `owner_name` VARCHAR(100) NOT NULL,
    `balance` BIGINT DEFAULT 0,
    `level` INT DEFAULT 1,
    `experience` INT DEFAULT 0,
    `reputation` FLOAT DEFAULT 5.0,
    `total_deliveries` INT DEFAULT 0,
    `completed_deliveries` INT DEFAULT 0,
    `failed_deliveries` INT DEFAULT 0,
    `total_revenue` BIGINT DEFAULT 0,
    `total_expenses` BIGINT DEFAULT 0,
    `employee_count` INT DEFAULT 0,
    `fleet_count` INT DEFAULT 0,
    `is_active` BOOLEAN DEFAULT TRUE,
    `founded_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_owner` (`owner_identifier`),
    INDEX `idx_name` (`name`),
    INDEX `idx_active` (`is_active`),
    INDEX `idx_balance` (`balance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_vehicles ====================

CREATE TABLE IF NOT EXISTS `trucking_vehicles` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `vehicle_id` VARCHAR(100) UNIQUE NOT NULL,
    `model_name` VARCHAR(50) NOT NULL,
    `owner_type` ENUM('player', 'company') DEFAULT 'player',
    `owner_identifier` VARCHAR(100) NOT NULL,
    `company_id` INT NULL,
    `plate` VARCHAR(20) UNIQUE NOT NULL,
    `purchase_price` BIGINT NOT NULL,
    `fuel_consumption` FLOAT DEFAULT 0.05,
    `cargo_capacity` INT DEFAULT 2000,
    `max_speed` INT DEFAULT 160,
    `weight` INT DEFAULT 5000,
    `current_health` INT DEFAULT 1000,
    `mileage` INT DEFAULT 0,
    `condition` VARCHAR(50) DEFAULT 'good',
    `is_available` BOOLEAN DEFAULT TRUE,
    `is_in_delivery` BOOLEAN DEFAULT FALSE,
    `current_delivery_id` INT NULL,
    `last_maintenance` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`company_id`) REFERENCES `trucking_companies`(`id`) ON DELETE SET NULL,
    INDEX `idx_owner` (`owner_identifier`, `owner_type`),
    INDEX `idx_company` (`company_id`),
    INDEX `idx_available` (`is_available`),
    INDEX `idx_in_delivery` (`is_in_delivery`),
    INDEX `idx_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_contracts ====================

CREATE TABLE IF NOT EXISTS `trucking_contracts` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `contract_number` VARCHAR(20) UNIQUE NOT NULL,
    `company_id` INT NOT NULL,
    `shipper_name` VARCHAR(100) NOT NULL,
    `origin_name` VARCHAR(100) NOT NULL,
    `origin_x` FLOAT NOT NULL,
    `origin_y` FLOAT NOT NULL,
    `origin_z` FLOAT NOT NULL,
    `destination_name` VARCHAR(100) NOT NULL,
    `dest_x` FLOAT NOT NULL,
    `dest_y` FLOAT NOT NULL,
    `dest_z` FLOAT NOT NULL,
    `estimated_distance` FLOAT NOT NULL,
    `estimated_time_hours` INT NOT NULL,
    `cargo_type` VARCHAR(50) NOT NULL,
    `cargo_description` VARCHAR(255),
    `cargo_weight` INT NOT NULL,
    `cargo_value` BIGINT NOT NULL,
    `is_fragile` BOOLEAN DEFAULT FALSE,
    `requires_certification` VARCHAR(100) NULL,
    `vehicle_type_required` VARCHAR(50) NULL,
    `base_reward` BIGINT NOT NULL,
    `time_bonus` BIGINT DEFAULT 0,
    `difficulty_multiplier` FLOAT DEFAULT 1.0,
    `status` ENUM('available', 'active', 'completed', 'cancelled', 'expired') DEFAULT 'available',
    `expires_at` TIMESTAMP NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`company_id`) REFERENCES `trucking_companies`(`id`) ON DELETE CASCADE,
    INDEX `idx_status` (`status`),
    INDEX `idx_cargo_type` (`cargo_type`),
    INDEX `idx_expires` (`expires_at`),
    INDEX `idx_contract_number` (`contract_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_deliveries ====================

CREATE TABLE IF NOT EXISTS `trucking_deliveries` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `delivery_uuid` VARCHAR(60) UNIQUE NOT NULL,
    `contract_id` INT NOT NULL,
    `player_identifier` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `company_id` INT NULL,
    `vehicle_id` VARCHAR(100) NOT NULL,
    `vehicle_plate` VARCHAR(20) NOT NULL,
    `status` ENUM(
        'accepted', 'vehicle_assigned', 'loading', 'in_transit',
        'checkpoint_pending', 'invoice_pending', 'fiscal_clearance_pending',
        'delivery_ready', 'completed', 'cancelled', 'failed', 'blocked'
    ) DEFAULT 'accepted',
    `cargo_intact` BOOLEAN DEFAULT TRUE,
    `vehicle_damage` INT DEFAULT 0,
    `route_deviation` FLOAT DEFAULT 0,
    `invoice_id` INT NULL,
    `fiscal_status` ENUM('pending', 'cleared', 'rejected') DEFAULT 'pending',
    `last_inspection_id` INT NULL,
    `inspection_result` VARCHAR(50) NULL,
    `current_checkpoint` INT DEFAULT 0,
    `total_checkpoints` INT DEFAULT 0,
    `last_checkpoint_passed_at` TIMESTAMP NULL,
    `final_reward` BIGINT NULL,
    `xp_earned` INT NULL,
    `is_paid` BOOLEAN DEFAULT FALSE,
    `accepted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `started_at` TIMESTAMP NULL,
    `completed_at` TIMESTAMP NULL,
    `deadline` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`contract_id`) REFERENCES `trucking_contracts`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`company_id`) REFERENCES `trucking_companies`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`invoice_id`) REFERENCES `trucking_invoices`(`id`) ON DELETE SET NULL,
    INDEX `idx_player` (`player_identifier`),
    INDEX `idx_status` (`status`),
    INDEX `idx_contract` (`contract_id`),
    INDEX `idx_vehicle` (`vehicle_id`),
    INDEX `idx_is_paid` (`is_paid`),
    INDEX `idx_fiscal_status` (`fiscal_status`),
    UNIQUE INDEX `idx_uuid` (`delivery_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_invoices ====================

CREATE TABLE IF NOT EXISTS `trucking_invoices` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `invoice_number` VARCHAR(50) UNIQUE NOT NULL,
    `delivery_id` INT UNIQUE NOT NULL,
    `contract_id` INT NOT NULL,
    `invoice_uuid` VARCHAR(60) UNIQUE NOT NULL,
    `shipper_name` VARCHAR(100) NOT NULL,
    `carrier_name` VARCHAR(100) NOT NULL,
    `carrier_cnpj` VARCHAR(20) NULL,
    `driver_name` VARCHAR(100) NOT NULL,
    `driver_id` VARCHAR(100) NOT NULL,
    `vehicle_plate` VARCHAR(20) NOT NULL,
    `vehicle_model` VARCHAR(50) NOT NULL,
    `trailer_plate` VARCHAR(20) NULL,
    `cargo_type` VARCHAR(50) NOT NULL,
    `cargo_description` VARCHAR(255),
    `cargo_weight` INT NOT NULL,
    `cargo_value` BIGINT NOT NULL,
    `origin_city` VARCHAR(100) NOT NULL,
    `destination_city` VARCHAR(100) NOT NULL,
    `status` ENUM('pending', 'issued', 'under_review', 'cleared', 'rejected', 'cancelled', 'invalid') DEFAULT 'pending',
    `validation_code` VARCHAR(20) NOT NULL,
    `issued_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `issued_by` VARCHAR(100),
    `cleared_at` TIMESTAMP NULL,
    `cleared_by` VARCHAR(100) NULL,
    `rejected_reason` VARCHAR(255) NULL,
    `rejected_by` VARCHAR(100) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`delivery_id`) REFERENCES `trucking_deliveries`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`contract_id`) REFERENCES `trucking_contracts`(`id`) ON DELETE CASCADE,
    INDEX `idx_status` (`status`),
    INDEX `idx_delivery` (`delivery_id`),
    INDEX `idx_invoice_number` (`invoice_number`),
    INDEX `idx_issued` (`issued_at`),
    UNIQUE INDEX `idx_uuid` (`invoice_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_fiscal_checkpoints ====================

CREATE TABLE IF NOT EXISTS `trucking_fiscal_checkpoints` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `checkpoint_id` VARCHAR(50) UNIQUE NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `checkpoint_x` FLOAT NOT NULL,
    `checkpoint_y` FLOAT NOT NULL,
    `checkpoint_z` FLOAT NOT NULL,
    `radius` FLOAT DEFAULT 50.0,
    `requires_invoice` BOOLEAN DEFAULT TRUE,
    `requires_prf_agent` BOOLEAN DEFAULT FALSE,
    `requires_certification` VARCHAR(100) NULL,
    `is_mandatory` BOOLEAN DEFAULT TRUE,
    `check_vehicle` BOOLEAN DEFAULT TRUE,
    `check_cargo` BOOLEAN DEFAULT TRUE,
    `check_documentation` BOOLEAN DEFAULT TRUE,
    `inspection_mode` ENUM('auto', 'prf_required', 'road_inspection') DEFAULT 'auto',
    `speed_limit` INT DEFAULT 80,
    `contingency_on_no_prf` VARCHAR(50) DEFAULT 'allow',
    `is_active` BOOLEAN DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_name` (`name`),
    INDEX `idx_active` (`is_active`),
    INDEX `idx_checkpoint_id` (`checkpoint_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_inspections ====================

CREATE TABLE IF NOT EXISTS `trucking_inspections` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `inspection_uuid` VARCHAR(60) UNIQUE NOT NULL,
    `delivery_id` INT NOT NULL,
    `checkpoint_id` INT NULL,
    `prf_officer_identifier` VARCHAR(100),
    `prf_officer_name` VARCHAR(100),
    `prf_officer_rank` VARCHAR(50),
    `vehicle_plate` VARCHAR(20) NOT NULL,
    `driver_identifier` VARCHAR(100) NOT NULL,
    `driver_name` VARCHAR(100) NOT NULL,
    `invoice_id` INT NULL,
    `has_valid_invoice` BOOLEAN DEFAULT FALSE,
    `invoice_status_at_inspection` VARCHAR(50),
    `vehicle_integrity_status` VARCHAR(50) NULL,
    `cargo_integrity_status` VARCHAR(50) NULL,
    `documentation_status` VARCHAR(50) NULL,
    `inspection_result` ENUM(
        'no_irregularities', 'document_mismatch', 'cargo_mismatch',
        'missing_certification', 'missing_invoice', 'invalid_invoice',
        'suspected_irregularity', 'cargo_damage', 'inconclusive'
    ) DEFAULT 'inconclusive',
    `irregularities_found` TEXT NULL,
    `officer_notes` TEXT NULL,
    `administrative_measure` VARCHAR(100) NULL,
    `measure_details` VARCHAR(255) NULL,
    `delivery_blocked` BOOLEAN DEFAULT FALSE,
    `location_x` FLOAT,
    `location_y` FLOAT,
    `location_z` FLOAT,
    `inspected_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `completed_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`delivery_id`) REFERENCES `trucking_deliveries`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`checkpoint_id`) REFERENCES `trucking_fiscal_checkpoints`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`invoice_id`) REFERENCES `trucking_invoices`(`id`) ON DELETE SET NULL,
    INDEX `idx_delivery` (`delivery_id`),
    INDEX `idx_result` (`inspection_result`),
    INDEX `idx_officer` (`prf_officer_identifier`),
    INDEX `idx_inspected` (`inspected_at`),
    UNIQUE INDEX `idx_uuid` (`inspection_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_certifications ====================

CREATE TABLE IF NOT EXISTS `trucking_certifications` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `player_identifier` VARCHAR(100) NOT NULL,
    `certification_type` VARCHAR(100) NOT NULL,
    `certification_name` VARCHAR(100) NOT NULL,
    `status` ENUM('active', 'expired', 'revoked') DEFAULT 'active',
    `granted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NULL,
    `revoked_at` TIMESTAMP NULL,
    `revoke_reason` VARCHAR(255) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`player_identifier`) REFERENCES `trucking_players`(`identifier`) ON DELETE CASCADE,
    UNIQUE KEY `uk_cert` (`player_identifier`, `certification_type`),
    INDEX `idx_status` (`status`),
    INDEX `idx_player` (`player_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_skills ====================

CREATE TABLE IF NOT EXISTS `trucking_skills` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `player_identifier` VARCHAR(100) NOT NULL UNIQUE,
    `fuel_efficiency` INT DEFAULT 0,
    `fragile_cargo` INT DEFAULT 0,
    `high_value_cargo` INT DEFAULT 0,
    `long_distance` INT DEFAULT 0,
    `urgent_deliveries` INT DEFAULT 0,
    `special_cargo` INT DEFAULT 0,
    `earning_rate` INT DEFAULT 0,
    `expense_reduction` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`player_identifier`) REFERENCES `trucking_players`(`identifier`) ON DELETE CASCADE,
    INDEX `idx_player` (`player_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_loans ====================

CREATE TABLE IF NOT EXISTS `trucking_loans` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `loan_uuid` VARCHAR(60) UNIQUE NOT NULL,
    `player_identifier` VARCHAR(100) NOT NULL,
    `company_id` INT NULL,
    `loan_type` ENUM('vehicle', 'business', 'emergency') DEFAULT 'vehicle',
    `principal_amount` BIGINT NOT NULL,
    `interest_rate` FLOAT DEFAULT 0.05,
    `total_amount` BIGINT NOT NULL,
    `installment_amount` BIGINT NOT NULL,
    `installments_total` INT NOT NULL,
    `installments_paid` INT DEFAULT 0,
    `status` ENUM('active', 'paid', 'defaulted') DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `due_date` TIMESTAMP NOT NULL,
    `last_payment_at` TIMESTAMP NULL,
    `completed_at` TIMESTAMP NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`player_identifier`) REFERENCES `trucking_players`(`identifier`) ON DELETE CASCADE,
    FOREIGN KEY (`company_id`) REFERENCES `trucking_companies`(`id`) ON DELETE SET NULL,
    INDEX `idx_player` (`player_identifier`),
    INDEX `idx_status` (`status`),
    INDEX `idx_company` (`company_id`),
    UNIQUE INDEX `idx_uuid` (`loan_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_financial_history ====================

CREATE TABLE IF NOT EXISTS `trucking_financial_history` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `player_identifier` VARCHAR(100) NOT NULL,
    `company_id` INT NULL,
    `transaction_type` VARCHAR(50) NOT NULL,
    `amount` BIGINT NOT NULL,
    `previous_balance` BIGINT NOT NULL,
    `new_balance` BIGINT NOT NULL,
    `reason` VARCHAR(255),
    `delivery_id` INT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`player_identifier`) REFERENCES `trucking_players`(`identifier`) ON DELETE CASCADE,
    FOREIGN KEY (`company_id`) REFERENCES `trucking_companies`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`delivery_id`) REFERENCES `trucking_deliveries`(`id`) ON DELETE SET NULL,
    INDEX `idx_player` (`player_identifier`),
    INDEX `idx_company` (`company_id`),
    INDEX `idx_date` (`created_at`),
    INDEX `idx_type` (`transaction_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_audit_logs ====================

CREATE TABLE IF NOT EXISTS `trucking_audit_logs` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `action_type` VARCHAR(100) NOT NULL,
    `actor_identifier` VARCHAR(100),
    `actor_name` VARCHAR(100),
    `target_identifier` VARCHAR(100),
    `target_type` VARCHAR(50),
    `target_id` INT,
    `action_details` JSON,
    `status_before` VARCHAR(100),
    `status_after` VARCHAR(100),
    `log_timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_action` (`action_type`),
    INDEX `idx_actor` (`actor_identifier`),
    INDEX `idx_date` (`log_timestamp`),
    INDEX `idx_target_id` (`target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_company_employees ====================

CREATE TABLE IF NOT EXISTS `trucking_company_employees` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `company_id` INT NOT NULL,
    `player_identifier` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `role` ENUM('owner', 'director', 'manager', 'driver', 'trainee') DEFAULT 'driver',
    `hired_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `fired_at` TIMESTAMP NULL,
    `salary` BIGINT DEFAULT 0,
    `is_active` BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (`company_id`) REFERENCES `trucking_companies`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_employee` (`company_id`, `player_identifier`),
    INDEX `idx_company` (`company_id`),
    INDEX `idx_player` (`player_identifier`),
    INDEX `idx_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_npc_drivers ====================

CREATE TABLE IF NOT EXISTS `trucking_npc_drivers` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `company_id` INT NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `level` INT DEFAULT 1,
    `experience` INT DEFAULT 0,
    `salary` BIGINT NOT NULL,
    `vehicle_id` INT NULL,
    `total_deliveries` INT DEFAULT 0,
    `completed_deliveries` INT DEFAULT 0,
    `failed_deliveries` INT DEFAULT 0,
    `total_revenue` BIGINT DEFAULT 0,
    `status` ENUM('available', 'busy', 'sick', 'fired') DEFAULT 'available',
    `hired_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `fired_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`company_id`) REFERENCES `trucking_companies`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`vehicle_id`) REFERENCES `trucking_vehicles`(`id`) ON DELETE SET NULL,
    INDEX `idx_company` (`company_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_delivery_groups ====================

CREATE TABLE IF NOT EXISTS `trucking_delivery_groups` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `group_uuid` VARCHAR(60) UNIQUE NOT NULL,
    `delivery_id` INT NOT NULL,
    `leader_identifier` VARCHAR(100) NOT NULL,
    `status` ENUM('forming', 'active', 'completed', 'disbanded') DEFAULT 'forming',
    `reward_split_mode` ENUM('equal', 'contribution', 'custom') DEFAULT 'equal',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `started_at` TIMESTAMP NULL,
    `completed_at` TIMESTAMP NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`delivery_id`) REFERENCES `trucking_deliveries`(`id`) ON DELETE CASCADE,
    INDEX `idx_leader` (`leader_identifier`),
    INDEX `idx_status` (`status`),
    UNIQUE INDEX `idx_delivery` (`delivery_id`),
    UNIQUE INDEX `idx_uuid` (`group_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TABELA: trucking_group_members ====================

CREATE TABLE IF NOT EXISTS `trucking_group_members` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `group_id` INT NOT NULL,
    `member_identifier` VARCHAR(100) NOT NULL,
    `member_name` VARCHAR(100) NOT NULL,
    `joined_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `contribution_percentage` INT DEFAULT 50,
    `is_active` BOOLEAN DEFAULT TRUE,
    `left_at` TIMESTAMP NULL,
    FOREIGN KEY (`group_id`) REFERENCES `trucking_delivery_groups`(`id`) ON DELETE CASCADE,
    INDEX `idx_group` (`group_id`),
    INDEX `idx_member` (`member_identifier`),
    INDEX `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ==================== INSERIR DADOS INICIAIS ====================

INSERT IGNORE INTO `trucking_companies` (
    `name`, `identifier`, `owner_identifier`, `owner_name`,
    `balance`, `level`, `reputation`
) VALUES (
    'Transportadora Central',
    'company_default_001',
    'steam:11000000001',
    'Admin',
    50000000,
    1,
    5.0
);

INSERT IGNORE INTO `trucking_fiscal_checkpoints` (
    `checkpoint_id`, `name`, `checkpoint_x`, `checkpoint_y`, `checkpoint_z`,
    `radius`, `requires_invoice`, `requires_prf_agent`, `is_mandatory`,
    `inspection_mode`, `contingency_on_no_prf`
) VALUES (
    'checkpoint_example_001',
    'Posto Fiscal Exemplo',
    100.0, 100.0, 10.0,
    50.0, TRUE, FALSE, TRUE,
    'auto', 'allow'
);

-- ==================== FIM DA INSTALAÇÃO ====================
-- Sucesso! Tabelas criadas e dados iniciais inseridos.