local ryn=ryn
-- Group management

local nameList={
	tank={"Harklen","Gaelber","Llanewrynn","Stardancer","Cooperbeard","Dobzse","Obier","Yxon","Fierileya","Bendegúz","Pinky","Naderius","Bugabo","Peacebringer"},
	heal={"Alaniel","Flo","Livia","Hoyt","Myra","Papsajt","Negreanu","Kearlah","Azure","Warrógép","Rhodelya","Blueyes","Erutan"}, -- Erutan temp
	multiHeal={
	"Dreamblast","Skyx","Uyalin","Illumyn","Paladino", -- Kearlah
	"Baleog","Lionel","Nobleforged","Lightbeard","Moonflower","Bronzecoat", -- Azsgrof
	"Pamelma","Amonstenn" -- Dobzse
	},
	multiDps={
	"Dorothy","Tygerra","Havox","Eoro","Livingbomb","Dorkilla","Reimus","Necropoly","Vibranium","Lazarrus","Skyfire", -- Kearlah
	"Azsgrof","Liberton","Leilena","Cromwell","Daemona","Carla","Windou","Jaliana","Fabregas","Pinkypie","Oakheart","Featherfire","Pompedous","Miraclemike","Morbent","Maleficus","Nightleaf","Ravencloud", -- Azsgrof
	"Aedis","Therena","Nien","Lucilde" -- Dobzse
	},
	myMultiHeal={"Ryonn"},
	myMultiDps={"Arvene","Nymira","Inochi","Seloris"}
}

local function InitTargetList()
	ryn.targetList={all={},party={},master={},self={}}
	for role,names in pairs(nameList) do
		ryn.targetList[role]={}
	end
	ryn.targetList.dps={}
	for i=1,8 do
		ryn.targetList["group"..i]={}
	end
end
InitTargetList()
local targetListReady=false

-- targetLists: {all,tank,heal,dps(default),multiHeal,multiDps,myMultiHeal,myMultiDps,party,group<1-8>,<charname>,master,self}   TODO: assist?,class,custom<any>?
-- playerInfo: uid -> {name,role,class,group,bias}

-- Initialize bias list
local biasList={}

-- Set default global bias values
biasList.tank,biasList.heal,biasList.multiHeal,biasList.multiDps,biasList.myMultiHeal,biasList.myMultiDps=-0.1,-0.07,0.1,0.15,-0.05,-0.02
biasList.Cipola=10000
biasList.Harklen=-0.1
biasList.Alaniel=-0.02
biasList.self=-0.05

-- Test values
--biasList.tank,biasList.heal,biasList.dps,biasList.multiHeal,biasList.multiDps,biasList.myMultiHeal,biasList.myMultiDps=0.1,0.2,0.3,0.4,0.5,0.6,0.7
--biasList.self=0.01
--biasList.master=0.001
--biasList.group1,biasList.group2,biasList.group3,biasList.group4=1,2,3,4
--biasList.group5,biasList.group6,biasList.group7,biasList.group8=5,6,7,8
--biasList.party=10
--biasList.Alaniel=100

local function AddBias(targetInfo,value)
	if value then
		targetInfo.bias=targetInfo.bias+value
	end
end

local function RemoveBias(targetInfo,value)
	if value then
		targetInfo.bias=targetInfo.bias-value
	end
end

-- This function should be used in SuperMacro's extended LUA code fields, to easily manage healing biases per healer.
-- I could set biasList as a saved variable, might do it later, but since the addon doesn't have ui elements, the method above is more comfortable to use.
ryn.SetBias=function(bias,list)
	local oldBias
	oldBias=biasList[list]
	biasList[list]=bias
	if oldBias==bias then
		return
	end
	if ryn.targetList then
		for target,info in pairs(ryn.targetList[list]) do
			RemoveBias(info,oldBias)
			AddBias(info,bias)
		end
	end
	--ryn.Debug("New bias value set.")
end

