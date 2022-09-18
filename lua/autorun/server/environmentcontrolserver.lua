//I need to re-organize this file a bit


//Network stuff for client-server communication
util.AddNetworkString( "NatLight_sendlights" )
util.AddNetworkString( "Environments_client_redownloadlightmaps" )
util.AddNetworkString( "Environments_client_changeLight" )
util.AddNetworkString( "Environments_client_forcedisablesky" )
util.AddNetworkString( "Environments_client_forceradiosityzero" )
util.AddNetworkString( "Environments_client_forcedisablespecular" )
util.AddNetworkString( "Environments_client_getWaterBlacken" )
util.AddNetworkString( "Environments_client_stopSoundscape" )

util.AddNetworkString( "Environments_server_requestWaterBlacken" )


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
CreateConVar( "Environment_DarkenWater", "0", FCVAR_NONE, "", 0, 1 )
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
	
	for k, v in pairs(ents.FindByClass("keyframe_rope")) do
		v.mapEnt = true
	end
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



LastChange = CurTime()
cvars.AddChangeCallback( "Environment_ambientLightLevel",  function(convar_name, value_old, value_new)
	
	if(CurTime()-LastChange > 0.5) then //Stops people from crashing their game by changing ambient light too much	
		
		timer.Simple(0.5, function() //Delay the code actually running and grab the convar when it does so it sets it to whatever value the slider was left on
			local Alphabet = "abcdefghijklmnopqrstuvwxyz"

			local convar = GetConVar("Environment_ambientLightLevel")

			local pattern = string.sub( Alphabet, convar:GetInt(), convar:GetInt() )

			engine.LightStyle( 0, pattern )

			timer.Simple(1, function() 
				net.Start("Environments_client_redownloadlightmaps")
				net.Broadcast()

				//render.RedownloadAllLightmaps( true, true )
			end)

			local Props = ents.FindByClass(" prop_physics ")

			timer.Simple(0.01, function() 
				for k,v in pairs (Props) do
					v:GetPhysicsObject():PhysWake()
				end
			end)

			SetGlobalInt( "environment_ambientLightLevel", convar:GetInt() ) //Set a global variable so we can access this clientside
		end)
		LastChange = CurTime()
	end
end)

