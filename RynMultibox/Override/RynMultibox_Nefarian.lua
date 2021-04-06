ryn.override.nefarian={}
ryn.overrideLocal.nefarian={}
local nefOverride=ryn.override.nefarian
local nef=ryn.overrideLocal.nefarian

nef.engagePrefix="Well done"
nef.classCallPrefixes={
	druid="Druids",hunter="Hunters",mage="Mages",priest="Priests",paladin="Paladins",
	rogue="Rogues",shaman="Shamans",warrior="Warriors",warlock="Warlocks"
}

if ryn.playerClass=="PRIEST" then
	nef.overrideEvents={"CHAT_MSG_MONSTER_YELL"}
	nef.classCallExpire=GetTime()
	nefOverride.ClassEventHandler=function()
		ryn.default.ClassEventHandler()
		if event=="CHAT_MSG_MONSTER_YELL" and string.find(arg1,nef.classCallPrefixes.priest,1,1) then
			nef.classCallExpire=GetTime()+30
		end
	end
	nefOverride.Heal=function(lTargetList,healProfile)
		if nef.classCallExpire>=GetTime() then
			if ryn.currentHealFinish then
				SpellStopCasting()
				ryn.stopCastingDelayExpire=GetTime()+ryn.stopCastingDelay
			else
				ryn.default.Heal(lTargetList,"instantOnly")
			end
		else
			ryn.default.Heal(lTargetList,healProfile)
		end
	end
	nefOverride.HealOrDispel=function(lTargetList,healProfile,dispelTypes,dispelByHp,dispelHpThreshold)
		if nef.classCallExpire>=GetTime() then
			if ryn.currentHealFinish then
				SpellStopCasting()
				ryn.stopCastingDelayExpire=GetTime()+ryn.stopCastingDelay
			else
				ryn.default.HealOrDispel(lTargetList,"instantOnly",dispelTypes,dispelByHp,dispelHpThreshold)
			end
		else
			ryn.default.HealOrDispel(lTargetList,healProfile,dispelTypes,dispelByHp,dispelHpThreshold)
		end
	end
elseif ryn.playerClass=="MAGE" then
	nef.overrideEvents={"CHAT_MSG_MONSTER_YELL"}
	nef.classCallExpire=GetTime()
	nefOverride.ClassEventHandler=function()
		ryn.default.ClassEventHandler()
		if event=="CHAT_MSG_MONSTER_YELL" and ryn.SpellExists("Ice Block") and string.find(arg1,nef.classCallPrefixes.mage,1,1) then
			nef.classCallExpire=GetTime()+30
		end
	end
	nefOverride.Dps=function()
		if nef.classCallExpire>=GetTime() and ryn.GetSpellCooldownByName("Ice Block")==0 then
			CastSpellByName("Ice Block")
		else
			ryn.default.Dps()
		end
	end
elseif ryn.playerClass=="WARRIOR" then
	nefOverride.TankDps=function()
		local _,_,defStance,usable=GetShapeshiftFormInfo(2)
		if not defStance and usable then
			CastSpellByName("Defensive Stance")
		else
			ryn.default.TankDps()
		end
	end
elseif ryn.playerClass=="HUNTER" then
	nef.overrideEvents={"CHAT_MSG_MONSTER_YELL"}
	nef.nextCall=nil
	nef.itemLink=GetInventoryItemLink("player",18)
	nef.unequipTime=2.5
	nef.reequipTime=1
	nef.timeoutTime=5
	nefOverride.ClassEventHandler=function()
		ryn.default.ClassEventHandler()
		if event=="CHAT_MSG_MONSTER_YELL" then
			if string.find(arg1,nef.engagePrefix,1,1) then
				nef.nextCall=GetTime()+35 -- Not sure about this value
			else
				local called=false
				for _,callPrefix in nef.classCallPrefixes do
					called=string.find(arg1,callPrefix,1,1)
					if called then
						nef.nextCall=GetTime()+25
						break
					end
				end
			end
		end
	end
	nefOverride.Dps=function()
		if nef.nextCall then
			local t=GetTime()
			nef.itemLink=GetInventoryItemLink("player",18) or nef.itemLink
			if nef.nextCall+10+nef.timeoutTime<=t then
				ryn.EquipItemByItemLink(nef.itemLink,18)
				nef.nextCall=nil
			elseif nef.nextCall-nef.unequipTime<=t then
				ryn.UnequipItemBySlotId(18)
			elseif nef.nextCall-25+nef.reequipTime<=t then
				ryn.EquipItemByItemLink(nef.itemLink,18)
			end
		end
		ryn.default.Dps()
	end
end