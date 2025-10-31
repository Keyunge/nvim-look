vim.wo.number = true
vim.o.relativenumber = true
vim.o.clipboard = 'unnamedplus'
vim.o.wrap = true
vim.o.autoindent = false
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4


vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.keymap.set('n', '<leader>ff', ':Telescope find_files<CR>', opts)
vim.keymap.set('n', '<C-s>', '<cmd> w <CR>', opts)
vim.keymap.set('n', '<leader>to', ':tabnew<CR>', opts) -- open new tab
vim.keymap.set('n', '<leader>tx', ':tabclose<CR>', opts) -- close current tab
vim.keymap.set('n', '<leader>tn', ':tabn<CR>', opts) --  go to next tab
vim.keymap.set('n', '<leader>tp', ':tabp<CR>', opts) --  go to previous tab


local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
    if vim.v.shell_error ~= 0 then
        error('Error cloning lazy.nvim:\n' .. out)
    end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
    { "ellisonleao/gruvbox.nvim", priority = 1000, config = true, opts = ... },
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons", -- optional, but recommended
        },
        lazy = false,                      -- neo-tree will lazily load itself
    },
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' }
    },
    {'neovim/nvim-lspconfig',
    dependencies = {
        { 'mason-org/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
        'mason-org/mason-lspconfig.nvim',
        'WhoIsSethDaniel/mason-tool-installer.nvim',

        -- Useful status updates for LSP.
        {
            'j-hui/fidget.nvim',
            opts = {
                notification = {
                    window = {
                        winblend = 0, -- Background color opacity in the notification window
                    },
                },
            },
        },
        'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
        vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
            callback = function(event)
                local map = function(keys, func, desc, mode)
                    mode = mode or 'n'
                    vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
                end

                map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

                map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

                map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

                map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

                map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

                map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

                map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

                map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

                map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

                local client = vim.lsp.get_client_by_id(event.data.client_id)
                if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
                    local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
                    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                        buffer = event.buf,
                        group = highlight_augroup,
                        callback = vim.lsp.buf.document_highlight,
                    })

                    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                        buffer = event.buf,
                        group = highlight_augroup,
                        callback = vim.lsp.buf.clear_references,
                    })

                    vim.api.nvim_create_autocmd('LspDetach', {
                        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
                        callback = function(event2)
                            vim.lsp.buf.clear_references()
                            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
                        end,
                    })
                end

                if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
                    map('<leader>th', function()
                        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
                    end, '[T]oggle Inlay [H]ints')
                end
            end,
        })

        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

        local servers = {
            ts_ls = {},
            ruff = {},
            pylsp = {
                settings = {
                    pylsp = {
                        plugins = {
                            pyflakes = { enabled = false },
                            pycodestyle = { enabled = false },
                            autopep8 = { enabled = false },
                            yapf = { enabled = false },
                            mccabe = { enabled = false },
                            pylsp_mypy = { enabled = false },
                            pylsp_black = { enabled = false },
                            pylsp_isort = { enabled = false },
                        },
                    },
                },
            },
            html = { filetypes = { 'html', 'twig', 'hbs' } },
            cssls = {},
            tailwindcss = {},
            dockerls = {},
            sqlls = {},
            terraformls = {},
            jsonls = {},
            yamlls = {},
            lua_ls = {
                settings = {
                    Lua = {
                        completion = {
                            callSnippet = 'Replace',
                        },
                        runtime = { version = 'LuaJIT' },
                        workspace = {
                            checkThirdParty = false,
                            library = vim.api.nvim_get_runtime_file('', true),
                        },
                        diagnostics = {
                            globals = { 'vim' },
                            disable = { 'missing-fields' },
                        },
                        format = {
                            enable = false,
                        },
                    },
                },
            },
        }

        local ensure_installed = vim.tbl_keys(servers or {})
        vim.list_extend(ensure_installed, {
            'stylua', -- Used to format Lua code
        })
        require('mason-tool-installer').setup { ensure_installed = ensure_installed }

        for server, cfg in pairs(servers) do
            cfg.capabilities = vim.tbl_deep_extend('force', {}, capabilities, cfg.capabilities or {})

            vim.lsp.config(server, cfg)
            vim.lsp.enable(server)
        end
    end,
		},
    {
        'nvim-telescope/telescope.nvim',
        event = 'VimEnter',
        -- branch = '0.1.x',
        branch = 'master',
        dependencies = {
            'nvim-lua/plenary.nvim',
            { -- If encountering errors, see telescope-fzf-native README for installation instructions
                'nvim-telescope/telescope-fzf-native.nvim',

                -- `build` is used to run some command when the plugin is installed/updated.
                -- This is only run then, not every time Neovim starts up.
                build = 'make',

                -- `cond` is a condition used to determine whether this plugin should be
                -- installed and loaded.
                cond = function()
                    return vim.fn.executable 'make' == 1
                end,
            },
            { 'nvim-telescope/telescope-ui-select.nvim' },

            -- Useful for getting pretty icons, but requires a Nerd Font.
            { 'nvim-tree/nvim-web-devicons',            enabled = vim.g.have_nerd_font },
        },
        config = function()
            -- Telescope is a fuzzy finder that comes with a lot of different things that
            -- it can fuzzy find! It's more than just a "file finder", it can search
            -- many different aspects of Neovim, your workspace, LSP, and more!
            --
            -- The easiest way to use Telescope, is to start by doing something like:
            --  :Telescope help_tags
            --
            -- After running this command, a window will open up and you're able to
            -- type in the prompt window. You'll see a list of `help_tags` options and
            -- a corresponding preview of the help.
            --
            -- Two important keymaps to use while in Telescope are:
            --  - Insert mode: <c-/>
            --  - Normal mode: ?
            --
            -- This opens a window that shows you all of the keymaps for the current
            -- Telescope picker. This is really useful to discover what Telescope can
            -- do as well as how to actually do it!

            -- [[ Configure Telescope ]]
            -- See `:help telescope` and `:help telescope.setup()`
            require('telescope').setup {
                -- You can put your default mappings / updates / etc. in here
                --  All the info you're looking for is in `:help telescope.setup()`
                defaults = {
                    mappings = {
                        i = {
                            ['<C-k>'] = require('telescope.actions').move_selection_previous, -- move to prev result
                            ['<C-j>'] = require('telescope.actions').move_selection_next,     -- move to next result
                            ['<C-l>'] = require('telescope.actions').select_default,          -- open file
                        },
                    },
                },
                pickers = {
                    find_files = {
                        file_ignore_patterns = { 'node_modules', '%.git', '%.venv' },
                        hidden = true,
                    },
                    live_grep = {
                        file_ignore_patterns = { 'node_modules', '%.git', '%.venv' },
                        additional_args = function(_)
                            return { '--hidden' }
                        end,
                    },
                },
                extensions = {
                    ['ui-select'] = {
                        require('telescope.themes').get_dropdown(),
                    },
                },
            }

            -- Enable Telescope extensions if they are installed
            pcall(require('telescope').load_extension, 'fzf')
            pcall(require('telescope').load_extension, 'ui-select')

            -- See `:help telescope.builtin`
            local builtin = require 'telescope.builtin'
            vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
            vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
            vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
            vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
            vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
            vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
            vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
            vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
            vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
            vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

            -- Slightly advanced example of overriding default behavior and theme
            vim.keymap.set('n', '<leader>/', function()
                -- You can pass additional configuration to Telescope to change the theme, layout, etc.
                builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, { desc = '[/] Fuzzily search in current buffer' })

            -- It's also possible to pass additional configuration options.
            --  See `:help telescope.builtin.live_grep()` for information about particular keys
            vim.keymap.set('n', '<leader>s/', function()
                builtin.live_grep {
                    grep_open_files = true,
                    prompt_title = 'Live Grep in Open Files',
                }
            end, { desc = '[S]earch [/] in Open Files' })
        end,
    },
    {'goolord/alpha-nvim',
     config = function()
	     require'alpha'.setup(require'alpha.themes.dashboard'.config)
     end
    },
    {'akinsho/bufferline.nvim', version = "*", dependencies = 'nvim-tree/nvim-web-devicons'},
    {
        "kdheepak/lazygit.nvim",
        lazy = true,
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        -- optional for floating window border decoration
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        -- setting the keybinding for LazyGit with 'keys' is recommended in
        -- order to load the plugin when the command is run for the first time
        keys = {
            { "<leader>g", "<cmd>LazyGit<cr>", desc = "LazyGit" }
        }
    },
{
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    -- add any options here
  },
  dependencies = {
    -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
    "MunifTanjim/nui.nvim",
    -- OPTIONAL:
    --   `nvim-notify` is only needed, if you want to use the notification view.
    --   If not available, we use `mini` as the fallback
    "rcarriga/nvim-notify",
},
},
{
  "sphamba/smear-cursor.nvim",
  opts = {
    smear_between_buffers = true,
    smear_between_neighbor_lines = true,
    scroll_buffer_space = true,
    legacy_computing_symbols_support = false,
    smear_insert_mode = true,
  },
},
		{ 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },
})

