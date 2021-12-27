if ryn.playerClass=="DRUID" then
local ryn=ryn

ryn.buffMark="Interface\\Icons\\Spell_Nature_Regeneration"
ryn.buffThorns="Interface\\Icons\\Spell_Nature_Thorns"
ryn.buffAbolishPoison="Interface\\Icons\\Spell_Nature_NullifyPoison_02"
ryn.debuffFaerieFire="Interface\\Icons\\Spell_Nature_FaerieFire"
ryn.buffRegrowth="Interface\\Icons\\Spell_Nature_ResistNature"
ryn.buffRejuvenation="Interface\\Icons\\Spell_Nature_Rejuvenation"
ryn.buffNaturesSwiftness="Interface\\Icons\\Spell_Nature_RavenForm"
--ryn.buffMoonkinForm="Interface\\Icons\\Spell_Nature_ForceOfNature"
--ryn.buffTravelForm="Interface\\Icons\\Ability_Druid_TravelForm"
--ryn.buffCatForm="Interface\\Icons\\Ability_Druid_CatForm"
--ryn.buffBearForm="Interface\\Icons\\Ability_Racial_BearForm"
--ryn.buffAquaticForm="Interface\\Icons\\Ability_Druid_AquaticForm"

ryn.healRange="Healing Touch(Rank 1)"
ryn.dispelRange="Thorns(Rank 1)"

--ryn.faerieFireActionSlot=10
ryn.ClassActionSlotInit=function()
	ryn.faerieFireActionSlot=ryn.GetActionSlot("Faerie Fire")
end

ryn.ClassEventHandler=function()
	if event=="UI_ERROR_MESSAGE" and arg1=="Target not in line of sight" then
		ryn.BlacklistTarget(ryn.currentHealTarget)
		ryn.currentHealTarget=nil
		ryn.precastHpThreshold=nil
	elseif event=="SPELLCAST_START" then
		ryn.currentHealFinish=GetTime()+arg2/1000
		--ryn.Debug("START: "..GetTime())
	elseif event=="SPELLCAST_DELAYED" then
		ryn.currentHealFinish=ryn.currentHealFinish+arg1/1000
	elseif event=="SPELLCAST_STOP" then
		ryn.currentHealTarget=nil
		ryn.currentHealFinish=nil
		ryn.precastHpThreshold=nil
		--ryn.Debug("STOP: "..GetTime())
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

local function RequestHandler()
	local sender,ct=ryn.GetGroupIdByName(ryn.requestSender),GetTime()
	if ct-ryn.requestReceived>=15 then SendChatMessage("Request timeout!","SAY")
	elseif UnitIsDeadOrGhost("player") then SendChatMessage("I'm dead!","SAY")
	elseif not sender then SendChatMessage("Unknown player!","SAY")
	elseif ryn.requestedSpell=="Innervate" then
		local _,class=UnitClass(sender)
		local st,dur=ryn.GetSpellCooldownByName(ryn.requestedSpell)
		if class=="WARRIOR" or class=="ROGUE" then
			SendChatMessage("Bad "..ryn.requestSender.."! No "..ryn.requestedSpell.." for you!","SAY")
		elseif st+dur-ct>=3 then
			SendChatMessage(ryn.requestedSpell.." is on cooldown! ("..math.ceil(st+dur-ct).." s)","SAY")
		else
			if UnitMana("player")<62 then return true end -- wait for mana
			if ryn.GetSpellCooldownByName(ryn.dispelRange)~=0 then return true end
			CastSpellByName(ryn.dispelRange)
			if ryn.IsValidSpellTarget(sender) then
				if ryn.IsMoonkin() then
					SpellStopTargeting()
					CastShapeshiftForm(5)
					return true
				elseif st==0 then
					CastSpellByName("Innervate")
					SpellTargetUnit(sender)
					SendChatMessage(ryn.requestedSpell.." used on "..ryn.requestSender.."!","SAY")
				end
			else
				SendChatMessage("Target is out of range, dead or mind controlled!","SAY")
				SpellStopTargeting()
			end
		end
	else
		SendChatMessage("Unknown/unsupported spell!","SAY")
	end
	ryn.requestedSpell=nil
	ryn.requestSender=nil
	ryn.requestReceived=nil
