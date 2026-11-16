-- ----------------------------------------------------------------
-- Module: Windows CMD Clink Prompt & Profile
-- ----------------------------------------------------------------

-- ================================
-- STARTUP
-- ================================

local function get_clink_dir()
	local info = debug and debug.getinfo and debug.getinfo(1, "S")
	if info and info.source and info.source:sub(1, 1) == "@" then
		local script_path = info.source:sub(2)
		local script_dir = script_path:match("^(.*)[\\/][^\\/]+$")
		if script_dir and script_dir ~= "" and (os.isdir and os.isdir(script_dir) or false) then
			return script_dir
		end
	end
	local env_clink_path = os.getenv("CLINK_PATH")
	if env_clink_path and env_clink_path ~= "" then
		return env_clink_path
	end
	local repo_dir = os.getenv("SHELL_REPO_DIR")
	if repo_dir and repo_dir ~= "" then
		return repo_dir .. [[\target\windows\cmd]]
	end
	local local_appdata = os.getenv("LOCALAPPDATA") or ""
	if local_appdata ~= "" then
		return local_appdata .. [[\clink]]
	end
	return os.getenv("CLINK_DIR") or ""
end

local function get_system32_dir()
	return (os.getenv("SystemRoot") or os.getenv("WINDIR") or [[C:\Windows]]) .. [[\System32]]
end

local function get_system32_path(file_name)
	return get_system32_dir() .. [[\]] .. file_name
end

local CLINK_PROFILE_DIR = get_clink_dir()

if clink and clink.setenv then
	local cache_home = os.getenv("XDG_CACHE_HOME")
	if cache_home and cache_home ~= "" then
		clink.setenv("PYTHONPYCACHEPREFIX", cache_home .. [[\pycache]])
	else
		local user_profile = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
		clink.setenv("PYTHONPYCACHEPREFIX", user_profile .. [[\.cache\pycache]])
	end
end

-- ================================
-- SYSTEM
-- ================================

local function is_dir(target_path)
	if not target_path or target_path == "" then return false end
	if path and path.is_dir then return path.is_dir(target_path) end
	if os.isdir then return os.isdir(target_path) end
	local ok, _, code = os.rename(target_path, target_path)
	if ok or code == 13 or code == 17 then return true end
	return false
end

local function is_file(target_path)
	if not target_path or target_path == "" then return false end
	if path and path.is_file then return path.is_file(target_path) end
	if os.isfile then return os.isfile(target_path) end
	local handle = io.open(target_path, "r")
	if handle then
		handle:close()
		return true
	end
	return false
end

local function exists(target_path)
	if not target_path or target_path == "" then return false end
	return is_dir(target_path) or is_file(target_path)
end

local function is_git_repo(dir_path)
	if not dir_path or dir_path == "" then return false end
	if is_dir(dir_path .. [[\.git]]) then return true end
	local handle = io.open(dir_path .. [[\.git\HEAD]], "r")
		or io.open(dir_path .. [[\.git\config]], "r")
		or io.open(dir_path .. [[\.git]], "r")
	if handle then
		handle:close()
		return true
	end
	return false
end

local cmd_cache = {
	path_env = nil,
	pathext_env = nil,
	by_name = {},
	all_paths = {},
}

local function rebuild_cmd_index()
	local path_env = os.getenv("PATH") or ""
	local pathext_env = os.getenv("PATHEXT") or ".COM;.EXE;.BAT;.CMD"
	if cmd_cache.path_env == path_env and cmd_cache.pathext_env == pathext_env then
		return
	end

	cmd_cache.path_env = path_env
	cmd_cache.pathext_env = pathext_env
	cmd_cache.by_name = {}
	cmd_cache.all_paths = {}

	local ext_rank = {}
	local ext_list = {}
	local rank_index = 0
	for ext in pathext_env:gmatch("[^;]+") do
		local clean_ext = ext:match("^%s*(.-)%s*$"):lower()
		if clean_ext ~= "" then
			if clean_ext:sub(1, 1) ~= "." then
				clean_ext = "." .. clean_ext
			end
			if not ext_rank[clean_ext] then
				rank_index = rank_index + 1
				ext_rank[clean_ext] = rank_index
				table.insert(ext_list, clean_ext)
			end
		end
	end

	local seen_dirs = {}
	for raw_dir in path_env:gmatch("[^;]+") do
		local dir_path = raw_dir:match("^%s*(.-)%s*$"):gsub('^"(.*)"$', "%1"):gsub("[\\/]+$", "")
		local dir_key = dir_path:lower()
		if dir_path ~= "" and not seen_dirs[dir_key] and is_dir(dir_path) then
			seen_dirs[dir_key] = true
			local entries = os.globfiles and os.globfiles(dir_path .. [[\*]]) or nil
			if entries then
				local dir_best = {}
				for _, filename in ipairs(entries) do
					local lower_name = filename:lower()
					local dot_pos = lower_name:match("^.+()%.[^%.]+$")
					if dot_pos then
						local ext = lower_name:sub(dot_pos)
						local current_rank = ext_rank[ext]
						if current_rank then
							local base_name = lower_name:sub(1, dot_pos - 1)
							local full_path = dir_path .. [[\]] .. filename
							local previous = dir_best[base_name]
							if not previous or current_rank < previous.rank then
								dir_best[base_name] = { rank = current_rank, path = full_path }
							end
							if not cmd_cache.by_name[lower_name] then
								cmd_cache.by_name[lower_name] = full_path
							end
							if not cmd_cache.all_paths[lower_name] then
								cmd_cache.all_paths[lower_name] = {}
							end
							table.insert(cmd_cache.all_paths[lower_name], full_path)
						end
					end
				end
				for base_name, best in pairs(dir_best) do
					if not cmd_cache.by_name[base_name] then
						cmd_cache.by_name[base_name] = best.path
					end
					if not cmd_cache.all_paths[base_name] then
						cmd_cache.all_paths[base_name] = {}
					end
					table.insert(cmd_cache.all_paths[base_name], best.path)
				end
			else
				cmd_cache.fallback_exts = ext_list
			end
		end
	end
end

local function has_cmd(cmd_name)
	if not cmd_name or cmd_name == "" then return false end
	if cmd_name:find("[\\/]") then
		return is_file(cmd_name)
	end
	rebuild_cmd_index()
	local lower_cmd = cmd_name:lower()
	if cmd_cache.by_name[lower_cmd] ~= nil then
		return true
	end
	if not os.globfiles and cmd_cache.fallback_exts then
		for raw_dir in (cmd_cache.path_env or ""):gmatch("[^;]+") do
			local dir_path = raw_dir:match("^%s*(.-)%s*$"):gsub('^"(.*)"$', "%1"):gsub("[\\/]+$", "")
			if dir_path ~= "" then
				if is_file(dir_path .. [[\]] .. cmd_name) then
					cmd_cache.by_name[lower_cmd] = dir_path .. [[\]] .. cmd_name
					return true
				end
				for _, ext in ipairs(cmd_cache.fallback_exts) do
					local candidate = dir_path .. [[\]] .. cmd_name .. ext
					if is_file(candidate) then
						cmd_cache.by_name[lower_cmd] = candidate
						return true
					end
				end
			end
		end
	end
	return false
end

-- ================================
-- ENVIRONMENT
-- ================================

local current = {
	prompt = nil,
	branch = nil,
	is_dirty = false,
	venv = nil,
	cwd = nil,
	dir = nil,
}

-- ================================
-- MSYS2 ENVIRONMENT
-- ================================

local function trim(input_str)
	return (string.gsub(input_str, "^%s*(.-)%s*$", "%1"))
end

local function get_home_dir()
	return os.getenv("USERPROFILE") or os.getenv("HOME") or ""
end

