ryn={} -- Addon scope

-- Settings
ryn.masterName="Harklen"
ryn.dpsMode=1
-- 1: Skull/cross targeting
-- 2: Master assist targeting (with skull/cross target lock if applied)
ryn.precastInterruptWindow=1
ryn.healHpThreshold=0.9
ryn.healInterruptThreshold=0.95
ryn.stopCastingDelay=0.5
-- Delay a new spellcast after a spell is interrupted.
ryn.blacklistTime=10
ryn.retryBlacklist=true
-- true: Try to heal/dispel blacklisted players, when no non-blacklisted player needs healing/dispelling.
-- false: Blacklisted players won't get heals/dispels until blacklist time expires.
ryn.aoeEnabled=true
ryn.damageType={arcane=true,fire=true,frost=true,holy=true,melee=true,nature=true,ranged=true,shadow=true,tank=true}

-- Addon global variables
_,ryn.playerClass=UnitClass("player")
ryn.buffSoulstone="Interface\\Icons\\Spell_Shadow_SoulGem"
--ryn.stopCastingDelayExpire
--ryn.currentHealTarget
--ryn.currentHealFinish
--ryn.precastHpThreshold

ryn.Debug=function(message,carry)
	local t,s=type(message),""
	if message==nil then
		s=s.."nil"
	elseif t=="boolean" then
		if message then s=s.."true" else s=s.."false" end
	elseif t=="string" or t=="number" then
		s=s..message
	elseif t=="table" and not carry then
		for key,val in message do
			s=s..ryn.Debug(key,true).." -> "..ryn.Debug(val,true)
			DEFAULT_CHAT_FRAME:AddMessage(s)
			s=""
		end
		return
	else
		s=s..t
	end
	if carry then return s
	else DEFAULT_CHAT_FRAME:AddMessage(s) end
end

ryn.GetSpellSlot=function(texture)
	for i=1,120 do
		if GetActionTexture(i)==texture then
			return i
		end
	end
	return nil
end

ryn.GetActionSlots=function()
	for lActionSlot = 1, 120 do
		local lActionText = GetActionText(lActionSlot);
		local lActionTexture = GetActionTexture(lActionSlot);
		if lActionTexture then
			local lMessage = "Slot " .. lActionSlot .. ": [" .. lActionTexture .. "]";
			if lActionText then
				lMessage = lMessage .. " \"" .. lActionText .. "\"";
			end
			DEFAULT_CHAT_FRAME:AddMessage(lMessage);
		end
	end
end

ryn.ManaLower=function(target,manaThreshold)
	local manaCurrent=UnitMana(target)/UnitManaMax(target)
	return manaCurrent<manaThreshold
end

ryn.HpLower=function(target,hpThreshold)
	local hpCurrent=UnitHealth(target)/UnitHealthMax(target)
	return hpCurrent<hpThreshold
end

ryn.IsCastingOrChanneling=function()
	return CastingBarFrame.casting or CastingBarFrame.channeling
end

ryn.IsValidSpellTarget=function(target)
	return not UnitIsDeadOrGhost(target) and SpellCanTargetUnit(target) and UnitIsFriend("player",target)
end

ryn.ClearFriendlyTarget=function()
	if UnitExists("target") and UnitIsFriend("player","target") then
		ClearTarget()
	end
end

-- TODO?: Might need to implement a second HoT check for druid healers.
ryn.GetHealTarget=function(targetList,healSpell,healIcon)
	ryn.ClearFriendlyTarget()
	CastSpellByName(healSpell)
	local currentTarget,minHp,minBiasedHp
	local currentHotTarget,minHotHp,minBiasedHotHp
	local blacklistFlag,minBlacklistTime=ryn.retryBlacklist,nil
	for target,info in pairs(targetList) do
		local hp=UnitHealth(target)/UnitHealthMax(target)
		if hp<ryn.healHpThreshold and ryn.IsValidSpellTarget(target) then
			if not info.blacklist or info.blacklist<=GetTime() then
				if blacklistFlag then
					blacklistFlag,currentTarget,currentHotTarget,minHp,minHotHp=false,nil,nil,nil,nil
				end
				info.blacklist=nil
				local biasedHp=hp+info.bias
				if not minHp or biasedHp<minBiasedHp then
					minHp,minBiasedHp,currentTarget=hp,biasedHp,target
				end
				if healIcon and (not minHotHp or biasedHp<minBiasedHotHp) and not ryn.BuffCheck(target,healIcon) then
					minHotHp,minBiasedHotHp,currentHotTarget=hp,biasedHp,target
				end
			elseif blacklistFlag then
				if not minBlacklistTime or minBlacklistTime>info.blacklist then
					minBlacklistTime=info.blacklist
					currentTarget=target
					minHp=hp
					if healIcon and not ryn.BuffCheck(target,healIcon) then
						currentHotTarget=target
						minHotHp=hp
					end
				end
			end
		end
	end
	SpellStopTargeting()
	return currentTarget,minHp,currentHotTarget,minHotHp
