-- pysession.lua — one IPython session per file, launched in an environment you pick.
--
-- Discovery: venv-selector.nvim's searches (if installed; built-in search otherwise),
-- plus any pixi workspace enclosing the file, your `extra` launchers, and a fallback
-- (`default_env`, or the python3 your shell resolved). You always pick from a list.
--
-- Launchers:
--   venv  : <venv>/bin/python, with VIRTUAL_ENV/PATH set like `activate` would
--   pixi  : `pixi run --manifest-path <m> -e <env> python` (runs activation scripts,
--           which RoboStack/ROS2 environments need) — also used when venv-selector
--           hands us an interpreter inside .pixi/envs/
--   extra : anything you define, e.g. a shell that sources /opt/ros first
--
-- Every launcher is validated (`import IPython`) in the exact environment the REPL
-- will get, so a broken environment fails loudly at start instead of halfway through.

local M = {}

M.config = {
    -- Built-in discovery, used only when venv-selector isn't available:
    venv_dirs = { "~/.venvs", "~/.virtualenvs" }, -- each subdirectory is a venv
    project_venv_names = { ".venv", "venv" }, -- searched upward from the file
    pixi = true, -- look upward for pixi.toml / pyproject.toml with [tool.pixi]
    pixi_frozen = false, -- true: never re-solve/install the env at startup
    -- Fallback when nothing else applies: a venv dir or an interpreter path, e.g.
    -- '~/.local/share/python'. nil = whatever python3 your shell's PATH resolves to.
    default_env = nil,
    -- Use venv-selector.nvim (if installed) to discover environments and put its current
    -- choice first. Without it, the built-in search below is used instead.
    venv_selector = true,
    search_timeout_ms = 10000,
    extra = {}, -- { { label = 'ros humble', python = { 'bash', '-c', 'source /opt/ros/humble/setup.bash && exec python3 "$@"', '_' } } }
    ipython_args = { "--no-banner", "--no-confirm-exit" },
    split = "botright 15split",
    -- Variables removed from Neovim's environment before launching, so a sourced ROS
    -- or an activated venv in your shell can't leak into the session.
    -- (Network settings like ROS_DOMAIN_ID / RMW_IMPLEMENTATION are kept on purpose.)
    scrub_vars = {
        "^PYTHONPATH$",
        "^PYTHONHOME$",
        "^VIRTUAL_ENV",
        "^CONDA_PREFIX",
        "^CONDA_DEFAULT_ENV$",
        "^CONDA_SHLVL$",
        "^PIXI_PROJECT_",
        "^PIXI_ENVIRONMENT_",
        "^PIXI_IN_SHELL$",
        "^AMENT_PREFIX_PATH$",
        "^COLCON_PREFIX_PATH$",
        "^CMAKE_PREFIX_PATH$",
        "^ROS_DISTRO$",
        "^ROS_VERSION$",
        "^ROS_PYTHON_VERSION$",
        "^ROS_PACKAGE_PATH$",
    },
    -- Entries matching these are dropped from PATH and LD_LIBRARY_PATH.
    scrub_path_patterns = { "^/opt/ros/" },
    ready_timeout_ms = 120000, -- pixi may install the env on first run
    -- Runtime completion for nvim-cmp (add { name = 'pysession' } to your cmp sources).
    completion = true,
    completion_timeout_ms = 500, -- give up quietly if the session is busy/hung
    completion_max_items = 300,
}

local sessions = {} -- source bufnr -> { term, chan, launcher, ready, queue }
-- Neovim's environment as inherited from your shell, before plugins such as venv-selector
-- rewrite vim.env. With lazy.nvim, snapshot it in the spec's `init` (runs at startup):
--   init = function() vim.g.pysession_startup_env = vim.fn.environ() end
local startup_env = vim.g.pysession_startup_env or vim.fn.environ()
local state_file = vim.fn.stdpath("state") .. "/pysession.json"

-- ---------------------------------------------------------------- utilities

local function notify(msg, level)
    vim.notify("pysession: " .. msg, level or vim.log.levels.INFO)
end

