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

	self:NetworkVar( "Bool", 11, "DisableStaticAmbLight", { KeyName = "disableStaticAmb", Edit = { type = "Boolean", order = 14 } } )
	self:NetworkVar( "Bool", 12, "DisableStaticSelfIllum", { KeyName = "disableStaticIllum", Edit = { type = "Boolean", order = 15 } } )

	if SERVER then --Change the convars when the editor's variables are changed
		self:NetworkVarNotify( "AmbientLight", function(name, old, new)
			if self.lightEnv_suppressUpdate then self.lightEnv_suppressUpdate = nil return end
			RunConsoleCommand("Environment_ambientLightLevel", new)
		end )
		self:NetworkVarNotify( "Sunlight", function(name, old, new)
			if self.lightEnv_suppressUpdate then self.lightEnv_suppressUpdate = nil return end
			RunConsoleCommand("Environment_SunLightLevel", new)
		end )

		local function setupNotify(var, convar)
			self:NetworkVarNotify(var, function(ent, name, old, new)
				if self.lightEnv_suppressUpdate then self.lightEnv_suppressUpdate = nil return end
				local val = (new and "1") or "0"
				RunConsoleCommand(convar, val)
			end)
		end

		--Destroy CVars would previously always run in saves, because I wrongly assumed just having the default value
		--wouldn't trigger this function. I'm a bit surprised literally no one complained about this, given a lot of
		--people seem to use the editor entity.
		local function setupNotifyDestroy(var, convar)
			self:NetworkVarNotify(var, function(ent, name, old, new)
				if not new then return end
				RunConsoleCommand(convar)
			end)
		end

		setupNotify("DarkWater", "Environment_DarkenWater")
		setupNotify("Disable3DSky", "Environment_ForceDisabledSkybox")
		setupNotify("MatSpecular", "Environment_ForceDisabledCubemaps")
		setupNotify("r_radiosityZero", "Environment_ForceRadiosityZero")
		setupNotify("DarkRopes", "Environment_DarkenRopes")

		setupNotifyDestroy("RemoveLightBeams", "Environment_Destroy_Beams")
		setupNotifyDestroy("RemoveAmbient_generics", "Environment_Destroy_AmbientGeneric")
		setupNotifyDestroy("RemoveSprites", "Environment_Destroy_Sprites")
		setupNotifyDestroy("RemoveSmoke", "Environment_DestroySmokeVolume")
		setupNotifyDestroy("RemoveSoundscapes", "Environment_Destroy_Soundscapes")

		setupNotify("Stopsounds", "Environment_stopsoundscape")

		setupNotifyDestroy("DisableStaticAmbLight", "Environment_DisableStaticAmbientLighting")
		setupNotify("DisableStaticSelfIllum", "Environment_DisableStaticSelfIllum")


		--Grab whatever the current values are, without breaking existing saves/dupes
		timer.Simple(0, function()
			self.lightEnv_suppressUpdate = true
			self:SetAmbientLight(GetConVar("Environment_ambientLightLevel"):GetInt())
			self.lightEnv_suppressUpdate = true
			self:SetSunlight(GetConVar("Environment_sunLightLevel"):GetInt())

			self.lightEnv_suppressUpdate = true
			self:SetDarkWater(GetConVar("Environment_DarkenWater"):GetBool())
			self.lightEnv_suppressUpdate = true
			self:SetDisable3DSky(GetConVar("Environment_ForceDisabledSkybox"):GetBool())
			self.lightEnv_suppressUpdate = true
			self:Setr_radiosityZero(GetConVar("Environment_ForceRadiosityZero"):GetBool())
			self.lightEnv_suppressUpdate = true
			self:SetMatSpecular(GetConVar("Environment_ForceDisabledCubemaps"):GetBool())
			self.lightEnv_suppressUpdate = true
			self:SetDarkRopes(GetConVar("Environment_DarkenRopes"):GetBool())

			self.lightEnv_suppressUpdate = true
			self:SetDisableStaticSelfIllum(GetConVar("Environment_DisableStaticSelfIllum"):GetBool())
		end)
	end
end

--Keep editor values consistent with console values
cvars.AddChangeCallback("Environment_ambientLightLevel", function(convar_name, value_old, value_new)
	for i, v in ipairs(ents.FindByClass("ent_lighteditor")) do
		v.lightEnv_suppressUpdate = true
		v["Set" .. "AmbientLight"](v, tonumber(value_new))
	end
end)
cvars.AddChangeCallback("Environment_SunLightLevel", function(convar_name, value_old, value_new)
	for i, v in ipairs(ents.FindByClass("ent_lighteditor")) do
		v.lightEnv_suppressUpdate = true
		v["Set" .. "Sunlight"](v, tonumber(value_new))
	end
end)

local function cvarUpdate(var, convar)
	cvars.AddChangeCallback(convar, function(convar_name, value_old, value_new)
		for i, v in ipairs(ents.FindByClass("ent_lighteditor")) do
			v["Set" .. var](v, tobool(value_new))
		end
	end)
end
cvarUpdate("DarkWater", "Environment_DarkenWater")
cvarUpdate("Disable3DSky", "Environment_ForceDisabledSkybox")
cvarUpdate("MatSpecular", "Environment_ForceDisabledCubemaps")
cvarUpdate("r_radiosityZero", "Environment_ForceRadiosityZero")
cvarUpdate("DarkRopes", "Environment_DarkenRopes")
cvarUpdate( "DisableStaticSelfIllum", "Environment_DisableStaticSelfIllum" )
