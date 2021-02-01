-- Group management

masterName="Harklen"
nameList={
	tank={"Harklen","Gaelber","Llanewrynn","Stardancer","Cooperbeard","Naderius","Dobzse","Obier","Yxon","Amonstenn","Fierileya"},
	heal={"Alaniel","Flo","Livia","Hoyt","Myra","Papsajt","Negreanu","Kearlah","Azure","Warrógép","Rhodelya"},
	multiHeal={
	"Paladino","Dreamblast","Skyx","Uyalin","Illumyn", -- Kearlah
	"Baleog","Lionel","Nobleforged","Lightbeard","Moonflower","Bronzecoat", -- Azsgrof
	"Pamelma" -- Dobzse
	},
	multiDps={
	"Dorothy","Tygerra","Havox","Eoro","Livingbomb","Dorkilla","Reimus","Necropoly","Vibranium","Lazarrus","Skyfire", -- Kearlah
	"Azsgrof","Liberton","Leilena","Cromwell","Daemona","Carla","Windou","Jaliana","Fabregas","Pinkypie","Oakheart","Featherfire","Pompedous","Miraclemike","Morbent","Maleficus","Nightleaf","Ravencloud", -- Azsgrof
	"Aedis","Therena","Nien","Lucilde" -- Dobzse
	},
	myMultiHeal={"Ryonn"},
	myMultiDps={"Arvene","Nymira","Inochi","Seloris"}
}

-- targetLists: {all,tank,heal,dps(default),multiHeal,multiDps,myMultiHeal,myMultiDps,party,group<1-8>,<charname>,master,self}   TODO: assist?,class,custom<any>?
-- playerInfo: uid -> {name,role,class,group,bias}

-- Initialize bias list structure
biasList={group={}}

-- Set default global bias values
biasList.tank,biasList.heal,biasList.multiHeal,biasList.multiDps,biasList.myMultiHeal,biasList.myMultiDps=-0.1,-0.07,0.1,0.15,-0.05,-0.02
biasList.Cipola=10000
biasList.Harklen=-0.06
biasList.Alaniel=-0.02
biasList.self=-0.05

-- Test values
--biasList.tank,biasList.heal,biasList.dps,biasList.multiHeal,biasList.multiDps,biasList.myMultiHeal,biasList.myMultiDps=0.1,0.2,0.3,0.4,0.5,0.6,0.7
--biasList.self=0.01
--biasList.master=0.001
--biasList.group={1,2,3,4,5,6,7,8}
--biasList.party=10
--biasList.Alaniel=100

function AddBias(targetInfo,value)
	if value then
		targetInfo.bias=targetInfo.bias+value
	end
end

function RemoveBias(targetInfo,value)
	if value then
		targetInfo.bias=targetInfo.bias-value
	end
end

-- This function should be used in SuperMacro's extended LUA code fields, to easily manage healing biases per healer.
-- I could set biasList as a saved variable, might do it later, but since the addon doesn't have ui elements, the method above is more comfortable to use.
function SetBias(bias,list,groupNum)
	local oldBias
	if list=="group" then
		oldBias=biasList.group[groupNum]
		biasList.group[groupNum]=bias
	else
		oldBias=biasList[list]
		biasList[list]=bias
	end
	if oldBias==bias then
		return
	end
	if targetList then
		if list=="group" then
			for target,info in pairs(targetList.group[groupNum]) do
				RemoveBias(info,oldBias)
				AddBias(info,bias)
			end
		else
			for target,info in pairs(targetList[list]) do
				RemoveBias(info,oldBias)
				AddBias(info,bias)
			end
		end
	end
	--Debug("New bias value set.")
end

function GetRole(name)
	for role,names in pairs(nameList) do
		for i,currentName in ipairs(names) do
			if currentName==name then
				return role
			end
		end
	end
	return "dps"
end