require("gruvbox").setup({
    terminal_colors = true, -- add neovim terminal colors
    undercurl = true,
    underline = true,
    bold = true,
    italic = {
        strings = true,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
    },
    strikethrough = true,
    invert_selection = false,
    invert_signs = false,
    invert_tabline = false,
    inverse = true, -- invert background for search, diffs, statuslines and errors
    contrast = "",  -- can be "hard", "soft" or empty string
    palette_overrides = {},
    overrides = {},
    dim_inactive = false,
    transparent_mode = true,
})
vim.cmd("colorscheme gruvbox")

local colors = {
    blue   = '#80a0ff',
    cyan   = '#79dac8',
    black  = '#080808',
    white  = '#C19C00',
    red    = '#ff5189',
    violet = '#d183e8',
    grey   = '#303030',
}

local bubbles_theme = {
    normal = {
        a = { fg = colors.black, bg = colors.blue },
        b = { fg = colors.white, bg = colors.grey },
        c = { fg = colors.white },
    },

    insert = { a = { fg = colors.black, bg = colors.cyan } },
    visual = { a = { fg = colors.black, bg = colors.violet } },
    command = { a = { fg = colors.black, bg = colors.red } },

    inactive = {
        a = { fg = colors.white, bg = colors.black },
        b = { fg = colors.white, bg = colors.black },
        c = { fg = colors.white },
    },
}

require('lualine').setup {
    options = {
        theme = bubbles_theme,
        component_separators = '',
        section_separators = { left = '', right = '' },
    },
    sections = {
        lualine_a = { { 'mode', separator = { left = '' }, right_padding = 2 } },
        lualine_b = { 'filename' },
        lualine_c = {
            '%=', --[[ add your center components here in place of this comment ]]
        },
        lualine_x = {},
        lualine_y = { 'filetype', 'progress' },
        lualine_z = {
            {'branch', separator = { right = '' }, left_padding = 2 },
        },
    },
    inactive_sections = {
        lualine_a = { 'filename' },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = { 'branch' },
    },
    tabline = {},
    extensions = {},
}