local function get_msys2_home()
	local explicit = os.getenv("MSYS2_HOME")
	if explicit and is_dir(explicit) then return explicit end

	local root_dir = os.getenv("MSYS2_ROOT") or [[C:\msys64]]
	local home_base = root_dir .. [[\home]]
	if not is_dir(home_base) then return nil end

	local user_name = os.getenv("MSYS2_USER") or os.getenv("USERNAME") or ""
	if user_name ~= "" then
		if is_dir(home_base .. [[\]] .. user_name) then
			return home_base .. [[\]] .. user_name
		end
		if is_dir(home_base .. [[\]] .. string.lower(user_name)) then
			return home_base .. [[\]] .. string.lower(user_name)
		end
	end

	if os.globdirs then
		local folders = os.globdirs(home_base .. [[\*]])
		if folders then
			for _, raw_folder in ipairs(folders) do
				local folder = trim(raw_folder):gsub("[\\/]+$", "")
				if folder ~= "" and folder ~= "." and folder ~= ".." and is_dir(home_base .. [[\]] .. folder) then
					return home_base .. [[\]] .. folder
				end
			end
		end
	end

	return nil
end

MSYS_HOME = get_msys2_home()

local function to_unix_path(win_path)
	local unix_path = win_path:gsub("\\", "/")
	local drive, rest = unix_path:match("^([A-Za-z]):(.*)")
	if drive then
		return "/" .. drive:lower() .. rest
	end
	return unix_path
end

local function resolve_candidate(candidates, validator)
	for _, candidate in ipairs(candidates) do
		if candidate and candidate ~= "" and validator(candidate) then
			return candidate
		end
	end
	return nil
end

local function collect_home_candidates(env_name, relative_paths, extra_paths)
	local home_dir = get_home_dir()
	local candidates = {}
	local function add(candidate)
		if candidate and candidate ~= "" then
			table.insert(candidates, candidate)
		end
	end

	if env_name then
		add(os.getenv(env_name))
	end
	for _, rel in ipairs(relative_paths) do
		if home_dir ~= "" then
			add(home_dir .. [[\]] .. rel)
		end
	end
	if extra_paths then
		for _, extra in ipairs(extra_paths) do
			add(extra)
		end
	end
	if MSYS_HOME then
		for _, rel in ipairs(relative_paths) do
			add(MSYS_HOME .. [[\]] .. rel)
		end
	end
	return candidates
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
	for _, root_dir in ipairs(roots) do
		if root_dir and root_dir ~= "" then
			if is_file(root_dir .. [[\usr\bin\bash.exe]]) then
				return [["]] .. root_dir .. [[\usr\bin\bash.exe"]]
			elseif is_file(root_dir .. [[\bin\bash.exe]]) then
				return [["]] .. root_dir .. [[\bin\bash.exe"]]
			end
		end
	end

	rebuild_cmd_index()
	local matches = cmd_cache.all_paths["bash.exe"]
	if matches then
		for _, candidate in ipairs(matches) do
			if not candidate:lower():find("system32") and is_file(candidate) then
				return [["]] .. candidate .. [["]]
			end
		end
	end

	return nil
end

local function load_vault_lua()
	local candidates = collect_home_candidates(
		"VAULT_DIR",
		{ [[.local\share\vault]], [[.config\vault]], [[.vault]] },
		nil
	)
	for _, dir_path in ipairs(candidates) do
		local vault_file = dir_path .. [[\vault.lua]]
		if is_file(vault_file) then
			pcall(dofile, vault_file)
			break
		end
	end
end
load_vault_lua()

-- ================================
-- CONSTANT
-- ================================

local function DEFAULT_BRANCH_DATA() return "" end

-- ================================
-- FUNCTIONS
-- ================================

local function split(input_str, pattern)
	local parts = {}
	for chunk in input_str:gmatch("[^" .. pattern .. "]+") do
		table.insert(parts, chunk)
	end
	return parts
end

