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
buffDivineFavor="Interface\\Icons\\Spell_Holy_Heal"
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
	Nymira={"Blessing of Salvation",buffSalvation},
	Seloris={"Blessing of Salvation",buffSalvation},
	Alaniel={"Blessing of Wisdom",buffWisdom},
	Arvene={"Blessing of Wisdom",buffWisdom}
}
palaHealRange="Holy Light(Rank 1)"
palaDispelRange="Purify"

function InitHealProfiles()
	-- NOTE: Do NOT use nil if you want to omit a heal profile entry parameter, use false instead.
	
	-- Heal profile entry format:
	-- {hpThreshold, manaCost, spellName, healMode, targetList, withCdOnly}
	-- The first three parameters are mandatory
	
	-- hpThreshold:
	-- Heal when the target is below this hp ratio.
	-- In precast heal mode: Interrupt the heal, if the target won't fall below this value shortly before the spellcast finishes.
	
	-- healMode:
	-- 1: Direct - Heals the target with the lowest health
	-- 2: Precast - Heals the enemy target's target
	-- 3: HoT - Heals the target with the lowest health that doesn't have the HoT effect (Priest Renew and Druid Rejuvenation)
	-- 4: AoE - Heals, when the third lowest health target in the party is below the hpThreshold.
	-- Default: Direct
	
	-- targetList:
	-- Only heal, when the selected heal target is in this target list. Only Direct and HoT heal modes check this.
	-- Default: targetList.all
	
	-- withCdOnly:
	-- If true, only heal, when a class specific healing cooldown is active: Priest: Inner Focus, Paladin: Divine Favor, Druid: Nature's Swiftness.
	-- Default: false
	
	-- HL: 660,580,465,365,275,190,110,60,35
	-- FOL: 140,115,90,70,50,35
	palaHealProfiles={
		regular={
			{0.4 , 720, "Divine Favor"},
			{0.4 , 660, "Holy Light"},
			{0.6 , 140, "Flash of Light"},
			{0.8 , 90 , "Flash of Light(Rank 4)"},
			{0.9 , 50 , "Flash of Light(Rank 2)"},
			{0.9 , 140, "Flash of Light",2}
		},
		hlTankOnly={
			{0.4 , 720, "Divine Favor",1,targetList.tank},
			{0.4 , 660, "Holy Light",1,targetList.tank},
			{0.6 , 140, "Flash of Light"},
			{0.8 , 70 , "Flash of Light(Rank 3)"},
			{0.9 , 35 , "Flash of Light(Rank 1)"},
			{0.9 , 140, "Flash of Light",2}
		},
		low={
			{0.4 , 720, "Divine Favor",1,targetList.tank},
			{0.4 , 660, "Holy Light",1,targetList.tank,true},
			{0.6 , 70 , "Flash of Light(Rank 5)"},
			{0.8 , 50 , "Flash of Light(Rank 3)"},
			{0.9 , 35 , "Flash of Light(Rank 1)"},
			{0.9 , 35 , "Flash of Light(Rank 1)",2}
		},
		UNLIMITEDPOWER={
			{0.5 , 0  , "Holy Light",1,targetList.tank},
			{0.3 , 0  , "Holy Light"},
			{0.99, 0  , "Flash of Light"},
			{0.9 , 0  , "Holy Light",2}
		},
		precastTest={
			{0.9 , 35 ,"Holy Light(Rank 1)",2}
		}
	}

	priestHealProfiles={
		regular={
			{0.4 , 380, "Flash Heal",1,targetList.tank},
			{0.5 , 0  , "Inner Focus",4},
			{0.5 , 0  , "Prayer of Healing",4,targetList.party,true},
			{0.8 , 410, "Prayer of Healing(Rank 1)",4},
			{0.3 , 380, "Flash Heal"},
			{0.5 , 215, "Flash Heal(Rank 4)"},
			{0.6 , 259, "Heal(Rank 4)"},
			{0.7 , 216, "Heal(Rank 3)"},
			{0.8 , 174, "Heal(Rank 2)"},
			{0.9 , 94 , "Renew(Rank 3)",3},
			{0.9 , 131, "Heal(Rank 1)"},
			{0.9 , 259, "Heal",2}
		},
		renewSpam={
			{0.5 , 380, "Flash Heal",1,targetList.tank},
			{0.5 , 0  , "Inner Focus",4},
			{0.5 , 0  , "Prayer of Healing",4,false,true},
			{0.8 , 410, "Prayer of Healing(Rank 1)",4},
			{0.4 , 259, "Heal"},
			{0.6 , 184, "Renew(Rank 6)",3},
			{0.9 , 94 , "Renew(Rank 3)",3},
			{0.9 , 131, "Heal(Rank 1)"},
			{0.9 , 259, "Heal",2}
		},
		pureRenewSpam={
			{0.6 , 184, "Renew(Rank 6)",3},
			{0.9 , 94 , "Renew(Rank 3)",3}
		},
		UNLIMITEDPOWER={
			{0.9 , 0  , "Prayer of Healing",4},
			{0.99, 0  , "Flash Heal"},
			{0.9 , 0  , "Greater Heal",2}
		},
		precastTest={
			{0.9 , 131, "Heal(Rank 1)",2}
		}
	}
