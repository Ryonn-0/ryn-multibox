ryn.override.nefarian={}
local nef=ryn.override.nefarian

if ryn.playerClass=="PRIEST" then
	nef.classCallExpire=GetTime()
	nef.ClassEventHandler=function()
		ryn.default.ClassEventHandler()
		if event=="CHAT_MSG_MONSTER_YELL" and arg1=="Priests! If you're going to keep healing like that, we might as well make it a little more interesting!" then
			nef.classCallExpire=GetTime()+30
		end
	end
	nef.Heal=function(lTargetList,healProfile)
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
	nef.HealOrDispel=function(lTargetList,healProfile,dispelTypes,dispelByHp,dispelHpThreshold)
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
	nef.classCallExpire=GetTime()
	nef.ClassEventHandler=function()
		ryn.default.ClassEventHandler()
		if event=="CHAT_MSG_MONSTER_YELL" and ryn.SpellExists("Ice Block") and arg1=="Mages too? You should be more careful when you play with magic..." then
			nef.classCallExpire=GetTime()+30
		end
	end
	nef.Dps=function()
		if nef.classCallExpire>=GetTime() and ryn.GetSpellCooldownByName("Ice Block")==0 then
			CastSpellByName("Ice Block")
		else
			ryn.default.Dps()
		end
	end
elseif ryn.playerClass=="WARRIOR" then
	nef.TankDps=function()
		local _,_,defStance,usable=GetShapeshiftFormInfo(2)
		if not defStance and usable then
			ryn.Debug(usable)
			CastSpellByName("Defensive Stance")
		else
			ryn.default.TankDps()
		end
	end
-- TODO:
--   - Hunter call: Hunters should unequip their weapons before class calls, and re-equip them after (this will be a pain to implement...)
end