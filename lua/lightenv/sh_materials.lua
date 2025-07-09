AddCSLuaFile()

hook.Add("InitPostEntity", "Environments_init_materials", function()
	--Stuff for the new less terrible water darkening
	lightEnv.defaultWaterFogs = {}
	for i, v in ipairs(game.GetWorld():GetBrushSurfaces()) do
		if v:IsWater() then
			local mat = v:GetMaterial()
			local fogCol = mat:GetVector("$fogcolor")
			if fogCol then
				table.insert(lightEnv.defaultWaterFogs, {
					["Material"] = mat,
					["Fog"] = fogCol * 1 --Create a copy not a reference
				})
			end
		end
	end

	if CLIENT then --Update based on what the server's telling us.
		lightEnv.updateDarkenWater()
	end
end)

function lightEnv.updateDarkenWater() --Called by the cvars/cmds
	if not lightEnv.defaultWaterFogs then return end
	local darken = GetGlobalInt("environment_ambientLightLevel") / 12
	darken = (lightEnv.darkenWater_cv:GetBool() and darken) or 1
	for i, v in ipairs(lightEnv.defaultWaterFogs) do
		v.Material:SetVector("$fogcolor", v.Fog * darken)
	end
	
	if SERVER then 
		timer.Simple(0.5, function()
			net.Start("Environments_client_updateDarkenWater")
			net.Broadcast()
		end)
	end
end

if CLIENT then 
	net.Receive("Environments_client_updateDarkenWater", function(len)
		lightEnv.updateDarkenWater()
	end)
end