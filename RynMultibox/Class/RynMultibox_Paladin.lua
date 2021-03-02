local class

if ryn.playerClass=="PALADIN" then
class={}

class.buffMight="Interface\\Icons\\Spell_Holy_FistOfJustice"
class.buffWisdom="Interface\\Icons\\Spell_Holy_SealOfWisdom"
class.buffLight="Interface\\Icons\\Spell_Holy_PrayerOfHealing02"
class.buffSalvation="Interface\\Icons\\Spell_Holy_SealOfSalvation"
class.buffKings="Interface\\Icons\\Spell_Magic_MageArmor"
class.buffGreaterMight="Interface\\Icons\\Spell_Holy_GreaterBlessingofKings"
class.buffGreaterWisdom="Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom"
class.buffGreaterLight="Interface\\Icons\\Spell_Holy_GreaterBlessingofLight"
class.buffGreaterSalvation="Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation"
class.buffGreaterKings="Interface\\Icons\\Spell_Magic_GreaterBlessingofKings"
class.buffDivineFavor="Interface\\Icons\\Spell_Holy_Heal"
--class.buffDevotionAura="Interface\\Icons\\Spell_Holy_DevotionAura"
--class.buffRetributionAura="Interface\\Icons\\Spell_Holy_AuraOfLight"
--class.buffConcentrationAura="Interface\\Icons\\Spell_Holy_MindSooth"
--class.buffShadowAura="Interface\\Icons\\Spell_Shadow_SealOfKings"
--class.buffFrostAura="Interface\\Icons\\Spell_Frost_WizardMark"
--class.buffFireAura="Interface\\Icons\\Spell_Fire_SealOfFire"

class.healRange="Holy Light(Rank 1)"
class.dispelRange="Purify"