local function last(list)
	return list[#list]
end

local function get_admin()
	if os and os.isuseradmin then
		local ok, is_admin = pcall(os.isuseradmin)
		if ok and is_admin ~= nil then
			return is_admin == true
		end
	end
	return false
end

local function get_user()
	local env_user = os.getenv("USERNAME") or os.getenv("USER")
	if env_user and env_user ~= "" then
		return env_user
	end
	return "user"
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
	local status_handle = io.popen([[git status --porcelain=v1 -uno --ignore-submodules=dirty 2>nul]])
	if status_handle then
		local status_line = status_handle:read("*l")
		status_handle:close()
		if status_line and trim(status_line) ~= "" then
			is_dirty = true
		end
	end

	return {
		branch = branch_data,
		is_dirty = is_dirty,
	}
end

local function get_win_build()
	if not (os and os.getfileversion) then
		return nil
	end
	local binaries = {
		get_system32_path("kernel32.dll"),
		get_system32_path("cmd.exe"),
	}
	for _, binary_path in ipairs(binaries) do
		local ok, version_info = pcall(os.getfileversion, binary_path)
		if ok and type(version_info) == "table" then
			local raw_ver = version_info.productvernum
				or version_info.filevernum
				or version_info.productversion
				or version_info.fileversion
			if type(raw_ver) == "string" then
				local build_str = raw_ver:match("10%.0%.(%d+)")
				if build_str then
					return tonumber(build_str)
				end
			end
		end
	end
	return nil
end

local function get_win_cache_path()
	local cache_root = os.getenv("XDG_CACHE_HOME") or os.getenv("LOCALAPPDATA") or os.getenv("TEMP")
	if not cache_root or cache_root == "" then
		return nil
	end
	return cache_root .. [[\clink_winver.cache]]
end

local function read_cached_display_version(build_num)
	if not build_num then return nil end
	local cache_path = get_win_cache_path()
	if not cache_path then return nil end
	local handle = io.open(cache_path, "r")
	if not handle then return nil end
	local line = handle:read("*l")
	handle:close()
	if not line then return nil end
	local cached_build, display_ver = line:match("^(%d+):(%S+)$")
	if cached_build and tonumber(cached_build) == build_num then
		return display_ver
	end
	return nil
end

local function write_cached_display_version(build_num, display_ver)
	if not build_num or not display_ver or display_ver == "" then return end
	local cache_path = get_win_cache_path()
	if not cache_path then return end
	local handle = io.open(cache_path, "w")
	if handle then
		handle:write(tostring(build_num) .. ":" .. display_ver .. "\n")
		handle:close()
	end
end

local win_build_num = get_win_build()
local win_display_version = read_cached_display_version(win_build_num)

local function format_win_info(build_num, display_ver)
	if not build_num then return "NT" end
	if build_num >= 22000 then
		return (display_ver and display_ver ~= "") and ("11 " .. display_ver) or "11"
	elseif build_num >= 10240 then
		return (display_ver and display_ver ~= "") and ("10 " .. display_ver) or "10"
	end
	return "NT 10.0"
end

local function get_win_info()
	return format_win_info(win_build_num, win_display_version)
end

local function get_win_icon()
	if win_build_num and win_build_num >= 22000 then
		return ""
	end
	return ""
end

local function refresh_win_display_version()
	if not win_build_num then return "" end
	local reg_handle = io.popen(get_system32_path("reg") .. [[ query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v DisplayVersion 2>nul]])
	if not reg_handle then return "" end
	local reg_out = reg_handle:read("*a")
	reg_handle:close()
	if not reg_out then return "" end
	local display_ver = reg_out:match("DisplayVersion%s+REG_SZ%s+(%S+)")
	if display_ver and display_ver ~= "" then
		write_cached_display_version(win_build_num, display_ver)
		return display_ver
	end
	return ""
end

local function extract_prompt(prompt_text)
	local prompt_venv = string.match(prompt_text, "^%((.-)%)")
	local prompt_cwd = os.getcwd()
	local prompt_dir = last(split(prompt_cwd, "\\"))
	if prompt_cwd == os.getenv("HOME") or prompt_cwd == os.getenv("USERPROFILE") or (MSYS_HOME and prompt_cwd == MSYS_HOME) then
		prompt_dir = "~"
	end

	return {
		venv = prompt_venv,
		cwd = prompt_cwd,
		dir = prompt_dir,
	}
end

-- ================================
-- CONSTANT COLORS
-- ================================

local function GET_RESET() return "\x1b[0m" end

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

local function set_text_color(color_code)
	return "\x1b[3" .. color_code .. "m"
end

local function set_text_bright_color(color_code)
	return "\x1b[9" .. color_code .. "m"
end

local function text_red(text)
	return set_text_color(GET_RED()) .. text .. GET_RESET()
end

local function text_green(text)
	return set_text_color(GET_GREEN()) .. text .. GET_RESET()
end

local function text_yellow(text)
	return set_text_color(GET_YELLOW()) .. text .. GET_RESET()
end

local function text_blue(text)
	return set_text_color(GET_BLUE()) .. text .. GET_RESET()
end

local function text_magenta(text)
	return set_text_color(GET_MAGENTA()) .. text .. GET_RESET()
end

local function text_cyan(text)
	return set_text_color(GET_CYAN()) .. text .. GET_RESET()
end

local function text_bright_black(text)
	return set_text_bright_color(GET_BLACK()) .. text .. GET_RESET()
end

local function text_bright_red(text)
	return set_text_bright_color(GET_RED()) .. text .. GET_RESET()
end

local function text_bright_green(text)
	return set_text_bright_color(GET_GREEN()) .. text .. GET_RESET()
end

local function text_bright_yellow(text)
	return set_text_bright_color(GET_YELLOW()) .. text .. GET_RESET()
end

local function text_bright_blue(text)
	return set_text_bright_color(GET_BLUE()) .. text .. GET_RESET()
end

local function text_bright_magenta(text)
	return set_text_bright_color(GET_MAGENTA()) .. text .. GET_RESET()
end

local function text_bright_cyan(text)
	return set_text_bright_color(GET_CYAN()) .. text .. GET_RESET()
end

-- ================================
-- VARIABLES
-- ================================

local is_admin = get_admin()
local active_user = get_user()
local win_info = get_win_info()
local win_icon = get_win_icon()

-- ================================
-- APPEARANCE
-- ================================

local prompt_filter = clink.promptfilter(10)
function prompt_filter:filter(prompt)
	local prompt_info = extract_prompt(prompt)
	current.venv = prompt_info.venv
	current.cwd = prompt_info.cwd
	current.dir = prompt_info.dir

	if win_display_version == nil and clink.promptcoroutine then
		local fetched_ver = clink.promptcoroutine(refresh_win_display_version)
		if fetched_ver ~= nil then
			win_display_version = fetched_ver
			win_info = format_win_info(win_build_num, win_display_version)
		end
	end

	local line1 = text_bright_black("") ..
		text_bright_blue(win_icon .. " ") ..
		text_bright_magenta(win_info .. " ") ..
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

	if is_admin then
		line2 = line2 .. text_bright_black("") .. text_bright_blue(" ") .. text_bright_red("admin") .. text_bright_black("")
	else
		line2 = line2 .. text_bright_black("") .. text_bright_blue(" ") .. text_bright_green(active_user) .. text_bright_black("")
	end

	local branch_info = clink.promptcoroutine(get_git_branch)
	local active_branch = nil
	local active_dirty = false
	if branch_info ~= nil and branch_info.branch ~= nil then
		active_branch = branch_info.branch
		active_dirty = branch_info.is_dirty
		current.branch = active_branch
		current.is_dirty = active_dirty
	elseif current.branch ~= nil then
		active_branch = current.branch
		active_dirty = current.is_dirty or false
	end

	if active_branch then
		local dirty_indicator = active_dirty and text_bright_yellow("*") or ""
		line2 = line2 .. " " .. text_bright_black("") .. text_bright_red("󰊢 ") .. text_bright_magenta(active_branch) .. dirty_indicator .. text_bright_black("")
	end

	if prompt_info.venv ~= nil then
		line2 = line2 .. " " .. text_bright_black("") .. text_bright_blue(" ") .. text_bright_cyan(prompt_info.venv) .. text_bright_black("")
	end

	local line3 = text_bright_black("\n└─") .. text_bright_blue(" ")

	prompt = GET_RESET() .. line1 .. line2 .. line3 .. GET_RESET()
	current.prompt = prompt
	return prompt
end

function prompt_filter:transientfilter(prompt)
	return current.prompt
end

-- ================================
-- SSH KEY RESOLUTION
-- ================================

local function resolve_vault_ssh_key(explicit_key, key_name)
	if explicit_key and explicit_key ~= "" and is_file(explicit_key) then
		return explicit_key
	end
	local candidates = collect_home_candidates(
		nil,
		{
			[[.local\share\vault\keys\]] .. key_name,
			[[.config\vault\keys\]] .. key_name,
			[[.vault\keys\]] .. key_name,
		},
		os.getenv("VAULT_DIR") and { os.getenv("VAULT_DIR") .. [[\keys\]] .. key_name } or nil
	)
	return resolve_candidate(candidates, is_file)
end

-- ================================
-- POWERSHELL HELPERS
-- ================================

local function get_pwsh_exe()
	return has_cmd("pwsh") and "pwsh" or "powershell"
end

local function ps_single_quote(value)
	return "'" .. tostring(value):gsub("'", "''") .. "'"
end

local function get_pwsh_profile_loader()
	local repo_dir = os.getenv("SHELL_REPO_DIR")
	if not repo_dir or repo_dir == "" then
		local repo_candidates = collect_home_candidates(
			"SHELL_REPO_DIR",
			{ [[.local\share\shell]], [[.config\shell]], [[.shell]] },
			{ [[C:\Program Files\Shell]] }
		)
		repo_dir = resolve_candidate(repo_candidates, is_dir)
	end
	local fallback_block = ""
	if repo_dir and repo_dir ~= "" then
		local ps1_path = repo_dir .. [[\target\windows\powershell\profile.ps1]]
		fallback_block = "; if (-not (Get-Command Update-All -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath "
			.. ps_single_quote(ps1_path)
			.. ")) { . "
			.. ps_single_quote(ps1_path)
			.. " }"
	end
	return "if ($PROFILE -and $PROFILE.CurrentUserAllHosts -and (Test-Path -LiteralPath $PROFILE.CurrentUserAllHosts)) { . $PROFILE.CurrentUserAllHosts }; if ($PROFILE -and (Test-Path -LiteralPath $PROFILE)) { . $PROFILE }" .. fallback_block
end

local function parse_first_arg(raw_args)
	local cleaned = trim(raw_args or "")
	if cleaned == "" then return "" end
	if cleaned:sub(1, 1) == '"' then
		local unquoted = cleaned:match('^"([^"]*)"')
		if unquoted then return unquoted end
	end
	return cleaned
end

local function build_ps_invoke_cmd(ps_func, raw_args)
	local pwsh_exe = get_pwsh_exe()
	local loader = get_pwsh_profile_loader()
	local target_arg = parse_first_arg(raw_args)
	local invocation = ps_func
	if target_arg ~= "" then
		invocation = invocation .. " " .. ps_single_quote(target_arg)
	end
	return pwsh_exe .. [[ -NoProfile -ExecutionPolicy Bypass -Command "& { ]] .. loader .. [[; ]] .. invocation .. [[ }"]]
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
-- ALIASES
-- ================================

local function get_web_browser_cmd()
	local candidates = { "google-chrome", "google-chrome-stable", "chrome", "brave", "chromium", "msedge", "firefox" }
	for _, browser_name in ipairs(candidates) do
		if has_cmd(browser_name) then return browser_name end
	end
	local program_files = os.getenv("ProgramFiles") or [[C:\Program Files]]
	local program_files_x86 = os.getenv("ProgramFiles(x86)") or [[C:\Program Files (x86)]]
	local local_appdata = os.getenv("LOCALAPPDATA") or ""
	local paths = {
		program_files .. [[\Google\Chrome\Application\chrome.exe]],
		program_files_x86 .. [[\Google\Chrome\Application\chrome.exe]],
		program_files .. [[\BraveSoftware\Brave-Browser\Application\brave.exe]],
		local_appdata .. [[\BraveSoftware\Brave-Browser\Application\brave.exe]],
		program_files_x86 .. [[\Microsoft\Edge\Application\msedge.exe]],
		program_files .. [[\Mozilla Firefox\firefox.exe]],
	}
	for _, browser_path in ipairs(paths) do
		if is_file(browser_path) then return [["]] .. browser_path .. [["]] end
	end
	return "explorer"
end

local pwsh_exe_cmd = get_pwsh_exe()
local web_browser_cmd = get_web_browser_cmd()
local default_editor_cmd = has_cmd("nvim") and [[nvim]]
	or (has_cmd("vim") and [[vim]]
	or (has_cmd("hx") and [[hx]] or [[emacs.exe -nw]]))
local has_rg = has_cmd("rg")
local has_eza = has_cmd("eza")
local has_bat = has_cmd("bat")
local has_fd = has_cmd("fd")
local has_dust = has_cmd("dust")
local has_procs = has_cmd("procs")
local has_btm = has_cmd("btm")
local delta_cmd = has_cmd("delta") and [[delta]]
	or (has_cmd("git-delta") and [[git-delta]] or [[busybox diff --color=auto]])
local msys_target_dir = MSYS_HOME or os.getenv("MSYS2_ROOT") or [[C:\msys64]]

local aliases = {
	-- --------------------------------
	-- MY SHORTCUTS
	-- --------------------------------
	["upget"] = [[winget upgrade --all]],
	["upscp"] = [[scoop update && scoop update --all]],
	["upcho"] = pwsh_exe_cmd .. [[ -NoProfile -Command "Start-Process choco -ArgumentList 'upgrade all -y' -Verb RunAs -Wait"]],
	["upwin"] = pwsh_exe_cmd .. [[ -NoProfile -Command "Get-WindowsUpdate -AcceptAll -Install -AutoReboot"]],

	["goto-msys"] = [[cd /d "]] .. msys_target_dir .. [["]],
	["show-msys"] = [[start "" "]] .. msys_target_dir .. [["]],

	["ek"] = [[taskkill /IM emacs.exe /F]],
	["es"] = [[runemacs --fg-daemon]],
	["er"] = [[taskkill /IM emacs.exe /F && runemacs --fg-daemon]],
	["ec"] = [[emacsclientw.exe --create-frame --alternate-editor ""]],
	["oe"] = [[emacsclientw.exe --create-frame --alternate-editor "" .]],
	["en"] = [[emacs.exe -nw]],
	["enw"] = [[emacs.exe -nw]],
	["emacs-nw"] = [[emacs.exe -nw]],
	["oen"] = [[emacs.exe -nw .]],
	["oenw"] = [[emacs.exe -nw .]],
	["open-emacs"] = [[emacsclientw.exe --create-frame --alternate-editor "" .]],
	["open-emacs-nw"] = [[emacs.exe -nw .]],
	["emacs-eshell"] = [[emacsclientw.exe --create-frame --alternate-editor "" --eval "(progn (cd \".\") (aweshell/new))"]],
	["open-eshell"] = [[emacsclientw.exe --create-frame --alternate-editor "" --eval "(progn (cd \".\") (aweshell/new))"]],
	["oes"] = [[emacsclientw.exe --create-frame --alternate-editor "" --eval "(progn (cd \".\") (aweshell/new))"]],
	["esh"] = [[emacsclientw.exe --create-frame --alternate-editor "" --eval "(progn (cd \".\") (aweshell/new))"]],

	-- --------------------------------
	-- DESKTOP APPLICATIONS & EDITORS
	-- --------------------------------
	["editor"] = default_editor_cmd,
	["e"] = default_editor_cmd,
	["open-helix"] = [[hx]],
	["open-hx"] = [[hx]],
	["oh"] = [[hx]],
	["h"] = [[hx]],
	["open-vlc"] = [[start "" vlc]],
	["ov"] = [[start "" vlc]],
	["open-mpv"] = [[mpv]],
	["om"] = [[mpv]],
	["open-wireshark"] = [[start "" wireshark]],
	["open-shark"] = [[start "" wireshark]],
	["os"] = [[start "" wireshark]],
	["open-firefox"] = [[start "" firefox]],
	["of"] = [[start "" firefox]],
	["open-browser"] = [[start "" ]] .. web_browser_cmd,
	["open-web"] = [[start "" ]] .. web_browser_cmd,
	["ow"] = [[start "" ]] .. web_browser_cmd,
	["open-onlyoffice"] = [[start "" desktopeditors]],
	["oo"] = [[start "" desktopeditors]],
	["open-libreoffice"] = [[start "" soffice]],
	["ol"] = [[start "" soffice]],
	["open-terminal"] = [[start "" wt.exe]],
	["ot"] = [[start "" wt.exe]],
	["open-thunderbird"] = [[start "" thunderbird]],
	["omail"] = [[start "" thunderbird]],
	["oth"] = [[start "" thunderbird]],

	["open-kate"] = [[start "" kate]],
	["ok"] = [[start "" kate]],
	["open-geany"] = [[start "" geany]],
	["og"] = [[start "" geany]],
	["open-code"] = [[code .]],
	["oc"] = [[code .]],
	["open-codium"] = [[codium .]],
	["ocm"] = [[codium .]],
	["open-antigravity"] = [[antigravity-ide .]],
	["open-ant"] = [[antigravity-ide .]],
	["oa"] = [[antigravity-ide .]],
	["open-zed"] = [[zed .]],
	["oz"] = [[zed .]],
	["ant"] = [[antigravity-ide]],

	-- --------------------------------
	-- GOOGLE ANTIGRAVITY CLI
	-- --------------------------------
	["a"] = [[agy]],
	["aa"] = [[agy --dangerously-skip-permissions]],
	["ad"] = [[agy --dangerously-skip-permissions]],
	["agy-continue"] = [[agy -c]],
	["agyc"] = [[agy -c]],
	["agyr"] = [[agy -c]],
	["agy-return"] = [[agy -c]],
	["agy-auto"] = [[agy --dangerously-skip-permissions]],
	["agy-danger"] = [[agy --dangerously-skip-permissions]],
	["agya"] = [[agy --dangerously-skip-permissions]],
	["agyd"] = [[agy --dangerously-skip-permissions]],
	["agy-continue-auto"] = [[agy -c --dangerously-skip-permissions]],
	["agy-continue-danger"] = [[agy -c --dangerously-skip-permissions]],
	["agyca"] = [[agy -c --dangerously-skip-permissions]],
	["agycd"] = [[agy -c --dangerously-skip-permissions]],
	["agyra"] = [[agy -c --dangerously-skip-permissions]],
	["agyrd"] = [[agy -c --dangerously-skip-permissions]],
	["agy-return-auto"] = [[agy -c --dangerously-skip-permissions]],
	["agy-return-danger"] = [[agy -c --dangerously-skip-permissions]],

	-- --------------------------------
	-- CONSOLE AND TERMINAL
	-- --------------------------------
	["clear"] = [[cls]],

	-- --------------------------------
	-- FILES AND DIRECTORIES
	-- --------------------------------
	["ls"] = [[busybox ls -F --color=auto]],
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
	["open-smart"] = [[start ""]],
	["o"] = [[start ""]],
	["hist"] = [[doskey /history]],
	["hg"] = [[doskey /history]],
	["z"] = [[zoxide]],

	-- --------------------------------
	-- SYSTEM AND PROCESSES
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
	-- DISK UTILS AND INFO
	-- --------------------------------
	["free"] = [[busybox free -m]],
	["who"] = [[quser]],
	["wc"] = [[busybox wc]],
	["diff"] = [[busybox diff --color=auto]],

	-- --------------------------------
	-- SEARCH AND NETWORK
	-- --------------------------------
	["grep"] = [[busybox grep --color=auto]],
	["find"] = [[busybox find]],
	["ifconfig"] = [[ipconfig]],
	["ip"] = [[ipconfig]],
	["ping"] = [[ping -t]],
	["wget"] = [[curl -O]],
	["env"] = [[set]],
	["export"] = [[set]],

	-- --------------------------------
	-- MODERN RUST CLI TOOLS
	-- --------------------------------
	["r"] = has_rg and [[rg --smart-case]] or [[findstr /I]],
	["g"] = has_rg and [[rg --smart-case]] or [[findstr /I]],
	["l"] = has_eza and [[eza --icons=auto --group-directories-first]] or [[busybox ls -F --color=auto]],
	["ll"] = has_eza and [[eza -la --icons=auto --group-directories-first --git]] or [[busybox ls -alF --color=auto]],
	["la"] = has_eza and [[eza -a --icons=auto --group-directories-first]] or [[busybox ls -A --color=auto]],
	["lr"] = has_eza and [[eza -R --icons=auto --group-directories-first]] or [[busybox ls -RF --color=auto]],
	["lar"] = has_eza and [[eza -aR --icons=auto --group-directories-first]] or [[busybox ls -aRF --color=auto]],
	["llr"] = has_eza and [[eza -laR --icons=auto --group-directories-first --git]] or [[busybox ls -laRF --color=auto]],
	["c"] = has_bat and [[bat --paging=never]] or [[busybox cat]],
	["b"] = has_bat and [[bat]] or [[busybox less -R]],
	["f"] = has_fd and [[fd]] or [[busybox find]],
	["d"] = has_dust and [[dust]] or [[busybox free -m]],
	["p"] = has_procs and [[procs]] or [[tasklist]],
	["t"] = has_btm and [[btm]] or [[taskmgr]],
	["delta"] = delta_cmd,

	-- --------------------------------
	-- VERSION CONTROL ALIASES
	-- --------------------------------
	["gs"] = [[git status -sb]],
	["gd"] = [[git diff]],
	["gst"] = [[git status]],
	["gco"] = [[git checkout]],
	["gcb"] = [[git checkout -b]],
	["gsw"] = [[git switch]],
	["gswc"] = [[git switch -c]],
	["gcm"] = [[git commit -m]],
	["gaa"] = [[git add --all]],
	["gl"] = [[git pull]],
	["gp"] = [[git push]],
	["glog"] = [[git log --oneline --decorate --graph -n 20]],
}

local function build_ssh_server_cmd(ip_var, user_var, key_var, default_key_name, extra_args)
	local server_ip = os.getenv(ip_var)
	if not server_ip or server_ip == "" then
		_ui_err(ip_var .. " não definido (configure no Vault ou variável de ambiente).")
		return ""
	end
	local server_user = os.getenv(user_var)
	if not server_user or server_user == "" then
		server_user = "ubuntu"
	end
	local key_path = resolve_vault_ssh_key(os.getenv(key_var), default_key_name)
	local suffix = (extra_args and extra_args ~= "") and (" " .. extra_args) or ""
	if key_path then
		return [[ssh -i "]] .. key_path .. [[" "]] .. server_user .. [[@]] .. server_ip .. [["]] .. suffix
	end
	return [[ssh "]] .. server_user .. [[@]] .. server_ip .. [["]] .. suffix
end

local function cmd_take_dir(raw_args)
	local target_dir = parse_first_arg(raw_args):gsub('"', "")
	if target_dir == "" then
		_ui_err("Uso: take <diretorio>")
		return ""
	end
	return [[(if not exist "]] .. target_dir .. [[" mkdir "]] .. target_dir .. [[") && cd /d "]] .. target_dir .. [["]]
end

local function cmd_cd_git_root()
	local pipe = io.popen([[git rev-parse --show-toplevel 2>nul]])
	local git_root = pipe and pipe:read("*l") or ""
	if pipe then pipe:close() end
	git_root = trim(git_root)
	if git_root == "" then
		_ui_err("Não está dentro de um repositório git.")
		return ""
	end
	return [[cd /d "]] .. git_root:gsub("/", "\\") .. [["]]
end

local function cmd_extract_archive(raw_args)
	local target_file = parse_first_arg(raw_args)
	if target_file == "" then
		_ui_err("Uso: extract <arquivo>")
		return ""
	end
	return build_ps_invoke_cmd("Invoke-ExtractArchive", raw_args)
end

local rewrite_commands = {
	["personal-server"] = function(raw_args)
		return build_ssh_server_cmd("PERSONAL_SERVER_IP", "PERSONAL_SERVER_USER", "PERSONAL_SERVER_KEY", "ssh-key-personal-server.key", raw_args)
	end,
	["venture-server"] = function(raw_args)
		return build_ssh_server_cmd("VENTURE_SERVER_IP", "VENTURE_SERVER_USER", "VENTURE_SERVER_KEY", "ssh-key-venture-server.key", raw_args)
	end,
	["take"] = cmd_take_dir,
	["take-dir"] = cmd_take_dir,
	["mkcd"] = cmd_take_dir,
	["cdb"] = cmd_cd_git_root,
	["cd-git-root"] = cmd_cd_git_root,
	["extract"] = cmd_extract_archive,
	["x"] = cmd_extract_archive,
}

for alias_name, _ in pairs(aliases) do
	local alias_parser = clink.arg.new_parser()
	clink.arg.register_parser(alias_name, alias_parser)
end

for cmd_name, _ in pairs(rewrite_commands) do
	local rewrite_parser = clink.arg.new_parser()
	clink.arg.register_parser(cmd_name, rewrite_parser)
end

local function filter_alias(text)
	local cmd_name, raw_args = text:match("^%s*(%S+)(.*)")
	if not cmd_name then
		return nil
	end
	if rewrite_commands[cmd_name] then
		return rewrite_commands[cmd_name](trim(raw_args or "")), false
	end
	if aliases[cmd_name] then
		return aliases[cmd_name] .. (raw_args or ""), false
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
	["lua"] = true,
}

