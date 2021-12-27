if ryn.playerClass=="MAGE" then
local ryn=ryn

ryn.buff={}
local buff=ryn.buff
buff["Ice Block"]="Interface\\Icons\\Spell_Frost_Frost"
buff["Mage Armor"]="Interface\\Icons\\Spell_MageArmor"
buff["Arcane Brilliance"]="Interface\\Icons\\Spell_Holy_ArcaneIntellect"
buff["Arcane Intellect"]="Interface\\Icons\\Spell_Holy_MagicalSentry"

ryn.debuff={}
local debuff=ryn.debuff
ryn.debuff["Polymorph"]="Interface\\Icons\\Spell_Nature_Polymorph"

ryn.dispelRange="Remove Lesser Curse"
ryn.startCasting=0.2

ryn.ClassActionSlotInit=function()
	ryn.wandActionSlot=ryn.GetActionSlot("Shoot")
	ryn.polymorphActionSlot=ryn.GetActionSlot("Polymorph")
end

ryn.ClassEventHandler=function()
	if event=="UI_ERROR_MESSAGE" and arg1=="Target not in line of sight" then
		ryn.BlacklistTarget(ryn.currentHealTarget)
		ryn.currentPolyTarget=nil
	end
end

ryn.classEventFrame=CreateFrame("Frame")
ryn.classEventFrame:RegisterEvent("UI_ERROR_MESSAGE")
ryn.classEventFrame:SetScript("OnEvent",ryn.ClassEventHandler)

ryn.Dispel=function(lTargetList)
	lTargetList=lTargetList or ryn.targetList.all
	if ryn.SpellCastReady(ryn.dispelRange,false) then
		local target=ryn.GetDispelTarget(lTargetList,ryn.dispelRange,{Curse=true},false)
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

ryn.CCPlayer=function()
	local target=ryn.currentPolyTarget
	if target then
		if not UnitCanAttack("player",target) then
			ryn.currentPolyTarget=nil
		elseif not ryn.DebuffCheck(target,debuff["Polymorph"]) then
			TargetUnit(target)
			if IsActionInRange(ryn.polymorphActionSlot)==1 then
				CastSpellByName("Polymorph")
				--ryn.Debug("Poly: "..UnitName(target))
			end
		-- TODO: NOT WORKING PROPERLY, need to do some testing
		elseif ryn.IsCastingOrChanelling() and CastingBarText:GetText()=="Polymorph" then
			SpellStopCasting()
			--ryn.stopCastingDelayExpire=GetTime()+ryn.stopCastingDelayreturn
			return
		end
	end
	for target,info in ryn.targetList.all do
		if UnitCanAttack("player",target) and not ryn.IsBlacklisted(target) and not ryn.DebuffCheck(target,debuff["Polymorph"]) then
			TargetUnit(target)
			if IsActionInRange(ryn.polymorphActionSlot)==1 then
				ryn.currentHealTarget=target
				ryn.currentPolyTarget=target -- Fixate on a target, until the mind control expires.
				CastSpellByName("Polymorph")
				SendChatMessage("Poly: "..info.name,"SAY")
			end
		end
	end
end

ryn.Buff=function(lTargetList)
	lTargetList=lTargetList or ryn.targetList.all
	if not ryn.IsCastingOrChanelling() then
		if not ryn.BuffCheck("player",buff["Mage Armor"]) then
			CastSpellByName("Mage Armor")
			return
		end
		ryn.ClearFriendlyTarget()
		CastSpellByName("Arcane Intellect")
		if not SpellIsTargeting() then return end
		local groups={}
		if UnitInRaid("player") then
			for i=1,8 do groups["group"..i]=true end
		else
			groups["party"]=true
		end
		for group,_ in groups do
			local count,buffTarget=0,nil
			for target,info in pairs(ryn.targetList[group]) do
				if not ryn.BuffCheck(target,buff["Arcane Brilliance"]) and not ryn.BuffCheck(target,buff["Arcane Intellect"]) and info.class~="WARRIOR" and info.class~="ROGUE" and ryn.IsValidSpellTarget(target) then
					count=count+1
					buffTarget=target
				end
			end
			if count>=3 then
				CastSpellByName("Arcane Brilliance")
				SpellTargetUnit(buffTarget)
				return
			elseif count >=1 then
				SpellTargetUnit(buffTarget)
				return
			end
		end
		SpellStopTargeting()
	end
end

ryn.Dps=function()
	if not ryn.IsCastingOrChanelling() and ryn.GetHostileTarget() then
		local mana,noMana=UnitMana("player"),false
		if not ryn.waitManaRegen or not ryn.ManaLower("player",ryn.startCasting) then
			ryn.waitManaRegen=false
			if ryn.dpsCooldownToggle then
				if ryn.UseTrinkets() then return
				elseif ryn.GetSpellCooldownByName("Arcane Power")==0 then
					CastSpellByName("Arcane Power")
				else ryn.dpsCooldownToggle=false end
			end
			if ryn.damageType.frost then
				if mana>246 then
					CastSpellByName("Frostbolt")
					return
				end
				noMana=true
			elseif ryn.damageType.fire then
				if mana>410 then
					CastSpellByName("Fireball")
					return
				end
				noMana=true
			elseif ryn.damageType.arcane then
				if mana>655 then
					CastSpellByName("Arcane Missiles")
					return
				end
				noMana=true
			end
			if noMana then
				if ryn.GetSpellCooldownByName("Evocation")==0 then
					CastSpellByName("Evocation")
				else
					ryn.waitManaRegen=true
				end
			end
		else
			if not IsAutoRepeatAction(ryn.wandActionSlot) and IsActionInRange(ryn.wandActionSlot)==1 then
				CastSpellByName("Shoot")
			end
		end
	end
	-- TODO: Mana gem
end

end