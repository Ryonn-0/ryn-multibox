ryn.default={}
ryn.override={}
ryn.overrideLocal={}
ryn.overrideMode=nil

ryn.RevertOverride=function()
	local revert=false
	for name,func in ryn.default do
		revert=true
		ryn[name]=func
		if name=="ClassEventHandler" then -- Tempfix for event overrides, refactor event system later.
			ryn.classEventFrame:SetScript("OnEvent",ryn.ClassEventHandler)
			if ryn.overrideLocal[mode].overrideEvents then
				for _,event in ipairs(ryn.overrideLocal[ryn.overrideMode].overrideEvents) do
					ryn.classEventFrame:UnregisterEvent(event)
				end
			end
		end
	end
	if revert then
		ryn.default={}
		ryn.overrideMode=nil
		ryn.Debug("Override deactivated")
	end
end

ryn.Override=function(mode)
	ryn.RevertOverride()
	if ryn.override[mode] then
		for name,func in ryn.override[mode] do
			ryn.default[name]=ryn[name]
			ryn[name]=func
			if name=="ClassEventHandler" then -- Tempfix for event overrides, refactor event system later.
				ryn.classEventFrame:SetScript("OnEvent",ryn.ClassEventHandler)
				if ryn.overrideLocal[mode].overrideEvents then
					for _,event in ipairs(ryn.overrideLocal[mode].overrideEvents) do
						ryn.classEventFrame:RegisterEvent(event)
					end
				end
			end
		end
		ryn.Debug("Override activated: "..mode)
		ryn.overrideMode=mode
	else
		ryn.Debug("This override mode does not exist.")
	end
end