local ryn=ryn

local commandList={
	syncDamageType={name="syncDamageType",id="\1",transmitMode="delayed",data=ryn.damageType,func=function(d)
		for k,v in pairs(d) do
			ryn.damageType[k]=v
			ryn.mainWindow[k.."Enabled"]:SetChecked(v)
		end
	end},
	requestSpell={name="requestSpell",id="\2",transmitMode="instant",func=function(spell,sender) -- param format: string (The requested spell's name)
		if type(spell)~="string" then return end
		if ryn.SpellExists(spell) then
			if not ryn.requestedSpell or GetTime()-ryn.requestReceived>=15 then
				ryn.requestedSpell=spell
				ryn.requestSender=sender
				ryn.requestReceived=GetTime()
				SendChatMessage("Request received!","SAY")
			else
				SendChatMessage("Another spell request is currently active! (Timeout in "..math.ceil(ryn.requestReceived+15-GetTime()).." s)","SAY")
			end
		end
	end}
}

local commandListById={}
for _,commData in pairs(commandList) do
	commandListById[commData.id]=commData
end

local function ReadChars(str,chars)
	return string.sub(str,1,chars),string.sub(str,chars+1,-1)
end

local function Encode(data)
	local s,dataType="",type(data)
	if dataType=="nil" then
		s=s.."\1"
	elseif dataType=="boolean" then
		if data then s=s.."\2" else s=s.."\3" end
	elseif dataType=="string" then
		s=s.."\4"..string.char(string.len(data)+1)..data
	elseif dataType=="number" then
		local numStr=tostring(data)
		s=s.."\5"..string.char(string.len(numStr)+1)..numStr
	elseif dataType=="table" then
		s=s.."\6"
		for key,val in pairs(data) do
			s=s..Encode(key)
			s=s..Encode(val)
		end
		s=s.."\7"
	else
		ryn.Debug("Cannot encode type: "..dataType)
	end
	return s
end

local function Decode(data)
	local var
	local dataType,data=ReadChars(data,1)
	if dataType=="\1" then var=nil
	elseif dataType=="\2" then var=true
	elseif dataType=="\3" then var=false
	elseif dataType=="\4" then
		local l
		l,data=ReadChars(data,1)
		l=string.byte(l)-1
		var,data=ReadChars(data,l)
	elseif dataType=="\5" then
		local l
		l,data=ReadChars(data,1)
		l=string.byte(l)-1
		var,data=ReadChars(data,l)
		var=tonumber(var)
	elseif dataType=="\6" then
		var={}
		while true do
			local key,val
			key,data=Decode(data)
			if not key then break end
			val,data=Decode(data)
			var[key]=val
		end
	elseif dataType=="\7" then
		-- table end
	else
		ryn.Debug("Decoding error! Unknown data type.")
	end
	return var,data
end

local function Serialize(commType,p)
	local s,data
	local comm=commandList[commType]
	if comm then
		s=comm.id
		data=comm.data or p
		s=s..Encode(data)
	else
		ryn.Debug("Unknown command type.")
	end
	if string.len(s)<=251 then return s end
	ryn.Debug("Can't serialize data. The encoded string is too long.")
end

local function Deserialize(s)
	local commId,data,comm
	commId,s=ReadChars(s,1)
	comm=commandListById[commId]
	if comm then
		data,s=Decode(s)
		if string.len(s)==0 then
			return comm.name,data,comm.func
		end
		ryn.Debug("Something went wrong with deserialization.")
		return
	end
	ryn.Debug("Unknown command type.")
end

local syncPending={}

local commFrame=CreateFrame("Frame")
commFrame:RegisterEvent("CHAT_MSG_ADDON")
commFrame:SetScript("OnEvent",function()
	if arg1~="ryn" or UnitName("player")==arg4 then return end
	-- TODO: Character validation
	local commType,data,func=Deserialize(arg2)
	if ryn.IsActiveTimer(syncPending[commType]) then return end
	--ryn.Debug("RECV: "..commType.." "..GetTime())
	func(data,arg4)
end)

local function Sync(args)
	local commData=Serialize(args.commType,args.p)
	SendAddonMessage("ryn",commData,"RAID")
end

ryn.Sync=function(commType,p)
	if commandList[commType].transmitMode=="instant" then
		Sync({commType=commType,p=p})
	else --transmitMode=="delayed"
		syncPending[commType]=ryn.Timer(0.5,Sync,{commType=commType,p=p},syncPending[commType],2)
	end
end