//I need to re-organize this file a bit


//Network stuff for client-server communication
util.AddNetworkString( "Environments_client_redownloadlightmaps" )
util.AddNetworkString( "Environments_client_changeLight" )
util.AddNetworkString( "Environments_client_forcedisablesky" )
util.AddNetworkString( "Environments_client_forceradiosityzero" )
util.AddNetworkString( "Environments_client_forcedisablespecular" )
util.AddNetworkString( "Environments_client_stopSoundscape" )



//Convar setup

//Lighting stuff
CreateConVar( "Environment_ambientLightLevel", "12", FCVAR_NONE, "", 1, 26 )
CreateConVar( "Environment_SunLightLevel", "12", FCVAR_NONE, "", 1, 26 )

//Lets people disable the fix for non-world lights (if they want to do that for some reason)
CreateConVar( "Environment_ChangeLightStyle", "1", FCVAR_NONE, "", 0, 1 )

//Stuff for messing with other convars (So you can fix/hide certain issues automatically for all players)
CreateConVar( "Environment_ForceDisabledSkybox", "0", FCVAR_NONE, "", 0, 1 )
CreateConVar( "Environment_ForceDisabledCubemaps", "0", FCVAR_NONE, "", 0, 1 )
CreateConVar( "Environment_ForceRadiosityZero", "0", FCVAR_NONE, "", 0, 1 )

//The thing that lets you draw a transparent black rectangle over water to make its glow less obvious
CreateConVar( "Environment_DarkenWater", "1", FCVAR_NONE, "", 0, 1 )
CreateConVar( "Environment_DarkenRopes", "0", FCVAR_NONE, "", 0, 1 )


hook.Add("InitPostEntity", "Environments_init", function() 
	
	//make sure we aren't using light styles used by dynamic lights on the map
	local availableLightStyles = {}
	
	for I=13, 64, 1 do 
		table.insert(availableLightStyles, I)
	end
	
	for k, v in pairs(ents.FindByClass("light")) do
		table.RemoveByValue( availableLightStyles, v:GetInternalVariable("style"))
	end
	for k, v in pairs(ents.FindByClass("env_projectedtexture")) do
		table.RemoveByValue( availableLightStyles, v:GetInternalVariable("style"))
	end
	for k, v in pairs(ents.FindByClass("light_environment")) do
		table.RemoveByValue( availableLightStyles, v:GetInternalVariable("style"))
	end

	//If every style number is used print something to console and try to use 64 
	if(table.IsEmpty(availableLightStyles)) then
		print("Light/Environment Editor: All lightStyles used, expect weird behaviour")
		engine.LightStyle(64, "m")
		availableLightStyles = {64}
	end
	
	SetGlobalInt( "environment_lightstyle", availableLightStyles[1]) 
	
	for k, v in ipairs(ents.FindByClass("keyframe_rope")) do
		v.mapEnt = true
	end

	//Stuff for the new less terrible water darkening
	lightEnv_defaultWaterFogs = {}
	
	for k, v in ipairs(game.GetWorld():GetBrushSurfaces()) do
		if v:IsWater() then
			local fogCol = v:GetMaterial():GetVector("$fogcolor")
			if fogCol then 
				table.insert(lightEnv_defaultWaterFogs, {["Surface"] = v, ["Fog"] = fogCol } )
			end
		end
	end

	SetGlobalInt( "environment_ambientLightLevel", 12)
end)



cvars.AddChangeCallback( "Environment_ForceDisabledSkybox",  function(convar_name, value_old, value_new)
	net.Start("Environments_client_forcedisablesky")
		net.WriteUInt(tonumber(value_new),1)
	net.Broadcast()
end)



cvars.AddChangeCallback( "Environment_ForceDisabledCubemaps",  function(convar_name, value_old, value_new)
	if(value_new == "1") then
		net.Start("Environments_client_forcedisablespecular")
		net.Broadcast()
	end
end)


cvars.AddChangeCallback( "Environment_ForceRadiosityZero",  function(convar_name, value_old, value_new)

	net.Start("Environments_client_forceradiosityzero")
		if(value_new == "1") then
			net.WriteUInt(0,2)
		else
			net.WriteUInt(3,2)
		end
	net.Broadcast()
end)


concommand.Add( "Environment_Destroy_Beams", function(player)

	if(player:IsSuperAdmin()) then
		local beams = ents.FindByClass("beam")
	
		for k, v in pairs(beams) do
			v:Remove()
		end
	end

end, nil, nil, 0 )


concommand.Add( "Environment_Destroy_SmokeVolume", function(player)

	if(player:IsSuperAdmin()) then
		local smokes = ents.FindByClass("func_smokevolume")
	
		for k, v in pairs(smokes) do
			v:Remove()
		end
	end

end, nil, nil, 0 )


concommand.Add( "Environment_Destroy_Soundscapes", function(player)

	if(player:IsSuperAdmin()) then
		local soundscapes = ents.FindByClass("env_soundscape")
	
		for k, v in pairs(soundscapes) do
			v:Remove()
		end
	end

end, nil, nil, 0 )