function RegisterUnit(isRaid,raidOrUnitId)
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
		local unitRole=GetRole(unitName)
		local targetInfo={}
		local isPlayer=unitName==UnitName("player")
		targetInfo.name=unitName
		targetInfo.class=unitClass
		targetInfo.group=unitGroup or 0
		targetInfo.role=unitRole
		targetInfo.bias=0
		
		-- Add player to target lists, set bias values
		-- All
		targetList.all[uid]=targetInfo
		
		-- Role
		targetList[unitRole][uid]=targetInfo
		AddBias(targetInfo,biasList[unitRole])
		
		-- Group
		if isRaid then
			targetList.group[unitGroup][uid]=targetInfo
			AddBias(targetInfo,biasList.group[unitGroup])
			if isPlayer then
				targetList.party=targetList.group[unitGroup]
				for target,partyInfo in pairs(targetList.party) do
					AddBias(partyInfo,biasList.party)
				end
			elseif targetList.party[uid] then
				AddBias(targetInfo,biasList.party)
			end
		else
			targetList.party[uid]=targetInfo
		end
		
		-- Player
		targetList[unitName]={}
		targetList[unitName][uid]=targetInfo
		AddBias(targetInfo,biasList[unitName])
		if isPlayer then
			targetList.self=targetList[unitName]
			AddBias(targetInfo,biasList.self)
		end
		
		-- Master
		if unitName==masterName then
			targetList.master={}
			targetList.master[uid]=targetInfo
			AddBias(targetInfo,biasList.master)
			masterTarget=uid
		end
	end
end

function GroupManagementHandler()
	--Debug(event)
	if not targetList then
		BuildTargetList()
	elseif event=="PLAYER_ENTERING_WORLD" or event=="RAID_ROSTER_UPDATE" and UnitInRaid("player") or event=="PARTY_MEMBERS_CHANGED" and not UnitInRaid("player") then
		UpdateTargetList()
	end
end

function BuildTargetList()
	-- Initialize/reset target list
	targetList={all={},group={},party={},master={},self={}}
	for role,names in pairs(nameList) do
		targetList[role]={}
	end
	for i=1,8 do
		targetList.group[i]={}
	end
	
	-- Register players
	if UnitInRaid("player") then
		partyToRaidChack=true
		for i=1,40 do
			if UnitName("raid"..i)=="Unknown" then
				--Debug("Couldn't build target list. raid"..i.."'s name is unknown.")
				targetList=nil
				return
			end
			RegisterUnit(true,i)
		end
	else
		partyToRaidChack=false
		RegisterUnit(false,"player")
		if UnitName("player")=="Unknown" then
			--Debug("Couldn't build target list. player's name is unknown.")
			targetList=nil
			return
		end
		for i=1,GetNumPartyMembers() do
			RegisterUnit(false,"party"..i)
			if UnitName("party"..i)=="Unknown" then
				--Debug("Couldn't build target list. party"..i.."'s name is unknown.")
				targetList=nil
				return
			end
		end
	end
	-- TODO: Put this somewhere else
	local _,unitClass=UnitClass("player")
	if unitClass=="HUNTER" and not IsAddOnLoaded("RynMultibox_Hunter") then
		LoadAddOn("RynMultibox_Hunter")
	end
	InitHealProfiles()
	BuildSpellData()
	--Debug("Target list built")
end

function UpdateTargetList()
	if UnitInRaid("player") then
		if not partyToRaidChack then
			BuildTargetList()
		else
			for i=1,40 do
				local uid="raid"..i
				if UnitIsConnected(uid) then
					currentTargetInfo=targetList.all[uid]
					if UnitName(uid)=="Unknown" then
						--Debug("Couldn't update target list. raid"..i.."'s name is unknown.")
						return
					end
					if not currentTargetInfo then
						RegisterUnit(1,i)
						--Debug("Added new uid")
					else
						local unitName,_,unitGroup,_,_,unitClass=GetRaidRosterInfo(i)
						if unitName~=currentTargetInfo.name then
							UpdatePlayer(uid,currentTargetInfo,unitName,unitClass)
							--Debug("Updated player info")
						end
						if unitGroup~=currentTargetInfo.group then
							UpdateGroup(uid,currentTargetInfo,unitGroup)
							--Debug("Updated player group")
						end
					end
				else
					if targetList.all[uid] then
						RemoveUid(uid)
						--Debug("Removed unused uid")
					end
				end
			end
			--Debug("Target list updated")
		end
	else
		if partyToRaidChack then
			BuildTargetList()
		else
			for i=1,GetNumPartyMembers() do
				local uid="party"..i
				if UnitIsConnected(uid) then
					if UnitName(uid)=="Unknown" then
						--Debug("Couldn't update target list. party"..i.."'s name is unknown.")
						return
					end
					currentTargetInfo=targetList.all[uid]
					if not currentTargetInfo then
						RegisterUnit(false,uid)
						--Debug("Added new uid")
					else
						local unitName=UnitName(uid)
						local _,unitClass=UnitClass(uid)
						if unitName~=currentTargetInfo.name then
							UpdatePlayer(uid,currentTargetInfo,unitName,unitClass)
							--Debug("Updated player info")
						end
					end
				else
					if targetList.all[uid] then
						RemoveUid(uid)
						--Debug("Removed unused uid")
					end
				end
			end
			--Debug("Target list updated")
		end
	end
