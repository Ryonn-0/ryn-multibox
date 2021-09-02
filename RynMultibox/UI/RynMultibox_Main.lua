ryn.mainWindow={}
local mw=ryn.mainWindow

local backdrop={
  bgFile="Interface\\AddOns\\RynMultibox\\Image\\backBlack",tile=true,tileSize=8,
  edgeFile="Interface\\AddOns\\RynMultibox\\Image\\edgeNeonGreen",edgeSize=8,
  insets={left=4,right=4,top=4,bottom=4}
}
local backdropBorderless={
  bgFile="Interface\\AddOns\\RynMultibox\\Image\\backBlack",tile=true,tileSize=8,
  insets={left=0,right=0,top=0,bottom=0}
}
local backdropBorderOnly={
  edgeFile="Interface\\AddOns\\RynMultibox\\Image\\edgeNeonGreen",edgeSize=8,
}

mw.window=CreateFrame("Frame",nil,UIParent)
mw.window:Hide()
--mw.window:Show()
mw.window:SetFrameStrata("DIALOG")
mw.window:SetWidth(200)
mw.window:SetHeight(120)
mw.window:SetBackdrop(backdrop)
mw.window:SetPoint("CENTER",0,0)
mw.window:SetMovable(true)
mw.window:EnableMouse(true)
mw.window:SetScript("OnMouseDown",function()
	mw.window:StartMoving()
end)
mw.window:SetScript("OnMouseUp",function()
	mw.window:StopMovingOrSizing()
end)

mw.window.title=mw.window:CreateFontString("Status","LOW","GameFontNormal")
mw.window.title:ClearAllPoints()
mw.window.title:SetPoint("TOP",0,-12)
mw.window.title:SetFontObject(GameFontWhite)
mw.window.title:SetFont(STANDARD_TEXT_FONT,16,"OUTLINE")
mw.window.title:SetText("|cff39ff14RynMultibox")

ryn.ToggleMainWindow=function()
	if mw.window:IsVisible() then mw.window:Hide() else mw.window:Show() end
	-- TODO: Slash command
end

ryn.CheckButtonFactory=function(name,parent,texture,posX,posY,location,index)
	mw[name]=CreateFrame("CheckButton",nil,parent)
	mw[name]:SetPoint("TOPLEFT",posX,posY)
	mw[name]:SetWidth(32)
	mw[name]:SetHeight(32)
	mw[name]:SetChecked(true)
	mw[name]:SetCheckedTexture(texture)
	mw[name]:SetNormalTexture(texture)
	mw[name]:SetScript("OnClick",function()
		if mw[name]:GetChecked() then location[index]=true else location[index]=false end
		ryn.Sync("syncDamageType")
	end)
end

ryn.CheckButtonFactory("tankEnabled",mw.window,"Interface\\Icons\\Ability_Warrior_DefensiveStance",12,-40,ryn.damageType,"tank")
ryn.CheckButtonFactory("meleeEnabled",mw.window,"Interface\\Icons\\Ability_DualWield",48,-40,ryn.damageType,"melee")
ryn.CheckButtonFactory("rangedEnabled",mw.window,"Interface\\Icons\\Ability_PierceDamage",84,-40,ryn.damageType,"ranged")
ryn.CheckButtonFactory("aoeEnabled",mw.window,"Interface\\Icons\\Ability_Whirlwind",156,-40,ryn.damageType,"aoe")
ryn.CheckButtonFactory("frostEnabled",mw.window,"Interface\\Icons\\Spell_Frost_FrostWard",12,-76,ryn.damageType,"frost")
ryn.CheckButtonFactory("fireEnabled",mw.window,"Interface\\Icons\\Spell_Fire_SealOfFire",48,-76,ryn.damageType,"fire")
ryn.CheckButtonFactory("arcaneEnabled",mw.window,"Interface\\Icons\\Spell_Nature_WispSplode",84,-76,ryn.damageType,"arcane")
ryn.CheckButtonFactory("shadowEnabled",mw.window,"Interface\\Icons\\Spell_Shadow_AntiShadow",120,-76,ryn.damageType,"shadow")
ryn.CheckButtonFactory("natureEnabled",mw.window,"Interface\\Icons\\Spell_Nature_ProtectionformNature",156,-76,ryn.damageType,"nature")