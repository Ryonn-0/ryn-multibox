local class

if ryn.playerClass=="WARLOCK" then
class={}

class.buffDemon="Interface\\Icons\\Spell_Shadow_RagingScream"
class.buffFire="Interface\\Icons\\Spell_Fire_FireArmor"
--class.buffSoulstone="Interface\\Icons\\Spell_Shadow_SoulGem"

ryn.Buff=function(lTargetList)
	lTargetList=lTargetList or ryn.targetList.all
	-- Returns are intentionally left out after warlock buff/summon, because the warlock and the minion can cast a spell simultaneously with a single function call.
	if not HasPetUI() then
		if UnitMana("player")>=1098 then
			CastSpellByName("Summon Imp")
		elseif not ryn.HpLower("player",0.4) then
			CastSpellByName("Life Tap")
		end
	elseif not ryn.BuffCheck("player",class.buffDemon) then
		if UnitMana("player")>=1580 then
			CastSpellByName("Demon Armor")
		elseif not ryn.HpLower("player",0.4) then
			CastSpellByName("Life Tap")
		end
	end
	for target,info in pairs(lTargetList) do
		if info.role=="tank" and not ryn.BuffCheck(target,class.buffFire) then
			TargetUnit(target)
			CastSpellByName("Fire Shield")
		end
	end
end

ryn.CC=function()
	if not ryn.IsCastingOrChanelling() and ryn.TryTargetRaidIcon(5,10,true) then
		local unitType,mana=UnitCreatureType("target"),UnitMana("player")
		if mana>=200 and (unitType=="Elemental" or unitType=="Demon") then
			CastSpellByName("Banish")
		elseif mana>=205 then
			CastSpellByName("Fear")
		elseif not ryn.HpLower("player",0.4) then
			CastSpellByName("Life Tap")
		end
	end
end

ryn.Dps=function()
	if not ryn.IsCastingOrChanelling() and ryn.GetHostileTarget() then
		local mana,noMana=UnitMana("player"),false
		if ryn.damageType.shadow then
			if mana>=372 then
				CastSpellByName("Shadow Bolt")
				return
			else
				noMana=true
			end
		elseif ryn.damageType.fire then
			if mana>=168 then
				CastSpellByName("Searing Pain")
				return
			else
				noMana=true
			end
		end
		if noMana and not ryn.HpLower("player",0.4) then
			CastSpellByName("Life Tap")
		end
	end
	-- TODO: Apply curse, use wand if Life Tap can not be cast or below a hp threshold.
end

ryn.DrainSoul=function()
	if not ryn.IsCastingOrChanelling() and ryn.GetHostileTarget() then
		if ryn.HpLower("target",0.3) then
			if UnitMana("player")>=290 then
				CastSpellByName("Drain Soul")
			elseif not ryn.HpLower("player",0.4) then
				CastSpellByName("Life Tap")
			end
		else
			ryn.Dps()
		end
	end
end

ryn.DrainMana=function()
	if not ryn.IsCastingOrChanelling() and ryn.GetHostileTarget() then
		CastSpellByName("Drain Mana")
	end
end

end