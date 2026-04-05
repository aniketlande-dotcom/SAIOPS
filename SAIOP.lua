getgenv().RAYFIELD_ASSET_ID = 132249892549826

local MAIN_LOADER_URL = "https://raw.githubusercontent.com/aniketlande-dotcom/SAIOPS/main/modules/main.lua"

if type(loadstring) ~= "function" then
	error("SAIOPS: loadstring is not available in this executor.")
end

local source = game:HttpGet(MAIN_LOADER_URL, true)
if type(source) ~= "string" or source == "" then
	error("SAIOPS: unable to fetch modules/main.lua from branch main.")
end

local chunk, loadError = loadstring(source)
if not chunk then
	error("SAIOPS: invalid modules/main.lua: " .. tostring(loadError))
end

chunk()
