getgenv().RAYFIELD_ASSET_ID = 132249892549826

local GITHUB_TOKEN = "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"
local REPO_PATH = "aniketlande-dotcom/SAIOPS/main/"

local function GetPrivateFile(path)
	local url = "https://raw.githubusercontent.com/" .. REPO_PATH .. path
	local requestFunction = request or http_request or (syn and syn.request)

	if requestFunction then
		local response = requestFunction({
			Url = url,
			Method = "GET",
			Headers = {
				["Authorization"] = "token " .. GITHUB_TOKEN
			}
		})

		if response and response.Body then
			return response.Body
		end
	end

	return game:HttpGet(url, true)
end

loadstring(GetPrivateFile("modules/main.lua"))()