end

ryn.GetDispelTarget=function(targetList,dispelSpell,dispelTypes,dispelByHp)
	ryn.ClearFriendlyTarget()
	CastSpellByName(dispelSpell)
	local currentTarget,topPriority,debuffType,currentDebuffType
	local blacklistFlag,minBlacklistTime=ryn.retryBlacklist,nil
	for target,info in pairs(targetList) do
		if ryn.IsValidSpellTarget(target) then
			for i=1,16 do
				_,_,debuffType=UnitDebuff(target,i,1)
				if not debuffType or dispelTypes[debuffType] then
					break
				end
			end
			if debuffType then
				if not info.blacklist or info.blacklist<=GetTime() then
					if blacklistFlag then
						blacklistFlag,currentTarget,currentDebuffType=false,nil,nil
					end
					info.blacklist=nil
					local priority=info.bias
					if dispelByHp then
						priority=priority+UnitHealth(target)/UnitHealthMax(target)
					end
					if not topPriority or priority<topPriority then
						topPriority=priority
						currentTarget=target
						currentDebuffType=debuffType
					end
				elseif blacklistFlag then
					if not minBlacklistTime or minBlacklistTime>info.blacklist then
						minBlacklistTime=info.blacklist
						currentTarget=target
						currentDebuffType=debuffType
					end
				end
			end
		end
	end
	SpellStopTargeting()
	return currentTarget,currentDebuffType
	-- TODO: Check the amount of debuffs on a player and maybe priorities by debuff type. Will be important for Chromaggus.
	-- TODO: Implement check for abolish effects (priest Abolish Disease, Druid abolish poison, Restorative Poison, etc...)
end

-- SEVEN PARAMETERS!!! YEP!!!!!!!!!!!!!!!!44444four
ryn.GetHealOrDispelTarget=function(targetList,healSpell,healIcon,dispelSpell,dispelTypes,dispelByHp,dispelHpThreshold)
	local dispelTarget,debuffType,action
	local healTarget,minHp,healHotTarget,minHotHp=ryn.GetHealTarget(targetList,healSpell,healIcon)
	if not healTarget or minHp>dispelHpThreshold then
		dispelTarget,debuffType=ryn.GetDispelTarget(targetList,dispelSpell,dispelTypes,dispelByHp)
		if dispelTarget then
			action="dispel"
		else
			action="heal"
		end
	else
		action="heal"
	end
	if action=="heal" then
		return healTarget,minHp,healHotTarget,minHotHp,action
	end
	return dispelTarget,debuffType,nil,nil,action
end

ryn.HealInterrupt=function()
	local target=ryn.currentHealTarget
	local finish=ryn.currentHealFinish
	local t=GetTime()
	if target and finish and (not ryn.stopCastingDelayExpire or ryn.stopCastingDelayExpire<t) then
		if ryn.precastHpThreshold then -- Precast
			--ryn.Debug("PRECAST")
			if finish-ryn.precastInterruptWindow<t and not ryn.HpLower(target,ryn.precastHpThreshold) then
				--ryn.Debug("PRECAST_INTERRUPT")
				SpellStopCasting()
				--ryn.Debug("Precast interrupt!")
				ryn.stopCastingDelayExpire=t+ryn.stopCastingDelay
				ryn.precastHpThreshold=nil
			end
		else -- Overheal prevention
			--ryn.Debug("OVERHEAL")
			if not ryn.HpLower(target,ryn.healInterruptThreshold) and (not ryn.targetList.tank[target] or finish-ryn.precastInterruptWindow<t) then
				--ryn.Debug("OVERHEAL_INTERRUPT")
				SpellStopCasting()
				--ryn.Debug("Overheal interrupt!")
				ryn.stopCastingDelayExpire=t+ryn.stopCastingDelay
			end
		end
	end
end

ryn.BlacklistTarget=function(target)
	if target then
		local targetInfo=ryn.targetList.all[target]
		if targetInfo then
			--ryn.Debug("Blacklisted "..targetInfo.name.."! ("..ryn.blacklistTime.."s)")
			--if not targetInfo.blacklist then
			--	SendChatMessage("Blacklisted "..targetInfo.name.."! ("..ryn.blacklistTime.."s)","SAY")
			--end
			targetInfo.blacklist=GetTime()+ryn.blacklistTime
		end
	end
end