class.buffProfiles={
	might={"Blessing of Might",class.buffMight,{PRIEST=true,MAGE=true,WARLOCK=true},{}},
	wisdom={"Blessing of Wisdom",class.buffWisdom,{WARRIOR=true,ROGUE=true},{}},
	salvation={"Blessing of Salvation",class.buffSalvation,{},{tank=true}},
	kings={"Blessing of Kings",class.buffKings,{},{}},
	light={"Blessing of Light",class.buffLight,{},{}},
	greaterMight={"Greater Blessing of Might",class.buffGreaterMight,{PRIEST=true,MAGE=true,WARLOCK=true},{}},
	greaterWisdom={"Greater Blessing of Wisdom",class.buffGreaterWisdom,{WARRIOR=true,ROGUE=true},{}},
	greaterSalvation={"Greater Blessing of Salvation",class.buffGreaterSalvation,{},{tank=true}},
	greaterKings={"Greater Blessing of Kings",class.buffGreaterKings,{},{}},
	greaterLight={"Greater Blessing of Light",class.buffGreaterLight,{},{}}
}
class.buffCustom={
	Harklen={"Blessing of Light",class.buffLight},
	Ryonn={"Blessing of Wisdom",class.buffWisdom},
	Inochi={"Blessing of Wisdom",class.buffWisdom},
	Nymira={"Blessing of Salvation",class.buffSalvation},
	Seloris={"Blessing of Salvation",class.buffSalvation},
	Alaniel={"Blessing of Wisdom",class.buffWisdom},
	Arvene={"Blessing of Wisdom",class.buffSalvation}
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
-- Default: targetList.all

-- withCdOnly:
-- If true, only heal, when a class specific healing cooldown is active: Priest: Inner Focus, Paladin: Divine Favor, Druid: Nature's Swiftness.
-- Default: false

-- HL: 660,580,465,365,275,190,110,60,35
-- FOL: 140,115,90,70,50,35

class.healProfiles={
	regular={
		{0.4 , 720, "Divine Favor"},
		{0.4 , 660, "Holy Light"},
		{0.6 , 140, "Flash of Light"},
		{0.8 , 90 , "Flash of Light(Rank 4)"},
		{0.9 , 50 , "Flash of Light(Rank 2)"},
		{0.9 , 140, "Flash of Light",2}
	},
	hlTankOnly={
		{0.4 , 720, "Divine Favor",1,ryn.targetList.tank},
		{0.4 , 660, "Holy Light",1,ryn.targetList.tank},
		{0.6 , 140, "Flash of Light"},
		{0.8 , 70 , "Flash of Light(Rank 3)"},
		{0.9 , 35 , "Flash of Light(Rank 1)"},
		{0.9 , 140, "Flash of Light",2}
	},
	low={
		{0.4 , 720, "Divine Favor",1,ryn.targetList.tank},
		{0.4 , 660, "Holy Light",1,ryn.targetList.tank,true},
		{0.6 , 70 , "Flash of Light(Rank 5)"},
		{0.8 , 50 , "Flash of Light(Rank 3)"},
		{0.9 , 35 , "Flash of Light(Rank 1)"},
		{0.9 , 35 , "Flash of Light(Rank 1)",2}
	},
	UNLIMITEDPOWER={
		{0.5 , 0  , "Holy Light",1,ryn.targetList.tank},
		{0.3 , 0  , "Holy Light"},
		{0.99, 0  , "Flash of Light"},
		{0.9 , 0  , "Holy Light",2}
	},
	precastTest={
		{0.9 , 35 ,"Holy Light(Rank 1)",2}
	}
}

class.EventHandler=function()
	if event=="UI_ERROR_MESSAGE" and arg1=="Target not in line of sight" then
		ryn.BlacklistTarget(ryn.currentHealTarget)
	elseif event=="SPELLCAST_START" then
		ryn.currentHealFinish=GetTime()+arg2/1000
	elseif event=="SPELLCAST_DELAYED" then
		ryn.currentHealFinish=ryn.currentHealFinish+arg1/1000
	end
end

class.eventFrame=CreateFrame("Frame")
class.eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
class.eventFrame:RegisterEvent("SPELLCAST_START")
class.eventFrame:RegisterEvent("SPELLCAST_DELAYED")
class.eventFrame:SetScript("OnEvent",class.EventHandler)

class.HealTarget=function(healProfile,target,hp)
	if class.healProfiles[healProfile] then
		for i,healProfileEntry in ipairs(class.healProfiles[healProfile]) do
			local hpThreshold,manaCost,spellName,healMode,lTargetList,withCdOnly=unpack(healProfileEntry)
			local mana=UnitMana("player")
			ryn.currentHealFinish=nil
			if mana>=manaCost and (not withCdOnly or ryn.BuffCheck("player",class.buffDivineFavor)) and ryn.GetSpellCooldownByName(spellName)==0 then
				if (not healMode or healMode==1) and target and hp<hpThreshold and (not lTargetList or lTargetList[target]) then
					--ryn.Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
					ryn.targetList.all[target].blacklist=nil
					ryn.currentHealTarget=target
					CastSpellByName(spellName)
					SpellTargetUnit(target)
					break
				elseif healMode==2 then
					if ryn.CheckRaidIcon("target",8) or ryn.CheckRaidIcon("target",7) or ryn.TryTargetRaidIcon(8,10,true) or ryn.TryTargetRaidIcon(7,10,true) then
						if UnitExists("targettarget") and UnitIsFriend("player","targettarget") then
							--ryn.Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
							ryn.currentHealTarget=ryn.GetGroupId("targettarget") or "targettarget"
							ryn.precastHpThreshold=hpThreshold
							CastSpellByName(spellName)
							SpellTargetUnit(ryn.currentHealTarget)
						end
					end
					break
				end
			end
		end
	end
end

class.DispelTarget=function(target)
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
		if buffProfile~="Custom" then
			if class.buffProfiles[buffProfile] then
				local spell,buff,classExcl,roleExcl=unpack(class.buffProfiles[buffProfile])
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
				local customBuff=class.buffCustom[info.name]
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
	if ryn.SpellCastReady(class.healRange,ryn.stopCastingDelayExpire) then
		local target,hp=ryn.GetHealTarget(lTargetList,class.healRange)
		class.HealTarget(healProfile,target,hp)
	else
		ryn.HealInterrupt(ryn.currentHealTarget,ryn.currentHealFinish,ryn.precastHpThreshold)
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
	if ryn.SpellCastReady(class.dispelRange) then
		local target=ryn.GetDispelTarget(lTargetList,class.dispelRange,dispelTypes,dispelByHp)
		class.DispelTarget(target)
	end
end

ryn.HealOrDispel=function(lTargetList,healProfile,dispelTypes,dispelByHp,dispelHpThreshold)
	lTargetList=lTargetList or ryn.targetList.all
	healProfile=healProfile or "regular"
	dispelTypes=dispelTypes or ryn.dispelAll
	dispelByHp=dispelByHp or false
	dispelHpThreshold=dispelHpThreshold or 0.4
	if ryn.SpellCastReady(class.healRange,ryn.stopCastingDelayExpire) then
		local target,hpOrDebuffType,_,_,action=ryn.GetHealOrDispelTarget(lTargetList,class.healRange,nil,class.dispelRange,dispelTypes,dispelByHp,dispelHpThreshold)
		if action=="heal" then
			class.HealTarget(healProfile,target,hpOrDebuffType)
		else
			class.DispelTarget(target)
		end
	else
		ryn.HealInterrupt(ryn.currentHealTarget,ryn.currentHealFinish,ryn.precastHpThreshold)
	end
end

ryn.CC=function()
	if ryn.TryTargetRaidIcon(1,10,true) then
		CastSpellByName("Turn Undead")
	end
end

end