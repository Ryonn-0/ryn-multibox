-- TODO: Put the code for each class in separate files or LoD addons.

-- Holy Paladin

buffMight="Interface\\Icons\\Spell_Holy_FistOfJustice"
buffWisdom="Interface\\Icons\\Spell_Holy_SealOfWisdom"
buffLight="Interface\\Icons\\Spell_Holy_PrayerOfHealing02"
buffSalvation="Interface\\Icons\\Spell_Holy_SealOfSalvation"
buffKings="Interface\\Icons\\Spell_Magic_MageArmor"
buffGreaterMight="Interface\\Icons\\Spell_Holy_GreaterBlessingofKings"
buffGreaterWisdom="Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom"
buffGreaterLight="Interface\\Icons\\Spell_Holy_GreaterBlessingofLight"
buffGreaterSalvation="Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation"
buffGreaterKings="Interface\\Icons\\Spell_Magic_GreaterBlessingofKings"
buffDevotionAura="Interface\\Icons\\Spell_Holy_DevotionAura"
buffRetributionAura="Interface\\Icons\\Spell_Holy_AuraOfLight"
buffConcentrationAura="Interface\\Icons\\Spell_Holy_MindSooth"
buffShadowAura="Interface\\Icons\\Spell_Shadow_SealOfKings"
buffFrostAura="Interface\\Icons\\Spell_Frost_WizardMark"
buffFireAura="Interface\\Icons\\Spell_Fire_SealOfFire"
spellFlashHeal="Interface\\Icons\\Spell_Holy_FlashHeal"
spellCleanse="Interface\\Icons\\Spell_Holy_Renew"
palaBuffProfiles={
	Might={"Blessing of Might",buffMight,{PRIEST=true,MAGE=true,WARLOCK=true},{}},
	Wisdom={"Blessing of Wisdom",buffWisdom,{WARRIOR=true,ROGUE=true},{}},
	Salvation={"Blessing of Salvation",buffSalvation,{},{tank=true}},
	Kings={"Blessing of Kings",buffKings,{},{}},
	Light={"Blessing of Light",buffLight,{},{}},
	GreaterMight={"Greater Blessing of Might",buffGreaterMight,{PRIEST=true,MAGE=true,WARLOCK=true},{}},
	GreaterWisdom={"Greater Blessing of Wisdom",buffGreaterWisdom,{WARRIOR=true,ROGUE=true},{}},
	GreaterSalvation={"Greater Blessing of Salvation",buffGreaterSalvation,{},{tank=true}},
	GreaterKings={"Greater Blessing of Kings",buffGreaterKings,{},{}},
	GreaterLight={"Greater Blessing of Light",buffGreaterLight,{},{}}
}
palaBuffCustom={
	Harklen={"Blessing of Light",buffLight},
	Ryonn={"Blessing of Wisdom",buffWisdom},
	Inochi={"Blessing of Wisdom",buffWisdom},
	Nymira={"Blessing of Kings",buffKings},
	Seloris={"Blessing of Wisdom",buffWisdom},
	Alaniel={"Blessing of Wisdom",buffWisdom},
	Arvene={"Blessing of Wisdom",buffWisdom}
}

-- HL: 660,580,465,365,275,190,110,60,35
-- FOL: 140,115,90,70,50,35

function PalaHealTarget(target,hp)
	if target then
		local mana=UnitMana("player")
		if hp<0.4 and mana>=140 and targetList.all[target].role=="tank" then
			CastSpellByName("Divine Favor")
			CastSpellByName("Flash of Light")
		elseif hp<0.6 and mana>=115 then
			CastSpellByName("Flash of Light(Rank 5)")
		elseif hp<0.8 and mana>=70 then
			CastSpellByName("Flash of Light(Rank 3)")
		else
			CastSpellByName("Flash of Light(Rank 1)")
		end
		SpellTargetUnit(target)
	end
end