local lua_parser = clink.arg.new_parser()
for cmd_name, _ in pairs(lua_commands) do
	clink.arg.register_parser(cmd_name, lua_parser)
end

local function run_lua_logic(code)
	local handle = io.open(code, "r")
	if handle then
		handle:close()
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
	local cmd_name, raw_args = text:match("^%s*(%S+)%s+(.*)")
	if not cmd_name then
		cmd_name = text:match("^%s*(%S+)%s*$")
		raw_args = ""
	end

	if cmd_name and lua_commands[cmd_name] then
		if #raw_args > 0 then
			run_lua_logic(raw_args)
		else
			print("[LuaCMD]: Digite um codigo ou arquivo para executar.")
		end
		return "", false
	end
	return nil
end

if clink.onfilterinput then
	clink.onfilterinput(filter_lua_cmd)
end

-- ================================
-- UPDATE COMMANDS ECOSYSTEM
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
	local root_dir = "."
	for word in flags:gmatch("%S+") do
		if not word:match("^%-") then
			root_dir = word
			break
		end
	end

	local action_title = is_status and "Auditando status de" or (is_dry and "Simulando atualização de" or "Buscando e atualizando")
	_ui_step(action_title .. " repositórios Git em: " .. root_dir)
	print("")

	local pipe = io.popen([[for /r "]] .. root_dir .. [[" %d in (.) do @if exist "%d\.git" echo %~fd]])
	if not pipe then
		_ui_err("Falha ao iniciar varredura Git.")
		return
	end

	local repos = {}
	for line in pipe:lines() do
		local repo_path = trim(line)
		if repo_path ~= "" and is_git_repo(repo_path) then
			table.insert(repos, repo_path)
		end
	end
	pipe:close()

	local function path_depth(target_path)
		local _, count = target_path:gsub([[\]], "")
		return count
	end

	table.sort(repos, function(left, right)
		return path_depth(left) < path_depth(right)
	end)

	if #repos == 0 then
		_ui_info("Nenhum repositório Git encontrado em " .. root_dir .. " (profundidade máxima de busca).")
		return
	end

	for _, repo_path in ipairs(repos) do
		local branch_pipe = io.popen([[git -C "]] .. repo_path .. [[" branch --show-current 2>nul]])
		local branch = branch_pipe and branch_pipe:read("*l") or ""
		if branch_pipe then branch_pipe:close() end
		local branch_label = (branch and branch ~= "") and branch or "detached"

		if is_status then
			local status_pipe = io.popen([[git -C "]] .. repo_path .. [[" status -s 2>nul]])
			local status_out = status_pipe and status_pipe:read("*a") or ""
			if status_pipe then status_pipe:close() end

			local cherry_pipe = io.popen([[git -C "]] .. repo_path .. [[" cherry -v 2>nul]])
			local unpushed = cherry_pipe and cherry_pipe:read("*a") or ""
			if cherry_pipe then cherry_pipe:close() end

			if (status_out and trim(status_out) ~= "") or (unpushed and trim(unpushed) ~= "") then
				_ui_warn(repo_path .. " [" .. branch_label .. "]: divergências detectadas")
				if unpushed and trim(unpushed) ~= "" then
					print("  \x1b[1;33m↳ Commits pendentes de push\x1b[0m")
				end
				if status_out and trim(status_out) ~= "" then
					print("  \x1b[90m" .. trim(status_out) .. "\x1b[0m")
				end
			else
				_ui_ok(repo_path .. " [" .. branch_label .. "]: sincronizado e limpo")
			end
		elseif is_dry then
			_ui_sub("[DRY-RUN PULL] " .. repo_path .. " [" .. branch_label .. "]")
		else
			_ui_sub("Atualizando " .. repo_path .. "...")
			local ok = os.execute([[git -C "]] .. repo_path .. [[" pull --ff-only 2>nul]])
			if ok ~= true and ok ~= 0 then
				os.execute([[git -C "]] .. repo_path .. [[" pull]])
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
	local root_dir = "."
	for word in flags:gmatch("%S+") do
		if not word:match("^%-") then
			root_dir = word
			break
		end
	end

	local action_title = is_status and "Auditando commits pendentes em" or (is_dry and "Simulando push de" or "Buscando e enviando")
	_ui_step(action_title .. " repositórios Git em: " .. root_dir)
	print("")

	local pipe = io.popen([[for /r "]] .. root_dir .. [[" %d in (.) do @if exist "%d\.git" echo %~fd]])
	if not pipe then
		_ui_err("Falha ao iniciar varredura Git.")
		return
	end

	local repos = {}
	for line in pipe:lines() do
		local repo_path = trim(line)
		if repo_path ~= "" and is_git_repo(repo_path) then
			table.insert(repos, repo_path)
		end
	end
	pipe:close()

	local function path_depth(target_path)
		local _, count = target_path:gsub([[\]], "")
		return count
	end

	table.sort(repos, function(left, right)
		return path_depth(left) > path_depth(right)
	end)

	if #repos == 0 then
		_ui_info("Nenhum repositório Git encontrado em " .. root_dir .. ".")
		return
	end

	for _, repo_path in ipairs(repos) do
		local check_pipe = io.popen([[git -C "]] .. repo_path .. [[" cherry -v 2>nul]])
		local unpushed = check_pipe and check_pipe:read("*a") or ""
		if check_pipe then check_pipe:close() end

		local branch_pipe = io.popen([[git -C "]] .. repo_path .. [[" branch --show-current 2>nul]])
		local branch = branch_pipe and branch_pipe:read("*l") or ""
		if branch_pipe then branch_pipe:close() end
		local branch_label = (branch and branch ~= "") and branch or "detached"

		if trim(unpushed) ~= "" then
			if is_status then
				_ui_warn(repo_path .. " [" .. branch_label .. "]: commits pendentes de envio")
				print("  \x1b[1;33m" .. trim(unpushed) .. "\x1b[0m")
			elseif is_dry then
				_ui_sub("[DRY-RUN PUSH] " .. repo_path .. " [" .. branch_label .. "]")
			else
				_ui_sub("Enviando " .. repo_path .. " [" .. branch_label .. "]...")
				local ok = os.execute([[git -C "]] .. repo_path .. [[" push]])
				if ok == 0 or ok == true then
					_ui_ok(repo_path .. ": push concluído com sucesso!")
				else
					_ui_err(repo_path .. ": falha no push.")
				end
			end
		else
			if is_status then
				_ui_ok(repo_path .. " [" .. branch_label .. "]: nada a enviar")
			else
				_ui_ok(repo_path .. ": já atualizado com o remote.")
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
	local home_dir = get_home_dir()
	local candidates = collect_home_candidates(
		"PROFILE_DIR",
		{ [[.local\share\profile]], [[.config\profile]], [[.profile]] },
		home_dir ~= "" and { home_dir .. [[\OneDrive\Documentos\Profile]], home_dir .. [[\Documents\Profile]] } or nil
	)
	local target_dir = resolve_candidate(candidates, function(dir_path)
		return is_file(dir_path .. [[\profile.sh]])
	end)

	if target_dir then
		local bash_cmd = get_bash_cmd()
		if bash_cmd then
			local unix_target = to_unix_path(target_dir)
			local safe_flags = flags:gsub('"', '\\"')
			os.execute([["]] .. bash_cmd .. [[ -c "MSYS=winsymlinks:nativestrict ']] .. unix_target .. [[/profile.sh' extensions ]] .. safe_flags .. [[""]])
		else
			_ui_warn("Ambiente MSYS2/Bash não detectado no PATH.")
		end
	else
		_ui_info("Repositório do Profile não encontrado.")
	end
