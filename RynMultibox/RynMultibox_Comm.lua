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

local function Serialize(commType)
	local s
	if commType=="syncDamageType" then
		s="\1"
		s=s..Encode(ryn.damageType)
	else
		ryn.Debug("Unknown command type.")
	end
	if string.len(s)<=251 then return s end
	ryn.Debug("Can't serialize data. The encoded string is too long.")
end

local function Deserialize(s)
	local commType,data
	commType,s=ReadChars(s,1)
	if commType=="\1" then
		data,s=Decode(s)
		if string.len(s)==0 then
			return "syncDamageType",data
		end
		ryn.Debug("Something went wrong with deserialization.")
		return
	end
	ryn.Debug("Unknown command type.")
end

local snycPending=nil

local commFrame=CreateFrame("Frame")
commFrame:RegisterEvent("CHAT_MSG_ADDON")
commFrame:SetScript("OnEvent",function()
	if arg1~="ryn" or UnitName("player")==arg4 then return end
	-- TODO: Character validation
	local commType,data=Deserialize(arg2)
	if syncPending==commType then return end
	--ryn.Debug("RECV: "..commType.." "..GetTime())
	
	if commType=="syncDamageType" then
		for k,v in pairs(data) do
			ryn.damageType[k]=v
			ryn.mainWindow[k.."Enabled"]:SetChecked(v)
		end
	end
end)

local function Sync(commType)
	local commData=Serialize(commType)
	--ryn.Debug("SEND: syncDamageType "..GetTime())
	SendAddonMessage("ryn",commData,"RAID")
end

local syncDelay=0.5
local elapsed=0
local timerFrame=CreateFrame("Frame")
timerFrame:Hide()
timerFrame:SetScript("OnUpdate",function()
	elapsed=elapsed+arg1
	if elapsed>=syncDelay then
		Sync(syncPending)
		timerFrame:Hide()
		syncPending=nil
	end
end)

ryn.Sync=function(commType)
	if syncPending~=commType then
		if syncPending then Sync(syncPending) end
		syncPending=commType
	end
	elapsed=0
	timerFrame:Show()
end