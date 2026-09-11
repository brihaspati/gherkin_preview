-- Bootstrap: lazy module load + user commands + <Plug> mappings.
-- Configure via require("gherkin-preview").setup({ ... }).

local function toggle()
  require("gherkin-preview").toggle()
end

local function stop()
  require("gherkin-preview").stop()
end

local function open()
  require("gherkin-preview").open()
end

vim.api.nvim_create_user_command("GherkinPreview", toggle, {})
vim.api.nvim_create_user_command("GherkinPreviewStop", stop, {})
vim.api.nvim_create_user_command("GherkinPreviewOpen", open, {})

vim.keymap.set("n", "<Plug>(gherkin-preview-toggle)", toggle, { silent = true })
vim.keymap.set("n", "<Plug>(gherkin-preview-stop)", stop, { silent = true })
vim.keymap.set("n", "<Plug>(gherkin-preview-open)", open, { silent = true })