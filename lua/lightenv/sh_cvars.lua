--I really need to rewrite this entire addon at some point.
AddCSLuaFile()

lightEnv.ambientLight_cv = CreateConVar("Environment_ambientLightLevel", "12", FCVAR_REPLICATED, "", 1, 26)
lightEnv.sunLight_cv = CreateConVar("Environment_SunLightLevel", "12", FCVAR_REPLICATED, "", 1, 26)

--Lets people disable the fix for non-world lights (if they want to do that for some reason)
lightEnv.changeLightStyle_cv = CreateConVar("Environment_ChangeLightStyle", "1", FCVAR_REPLICATED, "", 0, 1)

--Stuff for messing with other convars (So you can fix/hide certain issues automatically for all players)
lightEnv.disableSkyBox_cv = CreateConVar("Environment_ForceDisabledSkybox", "0", FCVAR_REPLICATED, "", 0, 1)
lightEnv.disableCubemaps_cv = CreateConVar("Environment_ForceDisabledCubemaps", "0", FCVAR_REPLICATED, "", 0, 1)
lightEnv.disableDetailProps_cv = CreateConVar("Environment_ForceDisabledDetailProps", "0", FCVAR_REPLICATED, "", 0, 1)
lightEnv.radiosityZero_cv = CreateConVar("Environment_ForceRadiosityZero", "0", FCVAR_REPLICATED, "", 0, 1)

--Water fog darkening
lightEnv.darkenWater_cv = CreateConVar("Environment_DarkenWater", "1", FCVAR_REPLICATED, "", 0, 1)
lightEnv.darkenRopes_cv = CreateConVar("Environment_DarkenRopes", "0", FCVAR_REPLICATED, "", 0, 1)

--Map Materials
lightEnv.noStaticSelfIllum = CreateConVar("Environment_DisableStaticSelfIllum", "0", FCVAR_REPLICATED, "", 0, 1)

--Should values be reset on cleanup
lightEnv.resetOnCleanup = CreateConVar("Environment_ResetOnCleanup", "1", FCVAR_REPLICATED, "", 0, 1)

--Hiding things
lightEnv.hideBeams_cv = CreateConVar("Environment_Hide_Beams", "0", FCVAR_REPLICATED, "", 0, 1)
lightEnv.hideSprites_cv = CreateConVar("Environment_Hide_Sprites", "0", FCVAR_REPLICATED, "", 0, 1)

if SERVER then --Work-around to allow superadmins to edit our CVars via the menu
	local whitelist = { --Do *not* allow requests to change anything other than this addon's cvars.
		["sv_skyname"] = true, --This is an engine cvar, but the menu lets you change it.

		["Environment_ambientLightLevel"] = true,
		["Environment_SunLightLevel"] = true,

		["Environment_ChangeLightStyle"] = true,
		["Environment_DarkenWater"] = true,
		["Environment_ForceDisabledSkybox"] = true,
		["Environment_ForceDisabledCubemaps"] = true,
		["Environment_ForceDisabledDetailProps"] = true,
		["Environment_ForceRadiosityZero"] = true,
		["Environment_DarkenRopes"] = true,

		["Environment_Hide_Beams"] = true,
		["Environment_Hide_Sprites"] = true,
	}

	net.Receive("Environments_server_setcv", function(len, ply)
		local cvarName = net.ReadString()
		if not(whitelist[cvarName] and ply:IsSuperAdmin()) then return end

		local dataType = net.ReadUInt(2)

		local newValue 
		if dataType == 0 then 
			newValue = net.ReadBool() and "1" or "0"
		elseif dataType == 1 then
			newValue = tostring(net.ReadUInt(8))
		else
			newValue = net.ReadString()
		end

		RunConsoleCommand(cvarName, newValue)
	end)
end