end

-- ffMode 1: Applies faerie fire on the current dps target
-- ffMode 2: Applies faerie fire on tank targets
ryn.Dps=function(ffMode,autoBoomkin)
	if not ryn.IsCastingOrChanelling() then
		if ryn.requestedSpell then
			if RequestHandler() then return end
		end
		if ffMode==2 and ryn.damageType.nature and ryn.GetSpellCooldownByName("Faerie Fire")==0 then
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
		if not ryn.IsMoonkin() and autoBoomkin then
			CastShapeshiftForm(5)
		elseif ryn.GetHostileTarget() then
			if ffMode==1 and ryn.damageType.nature and not ryn.DebuffCheck("target",ryn.debuffFaerieFire) and IsActionInRange(ryn.faerieFireActionSlot)==1 then
				CastSpellByName("Faerie Fire")
				return
			end
			if ryn.dpsCooldownToggle then
				if ryn.UseTrinkets() then return
				else ryn.dpsCooldownToggle=false end
			end
			if ryn.damageType.arcane then
				CastSpellByName("Starfire")
			elseif ryn.damageType.nature then
				CastSpellByName("Wrath")
			end
		end
	end
end


ryn.healProfiles={
	regular={
		{1   , 0  , "Healing Touch",1,false,true},
		{0.3 , 648, "Nature's Swiftness",1,"tank"},
		{0.3 , 248, "Swiftmend",1,"tank"},
		{0.3 , 800, "Regrowth",1,"tank"},
		{0.4 , 832, "Tranquility",4},
		{0.3 , 248, "Swiftmend",1,"heal"},
		{0.3 , 559, "Regrowth(Rank 7)",1,"heal"},
		{0.25, 648, "Healing Touch"},
		{0.45, 166, "Healing Touch(Rank 4)"},
		{0.65, 327, "Rejuvenation",3},
		{0.9 , 95 , "Rejuvenation(Rank 4)",3},
		{0.9 , 166, "Healing Touch(Rank 4)",2}
	}
}

ryn.AutoInnervate=function(lTargetList,threshold)
	if ryn.SpellCastReady("Innervate") then
		lTargetList=lTargetList or ryn.targetList.heal
		threshold=threshold or 0.1
		for target,_ in lTargetList do
			if ryn.ManaLower(target,threshold) then
				ryn.ClearFriendlyTarget()
				ryn.currentHealTarget=target
				CastSpellByName("Innervate")
				SpellTargetUnit(target)
			end
		end
	end
end

ryn.AoeInfo=function()
	ryn.ClearFriendlyTarget()
	CastSpellByName(ryn.dispelRange)
	local playerCount,playerHps=0,{}
	for target,info in pairs(ryn.targetList.party) do
		local hp=UnitHealth(target)/UnitHealthMax(target)
		if ryn.IsValidSpellTarget(target) then
			playerCount=playerCount+1
			playerHps[playerCount]={uid=target,hpRatio=hp}
		end
	end
	SpellStopTargeting()
	table.sort(playerHps,function(a,b) return a.hpRatio<b.hpRatio end)
	return playerHps
end