end

local function ensure_vim_junction(vimfiles_dir, is_status, is_dry)
	if not vimfiles_dir or vimfiles_dir == "" or not is_dir(vimfiles_dir) then return end

	local seen = {}
	local dests = {}
	local function add_dest(parent_dir)
		if not parent_dir or parent_dir == "" or not is_dir(parent_dir) then return end
		local clean_parent = parent_dir:gsub("/", "\\"):gsub("\\+$", "")
		local dst = clean_parent .. [[\.vim]]
		local key = dst:lower()
		if not seen[key] then
			seen[key] = true
			table.insert(dests, dst)
		end
	end

	add_dest(os.getenv("HOME"))
	add_dest(os.getenv("USERPROFILE"))
	if MSYS_HOME and is_dir(MSYS_HOME) then
		add_dest(MSYS_HOME)
	end
	if #dests == 0 then return end

	local pwsh_exe = get_pwsh_exe()
	local mode = is_status and "status" or (is_dry and "dry-run" or "update")
	local quoted_src = ps_single_quote(vimfiles_dir)
	local quoted_mode = ps_single_quote(mode)

	for _, dst in ipairs(dests) do
		local quoted_dst = ps_single_quote(dst)
		local ps_body = "$d=" .. quoted_dst
			.. ";$s=[System.IO.Path]::GetFullPath(" .. quoted_src .. ").TrimEnd([char[]]'\\/')"
			.. ";$a=" .. quoted_mode
			.. ";$i=Get-Item -LiteralPath $d -Force -ErrorAction SilentlyContinue"
			.. ";$rp=$false;$dirRp=$false"
			.. ";if($null -ne $i){$rp=($i.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0;$dirRp=$i.PSIsContainer -or (($i.Attributes -band [System.IO.FileAttributes]::Directory) -ne 0)}"
			.. "else{try{$at=[System.IO.File]::GetAttributes($d);if(($at -band [System.IO.FileAttributes]::ReparsePoint) -ne 0){$rp=$true;$dirRp=($at -band [System.IO.FileAttributes]::Directory) -ne 0}}catch{}}"
			.. ";if($rp){$t=$null;if(($null -ne $i) -and $i.PSObject.Properties['Target'] -and $i.Target){$t=@($i.Target)[0]}elseif(($null -ne $i) -and $i.PSObject.Properties['LinkTarget'] -and $i.LinkTarget){$t=$i.LinkTarget}"
			.. ";$ok=$false;if($t){if($t.StartsWith('\\\\?\\') -or $t.StartsWith('\\??\\')){$t=$t.Substring(4)}"
			.. ";if(-not [System.IO.Path]::IsPathRooted($t)){$t=[System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($d),$t)}"
			.. ";try{$ft=[System.IO.Path]::GetFullPath($t).TrimEnd([char[]]'\\/');if([string]::Equals($ft,$s,[System.StringComparison]::OrdinalIgnoreCase) -and [System.IO.Directory]::Exists($d)){$ok=$true}}catch{}}"
			.. ";if($ok){'OK';exit 0}"
			.. ";if($a -eq 'update'){try{if($dirRp){[System.IO.Directory]::Delete($d,$false)}else{[System.IO.File]::Delete($d)};New-Item -ItemType Junction -Path $d -Target $s -ErrorAction Stop|Out-Null;'RECREATED'}catch{'ERR:'+$_.Exception.Message}}"
			.. "else{if([System.IO.Directory]::Exists($d)){'DIVERGENT'}else{'BROKEN'}};exit 0}"
			.. ";if($null -eq $i){if($a -eq 'update'){try{New-Item -ItemType Junction -Path $d -Target $s -ErrorAction Stop|Out-Null;'CREATED'}catch{'ERR:'+$_.Exception.Message}}else{'MISSING'};exit 0}"
			.. ";if($i.PSIsContainer){$ne=$true;try{$ne=@([System.IO.Directory]::GetFileSystemEntries($d)).Count -gt 0}catch{$ne=$true}"
			.. ";if($ne){'NONEMPTY'}elseif($a -eq 'update'){try{[System.IO.Directory]::Delete($d,$false);New-Item -ItemType Junction -Path $d -Target $s -ErrorAction Stop|Out-Null;'CREATED'}catch{'ERR:'+$_.Exception.Message}}else{'EMPTY'}}"
			.. "else{'FILE'}"

		local cmd = pwsh_exe .. [[ -NoProfile -NonInteractive -Command "& { ]] .. ps_body .. [[ }" 2>nul]]
		local pipe = io.popen(cmd)
		local status_out = ""
		if pipe then
			status_out = trim(pipe:read("*a") or "")
			pipe:close()
		end

		if status_out == "OK" then
			if is_status then
				_ui_ok("Junction Vim sincronizada: " .. dst .. " -> " .. vimfiles_dir)
			elseif is_dry then
				_ui_sub("[IN-SYNC] Junction Vim: " .. dst .. " -> " .. vimfiles_dir)
			end
		elseif status_out == "CREATED" or status_out == "RECREATED" then
			_ui_ok("Junction Vim configurada: " .. dst .. " -> " .. vimfiles_dir)
		elseif status_out == "MISSING" then
			if is_status then
				_ui_warn("Junction Vim ausente: " .. dst .. " -> " .. vimfiles_dir)
			elseif is_dry then
				_ui_sub("[DRY-RUN JUNCTION] " .. dst .. " -> " .. vimfiles_dir)
			end
		elseif status_out == "BROKEN" then
			if is_status then
				_ui_warn("Junction Vim quebrada: " .. dst .. " (esperado: " .. vimfiles_dir .. ")")
			elseif is_dry then
				_ui_sub("[DRY-RUN JUNCTION] Recriar " .. dst .. " -> " .. vimfiles_dir)
			end
		elseif status_out == "DIVERGENT" then
			if is_status then
				_ui_warn("Junction Vim divergente: " .. dst .. " (esperado: " .. vimfiles_dir .. ")")
			elseif is_dry then
				_ui_sub("[DRY-RUN JUNCTION] Recriar " .. dst .. " -> " .. vimfiles_dir)
			end
		elseif status_out == "EMPTY" then
			if is_status then
				_ui_warn("Diretório vazio em " .. dst .. " bloqueia junction para " .. vimfiles_dir)
			elseif is_dry then
				_ui_sub("[DRY-RUN JUNCTION] Remover diretório vazio e criar " .. dst .. " -> " .. vimfiles_dir)
			end
		elseif status_out == "NONEMPTY" then
			_ui_warn("Diretório real não-vazio encontrado em " .. dst .. "; preservando dados do usuário sem criar junction.")
		elseif status_out == "FILE" then
			_ui_warn("Arquivo existente em " .. dst .. " impede criação da junction para " .. vimfiles_dir .. ".")
		elseif status_out:sub(1, 4) == "ERR:" then
			_ui_warn("Falha ao configurar junction Vim em " .. dst .. ": " .. status_out:sub(5))
		else
			_ui_warn("Não foi possível verificar junction Vim em " .. dst .. ".")
		end
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
	local home_dir = get_home_dir()
	local appdata = os.getenv("APPDATA") or ""
	local localappdata = os.getenv("LOCALAPPDATA") or ""
	local found = false

	local function update_editor(name, dir_path, has_submodules)
		if is_git_repo(dir_path) then
			found = true
			if is_status then
				_ui_sub("Status de " .. name .. " em " .. dir_path .. "...")
				os.execute([[git -C "]] .. dir_path .. [[" status -s -b]])
			elseif is_dry then
				_ui_sub("[DRY-RUN] Atualização de " .. name .. " em " .. dir_path .. "...")
				_ui_sub([[git -C "]] .. dir_path .. [[" pull --ff-only]])
			else
				_ui_sub("Atualizando " .. name .. " em " .. dir_path .. "...")
				if name == "Emacs" and is_dir(dir_path .. [[\usr\local]]) then
					os.execute([[git -C "]] .. dir_path .. [[" clean -fd usr/local >nul 2>&1]])
				end
				os.execute([[git -C "]] .. dir_path .. [[" pull --ff-only]])
				if has_submodules and exists(dir_path .. [[\.gitmodules]]) then
					_ui_sub("Sincronizando submódulos Elisp...")
					os.execute([[git -C "]] .. dir_path .. [[" submodule update --init --recursive --remote --merge]])
				end
				_ui_ok(name .. " atualizado com sucesso!")
			end
		end
	end

	local function find_editor_dir(candidates)
		return resolve_candidate(candidates, function(dir_path)
			return is_dir(dir_path .. [[\.git]])
		end)
	end

	local emacs_dir = find_editor_dir({
		home_dir .. [[\.emacs.d]],
		appdata ~= "" and (appdata .. [[\.emacs.d]]) or nil,
		home_dir .. [[\.config\emacs]],
		MSYS_HOME and (MSYS_HOME .. [[\.emacs.d]]) or nil,
	})
	if emacs_dir then update_editor("Emacs", emacs_dir, true) end

	local helix_dir = find_editor_dir({
		appdata ~= "" and (appdata .. [[\helix]]) or nil,
		home_dir .. [[\AppData\Roaming\helix]],
		home_dir .. [[\.config\helix]],
		MSYS_HOME and (MSYS_HOME .. [[\.config\helix]]) or nil,
	})
	if helix_dir then update_editor("Helix", helix_dir, false) end

	local nvim_dir = find_editor_dir({
		localappdata ~= "" and (localappdata .. [[\nvim]]) or nil,
		home_dir .. [[\AppData\Local\nvim]],
		home_dir .. [[\.config\nvim]],
		MSYS_HOME and (MSYS_HOME .. [[\.config\nvim]]) or nil,
	})
	if nvim_dir then update_editor("NeoVim", nvim_dir, false) end

	local vim_dir = find_editor_dir({
		home_dir .. [[\vimfiles]],
		home_dir .. [[\.vim]],
		MSYS_HOME and (MSYS_HOME .. [[\.vim]]) or nil,
	})
	if vim_dir then update_editor("Vim", vim_dir, false) end

	local env_home = os.getenv("HOME") or ""
	local vimfiles_dir = resolve_candidate({
		home_dir ~= "" and (home_dir .. [[\vimfiles]]) or nil,
		env_home ~= "" and (env_home .. [[\vimfiles]]) or nil,
	}, is_dir)
	if vimfiles_dir then
		found = true
		ensure_vim_junction(vimfiles_dir, is_status, is_dry)
	end

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
	local home_dir = get_home_dir()
	local candidates = collect_home_candidates(
		"PROFILE_DIR",
		{ [[.local\share\profile]], [[.config\profile]], [[.profile]] },
		home_dir ~= "" and { home_dir .. [[\OneDrive\Documentos\Profile]], home_dir .. [[\Documents\Profile]] } or nil
	)
	local target_dir = resolve_candidate(candidates, is_git_repo)

	if target_dir then
		local is_query = flags:find("%-%-status") or flags:find("%-s")
		local is_pull = flags:find("%-%-pull")
		local is_dry = flags:find("%-%-dry%-run") or flags:find("%-n")
		if not is_query and not is_pull and not is_dry then
			_ui_step("Atualizando Universal Profile em: " .. target_dir .. "...")
			local handle = io.popen([[git -C "]] .. target_dir .. [[" status --porcelain 2>nul]])
			local status_out = handle and handle:read("*a") or ""
			if handle then handle:close() end
			if status_out and status_out:match("%S") then
				_ui_warn("Alterações locais não commitadas detectadas em: " .. target_dir .. ". Ignorando git pull para preservar dados.")
			else
				os.execute([[git -C "]] .. target_dir .. [[" pull --ff-only]])
			end
		end
		local script_path = target_dir .. [[\profile.sh]]
		if exists(script_path) then
			_ui_sub("Sincronizando dotfiles e links via profile.sh (MSYS2)...")
			local bash_cmd = get_bash_cmd()
			if bash_cmd then
				local unix_target = to_unix_path(target_dir)
				local safe_flags = flags:gsub('"', '\\"')
				os.execute([["]] .. bash_cmd .. [[ -c "MSYS=winsymlinks:nativestrict ']] .. unix_target .. [[/profile.sh' sync ]] .. safe_flags .. [[""]])
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
	local candidates = collect_home_candidates(
		"VAULT_DIR",
		{ [[.local\share\vault]], [[.config\vault]], [[.vault]] },
		nil
	)
	local target_dir = resolve_candidate(candidates, is_git_repo)

	if target_dir then
		local is_status = flags:find("%-%-status") or flags:find("%-s")
		local is_dry = flags:find("%-%-dry%-run") or flags:find("%-n")
		if is_status then
			_ui_step("Status do Universal Vault em: " .. target_dir .. "...")
			os.execute([[git -C "]] .. target_dir .. [[" status -s -b]])
			return
		end
		if is_dry then
			_ui_step("[DRY-RUN] Atualização do Universal Vault em: " .. target_dir .. "...")
			_ui_sub([[git -C "]] .. target_dir .. [[" pull --ff-only]])
			return
		end
		_ui_step("Atualizando Universal Vault em: " .. target_dir .. "...")
		os.execute([[git -C "]] .. target_dir .. [[" pull --ff-only]])
		local vault_lua = target_dir .. [[\vault.lua]]
		if is_file(vault_lua) then
			_ui_sub("Recarregando segredos e ambiente do Vault...")
			pcall(dofile, vault_lua)
		end
		_ui_ok("Universal Vault atualizado com sucesso!")
	else
		_ui_info("Repositório do Vault não encontrado.")
	end
