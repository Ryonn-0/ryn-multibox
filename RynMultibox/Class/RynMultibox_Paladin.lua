if ryn.playerClass=="PALADIN" then

ryn.buffMight="Interface\\Icons\\Spell_Holy_FistOfJustice"
ryn.buffWisdom="Interface\\Icons\\Spell_Holy_SealOfWisdom"
ryn.buffLight="Interface\\Icons\\Spell_Holy_PrayerOfHealing02"
ryn.buffSalvation="Interface\\Icons\\Spell_Holy_SealOfSalvation"
ryn.buffKings="Interface\\Icons\\Spell_Magic_MageArmor"
ryn.buffSanctuary="Interface\\Icons\\Spell_Nature_LightningShield"
ryn.buffGreaterMight="Interface\\Icons\\Spell_Holy_GreaterBlessingofKings"
ryn.buffGreaterWisdom="Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom"
ryn.buffGreaterLight="Interface\\Icons\\Spell_Holy_GreaterBlessingofLight"
ryn.buffGreaterSalvation="Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation"
ryn.buffGreaterKings="Interface\\Icons\\Spell_Magic_GreaterBlessingofKings"
ryn.buffGreaterSanctuary="Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary"
ryn.buffDivineFavor="Interface\\Icons\\Spell_Holy_Heal"
--ryn.buffDevotionAura="Interface\\Icons\\Spell_Holy_DevotionAura"
--ryn.buffRetributionAura="Interface\\Icons\\Spell_Holy_AuraOfLight"
--ryn.buffConcentrationAura="Interface\\Icons\\Spell_Holy_MindSooth"
--ryn.buffShadowAura="Interface\\Icons\\Spell_Shadow_SealOfKings"
--ryn.buffFrostAura="Interface\\Icons\\Spell_Frost_WizardMark"
--ryn.buffFireAura="Interface\\Icons\\Spell_Fire_SealOfFire"

ryn.healRange="Holy Light(Rank 1)"
ryn.dispelRange="Purify"

ryn.buffProfiles={
	might={"Blessing of Might",ryn.buffMight,{PRIEST=true,MAGE=true,WARLOCK=true},{}},
	wisdom={"Blessing of Wisdom",ryn.buffWisdom,{WARRIOR=true,ROGUE=true},{}},
	salvation={"Blessing of Salvation",ryn.buffSalvation,{},{tank=true}},
	kings={"Blessing of Kings",ryn.buffKings,{},{}},
	light={"Blessing of Light",ryn.buffLight,{},{}},
	greaterMight={"Greater Blessing of Might",ryn.buffGreaterMight,{PRIEST=true,MAGE=true,WARLOCK=true},{}},
	greaterWisdom={"Greater Blessing of Wisdom",ryn.buffGreaterWisdom,{WARRIOR=true,ROGUE=true},{}},
	greaterSalvation={"Greater Blessing of Salvation",ryn.buffGreaterSalvation,{},{tank=true}},
	greaterKings={"Greater Blessing of Kings",ryn.buffGreaterKings,{},{}},
	greaterLight={"Greater Blessing of Light",ryn.buffGreaterLight,{},{}}
}
ryn.buffCustom={
	Harklen={"Greater Blessing of Sanctuary",ryn.buffGreaterSanctuary},
	Ryonn={"Greater Blessing of Wisdom",ryn.buffGreaterWisdom},
	Inochi={"Greater Blessing of Wisdom",ryn.buffGreaterWisdom},
	Nymira={"Greater Blessing of Salvation",ryn.buffGreaterSalvation},
	Seloris={"Greater Blessing of Salvation",ryn.buffGreaterSalvation},
	Alaniel={"Greater Blessing of Wisdom",ryn.buffGreaterWisdom},
	Arvene={"Greater Blessing of Salvation",ryn.buffGreaterSalvation}
}

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
-- Default: "all"

-- withCdOnly:
-- If true, only heal, when a class specific healing cooldown is active: Priest: Inner Focus, Paladin: Divine Favor, Druid: Nature's Swiftness.
-- Default: false

