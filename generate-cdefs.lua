-- This is far from a general-purpose solution, but for now it's "good enough"
local function preProcessHeaders(fileContents)
	local lines = {}
	for line in fileContents:gmatch("[^\r\n]+") do
		local isPreprocessorDirective = line:find("^#")
		local isCommentLine = line:find("^%s*//")
		local isExternC = line:find('extern "C"') -- This only works because the closing bracket features a comment, too
		if not (isPreprocessorDirective or isCommentLine or isExternC) then
			line = line:gsub("WGPU_EXPORT ", "")
			table.insert(lines, line)
		end
	end
	return table.concat(lines, "\n")
end

local headerFile = io.open("webgpu.h", "r")
local fileContents = headerFile:read("*a")
headerFile:close()

local cdefs = preProcessHeaders(fileContents)
local prefix = "return [[\n"
local suffix = "\n]]"

local cdefsFile = io.open("cdefs.lua", "w+")
local cdefString = prefix .. cdefs .. suffix
cdefsFile:write(cdefString)
cdefsFile:close()