end

local function cmd_vault_perms(args)
	local candidates = collect_home_candidates(
		"VAULT_DIR",
		{ [[.local\share\vault]], [[.config\vault]], [[.vault]] },
		nil
	)
	local target_dir = resolve_candidate(candidates, is_dir)

	if target_dir then
		local current_user = get_user()
		_ui_step("Ajustando permissões de segurança em " .. target_dir .. "...")
		os.execute([[icacls "]] .. target_dir .. [[" /inheritance:r /grant:r "]] .. current_user .. [[":(OI)(CI)F /c /q >nul 2>&1]])
		os.execute([[icacls "]] .. target_dir .. [[\*" /reset /t /c /q >nul 2>&1]])
		os.execute([[git -C "]] .. target_dir .. [[" config core.hooksPath .githooks >nul 2>&1]])
		_ui_ok("Permissões ajustadas com sucesso [acesso restrito a '" .. current_user .. "'].")
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
	local candidates = collect_home_candidates(
		"SHELL_REPO_DIR",
		{ [[.local\share\shell]], [[.config\shell]], [[.shell]] },
		{ [[C:\Program Files\Shell]] }
	)
	local target_dir = resolve_candidate(candidates, is_git_repo)

	if target_dir then
		local is_status = flags:find("%-%-status") or flags:find("%-s")
		local is_dry = flags:find("%-%-dry%-run") or flags:find("%-n")
		if is_status then
			_ui_step("Status do Universal Shell em: " .. target_dir .. "...")
			os.execute([[git -C "]] .. target_dir .. [[" status -s -b]])
			return
		end
		if is_dry then
			_ui_step("[DRY-RUN] Atualização do Universal Shell em: " .. target_dir .. "...")
			_ui_sub([[git -C "]] .. target_dir .. [[" pull --ff-only]])
			return
		end
		_ui_step("Atualizando Universal Shell em: " .. target_dir .. "...")
		os.execute([[git -C "]] .. target_dir .. [[" pull --ff-only]])
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
		os.execute(get_pwsh_exe() .. [[ -NoProfile -Command "Start-Process choco -ArgumentList 'upgrade all -y' -Verb RunAs -Wait"]])
	end
	if not found then
		_ui_warn("Nenhum gerenciador de pacotes suportado (winget, scoop, choco) encontrado no sistema.")
		return
	end
	_ui_ok("Pacotes do sistema atualizados com sucesso!")
