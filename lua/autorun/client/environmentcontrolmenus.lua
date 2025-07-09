local function lightEnv_updateCVar(newVal, cvarName)
	if LocalPlayer():IsListenServerHost() then return end 

	net.Start("Environments_server_setcv")
		net.WriteString(cvarName)

		if isbool(newVal) then
			net.WriteUInt(0, 2)
			net.WriteBool(newVal)
		elseif isnumber(newVal) then
			net.WriteUInt(1, 2)
			net.WriteUInt(newVal, 8)
		elseif isstring(newVal) then
			net.WriteUInt(2, 2)
			net.WriteString(newVal)
		end
	net.SendToServer()
end

hook.Add( "PopulateToolMenu", "EnvironmentMenu", function()
	spawnmenu.AddToolMenuOption( "Utilities", "Admin", "EnvironmentControl", "Environment Control", "", "", function( panel )
		panel:ClearControls()

		local skyName	 = panel:TextEntry( "SkyBox Texture", "sv_skyname" )
		function skyName:OnEnter(newVal) lightEnv_updateCVar(newVal, "sv_skyname") end

		local aLight	= panel:NumSlider( "Ambient Light", "Environment_ambientLightLevel", 1, 26, 0 )
		local sLight	= panel:NumSlider( "Sun Light", "Environment_SunLightLevel", 1, 26, 0 )
		function aLight:OnValueChanged(newVal) lightEnv_updateCVar(newVal, "Environment_ambientLightLevel") end
		function sLight:OnValueChanged(newVal) lightEnv_updateCVar(newVal, "Environment_SunLightLevel") end

		local lFixer	= panel:CheckBox( "Enable lamp/light fixer", "Environment_ChangeLightStyle" )
		local dWater	= panel:CheckBox( "Darken Water", "Environment_DarkenWater" )
		local d3DSky	= panel:CheckBox( "Forcibly disable the 3D skybox for all players", "Environment_ForceDisabledSkybox" )
		local matSpec	= panel:CheckBox( "Automatically set mat_specular to 0 for all players", "Environment_ForceDisabledCubemaps" )
		local dDetail	= panel:CheckBox( "Disable detail props for all players", "Environment_ForceDisabledDetailProps" )
		local dRad		= panel:CheckBox( "r_radiosity 0 for all players", "Environment_ForceRadiosityZero" )
		local dRope		= panel:CheckBox( "Darken ropes", "Environment_DarkenRopes" )
		function lFixer:OnChange(newVal) lightEnv_updateCVar(newVal, "Environment_ChangeLightStyle") end
		function dWater:OnChange(newVal) lightEnv_updateCVar(newVal, "Environment_DarkenWater") end
		function d3DSky:OnChange(newVal) lightEnv_updateCVar(newVal, "Environment_ForceDisabledSkybox") end
		function matSpec:OnChange(newVal) lightEnv_updateCVar(newVal, "Environment_ForceDisabledCubemaps") end
		function dDetail:OnChange(newVal) lightEnv_updateCVar(newVal, "Environment_ForceDisabledDetailProps") end
		function dRad:OnChange(newVal) lightEnv_updateCVar(newVal, "Environment_ForceRadiosityZero") end
		function dRope:OnChange(newVal) lightEnv_updateCVar(newVal, "Environment_DarkenRopes") end


		local btn		= panel:Button( "Remove Light Beams", "Environment_Destroy_Beams")
		btn:DockMargin(0,20,0,0)
		local hLight	= panel:CheckBox( "Hide Light Beams (unreliable)", "Environment_Hide_Beams" )
		function hLight:OnChange(newVal) lightEnv_updateCVar(newVal, "Environment_Hide_Beams") end


		panel:Button( "Remove Sprites", "Environment_Destroy_Sprites")
		local hSprites	= panel:CheckBox( "Hide Sprites (unreliable)", "Environment_Hide_Sprites")
		function hSprites:OnChange(newVal) lightEnv_updateCVar(newVal, "Environment_Hide_Sprites") end


		panel:Button( "Remove Ambient_Generic (sound emitters)", "Environment_Destroy_AmbientGeneric")
		panel:Button( "Remove Smoke", "Environment_Destroy_SmokeVolume")
		panel:Button( "Remove Particle Emitters", "Environment_Destroy_Particles")
		panel:Button( "Remove Soundscapes", "Environment_Destroy_Soundscapes")

		panel:Button( "Stop sounds&soundscapes (Requires sv_cheats 1)", "Environment_stopsoundscape")


		local staticAmbButton = vgui.Create("DButton", panel)
		staticAmbButton:DockMargin( 11, 35, 11, 0 )
		staticAmbButton:Dock( TOP )
		staticAmbButton:SetText( "Disable Static Prop Ambient Light" )

		staticAmbButton.DoClick = function()
			local frame = vgui.Create("DFrame")
			frame:SetSize(450, 100)
			frame:SetTitle("Are you sure?")
			frame:Center()
			frame:MakePopup()

			local label = vgui.Create("DLabel", frame)
			label:Dock( TOP )
			label:SetText( [[This will disable Ambient light on static props until you re-load the map.
			This might be undesirable if you want to use normal lighting levels as well as dark ones.]] )
			label:SizeToContents()

			local buttonPnl = vgui.Create("DPanel", frame)
			buttonPnl:Dock( BOTTOM )
			buttonPnl:SetBackgroundColor( Color(122, 125, 128) )

			local buttonYes = vgui.Create("DButton", buttonPnl)
			buttonYes:SetText("Yes")
			buttonYes:Dock( LEFT )
			buttonYes.DoClick = function()
				RunConsoleCommand( "Environment_DisableStaticAmbientLighting" )
				frame:Close()
			end

			local buttonNo = vgui.Create("DButton", buttonPnl)
			buttonNo:SetText("No")
			buttonNo:Dock( RIGHT )
			buttonNo.DoClick = function()
				frame:Close()
			end
			frame:SizeToContents()
		end

		local dIllum = panel:CheckBox( "Disable Static Prop Self-Illumination", "Environment_DisableStaticSelfIllum" )
		function dIllum:OnChange(newVal) lightEnv_updateCVar(newVal, "Environment_DisableStaticSelfIllum") end
	end )
end )