local function read_json(path)
    local f = io.open(path, "r")
    if not f then
        return {}
    end
    local ok, t = pcall(vim.json.decode, f:read("*a"))
    f:close()
    return (ok and type(t) == "table") and t or {}
end

local function write_json(path, t)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local f = io.open(path, "w")
    if f then
        f:write(vim.json.encode(t))
        f:close()
    end
end

local function shorten(p)
    return vim.fn.fnamemodify(p, ":~")
end

local function list_concat(...)
    local out = {}
    for _, l in ipairs({ ... }) do
        vim.list_extend(out, l)
    end
    return out
end

-- Base environment: Neovim's env minus anything that could poison the session.
local function clean_env()
    local env = vim.fn.environ()
    local own_venv_bin = env.VIRTUAL_ENV and (env.VIRTUAL_ENV .. "/bin") or nil
    for k in pairs(env) do
        for _, pat in ipairs(M.config.scrub_vars) do
            if k:match(pat) then
                env[k] = nil
                break
            end
        end
    end
    for _, var in ipairs({ "PATH", "LD_LIBRARY_PATH" }) do
        if env[var] then
            local kept = {}
            for entry in env[var]:gmatch("[^:]+") do
                local drop = entry == own_venv_bin
                for _, pat in ipairs(M.config.scrub_path_patterns) do
                    drop = drop or entry:match(pat) ~= nil
                end
                if not drop then
                    table.insert(kept, entry)
                end
            end
            env[var] = #kept > 0 and table.concat(kept, ":") or nil
        end
    end
    return env
end

-- ---------------------------------------------------------------- discovery

local function venv_launcher(prefix, label)
    local py = prefix .. "/bin/python"
    if vim.fn.executable(py) ~= 1 then
        return nil
    end
    -- Do NOT resolve the symlink: <venv>/bin/python -> base python would lose the venv.
    return {
        id = "venv:" .. prefix,
        label = label,
        python = { py },
        env = function(env)
            env.VIRTUAL_ENV = prefix
            env.PATH = prefix .. "/bin" .. (env.PATH and (":" .. env.PATH) or "")
            return env
        end,
        install_hint = (vim.fn.executable("uv") == 1) and { "uv", "pip", "install", "--python", py, "ipython" }
            or { py, "-m", "pip", "install", "ipython" },
    }
end

local function find_pixi_manifest(dir)
    for _, d in ipairs(vim.list_extend({ dir }, vim.iter(vim.fs.parents(dir)):totable())) do
        local toml = d .. "/pixi.toml"
        if vim.uv.fs_stat(toml) then
            return toml
        end
        local pyproj = d .. "/pyproject.toml"
        if vim.uv.fs_stat(pyproj) then
            local f = io.open(pyproj, "r")
            if f then
                local txt = f:read("*a")
                f:close()
                if txt:find("%[tool%.pixi") then
                    return pyproj
                end
            end
        end
    end
end

local function pixi_launchers(file_dir)
    if not M.config.pixi or vim.fn.executable("pixi") ~= 1 then
        return {}
    end
    local manifest = find_pixi_manifest(file_dir)
    if not manifest then
        return {}
    end
    local res = vim.system({ "pixi", "info", "--json", "--manifest-path", manifest }, { text = true }):wait()
    if res.code ~= 0 then
        notify("`pixi info` failed for " .. shorten(manifest) .. ":\n" .. (res.stderr or ""), vim.log.levels.WARN)
        return {}
    end
    local ok, info = pcall(vim.json.decode, res.stdout)
    if not ok then
        return {}
    end
    local out = {}
    for _, e in ipairs(info.environments_info or {}) do
        table.insert(out, M._pixi_launcher(manifest, e.name))
    end
    return out
end

function M._pixi_launcher(manifest, env_name)
    local run = { "pixi", "run", "--manifest-path", manifest, "-e", env_name }
    if M.config.pixi_frozen then
        table.insert(run, "--frozen")
    end
    return {
        id = "pixi:" .. manifest .. "#" .. env_name,
        label = ("[pixi] %s:%s"):format(vim.fs.basename(vim.fs.dirname(manifest)), env_name),
        python = list_concat(run, { "python" }),
        env = function(env)
            return env
        end,
        install_hint = nil, -- adding deps edits pixi.toml: your call, not the plugin's
        pixi_hint = ("pixi add --manifest-path %s%s ipython"):format(
            shorten(manifest),
            env_name == "default" and "" or (" --feature <feature-of-" .. env_name .. ">")
        ),
    }
