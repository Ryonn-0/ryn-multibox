buffBurstOfKnowledge="Interface\\Icons\\INV_Jewelry_Amulet_07"
buffSecondWind="Interface\\Icons\\INV_Jewelry_Talisman_06"

dpsMode=1
-- 1: Skull/cross targeting
-- 2: Master assist targeting (with skull/cross target lock if applied)

function Debug(message)
	if message==nil then
		DEFAULT_CHAT_FRAME:AddMessage("nil")
	else
		DEFAULT_CHAT_FRAME:AddMessage(message)
	end
end

function ManaLower(target,manaThreshold)
	local manaCurrent=UnitMana(target)/UnitManaMax(target)
	if manaCurrent<manaThreshold then
		return true
	end
	return false
end

function HpLower(target,hpThreshold)
	local hpCurrent=UnitHealth(target)/UnitHealthMax(target)
	if hpCurrent<hpThreshold then
		return true
	end
	return false
end

function GetSpellSlot(texture)
	for i=1,120 do
		if GetActionTexture(i)==texture then
			return i
		end
	end
	return nil
end

function IsValidSpellTarget(target)
	if not UnitIsDeadOrGhost(target) and SpellCanTargetUnit(target) then
		return true
	end
	return false
end

function ClearFriendlyTarget()
	if UnitExists("target") and UnitIsFriend("player","target") then
		ClearTarget()
	end
end

function GetHealTarget(targetList,healSpell,hpThreshold)
	ClearFriendlyTarget()
	CastSpellByName(healSpell)
	local currentTarget,minHp,minBiasedHp
	for target,info in pairs(targetList) do
		local hp=UnitHealth(target)/UnitHealthMax(target)
		if hp<hpThreshold and IsValidSpellTarget(target) then
			local biasedHp=hp+info.bias
			if not minHp or biasedHp<minBiasedHp then
				minHp=hp
				minBiasedHp=biasedHp
				currentTarget=target
			end
		end
	end
	SpellStopTargeting()
	return currentTarget,minHp
end

function GetDispelTarget(targetList,dispelSpell,dispelTypes,dispelByHp)
	ClearFriendlyTarget()
	CastSpellByName(dispelSpell)
	local currentTarget,topPriority,debuffType
	for target,info in pairs(targetList) do
		if IsValidSpellTarget(target) then
			for i=1,16 do
				_,_,debuffType=UnitDebuff(target,i,1)
				if not debuffType or dispelTypes[debuffType] then
					break
				end
			end
			if debuffType then
				local priority=info.bias
				if dispelByHp then
					priority=priority+UnitHealth(target)/UnitHealthMax(target)
				end
				if not topPriority or priority<topPriority then
					topPriority=priority
					currentTarget=target
				end
			end
		end
	end
	SpellStopTargeting()
	return currentTarget,debuffType
	-- TODO: Check the amount of debuffs on a player and maybe priorities by debuff type. Will be important for Chromaggus.
end

-- 7 PARAMETERS!!! YEP!!!!!!
-- TODO?: Optimize, as so the the function won't cycle through the whole raid twice in most cases. This would add a lot of complexity though, so it's probably fine like this...
function GetHealOrDispelTarget(targetList,healSpell,hpThreshold,dispelSpell,dispelTypes,dispelByHp,dispelHpThreshold)
	local dispelTarget,debuffType,action
	local healTarget,minHp=GetHealTarget(targetList,healSpell,hpThreshold)
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
		return healTarget,minHp,action
	end
	return dispelTarget,debuffType,action
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
	if IsUsableAction(actionSlot) and GetActionCooldown(actionSlot)==0 then
		return true
	end
	return false
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

function TryTargetRaidIcon(icon,tabCount,tankTargetCheck)
	if not CheckRaidIcon("target",icon) then
		if tankTargetCheck then
			for target,info in pairs(targetList.tank) do
				AssistUnit(target)
				if CheckRaidIcon("target",icon) then
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
		AssistUnit(masterTarget)
		if UnitExists(target) and UnitCanAttack("player","target") then
			ClassDps()
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