-- HL: 660,580,465,365,275,190,110,60,35
-- FOL: 140,115,90,70,50,35

ryn.healProfiles={
	regular={
		{0.4 , 720, "Divine Favor"},
		{0.4 , 660, "Holy Light"},
		{0.6 , 140, "Flash of Light"},
		{0.8 , 90 , "Flash of Light(Rank 4)"},
		{0.9 , 50 , "Flash of Light(Rank 2)"},
		{0.9 , 140, "Flash of Light",2}
	},
	hlTankOnly={
		{0.45, 720, "Divine Favor",1,"tank"},
		{0.45, 660, "Holy Light",1,"tank"},
		{0.6 , 140, "Flash of Light"},
		{0.8 , 70 , "Flash of Light(Rank 3)"},
		{0.9 , 35 , "Flash of Light(Rank 1)"},
		{0.9 , 140, "Flash of Light",2}
	},
	low={
		{0.4 , 720, "Divine Favor",1,"tank"},
		{0.4 , 660, "Holy Light",1,"tank",true},
		{0.6 , 70 , "Flash of Light(Rank 5)"},
		{0.8 , 50 , "Flash of Light(Rank 3)"},
		{0.9 , 35 , "Flash of Light(Rank 1)"},
		{0.9 , 35 , "Flash of Light(Rank 1)",2}
	},
	UNLIMITEDPOWER={
		{0.5 , 0  , "Holy Light",1,"tank"},
		{0.3 , 0  , "Holy Light"},
		{0.9 , 0  , "Flash of Light"},
		{0.9 , 0  , "Holy Light",2}
	}
}

ryn.ClassEventHandler=function()
	if event=="UI_ERROR_MESSAGE" and arg1=="Target not in line of sight" then
		ryn.BlacklistTarget(ryn.currentHealTarget)
		ryn.currentHealTarget=nil
		ryn.precastHpThreshold=nil
	elseif event=="SPELLCAST_START" then
		ryn.currentHealFinish=GetTime()+arg2/1000
	elseif event=="SPELLCAST_DELAYED" then
		ryn.currentHealFinish=ryn.currentHealFinish+arg1/1000
	elseif event=="SPELLCAST_STOP" then
		ryn.currentHealTarget=nil
		ryn.currentHealFinish=nil
		ryn.precastHpThreshold=nil
	end
end

ryn.classEventFrame=CreateFrame("Frame")
ryn.classEventFrame:RegisterEvent("UI_ERROR_MESSAGE")
ryn.classEventFrame:RegisterEvent("SPELLCAST_START")
ryn.classEventFrame:RegisterEvent("SPELLCAST_DELAYED")
ryn.classEventFrame:RegisterEvent("SPELLCAST_STOP")
ryn.classEventFrame:SetScript("OnEvent",ryn.ClassEventHandler)

ryn.HealTarget=function(healProfile,target,hp)
	if ryn.healProfiles[healProfile] then
		local mana=UnitMana("player")
		for i,healProfileEntry in ipairs(ryn.healProfiles[healProfile]) do
			local hpThreshold,manaCost,spellName,healMode,lTargetList,withCdOnly=unpack(healProfileEntry)
			ryn.currentHealFinish=nil
			if mana>=manaCost and (not withCdOnly or ryn.BuffCheck("player",ryn.buffDivineFavor)) and ryn.GetSpellCooldownByName(spellName)==0 then
				if (not healMode or healMode==1) and target and hp<hpThreshold and (not lTargetList or ryn.targetList[lTargetList][target]) then
					--ryn.Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
					ryn.targetList.all[target].blacklist=nil
					ryn.currentHealTarget=target
					CastSpellByName(spellName)
					SpellTargetUnit(target)
					break
				elseif healMode==2 then
					if ryn.CheckRaidIcon("target",8) or ryn.CheckRaidIcon("target",7) or ryn.TryTargetRaidIcon(8,10,true) or ryn.TryTargetRaidIcon(7,10,true) then
						local precastTarget=ryn.GetGroupId("targettarget")
						if precastTarget then
							--ryn.Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
							CastSpellByName(spellName)
							if ryn.IsValidSpellTarget(precastTarget) then
								ryn.currentHealTarget=precastTarget
								ryn.precastHpThreshold=hpThreshold
								SpellTargetUnit(ryn.currentHealTarget)
								break
							else
								SpellStopTargeting()
							end
						end
					end
				end
			end
		end
	end
