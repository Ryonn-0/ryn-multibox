if ryn.playerClass=="HUNTER" then
local ryn=ryn

ryn.buffHawk="Interface\\Icons\\Spell_Nature_RavenForm"
ryn.buffTrueshot="Interface\\Icons\\Ability_TrueShot"
ryn.debuffMark="Interface\\Icons\\Ability_Hunter_SniperShot"

-- Settings
ryn.aimedShotWindow=1 -- low value, with 3.0+ ranged attack speed (full/auto shot rotation), or a higher value with 2.9- ranged attack speed (clipped/aimed shot rotation)
ryn.multiShotWindow=1.6 -- should be around ranged attack speed minus 1

-- Action bar slot ids
--ryn.aimedShotActionSlot=1
--ryn.autoShotActionSlot=2
--ryn.multiShotActionSlot=4
--ryn.autoAttackActionSlot=60
--ryn.raptorStrikeActionSlot=61
--ryn.mongooseBiteActionSlot=62

ryn.ClassActionSlotInit=function()
	ryn.aimedShotActionSlot=ryn.GetActionSlot("Aimed Shot")
	--ryn.Debug(ryn.aimedShotActionSlot)
	ryn.autoShotActionSlot=ryn.GetActionSlot("Auto Shot")
	--ryn.Debug(ryn.autoShotActionSlot)
	ryn.multiShotActionSlot=ryn.GetActionSlot("Multi-Shot")
	--ryn.Debug(ryn.multiShotActionSlot)
	ryn.autoAttackActionSlot=ryn.GetActionSlot("Attack")
	--ryn.Debug(ryn.autoAttackActionSlot)
	ryn.raptorStrikeActionSlot=ryn.GetActionSlot("Raptor Strike")
	--ryn.Debug(ryn.raptorStrikeActionSlot)
	ryn.mongooseBiteActionSlot=ryn.GetActionSlot("Mongoose Bite")
	--ryn.Debug(ryn.mongooseBiteActionSlot)
end

ryn.aimedShotExpire=0
ryn.multiShotExpire=0
ryn.arrowCount=GetInventoryItemCount("player",0)
ryn.ignoreNext=false

ryn.ClassEventHandler=function()
	local newArrowCount=GetInventoryItemCount("player",0)
	if ryn.arrowCount~=newArrowCount then
		ryn.arrowCount=newArrowCount
		if ryn.ignoreNext then
			ryn.ignoreNext=false
		else
			ryn.aimedShotExpire=GetTime()+ryn.aimedShotWindow
			ryn.multiShotExpire=GetTime()+ryn.multiShotWindow
		end
	end
end

ryn.classEventFrame=CreateFrame("Frame")
ryn.classEventFrame:RegisterEvent("BAG_UPDATE")
ryn.classEventFrame:SetScript("OnEvent",ryn.ClassEventHandler)

ryn.Buff=function()
	if not ryn.BuffCheck("player",ryn.buffHawk) then
		CastSpellByName("Aspect of the Hawk")
	elseif not ryn.BuffCheck("player",ryn.buffTrueshot) then
		CastSpellByName("Trueshot Aura")
	end
	--TODO: Add hunter's mark
end

ryn.RangedDps=function()
	if not IsAutoRepeatAction(ryn.autoShotActionSlot) then
		CastSpellByName("Auto Shot")
		ryn.ignoreNext=false
		return
	end
	if not IsCurrentAction(ryn.aimedShotActionSlot) and not IsCurrentAction(ryn.multiShotActionSlot) then
		if ryn.aimedShotExpire>=GetTime() and ryn.IsActionReady(ryn.aimedShotActionSlot) then
			CastSpellByName("Aimed Shot")
			ryn.ignoreNext=true
		elseif ryn.damageType.aoe and ryn.multiShotExpire>=GetTime() and ryn.IsActionReady(ryn.multiShotActionSlot) then
			CastSpellByName("Multi-Shot")
			ryn.ignoreNext=true
		end
	end
end

ryn.MeleeDps=function()
	if ryn.IsActionReady(ryn.mongooseBiteActionSlot) then
		CastSpellByName("Mongoose Bite")
	elseif not IsCurrentAction(ryn.raptorStrikeActionSlot) and ryn.IsActionReady(ryn.raptorStrikeActionSlot) then
		CastSpellByName("Raptor Strike")
	elseif not IsCurrentAction(ryn.autoAttackActionSlot) then
		CastSpellByName("Attack")
	end
end

ryn.Dps=function()
	if ryn.GetHostileTarget() then
		--if ryn.damageType.arcane and not ryn.DebuffCheck("target",ryn.debuffMark) then
		--	CastSpellByName("Hunter's Mark")
		if ryn.damageType.ranged and IsActionInRange(ryn.autoShotActionSlot)==1 then
			if ryn.dpsCooldownToggle then
				if ryn.UseTrinkets() then return
				else
					local rapidFireActionSlot=ryn.GetActionSlot("Rapid Fire")
					if rapidFireActionSlot and ryn.IsActionReady(rapidFireActionSlot) then
						CastSpellByName("Rapid Fire")
						return
					else
						ryn.dpsCooldownToggle=false
					end
				end
			end
			ryn.RangedDps()
		elseif ryn.damageType.melee and IsActionInRange(ryn.mongooseBiteActionSlot)==1 then
			ryn.MeleeDps()
		end
	end
	-- TODO: pet stuff here
end

end