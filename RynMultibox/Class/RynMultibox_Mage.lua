local class

if ryn.playerClass=="MAGE" then
class={}

class.dispelRange="Remove Lesser Curse"

class.EventHandler=function()
	if event=="UI_ERROR_MESSAGE" and arg1=="Target not in line of sight" then
		ryn.BlacklistTarget(ryn.currentHealTarget)
	end
end

class.eventFrame=CreateFrame("Frame")
class.eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
class.eventFrame:SetScript("OnEvent",class.EventHandler)

ryn.Dispel=function(lTargetList)
	lTargetList=lTargetList or ryn.targetList.all
	if ryn.SpellCastReady(class.dispelRange,false) then
		local target=ryn.GetDispelTarget(lTargetList,class.dispelRange,{Curse=true},false)
		if target then
			lTargetList[target].blacklist=nil
			ryn.currentHealTarget=target
			CastSpellByName("Remove Lesser Curse")
			SpellTargetUnit(target)
		end
	end
end

ryn.CC=function()
	if not ryn.IsCastingOrChanelling() and ryn.TryTargetRaidIcon(3,10,true) then
		local unitType=UnitCreatureType("target")
		if UnitMana("player")>=150 and (unitType=="Humanoid" or unitType=="Beast") then
			CastSpellByName("Polymorph")
		end
	end
end

ryn.Dps=function()
	if not ryn.IsCastingOrChanelling() and ryn.GetHostileTarget() then
		if ryn.damageType.frost then
			CastSpellByName("Frostbolt")
		elseif ryn.damageType.fire then
			CastSpellByName("Fireball")
		elseif ryn.damageType.arcane then
			CastSpellByName("Arcane Missiles")
		end
	end
	-- TODO: Evocation, mana gem and wanding.
end

end