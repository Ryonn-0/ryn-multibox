if ryn.playerClass=="WARRIOR" then
local ryn=ryn

--ryn.autoAttackActionSlot=81
--ryn.heroicStrikeActionSlot=85
--ryn.shieldSlamActionSlot=86
--ryn.revengeActionSlot=87
--ryn.sunderArmorActionSlot=88

ryn.ClassActionSlotInit=function()
	ryn.autoAttackActionSlot=ryn.GetActionSlot("Attack")
	--ryn.Debug(ryn.autoAttackActionSlot)
	ryn.heroicStrikeActionSlot=ryn.GetActionSlot("Heroic Strike")
	--ryn.Debug(ryn.heroicStrikeActionSlot)
	ryn.shieldSlamActionSlot=ryn.GetActionSlot("Shield Slam")
	--ryn.Debug(ryn.shieldSlamActionSlot)
	ryn.revengeActionSlot=ryn.GetActionSlot("Revenge")
	--ryn.Debug(ryn.revengeActionSlot)
	ryn.sunderArmorActionSlot=ryn.GetActionSlot("Sunder Armor")
	--ryn.Debug(ryn.sunderArmorActionSlot)
end

ryn.rageBuffer=0

ryn.TankDps=function()
	if ryn.damageType.tank then
		local rage=UnitMana("player")
		if rage>=50+ryn.rageBuffer and not IsCurrentAction(ryn.heroicStrikeActionSlot) then
			CastSpellByName("Heroic Strike")
		elseif rage>=20+ryn.rageBuffer and ryn.IsActionReady(ryn.shieldSlamActionSlot) then
			CastSpellByName("Shield Slam")
		elseif rage>=5+ryn.rageBuffer and ryn.IsActionReady(ryn.revengeActionSlot) then
			CastSpellByName("Revenge")
		elseif rage>=12+ryn.rageBuffer and ryn.IsActionReady(ryn.sunderArmorActionSlot) then
			CastSpellByName("Sunder Armor")
		elseif not IsCurrentAction(ryn.autoAttackActionSlot) then
			CastSpellByName("Attack")
		end
	elseif IsCurrentAction(ryn.autoAttackActionSlot) then
		CastSpellByName("Attack")
	end
end

ryn.Taunt=function()
	if not UnitIsUnit("player","targettarget") then
		CastSpellByName("Taunt")
	end
end

end