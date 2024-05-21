--Make dynamic lights have a non-black lightstyle by default
local defaultDlight
if defaultDlight == nil then defaultDlight = DynamicLight end
function DynamicLight(index, elight)
	local light = defaultDlight(index, elight)
	light.Style = GetGlobalInt("environment_lightstyle", 64)
	return light
end


--Cleaner than copying the code for gmod's light tool to change a single value and should mean most dynamic lights from other addons will work too
net.Receive("Environments_client_redownloadlightmaps", function(len, ply)
	render.RedownloadAllLightmaps(true, true)
end)

net.Receive("Environments_client_stopSoundscape", function(len, ply)
	RunConsoleCommand("stopsound")
	RunConsoleCommand("stopsoundscape")
end)

net.Receive("Environments_client_forcedisablesky", function(len, ply)
	RunConsoleCommand("r_3dsky", (net.ReadBool() and 0) or 1)
end)

net.Receive("Environments_client_forcedisabledetailprops", function(len, ply)
	RunConsoleCommand("r_drawdetailprops", (net.ReadBool() and 0) or 1)
end)

net.Receive("Environments_client_forceradiosityzero", function(len, ply)
	local newValue = (net.ReadBool() and 0) or 3
	LocalPlayer():ChatPrint("Changing r_radiosity to " .. tostring(newValue) .. " in 5 seconds.")
	timer.Simple(5, function() RunConsoleCommand("r_radiosity", newValue) end)
end)

net.Receive("Environments_client_forcedisablespecular", function(len, ply)
	LocalPlayer():ChatPrint("Changing mat_specular to 0 in 5 seconds. You may freeze temporarily when this happens.")
	timer.Simple(5, function() RunConsoleCommand("mat_specular", 0) end)
end)

local skyboxConvar = GetConVar("Environment_ForceDisabledSkybox")
cvars.AddChangeCallback("r_3dsky", function(convar_name, value_old, value_new)
	if skyboxConvar:GetBool() and tobool(value_new) then
		RunConsoleCommand("r_3dsky", 0)
	end
end)

local detailPropsConvar = GetConVar("Environment_ForceDisabledDetailProps")
cvars.AddChangeCallback("r_drawdetailprops", function(convar_name, value_old, value_new)
	if detailPropsConvar:GetBool() and tobool(value_new) then
		RunConsoleCommand("r_drawdetailprops", 0)
	end
end)

local radiosityConvar = GetConVar("Environment_ForceRadiosityZero")
cvars.AddChangeCallback("r_radiosity", function(convar_name, value_old, value_new)
	if radiosityConvar:GetBool() and tobool(value_new) then
		RunConsoleCommand("r_radiosity", 0)
	end
end)


local defaultRadiosity = GetConVar("r_radiosity"):GetInt()
local default3DSky = GetConVar("r_3dsky"):GetInt()
local defaultMatSpecular = GetConVar("mat_specular"):GetInt()

gameevent.Listen("client_disconnect")
hook.Add("client_disconnect", "Environment_resetCVars", function()
	RunConsoleCommand( "r_radiosity", tostring(defaultRadiosity) )
	RunConsoleCommand( "r_3dsky", tostring(default3DSky) )
	RunConsoleCommand( "mat_specular", tostring(defaultMatSpecular) )
end )