end

-- Turn an interpreter path (e.g. from venv-selector) into the right launcher.
local function launcher_from_python(py)
    py = vim.fs.normalize(py)
    if vim.fn.executable(py) ~= 1 then
        return nil
    end
    -- Interpreter inside a pixi workspace: go through `pixi run` so activation runs.
    local root, env_name = py:match("^(.*)/%.pixi/envs/([^/]+)/bin/python[%d.]*$")
    if root and vim.fn.executable("pixi") == 1 then
        local manifest = find_pixi_manifest(root)
        if manifest then
            return M._pixi_launcher(manifest, env_name)
        end
    end
    local prefix = vim.fs.dirname(vim.fs.dirname(py))
    if vim.uv.fs_stat(prefix .. "/pyvenv.cfg") then
        return venv_launcher(prefix, "[venv] " .. shorten(prefix))
    end
    -- Anything else (conda env, system python): run it directly, no activation scripts.
    return {
        id = "python:" .. py,
        label = "[python] " .. shorten(py),
        python = { py },
        env = function(env)
            env.PATH = vim.fs.dirname(py) .. (env.PATH and (":" .. env.PATH) or "")
            return env
        end,
    }
end

-- The fallback launcher: `default_env` if configured, otherwise the python3 your
-- shell's PATH resolved to when Neovim started (e.g. a venv overlaid on every shell).
function M._fallback_launcher()
    local l, kind
    local target = M.config.default_env
    if target then
        target = vim.fs.normalize(target)
        local py = vim.fn.isdirectory(target) == 1 and (target .. "/bin/python") or target
        l, kind = launcher_from_python(py), "[default]"
        if not l then
            notify("default_env is not a usable venv or interpreter: " .. target, vim.log.levels.WARN)
        end
    end
    if not l then
        for dir in (startup_env.PATH or ""):gmatch("[^:]+") do
            local skip = false
            for _, pat in ipairs(M.config.scrub_path_patterns) do
                skip = skip or dir:match(pat) ~= nil
            end
            local p = dir .. "/python3"
            if not skip and vim.fn.executable(p) == 1 and vim.fn.isdirectory(p) == 0 then
                l, kind = launcher_from_python(p), "[shell]"
                break
            end
        end
    end
    if l then
        l.label = (l.label:gsub("^%[[^%]]+%]", kind))
        l.fallback = true
    end
    return l
end

-- What venv-selector has selected for this buffer (falls back to its global choice).
local function venv_selector_python(src)
    local ok, vs = pcall(require, "venv-selector")
    if not ok then
        return nil
    end
    local per_buf = vim.api.nvim_buf_is_valid(src) and vim.b[src].venv_selector_last_python or nil
    local ok2, global = pcall(vs.python)
    return per_buf or (ok2 and global) or nil
end

-- Ask venv-selector to run its searches and hand us the results (no UI).
-- Uses its documented SearchCallbacks contract: { on_result = fn, on_complete = fn }.
local function venv_selector_search(src, cb)
    local ok, search = pcall(require, "venv-selector.search")
    if not ok or type(search.run_search) ~= "function" then
        return cb(nil)
    end
    local results, done = {}, false
    local function finish()
        if done then
            return
        end
        done = true
        cb(results)
    end
    local ok2, err = pcall(search.run_search, {
        on_result = function(r)
            table.insert(results, r)
        end,
        on_complete = function()
            vim.schedule(finish)
        end,
    }, { bufnr = src })
    if not ok2 then
        notify("venv-selector search failed: " .. tostring(err), vim.log.levels.WARN)
        return cb(nil)
    end
    -- If no search job starts (e.g. fd missing), on_complete never fires.
    vim.defer_fn(function()
        if not done then
            notify("venv-selector search timed out; showing what was found", vim.log.levels.WARN)
            finish()
        end
    end, M.config.search_timeout_ms)