end

local function cmd_update_emacs_modes()
	local home_dir = get_home_dir()
	local appdata = os.getenv("APPDATA") or ""
	local emacs_dir = resolve_candidate({
		home_dir .. [[\.emacs.d]],
		appdata ~= "" and (appdata .. [[\.emacs.d]]) or nil,
		home_dir .. [[\.config\emacs]],
		MSYS_HOME and (MSYS_HOME .. [[\.emacs.d]]) or nil,
	}, function(dir_path)
		return is_dir(dir_path .. [[\.git]])
	end)
	if not emacs_dir then
		_ui_warn("Diretório do GNU Emacs não encontrado em ~/.emacs.d ou ~/.config/emacs.")
		return
	end
	_ui_step("Atualizando submódulos Elisp locais em " .. emacs_dir .. "...")
	os.execute([[git -C "]] .. emacs_dir .. [[" submodule update --init --recursive --remote --merge]])
	_ui_ok("Submódulos Elisp atualizados com sucesso!")
end

local function cmd_reinstall_shell()
	_ui_step("Recarregando ambiente do Clink...")
	if clink and clink.reload then
		clink.reload()
	end
	_ui_ok("Clink recarregado com sucesso!")
end

local function cmd_bench_shell()
	_ui_step("Medindo tempo de inicialização do Shell...")
	local start_clock = os.clock()
	os.execute([[cmd.exe /c exit]])
	local elapsed_ms = math.floor((os.clock() - start_clock) * 1000)
	_ui_ok("Latência de boot limpo: " .. tostring(elapsed_ms) .. " ms")
