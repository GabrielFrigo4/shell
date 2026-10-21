-- ----------------------------------------------------------------
-- Module: Windows CMD Clink Prompt & Profile
-- ----------------------------------------------------------------

-- ================================
-- STARTUP
-- ================================

local function CLINK_DIR() return [[C:\Program Files\Shell\clink]] end
local function SYSTEM32_DIR() return [[C:\Windows\System32]] end
local function SYSTEM32_PATH(file) return SYSTEM32_DIR() .. [[\]] .. file end

local startup = {
	cwd = os.getcwd(),
}

-- ================================
-- SYSTEM
-- ================================

local function is_dir(p)
	if not p or p == "" then return false end
	if path and path.is_dir then return path.is_dir(p) end
	if os.isdir then return os.isdir(p) end
	local ok, _, code = os.rename(p, p)
	if ok or code == 13 or code == 17 then return true end
	return false
end

local function is_file(p)
	if not p or p == "" then return false end
	if path and path.is_file then return path.is_file(p) end
	if os.isfile then return os.isfile(p) end
	local f = io.open(p, "r")
	if f then f:close() return true end
	return false
end

local function exists(p)
	if not p or p == "" then return false end
	return is_dir(p) or is_file(p)
end

local function is_git_repo(dir)
	if not dir or dir == "" then return false end
	if path and path.is_dir and path.is_dir(dir .. [[\.git]]) then return true end
	if os.isdir and os.isdir(dir .. [[\.git]]) then return true end
	local f = io.open(dir .. [[\.git\HEAD]], "r") or io.open(dir .. [[\.git\config]], "r") or io.open(dir .. [[\.git]], "r")
	if f then
		f:close()
		return true
	end
	return false
end

local function has_cmd(cmd)
	if not cmd or cmd == "" then return false end
	local handle = io.popen([[where ]] .. cmd .. [[ 2>nul]])
	if handle then
		local res = handle:read("*a")
		handle:close()
		return res and res:match("%S") ~= nil
	end
	return false
end

-- ================================
-- ENVIRONMENT
-- ================================

local current = {
	prompt = nil,
	branch = nil,
	venv = nil,
	cwd = nil,
	dir = nil,
}

-- ================================
-- MSYS2 ENVIRONMENT
-- ================================

local function trim(s)
	return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

local function get_msys2_home()
	local explicit = os.getenv("MSYS2_HOME")
	if explicit and is_dir(explicit) then return explicit end

	local root = os.getenv("MSYS2_ROOT") or [[C:\msys64]]
	local home_base = root .. [[\home]]
	if not is_dir(home_base) then return nil end

	local user = os.getenv("MSYS2_USER") or os.getenv("USERNAME") or ""
	if user ~= "" then
		if is_dir(home_base .. [[\]] .. user) then
			return home_base .. [[\]] .. user
		end
		if is_dir(home_base .. [[\]] .. string.lower(user)) then
			return home_base .. [[\]] .. string.lower(user)
		end
	end

	local pipe = io.popen([[dir "]] .. home_base .. [[" /b /ad 2>nul]])
	if pipe then
		for line in pipe:lines() do
			local folder = trim(line)
			if folder ~= "" and is_dir(home_base .. [[\]] .. folder) then
				pipe:close()
				return home_base .. [[\]] .. folder
			end
		end
		pipe:close()
	end

	return nil
end

MSYS_HOME = get_msys2_home()

local function to_unix_path(p)
	local u = p:gsub("\\", "/")
	local drive, rest = u:match("^([A-Za-z]):(.*)")
	if drive then
		return "/" .. drive:lower() .. rest
	end
	return u
end

local function get_bash_cmd()
	local roots = {
		os.getenv("MSYS2_ROOT"),
		[[C:\msys64]],
		[[D:\msys64]],
		[[E:\msys64]],
		(os.getenv("LOCALAPPDATA") or "") .. [[\Programs\msys64]],
		[[C:\Program Files\Git]],
	}
	for _, r in ipairs(roots) do
		if r and r ~= "" then
			if is_file(r .. [[\usr\bin\bash.exe]]) then
				return [["]] .. r .. [[\usr\bin\bash.exe"]]
			elseif is_file(r .. [[\bin\bash.exe]]) then
				return [["]] .. r .. [[\bin\bash.exe"]]
			end
		end
	end

	local pipe = io.popen([[where bash.exe 2>nul]])
	if pipe then
		for line in pipe:lines() do
			local p = trim(line)
			if p ~= "" and not p:lower():find("system32") and is_file(p) then
				pipe:close()
				return [["]] .. p .. [["]]
			end
		end
		pipe:close()
	end

	return nil
end

local function load_vault_lua()
	local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
	local candidates = {}
	local function add(p) if p and p ~= "" then table.insert(candidates, p) end end
	add(os.getenv("VAULT_DIR"))
	add(home .. [[\.local\share\vault]])
	add(home .. [[\.config\vault]])
	add(home .. [[\.vault]])
	if MSYS_HOME then
		add(MSYS_HOME .. [[\.local\share\vault]])
		add(MSYS_HOME .. [[\.config\vault]])
		add(MSYS_HOME .. [[\.vault]])
	end
	for _, p in ipairs(candidates) do
		local f = p .. [[\vault.lua]]
		if is_file(f) then
			pcall(dofile, f)
			break
		end
	end
end
load_vault_lua()

-- ================================
-- CONSTANT
-- ================================

local function IO_POPEN_SIZE() return 0 end
local function DEFAULT_USER_NAME() return "gabriel" end
local function DEFAULT_BRANCH_DATA() return "" end

-- ================================
-- FUNCTIONS
-- ================================

local function split(str, pattern)
	local str_list = {}
	for chunk in str:gmatch("[^" .. pattern .. "]+") do
		table.insert(str_list, chunk)
	end
	return str_list
end

