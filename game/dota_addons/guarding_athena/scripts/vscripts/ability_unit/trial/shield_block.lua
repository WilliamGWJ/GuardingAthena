function ShieldBlockAI( t )
    local caster = t.caster
    local ability = t.ability
    if RollPercentage(30) then
        CastAbility(caster,DOTA_UNIT_ORDER_CAST_NO_TARGET,ability,nil,nil)
    end
end
function OnSpellStart( t )
    local caster = t.caster
    local ability = t.ability
    local duration = ability:GetSpecialValueFor("duration")
    local particleName = "particles/units/heroes/hero_pangolier/pangolier_tailthump_buff_parent.vpcf"
    local p = CreateParticle(particleName,PATTACH_ABSORIGIN_FOLLOW,caster,duration)
    ParticleManager:SetParticleControl(p, 1, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(p, 3, Vector(300, 0, 0))
    ParticleManager:SetParticleControl(p, 8, Vector(5, 0, 0))
    ability:ApplyDataDrivenModifier(caster, caster, "modifier_shield_block_buff", nil)
    AddDamageFilterVictim(caster,"shield_block",function (damage,attacker)
        if caster:HasModifier("modifier_shield_block_buff") then
            CauseDamage(caster,attacker,damage,DAMAGE_TYPE_MAGICAL,ability)
            ability:ApplyDataDrivenModifier(caster, attacker, "modifier_shield_block_debuff", nil)
            return 0
        end
        return damage
    end)
    Timers:CreateTimer(duration,function ()
        RemoveDamageFilterVictim(caster,"shield_block")
    end)
end