end

local function builtin_venvs(dir, add)
    for _, name in ipairs(M.config.project_venv_names) do
        local found = vim.fs.find(name, { upward = true, path = dir, type = "directory" })[1]
        if found then
            add(venv_launcher(found, "[venv] " .. shorten(found)))
        end
    end
    for _, root in ipairs(M.config.venv_dirs) do
        root = vim.fs.normalize(root)
        if vim.fn.isdirectory(root) == 1 then
            for name, t in vim.fs.dir(root) do
                if t == "directory" or t == "link" then
                    add(venv_launcher(root .. "/" .. name, "[venv] " .. name))
                end
            end
        end
    end
end

-- Collects launchers asynchronously and calls cb(list).
local function candidates(file, src, cb)
    local dir = vim.fs.dirname(file)
    local out, seen = {}, {}
    local function add(l)
        if l and not seen[l.id] then
            seen[l.id] = true
            table.insert(out, l)
        end
    end

    -- Pixi workspaces enclosing the file: always checked (cheap, and activation-critical).
    for _, l in ipairs(pixi_launchers(dir)) do
        add(l)
    end

    local function finalize(vs_results)
        if vs_results then
            for _, r in ipairs(vs_results) do
                local l = launcher_from_python(r.path)
                if l and l.id:match("^python:") and r.type and r.type ~= "venv" then
                    l.label = ("[%s] %s"):format(r.type, shorten(r.path)) -- e.g. [anaconda] ...
                end
                add(l)
            end
        else
            builtin_venvs(dir, add)
        end
        for i, x in ipairs(M.config.extra) do
            add({
                id = "extra:" .. (x.label or i),
                label = "[custom] " .. (x.label or ("#" .. i)),
                python = x.python,
                env = x.env or function(env)
                    return env
                end,
            })
        end
        add(M._fallback_launcher()) -- always last

        local function promote(id, tag)
            for i, l in ipairs(out) do
                if l.id == id then
                    table.remove(out, i)
                    l.base_label = l.base_label or l.label
                    l.label = l.label .. "  (" .. tag .. ")"
                    table.insert(out, 1, l)
                    return true
                end
            end
        end
        -- Order: venv-selector's current choice, then this file's last-used, then the rest.
        local last = read_json(state_file)[file]
        if last then
            promote(last, "last used")
        end
        local vs_py = M.config.venv_selector and venv_selector_python(src)
        if vs_py then
            local l = launcher_from_python(vs_py)
            if l and not promote(l.id, "venv-selector") then
                l.base_label = l.label
                l.label = l.label .. "  (venv-selector)"
                table.insert(out, 1, l)
            end
        end
        cb(out)
    end

    if M.config.venv_selector then
        venv_selector_search(src, finalize)
    else
        finalize(nil)
    end
end

-- ---------------------------------------------------------------- completion bridge

