function Initialize(Plugin)
	Plugin:SetName( "Permissions" )
	Plugin:SetVersion( 5 )

	-- Add webadmin tabs:
	Plugin:AddWebTab("Plugins", HandleRequest_ManageWebPermissions)

	-- Log
	LOG("Initialised " .. Plugin:GetName() .. " v." .. Plugin:GetVersion())

	return true
end

function onDisable()
	LOG(PLUGIN:GetName() .. " disabled.")
end