ryn.IsBlacklisted=function(target)
	if target then
		targetInfo=ryn.targetList.all[target]
		if targetInfo then
			if not targetInfo.blacklist or targetInfo.blacklist<=GetTime() then
				targetInfo.blacklist=nil
				return false
			else
				return true
			end
		end
	end
end

ryn.IsActionReady=function(actionSlot)
	return IsUsableAction(actionSlot) and GetActionCooldown(actionSlot)==0
end

ryn.BuffCheck=function(target,buff)
	local i=1
	while UnitBuff(target,i)~=nil do
		if buff==UnitBuff(target,i) then
			return true
		end
		i=i+1
	end
	return false
end

ryn.DebuffCheck=function(target,debuff)
	local i=1
	while UnitDebuff(target,i)~=nil do
		if debuff==UnitDebuff(target,i) then
			return true
		end
		i=i+1
	end
	return false
end

ryn.CheckRaidIcon=function(target,icon)
	return UnitExists(target) and not UnitIsDead(target) and GetRaidTargetIndex(target)==icon
end

ryn.IsCastingOrChanelling=function()
	return CastingBarFrame.casting or CastingBarFrame.channeling
end

ryn.SpellCastReady=function(spell,delay)
	if not ryn.IsCastingOrChanelling() and ryn.GetSpellCooldownByName(spell)==0 and (not delay or delay<GetTime()) then
		ryn.stopCastingDelayExpire=nil
		return true
	end
	return false
end

ryn.TryTargetRaidIcon=function(icon,tabCount,tankTargetCheck)
	if not ryn.CheckRaidIcon("target",icon) then
		if tankTargetCheck then
			for target,info in pairs(ryn.targetList.tank) do
				if ryn.CheckRaidIcon(target.."target",icon) then
					AssistUnit(target)
					return true
				end
			end
		end
		for i=1,tabCount do
			TargetNearestEnemy()
			if ryn.CheckRaidIcon("target",icon) then
				return true
			end
		end
	else
		return true
	end
	return false
end

ryn.GetHostileTarget=function()
	if ryn.CheckRaidIcon("target",8) and UnitCanAttack("player","target") or ryn.CheckRaidIcon("target",7) and UnitCanAttack("player","target") then
		return true
	elseif ryn.dpsMode==1 then
		if ryn.TryTargetRaidIcon(8,10,true) and UnitCanAttack("player","target") or ryn.TryTargetRaidIcon(7,10,true) and UnitCanAttack("player","target") then
			return true
		end
	elseif ryn.dpsMode==2 then
		if ryn.masterTarget then
			AssistUnit(ryn.masterTarget)
			if UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player","target") then
				return true
			end
		end
	end
	return false
end

ryn.SSCheck=function(lTargetList)
	lTargetList=lTargetList or ryn.targetList.all
	local chatType=nil
	local nameString=""
	local buffCount=0
	if UnitInRaid("player") then
		chatType="RAID"
	else
		chatType="PARTY"
	end
	for target,info in pairs(lTargetList) do
		if ryn.BuffCheck(target,ryn.buffSoulstone) then
			buffCount=buffCount+1
			nameString=nameString..info.name.." "
		end
	end
	SendChatMessage("SS check: "..buffCount.." player(s) have SS.",chatType)
	if buffCount>0 then
		SendChatMessage(nameString,chatType)
	end
end

ryn.EquipItemByItemLink=function(itemLink,invSlotId)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local item=GetContainerItemLink(bag,slot)
			if item==itemLink then
				PickupContainerItem(bag,slot)
				EquipCursorItem(invSlotId)
			end
		end
	end
end

ryn.UnequipItemBySlotId=function(invSlotId)
	local itemLink=GetInventoryItemLink("player",invSlotId)
	if itemLink then
		PickupInventoryItem(invSlotId)
		PutItemInBackpack()
		return itemLink
	end
end

ryn.addOns={"Bartender2","Cartographer","!ImprovedErrorFrame","MobInfo2","!OmniCC","XPerl","XPerl_Options","XPerl_Party","XPerl_PartyPet","XPerl_Player","XPerl_PlayerPet"
	,"XPerl_RaidAdmin","XPerl_RaidFrames","XPerl_RaidHelper","XPerl_Target","XPerl_TargetTarget","XLoot","ShaguDB","ShaguQuest","!Questie"
}

ryn.RegularMode=function()
	for i,addOn in ipairs(ryn.addOns) do
		EnableAddOn(addOn)
	end
	ReloadUI()
end

ryn.MinimalMode=function()
	for i,addOn in ipairs(ryn.addOns) do
		DisableAddOn(addOn)
	end
	ReloadUI()
end

ryn.SmartReload=function()
	if UnitName("player")==ryn.masterName then
		ryn.RegularMode()
	else
		ryn.MinimalMode()
	end
end