function PalaHeal(targetList,hpThreshold)
	hpThreshold=hpThreshold or 0.9
	local target,hp=GetHealTarget(targetList,"Flash of Light",hpThreshold)
	PalaHealTarget(target,hp)
end

palaDispelAll={Magic=true,Disease=true,Poison=true}
palaDispelMagic={Magic=true}
palaDispelDisease={Disease=true}
palaDispelPoison={Poison=true}
palaDispelNoMagic={Disease=true,Poison=true}
palaDispelNoDisease={Magic=true,Poison=true}
palaDispelNoPoison={Magic=true,Disease=true}

function PalaDispelTarget(target)
	if target then
		CastSpellByName("Cleanse")
		SpellTargetUnit(target)
	end
end

function PalaDispel(targetList,dispelTypes,dispelByHp)
	dispelTypes=dispelTypes or palaDispelAll
	dispelByHp=dispelByHp or false
	local target=GetDispelTarget(targetList,"Cleanse",dispelTypes,dispelByHp)
	PalaDispelTarget(target)
end

function PalaHealOrDispel(targetList,hpThreshold,dispelTypes,dispelByHp,dispelHpThreshold)
	hpThreshold=hpThreshold or 0.9
	dispelTypes=dispelTypes or palaDispelAll
	dispelByHp=dispelByHp or false
	dispelHpThreshold=dispelHpThreshold or 0.4
	local target,hpOrDebuffType,action=GetHealOrDispelTarget(targetList,"Flash of Light",hpThreshold,"Cleanse",dispelTypes,dispelByHp,dispelHpThreshold)
	if action=="heal" then
		PalaHealTarget(target,hpOrDebuffType)
	else
		PalaDispelTarget(target,hpOrDebuffType)
	end
end

function PalaCC()
	if TryTargetRaidIcon(1,10,true) then
		CastSpellByName("Turn Undead")
	end
end

function PalaBuff(targetList,defaultAura,buffProfile)
	defaultAura=defaultAura or "Retribution Aura"
	local active=0
	for i=1,GetNumShapeshiftForms() do
		_,_,active=GetShapeshiftFormInfo(i)
		if active then
			break
		end
	end
	if not active then
		CastSpellByName(defaultAura)
		return
	end
	if buffProfile then
		if buffProfile~="Custom" then
			if palaBuffProfiles[buffProfile] then
				local spell,buff,classExcl,roleExcl=unpack(palaBuffProfiles[buffProfile])
				for target,info in pairs(targetList) do
					if not classExcl[info.class] and not roleExcl[info.role] and not BuffCheck(target,buff) then
						ClearFriendlyTarget()
						CastSpellByName(spell)
						if IsValidSpellTarget(target)then
							SpellTargetUnit(target)
							return
						end
						SpellStopTargeting()
					end
				end
			end
		else
			for target,info in pairs(targetList) do
				local customBuff=palaBuffCustom[info.name]
				if customBuff then
					local spell,buff=unpack(customBuff)
					if not BuffCheck(target,buff) then
						ClearFriendlyTarget()
						CastSpellByName(spell)
						if IsValidSpellTarget(target) then
							SpellTargetUnit(target)
							return
						end
						SpellStopTargeting()
					end
				end
			end
		end
	end
end

-- Balance Druid

buffMark="Interface\\Icons\\Spell_Nature_Regeneration"
buffThorns="Interface\\Icons\\Spell_Nature_Thorns"
buffMoonkinForm="Interface\\Icons\\Spell_Nature_ForceOfNature"
buffTravelForm="Interface\\Icons\\Ability_Druid_TravelForm"
buffCatForm="Interface\\Icons\\Ability_Druid_CatForm"
buffBearForm="Interface\\Icons\\Ability_Racial_BearForm"
buffAquaticForm="Interface\\Icons\\Ability_Druid_AquaticForm"
buffAbolishPoison="Interface\\Icons\\Spell_Nature_NullifyPoison_02"
spellRemoveCurse="Interface\\Icons\\Spell_Holy_RemoveCurse"

