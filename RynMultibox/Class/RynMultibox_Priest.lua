local class

if ryn.playerClass=="PRIEST" then
class={}

class.buffAbolishDisease="Interface\\Icons\\Spell_Nature_NullifyDisease"
class.buffRenew="Interface\\Icons\\Spell_Holy_Renew"
class.buffInnerFocus="Interface\\Icons\\Spell_Frost_WindWalkOn"
class.debuffWeakenedSoul="Interface\\Icons\\Spell_Holy_AshesToAshes"

class.healRange="Lesser Heal(Rank 1)"
class.dispelRange="Cure Disease"
class.aoeHealMinPlayers=3

class.EventHandler=function()
	if event=="UI_ERROR_MESSAGE" and arg1=="Target not in line of sight" then
		ryn.BlacklistTarget(ryn.currentHealTarget)
	elseif event=="SPELLCAST_START" then
		ryn.currentHealFinish=GetTime()+arg2/1000
		ryn.Debug("START: "..GetTime())
	elseif event=="SPELLCAST_DELAYED" then
		ryn.currentHealFinish=ryn.currentHealFinish+arg1/1000
	elseif event=="SPELLCAST_STOP" then
		ryn.currentHealTarget=nil
		ryn.currentHealFinish=nil
		ryn.precastHpThreshold=nil
		ryn.Debug("STOP: "..GetTime())
	end
end

class.eventFrame=CreateFrame("Frame")
class.eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
class.eventFrame:RegisterEvent("SPELLCAST_START")
class.eventFrame:RegisterEvent("SPELLCAST_DELAYED")
class.eventFrame:RegisterEvent("SPELLCAST_STOP")
class.eventFrame:SetScript("OnEvent",class.EventHandler)

class.healProfiles={
	regular={
		{0.4 , 380, "Flash Heal",1,"tank"},
		{0.5 , 0  , "Inner Focus",4},
		{0.5 , 0  , "Prayer of Healing",4,false,true},
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
		{0.5 , 380, "Flash Heal",1,"tank"},
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
		{0.9 , 0  , "Flash Heal"},
		{0.9 , 0  , "Greater Heal",2}
	}
}

class.HealTarget=function(healProfile,target,hp,hotTarget,hotHp,aoeInfo)
	if class.healProfiles[healProfile] then
		for i,healProfileEntry in ipairs(class.healProfiles[healProfile]) do
			local hpThreshold,manaCost,spellName,healMode,lTargetList,withCdOnly=unpack(healProfileEntry)
			local mana=UnitMana("player")
			currentHealFinish=nil
			if mana>=manaCost and (not withCdOnly or ryn.BuffCheck("player",class.buffInnerFocus)) and ryn.GetSpellCooldownByName(spellName)==0 then
				if (not healMode or healMode==1) and target and hp<hpThreshold and (not lTargetList or ryn.targetList[lTargetList][target]) then
					--ryn.Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
					if strfind(spellName,"Power Word: Shield",1,1) and ryn.DebuffCheck(target,class.debuffWeakenedSoul) then
						break
					end
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
				elseif healMode==3 and hotTarget and hotHp<hpThreshold and (not lTargetList or ryn.targetList[lTargetList][hotTarget]) then
					--ryn.Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
					ryn.targetList.all[target].blacklist=nil
					ryn.currentHealTarget=hotTarget
					CastSpellByName(spellName)
					SpellTargetUnit(hotTarget)
					break
				elseif healMode==4 and aoeInfo[class.aoeHealMinPlayers] and aoeInfo[class.aoeHealMinPlayers].hpRatio<hpThreshold then
					--ryn.Debug("Executing heal profile \""..healProfile.."\", entry: "..i)
					ryn.currentHealTarget=nil
					CastSpellByName(spellName)
					break
				end
			end
		end
	end
end

class.DispelTarget=function(target,debuffType)
	if target then
		ryn.targetList.all[target].blacklist=nil
		ryn.currentHealTarget=target
		ryn.currentHealFinish=nil
		if debuffType=="Magic" then
			ClearTarget()
			CastSpellByName("Dispel Magic")
		elseif not ryn.BuffCheck(target,class.buffAbolishDisease) then
			CastSpellByName("Abolish Disease")
		else
			CastSpellByName("Cure Disease")
		end
		SpellTargetUnit(target)
	end
end

class.AoeInfo=function()
	ryn.ClearFriendlyTarget()
	CastSpellByName(class.dispelRange)
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
	if ryn.SpellCastReady(class.healRange,ryn.stopCastingDelayExpire) then
		local target,hp,hotTarget,hotHp=ryn.GetHealTarget(lTargetList,class.healRange,class.buffRenew)
		local aoeInfo=class.AoeInfo()
		class.HealTarget(healProfile,target,hp,hotTarget,hotHp,aoeInfo)
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
	if ryn.SpellCastReady(class.dispelRange) then
		local target,debuffType=ryn.GetDispelTarget(lTargetList,class.dispelRange,dispelAll,false)
		class.DispelTarget(target,debuffType)
	end
end

ryn.HealOrDispel=function(lTargetList,healProfile,dispelTypes,dispelByHp,dispelHpThreshold)
	lTargetList=lTargetList or ryn.targetList.all
	healProfile=healProfile or "regular"
	dispelTypes=dispelTypes or ryn.dispelAll
	dispelByHp=dispelByHp or false
	dispelHpThreshold=dispelHpThreshold or 0.4
	if ryn.SpellCastReady(class.healRange,stopCastingDelayExpire) then
		local target,hpOrDebuffType,hotTarget,hotHp,action=ryn.GetHealOrDispelTarget(lTargetList,class.healRange,class.buffRenew,class.dispelRange,dispelTypes,dispelByHp,dispelHpThreshold)
		if action=="heal" then
			local aoeInfo=class.AoeInfo()
			class.HealTarget(healProfile,target,hpOrDebuffType,hotTarget,hotHp,aoeInfo)
		else
			class.DispelTarget(target,hpOrDebuffType)
		end
	else
		ryn.HealInterrupt()
	end
end

end