

hook.Add( "PopulateToolMenu", "EnvironmentMenu", function()

	spawnmenu.AddToolMenuOption( "Utilities", "Admin", "EnvironmentControl", "Environment Control", "", "", function( panel )

		panel:ClearControls()


		panel:TextEntry( "SkyBox Texture", "sv_skyname" )

		panel:NumSlider( "Ambient Light", "Environment_ambientLightLevel", 1, 26, 0 )
		panel:NumSlider( "Sun Light", "Environment_SunLightLevel", 1, 26, 0 )

		panel:CheckBox( "Enable lamp/light fixer", "Environment_ChangeLightStyle" )
		panel:CheckBox( "Darken Water", "Environment_DarkenWater" )
		panel:CheckBox( "Forcibly disable the 3D skybox for all players", "Environment_ForceDisabledSkybox" )
		panel:CheckBox( "Automatically set mat_specular to 0 for all players", "Environment_ForceDisabledCubemaps" )
		panel:CheckBox( "r_radiosity 0 for all players", "Environment_ForceRadiosityZero" )
		panel:CheckBox( "Darken ropes", "Environment_DarkenRopes" )

		panel:Button( "Remove Light Beams", "Environment_Destroy_Beams", nil )
		panel:Button( "Remove Ambient_Generic (sound emitters)", "Environment_Destroy_AmbientGeneric", nil )
		panel:Button( "Remove Sprites", "Environment_Destroy_Sprites", nil )
		panel:Button( "Remove Smoke", "Environment_Destroy_SmokeVolume", nil )
		panel:Button( "Remove Soundscapes", "Environment_Destroy_Soundscapes", nil )

		panel:Button( "Stop sounds&soundscapes (Requires sv_cheats 1)", "Environment_stopsoundscape", nil )

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

		panel:CheckBox( "Disable Static Prop Self-Illumination", "Environment_DisableStaticSelfIllum" )
	end )
end )