local function last(list)
	return list[#list]
end

local function size(file)
	return file:seek("end")
end

local function get_admin()
	local handle = io.popen(SYSTEM32_PATH("whoami") .. [[ /groups | ]] .. SYSTEM32_PATH("find") .. [[ " S-1-16-12288 "]])
	if handle == nil then
		return false
	end
	local content = handle:read("*l")
	handle:close()

	if content == nil then
		return false
	end
	local admin = #content > IO_POPEN_SIZE()
	return admin
end

local function get_user()
	local handle = io.popen(SYSTEM32_PATH("whoami"))
	if handle == nil then
		return DEFAULT_USER_NAME()
	end
	local content = handle:read("*l")
	handle:close()

	if content == nil then
		return DEFAULT_USER_NAME()
	end
	return last(split(content, "\\"))
end

local function get_git_branch()
	local handle = io.popen([[git symbolic-ref --short HEAD 2>nul]])
	if handle == nil then
		return { branch = DEFAULT_BRANCH_DATA(), is_dirty = false }
	end
	local content = handle:read("*a")
	handle:close()

	if content == nil then
		return { branch = DEFAULT_BRANCH_DATA(), is_dirty = false }
	end
	local branch_data = content:match("(.+)\n")
	if not branch_data then
		return { branch = nil, is_dirty = false }
	end

	local is_dirty = false
	local dh = io.popen([[git status --porcelain=v1 -uno --ignore-submodules=dirty 2>nul]])
	if dh then
		local dres = dh:read("*l")
		dh:close()
		if dres and trim(dres) ~= "" then
			is_dirty = true
		end
	end

	local branch_info = {
		branch = branch_data,
		is_dirty = is_dirty,
	}
	return branch_info
end

local function get_win_info()
	local handle = io.popen("ver")
	if handle == nil then return "NT" end
	local content = handle:read("*a")
	handle:close()

	local build = content:match("10%.0%.(%d+)")
	if build then
		local bnum = tonumber(build)
		local dv = nil
		local reg = io.popen('reg query "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion" /v DisplayVersion 2>nul')
		if reg then
			local reg_out = reg:read("*a")
			reg:close()
			dv = reg_out:match("DisplayVersion%s+REG_SZ%s+(%S+)")
		end
		if bnum >= 22000 then
			return (dv and dv ~= "") and ("11 " .. dv) or "11"
		elseif bnum >= 10240 then
			return (dv and dv ~= "") and ("10 " .. dv) or "10"
		else
			return "NT 10.0"
		end
	end
	return "NT"
end

local function get_win_icon()
	local handle = io.popen("ver")
	if handle == nil then return "" end
	local content = handle:read("*a")
	handle:close()

	local build = content:match("10%.0%.(%d+)")
	if build then
		if tonumber(build) >= 22000 then
			return ""
		else
			return ""
		end
	end
	return ""
end

local function extract_prompt(prompt)
	local prompt_venv = string.match(prompt, "^%((.-)%)")
	local prompt_cwd = os.getcwd()
	local prompt_dir = last(split(prompt_cwd, "\\"))
	if prompt_cwd == os.getenv("HOME") or prompt_cwd == os.getenv("USERPROFILE") or (MSYS_HOME and prompt_cwd == MSYS_HOME) then
		prompt_dir = "~"
	end

	local prompt_info = {
		venv = prompt_venv,
		cwd = prompt_cwd,
		dir = prompt_dir,
	}
	return prompt_info
end

-- ================================
-- CONSTANT COLORS
-- ================================

local function GET_RESET() return "\x1b[0m" end
local function GET_BOLD() return "\x1b[1m" end
local function GET_ITALIC() return "\x1b[3m" end
local function GET_UNDERLINE() return "\x1b[4m" end

local function GET_BLACK() return "0" end
local function GET_RED() return "1" end
local function GET_GREEN() return "2" end
local function GET_YELLOW() return "3" end
local function GET_BLUE() return "4" end
local function GET_MAGENTA() return "5" end
local function GET_CYAN() return "6" end
local function GET_WHITE() return "7" end

-- ================================
-- FUNCTIONS COLORS
-- ================================

local function create_rgb_color(r, g, b)
	local color = {
		r = r,
		g = g,
		b = b,
	}
	return color
end

local function set_text_color(color)
	return "\x1b[3" .. color .. "m"
end

local function set_background_color(color)
	return "\x1b[4" .. color .. "m"
end

local function set_text_bright_color(color)
	return "\x1b[9" .. color .. "m"
end

local function set_background_bright_color(color)
	return "\x1b[10" .. color .. "m"
end

local function set_text_extra_color(color)
	return "\x1b[38;5;" .. color .. "m"
end

local function set_background_extra_color(color)
	return "\x1b[48;5;" .. color .. "m"
end

local function set_text_rgb_color(color)
	return "\x1b[38;2;" .. color.r .. ";" .. color.g .. ";" .. color.b .. "m"
end

local function set_background_rgb_color(color)
	return "\x1b[48;2;" .. color.r .. ";" .. color.g .. ";" .. color.b .. "m"
end

local function text_black(str)
	return set_text_color(GET_BLACK()) .. str .. GET_RESET()
end
local function text_red(str)
	return set_text_color(GET_RED()) .. str .. GET_RESET()
end
local function text_green(str)
	return set_text_color(GET_GREEN()) .. str .. GET_RESET()
end
local function text_yellow(str)
	return set_text_color(GET_YELLOW()) .. str .. GET_RESET()
end
local function text_blue(str)
	return set_text_color(GET_BLUE()) .. str .. GET_RESET()
end
local function text_magenta(str)
	return set_text_color(GET_MAGENTA()) .. str .. GET_RESET()
end
local function text_cyan(str)
	return set_text_color(GET_CYAN()) .. str .. GET_RESET()
end
local function text_white(str)
	return set_text_color(GET_WHITE()) .. str .. GET_RESET()
end

local function background_black(str)
	return set_background_color(GET_BLACK()) .. str .. GET_RESET()
end
local function background_red(str)
	return set_background_color(GET_RED()) .. str .. GET_RESET()
end
local function background_green(str)
	return set_background_color(GET_GREEN()) .. str .. GET_RESET()
end
local function background_yellow(str)
	return set_background_color(GET_YELLOW()) .. str .. GET_RESET()
end
local function background_blue(str)
	return set_background_color(GET_BLUE()) .. str .. GET_RESET()
end
local function background_magenta(str)
	return set_background_color(GET_MAGENTA()) .. str .. GET_RESET()
end
local function background_cyan(str)
	return set_background_color(GET_CYAN()) .. str .. GET_RESET()
end
local function background_white(str)
	return set_background_color(GET_WHITE()) .. str .. GET_RESET()
end

local function text_bright_black(str)
	return set_text_bright_color(GET_BLACK()) .. str .. GET_RESET()
end
local function text_bright_red(str)
	return set_text_bright_color(GET_RED()) .. str .. GET_RESET()
end
local function text_bright_green(str)
	return set_text_bright_color(GET_GREEN()) .. str .. GET_RESET()
end
local function text_bright_yellow(str)
	return set_text_bright_color(GET_YELLOW()) .. str .. GET_RESET()
end
local function text_bright_blue(str)
	return set_text_bright_color(GET_BLUE()) .. str .. GET_RESET()
end
local function text_bright_magenta(str)
	return set_text_bright_color(GET_MAGENTA()) .. str .. GET_RESET()
end
local function text_bright_cyan(str)
	return set_text_bright_color(GET_CYAN()) .. str .. GET_RESET()
end
local function text_bright_white(str)
	return set_text_bright_color(GET_WHITE()) .. str .. GET_RESET()
end

local function background_bright_black(str)
	return set_background_bright_color(GET_BLACK()) .. str .. GET_RESET()
end
local function background_bright_red(str)
	return set_background_bright_color(GET_RED()) .. str .. GET_RESET()
end
local function background_bright_green(str)
	return set_background_bright_color(GET_GREEN()) .. str .. GET_RESET()
end
local function background_bright_yellow(str)
	return set_background_bright_color(GET_YELLOW()) .. str .. GET_RESET()
end
local function background_bright_blue(str)
	return set_background_bright_color(GET_BLUE()) .. str .. GET_RESET()
end
local function background_bright_magenta(str)
	return set_background_bright_color(GET_MAGENTA()) .. str .. GET_RESET()
end
local function background_bright_cyan(str)
	return set_background_bright_color(GET_CYAN()) .. str .. GET_RESET()
end
local function background_bright_white(str)
	return set_background_bright_color(GET_WHITE()) .. str .. GET_RESET()
end

-- ================================
-- VARIABLES
-- ================================

local admin = get_admin()
local user = get_user()
local info = get_win_info()
local icon = get_win_icon()

-- ================================
-- APPEARANCE
-- ================================

local pf = clink.promptfilter(10)
function pf:filter(prompt)
	local prompt_info = extract_prompt(prompt)
	current.venv = prompt_info.venv
	current.cwd = prompt_info.cwd
	current.dir = prompt_info.dir

	local line1 = text_bright_black("") ..
		text_bright_blue(icon .. " ") ..
		text_bright_magenta(info .. " ") ..
		text_bright_blue("󰣆 ") ..
		text_bright_magenta("NT 10.0 ") ..
		text_bright_blue(" ") ..
		text_bright_magenta("cmd") ..
		text_bright_black("\n")

	local time_str = os.date("%H:%M:%S")
	local date_str = os.date("%d/%m/%y")

	local line2 = text_bright_black("┌──") ..
		text_bright_blue(" ") .. text_bright_green(time_str) .. text_bright_black("─") ..
		text_bright_blue(" ") .. text_bright_green(date_str) .. text_bright_black("─") ..
		text_bright_yellow(" ") .. text_bright_cyan(prompt_info.dir) .. text_bright_black("─ ")

	if admin then
		line2 = line2 .. text_bright_black("") .. text_bright_blue(" ") .. text_bright_red("admin") .. text_bright_black("")
	else
		line2 = line2 .. text_bright_black("") .. text_bright_blue(" ") .. text_bright_green(user) .. text_bright_black("")
	end

	local binfo = clink.promptcoroutine(get_git_branch)
	local active_branch = nil
	local active_dirty = false
	if binfo ~= nil and binfo.branch ~= nil then
		active_branch = binfo.branch
		active_dirty = binfo.is_dirty
		current.branch = active_branch
		current.is_dirty = active_dirty
	elseif current.branch ~= nil then
		active_branch = current.branch
		active_dirty = current.is_dirty or false
	end

	if active_branch then
		local dirty_ind = active_dirty and text_bright_yellow("*") or ""
		line2 = line2 .. " " .. text_bright_black("") .. text_bright_red("󰊢 ") .. text_bright_magenta(active_branch) .. dirty_ind .. text_bright_black("")
	end

	if prompt_info.venv ~= nil then
		line2 = line2 .. " " .. text_bright_black("") .. text_bright_blue(" ") .. text_bright_cyan(prompt_info.venv) .. text_bright_black("")
	end

	local line3 = text_bright_black("\n└─") .. text_bright_blue(" ")

	prompt = GET_RESET() .. line1 .. line2 .. line3 .. GET_RESET()
	current.prompt = prompt
	return prompt
end

function pf:transientfilter(prompt)
	return current.prompt
end

-- ================================
-- SSH KEY RESOLUTION
-- ================================

local function resolve_vault_ssh_key(explicit_key, key_name)
	if explicit_key and explicit_key ~= "" and is_file(explicit_key) then
		return explicit_key
	end
	local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
	local candidates = {}
	local function add(p)
		if p and p ~= "" then table.insert(candidates, p) end
	end

	if os.getenv("VAULT_DIR") then
		add(os.getenv("VAULT_DIR") .. [[\keys\]] .. key_name)
	end
	if home ~= "" then
		add(home .. [[\.local\share\vault\keys\]] .. key_name)
		add(home .. [[\.config\vault\keys\]] .. key_name)
		add(home .. [[\.vault\keys\]] .. key_name)
	end
	if MSYS_HOME then
		add(MSYS_HOME .. [[\.local\share\vault\keys\]] .. key_name)
		add(MSYS_HOME .. [[\.config\vault\keys\]] .. key_name)
		add(MSYS_HOME .. [[\.vault\keys\]] .. key_name)
	end

	for _, p in ipairs(candidates) do
		if is_file(p) then
			return p
		end
	end
	return nil
end

-- ================================
-- ALIASES
-- ================================

local aliases = {
	-- --------------------------------
	-- My Shortcuts
	-- --------------------------------
	["upget"] = [[winget upgrade --all]],
	["upscp"] = [[scoop update && scoop update --all]],
	["upcho"] = [[powershell -NoProfile -Command "Start-Process choco -ArgumentList 'upgrade all -y' -Verb RunAs -Wait"]],
	["upwin"] = [[powershell -NoProfile -Command "Get-WindowsUpdate -AcceptAll -Install -AutoReboot"]],

	["goto-msys"] = [[cd /d "]] .. (MSYS_HOME or [[C:\msys64]]) .. [["]],
	["show-msys"] = [[start "" "]] .. (MSYS_HOME or [[C:\msys64]]) .. [["]],

	["personal-server"] = (function()
		local ip = os.getenv("PERSONAL_SERVER_IP") or "144.22.210.65"
		local user = os.getenv("PERSONAL_SERVER_USER") or "ubuntu"
		local key = resolve_vault_ssh_key(os.getenv("PERSONAL_SERVER_KEY"), "ssh-key-personal-server.key")
		if key then
			return [[ssh -i "]] .. key .. [[" "]] .. user .. [[@]] .. ip .. [["]]
		end
		return [[ssh "]] .. user .. [[@]] .. ip .. [["]]
	end)(),
	["venture-server"] = (function()
		local ip = os.getenv("VENTURE_SERVER_IP") or "137.131.238.161"
		local user = os.getenv("VENTURE_SERVER_USER") or "ubuntu"
		local key = resolve_vault_ssh_key(os.getenv("VENTURE_SERVER_KEY"), "ssh-key-venture-server.key")
		if key then
			return [[ssh -i "]] .. key .. [[" "]] .. user .. [[@]] .. ip .. [["]]
		end
		return [[ssh "]] .. user .. [[@]] .. ip .. [["]]
	end)(),

	["ek"] = [[taskkill /IM emacs.exe /F]],
	["es"] = [[runemacs --fg-daemon]],
	["er"] = [[taskkill /IM emacs.exe /F && runemacs --fg-daemon]],
	["ec"] = [[emacsclientw.exe --create-frame --alternate-editor ""]],
	["oe"] = [[emacsclientw.exe --create-frame --alternate-editor "" .]],
	["en"] = [[emacsclient.exe -t --alternate-editor ""]],
	["enw"] = [[emacsclient.exe -t --alternate-editor ""]],
	["oen"] = [[emacsclient.exe -t --alternate-editor "" .]],
	["oenw"] = [[emacsclient.exe -t --alternate-editor "" .]],
	["ov"] = [[vim .]],
	["on"] = [[nvim .]],
	['oc'] = [[code .]],
	['ocm'] = [[codium .]],
	['oa'] = [[antigravity-ide .]],
	['oz'] = [[zed .]],
	['ant'] = [[antigravity-ide]],

	-- --------------------------------
	-- Google Antigravity CLI
	-- --------------------------------
	["agy-continue"] = [[agy -c]],
	["agyc"] = [[agy -c]],
	["agy-auto"] = [[agy --dangerously-skip-permissions]],
	["agy-danger"] = [[agy --dangerously-skip-permissions]],
	["agya"] = [[agy --dangerously-skip-permissions]],
	["agyd"] = [[agy --dangerously-skip-permissions]],
	["agy-continue-auto"] = [[agy -c --dangerously-skip-permissions]],
	["agy-continue-danger"] = [[agy -c --dangerously-skip-permissions]],
	["agyca"] = [[agy -c --dangerously-skip-permissions]],
	["agycd"] = [[agy -c --dangerously-skip-permissions]],

	-- --------------------------------
	-- Console and Terminal
	-- --------------------------------
	["clear"] = [[cls]],

	-- --------------------------------
	-- Files and Directories
	-- --------------------------------
	["ls"] = [[busybox ls -F --color=auto]],
	["ll"] = [[busybox ls -alF --color=auto]],
	["la"] = [[busybox ls -A --color=auto]],
	["pwd"] = [[cd]],
	["cd"] = [[cd /d]],
	["cp"] = [[busybox cp -i]],
	["cpr"] = [[busybox cp -r]],
	["mv"] = [[busybox mv -i]],
	["rm"] = [[busybox rm -i]],
	["rmrf"] = [[busybox rm -rf]],
	["mkdir"] = [[md]],
	["cat"] = [[busybox cat]],
	["less"] = [[busybox less -R]],
	["head"] = [[busybox head]],
	["tail"] = [[busybox tail]],
	["touch"] = [[busybox touch]],
	["which"] = [[where]],
	["open"] = [[start]],

	-- --------------------------------
	-- System and Processes
	-- --------------------------------
	["ps"] = [[tasklist]],
	["kill"] = [[taskkill /F /IM]],
	["top"] = [[taskmgr]],
	["htop"] = [[taskmgr]],
	["uname"] = [[ver]],
	["history"] = [[doskey /history]],
	["man"] = [[help]],
	["reboot"] = [[shutdown /r /t 0]],
	["poweroff"] = [[shutdown /s /t 0]],

	-- --------------------------------
	-- Disk Utils and Info
	-- --------------------------------
	["free"] = [[busybox free -m]],
	["who"] = [[quser]],
	["wc"] = [[busybox wc]],
	["diff"] = [[busybox diff --color=auto]],

	-- --------------------------------
	-- Search and Network
	-- --------------------------------
	["grep"] = [[busybox grep --color=auto]],
	["find"] = [[busybox find]],
	["ifconfig"] = [[ipconfig]],
	["ip"] = [[ipconfig]],
	["ping"] = [[ping -t]],
	["wget"] = [[curl -O]],
	["env"] = [[set]],
	["export"] = [[set]],
}

for alias, _ in pairs(aliases) do
	local parser = clink.arg.new_parser()
	clink.arg.register_parser(alias, parser)
end

local function filter_alias(text)
	local cmd, args = text:match("^%s*(%S+)(.*)")
	if cmd and aliases[cmd] then
		return aliases[cmd] .. args
	end
	return nil
end

if clink.onfilterinput then
	clink.onfilterinput(filter_alias)
end

-- ================================
-- LUA COMMAND
-- ================================

local lua_commands = {
	["lc"] = true,
	["l"] = true,
}

local parser = clink.arg.new_parser()
for cmd, _ in pairs(lua_commands) do
	clink.arg.register_parser(cmd, parser)
end

local function run_lua_logic(code)
	local f = io.open(code, "r")
	if f then
		f:close()
		dofile(code)
		return
	end

	local func, err = load("return " .. code)
	if not func then
		func, err = load(code)
	end

	if func then
		local success, result = pcall(func)
		if success then
			if result ~= nil then
				print(result)
			end
		else
			print("[LuaCMD]: Erro de Execução Lua: " .. tostring(result))
		end
	else
		print("[LuaCMD]: Erro de Sintaxe: " .. tostring(err))
	end
end

local function filter_lua_cmd(text)
	local cmd, args = text:match("^%s*(%S+)%s+(.*)")
	if not cmd then
		cmd = text:match("^%s*(%S+)%s*$")
		args = ""
	end

	if cmd and lua_commands[cmd] then
		if #args > 0 then
			run_lua_logic(args)
		else
			print("[LuaCMD]: Digite um codigo ou arquivo para executar.")
		end
		return ""
	end
	return nil
end

if clink.onfilterinput then
	clink.onfilterinput(filter_lua_cmd)
end

-- ================================
-- EMISSAO E UI SEMANTICA
-- ================================

local function _ui_step(msg) print(text_cyan("==> ") .. msg) end
local function _ui_sub(msg)  print(text_blue("  ↳ ") .. msg) end
local function _ui_ok(msg)   print(text_green("  ✅ ") .. msg) end
local function _ui_warn(msg) print(text_yellow("  ⚠️  ") .. msg) end
local function _ui_err(msg)  io.stderr:write(text_red("  ❌ ") .. msg .. "\n") end
local function _ui_info(msg) print(text_magenta("  ℹ️  ") .. msg) end
local function _ui_banner(title)
	local sep = string.rep("=", 64)
	print("\n" .. text_cyan(sep) .. "\n  " .. title .. "\n" .. text_cyan(sep) .. "\n")
end

-- ================================
-- UPDATE COMMANDS (ECOSYSTEM)
-- ================================

local function cmd_upgit(args)
	local flags = args and trim(args) or ""
	if flags:find("%-%-help") or flags:find("%-h") then
		print("Uso: upgit [diretório] [opções] (alias: plgit, pull-git)")
		print("")
		print("Localiza e atualiza repositórios Git recursivamente com proteção resiliente.")
		print("")
		print("Opções:")
		print("  -s, --status    Audita status de branches, commits divergentes e alterações")
		print("  -n, --dry-run   Simula a sincronização sem efetuar git pull")
		print("  -h, --help      Exibe esta ajuda")
		return
	end
	local is_status = flags:find("%-%-status") or flags:find("%-s")
	local is_dry = flags:find("%-%-dry%-run") or flags:find("%-n")
	local root = "."
	for word in flags:gmatch("%S+") do
		if not word:match("^%-") then
			root = word
			break
		end
	end

	local action_title = is_status and "Auditando status de" or (is_dry and "Simulando atualização de" or "Buscando e atualizando")
	_ui_step(action_title .. " repositórios Git em: " .. root)
	print("")

	local pipe = io.popen([[for /r "]] .. root .. [[" %d in (.) do @if exist "%d\.git" echo %~fd]])
	if not pipe then
		_ui_err("Falha ao iniciar varredura Git.")
		return
	end

	local repos = {}
	for line in pipe:lines() do
		local repo = trim(line)
		if repo ~= "" and is_git_repo(repo) then
			table.insert(repos, repo)
		end
	end
	pipe:close()

	local function depth(p)
		local _, c = p:gsub([[\]], "")
		return c
	end

	table.sort(repos, function(a, b)
		return depth(a) < depth(b)
	end)

	if #repos == 0 then
		_ui_info("Nenhum repositório Git encontrado em " .. root .. " (profundidade máxima de busca).")
		return
	end

	for _, repo in ipairs(repos) do
		local branch_pipe = io.popen([[git -C "]] .. repo .. [[" branch --show-current 2>nul]])
		local branch = branch_pipe and branch_pipe:read("*l") or ""
		if branch_pipe then branch_pipe:close() end
		local branch_lbl = (branch and branch ~= "") and branch or "detached"

		if is_status then
			local st_pipe = io.popen([[git -C "]] .. repo .. [[" status -s 2>nul]])
			local st = st_pipe and st_pipe:read("*a") or ""
			if st_pipe then st_pipe:close() end

			local ch_pipe = io.popen([[git -C "]] .. repo .. [[" cherry -v 2>nul]])
			local unpushed = ch_pipe and ch_pipe:read("*a") or ""
			if ch_pipe then ch_pipe:close() end

			if (st and trim(st) ~= "") or (unpushed and trim(unpushed) ~= "") then
				_ui_warn(repo .. " [" .. branch_lbl .. "]: divergências detectadas")
				if unpushed and trim(unpushed) ~= "" then
					print("  \x1b[1;33m↳ Commits pendentes de push\x1b[0m")
				end
				if st and trim(st) ~= "" then
					print("  \x1b[90m" .. trim(st) .. "\x1b[0m")
				end
			else
				_ui_ok(repo .. " [" .. branch_lbl .. "]: sincronizado e limpo")
			end
		elseif is_dry then
			_ui_sub("[DRY-RUN PULL] " .. repo .. " [" .. branch_lbl .. "]")
		else
			_ui_sub("Atualizando " .. repo .. "...")
			local ok = os.execute([[git -C "]] .. repo .. [[" pull --ff-only 2>nul]])
			if not ok or ok ~= 0 then
				os.execute([[git -C "]] .. repo .. [[" pull]])
			end
		end
	end
	print("")
	_ui_ok("Operação Git concluída!")
end

local function cmd_psgit(args)
	local flags = args and trim(args) or ""
	if flags:find("%-%-help") or flags:find("%-h") then
		print("Uso: psgit [diretório] [opções] (alias: push-git)")
		print("")
		print("Localiza repositórios Git recursivamente e envia commits pendentes upstream.")
		print("")
		print("Opções:")
		print("  -s, --status    Audita commits locais pendentes de envio (cherry -v)")
		print("  -n, --dry-run   Simula o push sem enviar commits")
		print("  -h, --help      Exibe esta ajuda")
		return
	end
	local is_status = flags:find("%-%-status") or flags:find("%-s")
	local is_dry = flags:find("%-%-dry%-run") or flags:find("%-n")
	local root = "."
	for word in flags:gmatch("%S+") do
		if not word:match("^%-") then
			root = word
			break
		end
	end

	local action_title = is_status and "Auditando commits pendentes em" or (is_dry and "Simulando push de" or "Buscando e enviando")
	_ui_step(action_title .. " repositórios Git em: " .. root)
	print("")

	local pipe = io.popen([[for /r "]] .. root .. [[" %d in (.) do @if exist "%d\.git" echo %~fd]])
	if not pipe then
		_ui_err("Falha ao iniciar varredura Git.")
		return
	end

	local repos = {}
	for line in pipe:lines() do
		local repo = trim(line)
		if repo ~= "" and is_git_repo(repo) then
			table.insert(repos, repo)
		end
	end
	pipe:close()

	local function depth(p)
		local _, c = p:gsub([[\]], "")
		return c
	end

	table.sort(repos, function(a, b)
		return depth(a) > depth(b)
	end)

	if #repos == 0 then
		_ui_info("Nenhum repositório Git encontrado em " .. root .. ".")
		return
	end

	for _, repo in ipairs(repos) do
		local check = io.popen([[git -C "]] .. repo .. [[" cherry -v 2>nul]])
		local unpushed = check and check:read("*a") or ""
		if check then check:close() end

		local branch_pipe = io.popen([[git -C "]] .. repo .. [[" branch --show-current 2>nul]])
		local branch = branch_pipe and branch_pipe:read("*l") or ""
		if branch_pipe then branch_pipe:close() end
		local branch_lbl = (branch and branch ~= "") and branch or "detached"

		if trim(unpushed) ~= "" then
			if is_status then
				_ui_warn(repo .. " [" .. branch_lbl .. "]: commits pendentes de envio")
				print("  \x1b[1;33m" .. trim(unpushed) .. "\x1b[0m")
			elseif is_dry then
				_ui_sub("[DRY-RUN PUSH] " .. repo .. " [" .. branch_lbl .. "]")
			else
				_ui_sub("Enviando " .. repo .. " [" .. branch_lbl .. "]...")
				local ok = os.execute([[git -C "]] .. repo .. [[" push]])
				if ok == 0 or ok == true then
					_ui_ok(repo .. ": push concluído com sucesso!")
				else
					_ui_err(repo .. ": falha no push.")
				end
			end
		else
			if is_status then
				_ui_ok(repo .. " [" .. branch_lbl .. "]: nada a enviar")
			else
				_ui_ok(repo .. ": já atualizado com o remote.")
			end
		end
	end
	print("")
	_ui_ok("Operação Push Git concluída!")
end

local function cmd_sync_extensions(args)
	local flags = args and trim(args) or ""
	if flags:find("%-%-help") or flags:find("%-h") then
		print("Uso: sync-extensions [opções] (alias: upext, update-extensions)")
		print("")
		print("Sincroniza extensões declarativas de IDE (VS Code, VSCodium, Antigravity).")
		print("")
		print("Opções:")
		print("  -s, --status    Audita extensões declaradas no manifesto")
		print("  -n, --dry-run   Simula a sincronização sem modificar o ambiente")
		print("  -h, --help      Exibe esta ajuda")
		return
	end
	_ui_step("Sincronizando extensões de IDE declarativas...")
	local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
	local candidates = {}
	local function add(p)
		if p and p ~= "" then table.insert(candidates, p) end
	end

	add(os.getenv("PROFILE_DIR"))
	add(home .. [[\.local\share\profile]])
	add(home .. [[\.config\profile]])
	add(home .. [[\.profile]])
	add(home .. [[\OneDrive\Documentos\Profile]])
	add(home .. [[\Documents\Profile]])

	if MSYS_HOME then
		add(MSYS_HOME .. [[\.local\share\profile]])
		add(MSYS_HOME .. [[\.config\profile]])
		add(MSYS_HOME .. [[\.profile]])
	end

	local target = nil
	for _, p in ipairs(candidates) do
		if is_file(p .. [[\profile.sh]]) then
			target = p
			break
		end
	end

	if target then
		local bash = get_bash_cmd()
		local flags = args and trim(args) or ""
		if bash then
			local unix_target = to_unix_path(target)
			os.execute(bash .. [[ -c "MSYS=winsymlinks:nativestrict ']] .. unix_target .. [[/profile.sh' extensions ]] .. flags .. [["]])
		else
			_ui_warn("Ambiente MSYS2/Bash não detectado no PATH.")
		end
	else
		_ui_info("Repositório do Profile não encontrado.")
	end
end

local function cmd_uped(args)
	local flags = args and trim(args) or ""
	if flags:find("%-%-help") or flags:find("%-h") then
		print("Uso: uped [opções] (alias: update-editors)")
		print("")
		print("Atualiza os repositórios da Suíte de Editores (Emacs, Helix, NeoVim, Vim).")
		print("")
		print("Opções:")
		print("  -s, --status        Audita o status Git de cada editor instalado")
		print("  -n, --dry-run       Simula a sincronização sem puxar alterações")
		print("  -e, --extensions    Sincroniza também as extensões declarativas de IDE")
		print("  -h, --help          Exibe esta ajuda")
		return
	end
	local is_status = flags:find("%-%-status") or flags:find("%-s")
	local is_dry = flags:find("%-%-dry%-run") or flags:find("%-n")
	local is_ext = flags:find("%-%-extensions") or flags:find("%-e")
	local action_title = is_status and "Auditando status da" or (is_dry and "Simulando atualização da" or "Atualizando a")
	_ui_step(action_title .. " Suíte de Editores no Windows...")
	local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
	local appdata = os.getenv("APPDATA") or ""
	local localappdata = os.getenv("LOCALAPPDATA") or ""
	local found = false

	local function update_editor(name, dir, has_submodules)
		if is_git_repo(dir) then
			found = true
			if is_status then
				_ui_sub("Status de " .. name .. " em " .. dir .. "...")
				os.execute([[git -C "]] .. dir .. [[" status -s -b]])
			elseif is_dry then
				_ui_sub("[DRY-RUN] Atualização de " .. name .. " em " .. dir .. "...")
				_ui_sub([[git -C "]] .. dir .. [[" pull --ff-only]])
			else
				_ui_sub("Atualizando " .. name .. " em " .. dir .. "...")
				if name == "Emacs" and is_dir(dir .. [[\usr\local]]) then
					os.execute([[git -C "]] .. dir .. [[" clean -fd usr/local >nul 2>&1]])
				end
				os.execute([[git -C "]] .. dir .. [[" pull --ff-only]])
				if has_submodules and exists(dir .. [[\.gitmodules]]) then
					_ui_sub("Sincronizando submódulos Elisp...")
					os.execute([[git -C "]] .. dir .. [[" submodule update --init --recursive --remote --merge]])
				end
				_ui_ok(name .. " atualizado com sucesso!")
			end
		end
	end

	local emacs_dir = home .. [[\.emacs.d]]
	if not is_dir(emacs_dir) and appdata ~= "" then emacs_dir = appdata .. [[\.emacs.d]] end
	if not is_dir(emacs_dir) and MSYS_HOME then emacs_dir = MSYS_HOME .. [[\.emacs.d]] end
	update_editor("Emacs", emacs_dir, true)

	local helix_dir = appdata ~= "" and (appdata .. [[\helix]]) or (home .. [[\.config\helix]])
	if not is_dir(helix_dir) and is_dir(home .. [[\.config\helix]]) then helix_dir = home .. [[\.config\helix]] end
	if not is_dir(helix_dir) and MSYS_HOME and is_dir(MSYS_HOME .. [[\.config\helix]]) then helix_dir = MSYS_HOME .. [[\.config\helix]] end
	update_editor("Helix", helix_dir, false)

	local nvim_dir = localappdata ~= "" and (localappdata .. [[\nvim]]) or (home .. [[\.config\nvim]])
	if not is_dir(nvim_dir) and is_dir(home .. [[\.config\nvim]]) then nvim_dir = home .. [[\.config\nvim]] end
	if not is_dir(nvim_dir) and MSYS_HOME and is_dir(MSYS_HOME .. [[\.config\nvim]]) then nvim_dir = MSYS_HOME .. [[\.config\nvim]] end
	update_editor("NeoVim", nvim_dir, false)

	local vim_dir = home .. [[\vimfiles]]
	if not is_dir(vim_dir) and is_dir(home .. [[\.vim]]) then vim_dir = home .. [[\.vim]] end
	if not is_dir(vim_dir) and MSYS_HOME and is_dir(MSYS_HOME .. [[\.vim]]) then vim_dir = MSYS_HOME .. [[\.vim]] end
	update_editor("Vim", vim_dir, false)

	if not found then
		_ui_info("Nenhum repositório de editor encontrado nos caminhos canônicos (~/.emacs.d, helix, nvim, vimfiles).")
	else
		_ui_ok("Suíte de Editores sincronizada com sucesso!")
	end

	if is_ext then
		cmd_sync_extensions(args)
	end
end

local function cmd_uprc(args)
	local flags = args and trim(args) or ""
	if flags:find("%-%-help") or flags:find("%-h") then
		print("Uso: uprc [opções] (alias: upprofile, update-profile, sync-profile)")
		print("")
		print("Atualiza o repositório Universal Profile e sincroniza dotfiles via profile.sh.")
		print("")
		print("Opções:")
		print("  -s, --status        Audita o status do Profile e compara divergências")
		print("  -n, --dry-run       Simula a sincronização sem alterar arquivos")
		print("  -b, --backup        Cria backup (.bak) antes de substituir arquivos")
		print("  -e, --extensions    Sincroniza extensões declarativas de IDE")
		print("  --pull              Reconcilia alterações do sistema de volta ao Git")
		print("  -h, --help          Exibe esta ajuda")
		return
	end
	local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
	local candidates = {}
	local function add(p)
		if p and p ~= "" then table.insert(candidates, p) end
	end

	add(os.getenv("PROFILE_DIR"))
	add(home .. [[\.local\share\profile]])
	add(home .. [[\.config\profile]])
	add(home .. [[\.profile]])
	add(home .. [[\OneDrive\Documentos\Profile]])
	add(home .. [[\Documents\Profile]])

	if MSYS_HOME then
		add(MSYS_HOME .. [[\.local\share\profile]])
		add(MSYS_HOME .. [[\.config\profile]])
		add(MSYS_HOME .. [[\.profile]])
	end

	local target = nil
	for _, p in ipairs(candidates) do
		if is_git_repo(p) then
			target = p
			break
		end
	end

	if target then
		local flags = args and trim(args) or ""
		local is_query = flags:find("%-%-status") or flags:find("%-s")
		local is_pull = flags:find("%-%-pull")
		local is_dry = flags:find("%-%-dry%-run") or flags:find("%-n")
		if not is_query and not is_pull and not is_dry then
			_ui_step("Atualizando Universal Profile em: " .. target .. "...")
			local handle = io.popen([[git -C "]] .. target .. [[" status --porcelain 2>nul]])
			local status = handle and handle:read("*a") or ""
			if handle then handle:close() end
			if status and status:match("%S") then
				_ui_warn("Alterações locais não commitadas detectadas em: " .. target .. ". Ignorando git pull para preservar dados.")
			else
				os.execute([[git -C "]] .. target .. [[" pull --ff-only]])
			end
		end
		local script = target .. [[\profile.sh]]
		if exists(script) then
			_ui_sub("Sincronizando dotfiles e links via profile.sh (MSYS2)...")
			local bash = get_bash_cmd()
			if bash then
				local unix_target = to_unix_path(target)
				os.execute(bash .. [[ -c "MSYS=winsymlinks:nativestrict ']] .. unix_target .. [[/profile.sh' sync ]] .. flags .. [["]])
			else
				_ui_warn("Ambiente MSYS2/Bash não detectado no PATH (excluído WSL em System32).")
			end
		end
		_ui_ok("Universal Profile atualizado e sincronizado com sucesso!")
	else
		_ui_info("Repositório do Profile não encontrado.")
	end
end

local function cmd_upvt(args)
	local flags = args and trim(args) or ""
	if flags:find("%-%-help") or flags:find("%-h") then
		print("Uso: upvt [opções] (alias: update-vault)")
		print("")
		print("Atualiza o repositório Universal Vault e aplica permissões de segurança.")
		print("")
		print("Opções:")
		print("  -s, --status    Audita o status do repositório do cofre")
		print("  -n, --dry-run   Simula o pull sem aplicar alterações")
		print("  -h, --help      Exibe esta ajuda")
		return
	end
	local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
	local candidates = {}
	local function add(p)
		if p and p ~= "" then table.insert(candidates, p) end
	end

	add(os.getenv("VAULT_DIR"))
	add(home .. [[\.local\share\vault]])
	add(home .. [[\.config\vault]])
	add(home .. [[\.vault]])

	if MSYS_HOME then
		add(MSYS_HOME .. [[\.local\share\vault]])
		add(MSYS_HOME .. [[\.config\vault]])
		add(MSYS_HOME .. [[\.vault]])
	end

	local target = nil
	for _, p in ipairs(candidates) do
		if is_git_repo(p) then
			target = p
			break
		end
	end

	if target then
		local flags = args and trim(args) or ""
		local is_status = flags:find("%-%-status") or flags:find("%-s")
		local is_dry = flags:find("%-%-dry%-run") or flags:find("%-n")
		if is_status then
			_ui_step("Status do Universal Vault em: " .. target .. "...")
			os.execute([[git -C "]] .. target .. [[" status -s -b]])
			return
		end
		if is_dry then
			_ui_step("[DRY-RUN] Atualização do Universal Vault em: " .. target .. "...")
			_ui_sub([[git -C "]] .. target .. [[" pull --ff-only]])
			return
		end
		_ui_step("Atualizando Universal Vault em: " .. target .. "...")
		os.execute([[git -C "]] .. target .. [[" pull --ff-only]])
		local v_lua = target .. [[\vault.lua]]
		if is_file(v_lua) then
			_ui_sub("Recarregando segredos e ambiente do Vault...")
			pcall(dofile, v_lua)
		end
		_ui_ok("Universal Vault atualizado com sucesso!")
	else
		_ui_info("Repositório do Vault não encontrado.")
	end
end

local function cmd_vault_perms(args)
	local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
	local candidates = {}
	local function add(p)
		if p and p ~= "" then table.insert(candidates, p) end
	end

	add(os.getenv("VAULT_DIR"))
	add(home .. [[\.local\share\vault]])
	add(home .. [[\.config\vault]])
	add(home .. [[\.vault]])

	if MSYS_HOME then
		add(MSYS_HOME .. [[\.local\share\vault]])
		add(MSYS_HOME .. [[\.config\vault]])
		add(MSYS_HOME .. [[\.vault]])
	end

	local target = nil
	for _, p in ipairs(candidates) do
		if is_dir(p) then
			target = p
			break
		end
	end

	if target then
		local user = os.getenv("USERNAME") or "user"
		_ui_step("Ajustando permissões de segurança em " .. target .. "...")
		os.execute([[icacls "]] .. target .. [[" /inheritance:r /grant:r "]] .. user .. [[":(OI)(CI)F /c /q >nul 2>&1]])
		os.execute([[icacls "]] .. target .. [[\*" /reset /t /c /q >nul 2>&1]])
		os.execute([[git -C "]] .. target .. [[" config core.hooksPath .githooks >nul 2>&1]])
		_ui_ok("Permissões ajustadas com sucesso [acesso restrito a '" .. user .. "'].")
	else
		_ui_info("Repositório do Vault não encontrado.")
	end
end

local function cmd_upsh(args)
	local flags = args and trim(args) or ""
	if flags:find("%-%-help") or flags:find("%-h") then
		print("Uso: upsh [opções] (alias: update-shell)")
		print("")
		print("Atualiza o repositório Universal Shell via git pull.")
		print("")
		print("Opções:")
		print("  -s, --status    Audita o status do repositório Git local sem puxar")
		print("  -n, --dry-run   Simula a sincronização sem efetuar pull")
		print("  -h, --help      Exibe esta ajuda")
		return
	end
	local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
	local candidates = {}
	local function add(p)
		if p and p ~= "" then table.insert(candidates, p) end
	end

	add(os.getenv("SHELL_REPO_DIR"))
	add(home .. [[\.local\share\shell]])
	add(home .. [[\.config\shell]])
	add(home .. [[\.shell]])
	add([[C:\Program Files\Shell]])

	if MSYS_HOME then
		add(MSYS_HOME .. [[\.local\share\shell]])
		add(MSYS_HOME .. [[\.config\shell]])
		add(MSYS_HOME .. [[\.shell]])
	end

	local target = nil
	for _, p in ipairs(candidates) do
		if is_git_repo(p) then
			target = p
			break
		end
	end

	if target then
		local flags = args and trim(args) or ""
		local is_status = flags:find("%-%-status") or flags:find("%-s")
		local is_dry = flags:find("%-%-dry%-run") or flags:find("%-n")
		if is_status then
			_ui_step("Status do Universal Shell em: " .. target .. "...")
			os.execute([[git -C "]] .. target .. [[" status -s -b]])
			return
		end
		if is_dry then
			_ui_step("[DRY-RUN] Atualização do Universal Shell em: " .. target .. "...")
			_ui_sub([[git -C "]] .. target .. [[" pull --ff-only]])
			return
		end
		_ui_step("Atualizando Universal Shell em: " .. target .. "...")
		os.execute([[git -C "]] .. target .. [[" pull --ff-only]])
		_ui_ok("Universal Shell atualizado com sucesso!")
	else
		_ui_info("Repositório do Shell não encontrado.")
	end
end

local function cmd_upsys(args)
	local flags = args and trim(args) or ""
	if flags:find("%-%-help") or flags:find("%-h") then
		print("Uso: upsys [opções] (alias: update-system)")
		print("")
		print("Atualiza pacotes dos gerenciadores nativos (Winget, Scoop, Chocolatey).")
		return
	end
	_ui_step("Atualizando gerenciadores de pacotes do sistema...")
	local found = false
	if has_cmd("winget") then
		found = true
		_ui_sub("Atualizando pacotes via Winget...")
		os.execute([[winget upgrade --all]])
	end
	if has_cmd("scoop") then
		found = true
		_ui_sub("Atualizando pacotes via Scoop...")
		os.execute([[scoop update && scoop update --all]])
	end
	if has_cmd("choco") then
		found = true
		_ui_sub("Atualizando pacotes via Chocolatey...")
		local pw = has_cmd("pwsh") and "pwsh" or "powershell"
		os.execute(pw .. [[ -NoProfile -Command "Start-Process choco -ArgumentList 'upgrade all -y' -Verb RunAs -Wait"]])
	end
	if not found then
		_ui_warn("Nenhum gerenciador de pacotes suportado (winget, scoop, choco) encontrado no sistema.")
		return
	end
	_ui_ok("Pacotes do sistema atualizados com sucesso!")
end

local function cmd_clean_system(args)
	local flags = args and trim(args) or ""
	if flags:find("%-%-help") or flags:find("%-h") then
		print("Uso: clean-system [opções] (alias: cleansys, sysclean, syscls, clear-system, clearsys)")
		print("")
		print("Limpeza de pacotes órfãos e caches no Windows.")
		return
	end
	_ui_step("Executando limpeza de pacotes e caches do sistema...")
	os.execute([[scoop cache rm * >nul 2>nul]])
	os.execute([[scoop cleanup * >nul 2>nul]])
	os.execute([[powershell -NoProfile -Command "if (Get-Command choco -ErrorAction SilentlyContinue) { Start-Process choco -ArgumentList 'cache remove' -Verb RunAs -Wait }" >nul 2>nul]])
	_ui_ok("Limpeza do sistema concluída!")
end

local function cmd_upall(args)
	local flags = args and trim(args) or ""
	if flags:find("%-%-help") or flags:find("%-h") then
		print("Uso: upall [opções] (alias: update-all)")
		print("")
		print("Atualização geral e coordenada do ecossistema e gerenciadores de pacotes do sistema.")
		print("")
		print("Opções:")
		print("  -s, --status    Executa auditoria e diagnóstico geral sem atualizar")
		print("  -n, --dry-run   Simula a atualização de todos os componentes")
		print("  -h, --help      Exibe esta ajuda")
		return
	end
	local is_status = flags:find("%-%-status") or flags:find("%-s")
	local is_dry = flags:find("%-%-dry%-run") or flags:find("%-n")

	if is_status then
		_ui_banner("Status Global do Ecossistema")
		cmd_uprc(args)
		cmd_upvt(args)
		cmd_upsh(args)
		cmd_uped(args)
		_ui_banner("Verificação de Status Concluída")
		return
	end
	if is_dry then
		_ui_banner("Simulação Global do Ecossistema (Dry-Run)")
		cmd_uprc(args)
		cmd_upvt(args)
		cmd_upsh(args)
		cmd_uped(args)
		_ui_banner("Simulação Concluída")
		return
	end
	_ui_banner("Atualização Global do Ecossistema e Sistema")
	cmd_upsys()
	cmd_uprc()
	cmd_upvt()
	cmd_upsh()
	cmd_uped()
	cmd_clean_system()
	_ui_banner("Atualização Global Concluída com Sucesso")
end

local updater_commands = {
	["upgit"] = cmd_upgit,
	["plgit"] = cmd_upgit,
	["update-git"] = cmd_upgit,
	["psgit"] = cmd_psgit,
	["push-git"] = cmd_psgit,
	["sync-extensions"] = cmd_sync_extensions,
	["update-extensions"] = cmd_sync_extensions,
	["upext"] = cmd_sync_extensions,
	["uped"] = cmd_uped,
	["update-editors"] = cmd_uped,
	["uprc"] = cmd_uprc,
	["upprofile"] = cmd_uprc,
	["update-profile"] = cmd_uprc,
	["sync-profile"] = cmd_uprc,
	["upvt"] = cmd_upvt,
	["update-vault"] = cmd_upvt,
	["vault-perms"] = cmd_vault_perms,
	["upsh"] = cmd_upsh,
	["update-shell"] = cmd_upsh,
	["upsys"] = cmd_upsys,
	["update-system"] = cmd_upsys,
	["upall"] = cmd_upall,
	["update-all"] = cmd_upall,
	["clean-system"] = cmd_clean_system,
	["clear-system"] = cmd_clean_system,
	["cleansys"] = cmd_clean_system,
	["clearsys"] = cmd_clean_system,
	["sysclean"] = cmd_clean_system,
	["syscls"] = cmd_clean_system,
}

local updater_parser = clink.arg.new_parser()
for cmd, _ in pairs(updater_commands) do
	clink.arg.register_parser(cmd, updater_parser)
end

local function filter_updater_cmd(text)
	local cmd, args = text:match("^%s*(%S+)%s*(.*)")
	if cmd and updater_commands[cmd] then
		updater_commands[cmd](args)
		return ""
	end
	return nil
end

if clink.onfilterinput then
	clink.onfilterinput(filter_updater_cmd)
end

if settings and settings.set then
	settings.set("autosuggest.enable", true)
	settings.set("autosuggest.strategy", "history,completion")
	settings.set("match.preview", true)
end
