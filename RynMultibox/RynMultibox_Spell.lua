local ryn=ryn
-- Spell management

local invSlotName={"Head","Neck","Shoulder","Shirt","Chest","Waist","Legs","Feet","Wrist","Hands",
	"Finger 1","Finger 2","Trinket 1","Trinket 2","Back","Main hand","Off hand","Ranged","Tabard"}
invSlotName[0]="Ammo"

-- TODO: Pet abilities

-- spellData:{spellKey,spellName,spellRank,spellID,bookType,isMaxRank,actionSlot,actionMulti}
-- spellKey -> spellData
local spellData={}
-- actionSlot -> spellData
local actionData={}
local itemData={}

ryn.BuildSpellData=function()
	local i=1
	local lMaxSpell,lMaxRank=nil,nil
	while true do
		local lSpellName,lSpellRank=GetSpellName(i,BOOKTYPE_SPELL);
		if lMaxSpell and lSpellName~=lMaxSpell then
			spellData[lMaxSpell]=spellData[lMaxSpell.."("..lMaxRank..")"]
			spellData[lMaxSpell].isMaxRank=true
			lMaxSpell,lMaxRank=nil,nil
		end
		if not lSpellName then
			break
		end
		local spellDataKey
		if strfind(lSpellRank,"Rank",1,1) then
			lMaxSpell,lMaxRank=lSpellName,lSpellRank
			spellDataKey=lSpellName.."("..lSpellRank..")"
			local _,_,spellRankNum=string.find(lSpellRank,"(%d+)")
			spellRankNum=tonumber(spellRankNum)
			spellData[spellDataKey]={spellKey=spellDataKey,spellName=lSpellName,spellRank=spellRankNum,spellId=i,bookType="BOOKTYPE_SPELL"}
		elseif lSpellRank~="Passive" and lSpellRank~="Racial Passive" then
			lMaxSpell,lMaxRank=nil,nil
			spellDataKey=lSpellName
			spellData[spellDataKey]={spellKey=spellDataKey,spellName=lSpellName,spellId=i,bookType="BOOKTYPE_SPELL",isMaxRank=true}
			if strfind(spellDataKey,")",-1) then
				spellData[spellDataKey.."()"]=spellData[spellDataKey]
			end
		end
		i=i+1
	end
	ryn.ActionSlotInit()
end

ryn.GetSpellIdEntries=function(pSpellId)
	local count=0
	for key,info in pairs(spellData) do
		if not pSpellId or info.spellId==pSpellId then
			local s=info.spellId..": "..key
			if info.actionSlot then
				s=s.." | Slot: "..info.actionSlot
			end
			ryn.Debug(s)
			count=count+1
		end
	end
	ryn.Debug("Total entries: "..count)
end

ryn.GetSpellNameEntries=function(pSpellName)
	local count=0
	for key,info in pairs(spellData) do
		if not pSpellName or info.spellName==pSpellName then
			local s=info.spellId..": "..key
			if info.actionSlot then
				s=s.." | Slot: "..info.actionSlot
			end
			ryn.Debug(s)
			count=count+1
		end
	end
	ryn.Debug("Total entries: "..count)
end

ryn.GetActionSlotEntries=function(slot)
	local count=0
	for name,info in pairs(spellData) do
		if info.actionSlot and (info.actionSlot==slot or not slot) then
			local s=info.spellId..": "..name
			s=s.." | Slot: "..info.actionSlot
			ryn.Debug(s)
			count=count+1
		end
	end
	ryn.Debug("Total entries: "..count)
end

ryn.SpellExists=function(spellName)
	if spellData[spellName] then
		return true
	end
	return false
end

ryn.GetSpellCooldownByName=function(spellName)
	local spellEntry=spellData[spellName]
	if spellEntry then
		return GetSpellCooldown(spellEntry.spellId,spellEntry.bookType)
	end
end

ryn.GetActionSlot=function(spellName)
	local spellEntry=spellData[spellName]
	if spellEntry then
		return spellEntry.actionSlot
	end
end

ryn.GetItemCooldown=function(slotName)
	local item=itemData[slotName]
	if item then
		return GetActionCooldown(item.actionSlot)
	end
end

ryn.UseItem=function(slotName)
	local item=itemData[slotName]
	if item then
		UseAction(item.actionSlot)
	end
end

