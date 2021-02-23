local class

if ryn.playerClass=="DRUID" then
class={}

class.buffMark="Interface\\Icons\\Spell_Nature_Regeneration"
class.buffThorns="Interface\\Icons\\Spell_Nature_Thorns"
class.buffAbolishPoison="Interface\\Icons\\Spell_Nature_NullifyPoison_02"
--class.buffMoonkinForm="Interface\\Icons\\Spell_Nature_ForceOfNature"
--class.buffTravelForm="Interface\\Icons\\Ability_Druid_TravelForm"
--class.buffCatForm="Interface\\Icons\\Ability_Druid_CatForm"
--class.buffBearForm="Interface\\Icons\\Ability_Racial_BearForm"
--class.buffAquaticForm="Interface\\Icons\\Ability_Druid_AquaticForm"

class.druidDispelRange="Thorns"

class.EventHandler=function()
	if event=="UI_ERROR_MESSAGE" and arg1=="Target not in line of sight" then
		ryn.BlacklistTarget(ryn.currentHealTarget)
	end
end

class.eventFrame=CreateFrame("Frame")
class.eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
class.eventFrame:SetScript("OnEvent",class.EventHandler)

--class.GetForm=function()
--	for i=1,5 do
--		local _,_,active=GetShapeshiftFormInfo(i)
--		if active then
--			return i
--		end
--	end
--end

class.IsMoonkin=function()
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
		if info.role=="tank" and not ryn.BuffCheck(target,class.buffThorns) then
			ryn.ClearFriendlyTarget()
			CastSpellByName("Thorns")
			if ryn.IsValidSpellTarget(target) then
				SpellTargetUnit(target)
				return
			end
			SpellStopTargeting()
		elseif not ryn.BuffCheck(target,class.buffMark) then
			if class.IsMoonkin() then
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
	if not class.IsMoonkin() then
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
	if ryn.SpellCastReady(class.druidDispelRange,false) then
		local target,debuffType=ryn.GetDispelTarget(lTargetList,class.druidDispelRange,dispelTypes,false)
		if target then
			if moonkinSwap and class.IsMoonkin() then
				CastShapeshiftForm(5)
				return
			end
			ryn.targetList.all[target].blacklist=nil
			ryn.currentHealTarget=target
			if debuffType=="Curse" then
				CastSpellByName("Remove Curse")
			elseif not ryn.BuffCheck(target,class.buffAbolishPoison) then
				CastSpellByName("Abolish Poison")
			else
				CastSpellByName("Cure Poison")
			end
			SpellTargetUnit(target)
		elseif moonkinSwap and not class.IsMoonkin() then
			CastShapeshiftForm(5)
		end
	end
end

ryn.Dps=function()
	if not class.IsMoonkin() then
		CastShapeshiftForm(5)
	elseif not ryn.IsCastingOrChanelling() and ryn.GetHostileTarget() then
		CastSpellByName("Starfire")
	end
end

end