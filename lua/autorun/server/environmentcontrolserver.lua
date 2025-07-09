lightEnv = {}

--Network stuff for client-server communication
util.AddNetworkString("Environments_client_redownloadlightmaps")
util.AddNetworkString("Environments_client_changeLight")
util.AddNetworkString("Environments_client_forcedisablesky")
util.AddNetworkString("Environments_client_forcedisabledetailprops")
util.AddNetworkString("Environments_client_forceradiosityzero")
util.AddNetworkString("Environments_client_forcedisablespecular")
util.AddNetworkString("Environments_client_stopSoundscape")

util.AddNetworkString("Environments_client_updateDarkenWater")

util.AddNetworkString("Environments_server_setcv")

include("lightenv/sv_staticproplighting.lua")
include("lightenv/sh_materials.lua")
include("lightenv/sh_cvars.lua")



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

cvars.AddChangeCallback("Environment_ForceDisabledDetailProps", function(convar_name, value_old, value_new)
	net.Start("Environments_client_forcedisabledetailprops")
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
setupDestroyCmd("Environment_Destroy_Particles", "info_particle_system")
setupDestroyCmd("Environment_Destroy_Soundscapes", "env_soundscape")
setupDestroyCmd("Environment_Destroy_AmbientGeneric", "ambient_generic")

concommand.Add("Environment_Destroy_Sprites", function(player)
	if not player:IsSuperAdmin() then return end
	local Glows = ents.FindByClass("env_sprite")
	table.Add(Glows, ents.FindByClass("env_lightglow"))
	table.Add(Glows, ents.FindByClass("env_sprite_oriented"))
	table.Add(Glows, ents.FindByClass("env_sprite_clientside"))
	for i, v in ipairs(Glows) do
		v:Remove()
	end
end)

concommand.Add("Environment_Destroy_SmokeVolume", function(player)
	if not player:IsSuperAdmin() then return end
	local Smokes = ents.FindByClass("func_smokevolume")
	table.Add(Smokes, ents.FindByClass("env_smokestack"))
	for i, v in ipairs(Smokes) do
		v:Remove()
	end
end)

concommand.Add("Environment_stopsoundscape", function(player)
	if not player:IsSuperAdmin() then return end
	net.Start("Environments_client_stopSoundscape")
	net.Broadcast()
end)


cvars.AddChangeCallback("Environment_Hide_Sprites", function(convar_name, value_old, value_new)
	local Glows = ents.FindByClass("env_sprite")
	table.Add(Glows, ents.FindByClass("env_lightglow"))
	table.Add(Glows, ents.FindByClass("env_sprite_oriented"))
	table.Add(Glows, ents.FindByClass("env_sprite_clientside"))
	local shouldDraw = tobool(value_new)
	for i, v in ipairs(Glows) do
		if v:GetNoDraw() then
			print(v)
		end
	end
	for i, v in ipairs(Glows) do
		v:SetNoDraw(shouldDraw)
	end
end)

cvars.AddChangeCallback("Environment_Hide_Beams", function(convar_name, value_old, value_new)
	local shouldDraw = tobool(value_new)
	for i, v in ipairs(ents.FindByClass("beam")) do
		v:SetNoDraw(shouldDraw)
	end
end)


local lightEnv_LastChange = CurTime()
cvars.AddChangeCallback("Environment_ambientLightLevel", function(convar_name, value_old, value_new)
	if CurTime() - lightEnv_LastChange < 0.5 then return end --Stops people from crashing their game by changing ambient light too often
	timer.Simple(0.5, function()
		--Delay the code actually running and grab the convar when it does so it sets it to whatever value the slider was left on
		local pattern = string.char(96 + lightEnv.ambientLight_cv:GetInt())
		engine.LightStyle(0, pattern)
		timer.Simple(1, function()
			net.Start("Environments_client_redownloadlightmaps")
			net.Broadcast()
		end)

		SetGlobalInt("environment_ambientLightLevel", lightEnv.ambientLight_cv:GetInt()) --Set a global variable so we can access this clientside
		lightEnv.updateDarkenWater()
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
	if not(lightEnv.changeLightStyle_cv:GetBool() and ent:GetClass() == "env_projectedtexture") then return end
	timer.Simple(0.001, function()
		if not ent:IsValid() then return end
		local style = GetGlobalInt("environment_lightstyle", 64)
		ent:SetKeyValue("style", tostring(style))
	end)
end)

cvars.AddChangeCallback("Environment_DarkenWater", function(convar_name, value_old, value_new)
	lightEnv.updateDarkenWater() --This is called in amblight too because that affects how dark/light it makes the water
end)

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
	if not lightEnv.resetOnCleanup:GetBool() then return end
	lightEnv.ambientLight_cv:SetInt(12)
	lightEnv.sunLight_cv:SetInt(12)

	lightEnv.darkenRopes_cv:SetBool(false)

	lightEnv.disableSkyBox_cv:SetBool(false)
	lightEnv.disableCubemaps_cv:SetBool(false)
	lightEnv.disableDetailProps_cv:SetBool(false)
	lightEnv.radiosityZero_cv:SetBool(false)

	lightEnv.noStaticSelfIllum:SetBool(false)

	lightEnv.hideBeams_cv:SetBool(false)
	lightEnv.hideSprites_cv:SetBool(false)
end )