-- Python side, loaded via PYTHONSTARTUP inside each session's IPython. It serves
-- completions from IPython's own completer (Jedi off: namespace lookups, dict keys,
-- DataFrame columns, attributes; no code execution) on a private Unix socket.
local BRIDGE_PY = [==[
# Written by pysession.nvim; loaded through PYTHONSTARTUP in its IPython sessions.
def _pysession_bridge():
    import os
    path = os.environ.pop("PYSESSION_SOCKET", None)
    prev = os.environ.pop("PYSESSION_PREV_STARTUP", None)
    # Don't leak into child interpreters; hand PYTHONSTARTUP back to the user's file.
    if prev:
        os.environ["PYTHONSTARTUP"] = prev
    else:
        os.environ.pop("PYTHONSTARTUP", None)
    try:
        from IPython import get_ipython
        ip = get_ipython()
    except Exception:
        return
    if ip is None:
        return
    if prev and os.path.isfile(prev):
        with open(prev) as f:
            exec(compile(f.read(), prev, "exec"), ip.user_ns)
    if not path:
        return

    import atexit, json, socket, threading
    from IPython.core.completer import IPCompleter, provisionalcompleter

    comp = IPCompleter(shell=ip, namespace=ip.user_ns,
                       global_namespace=ip.user_global_ns, parent=ip)
    comp.use_jedi = False

    def bpos(s, i):
        return len(s[:i].encode("utf-8"))

    def handle(req):
        if req.get("op") == "complete":
            line = req["line"]
            with provisionalcompleter():
                cs = list(comp.completions(line, len(line)))
            n = int(req.get("limit", 300))
            return {"items": [
                {"text": c.text, "start": bpos(line, c.start), "end": bpos(line, c.end),
                 "type": c.type or "", "signature": c.signature or ""}
                for c in cs[:n]]}
        return {"ok": True}

    try:
        os.unlink(path)
    except OSError:
        pass
    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(path)
    os.chmod(path, 0o600)
    srv.listen(8)

    def serve():
        while True:
            try:
                conn, _ = srv.accept()
            except OSError:
                return
            try:
                with conn, conn.makefile("rwb") as f:
                    for raw in f:
                        try:
                            resp = handle(json.loads(raw))
                        except Exception as e:  # e.g. dict changed size mid-run
                            resp = {"error": repr(e)}
                        f.write(json.dumps(resp).encode() + b"\n")
                        f.flush()
            except Exception:
                pass

    threading.Thread(target=serve, name="pysession-bridge", daemon=True).start()

    def cleanup():
        srv.close()
        try:
            os.unlink(path)
        except OSError:
            pass

    atexit.register(cleanup)


_pysession_bridge()
del _pysession_bridge
]==]

local bridge_path
local function ensure_bridge_file()
    if bridge_path then
        return bridge_path
    end
    local dir = vim.fn.stdpath("cache") .. "/pysession"
    vim.fn.mkdir(dir, "p")
    bridge_path = dir .. "/bridge.py"
    local f = io.open(bridge_path, "r")
    local current = f and f:read("*a")
    if f then
        f:close()
    end
    if current ~= BRIDGE_PY then
        f = assert(io.open(bridge_path, "w"))
        f:write(BRIDGE_PY)
        f:close()
    end
    return bridge_path
end

-- One request per connection: connect, send a JSON line, read a JSON line, close.
local function bridge_request(s, req, cb)
    if not (s and s.socket) then
        return cb(nil)
    end
    local pipe = vim.uv.new_pipe(false)
    local buf, finished, timer = "", false, nil
    local function done(line)
        if finished then
            return
        end
        finished = true
        if timer then
            timer:stop()
            timer:close()
        end
        if not pipe:is_closing() then
            pipe:close()
        end
        vim.schedule(function()
            local ok, res = pcall(vim.json.decode, line or "")
            cb((ok and type(res) == "table" and not res.error) and res or nil)
        end)
    end
    timer = vim.uv.new_timer()
    timer:start(M.config.completion_timeout_ms, 0, function()
        done(nil)
    end)
    pipe:connect(s.socket, function(err)
        if err then
            return done(nil)
        end
        pipe:read_start(function(rerr, chunk)
            if rerr or not chunk then
                return done(nil)
            end
            buf = buf .. chunk
            local nl = buf:find("\n", 1, true)
            if nl then
                done(buf:sub(1, nl - 1))
            end
        end)
        pipe:write(vim.json.encode(req) .. "\n")
    end)
end

local KIND = {
    ["function"] = "Function",
    instance = "Variable",
    variable = "Variable",
    statement = "Variable",
    param = "Variable",
    module = "Module",
    class = "Class",
    keyword = "Keyword",
    magic = "Keyword",
    path = "File",
    ["dict key"] = "Field",
    attribute = "Property",
    property = "Property",
}

