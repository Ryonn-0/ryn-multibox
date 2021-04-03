ryn.default={}
ryn.override={}

ryn.RevertOverride=function()
	local revert=false
	for name,func in ryn.default do
		revert=true
		ryn[name]=func
	end
	if revert then
		ryn.default={}
		--ryn.Debug("Override deactivated")
	end
end

ryn.Override=function(mode)
	ryn.RevertOverride()
	for name,func in ryn.override[mode] do
		ryn.default[name]=ryn[name]
		ryn[name]=func
	end
	--ryn.Debug("Override activated: "..mode)
end