end

function UpdatePlayer(uid,info,name,class)
	local role=GetRole(name)
	local oldRole=info.role
	local oldName=info.name
	local ownName=UnitName("player")
	
	-- Role
	if role~=oldRole then
		info.role=role
		targetList[role][uid]=info
		targetList[oldRole][uid]=nil
		AddBias(info,biasList[role])
		RemoveBias(info,biasList[oldRole])
	end
	
	-- Class
	info.class=class
	
	-- Player
	if name~=oldName then -- Just to be safe.
		info.name=name
		
		if not targetList[name] then
			targetList[name]={}
		end
		targetList[name][uid]=info
		targetList[oldName][uid]=nil
		
		AddBias(info,biasList[name])
		RemoveBias(info,biasList[oldName])
		
		if name==masterName then
			targetList.master[uid]=info
			AddBias(info,biasList.master)
			masterTarget=uid
		elseif oldName==masterName then
			targetList.master[uid]=nil
			RemoveBias(info,biasList.master)
		end
		
		if name==ownName then
			targetList.self[uid]=info
			AddBias(info,biasList.self)
		elseif oldName==ownName then
			targetList.self[uid]=nil
			RemoveBias(info,biasList.self)
		end
	end
end

function UpdateGroup(uid,info,groupNum)
	local oldGroupNum=info.group
	local ownName=UnitName("player")

	if groupNum~=0 and oldGroupNum~=0 then -- Just to be safe
		if ownName==info.name then
			for target,partyInfo in pairs(targetList.party) do
				RemoveBias(partyInfo,biasList.party)
			end
		elseif targetList.party[uid] then
			RemoveBias(info,biasList.party)
		end
		
		info.group=groupNum
		targetList.group[groupNum][uid]=info
		targetList.group[oldGroupNum][uid]=nil
		AddBias(info,biasList.group[groupNum])
		RemoveBias(info,biasList.group[oldGroupNum])
		
		if ownName==info.name then
			targetList.party=targetList.group[groupNum]
			for target,partyInfo in pairs(targetList.party) do
				AddBias(partyInfo,biasList.party)
			end
		elseif targetList.party[uid] then
			AddBias(info,biasList.party)
		end
	end
end

function RemoveUid(uid)
	local info=targetList.all[uid]
	local name=info.name
	local group=info.group
	local role=info.role
	
	targetList.all[uid]=nil
	targetList[name][uid]=nil
	
	if group==0 then
		targetList.party[uid]=nil
	else
		targetList.group[group][uid]=nil
	end
	targetList[role][uid]=nil
	if name==masterName then
		targetList.master[uid]=nil
	end
	if name==UnitName("player") then
		targetList.self[uid]=nil
	end
end

function PrintTargetList(targetList)
	DEFAULT_CHAT_FRAME:AddMessage("Target list:")
	local count=0
	for uid,info in pairs(targetList) do
		DEFAULT_CHAT_FRAME:AddMessage(uid.." | "..info.name.." | "..info.role.." | "..info.class.." | group"..info.group.." | "..info.bias)
		count=count+1
	end
	Debug("Players in target list: "..count)
end

function PrintTargetLists()
	for listName,list in pairs(targetList) do
		if listName=="group" then
			for i=1,8 do
				DEFAULT_CHAT_FRAME:AddMessage("Target list [group["..i.."]]:")
				for uid,info in pairs(list[i]) do
					DEFAULT_CHAT_FRAME:AddMessage(uid.." | "..info.name.." | "..info.role.." | "..info.class.." | group"..info.group.." | "..info.bias)
				end
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("Target list ["..listName.."]:")
			for uid,info in pairs(list) do
				DEFAULT_CHAT_FRAME:AddMessage(uid.." | "..info.name.." | "..info.role.." | "..info.class.." | group"..info.group.." | "..info.bias)
			end
		end
	end
end

function PrintPlayerLists()
	local tlCount,realTlCount=0,0
	for listName,list in pairs(targetList) do
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
	Debug("Total player target lists: "..tlCount..", non-empty: "..realTlCount)
end