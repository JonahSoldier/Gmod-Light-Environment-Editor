
AddCSLuaFile( "shared.lua" )  

include('shared.lua')


/*
function ENT:Initialize()
	
	self:SetambLight(12)
	self:SetsunLight(12)
end
*/

function ENT:Think() 

	
	//save me having to write as much code
	local function varChange(last, current, convar)
		if(current != last) then 
			if(type(current) == "boolean") then
				
				if (current) then RunConsoleCommand( convar, "1" ) else RunConsoleCommand( convar, "0" ) end
			else
				RunConsoleCommand( convar, current )
			end
			return true
		end
		return false
	end

	//light editors
	if(varChange(self.lastAmblight, self:GetAmbientLight(), "Environment_ambientLightLevel" )) then self.lastAmblight = self:GetAmbientLight() end
	if(varChange(self.lastSunlight, self:GetSunlight(), "Environment_sunLightLevel" )) then self.lastSunlight = self:GetSunlight() end
	
	//checkbox equivalents
	if(varChange(self.last3DSky, self:GetDisable3DSky(), "Environment_ForceDisabledSkybox" )) then self.last3DSky = self:GetDisable3DSky() end
	if(varChange(self.lastMatSpec, self:GetMatSpecular(), "Environment_ForceDisabledCubemaps" )) then self.lastMatSpec = self:GetMatSpecular() end
	if(varChange(self.lastDarkWater, self:GetDarkWater(), "Environment_DarkenWater" )) then self.last3DSky = self:GetDarkWater() end

	//Button equivalents
	if(varChange(self.lastRLightbeams, self:GetRemoveLightBeams(), "Environment_Destroy_Beams" )) then self.lastRLightbeams = self:GetRemoveLightBeams() end
	if(varChange(self.lastRambGenerics, self:GetRemoveAmbient_generics(), "Environment_Destroy_AmbientGeneric" )) then self.lastRambGenerics = self:GetRemoveAmbient_generics() end
	if(varChange(self.lastRSprites, self:GetRemoveSprites(), "Environment_Destroy_Sprites" )) then self.lastRSprites = self:GetRemoveSprites() end
	if(varChange(self.lastRSmoke, self:GetRemoveSmoke(), "Environment_Destroy_SmokeVolume" )) then self.lastRSmoke = self:GetRemoveSmoke() end
	if(varChange(self.lastRSoundscapes, self:GetRemoveSoundscapes(), "Environment_Destroy_Soundscapes" )) then self.lastRSoundscapes = self:GetRemoveSoundscapes() end

	//stopsound&soundscape
	if(varChange(self.lastStopSounds, self:GetStopsounds(), "Environment_stopSoundscape" )) then self.lastStopSounds = self:GetStopsounds() end
	

	self:NextThink(CurTime()+1)
	return true
end



function ENT:OnRemove()
	//Prevents people who haven't figured out how to use editors from making the map dark for the rest of the session
	RunConsoleCommand("Environment_ambientLightLevel", 12)
	RunConsoleCommand("Environment_SunLightLevel", 12)
end
