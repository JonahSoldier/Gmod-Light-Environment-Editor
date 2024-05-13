lightEnv = {}
--Network stuff for client-server communication
util.AddNetworkString("Environments_client_redownloadlightmaps")
util.AddNetworkString("Environments_client_changeLight")
util.AddNetworkString("Environments_client_forcedisablesky")
util.AddNetworkString("Environments_client_forceradiosityzero")
util.AddNetworkString("Environments_client_forcedisablespecular")
util.AddNetworkString("Environments_client_stopSoundscape")

--Convar setup
--Lighting stuff
local env_ambientLight_cv = CreateConVar("Environment_ambientLightLevel", "12", FCVAR_NONE, "", 1, 26)
local env_sunLight_cv = CreateConVar("Environment_SunLightLevel", "12", FCVAR_NONE, "", 1, 26)

--Lets people disable the fix for non-world lights (if they want to do that for some reason)
local env_changeLightStyle_cv = CreateConVar("Environment_ChangeLightStyle", "1", FCVAR_NONE, "", 0, 1)

--Stuff for messing with other convars (So you can fix/hide certain issues automatically for all players)
local env_disableSkyBox_cv = CreateConVar("Environment_ForceDisabledSkybox", "0", FCVAR_NONE, "", 0, 1)
local env_disableCubemaps_cv = CreateConVar("Environment_ForceDisabledCubemaps", "0", FCVAR_NONE, "", 0, 1)
local env_radiosityZero_cv = CreateConVar("Environment_ForceRadiosityZero", "0", FCVAR_NONE, "", 0, 1)

--Water fog darkening
local env_darkenWater_cv = CreateConVar("Environment_DarkenWater", "1", FCVAR_NONE, "", 0, 1)
local env_darkenRopes_cv = CreateConVar("Environment_DarkenRopes", "0", FCVAR_NONE, "", 0, 1)

--Map Materials
--local env_noStaticAmbLight_cv = CreateConVar("Environment_DisableStaticAmbientLighting", "0", FCVAR_NONE, "", 0, 1)
local env_noStaticSelfIllum = CreateConVar("Environment_DisableStaticSelfIllum", "0", FCVAR_NONE, "", 0, 1)


--Should values be reset on cleanup
local env_resetOnCleanup = CreateConVar("Environment_ResetOnCleanup", "1", FCVAR_NONE, "", 0, 1)

include("lightenv/sv_staticproplighting.lua")

hook.Add("InitPostEntity", "Environments_init", function()
	--make sure we aren't using light styles used by dynamic lights on the map
	local availableLightStyles = {}
	for I = 13, 64 do
		table.insert(availableLightStyles, I)
	end

	for i, v in ipairs(ents.FindByClass("light")) do
		table.RemoveByValue(availableLightStyles, v:GetInternalVariable("style"))
	end
	for i, v in ipairs(ents.FindByClass("env_projectedtexture")) do
		table.RemoveByValue(availableLightStyles, v:GetInternalVariable("style"))
	end
	for i, v in ipairs(ents.FindByClass("light_environment")) do
		table.RemoveByValue(availableLightStyles, v:GetInternalVariable("style"))
	end

	--If every style number is used print something to console and try to use 64 
	if table.IsEmpty(availableLightStyles) then
		print("Light/Environment Editor: All lightStyles used, expect weird behaviour")
		engine.LightStyle(64, "m")
		availableLightStyles[1] = 64
	end

	SetGlobalInt("environment_lightstyle", availableLightStyles[1])

	--Stuff for the new less terrible water darkening
	lightEnv.defaultWaterFogs = {}
	for i, v in ipairs(game.GetWorld():GetBrushSurfaces()) do
		if v:IsWater() then
			local mat = v:GetMaterial()
			local fogCol = mat:GetVector("$fogcolor")
			if fogCol then
				table.insert(lightEnv.defaultWaterFogs, {
					["Material"] = mat,
					["Fog"] = fogCol * 1 --Create a copy not a reference
				})
			end
		end
	end

	SetGlobalInt("environment_ambientLightLevel", 12)
end)


cvars.AddChangeCallback("Environment_ForceDisabledSkybox", function(convar_name, value_old, value_new)
	net.Start("Environments_client_forcedisablesky")
	net.WriteBool(tobool(value_new))
	net.Broadcast()
end)

cvars.AddChangeCallback("Environment_ForceDisabledCubemaps", function(convar_name, value_old, value_new)
	if tobool(value_new) then
		net.Start("Environments_client_forcedisablespecular")
		net.Broadcast()
	end
end)

cvars.AddChangeCallback("Environment_ForceRadiosityZero", function(convar_name, value_old, value_new)
	net.Start("Environments_client_forceradiosityzero")
	net.WriteBool(tobool(value_new))
	net.Broadcast()
end)


local function setupDestroyCmd(name, type)
	concommand.Add(name, function(player)
		if not player:IsSuperAdmin() then return end

		local entsToRemove = ents.FindByClass(type)
		for i, v in ipairs(entsToRemove) do
			v:Remove()
		end
	end)
