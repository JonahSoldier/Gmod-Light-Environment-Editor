

AddCSLuaFile()
DEFINE_BASECLASS( "base_edit" )


ENT.Category = "Editors"
ENT.PrintName = "Light/Environment editor"
ENT.Author = "JonahSoldier"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Editable = true


function ENT:Initialize()
	BaseClass.Initialize( self )
	self:SetMaterial( "light_editor/edit_light" )
end



function ENT:SetupDataTables()

	self:NetworkVar( "Int", 0, "AmbientLight", { KeyName = "AmbLight", Edit = { type = "Int", min = 1, max = 26, order = 1 } } )
	self:NetworkVar( "Int", 1, "Sunlight", { KeyName = "SunLight", Edit = { type = "Int", min = 1, max = 26, order = 2 } } )

	self:NetworkVar( "Bool", 0, "DarkWater", { KeyName = "darkWater", Edit = { type = "Boolean", order = 3 } } )
	self:NetworkVar( "Bool", 1, "Disable3DSky", { KeyName = "disable3DSky", Edit = { type = "Boolean", order = 4 } } )
	self:NetworkVar( "Bool", 2, "MatSpecular", { KeyName = "matSpec", Edit = { type = "Boolean", order = 5 } } )
	self:NetworkVar( "Bool", 3, "r_radiosityZero", { KeyName = "radiosity", Edit = { type = "Boolean", order = 6 } } )
	self:NetworkVar( "Bool", 4, "DarkRopes", { KeyName = "darkRopes", Edit = { type = "Boolean", order = 7 } } )

	self:NetworkVar( "Bool", 5, "RemoveLightBeams", { KeyName = "rLightbeams", Edit = { type = "Boolean", order = 8 } } )
	self:NetworkVar( "Bool", 6, "RemoveAmbient_generics", { KeyName = "rAmbGeneric", Edit = { type = "Boolean", order = 9 } } )
	self:NetworkVar( "Bool", 7, "RemoveSprites", { KeyName = "rSprites", Edit = { type = "Boolean", order = 10 } } )
	self:NetworkVar( "Bool", 8, "RemoveSmoke", { KeyName = "rSmoke", Edit = { type = "Boolean", order = 11 } } )
	self:NetworkVar( "Bool", 9, "RemoveSoundscapes", { KeyName = "rSoundscapes", Edit = { type = "Boolean", order = 12 } } )

	self:NetworkVar( "Bool", 10, "Stopsounds", { KeyName = "stopsounds", Edit = { type = "Boolean", order = 13 } } )

	if SERVER then //Change the convars when the editor's variables are changed
		self:NetworkVarNotify( "AmbientLight", function(name, old, new) RunConsoleCommand("Environment_ambientLightLevel", new) end )
		self:NetworkVarNotify( "Sunlight", function(name, old, new) RunConsoleCommand("Environment_SunLightLevel", new) end )
		
		local function setupNotify(var, convar)
			self:NetworkVarNotify(var, function(ent, name, old, new) 
				if new then
					RunConsoleCommand(convar, "1")
				else
					RunConsoleCommand(convar, "0")
				end 
			end)
		end
		
		setupNotify("DarkWater", "Environment_DarkenWater")
		setupNotify("Disable3DSky", "Environment_ForceDisabledSkybox")
		setupNotify("MatSpecular", "Environment_ForceDisabledCubemaps")
		setupNotify("r_radiosityZero", "Environment_ForceRadiosityZero")
		setupNotify("DarkRopes", "Environment_DarkenRopes")

		setupNotify("RemoveLightBeams", "Environment_Destroy_Beams")
		setupNotify("RemoveAmbient_generics", "Environment_Destroy_AmbientGeneric")
		setupNotify("RemoveSprites", "Environment_Destroy_Sprites")
		setupNotify("RemoveSmoke", "Environment_DestroySmokeVolume")
		setupNotify("RemoveSoundscapes", "Environment_Destroy_Soundscapes")

		setupNotify("Stopsounds", "Environment_stopsoundscape")
	end
end