end

local function cmd_clean_cache()
	_ui_step("Limpando caches temporários do Shell...")
	local cache_file = get_win_cache_path()
	if cache_file and is_file(cache_file) then
		os.remove(cache_file)
	end
	_ui_ok("Cache do Universal Shell limpo com sucesso!")
end

local function cmd_update_wifi()
	_ui_step("Auditando interfaces e perfis de rede sem fio...")
	os.execute([[netsh wlan show interfaces]])
	_ui_ok("Status de WiFi verificado com sucesso!")
end

local function cmd_update_network()
	_ui_step("Auditando configurações e adaptadores de rede...")
	os.execute(get_pwsh_exe() .. [[ -NoProfile -Command "Get-NetAdapter | Format-Table -AutoSize"]])
	_ui_ok("Rede verificada com sucesso!")
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
	os.execute(get_pwsh_exe() .. [[ -NoProfile -Command "if (Get-Command choco -ErrorAction SilentlyContinue) { Start-Process choco -ArgumentList 'cache remove' -Verb RunAs -Wait }" >nul 2>nul]])
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

-- ================================
-- COMMAND DISPATCH
-- ================================

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
	["u"] = cmd_upall,
	["update-emacs-modes"] = cmd_update_emacs_modes,
	["upmodes"] = cmd_update_emacs_modes,
	["reinstall-shell"] = cmd_reinstall_shell,
	["resh"] = cmd_reinstall_shell,
	["bench-shell"] = cmd_bench_shell,
	["bsh"] = cmd_bench_shell,
	["shell-bench"] = cmd_bench_shell,
	["clean-cache"] = cmd_clean_cache,
	["ccache"] = cmd_clean_cache,
	["cleancache"] = cmd_clean_cache,
	["update-wifi"] = cmd_update_wifi,
	["upwf"] = cmd_update_wifi,
	["update-network"] = cmd_update_network,
	["upnet"] = cmd_update_network,
	["clean-system"] = cmd_clean_system,
	["clear-system"] = cmd_clean_system,
	["cleansys"] = cmd_clean_system,
	["clearsys"] = cmd_clean_system,
	["sysclean"] = cmd_clean_system,
	["syscls"] = cmd_clean_system,
}

local updater_parser = clink.arg.new_parser()
for cmd_name, _ in pairs(updater_commands) do
	clink.arg.register_parser(cmd_name, updater_parser)
end

local function filter_updater_cmd(text)
	local cmd_name, raw_args = text:match("^%s*(%S+)%s*(.*)")
	if cmd_name and updater_commands[cmd_name] then
		updater_commands[cmd_name](raw_args)
		return "", false
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
