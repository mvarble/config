return {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { "catppuccin/nvim" },
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

        -- Set header
        dashboard.section.header.val = {
            [[                                                                               ]],
            [[                                            ____-----__                        ]],
            [[                                        .--'           `\                      ]],
            [[                                      .'                 `.                    ]],
            [[                                    .'                     \                   ]],
            [[                      _______     .'                        `.                 ]],
            [[             ____,---'   ~~~<.---'                            \                ]],
            [[           _C~           `--'                                  \               ]],
            [[  __--x_x-'  .~      `---'                                      `              ]],
            [[ | /         \'                                                  |             ]],
            [[  \|                                                             |             ]],
            [[   \   \  ,                                             __       `,            ]],
            [[    `~~ ~~ --__                                       .'  \       |            ]],
            [[      `` \_                                          '     |      |            ]],
            [[           `-._                                     /       `    /             ]],
            [[               `-.___/--.              /           /         |  /              ]],
            [[                         `~~--__       \          /          | <               ]],
            [[                        __>     `,     >         |          /   \              ]],
            [[                    .--'         /   ,'`---.___ .'           /   `.            ]],
            [[                  .'    ___.---'/   /           |           /      `.___       ]],
            [[                .'   .~~    .--'   /             \_      __/ \          `.     ]],
            [[                |'/\|      /,   __,'               `----'     `.__        `,   ]],
            [[                \'         `/._/                   //.<          `---.."   |   ]],
            [[                            `'                     VV V        __..--'    .'   ]],
            [[                                                             .'         .'     ]],
            [[                                                           .'   .------'       ]],
            [[                                                           |  .'               ]],
            [[                                                   ______.'   |                ]],
            [[                                                 .'         .'                 ]],
            [[                                   __====_`-----'  .-------'                   ]],
            [[                                        ___-------'                            ]],
            [[                                       (   )                                   ]],
            [[                        ___ .-.   .---. | |_     .--.                          ]],
            [[                       (   )   \ / .-, (   __) /  _  \                         ]],
            [[                        | ' .-. (__) ; || |   . .' `. ;                        ]],
            [[                        |  / (___).'`  || | __| '   | |                        ]],
            [[                        | |      / .'| || |(  _\_`.(___)                       ]],
            [[                        | |     | /  | || | | (   ). '.                        ]],
            [[                        | |     ; |  ; || ' | || |  `\ |                       ]],
            [[                        | |     ' `-'  |' `-' ;; '._,' '                       ]],
            [[                       (___)    `.__.'_. `.__.  '.___.'                        ]],
        }
        dashboard.section.header.opts.hl = "Function"

        -- Set menu
        dashboard.section.buttons.val = {
            dashboard.button("e", "  > New file", "<cmd>ene<CR>"),
            dashboard.button("<leader>e", "  > Toggle file explorer", "<cmd>NvimTreeToggle<CR>"),
            dashboard.button("<leader>ff", "󰱼  > Find file", "<cmd>Telescope find_files<CR>"),
            dashboard.button("<leader>fs", "  > Find word", "<cmd>Telescope live_grep<CR>"),
            dashboard.button("<leader>fp", "  > Projects", "<cmd>Telescope projects<CR>"),
            dashboard.button("q", "  > Quit neovim", "<cmd>qa<CR>"),
        }

        -- Send config to alpha
        alpha.setup(dashboard.opts)

        -- Disable folding on alpha buffer
        vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
    end,
}