cvars.AddChangeCallback( "Environment_SunLightLevel",  function(convar_name, value_old, value_new)
	
	local Alphabet = "abcdefghijklmnopqrstuvwxyz"
	local LightEnvs = ents.FindByClass( "light_environment" )

	local convar = GetConVar("Environment_SunLightLevel")

	local pattern = string.sub( Alphabet, convar:GetInt(), convar:GetInt() )

	for k,v in pairs(LightEnvs) do
		v:Fire( "SetPattern", pattern, 0, nil, nil )
	end

	local Props = ents.FindByClass(" prop_physics ")
	

	timer.Simple(0.01, function() 
		for k,v in pairs (Props) do
			v:GetPhysicsObject():PhysWake()
		end
	end)
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

net.Receive("Environments_server_requestWaterBlacken", function(len, ply) 
	if(GetConVar("Environment_DarkenWater"):GetBool()) then
		net.Start("Environments_client_getWaterBlacken")
			net.WriteTable(WaterZones)
		net.Send(ply)
	end
end)

cvars.AddChangeCallback( "Environment_DarkenWater",  function(convar_name, value_old, value_new)

	SetGlobalBool( "environment_darkenWater", tobool(value_new) )

	if(value_new == "1") then

		local WaterHits = {}
		WaterZones = {}

		for I=-35000, 35000, 500 do
			//Check for water in a bunch of chunks across the whole map
			for V=-35000, 35000, 500 do
				local tr = util.TraceHull( {
					start = Vector( I, V, 10000 ),
					endpos = Vector( I, V, -10000),
					filter = false,
					mins = Vector(-500,-500,0),
					maxs = Vector(500,500,0), //This doesn't look right, I need to check this later
					mask = MASK_WATER
				} )
				if tr.Hit == true then	

					local breakLoop1 = false
					local dontBreak1 = false
					local breakLoop2 = false
					local dontBreak2 = false

					//If water is found by one of the tracehulls fire a shitload of traces at it to find the exact shape of the water
					//Approach from front/back and stop when hitting something to minimize number of traces
					for Q=I+500, I-500, -25 do
						if(breakLoop1 == false) then
							for R=V+500, V-500, -25 do			
								local tr2 = util.TraceLine( {
									start = Vector( Q, R, 10000 ),
									endpos = Vector( Q, R, -10000),
									filter = false,
									mask = MASK_WATER
								} )
								if(breakLoop1 == false) then
										
									if tr2.Hit == true then
										local foundMatch = false
										for k, v in pairs(WaterZones) do
											if(v[1] == tr2.HitPos[3]) then
												foundMatch = true
												if(v[3][1] < tr2.HitPos[1]) then
													v[3][1] = tr2.HitPos[1] //Set our maximum X to this trace's X
												end
												if(v[3][2] < tr2.HitPos[2]) then
													v[3][2] = tr2.HitPos[2] //Set our maximum Y to this trace's Y
												end
											end
										end
										if(foundMatch == false)then
											dontBreak1 = true //We have to check for multiple waterlevels in this square now

											local xVar = tr2.HitPos[1]
											local yVar = tr2.HitPos[2]
											local zVar = tr2.HitPos[3]
											
											local xMax = -35000
											local yMax = -35000
											local xMin = 35000
											local yMin = 35000
									
									
											if(xVar>xMax) then
												xMax = xVar
											end
											if(xVar<xMin) then
												xMin = xVar
											end
							
											if(yVar>yMax) then
												yMax = yVar
											end
											if(yVar<yMin) then
												yMin = yVar
											end
									
											table.insert( WaterZones, {zVar,Vector(xMin,yMin,0),Vector(xMax,yMax,0)} )
										else
											if(dontBreak1 == false) then //Makes sure we get traces of the whole square instead of just finding the first value and setting it as the max
												breakLoop1 = true 
											end
										end
									end
									
								end
							end
						end
					end

					for Q=I-500, I+500, 25 do
						if(breakLoop2 == false) then
							for R=V-500, V+500, 25 do			
								local tr2 = util.TraceLine( {
									start = Vector( Q, R, 10000 ),
									endpos = Vector( Q, R, -10000),
									filter = false,
									mask = MASK_WATER
								} )
								if(breakLoop2 == false) then
										
									if tr2.Hit == true then
										local foundMatch = false
										for k, v in pairs(WaterZones) do
											if(v[1] == tr2.HitPos[3]) then
												foundMatch = true
												if(v[2][1] > tr2.HitPos[1]) then
													v[2][1] = tr2.HitPos[1] //Set our minimum X to this trace's X
												end
												if(v[2][2] > tr2.HitPos[2]) then
													v[2][2] = tr2.HitPos[2] //Set our minimum Y to this trace's Y
												end
											end
										end
										if(foundMatch == false)then
											print("This shouldn't appear")
											dontBreak2 = true //We have to check for multiple waterlevels in this square now
											
											
											local xMax = -35000
											local yMax = -35000
											local xMin = 35000
											local yMin = 35000
									
									
											if(xVar>xMax) then
												xMax = xVar
											end
											if(xVar<xMin) then
												xMin = xVar
											end
							
											if(yVar>yMax) then
												yMax = yVar
											end
											if(yVar<yMin) then
												yMin = yVar
											end
									
											table.insert( WaterZones, {zVar,Vector(xMin,yMin,0),Vector(xMax,yMax,0)} )
										else
											if(dontBreak2 == false) then //Makes sure we get traces of the whole square instead of just finding the first value and setting it as the max
												breakLoop2 = true 
											end
										end
									end
									
								end
							end
						end
					end




				end
			end		
		end
		
		for k, v in pairs(WaterZones) do //increase the size of our rectangle zones a little bit to compensate for the fact we can't find the actual borders
			v[2][1] = v[2][1] - 25
			v[2][2] = v[2][2] - 25
			v[3][1] = v[3][1] + 25
			v[3][2] = v[3][2] + 25
		end
		
		net.Start("Environments_client_getWaterBlacken")
			net.WriteTable(WaterZones)
		net.Broadcast()

	end
end)




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