ryn.GetRole=function(name)
	for role,names in pairs(nameList) do
		for i,currentName in ipairs(names) do
			if currentName==name then
				return role
			end
		end
	end
	return "dps"
end

ryn.GetGroupId=function(uid)
	for target,_ in pairs(ryn.targetList.all) do
		if UnitIsUnit(uid,target) then
			return target
		end
	end
	return nil
end

ryn.GetGroupIdByName=function(name)
	for target,info in pairs(ryn.targetList.all) do
		if info.name==name then
			return target
		end
	end
	return nil
end

local function RegisterUnit(isRaid,raidOrUnitId)
	local uid
	if isRaid then
		uid="raid"..raidOrUnitId
	else
		uid=raidOrUnitId
	end
	if UnitIsConnected(uid) then
		-- Set player info, initialize bias
		local unitName,unitGroup,unitClass,unitRole
		if isRaid then
			unitName,_,unitGroup,_,_,unitClass=GetRaidRosterInfo(raidOrUnitId)
		else
			unitName=UnitName(uid)
			_,unitClass=UnitClass(uid)
		end
		local unitRole=ryn.GetRole(unitName)
		local targetInfo={}
		local isPlayer=unitName==UnitName("player")
		targetInfo.name=unitName
		targetInfo.class=unitClass
		targetInfo.group=unitGroup or 0
		targetInfo.role=unitRole
		targetInfo.bias=0

		-- Add player to target lists, set bias values
		-- All
		ryn.targetList.all[uid]=targetInfo
		
		-- Role
		ryn.targetList[unitRole][uid]=targetInfo
		AddBias(targetInfo,biasList[unitRole])
		
		-- Group
		if isRaid then
			ryn.targetList["group"..unitGroup][uid]=targetInfo
			AddBias(targetInfo,biasList["group"..unitGroup])
			if isPlayer then
				ryn.targetList.party=ryn.targetList["group"..unitGroup]
				for target,partyInfo in pairs(ryn.targetList.party) do
					AddBias(partyInfo,biasList.party)
				end
			elseif ryn.targetList.party[uid] then
				AddBias(targetInfo,biasList.party)
			end
		else
			ryn.targetList.party[uid]=targetInfo
		end
		
		-- Player
		ryn.targetList[unitName]={}
		ryn.targetList[unitName][uid]=targetInfo
		AddBias(targetInfo,biasList[unitName])
		if isPlayer then
			ryn.targetList.self=ryn.targetList[unitName]
			AddBias(targetInfo,biasList.self)
		end
		
		-- Master
		if unitName==ryn.masterName then
			ryn.targetList.master={}
			ryn.targetList.master[uid]=targetInfo
			AddBias(targetInfo,biasList.master)
			ryn.masterTarget=uid
		end
	end
end

local function GroupManagementHandler()
	--ryn.Debug(event)
	if not targetListReady then
		ryn.BuildTargetList()
	elseif event=="PLAYER_ENTERING_WORLD" or event=="RAID_ROSTER_UPDATE" and UnitInRaid("player") or event=="PARTY_MEMBERS_CHANGED" and not UnitInRaid("player") then
		ryn.UpdateTargetList()
	elseif event=="ACTIONBAR_SLOT_CHANGED" then
		if arg1 then
			ryn.ActionSlotUpdate(arg1)
			--ryn.Debug("Action bar event: Slot"..arg1)
		end
		-- TODO: This shouldn't be here...
	end
end

local gmFrame=CreateFrame("Frame")
gmFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
gmFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
gmFrame:RegisterEvent("RAID_ROSTER_UPDATE")
gmFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
gmFrame:SetScript("OnEvent",GroupManagementHandler)

