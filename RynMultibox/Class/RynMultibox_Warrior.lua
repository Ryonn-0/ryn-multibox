local class

if ryn.playerClass=="WARRIOR" then
class={}

class.autoAttackActionSlot=81
class.heroicStrikeActionSlot=85
class.shieldSlamActionSlot=86
class.revengeActionSlot=87
class.sunderArmorActionSlot=88
class.rageBuffer=0

ryn.TankDps=function()
	if ryn.damageType.melee then
		local rage=UnitMana("player")
		if rage>=35+class.rageBuffer and not IsCurrentAction(class.heroicStrikeActionSlot) then
			CastSpellByName("Heroic Strike")
		elseif rage>=5+class.rageBuffer and ryn.IsActionReady(class.revengeActionSlot) then
			CastSpellByName("Revenge")
		elseif rage>=20+class.rageBuffer and ryn.IsActionReady(class.shieldSlamActionSlot) then
			CastSpellByName("Shield Slam")
		elseif rage>=12+class.rageBuffer and ryn.IsActionReady(class.sunderArmorActionSlot) then
			CastSpellByName("Sunder Armor")
		elseif not IsCurrentAction(class.autoAttackActionSlot) then
			CastSpellByName("Attack")
		end
	end
end

ryn.Taunt=function()
	if not UnitIsUnit("player","targettarget") then
		CastSpellByName("Taunt")
	end
end

end