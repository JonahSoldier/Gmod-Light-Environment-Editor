


hook.Add( "InitPostEntity", "playerBlackenWaterRequest", function()
	net.Start( "Environments_server_requestWaterBlacken" )
	net.SendToServer()
end)


net.Receive("Environments_client_redownloadlightmaps", function( len, ply )
	render.RedownloadAllLightmaps(true, true)
end)

net.Receive("Environments_client_stopSoundscape", function( len, ply )
	 RunConsoleCommand("stopsound")
	 RunConsoleCommand("stopsoundscape")
end)


net.Receive("Environments_client_changeLight", function( len, ply )

	local ent = net.ReadEntity()

	ent.Think = function()
		ent.BaseClass.Think( ent )
		if ( CLIENT ) then
					
			if ( !ent:GetOn() ) then return end

			local noworld = ent:GetLightWorld()
			local dlight = DynamicLight( ent:EntIndex(), noworld )

			if ( dlight ) then

				local c = ent:GetColor()

				local size = ent:GetLightSize()
				local brght = ent:GetBrightness()
				-- Clamp for multiplayer
				if ( !game.SinglePlayer() ) then
					size = math.Clamp( size, 0, 1024 )
					brght = math.Clamp( brght, 0, 6 )
				end

				dlight.Pos = ent:GetPos()
				dlight.r = c.r
				dlight.g = c.g
				dlight.b = c.b
				dlight.Brightness = brght
				dlight.Decay = size * 5
				dlight.Size = size
				dlight.DieTime = CurTime() + 1
				dlight.Style = 32

				dlight.noworld = noworld
				dlight.nomodel = ent:GetLightModels()
			end

		end
	end
end)



net.Receive("Environments_client_forcedisablesky", function( len, ply )
	
	RunConsoleCommand( "r_3dsky", net.ReadUInt(1) )
end)

net.Receive("Environments_client_forcedisablespecular", function( len, ply )
	
	LocalPlayer():ChatPrint( "Changing mat_specular to 0 in 5 seconds. You may freeze temporarily when this happens." )
	
	timer.Simple(5, function() 
		
		RunConsoleCommand( "mat_specular", 0 )
		
	end)
	
end)

cvars.AddChangeCallback( "r_3dsky",  function(convar_name, value_old, value_new)

	if(GetConVar("Environment_ForceDisabledSkybox"):GetBool() == true) then
		if(value_new == "1") then
			RunConsoleCommand( "r_3dsky", 0 )
		end
	end
end)


net.Receive("Environments_client_getWaterBlacken", function( len, ply )
	waterZones = net.ReadTable()
end)




hook.Add( "PostDrawTranslucentRenderables", "Waterblackener", function()

	local shouldDarkenWater = GetGlobalBool( "environment_darkenWater", false)

	if(shouldDarkenWater && waterZones ~= nil) then
		for k, v in pairs(waterZones) do
			//zvar
			//mins
			//maxs
			local zLev = v[1]
			local xMin = v[2][1]
			local yMin = v[2][2]
			local xMax = v[3][1]
			local yMax = v[3][2]

			local ambLightLev = GetGlobalInt( "environment_ambientLightLevel", 12 )
		
			render.SetColorMaterial()

			//Render higher up at a distance to avoid z fighting
			local distToBox = Vector((xMin+xMax)/2,(yMin+yMax)/2,zLev) - EyePos()
			local adjustHeight = (distToBox[3]*distToBox[3])*0.0000005

			if(adjustHeight>5) then
				adjustHeight = 5
			end

			render.DrawBox( Vector(0,0,0), Angle(0,0,0), Vector(xMin,yMin,zLev-(adjustHeight+2)),Vector(xMax,yMax,zLev+adjustHeight+0.5), Color( 0, 0, 0, (255/ambLightLev)-2 ) )
		end
	end

end )
