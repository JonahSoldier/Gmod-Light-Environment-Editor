
//Make dynamic lights have a non-black lightstyle by default
if defaultDlight == nil then defaultDlight = DynamicLight end

function DynamicLight( index, elight )
	local light = defaultDlight(index,elight) 
	light.Style = GetGlobalInt( "environment_lightstyle", 64 )
	return light
end
//Cleaner than copying the code for gmod's light tool to change a single value and should mean most dynamic lights from other addons will work too

net.Receive("Environments_client_redownloadlightmaps", function( len, ply )
	render.RedownloadAllLightmaps(true, true)
end)

net.Receive("Environments_client_stopSoundscape", function( len, ply )
	 RunConsoleCommand("stopsound")
	 RunConsoleCommand("stopsoundscape")
end)

net.Receive("Environments_client_forcedisablesky", function( len, ply )
	if(net.ReadUInt(1) == 1) then
		RunConsoleCommand( "r_3dsky", 0 )
	else
		RunConsoleCommand( "r_3dsky", 1 )
	end
end)

net.Receive("Environments_client_forceradiosityzero", function( len, ply )
	local newValue = net.ReadUInt(2)
	LocalPlayer():ChatPrint( "Changing r_radiosity to "..tostring(newValue).." in 5 seconds." )

	timer.Simple(5, function()
		RunConsoleCommand( "r_radiosity", newValue)
	end)
end)

net.Receive("Environments_client_forcedisablespecular", function( len, ply )
	
	LocalPlayer():ChatPrint( "Changing mat_specular to 0 in 5 seconds. You may freeze temporarily when this happens." )
	
	timer.Simple(5, function() 
		
		RunConsoleCommand( "mat_specular", 0 )
		
	end)
	
end)

cvars.AddChangeCallback( "r_3dsky",  function(convar_name, value_old, value_new)

	if(GetConVar("Environment_ForceDisabledSkybox"):GetBool()) then
		if(value_new == "1") then
			RunConsoleCommand( "r_3dsky", 0 )
		end
	end
end)

cvars.AddChangeCallback( "r_radiosity",  function(convar_name, value_old, value_new)

	if(GetConVar("Environment_ForceRadiosityZero"):GetBool()) then
		if(value_new != "0") then
			RunConsoleCommand( "r_radiosity", 0 )
		end
	end
end)