ryn.BuildTargetList=function()
	targetListReady=false
	
	-- Initialize/reset target list
	InitTargetList()
	
	-- Register players
	if UnitInRaid("player") then
		partyToRaidChack=true
		for i=1,40 do
			if UnitName("raid"..i)=="Unknown" then
				--ryn.Debug("Couldn't build target list. raid"..i.."'s name is unknown.")
				return
			end
			RegisterUnit(true,i)
		end
	else
		partyToRaidChack=false
		RegisterUnit(false,"player")
		if UnitName("player")=="Unknown" then
			--ryn.Debug("Couldn't build target list. player's name is unknown.")
			return
		end
		for i=1,GetNumPartyMembers() do
			RegisterUnit(false,"party"..i)
			if UnitName("party"..i)=="Unknown" then
				--ryn.Debug("Couldn't build target list. party"..i.."'s name is unknown.")
				return
			end
		end
	end
	targetListReady=true
	-- TODO: Make an event handler for spell management, this line should go there.
	ryn.BuildSpellData()
	--ryn.Debug("Target list built")
end

local function UpdatePlayer(uid,info,name,class)
	local role=ryn.GetRole(name)
	local oldRole=info.role
	local oldName=info.name
	local ownName=UnitName("player")
	
	-- Role
	if role~=oldRole then
		info.role=role
		ryn.targetList[role][uid]=info
		ryn.targetList[oldRole][uid]=nil
		AddBias(info,biasList[role])
		RemoveBias(info,biasList[oldRole])
	end
	
	-- Class
	info.class=class
	
	-- Player
	if name~=oldName then -- Just to be safe.
		info.name=name
		
		if not ryn.targetList[name] then
			ryn.targetList[name]={}
		end
		ryn.targetList[name][uid]=info
		ryn.targetList[oldName][uid]=nil
		
		AddBias(info,biasList[name])
		RemoveBias(info,biasList[oldName])
		
		if name==ryn.masterName then
			ryn.targetList.master[uid]=info
			AddBias(info,biasList.master)
			ryn.masterTarget=uid
		elseif oldName==ryn.masterName then
			ryn.targetList.master[uid]=nil
			RemoveBias(info,biasList.master)
		end
		
		if name==ownName then
			ryn.targetList.self[uid]=info
			AddBias(info,biasList.self)
		elseif oldName==ownName then
			ryn.targetList.self[uid]=nil
			RemoveBias(info,biasList.self)
		end
	end
end

local function UpdateGroup(uid,info,groupNum)
	local oldGroupNum=info.group
	local ownName=UnitName("player")

	if groupNum~=0 and oldGroupNum~=0 then -- Just to be safe
		if ownName==info.name then
			for target,partyInfo in pairs(ryn.targetList.party) do
				RemoveBias(partyInfo,biasList.party)
			end
		elseif ryn.targetList.party[uid] then
			RemoveBias(info,biasList.party)
		end
		
		info.group=groupNum
		ryn.targetList["group"..groupNum][uid]=info
		ryn.targetList["group"..oldGroupNum][uid]=nil
		AddBias(info,biasList["group"..groupNum])
		RemoveBias(info,biasList["group"..oldGroupNum])
		
		if ownName==info.name then
			ryn.targetList.party=ryn.targetList["group"..groupNum]
			for target,partyInfo in pairs(ryn.targetList.party) do
				AddBias(partyInfo,biasList.party)
			end
		elseif ryn.targetList.party[uid] then
			AddBias(info,biasList.party)
		end
	end
end

local function RemoveUid(uid)
	local info=ryn.targetList.all[uid]
	local name=info.name
	local group=info.group
	local role=info.role
	
	ryn.targetList.all[uid]=nil
	ryn.targetList[name][uid]=nil
	
	if group==0 then
		ryn.targetList.party[uid]=nil
	else
		ryn.targetList["group"..group][uid]=nil
	end
	ryn.targetList[role][uid]=nil
	if name==ryn.masterName then
		ryn.targetList.master[uid]=nil
		ryn.masterTarget=nil
	end
	if name==UnitName("player") then
		ryn.targetList.self[uid]=nil
	end
end