function DruidDps()
	CastSpellByName("Starfire")
end

--function GetForm()
--	for i=1,5 do
--		local _,_,active=GetShapeshiftFormInfo(i)
--		if active then
--			return i
--		end
--	end
--	return 0
--end

function IsMoonkin()
	local _,_,active=GetShapeshiftFormInfo(5)
	if active then
		return true
	end
	return false
end

function DruidBuff(targetList,groupBuff)
	for target,info in pairs(targetList) do
		if info.role=="tank" and not BuffCheck(target,buffThorns) then
			ClearFriendlyTarget()
			CastSpellByName("Thorns")
			if IsValidSpellTarget(target) then
				SpellTargetUnit(target)
				return
			end
			SpellStopTargeting()
		elseif not BuffCheck(target,buffMark) then
			if IsMoonkin() then
				CastShapeshiftForm(5)
				return
			else
				ClearFriendlyTarget()
				if groupBuff then
					CastSpellByName("Gift of the Wild")
				else
					CastSpellByName("Mark of the Wild")
				end
				if IsValidSpellTarget(target) then
					SpellTargetUnit(target)
					return
				end
				SpellStopTargeting()
			end
		end
	end
	if not IsMoonkin() then
		CastShapeshiftForm(5)
	end
end

function DruidCC()
	if TryTargetRaidIcon(4,10,true) then
		CastSpellByName("Hibernate")
	end
end

druidDispelAll={Poison=true,Curse=true}
druidDispelPoison={Poison=true}
druidDispelCurse={Curse=true}

function DruidDispel(targetList)
	local target,debuffType=GetDispelTarget(targetList,"Thorns",druidDispelAll,false)
	if target then
		if debuffType=="Curse" then
			CastSpellByName("Remove Curse")
			SpellTargetUnit(target)
		elseif not BuffCheck(target,buffAbolishPoison) then
			CastSpellByName("Abolish Poison")
			SpellTargetUnit(target)
		end
	end
end

-- SM/Ruin Warlock

buffDemon="Interface\\Icons\\Spell_Shadow_RagingScream"
buffFire="Interface\\Icons\\Spell_Fire_FireArmor"
buffSoulstone="Interface\\Icons\\Spell_Shadow_SoulGem"

function WarlockDps()
	if UnitMana("player")>=380 then
		CastSpellByName("Shadow Bolt")
	else
		CastSpellByName("Life Tap")
	end
	-- TODO: Use wand if Life Tap can not be cast or below a hp threshold.
end

function WarlockBuff(targetList)
	-- Returns are intentionally left out after warlock buff/summon, because the warlock and the minion can cast a spell simultaneously with a single function call.
	if not HasPetUI() then
		if UnitMana("player")>=1098 then
			CastSpellByName("Summon Imp")
		else
			CastSpellByName("Life Tap")
		end
	elseif not BuffCheck("player",buffDemon) then
		if UnitMana("player")>=1580 then
			CastSpellByName("Demon Armor")
		else
			CastSpellByName("Life Tap")
		end
	end
	for target,info in pairs(targetList) do
		if info.role=="tank" and not BuffCheck(target,buffFire) then
			TargetUnit(target)
			CastSpellByName("Fire Shield")
		end
	end
end

function WarlockCC()
	if TryTargetRaidIcon(3,10,true) then
		local unitType=UnitCreatureType("target")
		if UnitMana("player")>=200 and (unitType=="Elemental" or unitType=="Demon") then
			CastSpellByName("Banish")
		elseif UnitMana("player")>=205 then
			CastSpellByName("Fear")
		else
			CastSpellByName("Life Tap")
		end
	end
end

function WarlockDrainSoul()
	if HpLower("target",0.3) then
		if UnitMana("player")>=290 then 
			CastSpellByName("Drain Soul")
		else
			CastSpellByName("Life Tap")
		end
	end