concommand.Add( "Environment_Destroy_AmbientGeneric", function(player)

	if(player:IsSuperAdmin()) then
		local sounds = ents.FindByClass("ambient_generic")
	
		for k, v in pairs(sounds) do
			v:Remove()
		end
	end
end, nil, nil, 0 )


concommand.Add( "Environment_Destroy_Sprites", function(player)

	if(player:IsSuperAdmin()) then

		Glows = ents.FindByClass("env_sprite")
		table.Add( Glows, ents.FindByClass( "env_lightglow" ) )
		table.Add( Glows, ents.FindByClass( "env_sprite_oriented" ) )
		table.Add( Glows, ents.FindByClass( "env_sprite_clientside" ) )

		for k, v in pairs(Glows) do
			v:Remove()
		end
	end
end, nil, nil, 0 )


concommand.Add( "Environment_stopsoundscape", function(player)

	if(player:IsSuperAdmin()) then
		net.Start("Environments_client_stopSoundscape")	
		net.Broadcast()
	end

end, nil, nil, 0 )



lightEnv_LastChange = CurTime()
cvars.AddChangeCallback( "Environment_ambientLightLevel",  function(convar_name, value_old, value_new)
	
	if(CurTime()-lightEnv_LastChange > 0.5) then //Stops people from crashing their game by changing ambient light too often
		
		timer.Simple(0.5, function() //Delay the code actually running and grab the convar when it does so it sets it to whatever value the slider was left on

			local convar = GetConVar("Environment_ambientLightLevel")
			local pattern = string.char(96 + convar:GetInt())
			engine.LightStyle( 0, pattern )

			timer.Simple(1, function() 
				net.Start("Environments_client_redownloadlightmaps")
				net.Broadcast()
			end)

			SetGlobalInt( "environment_ambientLightLevel", convar:GetInt() ) //Set a global variable so we can access this clientside
			lightEnv_updateDarkenWater()
		end)
		lightEnv_LastChange = CurTime()
	end
end)



cvars.AddChangeCallback( "Environment_SunLightLevel",  function(convar_name, value_old, value_new)
	
	local LightEnvs = ents.FindByClass( "light_environment" )
	local pattern = string.char(96+value_new)
	
	for k,v in pairs(LightEnvs) do
		v:Fire( "SetPattern", pattern, 0, nil, nil )
	end
end)



cvars.AddChangeCallback( "Environment_ChangeLightStyle",  function(convar_name, value_old, value_new)

	projectedTextures = ents.FindByClass("env_projectedtexture")

	if(value_new == "1") then
		for k, v in pairs(projectedTextures) do
			local style = GetGlobalInt( "environment_lightstyle", 64 )
			v:SetKeyValue("style", tostring(style))
		end
	else
		for k, v in pairs(projectedTextures) do
			v:SetKeyValue("style", "0")
		end
	end

end)



hook.Add( "OnEntityCreated", "UpdateLamps", function( ent )
	local convar = GetConVar("Environment_ChangeLightStyle")

	if(convar:GetBool()) then
		if ( ent:GetClass() == "env_projectedtexture" ) then
			timer.Simple(0.001, function()
				if(ent:IsValid()) then
					local style = GetGlobalInt( "environment_lightstyle", 64 )
					ent:SetKeyValue("style", tostring(style))
				end
			end)
		end
	end
end )



cvars.AddChangeCallback( "Environment_DarkenWater",  function(convar_name, value_old, value_new)
	lightEnv_updateDarkenWater() //This is called in amblight too because that affects how dark/light it makes the water
end)

function lightEnv_updateDarkenWater()
	if GetConVar("Environment_DarkenWater"):GetBool() then
		for k, v in pairs(lightEnv_defaultWaterFogs) do
			local darken = GetGlobalInt("environment_ambientLightLevel")/12
			v.Surface:GetMaterial():SetVector("$fogcolor", v.Fog*darken)
		end
	else
		for k, v in pairs(lightEnv_defaultWaterFogs) do
			v.Surface:GetMaterial():SetVector("$fogcolor", v.Fog) 
		end
	end
end



cvars.AddChangeCallback( "Environment_DarkenRopes",  function(convar_name, value_old, value_new)
	
	if(value_new == "1") then
		for k, v in pairs(ents.FindByClass("keyframe_rope")) do 
			if(v.mapEnt) then 
				if !(v.defaultColour) then v.defaultColour = v:GetColor() end
				v:SetColor(Color(0,0,0,255))
			end
		end
		for k, v in pairs(ents.FindByClass("move_rope")) do
			if !(v.defaultColour) then v.defaultColour = v:GetColor() end
			v:SetColor(Color(0,0,0,255))
		end
	else
		local function resetCol(ropeType)
			for k, v in pairs(ents.FindByClass(ropeType)) do
				v:SetColor(v.defaultColour)
			end
		end
		resetCol("move_rope")
		resetCol("keyframe_rope")
	end
end)
