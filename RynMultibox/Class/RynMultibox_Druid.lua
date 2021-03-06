if ryn.playerClass=="DRUID" then

ryn.buffMark="Interface\\Icons\\Spell_Nature_Regeneration"
ryn.buffThorns="Interface\\Icons\\Spell_Nature_Thorns"
ryn.buffAbolishPoison="Interface\\Icons\\Spell_Nature_NullifyPoison_02"
ryn.debuffFaerieFire="Interface\\Icons\\Spell_Nature_FaerieFire"
--ryn.buffMoonkinForm="Interface\\Icons\\Spell_Nature_ForceOfNature"
--ryn.buffTravelForm="Interface\\Icons\\Ability_Druid_TravelForm"
--ryn.buffCatForm="Interface\\Icons\\Ability_Druid_CatForm"
--ryn.buffBearForm="Interface\\Icons\\Ability_Racial_BearForm"
--ryn.buffAquaticForm="Interface\\Icons\\Ability_Druid_AquaticForm"

ryn.druidDispelRange="Thorns"
ryn.faerieFireActionSlot=10

ryn.ClassEventHandler=function()
	if event=="UI_ERROR_MESSAGE" and arg1=="Target not in line of sight" then
		ryn.BlacklistTarget(ryn.currentHealTarget)
	end
end

ryn.classEventFrame=CreateFrame("Frame")
ryn.classEventFrame:RegisterEvent("UI_ERROR_MESSAGE")
ryn.classEventFrame:SetScript("OnEvent",ryn.ClassEventHandler)

--ryn.GetForm=function()
--	for i=1,5 do
--		local _,_,active=GetShapeshiftFormInfo(i)
--		if active then
--			return i
--		end
--	end
--end

ryn.IsMoonkin=function()
	local _,_,active=GetShapeshiftFormInfo(5)
	if active then
		return true
	end
	return false
end

ryn.Buff=function(lTargetList,groupBuff)
	lTargetList=lTargetList or ryn.targetList.all
	groupBuff=groupBuff or true
	for target,info in pairs(lTargetList) do
		if info.role=="tank" and not ryn.BuffCheck(target,ryn.buffThorns) then
			ryn.ClearFriendlyTarget()
			CastSpellByName("Thorns")
			if ryn.IsValidSpellTarget(target) then
				SpellTargetUnit(target)
				return
			end
			SpellStopTargeting()
		elseif not ryn.BuffCheck(target,ryn.buffMark) then
			if ryn.IsMoonkin() then
				CastShapeshiftForm(5)
				return
			else
				ryn.ClearFriendlyTarget()
				if groupBuff then
					CastSpellByName("Gift of the Wild")
				else
					CastSpellByName("Mark of the Wild")
				end
				if ryn.IsValidSpellTarget(target) then
					SpellTargetUnit(target)
					return
				end
				SpellStopTargeting()
			end
		end
	end
	if not ryn.IsMoonkin() then
		CastShapeshiftForm(5)
	end
end

ryn.CC=function()
	if ryn.TryTargetRaidIcon(4,10,true) then
		CastSpellByName("Hibernate")
	end
end

ryn.dispelAll={Poison=true,Curse=true}
ryn.dispelPoison={Poison=true}
ryn.dispelCurse={Curse=true}

ryn.Dispel=function(lTargetList,dispelTypes,moonkinSwap)
	lTargetList=lTargetList or ryn.targetList.all
	dispelTypes=dispelTypes or ryn.dispelAll
	moonkinSwap=moonkinSwap or false
	if ryn.SpellCastReady(ryn.druidDispelRange,false) then
		local target,debuffType=ryn.GetDispelTarget(lTargetList,ryn.druidDispelRange,dispelTypes,false)
		if target then
			if moonkinSwap and ryn.IsMoonkin() then
				CastShapeshiftForm(5)
				return
			end
			ryn.targetList.all[target].blacklist=nil
			ryn.currentHealTarget=target
			if debuffType=="Curse" then
				CastSpellByName("Remove Curse")
			elseif not ryn.BuffCheck(target,ryn.buffAbolishPoison) then
				CastSpellByName("Abolish Poison")
			else
				CastSpellByName("Cure Poison")
			end
			SpellTargetUnit(target)
		elseif moonkinSwap and not ryn.IsMoonkin() then
			CastShapeshiftForm(5)
		end
	end
end

-- ffMode 1: Applies faerie fire on the current dps target
-- ffMode 2: Applies faerie fire on tank targets
ryn.Dps=function(ffMode)
	if not ryn.IsMoonkin() then
		CastShapeshiftForm(5)
	elseif not ryn.IsCastingOrChanelling() then
		if ffMode==2 and ryn.GetSpellCooldownByName("Faerie Fire")==0 then
			for target,info in ryn.targetList.tank do
				local currentTarget=target.."target"
				if UnitCanAttack("player",currentTarget) and not ryn.DebuffCheck(currentTarget,ryn.debuffFaerieFire) and UnitAffectingCombat(currentTarget) then
					TargetUnit(currentTarget)
					if IsActionInRange(ryn.faerieFireActionSlot)==1 then
						CastSpellByName("Faerie Fire")
						return
					end
				end
			end
		end
		if ryn.GetHostileTarget() then
			if ffMode==1 and not ryn.DebuffCheck("target",ryn.debuffFaerieFire) and IsActionInRange(ryn.faerieFireActionSlot)==1 then
				CastSpellByName("Faerie Fire")
			elseif ryn.damageType.arcane then
				CastSpellByName("Starfire")
			elseif ryn.damageType.nature then
				CastSpellByName("Wrath")
			end
		end
	end
end

end