ryn.UseTrinkets=function()
	if ryn.GetItemCooldown("Trinket 1")==0 then
		ryn.UseItem("Trinket 1")
		return true
	elseif ryn.GetItemCooldown("Trinket 2")==0 then
		ryn.UseItem("Trinket 2")
		return true
	end
	return false
end

ryn.Mount=function()
	local mount=itemData["Fast mount"] or itemData["Slow mount"] or spellData["Summon Warhorse"] or spellData["Summon Felsteed"]
	if mount and mount.actionSlot then
		UseAction(mount.actionSlot)
	end
end

CreateFrame("GameTooltip","RynTooltip",nil,"GameTooltipTemplate")
RynTooltip:SetOwner(WorldFrame,"ANCHOR_NONE")
RynTooltip:AddFontStrings(
	RynTooltip:CreateFontString("$parentTextLeft1",nil,"GameTooltipText"),
	RynTooltip:CreateFontString("$parentTextRight1",nil,"GameTooltipText")
)

ryn.ActionSlotUpdate=function(slot,isInit)
	if GetActionText(slot) then return end -- macro
	local name,rank
	local changed=false
	RynTooltip:ClearLines()
	RynTooltip:SetAction(slot)
	if RynTooltip:NumLines()>0 then
		name=RynTooltipTextLeft1:GetText()
		if RynTooltipTextRight1:IsShown() then
			rank=RynTooltipTextRight1:GetText()
		end
		local currentSpellData
		if rank and strfind(rank,"Rank",1,1) then
			currentSpellData=spellData[name.."("..rank..")"]
		else
			currentSpellData=spellData[name]
		end
		if currentSpellData then
			local currentActionSlot=currentSpellData.actionSlot
			if not currentActionSlot then
				changed=true
				currentSpellData.actionSlot=slot
				actionData[slot]=currentSpellData
			elseif currentActionSlot~=slot then
				currentSpellData.actionMulti=true
				actionData[slot]=currentSpellData
			end
		else
			if IsEquippedAction(slot) then
				--ryn.Debug("Equipped: "..slot)
				for i=1,18 do
					local itemName=GetInventoryItemLink("player",i)
					if itemName then
						_,_,itemName=string.find(GetInventoryItemLink("player",i),"%[(.*)%]")
						if itemName==name then
							local currentInvSlot=invSlotName[i]
							itemData[currentInvSlot]={actionType="Equipped",invSlot=currentInvSlot,itemName=name,actionSlot=slot}
							actionData[slot]=itemData[currentInvSlot]
							break
						end
					end
				end
			elseif IsConsumableAction(slot) then
				--ryn.Debug("Consumable: "..slot)
				-- Something
			else
				--ryn.Debug("Other: "..slot)
				local line,i="",2
				while line~=nil do
					line=getglobal("RynTooltipTextLeft"..i):GetText()
					if line=="Requires Riding (150)" then
						--ryn.Debug("Fast mount")
						itemData["Fast mount"]={actionType="Mount",itemName=name,actionSlot=slot}
					elseif line=="Requires Riding (75)" then
						if strfind(name,"Qiraji Resonating") then
							--ryn.Debug("AQ mount")
							itemData["AQ mount"]={actionType="Mount",itemName=name,actionSlot=slot}
						else
							--ryn.Debug("Slow mount")
							itemData["Slow mount"]={actionType="Mount",itemName=name,actionSlot=slot}
						end
					end
					i=i+1
				end
			end
		end
	elseif not isInit then
		local currentData=actionData[slot]
		if not currentData then return end
		actionData[slot]=nil
		if currentData.spellKey then
			if currentData.actionMulti then
				for iSlot,iSpellData in actionData do
					local found=false
					if iSpellData.spellKey==currentData.spellKey then
						if found then
							currentData.actionMulti=true
							break
						else
							currentData.actionSlot=iSlot
							currentData.actionMulti=false
							found=true
						end
					end
				end
			else
				currentData.actionSlot=nil
			end
			changed=true
		end
	end
	if not isInit and changed and ryn.ClassActionSlotInit then
		ryn.ClassActionSlotInit()
	end
end

ryn.ActionSlotInit=function()
	for slot=1,120 do
		ryn.ActionSlotUpdate(slot,true)
	end
	if ryn.ClassActionSlotInit then
		ryn.ClassActionSlotInit()
	end
end