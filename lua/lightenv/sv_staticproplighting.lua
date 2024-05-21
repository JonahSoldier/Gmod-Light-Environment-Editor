--Not super happy with how I structured this, but it works fine.

local function readStaticPropMaterials(callOnFinish)
	file.AsyncRead( "maps/" .. game.GetMap() .. ".bsp" , "GAME", function( fileName, gamePath, status, data )
		if not status == FSASYNC_OK then
			print("Light/Environment Editor: Failed to open map .BSP | " .. tostring(status))
			return
		end

		--Pretty cursed method of getting the materials used by a map's static props. As far as I'm aware there aren't any better ways of doing this.
		lightEnv.staticPropMats = {}
		local matEnt = ents.Create( "prop_physics" )

		local startPos, endPos = string.find(data, "models/[%w/_]*%.mdl")
		while startPos do
			if not(string.sub(data, startPos-8, startPos-4) == "model") then --Exclude physics props
				matEnt:SetModel(string.sub(data, startPos, endPos))
				table.Add(lightEnv.staticPropMats, matEnt:GetMaterials())
			end
			startPos, endPos = string.find(data, "models/[%w/_]*%.mdl", endPos)
		end
		matEnt:Remove()
		print("Light/Environment Editor: Successfully opened map .BSP and read static props")
		if isfunction(callOnFinish) then
			callOnFinish()
		end
	end)
end

local function disableStaticAmbientLighting()
	if not lightEnv.staticPropMats then
		readStaticPropMaterials(disableStaticAmbientLighting)
		return
	end

	local flatNormalMat = Material("lightEnv/flat_normal")
	local flatNormal = flatNormalMat:GetTexture("$basetexture")

	for i, v in ipairs(lightEnv.staticPropMats) do
		local mat = Material(v)
		local normalMap = mat:GetTexture( "$bumpmap" )
		if not(normalMap) or not(normalMap:IsError()) then
			mat:SetTexture( "$bumpmap", flatNormal )
		end
	end
	print("Light/Environment Editor: Disabled ambient lighting on static props materials")
end

local function disableStaticSelfIllum()
	if not lightEnv.staticPropMats then
		readStaticPropMaterials(disableStaticSelfIllum)
		return
	end
	lightEnv.staticPropMatFlags = lightEnv.staticPropMatFlags or {}

	for i, v in ipairs(lightEnv.staticPropMats) do
		local mat = Material(v)
		local flags = mat:GetInt("$flags")
		lightEnv.staticPropMatFlags[i] = bit.band(flags, 64)
		local newFlags = bit.band(flags, 1073741759)
		mat:SetInt("$flags", newFlags)
	end
	print("Light/Environment Editor: Disabled self-illumination on static props materials")
end


concommand.Add("Environment_DisableStaticAmbientLighting", function(player)
	if not player:IsSuperAdmin() then return end
	disableStaticAmbientLighting()
end)

cvars.AddChangeCallback( "Environment_DisableStaticSelfIllum", function(convar_name, value_old, value_new)
	if tobool(value_new) then
		disableStaticSelfIllum()
		return
	end
	if not lightEnv.staticPropMatFlags then return end

	for i, v in ipairs(lightEnv.staticPropMats) do
		local mat = Material(v)
		local newFlags = bit.bor(mat:GetInt("$flags"), lightEnv.staticPropMatFlags[i])
		mat:SetInt("$flags", newFlags)
	end
	print("Light/Environment Editor: Re-Enabled self-illumination on static props materials")
end)
