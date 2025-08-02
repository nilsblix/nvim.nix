local cmd = vim.cmd
local opt = vim.o

opt.path = opt.path .. '**'

opt.number = true
opt.showmatch = true -- Highlight matching parentheses, etc
opt.incsearch = true
opt.hlsearch = true
opt.guicursor = "n-v-i-c:block-Cursor"

opt.expandtab = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.scrolloff = 10

opt.autoread = true
opt.swapfile = false
vim.g.mapleader = " "

opt.mouse = "a"

cmd("set clipboard+=unnamed")
cmd("set listchars=tab:>~,nbsp:_")

-- FIXME: What is this?
-- Native plugins
cmd.filetype('plugin', 'indent', 'on')
cmd.packadd('cfilter') -- Allows filtering the quickfix list with :cfdo

local keymap = vim.keymap
keymap.set("n", "<leader>p", "<C-^>")
keymap.set("n", "<leader>n", ":Ex<CR>")
keymap.set("n", "<leader>ya", "mzggyG`z")
keymap.set("n", "<C-c>", ":cnext<CR>")
keymap.set("n", "<C-k>", ":cprev<CR>")
keymap.set("n", "<Esc>", ":nohlsearch<CR>", { silent = true })

vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank()
    end,
})

-- This bad boy removes all italics forever.
-- Everything Everywhere All at Once.
local grpid = vim.api.nvim_create_augroup('custom_highlights', {})
vim.api.nvim_create_autocmd('ColorScheme', {
    group = grpid,
    pattern = "*",
    callback = function(_)
        cmd("hi! Cursorline guibg=NONE")
        for _, name in ipairs(vim.fn.getcompletion("", "highlight")) do
            local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name })
            if ok and hl then
                if hl.italic or hl.underline or hl.undercurl or hl.underdouble or hl.underdotted or hl.underdashed then
                    hl.italic = false
                    vim.api.nvim_set_hl(0, name, hl)
                end
            end
        end
        vim.cmd("hi! clear Cursor")
    end,
})

function B(bg)
    cmd("hi! Normal guibg=" .. bg)
    cmd("hi! EndOfBuffer guibg=" .. bg)
    cmd("hi! LineNr guibg=" .. bg)
end

cmd("set notermguicolors") -- Used to make sonokai more appealing
cmd("colorscheme sonokai")

-- <=============== Blink ===============>
local blink = require("blink.cmp")
blink.setup({
    keymap = { preset = "default" },
    sources = {
        default = { "lsp", "path" },
    },
    fuzzy = { implementation = "rust" },
    completion = {
        menu = {
            draw = {
                columns = { { "label", "kind", gap = 1 }, { "label_description" } },
            }
        }
    }
})

-- <=============== Harpoon ===============>
local harpoon = require("harpoon")
harpoon:setup()

local list = harpoon:list()

for i = 1, 4 do
    local key = "<leader>" .. tostring(i)
    keymap.set("n", key, function() list:select(i) end, { noremap = true, silent = true })
end

keymap.set("n", "<leader><leader>", function() harpoon.ui:toggle_quick_menu(list) end)
keymap.set("n", "<leader>a", function() list:add() end)

-- <=============== Treesitter ===============>
require("nvim-treesitter.configs").setup({
    ensure_installed = {},
    sync_install = false,
    auto_install = false,
    indent = { enable = true, },
    highlight = { enable = true, },
})

require("treesitter-context").setup({
    enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
    multiwindow = false, -- Enable multiwindow support.
    max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
    min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
    line_numbers = true,
    multiline_threshold = 20, -- Maximum number of lines to show for a single context
    trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
    mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
    -- Separator between context and content. Should be a single character string, like '-'.
    -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
    separator = nil,
    zindex = 20, -- The Z-index of the context window
    on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
})

-- <=============== Lsp ===============>
local border_opt = "single"

vim.diagnostic.config({
    float = { border = border_opt, focusable = true, },
    virtual_text = true,
    signs = false,
})

local capabilities = blink.get_lsp_capabilities()

local servers = {
    "lua_ls",
    "rust_analyzer",
    "zls",
    "ts_ls",
    "nixd",
    "yamlls"
}

for _, server in ipairs(servers) do
    if (server == "nixd") then
        require("lspconfig")[server].setup({
            capabilities = capabilities,
            cmd = { "nixd" },
            settings = {
                nixd = {
                    nixpkgs = {
                        expr = "import <nixpkgs> { }",
                    },
                },
            },
        })
    else
        require("lspconfig")[server].setup({
            capabilities = capabilities,
        })
    end
end

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(e)
        local opts = { buffer = e.buf }
        keymap.set("n", "gd", function()
            vim.lsp.buf.definition()
        end, opts)
        keymap.set("n", "gr", function()
            vim.lsp.buf.references()
        end, opts)
        keymap.set("n", "K", function()
            vim.lsp.buf.hover({})
        end, opts)
        keymap.set("i", "<C-h>", function()
            vim.lsp.buf.signature_help()
        end, opts)
        keymap.set("n", "<leader>rn", function()
            vim.lsp.buf.rename()
        end, opts)
        keymap.set("n", "<leader>E", function()
            vim.diagnostic.open_float()
        end, opts)
    end,
})

local tel = require("telescope.builtin")
keymap.set("n", "<leader>sf", tel.find_files)
keymap.set("n", "<leader>sg", tel.live_grep)
keymap.set("n", "<leader>sd", tel.diagnostics)