end

function PalaHealTarget(healProfile,target,hp)
	if palaHealProfiles[healProfile] then
		for i,healProfileEntry in ipairs(palaHealProfiles[healProfile]) do
			local hpThreshold,manaCost,spellName,healMode,pTargetList,withCdOnly=unpack(healProfileEntry)
			local mana=UnitMana("player")
			if mana>=manaCost and (not withCdOnly or BuffCheck("player",buffDivineFavor)) and GetSpellCooldownByName(spellName)==0 then
				if (not healMode or healMode==1) and target and hp<hpThreshold and (not pTargetList or pTargetList[target]) then
					--Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
					targetList.all[target].blacklist=nil
					currentHealTarget=target
					CastSpellByName(spellName)
					SpellTargetUnit(target)
					break
				elseif healMode==2 then
					if CheckRaidIcon("target",8) or CheckRaidIcon("target",7) or TryTargetRaidIcon(8,10,true) or TryTargetRaidIcon(7,10,true) then
						if UnitExists("targettarget") and UnitIsFriend("player","targettarget") then
							--Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
							currentHealTarget=GetGroupId("targettarget") or "targettarget"
							currentHealFinish=GetTime()+(GetSpellCastTimeByName(spellName) or 1.5)
							precastHpThreshold=hpThreshold
							CastSpellByName(spellName)
							SpellTargetUnit(currentHealTarget)
						end
					end
					break
				end
			end
		end
	end
end

function PalaHeal(targetList,healProfile)
	healProfile=healProfile or "regular"
	if SpellCastReady(palaHealRange,stopCastingDelayExpire) then
		local target,hp=GetHealTarget(targetList,palaHealRange)
		PalaHealTarget(healProfile,target,hp)
	else
		HealInterrupt(currentHealTarget,currentHealFinish,precastHpThreshold)
	end
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
		targetList.all[target].blacklist=nil
		currentHealTarget=target
		CastSpellByName("Cleanse")
		SpellTargetUnit(target)
	end
end

function PalaDispel(targetList,dispelTypes,dispelByHp)
	dispelTypes=dispelTypes or palaDispelAll
	dispelByHp=dispelByHp or false
	if SpellCastReady(palaDispelRange) then
		local target=GetDispelTarget(targetList,palaDispelRange,dispelTypes,dispelByHp)
		PalaDispelTarget(target)
	end
end

function PalaHealOrDispel(targetList,healProfile,dispelTypes,dispelByHp,dispelHpThreshold)
	healProfile=healProfile or "regular"
	dispelTypes=dispelTypes or palaDispelAll
	dispelByHp=dispelByHp or false
	dispelHpThreshold=dispelHpThreshold or 0.4
	if SpellCastReady(palaHealRange,stopCastingDelayExpire) then
		local target,hpOrDebuffType,_,_,action=GetHealOrDispelTarget(targetList,palaHealRange,nil,palaDispelRange,dispelTypes,dispelByHp,dispelHpThreshold)
		if action=="heal" then
			PalaHealTarget(healProfile,target,hpOrDebuffType)
		else
			PalaDispelTarget(target,hpOrDebuffType)
		end
	else
		HealInterrupt(currentHealTarget,currentHealFinish,precastHpThreshold)
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

druidDispelRange="Thorns"

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