-- nvim-cmp source: completions from the session attached to the current buffer.
function M.cmp_source()
    local source = {}

    function source:get_debug_name()
        return "pysession"
    end

    function source:get_position_encoding_kind()
        return "utf-8"
    end

    function source:get_trigger_characters()
        return { ".", "[", '"', "'" }
    end

    function source:is_available()
        local s = sessions[vim.api.nvim_get_current_buf()]
        return s ~= nil and s.ready and s.socket ~= nil
    end

    function source:complete(params, callback)
        local ctx = params.context
        local s = sessions[ctx.bufnr]
        local req = { op = "complete", line = ctx.cursor_before_line, limit = M.config.completion_max_items }
        bridge_request(s, req, function(res)
            if not (res and res.items) then
                return callback()
            end
            local Kind = require("cmp").lsp.CompletionItemKind
            local row = ctx.cursor.line
            local items = {}
            for _, c in ipairs(res.items) do
                table.insert(items, {
                    label = (c.text:gsub("^%.", "")), -- attributes arrive as '.name'
                    filterText = c.text,
                    kind = Kind[KIND[c.type] or "Variable"],
                    detail = (c.signature ~= "" and c.signature) or c.type,
                    textEdit = {
                        newText = c.text,
                        range = {
                            start = { line = row, character = c.start },
                            ["end"] = { line = row, character = c["end"] },
                        },
                    },
                })
            end
            callback({ items = items, isIncomplete = false })
        end)
    end

    return source
end

-- ---------------------------------------------------------------- sessions

local function source_buf()
    return vim.b.pysession_src or vim.api.nvim_get_current_buf()
end

local function open_window(term)
    vim.cmd(M.config.split)
    vim.api.nvim_win_set_buf(0, term)
end

local function scroll_to_end(s)
    local win = vim.fn.bufwinid(s.term)
    if win ~= -1 then
        vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(s.term), 0 })
    end
end

local function raw_send(s, text)
    -- Bracketed paste: IPython takes the block verbatim (no auto-indent mangling).
    vim.api.nvim_chan_send(s.chan, "\27[200~" .. text .. "\27[201~")
    -- An indented last line leaves IPython waiting for another Enter.
    local last = text:match("([^\n]*)\n*$") or ""
    vim.api.nvim_chan_send(s.chan, last:match("^%s") and "\r\r" or "\r")
    scroll_to_end(s)
end

local function wait_ready(s, src)
    local deadline = vim.uv.now() + M.config.ready_timeout_ms
    local function poll()
        if sessions[src] ~= s then
            return
        end
        local lines = vim.api.nvim_buf_get_lines(s.term, 0, -1, false)
        for i = #lines, 1, -1 do
            if lines[i]:match("^In %[%d+%]:") then
                s.ready = true
                for _, text in ipairs(s.queue) do
                    raw_send(s, text)
                end
                s.queue = {}
                return
            end
        end
        if vim.uv.now() > deadline then
            notify("IPython prompt never appeared; check the REPL window", vim.log.levels.ERROR)
            return
        end
        vim.defer_fn(poll, 50)
    end
    poll()
end

local function launch(src, launcher, opts)
    opts = opts or {}
    local file = vim.api.nvim_buf_get_name(src)
    local env = launcher.env(clean_env())
    local cwd = vim.fs.dirname(file)

    local origin = vim.api.nvim_get_current_win()
    local term = vim.api.nvim_create_buf(false, false)
    open_window(term)
    local cmd = list_concat(launcher.python, { "-m", "IPython" }, M.config.ipython_args)
    local s = { term = term, launcher = launcher, ready = false, queue = opts.queue or {} }
    if M.config.completion then
        s.socket = vim.fn.tempname() .. ".sock" -- inside Neovim's private (0700) temp dir
        env.PYSESSION_SOCKET = s.socket
        env.PYSESSION_PREV_STARTUP = env.PYTHONSTARTUP
        env.PYTHONSTARTUP = ensure_bridge_file()
    end
    local jobopts = {
        cwd = cwd,
        env = env,
        clear_env = true,
        on_exit = function()
            if sessions[src] == s then
                sessions[src] = nil
            end
        end,
    }
    if vim.fn.has("nvim-0.11") == 1 then
        jobopts.term = true
        s.chan = vim.fn.jobstart(cmd, jobopts)
    else
        s.chan = vim.fn.termopen(cmd, jobopts)
    end
    vim.bo[term].bufhidden = "hide"
    vim.b[term].pysession_src = src
    pcall(
        vim.api.nvim_buf_set_name,
        term,
        ("ipython://%s [%s]"):format(vim.fn.fnamemodify(file, ":t"), launcher.base_label or launcher.label)
    )
    sessions[src] = s

    local mem = read_json(state_file)
    mem[file] = launcher.id
    write_json(state_file, mem)

    if opts.focus then
        vim.cmd.startinsert()
    else
        vim.api.nvim_set_current_win(origin)
    end
    wait_ready(s, src)
