local cmd = vim.cmd
local opt = vim.o

opt.path = opt.path .. '**'

opt.number = true
-- opt.showmatch = true
opt.incsearch = true
opt.hlsearch = true
opt.guicursor = "n-v-i-c:block-Cursor"
vim.cmd("let g:netrw_banner=0")

opt.title = true
opt.expandtab = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.scrolloff = 10
opt.wrap = false

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
keymap.set("n", "<leader>ya", "mzggyG`z")
keymap.set("n", "<leader>n", ":Ex<CR>", { silent = true })
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

cmd("colo github_dark_default")
cmd("hi StatusLine guibg=#282838 guifg=#a2a2a2")
-- cmd("set notermguicolors") -- Make sonokai better looking imo.
-- cmd("colorscheme sonokai")
-- Similar to OCAML-demo video editor.
-- cmd("colorscheme gruvbox-material")
-- B("black")
-- cmd("hi link @variable Fg")

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

-- <=============== Lsp ===============>
require("fidget").setup({})

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
    "yamlls",
    "basedpyright",
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
    elseif (server == "lua_ls") then
        require("lspconfig")[server].setup({
            capabilities = capabilities,
            settings = {
                Lua = {
                    diagnostics = {
                        globals = { "vim" },
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

local telescope_builtin = require("telescope.builtin")
keymap.set("n", "<leader>sf", telescope_builtin.find_files)
keymap.set("n", "<leader>sg", telescope_builtin.live_grep)
keymap.set("n", "<leader>sd", telescope_builtin.diagnostics)
