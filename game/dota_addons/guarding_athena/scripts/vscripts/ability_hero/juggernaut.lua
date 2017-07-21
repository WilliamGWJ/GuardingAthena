function minjiejingtong( keys )
	local caster = keys.caster
	local ability = keys.ability
	local stackcount = caster:GetBaseAgility() * 0.001 + 0.1
	if stackcount > 1 then
		stackcount = 1
	end
	local attack_rate = caster:GetBaseAttackTime() - stackcount
	if attack_rate < 0.4 then
		attack_rate = 0.4
	end
	caster:SetBaseAttackTime(attack_rate)
	Timers:CreateTimer(5,function (  )
		caster:SetBaseAttackTime(1.4)
	end)
end
function SpaceCut( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local caster_location = caster:GetAbsOrigin()
	local target_location = target:GetAbsOrigin()
	local vector = caster:GetForwardVector()
	local point = target_location + vector * 100
	SetUnitPosition(caster, point)
	local teamNumber = caster:GetTeamNumber()
	local targetTeam = ability:GetAbilityTargetTeam()
	local targetType = ability:GetAbilityTargetType()
	local damageType = ability:GetAbilityDamageType()
	local damage = ability:GetSpecialValueFor("damage") * caster:GetAgility() + ability:GetSpecialValueFor("base_damage")
	local unitGroup = FindUnitsInLine( teamNumber, caster_location, point, nil, 100, targetTeam, targetType, FIND_CLOSEST)
	for k, v in pairs( unitGroup ) do
        CauseDamage(caster, v, damage, damageType, ability)
        local duration = damage / v:GetMaxHealth() * 10
        ability:ApplyDataDrivenModifier(caster, v, "modifier_space_cut_debuff", {duration = duration})
    end
    --local find_illusions = FindUnitsInRadius(teamNumber, caster_location, caster, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, targetType, targetFlag, 0, false)
	if not caster.mirror_image_illusions then
        caster.mirror_image_illusions = {}
    end
    local illusions = caster.mirror_image_illusions
	for k,v in pairs(illusions) do
        if v:IsNull() then 
            table.remove(illusions, k)
        end
    end
    --[[for k, v in pairs( find_illusions ) do
        if v:IsIllusion() then
        	table.insert(illusions,v)
        end
    end]]--
    if #illusions > 0 then
	    for k, v in pairs( illusions ) do
            if not v:IsNull() then
                local distance = (v:GetAbsOrigin() - caster_location):Length2D()
                if distance <= 1200 then
                    local fxIndex = CreateParticle( "particles/skills/space_cut_blade.vpcf", PATTACH_ABSORIGIN_FOLLOW, v )
                    local illusion_location = v:GetAbsOrigin()
                    local illusion_vector = v:GetForwardVector()
                    local point = target_location + vector * 100
                    SetUnitPosition(v, point)
                    local unitGroup = FindUnitsInLine( teamNumber, illusion_location, point, nil, 100, targetTeam, targetType, FIND_CLOSEST)
                    for k, v in pairs( unitGroup ) do
                        CauseDamage(caster, v, damage, damageType, ability)
                    end
                end
            end
	    end
	end
end
function SpaceCutIllusion( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local caster_location = caster:GetAbsOrigin()
	local target_location = target:GetAbsOrigin()
	local teamNumber = caster:GetTeamNumber()
	local targetTeam = ability:GetAbilityTargetTeam()
	local targetType = ability:GetAbilityTargetType()
	local targetFlag = ability:GetAbilityTargetFlags()
	local find_illusions = FindUnitsInRadius(teamNumber, caster_location, caster, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, targetType, targetFlag, 0, false)
    local illusions = {}
    for k, v in pairs( find_illusions ) do
        if v:IsIllusion() then
        	table.insert(illusions,v)
        end
    end
    if #illusions > 0 then
	    for k, v in pairs( illusions ) do
	    	ability:ApplyDataDrivenModifier(caster, v, "modifier_space_cut", nil)
	    	v:SetForwardVector((target_location - caster_location):Normalized())
	        v:StartGesture(1505)
	    end
	end
end
function MirrorImage( event )
    local caster = event.caster
    local player = caster:GetPlayerID()
    local ability = event.ability
    local unit_name = caster:GetUnitName()
    local images_count = ability:GetSpecialValueFor("images_count")
    local duration = ability:GetSpecialValueFor("duration")
    local outgoingDamage = ability:GetSpecialValueFor("output_damage")
    local incomingDamage = ability:GetSpecialValueFor("input_damage")

    local casterOrigin = caster:GetAbsOrigin()
    local casterAngles = caster:GetAngles()

    -- Stop any actions of the caster otherwise its obvious which unit is real
    caster:Stop()

    -- Initialize the illusion table to keep track of the units created by the spell
    if not caster.mirror_image_illusions then
        caster.mirror_image_illusions = {}
    end

    -- Kill the old images
    for k,v in pairs(caster.mirror_image_illusions) do
        if v and IsValidEntity(v) then 
            v:ForceKill(false)
        end
    end

    -- Start a clean illusion table
    caster.mirror_image_illusions = {}

    -- Setup a table of potential spawn positions
    local vRandomSpawnPos = {
        Vector( 72, 0, 0 ),     -- North
        Vector( 0, 72, 0 ),     -- East
        Vector( -72, 0, 0 ),    -- South
        Vector( 0, -72, 0 ),    -- West
        Vector( 72, 72, 0 ),    -- West
        Vector( -72, -72, 0 ),    -- West
    }

    for i=#vRandomSpawnPos, 2, -1 do    -- Simply shuffle them
        local j = RandomInt( 1, i )
        vRandomSpawnPos[i], vRandomSpawnPos[j] = vRandomSpawnPos[j], vRandomSpawnPos[i]
    end

    -- Insert the center position and make sure that at least one of the units will be spawned on there.
    table.insert( vRandomSpawnPos, RandomInt( 1, images_count+1 ), Vector( 0, 0, 0 ) )

    -- At first, move the main hero to one of the random spawn positions.
    SetUnitPosition( caster, casterOrigin + table.remove( vRandomSpawnPos, 1 ) )

    -- Spawn illusions
    for i=1, images_count do

        local origin = casterOrigin + table.remove( vRandomSpawnPos, 1 )

        -- handle_UnitOwner needs to be nil, else it will crash the game.
        local illusion = CreateUnitByName(unit_name, origin, true, caster, nil, caster:GetTeamNumber())
        illusion.caster_hero = caster
        HeroState:InitIllusion(illusion)
        illusion:SetPlayerID(caster:GetPlayerID())
        illusion:SetControllableByPlayer(player, true)

        illusion:SetAngles( casterAngles.x, casterAngles.y, casterAngles.z )
        
        -- Level Up the unit to the casters level
        local casterLevel = caster:GetLevel()
        for i=1,casterLevel-1 do
            illusion:HeroLevelUp(false)
        end

        -- Set the skill points to 0 and learn the skills of the caster
        illusion:SetAbilityPoints(0)
        for abilitySlot=0,15 do
            local ability = caster:GetAbilityByIndex(abilitySlot)
            if ability ~= nil then 
                local abilityLevel = ability:GetLevel()
                local abilityName = ability:GetAbilityName()
                local illusionAbility = illusion:GetAbilityByIndex(abilitySlot)
                if illusionAbility then
                	illusionAbility:SetLevel(abilityLevel)
                end
            end
        end

        -- Recreate the items of the caster
        for itemSlot=0,5 do
            local item = caster:GetItemInSlot(itemSlot)
            if item ~= nil then
                local itemName = item:GetName()
                local newItem = CreateItem(itemName, illusion, illusion)
                illusion:AddItem(newItem)
            end
        end

        -- Set the unit as an illusion
        -- modifier_illusion controls many illusion properties like +Green damage not adding to the unit damage, not being able to cast spells and the team-only blue particle
        illusion:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration, outgoing_damage = outgoingDamage, incoming_damage = incomingDamage })
        ability:ApplyDataDrivenModifier(caster, illusion, "modifier_images_buff", nil)
        --illusion:AddNewModifier(nil, nil, "modifier_phased", {duration = duration})
        
        -- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
        illusion:MakeIllusion()
        -- Set the illusion hp to be the same as the caster
        illusion:SetHealth(caster:GetHealth())

        -- Add the illusion created to a table within the caster handle, to remove the illusions on the next cast if necessary
        table.insert(caster.mirror_image_illusions, illusion)

    end