end

-- Validate in the exact environment the REPL will get, then launch.
local function validate_and_launch(src, launcher, opts)
    local cmd = list_concat(launcher.python, { "-c", "import sys, IPython; print(sys.executable)" })
    notify("checking " .. launcher.label .. " …")
    vim.system(
        cmd,
        {
            text = true,
            env = launcher.env(clean_env()),
            clear_env = true,
            cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(src)),
        },
        vim.schedule_wrap(function(res)
            if res.code == 0 then
                return launch(src, launcher, opts)
            end
            local err = vim.trim(res.stderr or "")
            local missing_ipython = err:find("No module named 'IPython'", 1, true)
            if missing_ipython and launcher.install_hint then
                local ans = vim.fn.confirm(
                    ("IPython is missing in %s. Run:\n  %s"):format(
                        launcher.label,
                        table.concat(launcher.install_hint, " ")
                    ),
                    "&Install\n&Cancel",
                    2
                )
                if ans == 1 then
                    local r = vim.system(launcher.install_hint, { text = true }):wait()
                    if r.code ~= 0 then
                        return notify("install failed:\n" .. (r.stderr or ""), vim.log.levels.ERROR)
                    end
                    return validate_and_launch(src, launcher, opts)
                end
                return
            end
            if missing_ipython and launcher.pixi_hint then
                return notify(
                    "IPython is missing in " .. launcher.label .. ". Add it with:\n  " .. launcher.pixi_hint,
                    vim.log.levels.ERROR
                )
            end
            if missing_ipython then
                -- Not a venv we can install into: pip into a distro Python is blocked by PEP 668.
                return notify(
                    (
                        "%s has no IPython. Install it into that interpreter (for a distro Python, "
                        .. "its package: python3-ipython / ipython), or point `default_env` at a venv that has it."
                    ):format(launcher.label),
                    vim.log.levels.ERROR
                )
            end
            notify(("environment check failed for %s:\n%s"):format(launcher.label, err), vim.log.levels.ERROR)
        end)
    )
end

local function pick_and_launch(src, opts)
    local file = vim.api.nvim_buf_get_name(src)
    if file == "" then
        return notify("save the buffer to a file first", vim.log.levels.WARN)
    end
    candidates(file, src, function(cands)
        if #cands == 0 then
            return notify("no Python environment or interpreter found", vim.log.levels.ERROR)
        end
        vim.ui.select(cands, {
            prompt = "Python environment for " .. vim.fn.fnamemodify(file, ":t"),
            format_item = function(l)
                return l.label
            end,
        }, function(choice)
            if choice then
                validate_and_launch(src, choice, opts)
            end
        end)
    end)
end

-- ---------------------------------------------------------------- public API

function M.start(opts)
    local src = source_buf()
    if sessions[src] then
        return notify("session already running (use :PySession pick to switch)")
    end
    pick_and_launch(src, vim.tbl_extend("force", { focus = true }, opts or {}))
end

function M.toggle()
    local src = source_buf()
    local s = sessions[src]
    if not s then
        return M.start()
    end
    local win = vim.fn.bufwinid(s.term)
    if win ~= -1 then
        if #vim.api.nvim_tabpage_list_wins(0) > 1 then
            vim.api.nvim_win_hide(win)
        end
    else
        open_window(s.term)
        vim.cmd.startinsert()
    end
end

function M.kill(src)
    src = src or source_buf()
    local s = sessions[src]
    if not s then
        return
    end
    sessions[src] = nil
    pcall(vim.fn.jobstop, s.chan)
    pcall(vim.api.nvim_buf_delete, s.term, { force = true })
    if s.socket then
        os.remove(s.socket)
    end
end

