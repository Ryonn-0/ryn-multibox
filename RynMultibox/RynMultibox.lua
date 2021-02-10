buffBurstOfKnowledge="Interface\\Icons\\INV_Jewelry_Amulet_07"
buffSecondWind="Interface\\Icons\\INV_Jewelry_Talisman_06"

dpsMode=1
-- 1: Skull/cross targeting
-- 2: Master assist targeting (with skull/cross target lock if applied)
precastInterruptWindow=1
healHpThreshold=0.9
healInterruptThreshold=0.95
stopCastingDelay=0.5

stopCastingDelayExpire=nil
currentHealTarget=nil
currentHealFinish=nil
precastHpThreshold=nil
blacklistTime=10

function Debug(message)
	if message==nil then
		DEFAULT_CHAT_FRAME:AddMessage("nil")
	else
		DEFAULT_CHAT_FRAME:AddMessage(message)
	end
end

function ManaLower(target,manaThreshold)
	local manaCurrent=UnitMana(target)/UnitManaMax(target)
	return manaCurrent<manaThreshold
end

function HpLower(target,hpThreshold)
	local hpCurrent=UnitHealth(target)/UnitHealthMax(target)
	return hpCurrent<hpThreshold
end

function GetSpellSlot(texture)
	for i=1,120 do
		if GetActionTexture(i)==texture then
			return i
		end
	end
	return nil
end

function IsCastingOrChanneling()
	return CastingBarFrame.casting or CastingBarFrame.channeling
end

function IsValidSpellTarget(target)
	return not UnitIsDeadOrGhost(target) and SpellCanTargetUnit(target)
end

function ClearFriendlyTarget()
	if UnitExists("target") and UnitIsFriend("player","target") then
		ClearTarget()
	end
end

-- TODO?: Might need to implement a second HoT check for druid healers.
function GetHealTarget(targetList,healSpell,healIcon)
	ClearFriendlyTarget()
	CastSpellByName(healSpell)
	local currentTarget,minHp,minBiasedHp
	local currentHotTarget,minHotHp,minBiasedHotHp
	local blacklistFlag,minBlacklistTime=true,nil
	for target,info in pairs(targetList) do
		local hp=UnitHealth(target)/UnitHealthMax(target)
		if hp<healHpThreshold and IsValidSpellTarget(target) then
			if not info.blacklist or info.blacklist<=GetTime() then
				if blacklistFlag then
					blacklistFlag,currentTarget,currentHotTarget,minHp,minHotHp=false,nil,nil,nil,nil
				end
				info.blacklist=nil
				local biasedHp=hp+info.bias
				if not minHp or biasedHp<minBiasedHp then
					minHp,minBiasedHp,currentTarget=hp,biasedHp,target
				end
				if healIcon and (not minHotHp or biasedHp<minBiasedHotHp) and not BuffCheck(target,healIcon) then
					minHotHp,minBiasedHotHp,currentHotTarget=hp,biasedHp,target
				end
			elseif blacklistFlag then
				if not minBlacklistTime or minBlacklistTime>info.blacklist then
					minBlacklistTime=info.blacklist
					currentTarget=target
					minHp=hp
					if healIcon and not BuffCheck(target,healIcon) then
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

function GetDispelTarget(targetList,dispelSpell,dispelTypes,dispelByHp)
	ClearFriendlyTarget()
	CastSpellByName(dispelSpell)
	local currentTarget,topPriority,debuffType,currentDebuffType
	local blacklistFlag,minBlacklistTime=true,nil
	for target,info in pairs(targetList) do
		if IsValidSpellTarget(target) then
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
function GetHealOrDispelTarget(targetList,healSpell,healIcon,dispelSpell,dispelTypes,dispelByHp,dispelHpThreshold)
	local dispelTarget,debuffType,action
	local healTarget,minHp,healHotTarget,minHotHp=GetHealTarget(targetList,healSpell,healIcon)
	if not healTarget or minHp>dispelHpThreshold then
		dispelTarget,debuffType=GetDispelTarget(targetList,dispelSpell,dispelTypes,dispelByHp)
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

