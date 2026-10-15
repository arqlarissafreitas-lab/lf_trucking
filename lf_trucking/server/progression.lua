-- ==================== PROGRESSION MANAGEMENT ====================
-- Gerenciamento de progressão, XP e habilidades

Progression = {}

-- Calcular XP necessário para próximo nível
function Progression.GetXPForLevel(level)
    return Config.Progression.XpPerLevel * level
end

-- Obter nível baseado em XP
function Progression.GetLevelFromXP(totalXP)
    local level = math.floor(totalXP / Config.Progression.XpPerLevel) + 1
    return math.min(level, Config.Progression.MaxLevel)
end

-- Obter XP necessário para próximo nível
function Progression.GetXPToNextLevel(totalXP)
    local currentLevel = Progression.GetLevelFromXP(totalXP)
    if currentLevel >= Config.Progression.MaxLevel then
        return 0
    end
    
    local currentLevelXP = (currentLevel - 1) * Config.Progression.XpPerLevel
    local nextLevelXP = currentLevel * Config.Progression.XpPerLevel
    local currentProgress = totalXP - currentLevelXP
    
    return nextLevelXP - totalXP
end

-- Desbloquear habilidade
function Progression.UnlockSkill(identifier, skillId)
    if not Config.SkillTree then
        return false, 'skill_tree_not_available'
    end
    
    -- Encontrar skill
    local skill = nil
    for _, s in ipairs(Config.SkillTree or {}) do
        if s.id == skillId then
            skill = s
            break
        end
    end
    
    if not skill then
        return false, 'skill_not_found'
    end
    
    -- Verificar nível
    local profile = Players.GetProfile(identifier)
    if not profile or profile.level < skill.level_requirement then
        return false, 'insufficient_level'
    end
    
    -- Verificar dinheiro
    local money = profile.total_money
    if money < skill.cost then
        return false, 'insufficient_funds'
    end
    
    -- Remover dinheiro
    local success = Players.RemoveMoney(identifier, skill.cost, 'skill_unlock')
    
    if success then
        -- Atualizar skill
        Players.IncrementSkill(identifier, skillId, 1)
        
        -- Log auditoria
        Database.LogAudit(
            'skill_unlocked',
            identifier,
            profile.player_name,
            identifier,
            'player',
            profile.id,
            { skill_id = skillId, skill_name = skill.name, cost = skill.cost },
            'locked',
            'unlocked'
        )
        
        return true
    end
    
    return false, 'unlock_failed'
end

-- Obter bônus de habilidade
function Progression.GetSkillBonus(identifier, skillType)
    local skills = Players.GetSkills(identifier)
    
    if not skills or not skills[skillType] then
        return 0
    end
    
    -- Encontrar skill
    local skillLevel = skills[skillType]
    
    for _, skill in ipairs(Config.SkillTree or {}) do
        if skill.id == skillType then
            if skill.benefit_type == 'percentage' then
                return (skill.benefit_value / 100) * skillLevel
            elseif skill.benefit_type == 'flat' then
                return skill.benefit_value * skillLevel
            end
        end
    end
    
    return 0
end

-- Calcular multiplicador de pagamento baseado em habilidades
function Progression.GetPaymentMultiplier(identifier, contractType)
    local skills = Players.GetSkills(identifier)
    local multiplier = 1.0
    
    -- Bônus de eficiência
    if skills.earning_rate then
        multiplier = multiplier + (skills.earning_rate * 0.01)
    end
    
    -- Bônus por tipo de carga
    if contractType == 'fragile' and skills.fragile_cargo then
        multiplier = multiplier + (skills.fragile_cargo * 0.01)
    elseif contractType == 'high_value' and skills.high_value_cargo then
        multiplier = multiplier + (skills.high_value_cargo * 0.01)
    end
    
    return multiplier
end

-- Obter árvore de habilidades
function Progression.GetSkillTree(identifier)
    local profile = Players.GetProfile(identifier)
    if not profile then
        return {}
    end
    
    local skills = Players.GetSkills(identifier)
    local tree = {}
    
    for _, skill in ipairs(Config.SkillTree or {}) do
        local currentLevel = (skills and skills[skill.id]) or 0
        
        table.insert(tree, {
            id = skill.id,
            name = skill.name,
            description = skill.description,
            level_requirement = skill.level_requirement,
            cost = skill.cost,
            max_level = skill.max_level,
            current_level = currentLevel,
            unlocked = currentLevel > 0,
            can_unlock = profile.level >= skill.level_requirement and profile.total_money >= skill.cost,
            benefit_type = skill.benefit_type,
            benefit_value = skill.benefit_value,
        })
    end
    
    return tree
end

-- Calcular progresso de nível
function Progression.GetLevelProgress(identifier)
    local profile = Players.GetProfile(identifier)
    if not profile then
        return nil
    end
    
    local currentLevelXP = (profile.level - 1) * Config.Progression.XpPerLevel
    local nextLevelXP = profile.level * Config.Progression.XpPerLevel
    local currentProgress = profile.experience - currentLevelXP
    local progressNeeded = nextLevelXP - currentLevelXP
    
    return {
        level = profile.level,
        current_xp = profile.experience,
        progress = currentProgress,
        required = progressNeeded,
        percentage = (currentProgress / progressNeeded) * 100,
        is_max_level = profile.level >= Config.Progression.MaxLevel,
    }
end

return Progression