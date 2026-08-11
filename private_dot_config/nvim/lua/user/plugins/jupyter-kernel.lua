return {
    "lkhphuc/jupyter-kernel.nvim",
    opts = {
        inspect = { window = { max_width = 84 } },
        timeout = 0.5,
    },
    cmd = { "JupyterAttach", "JupyterInspect", "JupyterExecute" },
}
