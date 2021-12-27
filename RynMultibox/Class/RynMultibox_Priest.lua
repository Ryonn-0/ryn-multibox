if ryn.playerClass=="PRIEST" then
local ryn=ryn

ryn.buffAbolishDisease="Interface\\Icons\\Spell_Nature_NullifyDisease"
ryn.buffRenew="Interface\\Icons\\Spell_Holy_Renew"
ryn.buffInnerFocus="Interface\\Icons\\Spell_Frost_WindWalkOn"
ryn.debuffWeakenedSoul="Interface\\Icons\\Spell_Holy_AshesToAshes"

ryn.healRange="Lesser Heal(Rank 1)"
ryn.dispelRange="Cure Disease"
ryn.aoeHealMinPlayers=3

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
ryn.classEventFrame:RegisterEvent("SPELLCAST_START")
ryn.classEventFrame:RegisterEvent("SPELLCAST_DELAYED")
ryn.classEventFrame:RegisterEvent("SPELLCAST_STOP")
ryn.classEventFrame:SetScript("OnEvent",ryn.ClassEventHandler)

ryn.healProfiles={
	regular={
		{1   , 0  , "Prayer of Healing",4,false,true},
		{0.5 , 380, "Flash Heal",1,"tank"},
		{0.5 , 0  , "Inner Focus",4},
		{0.3 , 380, "Flash Heal"},
		{0.5 , 215, "Flash Heal(Rank 4)"},
		{0.8 , 410, "Prayer of Healing(Rank 1)",4},
		{0.6 , 259, "Heal(Rank 4)"},
		{0.7 , 216, "Heal(Rank 3)"},
		{0.8 , 174, "Heal(Rank 2)"},
		{0.9 , 94 , "Renew(Rank 3)",3},
		{0.9 , 131, "Heal(Rank 1)"},
		{0.9 , 259, "Heal",2}
	},
	renewSpam={
		{1   , 0  , "Prayer of Healing",4,false,true},
		{0.4 , 184, "Power Word: Shield",1,"tank"}, --0.6
		{0.7 , 380, "Flash Heal",1,"tank"}, --0.5
		{0.5 , 0  , "Inner Focus",4},
		{0.65, 259, "Heal",1,"tank"},
		{0.3 , 380, "Flash Heal"},
		{0.45, 259, "Heal"},
		{0.8 , 410, "Prayer of Healing(Rank 1)",4},
		{0.6 , 184, "Renew(Rank 6)",3},
		{0.9 , 94 , "Renew(Rank 3)",3},
		{0.9 , 131, "Heal(Rank 1)"},
		{0.9 , 259, "Heal",2}
	},
	instantOnly={
		{0.6 , 184, "Power Word: Shield",1,"tank"},
		{0.3 , 184, "Power Word: Shield"},
		{0.6 , 184, "Renew(Rank 6)",3},
		{0.9 , 94 , "Renew(Rank 3)",3}
	},
	UNLIMITEDPOWER={
		{0.9 , 0  , "Prayer of Healing",4},
		{0.9 , 0  , "Flash Heal"},
		{0.9 , 0  , "Greater Heal",2}
	}
}

ryn.HealTarget=function(healProfile,target,hp,hotTarget,hotHp)
	if ryn.healProfiles[healProfile] then
		local mana,aoeInfo=UnitMana("player"),nil
		for i,healProfileEntry in ipairs(ryn.healProfiles[healProfile]) do
			local hpThreshold,manaCost,spellName,healMode,lTargetList,withCdOnly=unpack(healProfileEntry)
			ryn.currentHealFinish=nil
			if mana>=manaCost and (not withCdOnly or ryn.BuffCheck("player",ryn.buffInnerFocus)) and ryn.GetSpellCooldownByName(spellName)==0 then
				if (not healMode or healMode==1) and target and hp<hpThreshold and (not lTargetList or ryn.targetList[lTargetList][target]) then
					if not strfind(spellName,"Power Word: Shield",1,1) or not ryn.DebuffCheck(target,ryn.debuffWeakenedSoul) then
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

ryn.DispelTarget=function(target,debuffType)
	if target then
		local retarget=false
		ryn.targetList.all[target].blacklist=nil
		ryn.currentHealTarget=target
		ryn.currentHealFinish=nil
		if debuffType=="Magic" then
			if UnitExists("target") then
				ClearTarget()
				retarget=true
			end
			CastSpellByName("Dispel Magic")
		elseif not ryn.BuffCheck(target,ryn.buffAbolishDisease) then
			CastSpellByName("Abolish Disease")
		else
			CastSpellByName("Cure Disease")
		end
		SpellTargetUnit(target)
		if retarget then
			TargetLastTarget()
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

ryn.Heal=function(lTargetList,healProfile)
	lTargetList=lTargetList or ryn.targetList.all
	healProfile=healProfile or "regular"
	if ryn.SpellCastReady(ryn.healRange,ryn.stopCastingDelayExpire) then
		local target,hp,hotTarget,hotHp=ryn.GetHealTarget(lTargetList,ryn.healRange,ryn.buffRenew)
		ryn.HealTarget(healProfile,target,hp,hotTarget,hotHp)
	else
		ryn.HealInterrupt()
	end
end

ryn.dispelAll={Magic=true,Disease=true}
ryn.dispelMagic={Magic=true}
ryn.dispelDisease={Disease=true}

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
		local target,hpOrDebuffType,hotTarget,hotHp,action=ryn.GetHealOrDispelTarget(lTargetList,ryn.healRange,ryn.buffRenew,ryn.dispelRange,dispelTypes,dispelByHp,dispelHpThreshold)
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