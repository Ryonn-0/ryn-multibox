local class

if ryn.playerClass=="HUNTER" then
class={}

class.buffHawk="Interface\\Icons\\Spell_Nature_RavenForm"
class.buffTrueshot="Interface\\Icons\\Ability_TrueShot"
class.debuffMark="Interface\\Icons\\Ability_Hunter_SniperShot"

-- Settings
class.aimedShotWindow=1 -- low value, with 3.0+ ranged attack speed (full/auto shot rotation), or a higher value with 2.9- ranged attack speed (clipped/aimed shot rotation)
class.multiShotWindow=1.6 -- should be around ranged attack speed minus 1

-- Action bar slot ids
class.aimedShotActionSlot=1
class.autoShotActionSlot=2
class.multiShotActionSlot=4
class.autoAttackActionSlot=60
class.raptorStrikeActionSlot=61
class.mongooseBiteActionSlot=62

class.aimedShotExpire=0
class.multiShotExpire=0
class.arrowCount=GetInventoryItemCount("player",0)
class.ignoreNext=false

class.EventHandler=function()
	local newArrowCount=GetInventoryItemCount("player",0)
	if class.arrowCount~=newArrowCount then
		class.arrowCount=newArrowCount
		if class.ignoreNext then
			class.ignoreNext=false
		else
			class.aimedShotExpire=GetTime()+class.aimedShotWindow
			class.multiShotExpire=GetTime()+class.multiShotWindow
		end
	end
end

class.eventFrame=CreateFrame("Frame")
class.eventFrame:RegisterEvent("BAG_UPDATE")
class.eventFrame:SetScript("OnEvent",class.EventHandler)

ryn.Buff=function()
	if not ryn.BuffCheck("player",class.buffHawk) then
		CastSpellByName("Aspect of the Hawk")
	elseif not ryn.BuffCheck("player",class.buffTrueshot) then
		CastSpellByName("Trueshot Aura")
	end
	--TODO: Add hunter's mark
end

class.RangedDps=function()
	if not IsAutoRepeatAction(class.autoShotActionSlot) then
		CastSpellByName("Auto Shot")
		class.ignoreNext=false
		return
	end
	if not IsCurrentAction(class.aimedShotActionSlot) and not IsCurrentAction(class.multiShotActionSlot) then
		if class.aimedShotExpire>=GetTime() and ryn.IsActionReady(class.aimedShotActionSlot) then
			CastSpellByName("Aimed Shot")
			class.ignoreNext=true
		elseif ryn.aoeEnabled and class.multiShotExpire>=GetTime() and ryn.IsActionReady(class.multiShotActionSlot) then
			CastSpellByName("Multi-Shot")
			class.ignoreNext=true
		end
	end
end

class.MeleeDps=function()
	if ryn.IsActionReady(class.mongooseBiteActionSlot) then
		CastSpellByName("Mongoose Bite")
	elseif not IsCurrentAction(class.raptorStrikeActionSlot) and ryn.IsActionReady(class.raptorStrikeActionSlot) then
		CastSpellByName("Raptor Strike")
	elseif not IsCurrentAction(class.autoAttackActionSlot) then
		CastSpellByName("Attack")
	end
end

ryn.Dps=function()
	if ryn.GetHostileTarget() then
		if ryn.damageType.ranged and IsActionInRange(class.autoShotActionSlot)==1 then
			class.RangedDps()
		elseif ryn.damageType.melee and IsActionInRange(class.mongooseBiteActionSlot)==1 then
			class.MeleeDps()
		end
	end
	-- TODO: pet stuff here
end

end