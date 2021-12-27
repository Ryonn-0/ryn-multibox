local ryn=ryn

ryn.override.nefarian={}
ryn.overrideLocal.nefarian={}
local nefOverride=ryn.override.nefarian
local nef=ryn.overrideLocal.nefarian

nef.aggroPrefix="Let the"
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
	nef.unequipTime=1.5
	nef.reequipTime=0.5
	--nef.timeoutTime=1
	nef.Equip=function()
		local equipped=GetInventoryItemLink("player",18)
		nef.itemLink=equipped or nef.itemLink
		if not equipped then
			ryn.Debug("NOT EQUIPPED")
			if not ryn.EquipItemByItemLink(nef.itemLink,18) then
				SendChatMessage("Equip a ranged weapon!","SAY")
				ryn.Debug("FAILED TO EQUIP")
			end
		end
	end
	nefOverride.ClassEventHandler=function()
		ryn.default.ClassEventHandler()
		if event=="CHAT_MSG_MONSTER_YELL" then
			ryn.Debug("YELL")
			if string.find(arg1,nef.aggroPrefix,1,1) then
				ryn.Debug("AGGRO")
				nef.Equip()
			elseif string.find(arg1,nef.engagePrefix,1,1) then
				ryn.Debug("ENGAGE")
				nef.Equip()
				ryn.Timer(35-nef.unequipTime,ryn.UnequipItemBySlotId,18) -- Not sure about this value
			else
				local called=false
				for _,callPrefix in nef.classCallPrefixes do
					called=string.find(arg1,callPrefix,1,1)
					if called then
						--ryn.Timer(35+nef.timeoutTime,nef.Equip)
						ryn.Debug("CALL")
						ryn.Timer(25-nef.unequipTime,ryn.UnequipItemBySlotId,18)
						ryn.Timer(nef.reequipTime,nef.Equip)
						break
					end
				end
			end
		end
	end
end