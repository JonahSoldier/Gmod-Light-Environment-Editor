

AddCSLuaFile()
DEFINE_BASECLASS( "base_edit" )


ENT.Category = "Editors"
ENT.PrintName= "Light/Environment editor"
ENT.Author= "JonahSoldier"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Editable = true


function ENT:Initialize()

	BaseClass.Initialize( self )
	self:SetMaterial( "gmod/edit_sky" )
	self:SetColor( Color(30, 30, 30, 255) )
	
	if SERVER then


		self.lastAmblight = 12
		self.lastSunlight = 12
	
		self.last3DSky = false
		self.lastMatSpec = false
		self.lastDarkWater = false

		self.lastRLightbeams = false
		self.lastRambGenerics = false
		self.lastRSprites = false
		self.lastRSmoke = false
		self.lastRSoundscapes = false
	
		self.lastStopSounds = false 

	end
end



function ENT:SetupDataTables()

	self:NetworkVar( "Int", 0, "AmbientLight", { KeyName = "AmbLight", Edit = { type = "Int", min = 1, max = 26, order = 1 } } )
	self:NetworkVar( "Int", 1, "Sunlight", { KeyName = "SunLight", Edit = { type = "Int", min = 1, max = 26, order = 2 } } )

	self:NetworkVar( "Bool", 0, "Disable3DSky", { KeyName = "disable3DSky", Edit = { type = "Boolean", order = 3 } } )
	self:NetworkVar( "Bool", 1, "MatSpecular", { KeyName = "matSpec", Edit = { type = "Boolean", order = 3 } } )
	self:NetworkVar( "Bool", 2, "DarkWater", { KeyName = "darkWater", Edit = { type = "Boolean", order = 3 } } )

	self:NetworkVar( "Bool", 3, "RemoveLightBeams", { KeyName = "rLightbeams", Edit = { type = "Boolean", order = 4 } } )
	self:NetworkVar( "Bool", 4, "RemoveAmbient_generics", { KeyName = "rAmbGeneric", Edit = { type = "Boolean", order = 5 } } )
	self:NetworkVar( "Bool", 5, "RemoveSprites", { KeyName = "rSprites", Edit = { type = "Boolean", order = 6 } } )
	self:NetworkVar( "Bool", 6, "RemoveSmoke", { KeyName = "rSmoke", Edit = { type = "Boolean", order = 7 } } )
	self:NetworkVar( "Bool", 7, "RemoveSoundscapes", { KeyName = "rSoundscapes", Edit = { type = "Boolean", order = 8 } } )

	self:NetworkVar( "Bool", 8, "Stopsounds", { KeyName = "stopsounds", Edit = { type = "Boolean", order = 9 } } )

	/*
	if ( SERVER ) then
		self:SetAmbientLight(12)
		self:SetSunlight(12)
	end
	*/
end
