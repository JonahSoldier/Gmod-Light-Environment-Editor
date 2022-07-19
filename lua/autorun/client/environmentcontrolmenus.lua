

hook.Add( "PopulateToolMenu", "EnvironmentMenu", function()

	spawnmenu.AddToolMenuOption( "Utilities", "Admin", "EnvironmentControl", "Environment Control", "", "", function( panel )

		panel:ClearControls()


		panel:TextEntry( "SkyBox Texture", "sv_skyname" )

		panel:NumSlider( "Ambient Light", "Environment_ambientLightLevel", 1, 26, 0 )
		panel:NumSlider( "Sun Light", "Environment_SunLightLevel", 1, 26, 0 )

		panel:CheckBox( "Enable lamp/light fixer", "Environment_ChangeLightStyle" )
		panel:CheckBox( "Forcibly disable the 3D skybox for all players", "Environment_ForceDisabledSkybox" )
		panel:CheckBox( "Automatically set mat_specular to 0 for all players", "Environment_ForceDisabledCubemaps" )
		panel:CheckBox( "Artificially darken water (will cause a lag spike when activated)", "Environment_DarkenWater" )

		panel:Button( "Remove Light Beams", "Environment_Destroy_Beams", nil )
		panel:Button( "Remove Ambient_Generic (sound emitters)", "Environment_Destroy_AmbientGeneric", nil )
		panel:Button( "Remove Sprites", "Environment_Destroy_Sprites", nil )
		panel:Button( "Remove Smoke", "Environment_Destroy_SmokeVolume", nil )
		panel:Button( "Remove Soundscapes", "Environment_Destroy_Soundscapes", nil )

		panel:Button( "Stop sounds&soundscapes (Requires sv_cheats 1)", "Environment_stopsoundscape", nil )
	end )
end )