function DruidDispel(targetList,moonkinSwap)
	moonkinSwap=moonkinSwap or false
	if SpellCastReady(druidDispelRange,false) then
		local target,debuffType=GetDispelTarget(targetList,druidDispelRange,druidDispelAll,false)
		if target then
			if moonkinSwap and IsMoonkin() then
				CastShapeshiftForm(5)
				return
			end
			targetList.all[target].blacklist=nil
			currentHealTarget=target
			if debuffType=="Curse" then
				CastSpellByName("Remove Curse")
			elseif not BuffCheck(target,buffAbolishPoison) then
				CastSpellByName("Abolish Poison")
			else
				CastSpellByName("Cure Poison")
			end
			SpellTargetUnit(target)
		elseif moonkinSwap and not IsMoonkin() then
			CastShapeshiftForm(5)
		end
	end
end

-- SM/Ruin Warlock

buffDemon="Interface\\Icons\\Spell_Shadow_RagingScream"
buffFire="Interface\\Icons\\Spell_Fire_FireArmor"
buffSoulstone="Interface\\Icons\\Spell_Shadow_SoulGem"

function WarlockDps()
	if not IsCastingOrChanelling() then
		if UnitMana("player")>=372 then
		--if UnitMana("player")>=2000 then
			CastSpellByName("Shadow Bolt")
		else
			CastSpellByName("Life Tap")
		end
	end
	-- TODO: Apply curse, use wand if Life Tap can not be cast or below a hp threshold.
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
	if not IsCastingOrChanelling() and TryTargetRaidIcon(2,10,true) then
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
	if not IsCastingOrChanelling() then
		if HpLower("target",0.3) then
			if UnitMana("player")>=290 then
				CastSpellByName("Drain Soul")
			else
				CastSpellByName("Life Tap")
			end
		else
			WarlockDps()
		end
	end
end

function WarlockDrainMana()
	CastSpellByName("Drain Mana")
end

-- Frost Mage

spellRemoveLesserCurse="Interface\\Icons\\Spell_Nature_RemoveCurse"

mageDispelRange="Remove Lesser Curse"

function MageDps()
	if not IsCastingOrChanelling() then
		CastSpellByName("Frostbolt")
		--CastSpellByName("Fireball")
	end
	-- TODO: Evocation, mana gem and wanding.
end

mageDispel={Curse=true}

function MageDispel(targetList)
	if SpellCastReady(mageDispelRange,false) then
		local target=GetDispelTarget(targetList,mageDispelRange,mageDispel,false)
		if target then
			targetList.all[target].blacklist=nil
			currentHealTarget=target
			CastSpellByName("Remove Lesser Curse")
			SpellTargetUnit(target)
		end
	end
end

function MageCC()
	if TryTargetRaidIcon(3,10,true) then
		local unitType=UnitCreatureType("target")
		if UnitMana("player")>=150 and (unitType=="Humanoid" or unitType=="Beast") then
			CastSpellByName("Polymorph")
		end
	end
end

-- Holy Priest

buffAbolishDisease="Interface\\Icons\\Spell_Nature_NullifyDisease"
buffRenew="Interface\\Icons\\Spell_Holy_Renew"
buffInnerFocus="Interface\\Icons\\Spell_Frost_WindWalkOn"
spellHeal="Interface\\Icons\\Spell_Holy_Heal02"

priestHealRange="Lesser Heal(Rank 1)"
priestDispelRange="Cure Disease"
aoeHealMinPlayers=3

function PriestHealTarget(healProfile,target,hp,hotTarget,hotHp,aoeInfo)
	if priestHealProfiles[healProfile] then
		for i,healProfileEntry in ipairs(priestHealProfiles[healProfile]) do
			local hpThreshold,manaCost,spellName,healMode,lTargetList,withCdOnly=unpack(healProfileEntry)
			local mana=UnitMana("player")
			if mana>=manaCost and (not withCdOnly or BuffCheck("player",buffInnerFocus)) and GetSpellCooldownByName(spellName)==0 then
				if (not healMode or healMode==1) and target and hp<hpThreshold and (not lTargetList or lTargetList[target]) then
					--Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
					targetList.all[target].blacklist=nil
					currentHealTarget=target
					CastSpellByName(spellName)
					SpellTargetUnit(target)
					break
				elseif healMode==2 then
					if CheckRaidIcon("target",8) or CheckRaidIcon("target",7) or TryTargetRaidIcon(8,10,true) or TryTargetRaidIcon(7,10,true) then
						if UnitExists("targettarget") and UnitIsFriend("player","targettarget") then
							--Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
							currentHealTarget=GetGroupId("targettarget") or "targettarget"
							currentHealFinish=GetTime()+(GetSpellCastTimeByName(spellName) or 1.5)
							precastHpThreshold=hpThreshold
							CastSpellByName(spellName)
							SpellTargetUnit(currentHealTarget)
						end
					end
					break
				elseif healMode==3 and hotTarget and hotHp<hpThreshold and (not lTargetList or lTargetList[hotTarget]) then
					--Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
					targetList.all[target].blacklist=nil
					currentHealTarget=hotTarget
					CastSpellByName(spellName)
					SpellTargetUnit(hotTarget)
					break
				elseif healMode==4 and aoeInfo[aoeHealMinPlayers] and aoeInfo[aoeHealMinPlayers].hpRatio<hpThreshold then
					--Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
					currentHealTarget=nil
					CastSpellByName(spellName)
					break
				end
			end
		end
	end