end

ryn.DispelTarget=function(target)
	if target then
		ryn.targetList.all[target].blacklist=nil
		ryn.currentHealTarget=target
		ryn.currentHealFinish=nil
		CastSpellByName("Cleanse")
		SpellTargetUnit(target)
	end
end

ryn.Buff=function(lTargetList,defaultAura,buffProfile)
	lTargetList=lTargetList or ryn.targetList.all
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
		if buffProfile~="custom" then
			if ryn.buffProfiles[buffProfile] then
				local spell,buff,classExcl,roleExcl=unpack(ryn.buffProfiles[buffProfile])
				for target,info in pairs(lTargetList) do
					if not classExcl[info.class] and not roleExcl[info.role] and not ryn.BuffCheck(target,buff) then
						ryn.ClearFriendlyTarget()
						CastSpellByName(spell)
						if ryn.IsValidSpellTarget(target) then
							SpellTargetUnit(target)
							return
						end
						SpellStopTargeting()
					end
				end
			end
		else
			for target,info in pairs(lTargetList) do
				local customBuff=ryn.buffCustom[info.name]
				if customBuff then
					local spell,buff=unpack(customBuff)
					if not ryn.BuffCheck(target,buff) then
						ryn.ClearFriendlyTarget()
						CastSpellByName(spell)
						if ryn.IsValidSpellTarget(target) then
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

ryn.Heal=function(lTargetList,healProfile)
	lTargetList=lTargetList or ryn.targetList.all
	healProfile=healProfile or "regular"
	if ryn.SpellCastReady(ryn.healRange,ryn.stopCastingDelayExpire) then
		local target,hp=ryn.GetHealTarget(lTargetList,ryn.healRange)
		ryn.HealTarget(healProfile,target,hp)
	else
		ryn.HealInterrupt()
	end
end

ryn.dispelAll={Magic=true,Disease=true,Poison=true}
ryn.dispelMagic={Magic=true}
ryn.dispelDisease={Disease=true}
ryn.dispelPoison={Poison=true}
ryn.dispelNoMagic={Disease=true,Poison=true}
ryn.dispelNoDisease={Magic=true,Poison=true}
ryn.dispelNoPoison={Magic=true,Disease=true}

ryn.Dispel=function(lTargetList,dispelTypes,dispelByHp)
	lTargetList=lTargetList or ryn.targetList.all
	dispelTypes=dispelTypes or ryn.dispelAll
	dispelByHp=dispelByHp or false
	if ryn.SpellCastReady(ryn.dispelRange) then
		local target=ryn.GetDispelTarget(lTargetList,ryn.dispelRange,dispelTypes,dispelByHp)
		ryn.DispelTarget(target)
	end
end

ryn.HealOrDispel=function(lTargetList,healProfile,dispelTypes,dispelByHp,dispelHpThreshold)
	lTargetList=lTargetList or ryn.targetList.all
	healProfile=healProfile or "regular"
	dispelTypes=dispelTypes or ryn.dispelAll
	dispelByHp=dispelByHp or false
	dispelHpThreshold=dispelHpThreshold or 0.4
	if ryn.SpellCastReady(ryn.healRange,ryn.stopCastingDelayExpire) then
		local target,hpOrDebuffType,_,_,action=ryn.GetHealOrDispelTarget(lTargetList,ryn.healRange,nil,ryn.dispelRange,dispelTypes,dispelByHp,dispelHpThreshold)
		if action=="heal" then
			ryn.HealTarget(healProfile,target,hpOrDebuffType)
		else
			ryn.DispelTarget(target)
		end
	else
		ryn.HealInterrupt()
	end
end

ryn.CC=function()
	if ryn.TryTargetRaidIcon(1,10,true) then
		CastSpellByName("Turn Undead")
	end
end

end