function PracticeStart( trigger )
	local caster = trigger.activator
	local caller = trigger.caller
	if caller.unitRemaining == nil then
		caller.unitRemaining = {}
	end
	if caller.used == nil then
		caller.used = 0
	end
	for i=1,4 do
	 	if caller:GetName() == "practice_"..tostring(i) then
	 		if caster:IsRealHero() then
			 	caller.used = caller.used + 1
				if caller.used == 1 and caller.onthink == false then
					PracticeThink(caller,caster)
					caller.onthink = true
				end
			end
	 		break
	 	end
	 end
	--print("[GuardingAthena]Practice Start")
end
function PracticeThink( caller, caster )
	Timers:CreateTimer(1,function()
		if caller.used >= 1 then
			if #caller.unitRemaining <= 0 then
	        	PracticeDoSpawn( caller, caster )
	        	return 2
	        else
	        	return 2
	        end
	    end
	    caller.onthink = false
    end)
end
function PracticeDoSpawn( caller, caster )
	local practice_level = math.floor(caster.practice * 0.02)
	for i=1,10 do
		PrecacheUnitByNameAsync( "practicer", function()
			local SpawnPoint = caller:GetAbsOrigin()
			local unit = CreateUnitByName("practicer", SpawnPoint, true, nil, nil, DOTA_TEAM_BADGUYS )
			local level = math.floor((GameRules:GetGameTime() - GuardingAthena.GameStartTime) / 120)
			unit:AddNewModifier(nil, nil, "modifier_phased", {duration=0.2})
			unit:CreatureLevelUp(level)
			unit:SetDeathXP(unit:GetDeathXP() * 1.6 * (1 + 0.01 * practice_level))
			unit:SetMinimumGoldBounty(unit:GetMinimumGoldBounty() * 1.6 * (1 + 0.01 * practice_level))
			unit:SetMaximumGoldBounty(unit:GetMaximumGoldBounty() * 1.6 * (1 + 0.01 * practice_level))
			unit.room = caller
			table.insert(caller.unitRemaining,unit)
		end)
	end
end	
function PracticeEnd( trigger )
	local caster = trigger.activator
	local caller = trigger.caller
	for i=1,4 do
	 	if caller:GetName() == "practice_"..tostring(i) then
	 		if caster:IsRealHero() then
				caller.used = caller.used - 1
			end
	 		break
	 	end
	end
end