ryn.UpdateTargetList=function()
	targetListReady=false
	if UnitInRaid("player") then
		if not partyToRaidChack then
			ryn.BuildTargetList()
		else
			for i=1,40 do
				local uid="raid"..i
				if UnitIsConnected(uid) then
					currentTargetInfo=ryn.targetList.all[uid]
					if UnitName(uid)=="Unknown" then
						--ryn.Debug("Couldn't update target list. raid"..i.."'s name is unknown.")
						return
					end
					if not currentTargetInfo then
						RegisterUnit(1,i)
						--ryn.Debug("Added new uid")
					else
						local unitName,_,unitGroup,_,_,unitClass=GetRaidRosterInfo(i)
						if unitName~=currentTargetInfo.name then
							UpdatePlayer(uid,currentTargetInfo,unitName,unitClass)
							--ryn.Debug("Updated player info")
						end
						if unitGroup~=currentTargetInfo.group then
							UpdateGroup(uid,currentTargetInfo,unitGroup)
							--ryn.Debug("Updated player group")
						end
					end
				else
					if ryn.targetList.all[uid] then
						RemoveUid(uid)
						--ryn.Debug("Removed unused uid")
					end
				end
			end
			--ryn.Debug("Target list updated")
		end
	else
		if partyToRaidChack then
			ryn.BuildTargetList()
		else
			for i=1,GetNumPartyMembers() do
				local uid="party"..i
				if UnitIsConnected(uid) then
					if UnitName(uid)=="Unknown" then
						--ryn.Debug("Couldn't update target list. party"..i.."'s name is unknown.")
						return
					end
					currentTargetInfo=ryn.targetList.all[uid]
					if not currentTargetInfo then
						RegisterUnit(false,uid)
						--ryn.Debug("Added new uid")
					else
						local unitName=UnitName(uid)
						local _,unitClass=UnitClass(uid)
						if unitName~=currentTargetInfo.name then
							UpdatePlayer(uid,currentTargetInfo,unitName,unitClass)
							--ryn.Debug("Updated player info")
						end
					end
				else
					if ryn.targetList.all[uid] then
						RemoveUid(uid)
						--ryn.Debug("Removed unused uid")
					end
				end
			end
			--ryn.Debug("Target list updated")
		end
	end
	targetListReady=true
end

ryn.PrintTargetList=function(lTargetList)
	lTargetList=lTargetList or ryn.targetList.all
	DEFAULT_CHAT_FRAME:AddMessage("Target list:")
	local count=0
	for uid,info in pairs(lTargetList) do
		DEFAULT_CHAT_FRAME:AddMessage(uid.." | "..info.name.." | "..info.role.." | "..info.class.." | group"..info.group.." | "..info.bias)
		count=count+1
	end
	ryn.Debug("Players in target list: "..count)
end

ryn.PrintTargetLists=function()
	for listName,list in pairs(ryn.targetList) do
		DEFAULT_CHAT_FRAME:AddMessage("Target list ["..listName.."]:")
		for uid,info in pairs(list) do
			DEFAULT_CHAT_FRAME:AddMessage(uid.." | "..info.name.." | "..info.role.." | "..info.class.." | group"..info.group.." | "..info.bias)
		end
	end
end

ryn.PrintPlayerLists=function()
	local tlCount,realTlCount=0,0
	for listName,list in pairs(ryn.targetList) do
		local firstChar=string.sub(listName,1,1)
		if firstChar==string.upper(firstChar) then
			DEFAULT_CHAT_FRAME:AddMessage("Target list ["..listName.."]:")
			tlCount=tlCount+1
			for uid,info in pairs(list) do
				DEFAULT_CHAT_FRAME:AddMessage(uid.." | "..info.name.." | "..info.role.." | "..info.class.." | group"..info.group.." | "..info.bias)
				realTlCount=realTlCount+1
			end
		end
	end
	ryn.Debug("Total player target lists: "..tlCount..", non-empty: "..realTlCount)
end