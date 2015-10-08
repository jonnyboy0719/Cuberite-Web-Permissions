local ins = table.insert
local con = table.concat

-- Lets count how many plugins have info.lua
local CounterInfo = -1

-- Globalize it, so we can call it anywhere on the plugin!
local js_stuff = [[
	<script type="text/javascript" language="javascript" src="/datatables/jquery.js"></script>
	<script type="text/javascript" language="javascript" src="/datatables/jquery.dataTables.js"></script>
	
	<link rel="stylesheet" type="text/css" href="/datatables/css/jquery.dataTables.css">
	<script type="text/javascript" language="javascript" class="init">

$(document).ready(function() {
	$('#plugin_table').dataTable( {
		"paging":   true,
		"ordering": false,
		"info":     true,
		stateSave: true,
		"language": {
            "lengthMenu": "Display _MENU_ commands per page",
            "zeroRecords": "Nothing found - sorry",
            "info": "Showing page _PAGE_ of _PAGES_",
            "infoEmpty": "No commands available",
            "infoFiltered": "(filtered from _MAX_ total commands)"
        }
	} );
} );

	</script>
	]]

-- some error messages
local error_messages = {}

error_messages[1] = {
	msg = "This command do not show a permission!",
	color = "red"
}

error_messages[0] = {
	msg = "The permission you are trying to apply already exist within the group!",
	color = "black"
}

function AssignButton(a_SubpageName, a_ButtonText, a_Permission, a_Permission_Table, a_RquestPath)
	local EnableTable = false
	local StringOnly = false
	local Disabled = false
	
	-- Check params:
	assert(type(a_SubpageName) == "string")
	assert(type(a_ButtonText) == "string")
	
	if a_Permission then
		assert(type(a_Permission) == "string")
		StringOnly = true
	end
	
	-- not working as of yet, so lets disable it for now
	if a_Permission_Table and not StringOnly then
		assert(type(a_Permission_Table or {}) == "table")
--		EnableTable = true
		Disabled = true
	end
	
	if Disabled then
		return ""
	end
	
	assert(type(a_RquestPath) == "string")
	
	local res = {"<a href='/" .. a_RquestPath .. "?subpage=" .. a_SubpageName}
	if EnableTable then
		ins(res, "&Table=" .. cWebAdmin:GetHTMLEscapedString(con(a_Permission_Table)) .. "'><input type='submit' value='")
	elseif StringOnly then
		ins(res, "&Permission=" .. cWebAdmin:GetHTMLEscapedString(a_Permission) .. "'><input type='submit' value='")
	else
		ins(res, "'><input type='submit' value='")
	end
	ins(res, cWebAdmin:GetHTMLEscapedString(a_ButtonText))
	ins(res, "'/></a>")
	
	return con(res)
end

function AssignButtonGroup(a_SubpageName, a_ButtonText, a_Permission, a_Group, a_RquestPath)
	-- Check params:
	assert(type(a_SubpageName) == "string")
	assert(type(a_ButtonText) == "string")
	assert(type(a_Permission) == "string")
	assert(type(a_Group) == "string")
	assert(type(a_RquestPath) == "string")
	
	local res = {"<a href='/" .. a_RquestPath .. "?subpage=" .. a_SubpageName}
	ins(res, "&Permission=" .. cWebAdmin:GetHTMLEscapedString(a_Permission) .. "&Group=" .. cWebAdmin:GetHTMLEscapedString(a_Group) .. "'><input type='submit' value='")
	ins(res, cWebAdmin:GetHTMLEscapedString(a_ButtonText))
	ins(res, "'/></a>")
	
	return con(res)
end

-- Tableprint, if we want to debug
function tableprint ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

-- Lets show the subcommands
local function ShowSubCommands(a_SubCommands)
	local Row = {}
	-- Debug
--	tableprint(a_SubCommands)
	if a_SubCommands then
		for string, table in pairs(a_SubCommands) do
			if (table.Permission) then
				ins(Row, "<span>" .. string .. " - " .. table.Permission .. "<span></br>")
			end
			if (table.Subcommands) then
				ins(Row, ShowSubCommands(table.Subcommands))
			end
		end
	else
		ins(Row, "<b><span style='color: " .. error_messages[1].color .. "'>ERR: " .. error_messages[1].msg .. "</span></b>")
	end
	return con(Row)
end

local function GetPlugins(a_Request)

	-- Lets make sure CounterInfo is always on 0 on start, not -1
	CounterInfo = 0

	local Row = {}
	local Row_tables = {}
	
	local modified_js_stuff = [[
			<script type="text/javascript" language="javascript" src="/datatables/jquery.js"></script>
			<script type="text/javascript" language="javascript" src="/datatables/jquery.dataTables.js"></script>
			
			<link rel="stylesheet" type="text/css" href="/datatables/css/jquery.dataTables.css">
			<script type="text/javascript" language="javascript" class="init">

		$(document).ready(function() {
			$('#plugin_table').dataTable( {
				"paging":   true,
				"ordering": false,
				"info":     true,
				stateSave: true,
				"language": {
					"lengthMenu": "Display _MENU_ commands per page",
					"zeroRecords": "Nothing found - sorry",
					"info": "Showing page _PAGE_ of _PAGES_",
					"infoEmpty": "No commands available",
					"infoFiltered": "(filtered from _MAX_ total commands)"
				}
			} );
		} );

			</script>
	]]
	
	ins(Row_tables, modified_js_stuff)
	ins(Row_tables, "<table id='plugin_table' border='0' cellpadding='8' cellspacing='1' width='100%'>")
	ins(Row_tables, "<thead><tr><th>Plugin</th><th>Commands</th><th>Permissions</th><th>Help Strings</th><th>Assign to Group</th></tr></thead>")
	ins(Row_tables, "<tbody>")
	
	ins(Row, "<table>")
	-- Lets grab all plugin permission, commands and help strings
	cPluginManager:ForEachPlugin(
		function(a_Plugin)
			if (not cFile:IsFile(a_Plugin:GetLocalFolder() .. "/Info.lua")) then
				-- The plugin doesn't have a Info.lua file
				return false
			end
			
			-- We don't want to load plugins that isn't enabled
			if (not a_Plugin:IsLoaded()) then
				return false
			end
			
			-- Add by 1
			CounterInfo = CounterInfo + 1
			
			local PluginInfoLoader = loadfile(a_Plugin:GetLocalFolder() .. "/Info.lua")
			local LoaderEnv = {}
			
			-- This way the function can't overwrite any of the functions in this environment.
			-- And we can extract the g_PluginInfo variable
			setfenv(PluginInfoLoader, LoaderEnv)
			
			PluginInfoLoader()
			
			local PluginInfo = LoaderEnv["g_PluginInfo"]
			local PluginName = PluginInfo.Name -- You can also use a_Plugin:GetName() of course.
			
			ins(Row, "<tr><td valign='top' style='background-color: unset;'><b style='font-size: 20px; position: relative; margin: 15px;'><a href='/" .. a_Request.Path .. "?subpage=show&Plugin=" .. cWebAdmin:GetHTMLEscapedString(PluginName) .. "'>" .. PluginName .. "</b></br></td><td valign='top'>Version: " .. (PluginInfo.Version or "Unknown Version") .. "</td></tr>")
			
			-- Don't print anything if the counter was never above 1!
			if CounterInfo > 0 then
				-- For each command like usually.
				for CommandString, CommandInfo in pairs(PluginInfo.Commands) do
				
					local PermissionString
					
					if (not CommandInfo.Permission == "") then
						PermissionString = "This plugin doesn't require any permission"
					else
						PermissionString = CommandInfo.Permission
					end
					
					ins(Row_tables, "<tr></td><td valign='top'>" .. PluginName .. "<br/></td><td valign='top'>" .. CommandString .. "<br/></td><td valign='top'>" .. (PermissionString or ShowSubCommands(CommandInfo.Subcommands)) .. "<br/></td><td valign='top'>" .. (CommandInfo.HelpString or "") .. "<br/></td><td valign='top'>" .. AssignButton("assign", "Add Permission", PermissionString, CommandInfo.Subcommands, a_Request.Path) .. "</td></tr>")
				end
			end
		end
	)
	
	-- if less than one, lets notify the user!
	if CounterInfo < 0 then
		ins(Row, "<tr></td><td valign='top'>None of the enabled plugins have a <b>info.lua</b> file!<br/></td><td valign='top'></tr>")
		ins(Row, "</table>")
		return false
	end
	ins(Row, "</table>")
	
	ins(Row_tables, "</tbody>")
	ins(Row_tables, "<tfoot><tr><th>Plugin</th><th>Commands</th><th>Permissions</th><th>Help Strings</th><th>Assign to Group</th></tr></tfoot>")
	ins(Row_tables, "</table>")
	
	ins(Row, con(Row_tables))
	return con(Row)
end

local function GetPlugin(get_plugin, a_Request)
	local Row = {}
	cPluginManager:ForEachPlugin(
		function(a_Plugin)
			
			-- We don't want to load plugins that isn't enabled
			if (not a_Plugin:IsLoaded()) then
				return false
			end
			
			local plugin_name = a_Plugin:GetName()
			if (get_plugin ~= plugin_name) then
				-- Its not the plugin we are looking for
				return false
			end
			
			if (not cFile:IsFile(a_Plugin:GetLocalFolder() .. "/Info.lua")) then
				-- The plugin doesn't have a Info.lua file
				return false
			end
			
			local PluginInfoLoader = loadfile(a_Plugin:GetLocalFolder() .. "/Info.lua")
			local LoaderEnv = {}
			
			-- This way the function can't overwrite any of the functions in this environment.
			-- And we can extract the g_PluginInfo variable
			setfenv(PluginInfoLoader, LoaderEnv)
			
			PluginInfoLoader()
			
			local PluginInfo = LoaderEnv["g_PluginInfo"]
			local PluginName = PluginInfo.Name -- You can also use a_Plugin:GetName() of course.
			
			ins(Row, "<thead><tr><th>Commands</th><th>Permissions</th><th>Help Strings</th><th>Assign to Group</th></tr></thead>")
			ins(Row, "<tbody>")
			-- For each command like usually.
			for CommandString, CommandInfo in pairs(PluginInfo.Commands) do
			
				local PermissionString
				if (not CommandInfo.Permission == "") then
					PermissionString = "This plugin doesn't require any permission"
				else
					PermissionString = CommandInfo.Permission
				end
				
				ins(Row, "<tr></td><td valign='top'>" .. CommandString .. "<br/></td><td valign='top'>" .. (PermissionString or ShowSubCommands(CommandInfo.Subcommands)) .. "<br/></td><td valign='top'>" .. (CommandInfo.HelpString or "") .. "<br/></td><td valign='top'>" .. AssignButton("assign", "Assign Permission", PermissionString, CommandInfo.Subcommands, a_Request.Path) .. "</td></tr>")
			end
			ins(Row, "</tbody>")
			ins(Row, "<tfoot><tr><th>Commands</th><th>Permissions</th><th>Help Strings</th><th>Assign to Group</th></tr></tfoot>")
		end
	)
	return con(Row)
end

local function ShowMainPermissionsPage(a_Request)

	local Page = {""}
	
	ins(Page, "<h4>Plugin Permissions</h4>")
	ins(Page, GetPlugins(a_Request))
	
	return con(Page)
end

local function ShowPluginOnlyPage(a_Request)
	-- Check params:
	local PluginName = a_Request.PostParams["Plugin"]
	if (PluginName == nil) then
		return HTMLError("Bad request, missing parameters.")
	end
	
	local Page = {""}
	
	ins(Page, js_stuff)
	
	ins(Page, "<h4>" .. PluginName .." Permissions</h4>")
	ins(Page, AssignButton("", "<< BACK", nil, nil, a_Request.Path))
	ins(Page, "<table id='plugin_table' border='0' cellpadding='8' cellspacing='1' width='100%'>")
	ins(Page, GetPlugin(PluginName, a_Request))
	ins(Page, "</table>")

	return con(Page)
