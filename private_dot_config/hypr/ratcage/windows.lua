local config = require("./common/config.lua")
local workspaces = config.workspaces
local monitors = require("./ratcage/monitors.lua")

for i = 1, workspaces do
    hl.workspace_rule({ workspace = tostring(i), persistent = i == 1, monitor = monitors.main, default = i == 1 })
end
hl.workspace_rule({ workspace = "10", persistent = true, monitor = monitors.alt, default = false })