end

function PriestHeal(targetList,healProfile)
	healProfile=healProfile or "regular"
	if SpellCastReady(priestHealRange,stopCastingDelayExpire) then
		local target,hp,hotTarget,hotHp=GetHealTarget(targetList,priestHealRange,buffRenew)
		local aoeInfo=PriestAoeInfo()
		PriestHealTarget(healProfile,target,hp,hotTarget,hotHp,aoeInfo)
	else
		HealInterrupt(currentHealTarget,currentHealFinish,precastHpThreshold)
	end
end

function PriestAoeInfo()
	ClearFriendlyTarget()
	CastSpellByName("Cure Disease")
	local playerCount,playerHps=0,{}
	for target,info in pairs(targetList.party) do
		local hp=UnitHealth(target)/UnitHealthMax(target)
		if IsValidSpellTarget(target) then
			playerCount=playerCount+1
			playerHps[playerCount]={uid=target,hpRatio=hp}
		end
	end
	SpellStopTargeting()
	table.sort(playerHps,function(a,b) return a.hpRatio<b.hpRatio end)
	return playerHps
end

priestDispelAll={Magic=true,Disease=true}
priestDispelMagic={Magic=true}
priestDispelDisease={Disease=true}

function PriestDispelTarget(target,debuffType)
	if target then
		targetList.all[target].blacklist=nil
		currentHealTarget=target
		if debuffType=="Magic" then
			ClearTarget()
			CastSpellByName("Dispel Magic")
		elseif not BuffCheck(target,buffAbolishDisease) then
			CastSpellByName("Abolish Disease")
		else
			CastSpellByName("Cure Disease")
		end
		SpellTargetUnit(target)
	end
end

function PriestDispel(targetList,dispelTypes,dispelByHp)
	dispelTypes=dispelTypes or priestDispelAll
	dispelByHp=dispelByHp or false
	if SpellCastReady(priestDispelRange) then
		local target,debuffType=GetDispelTarget(targetList,priestDispelRange,priestDispelAll,false)
		PriestDispelTarget(target,debuffType)
	end
end

function PriestHealOrDispel(targetList,healProfile,dispelTypes,dispelByHp,dispelHpThreshold)
	healProfile=healProfile or "regular"
	dispelTypes=dispelTypes or priestDispelAll
	dispelByHp=dispelByHp or false
	dispelHpThreshold=dispelHpThreshold or 0.4
	if SpellCastReady(priestHealRange,stopCastingDelayExpire) then
		local target,hpOrDebuffType,hotTarget,hotHp,action=GetHealOrDispelTarget(targetList,priestHealRange,buffRenew,priestDispelRange,dispelTypes,dispelByHp,dispelHpThreshold)
		if action=="heal" then
			local aoeInfo=PriestAoeInfo()
			PriestHealTarget(healProfile,target,hpOrDebuffType,hotTarget,hotHp,aoeInfo)
		else
			PriestDispelTarget(target,hpOrDebuffType)
		end
	else
		HealInterrupt(currentHealTarget,currentHealFinish,precastHpThreshold)
	end
end

-- Protection Warrior

heroicStrikeActionSlot=1
revengeActionSlot=3

function WarriorTankDps()
	local rage=UnitMana("player")
	if rage>=60 and not IsCurrentAction(heroicStrikeActionSlot) then
		CastSpellByName("Heroic Strike")
	elseif rage>=5 and IsUsableAction(revengeActionSlot) then
		CastSpellByName("Revenge")
	elseif rage>=20 then
		CastSpellByName("Shield Slam")
	elseif rage>=12 then
		CastSpellByName("Sunder Armor")
	end
end