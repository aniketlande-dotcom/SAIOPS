getgenv().RAYFIELD_ASSET_ID = 132249892549826

local REPO_PATH = "aniketlande-dotcom/SAIOPS/main/"
local REPO_REF = "8778df8"

local function GetPublicFile(path)
	return game:HttpGet("https://raw.githubusercontent.com/aniketlande-dotcom/SAIOPS/" .. REPO_REF .. "/" .. path, true)
end

local function LoadModule(path)
	if type(loadstring) ~= "function" then
		error("SAIOPS: loadstring is not available in this executor.")
	end

	local source = GetPublicFile(path)
	if type(source) ~= "string" or source == "" then
		error("SAIOPS: unable to fetch " .. path .. " from the public repository.")
	end

	local chunk, loadError = loadstring(source)
	if not chunk then
		error("SAIOPS: invalid module " .. path .. ": " .. tostring(loadError))
	end

	return chunk()
end

LoadModule("modules/main.lua")
