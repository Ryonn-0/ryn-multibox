-- Marksmanship Hunter

buffHawk="Interface\\Icons\\Spell_Nature_RavenForm"
buffTrueshot="Interface\\Icons\\Ability_TrueShot"
debuffMark="Interface\\Icons\\Ability_Hunter_SniperShot"

-- Settings
multiShotEnabled=true
aimedShotWindow=0.5 -- low value, with 3.0+ ranged attack speed (full/auto shot rotation), or a higher value with 2.9- ranged attack speed (clipped/aimed shot rotation)
multiShotWindow=2.3 -- should be around ranged attack speed minus 1

-- Action bar slot ids
aimedShotActionSlot=1
autoShotActionSlot=2
multiShotActionSlot=4
autoAttackActionSlot=60
raptorStrikeActionSlot=61
mongooseBiteActionSlot=62

aimedShotExpire=0
multiShotExpire=0
arrowCount=GetInventoryItemCount("player",0)
ignoreNext=false

function HunterEventHandler()
	local newArrowCount=GetInventoryItemCount("player",0)
	if arrowCount~=newArrowCount then
		arrowCount=newArrowCount
		if ignoreNext then
			ignoreNext=false
		else
			--Debug("Auto Shot!")
			aimedShotExpire=GetTime()+aimedShotWindow
			multiShotExpire=GetTime()+multiShotWindow
		end
	end
end

function HunterRangedDps()
	if not IsAutoRepeatAction(autoShotActionSlot) then
		CastSpellByName("Auto Shot")
		ignoreNext=false
		return
	end
	if not IsCurrentAction(aimedShotActionSlot) and not IsCurrentAction(multiShotActionSlot) then
		if aimedShotExpire>=GetTime() and IsActionReady(aimedShotActionSlot) then
			CastSpellByName("Aimed Shot")
			ignoreNext=true
			--Debug("Aimed shot!")
		elseif multiShotEnabled and multiShotExpire>=GetTime() and IsActionReady(multiShotActionSlot) then
			CastSpellByName("Multi-Shot")
			ignoreNext=true
			--Debug("Multi-Shot!")
		end
	end
end

function HunterMeleeDps()
	if IsActionReady(mongooseBiteActionSlot) then
		CastSpellByName("Mongoose Bite")
		--Debug("Mongoose Bite!")
	elseif not IsCurrentAction(raptorStrikeActionSlot) and IsActionReady(raptorStrikeActionSlot) then
		CastSpellByName("Raptor Strike")
		--Debug("Raptor Strike!")
	elseif not IsCurrentAction(autoAttackActionSlot) then
		CastSpellByName("Attack")
		--Debug("Auto Attack!")
	end
end

function HunterDps()
	if IsActionInRange(autoShotActionSlot)==1 then
		HunterRangedDps()
	elseif IsActionInRange(mongooseBiteActionSlot)==1 then
		HunterMeleeDps()
	end
	-- TODO: pet stuff here
end

function HunterBuff()
	if not BuffCheck("player",buffHawk) then
		CastSpellByName("Aspect of the Hawk")
	elseif not BuffCheck("player",buffTrueshot) then
		CastSpellByName("Trueshot Aura")
	end
	--TODO: Add hunter's mark
end