function M.restart()
    local src = source_buf()
    local s = sessions[src]
    if not s then
        return M.start()
    end
    local launcher = s.launcher
    M.kill(src)
    validate_and_launch(src, launcher, { focus = false })
end

function M.pick()
    local src = source_buf()
    M.kill(src)
    pick_and_launch(src, { focus = false })
end

function M.send(text, src)
    src = src or source_buf()
    local s = sessions[src]
    if not s then
        -- No session yet: pick an environment, then run the text once IPython is up.
        return pick_and_launch(src, { focus = false, queue = { text } })
    end
    if s.ready then
        raw_send(s, text)
    else
        table.insert(s.queue, text)
    end
end

-- Remove the indentation shared by all non-blank lines, so code lifted out of a
-- function/loop body runs at top level. Relative indentation is preserved.
local function dedent(lines)
    local min
    for _, l in ipairs(lines) do
        if l:match("%S") then
            local n = #l:match("^%s*")
            min = (min == nil or n < min) and n or min
        end
    end
    return vim.tbl_map(function(l)
        return l:match("%S") and l:sub((min or 0) + 1) or ""
    end, lines)
end

function M.send_line()
    M.send(vim.trim(vim.api.nvim_get_current_line()))
end

function M.send_visual()
    local mode = vim.fn.mode()
    local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    if mode == "v" and #lines > 1 then
        -- Charwise: the first line usually starts mid-line, so it carries no indent
        -- information. Strip it on its own and dedent the rest as a block.
        local rest = dedent(vim.list_slice(lines, 2))
        lines = { vim.trim(lines[1]), unpack(rest) }
    else
        lines = dedent(lines)
    end
    M.send(table.concat(lines, "\n"))
end

-- Lines between `# %%` markers around the cursor.
function M.send_cell()
    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local is_marker = function(l)
        return l:match("^#%s*%%%%") ~= nil
    end
    local first, last = 1, #lines
    for i = row, 1, -1 do
        if is_marker(lines[i]) then
            first = i + 1
            break
        end
    end
    for i = row + 1, #lines do
        if is_marker(lines[i]) then
            last = i - 1
            break
        end
    end
    local cell = vim.list_slice(lines, first, last)
    while #cell > 0 and cell[#cell]:match("^%s*$") do
        table.remove(cell)
    end
    cell = dedent(cell)
    if #cell > 0 then
        M.send(table.concat(cell, "\n"))
    end
    -- Jump to the next cell, notebook-style.
    if last + 2 <= #lines then
        vim.api.nvim_win_set_cursor(0, { last + 2, 0 })
    end
end

-- Run the saved file in the session's namespace (variables persist both ways).
function M.run_file()
    local src = source_buf()
    vim.api.nvim_buf_call(src, function()
        vim.cmd("silent update")
    end)
    local file = vim.api.nvim_buf_get_name(src)
    M.send(('%%run -i "%s"'):format(file), src)
end

-- For your statusline: which environment this file's session runs in.
function M.status()
    local s = sessions[source_buf()]
    return s and (s.launcher.base_label or s.launcher.label) or ""
end

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})

    if M.config.completion then
        local ok, cmp = pcall(require, "cmp")
        if ok then
            cmp.register_source("pysession", M.cmp_source())
        end
    end

    local subcommands = {
        start = M.start,
        toggle = M.toggle,
        pick = M.pick,
        restart = M.restart,
        kill = function()
            M.kill()
        end,
        run = M.run_file,
        info = function()
            notify(M.status() ~= "" and M.status() or "no session for this buffer")
        end,
    }
    vim.api.nvim_create_user_command("PySession", function(a)
        (subcommands[a.args ~= "" and a.args or "toggle"] or subcommands.info)()
    end, {
        nargs = "?",
        complete = function()
            return vim.tbl_keys(subcommands)
        end,
    })

    vim.api.nvim_create_autocmd("BufDelete", {
        group = vim.api.nvim_create_augroup("pysession", { clear = true }),
        callback = function(a)
            if sessions[a.buf] then
                M.kill(a.buf)
            end
        end,
    })
end

M._sessions = sessions -- for tests / debugging
M._bridge_request = bridge_request
return M
