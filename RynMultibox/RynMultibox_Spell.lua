-- Spell management
-- TODO: Action slot mapping and pet abilities

-- spellName -> {spellID,bookType,actionSlot}
spellData={}

function BuildSpellData()
	local i=1
	local maxSpell,maxRank=nil,nil
	while true do
		local spellName,spellRank=GetSpellName(i,BOOKTYPE_SPELL);
		if not spellName then
			if maxSpell then
				spellData[maxSpell]=spellData[maxSpell.."("..maxRank..")"]
				if strfind(maxRank,")",-1) then
					spellData[maxSpell.."()"].spellId=i
				end
			end
			break
		end
		if maxSpell and spellName~=maxSpell then
			spellData[maxSpell]=spellData[maxSpell.."("..maxRank..")"]
			if strfind(maxRank,")",-1) then
				spellData[maxSpell.."()"].spellId=i
			end
			maxSpell,maxRank=nil,nil
		end
		if strfind(spellRank,"Rank",1,1) then
			maxSpell,maxRank=spellName,spellRank
			spellData[spellName.."("..spellRank..")"]={spellId=i,bookType="BOOKTYPE_SPELL"}
		elseif spellRank~="Passive" and spellRank~="Racial Passive" then
			maxSpell,maxRank=nil,nil
			spellData[spellName]={spellId=i,bookType="BOOKTYPE_SPELL"}
		end
		i=i+1
	end
	--for name,info in pairs(spellData) do
	--	local s=info.spellId..": "..name
	--	Debug(s)
	--end
end

function GetSpellCooldownByName(spellName)
	return GetSpellCooldown(spellData[spellName].spellId,spellData[spellName].bookType)
end