if ryn.playerClass=="WARLOCK" then

ryn.buffDemon="Interface\\Icons\\Spell_Shadow_RagingScream"
ryn.buffFire="Interface\\Icons\\Spell_Fire_FireArmor"
--ryn.buffSoulstone="Interface\\Icons\\Spell_Shadow_SoulGem"   -- This is already declared as an addon global variable for SS check

ryn.curses={
	doom={spell="Curse of Doom",debuff="Interface\\Icons\\Spell_Shadow_AuraOfDarkness",mana=300},
	recklessness={spell="Curse of Recklessness",debuff="Interface\\Icons\\Spell_Shadow_UnholyStrength",mana=115},
	shadow={spell="Curse of Shadow",debuff="Interface\\Icons\\Spell_Shadow_CurseOfAchimonde",mana=200},
	tongues={spell="Curse of Tongues",debuff="Interface\\Icons\\Spell_Shadow_CurseOfTounges",mana=110},
	weakness={spell="Curse of Weakness",debuff="Interface\\Icons\\Spell_Shadow_CurseOfMannoroth",mana=175,amplify=true},
	elements={spell="Curse of the Elements",debuff="Interface\\Icons\\Spell_Shadow_ChillTouch",mana=200},
	agony={spell="Curse of Agony",debuff="Interface\\Icons\\Spell_Shadow_CurseOfSargeras",mana=215,amplify=true},
	exhaustion={spell="Curse of Exhaustion",debuff="Interface\\Icons\\Spell_Shadow_GrimWard",mana=109,amplify=true}
}

ryn.tapThreshold=0.4

ryn.Buff=function(lTargetList)
	lTargetList=lTargetList or ryn.targetList.all
	if not HasPetUI() then
		if UnitMana("player")>=1098 then
			CastSpellByName("Summon Imp")
			return
		elseif not ryn.HpLower("player",ryn.tapThreshold) then
			CastSpellByName("Life Tap")
			return
		end
	elseif not ryn.BuffCheck("player",ryn.buffDemon) then
		if UnitMana("player")>=1580 then
			CastSpellByName("Demon Armor")
		elseif not ryn.HpLower("player",ryn.tapThreshold) then
			CastSpellByName("Life Tap")
		end
	elseif not ryn.HpLower("player",ryn.tapThreshold) and ryn.ManaLower("player",0.85) then
		CastSpellByName("Life Tap")
	end
	for target,info in pairs(lTargetList) do
		if info.role=="tank" and not ryn.BuffCheck(target,ryn.buffFire) then
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
		elseif not ryn.HpLower("player",ryn.tapThreshold) then
			CastSpellByName("Life Tap")
		end
	end
end

ryn.Dps=function(curse,drainThreshold)
	if ryn.IsCastingOrChanelling() then return end
	if ryn.GetHostileTarget() then
		local mana,noMana=UnitMana("player"),false
		if curse then
			curse=ryn.curses[curse]
		end
		if ryn.dpsCooldownToggle then
			if ryn.UseTrinkets() then return
			else ryn.dpsCooldownToggle=false end
		end
		if ryn.damageType.shadow then
			if drainThreshold and mana>=290 and ryn.HpLower("target",drainThreshold) then
				CastSpellByName("Drain Soul")
				return
			elseif curse and ryn.SpellExists(curse.spell) and mana>=curse.mana and not ryn.DebuffCheck("target",curse.debuff) then
				if curse.amplify and ryn.GetSpellCooldownByName("Amplify Curse")==0 then
					CastSpellByName("Amplify Curse")
					return
				end
				CastSpellByName(curse.spell)
				return
			elseif mana>=372 then
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
		if noMana and not ryn.HpLower("player",ryn.tapThreshold) then
			CastSpellByName("Life Tap")
		end
	elseif not ryn.HpLower("player",ryn.tapThreshold) and ryn.ManaLower("player",0.85) then
		CastSpellByName("Life Tap")
	end
	-- TODO: Use wand if Life Tap can not be cast or below a hp threshold.
end

ryn.DrainMana=function()
	if not ryn.IsCastingOrChanelling() and ryn.GetHostileTarget() then
		CastSpellByName("Drain Mana")
	end
end

end