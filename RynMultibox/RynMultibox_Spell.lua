-- Spell management

-- TODO: Action slot mapping and pet abilities
-- spellName -> {spellID,bookType}
local spellData={}

ryn.BuildSpellData=function()
	local i=1
	local maxSpell,maxRank=nil,nil
	while true do
		local spellName,spellRank=GetSpellName(i,BOOKTYPE_SPELL);
		if maxSpell and spellName~=maxSpell then
			spellData[maxSpell]=spellData[maxSpell.."("..maxRank..")"]
			maxSpell,maxRank=nil,nil
		end
		if not spellName then
			break
		end
		local spellDataKey
		if strfind(spellRank,"Rank",1,1) then
			maxSpell,maxRank=spellName,spellRank
			spellDataKey=spellName.."("..spellRank..")"
			spellData[spellDataKey]={spellId=i,bookType="BOOKTYPE_SPELL"}
		elseif spellRank~="Passive" and spellRank~="Racial Passive" then
			maxSpell,maxRank=nil,nil
			spellDataKey=spellName
			spellData[spellDataKey]={spellId=i,bookType="BOOKTYPE_SPELL"}
			if strfind(spellDataKey,")",-1) then
				spellData[spellDataKey.."()"]=spellData[spellDataKey]
			end
		end
		i=i+1
	end
end

ryn.GetSpellIdEntries=function(pSpellId)
	for name,info in pairs(spellData) do
		if not pSpellId or info.spellId==pSpellId then
			local s=info.spellId..": "..name
			if info.castTime then
				s=s.." | Cast: "..info.castTime.."s"
			end
			Debug(s)
		end
	end
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
	return nil
end