end
function BladeDance( keys )
	local caster = keys.caster
	local fxIndex = CreateParticle( "particles/skills/blade_dance.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControl( fxIndex, 2, Vector(RandomInt(0, 180),RandomInt(0, 180),RandomInt(0, 180)) )
end
function BladeDanceDamage( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local caster_location = caster:GetAbsOrigin()
	local teamNumber = caster:GetTeamNumber()
	local targetTeam = ability:GetAbilityTargetTeam()
	local targetType = ability:GetAbilityTargetType()
	local targetFlag = ability:GetAbilityTargetFlags()
	local damageType = ability:GetAbilityDamageType()
	local damage = ability:GetSpecialValueFor("damage") * caster:GetAgility()
    local duration = ability:GetSpecialValueFor("duration")
	local unitGroup = FindUnitsInRadius(teamNumber, caster_location, caster, 300, targetTeam, targetType, targetFlag, 0, false)
	for k, v in pairs( unitGroup ) do
        CauseDamage(caster, v, damage, damageType, ability)
    end
    --[[if target:GetUnitName() == "hero_statue_1" or target:GetUnitName() == "hero_statue_2" then
    	return
    end]]--
    AddModifierStackCount( caster, caster, ability, "modifier_blade_dance_attack_speed", 1, duration, true)
    --[[if caster:HasModifier("modifier_blade_dance_attack_speed") then
    	ability:ApplyDataDrivenModifier(caster, caster, "modifier_blade_dance_attack_speed", nil)
    	local stackcount = caster:GetModifierStackCount("modifier_blade_dance_attack_speed", nil) + 1
    	if stackcount < 100 then
    		caster:SetModifierStackCount("modifier_blade_dance_attack_speed", caster, stackcount)
    	end
    else
    	ability:ApplyDataDrivenModifier(caster, caster, "modifier_blade_dance_attack_speed", nil)
    	caster:SetModifierStackCount("modifier_blade_dance_attack_speed", caster, 1)
    end]]--
end
function jianrenfengbao( keys )
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	local targetTeam = ability:GetAbilityTargetTeam() -- DOTA_UNIT_TARGET_TEAM_ENEMY
	local targetType = ability:GetAbilityTargetType() -- DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local targetFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local damageType = ability:GetAbilityDamageType()
	local ability_level = ability:GetLevel() - 1
	local abilityDamage = caster:GetAverageTrueAttackDamage(caster) * ability:GetLevelSpecialValueFor("damage", ability_level) * 0.1
	local casterPos = caster:GetAbsOrigin()
	local fxIndex = CreateParticle( "particles/skills/invoker.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
    Timers:CreateTimer(6,function()
        ParticleManager:DestroyParticle(fxIndex,false)
    end)
    Timers:CreateTimer(function ()
        local times = 0
        Timers:CreateTimer(function ()
            if times < 60 then
                local units = FindUnitsInRadius( caster:GetTeamNumber(),caster:GetAbsOrigin(), caster, 500,
                targetTeam, targetType, targetFlag, 0, false )
                for k,v in pairs ( units ) do
                    CauseDamage( caster, v, abilityDamage, damageType, ability)
                end
            times = times + 1
            return 0.1
            end
        end)  	
    end)	
end