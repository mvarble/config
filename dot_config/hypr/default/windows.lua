local config = require("./common/config.lua")
local workspaces = config.workspaces

for i = 1, workspaces do
    hl.workspace_rule({ workspace = tostring(i), persistent = i == 1, default = i == 1 })
end