end

-- Frost Mage

spellRemoveLesserCurse="Interface\\Icons\\Spell_Nature_RemoveCurse"

function MageDps()
	CastSpellByName("Frostbolt")
	-- TODO: Evocation, mana gem and wanding.
end

mageDispel={Curse=true}

function MageDispel(targetList)
	local target=GetDispelTarget(targetList,"Remove Lesser Curse",mageDispel,false)
	if target then
		CastSpellByName("Remove Lesser Curse")
		SpellTargetUnit(target)
	end
end

-- Holy Priest

buffAbolishDisease="" -- check
buffRenew="Interface\\Icons\\Spell_Holy_Renew"
spellHeal="Interface\\Icons\\Spell_Holy_Heal02"

function PriestHealTarget(target,hp)
	if target then
		if hp<0.3 and UnitMana("player")>=380 then
			CastSpellByName("Flash Heal")
		elseif hp<0.5 and UnitMana("player")>=215 then
			CastSpellByName("Flash Heal(Rank 4)")
		elseif hp<0.6 and UnitMana("player")>=259 then
			CastSpellByName("Heal(Rank 4)")
		elseif hp<0.7 and UnitMana("player")>=216 then
			CastSpellByName("Heal(Rank 3)")
		elseif hp<0.8 and UnitMana("player")>=174 then
			CastSpellByName("Heal(Rank 2)")
		elseif not BuffCheck(target,buffRenew) then
			CastSpellByName("Renew(Rank 3)")
		else
			CastSpellByName("Heal(Rank 1)")
		end
		SpellTargetUnit(target)
	end
end

function PriestHeal(targetList,hpThreshold)
	hpThreshold=hpThreshold or 0.9
	local target,hp=GetHealTarget(targetList,"Heal",0.9)
	PriestHealTarget(target,hp)
	-- TODO: Aoe heal support
end

priestDispelAll={Magic=true,Disease=true}
priestDispelMagic={Magic=true}
priestDispelDisease={Disease=true}

function PriestDispelTarget(target,debuffType)
	if target then
		if debuffType=="Magic" then
			CastSpellByName("Dispel Magic")
			SpellTargetUnit(target)
		elseif not BuffCheck(target,buffAbolishDisease) then
			CastSpellByName("Abolish Disease")
			SpellTargetUnit(target)
		end
	end
end

function PriestDispel(targetList,dispelTypes,dispelByHp)
	dispelTypes=dispelTypes or priestDispelAll
	dispelByHp=dispelByHp or false
	local target,debuffType=GetDispelTarget(targetList,"Dispel Magic",priestDispelAll,false)
	PriestDispelTarget(target,debuffType)
end

function PriestHealOrDispel(targetList,hpThreshold,dispelTypes,dispelByHp,dispelHpThreshold)
	hpThreshold=hpThreshold or 0.9
	dispelTypes=dispelTypes or priestDispelAll
	dispelByHp=dispelByHp or false
	dispelHpThreshold=dispelHpThreshold or 0.4
	local target,hpOrDebuffType,action=GetHealOrDispelTarget(targetList,"Heal",hpThreshold,"Dispel Magic",dispelTypes,dispelByHp,dispelHpThreshold)
	if action=="heal" then
		PriestHealTarget(target,hpOrDebuffType)
	else
		PriestDispelTarget(target,hpOrDebuffType)
	end
end

-- Protection Warrior

heroicStrikeActionSlot=1
revengeActionSlot=3

function WarriorTankDps()
	local rage=UnitMana("player")
	if rage>=70 and not IsCurrentAction(heroicStrikeActionSlot) then
		CastSpellByName("Heroic Strike")
	elseif rage>=5 and IsUsableAction(revengeActionSlot) then
		CastSpellByName("Revenge")
	elseif rage>=30 then
		CastSpellByName("Shield Slam")
	elseif rage>=12 then
		CastSpellByName("Sunder Armor")
	end
end