function HealInterrupt(target,finish,hpThreshold)
	if not stopCastingDelayExpire then
		if precastHpThreshold then -- Precast
			if not UnitExists(target) or not UnitIsFriend("player",target) or
			finish-precastInterruptWindow<GetTime() and not HpLower(target,hpThreshold) then
				SpellStopCasting()
				--Debug("Precast interrupt!")
				stopCastingDelayExpire=GetTime()+stopCastingDelay
			end
		elseif target then -- Overheal prevention
			if UnitExists(target) and not HpLower(target,healInterruptThreshold) then
				SpellStopCasting()
				--Debug("Overheal interrupt!")
				stopCastingDelayExpire=GetTime()+stopCastingDelay
			end
		end
	end
end

function GetActionSlots()
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

function IsActionReady(actionSlot)
	return IsUsableAction(actionSlot) and GetActionCooldown(actionSlot)==0
end

function BuffCheck(target,buff)
	local i=1
	while UnitBuff(target,i)~=nil do
		if buff==UnitBuff(target,i) then
			return true
		end
		i=i+1;
	end
	return false
end

function CheckRaidIcon(target,icon)
	return UnitExists(target) and not UnitIsDead(target) and GetRaidTargetIndex(target)==icon
end

function IsCastingOrChanelling()
	return CastingBarFrame.casting or CastingBarFrame.channeling
end

function SpellCastReady(spell,delay)
	if not IsCastingOrChanelling() and GetSpellCooldownByName(spell)==0 and (not delay or delay<GetTime()) then
		stopCastingDelayExpire=nil
		precastHpThreshold=nil
		return true
	end
	return false
end

function TryTargetRaidIcon(icon,tabCount,tankTargetCheck)
	if not CheckRaidIcon("target",icon) then
		if tankTargetCheck then
			for target,info in pairs(targetList.tank) do
				if CheckRaidIcon(target.."target",icon) then
					AssistUnit(target)
					return true
				end
			end
		end
		for i=1,tabCount do
			TargetNearestEnemy()
			if CheckRaidIcon("target",icon) then
				return true
			end
		end
	else
		return true
	end
	return false
end

function Dps(ClassDps)
	if CheckRaidIcon("target",8) or CheckRaidIcon("target",7) then
		ClassDps()
	elseif dpsMode==1 then
		if TryTargetRaidIcon(8,10,true) or TryTargetRaidIcon(7,10,true) then
			ClassDps()
		end
	elseif dpsMode==2 then
		if masterTarget then
			AssistUnit(masterTarget)
			if UnitExists("target") and UnitCanAttack("player","target") then
				ClassDps()
			end
		end
	end
end

function SSCheck(targetList)
	local chatType=nil
	local nameString=""
	local buffCount=0
	if UnitInRaid("player") then
		chatType="RAID"
	else
		chatType="PARTY"
	end
	for target,info in pairs(targetList) do
		if BuffCheck(target,buffSoulstone) then
			buffCount=buffCount+1
			nameString=nameString..info.name.." "
		end
	end
	SendChatMessage("SS check: "..buffCount.." player(s) have SS.",chatType)
	if buffCount>0 then
		SendChatMessage(nameString,chatType)
	end
end

addOns={"Bartender2","Cartographer","!ImprovedErrorFrame","MobInfo2","!OmniCC","XPerl","XPerl_Options","XPerl_Party","XPerl_PartyPet","XPerl_Player","XPerl_PlayerPet"
	,"XPerl_RaidAdmin","XPerl_RaidFrames","XPerl_RaidHelper","XPerl_Target","XPerl_TargetTarget","XLoot","ShaguDB","ShaguQuest","!Questie"
}

function RegularMode()
	for i,addOn in ipairs(addOns) do
		EnableAddOn(addOn)
	end
	ReloadUI()
end

function MinimalMode()
	for i,addOn in ipairs(addOns) do
		DisableAddOn(addOn)
	end
	ReloadUI()
end

function SmartReload()
	if UnitName("player")==masterName then
		RegularMode()
	else
		MinimalMode()
	end
end