end

setupDestroyCmd("Environment_Destroy_Beams", "beam")
setupDestroyCmd("Environment_Destroy_SmokeVolume", "func_smokevolume")
setupDestroyCmd("Environment_Destroy_Soundscapes", "env_soundscape")
setupDestroyCmd("Environment_Destroy_AmbientGeneric", "ambient_generic")

concommand.Add("Environment_Destroy_Sprites", function(player)
	if not player:IsSuperAdmin() then return end
	Glows = ents.FindByClass("env_sprite")
	table.Add(Glows, ents.FindByClass("env_lightglow"))
	table.Add(Glows, ents.FindByClass("env_sprite_oriented"))
	table.Add(Glows, ents.FindByClass("env_sprite_clientside"))
	for i, v in ipairs(Glows) do
		v:Remove()
	end
end)

concommand.Add("Environment_stopsoundscape", function(player)
	if not player:IsSuperAdmin() then return end
	net.Start("Environments_client_stopSoundscape")
	net.Broadcast()
end)


local lightEnv_LastChange = CurTime()
cvars.AddChangeCallback("Environment_ambientLightLevel", function(convar_name, value_old, value_new)
	if CurTime() - lightEnv_LastChange < 0.5 then return end --Stops people from crashing their game by changing ambient light too often
	timer.Simple(0.5, function()
		--Delay the code actually running and grab the convar when it does so it sets it to whatever value the slider was left on
		local pattern = string.char(96 + env_ambientLight_cv:GetInt())
		engine.LightStyle(0, pattern)
		timer.Simple(1, function()
			net.Start("Environments_client_redownloadlightmaps")
			net.Broadcast()
		end)

		SetGlobalInt("environment_ambientLightLevel", env_ambientLight_cv:GetInt()) --Set a global variable so we can access this clientside
		lightEnv_updateDarkenWater()
	end)

	lightEnv_LastChange = CurTime()
end)

cvars.AddChangeCallback("Environment_SunLightLevel", function(convar_name, value_old, value_new)
	local LightEnvs = ents.FindByClass("light_environment")
	local pattern = string.char(96 + value_new)
	for i, v in ipairs(LightEnvs) do
		v:Fire("SetPattern", pattern)
	end
end)


cvars.AddChangeCallback("Environment_ChangeLightStyle", function(convar_name, value_old, value_new)
	projectedTextures = ents.FindByClass("env_projectedtexture")
	local style = tostring( GetGlobalInt("environment_lightstyle", 64) )
	style = (tobool(value_new) and style) or "0"
	for i, v in ipairs(projectedTextures) do
		v:SetKeyValue("style", style)
	end
end)

hook.Add("OnEntityCreated", "UpdateLamps", function(ent)
	if not(env_changeLightStyle_cv:GetBool() and ent:GetClass() == "env_projectedtexture") then return end
	timer.Simple(0.001, function()
		if not ent:IsValid() then return end
		local style = GetGlobalInt("environment_lightstyle", 64)
		ent:SetKeyValue("style", tostring(style))
	end)
end)

cvars.AddChangeCallback("Environment_DarkenWater", function(convar_name, value_old, value_new)
	lightEnv_updateDarkenWater() --This is called in amblight too because that affects how dark/light it makes the water
end)

function lightEnv_updateDarkenWater()
	local darken = GetGlobalInt("environment_ambientLightLevel") / 12
	darken = (env_darkenWater_cv:GetBool() and darken) or 1
	for i, v in ipairs(lightEnv.defaultWaterFogs) do
		v.Material:SetVector("$fogcolor", v.Fog * darken)
	end
end

cvars.AddChangeCallback("Environment_DarkenRopes", function(convar_name, value_old, value_new)
	if tobool(value_new) then
		local black = Color(0, 0, 0, 255)
		local function setCol(ropeType)
			for i, v in ipairs(ents.FindByClass(ropeType)) do
				if v:CreatedByMap() then
					if not v.defaultColour then v.defaultColour = v:GetColor() end
					v:SetColor(black)
				end
			end
		end

		setCol("keyframe_rope")
		setCol("move_rope")
	else
		local function resetCol(ropeType)
			for i, v in ipairs(ents.FindByClass(ropeType)) do
				if v.defaultColour then
					v:SetColor(v.defaultColour)
				end
			end
		end

		resetCol("move_rope")
		resetCol("keyframe_rope")
	end
end)

hook.Add( "PreCleanupMap", "Environment_Cleanup", function()
	if not env_resetOnCleanup:GetBool() then return end
	env_ambientLight_cv:SetInt(12)
	env_sunLight_cv:SetInt(12)

	env_darkenRopes_cv:SetBool(false)

	env_disableSkyBox_cv:SetBool(false)
	env_disableCubemaps_cv:SetBool(false)
	env_radiosityZero_cv:SetBool(false)

	env_noStaticSelfIllum:SetBool(false)
end )