ryn.HealTarget=function(healProfile,target,hp,hotTarget,hotHp)
	if ryn.healProfiles[healProfile] then
		local mana,aoeInfo=UnitMana("player"),nil
		for i,healProfileEntry in ipairs(ryn.healProfiles[healProfile]) do
			local hpThreshold,manaCost,spellName,healMode,lTargetList,withCdOnly=unpack(healProfileEntry)
			ryn.currentHealFinish=nil
			if mana>=manaCost and (not withCdOnly or ryn.BuffCheck("player",ryn.buffNaturesSwiftness)) and ryn.GetSpellCooldownByName(spellName)==0 then
				if (not healMode or healMode==1) and target and hp<hpThreshold and (not lTargetList or ryn.targetList[lTargetList][target]) then
					if not strfind(spellName,"Swiftmend",1,1) or ryn.BuffCheck(target,ryn.buffRejuvenation) or ryn.BuffCheck(target,ryn.buffRegrowth) then
						--ryn.Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
						ryn.targetList.all[target].blacklist=nil
						ryn.currentHealTarget=target
						CastSpellByName(spellName)
						SpellTargetUnit(target)
						break
					end
				elseif healMode==2 then
					if ryn.CheckRaidIcon("target",8) or ryn.CheckRaidIcon("target",7) or ryn.TryTargetRaidIcon(8,10,true) or ryn.TryTargetRaidIcon(7,10,true) then
						local precastTarget=ryn.GetGroupId("targettarget")
						if precastTarget then
							CastSpellByName(spellName)
							if ryn.IsValidSpellTarget(precastTarget) then
								--ryn.Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
								ryn.currentHealTarget=precastTarget
								ryn.precastHpThreshold=hpThreshold
								SpellTargetUnit(ryn.currentHealTarget)
								break
							else
								SpellStopTargeting()
							end
						end
					end
				elseif healMode==3 and hotTarget and hotHp<hpThreshold and (not lTargetList or ryn.targetList[lTargetList][hotTarget]) then
					--ryn.Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
					ryn.targetList.all[target].blacklist=nil
					ryn.currentHealTarget=hotTarget
					CastSpellByName(spellName)
					SpellTargetUnit(hotTarget)
					break
				elseif healMode==4 then
					if not aoeInfo then aoeInfo=ryn.AoeInfo() end
					if aoeInfo[ryn.aoeHealMinPlayers] and aoeInfo[ryn.aoeHealMinPlayers].hpRatio<hpThreshold then
						--ryn.Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
						ryn.currentHealTarget=nil
						CastSpellByName(spellName)
						break
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
		local target,hp,hotTarget,hotHp=ryn.GetHealTarget(lTargetList,ryn.healRange,ryn.buffRejuvenation)
		ryn.HealTarget(healProfile,target,hp,hotTarget,hotHp)
	else
		ryn.HealInterrupt()
	end
end

ryn.dispelAll={Poison=true,Curse=true}
ryn.dispelPoison={Poison=true}
ryn.dispelCurse={Curse=true}

ryn.DispelTarget=function(target,debuffType)
	if target then
		ryn.targetList.all[target].blacklist=nil
		ryn.currentHealTarget=target
		ryn.currentHealFinish=nil
		if debuffType=="Curse" then
			CastSpellByName("Remove Curse")
		elseif not ryn.BuffCheck(target,ryn.buffAbolishPoison) then
			CastSpellByName("Abolish Poison")
		else
			CastSpellByName("Cure Poison")
		end
		SpellTargetUnit(target)
	end
end

ryn.Dispel=function(lTargetList,dispelTypes,dispelByHp)
	lTargetList=lTargetList or ryn.targetList.all
	dispelTypes=dispelTypes or ryn.dispelAll
	dispelByHp=dispelByHp or false
	if ryn.SpellCastReady(ryn.dispelRange) then
		local target,debuffType=ryn.GetDispelTarget(lTargetList,ryn.dispelRange,dispelTypes,dispelByHp)
		ryn.DispelTarget(target,debuffType)
	end
end

ryn.HealOrDispel=function(lTargetList,healProfile,dispelTypes,dispelByHp,dispelHpThreshold)
	lTargetList=lTargetList or ryn.targetList.all
	healProfile=healProfile or "regular"
	dispelTypes=dispelTypes or ryn.dispelAll
	dispelByHp=dispelByHp or false
	dispelHpThreshold=dispelHpThreshold or 0.4
	if ryn.SpellCastReady(ryn.healRange,ryn.stopCastingDelayExpire) then
		local target,hpOrDebuffType,hotTarget,hotHp,action=ryn.GetHealOrDispelTarget(lTargetList,ryn.healRange,ryn.buffRejuvenation,ryn.dispelRange,dispelTypes,dispelByHp,dispelHpThreshold)
		if action=="heal" then
			ryn.HealTarget(healProfile,target,hpOrDebuffType,hotTarget,hotHp)
		else
			ryn.DispelTarget(target,hpOrDebuffType)
		end
	else
		ryn.HealInterrupt()
	end
end

end