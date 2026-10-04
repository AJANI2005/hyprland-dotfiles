-- Must be set up here
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local gh = "https://www.github.com/"

vim.pack.add{
  { src = gh .. 'neovim/nvim-lspconfig' },
  { src = gh .. 'mason-org/mason.nvim' },
  { src = gh .. 'mason-org/mason-lspconfig.nvim' },
}

local servers = {
  "lua_ls", "ts_ls", "jsonls", "bashls",
  "pyright", "clangd",
}
require("mason").setup({})
require("mason-lspconfig").setup({ ensure_installed=servers })

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT', },
      diagnostics = { globals = { 'vim' }, },
      workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME, }, },
      telemetry = { enable = false, }, },
  },
})

vim.pack.add{
  { src = gh .. 'saghen/blink.cmp', version='v1' },
}
require('blink.cmp').setup {}
local capabilities = require('blink.cmp').get_lsp_capabilities()
for _,server in ipairs(servers) do
    vim.lsp.config(server,{ capabilities = capabilities })
end

-- Fuzzy Finder
vim.pack.add({
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
})
require('telescope').setup({})
vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<CR>', { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<CR>', { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fd', '<cmd>Telescope lsp_definitions<CR>', { desc = 'Definitions' })
vim.keymap.set('n', '<leader>fr', '<cmd>Telescope lsp_references<CR>', { desc = 'References' })
vim.keymap.set('n', '<leader>fi', '<cmd>Telescope lsp_implementations<CR>', { desc = 'Implementations' })
vim.keymap.set('n', '<leader>ft', '<cmd>Telescope lsp_type_definitions<CR>', { desc = 'Type definitions' })
vim.keymap.set('n', '<leader>fs', '<cmd>Telescope lsp_document_symbols<CR>', { desc = 'Document symbols' })
vim.keymap.set('n', '<leader>fw', '<cmd>Telescope lsp_dynamic_workspace_symbols<CR>', { desc = 'Workspace symbols' })


-- More Plugins
vim.pack.add({
  'https://github.com/akinsho/toggleterm.nvim',
  'https://github.com/echasnovski/mini.indentscope',
  'https://github.com/lukas-reineke/indent-blankline.nvim',
  'https://github.com/stevearc/oil.nvim',
  'https://github.com/echasnovski/mini.icons',
  'https://github.com/nvim-lualine/lualine.nvim',
  'https://github.com/folke/which-key.nvim',
  'https://github.com/folke/tokyonight.nvim',
  'https://github.com/windwp/nvim-autopairs',
  'https://github.com/windwp/nvim-ts-autotag',
})
require('nvim-autopairs').setup()
require('nvim-ts-autotag').setup()
require('which-key').setup()
require('mini.icons').setup()
require('ibl').setup({ indent = { char = "│", } })
require('mini.indentscope').setup({ symbol = '│', options = { try_as_border = true, }, })
require('toggleterm').setup({ open_mapping = [[<M-CR>]], direction = 'float', })

vim.keymap.set('t', '<M-Esc>', '<C-\\><C-n>:ToggleTerm<CR>')
vim.keymap.set('n', '<M-Esc>', '<cmd>ToggleTerm<CR>')

-- Oil File Explorer
require('oil').setup({
  columns = { 'icon' },
  winbar = '%{v:lua.require("oil").get_current_dir()}',
})
vim.keymap.set('n', '<leader>pv', '<cmd>Oil<CR>', { desc = 'File explorer' })
vim.keymap.set('n', '<leader>e', '<cmd>Oil<CR>', { desc = 'File explorer' })

-- Status line
require('lualine').setup({
  options = {
    globalstatus = true,
    component_separators = '',
    section_separators = '',
  },
})


-- Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.ignorecase = true

vim.opt.list = true
-- vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣", }
-- vim.opt.clipboard = "unnamedplus" -- use system clipboard
vim.opt.termguicolors = true
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.o.complete = ".,o"
vim.o.completeopt = "menu,menuone,noselect,popup"
vim.bo.omnifunc = "v:lua.vim.lsp.omnifunc"
vim.o.autocomplete = true
vim.o.pumheight = 12
vim.opt.isfname:append("@-@")

-- diagnostics
vim.diagnostic.config({ virtual_text = true })

-- Keymaps
vim.keymap.set("n", "<leader>x", function()
  vim.diagnostic.setqflist()
  vim.lsp.buf.workspace_diagnostics()
  vim.cmd("copen")
end, { silent = true })

vim.keymap.set("v", "<C-Space>", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<C-Space>", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "NetRW" })
vim.keymap.set("n", "<leader>so", "<cmd>source %<CR>", { desc = "Source Current File" })
vim.keymap.set("n", "<leader>q", "<cmd>close<CR>", { desc = "Close Window" })
vim.keymap.set("n", "<leader>fb", "<cmd>lua vim.lsp.buf.format()<CR>", { desc = "Format Buffer" })
vim.keymap.set("n", "<C-h>", "<cmd>wincmd h<CR>")
vim.keymap.set("n", "<C-j>", "<cmd>wincmd j<CR>")
vim.keymap.set("n", "<C-k>", "<cmd>wincmd k<CR>")
vim.keymap.set("n", "<C-l>", "<cmd>wincmd l<CR>")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join line" })
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv") -- keep search term centered
vim.keymap.set("x", "<leader>p", "\"_dP", { desc = "Paste without changing buffer" })
vim.keymap.set("n","Q", "<nop>") -- worst place in the universe
vim.keymap.set({"n"}, "<leader>sw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set({"v"}, "<leader>sw", [["hy:%s/\V<C-r>h/<C-r>h/gI<Left><Left><Left>]])
-- split window 
vim.keymap.set("n", "<leader>sv", "<C-w>v<C-w>l", { desc = "Split Window Vertically" })
vim.keymap.set("n", "<leader>sh", "<C-w>s<C-w>j", { desc = "Split Window Horizontally" })

-- Highlight selection on 
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  pattern = "*",
  desc = "highlight selection on yank",
  callback = function()
    vim.highlight.on_yank({ timeout = 200, visual = true })
  end,
})
-- Restore cursor to file position in previous editing session
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
      -- defer centering slightly so it's applied after render
      vim.schedule(function()
        vim.cmd("normal! zz")
      end)
    end
  end,
})

-- transparent background
vim.cmd.colorscheme('tokyonight-night')
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })


