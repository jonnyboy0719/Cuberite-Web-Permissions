local ins = table.insert
local con = table.concat

local function GetPlugins()

	local Row = {}
	-- Lets grab all plugin permission, commands and help string
	cPluginManager:Get():ForEachCommand(
		function(a_CBCommand, a_CBPermission, a_CBHelpString)
			local helpstring
			if (a_CBHelpString == "") then
				-- No help string found!
				helpstring = ""
			else
				helpstring = a_CBHelpString
			end
			ins(Row, "<tr></td><td valign='top'>" .. a_CBCommand .. "<br/></td><td valign='top'>" .. a_CBPermission .. "<br/></td><td valign='top'>" .. helpstring .. "<br/></td><td valign='top'></tr>")
			--[[ins(Row, "<tr>")
			-- Commands
			ins(Row, a_CBCommand .. "<br/>")
			ins(Row, "</td><td valign='top'>")
			-- Permission
			ins(Row, a_CBPermission .. "<br/>")
			ins(Row, "</td><td valign='top'>")
			-- Help String
			ins(Row, helpstring .. "<br/>")
			ins(Row, "</td><td valign='top'>")
			ins(Row, "</tr>")
			--]]
		end
	)

	return con(Row)
end




--- Displays the main Permissions page, listing the permission groups and their permissions
local function ShowMainPermissionsPage(a_Request)
	local Page = {""}

	-- Display a table showing all groups currently known:
	ins(Page, "<h4>Plugin Permissions</h4><table><tr><th>Commands</th><th>Permissions</th><th>Help Strings</th></tr>")
	ins(Page, GetPlugins())
	ins(Page, "<tr><th>Commands</th><th>Permissions</th><th>Help Strings</th></tr>")
	ins(Page, "</table>")
	
	return con(Page)
end




--- Handlers for the individual subpages in this tab
-- Each item maps a subpage name to a handler function that receives a HTTPRequest object and returns the HTML to return
local g_SubpageHandlers =
{
	[""]		=		ShowMainPermissionsPage,
}




--- Handles the web request coming from MCS
-- Returns the entire tab's HTML contents, based on the player's request
function HandleRequest_ManageWebPermissions(a_Request)
	local Subpage = (a_Request.PostParams["subpage"] or "")
	local Handler = g_SubpageHandlers[Subpage]
	if (Handler == nil) then
		return HTMLError("An internal error has occurred, no handler for subpage " .. Subpage .. ".")
	end
	
	local PageContent = Handler(a_Request)
	
	--[[
	-- DEBUG: Save content to a file for debugging purposes:
	local f = io.open("permissions.html", "wb")
	if (f ~= nil) then
		f:write(PageContent)
		f:close()
	end
	--]]
	
	return PageContent
end