end

local function GetGroupRow(a_GroupName, a_Request, Permission)
	-- Check params:
	assert(type(a_GroupName) == "string")
	
	local HasPermission = false
	local HasPermission_TXT = ""
	local ShowButton = ""
	
	local Permissions = cRankManager:GetGroupPermissions(a_GroupName)
	table.sort(Permissions)
	for _, permission in ipairs(Permissions) do
		if Permission == permission then
			HasPermission = true
		end
	end
	
	if HasPermission then
		HasPermission_TXT = "<span style='color: green'><b>YES</b></span>"
		ShowButton = AssignButtonGroup("removeperm", "Remove Permission", Permission, a_GroupName, a_Request.Path)
	else
		HasPermission_TXT = "<span style='color: red'><b>NO</b></span>"
		ShowButton = AssignButtonGroup("addperm", "Add Permission", Permission, a_GroupName, a_Request.Path)
	end
	
	local Row = {}
	ins(Row, "<tr></td><td valign='top'>" .. cWebAdmin:GetHTMLEscapedString(a_GroupName) .. "</td><td valign='top'>" .. HasPermission_TXT .. "<br/></td><td valign='top'>" .. ShowButton .. "</td></tr>")
	
	return con(Row)
end

local function AssignPermission(a_Request)
	-- Check params:
	local Permission = a_Request.PostParams["Permission"]
	if (Permission == nil) then
		return HTMLError("Bad request, missing parameters.")
	end
	
	local Page = {""}
	
	ins(Page, js_stuff)
	
	ins(Page, AssignButton("", "<< BACK", nil, nil, a_Request.Path))
	ins(Page, "<h4>Assign " .. Permission .." to a group.</h4>")
	ins(Page, "<table id='plugin_table' border='0' cellpadding='8' cellspacing='1' width='100%'>")
	ins(Page, "<thead><tr><th>Group</th><th>Has Permission</th><th>Assign to Group</th></tr></thead>")
	ins(Page, "<tbody>")
	local AllGroups = cRankManager:GetAllGroups()
	table.sort(AllGroups)
	for _, group in ipairs(AllGroups) do
		ins(Page, GetGroupRow(group, a_Request, Permission))
	end
	ins(Page, "</tbody>")
	ins(Page, "<tfoot><tr><th>Group</th><th>Has Permission</th><th>Assign to Group</th></tr></tfoot>")

	return con(Page)
end

local function AddPermission(a_Request)
	-- Check params:
	local Permission = a_Request.PostParams["Permission"]
	local Group = a_Request.PostParams["Group"]

	if (Permission == nil or Group == nil) then
		return HTMLError("Bad request, missing parameters.")
	end

	cRankManager:AddPermissionToGroup(Permission, Group)

	return "<p>Permission added. <a href='/" .. a_Request.Path .. "?subpage=" .. "'>Return to group list</a>.</p>"
end

local function RemovePermission(a_Request)
	-- Check params:
	local Permission = a_Request.PostParams["Permission"]
	local Group = a_Request.PostParams["Group"]

	if (Permission == nil or Group == nil) then
		return HTMLError("Bad request, missing parameters.")
	end

	cRankManager:RemovePermissionFromGroup(Permission, Group)

	return "<p>Permission removed. <a href='/" .. a_Request.Path .. "?subpage=" .. "'>Return to group list</a>.</p>"
end

local g_SubpageHandlers =
{
	[""]			=		ShowMainPermissionsPage,
	["show"]		=		ShowPluginOnlyPage,
	["assign"]		=		AssignPermission,
	["addperm"]		=		AddPermission,
	["removeperm"]	=		RemovePermission,
}

function HandleRequest_ManageWebPermissions(a_Request)
	local Subpage = (a_Request.PostParams["subpage"] or "")
	local Handler = g_SubpageHandlers[Subpage]
	if (Handler == nil) then
		return HTMLError("An internal error has occurred, no handler for subpage " .. Subpage .. ".")
	end
	
	local PageContent = Handler(a_Request)
	
	return PageContent
end

