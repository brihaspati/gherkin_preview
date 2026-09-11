# gherkin-preview.nvim

Render `.feature` (Gherkin/Cucumber) files in your browser as a semantic
"living documentation" page — the Gherkin analogue of
[markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim).

Zero external runtime. The parser, HTML renderer, and live-reload HTTP server
are pure Lua built on Neovim's bundled libuv.

![scope](https://img.shields.io/badge/neovim-0.8%2B-57A143)

## What it renders

- `Feature` with its free-form description and tags
- `Background`, `Rule` (nested scenarios), `Scenario`
- `Scenario Outline` with `Examples` tables (header row preserved)
- Steps color-coded by keyword (`Given`/`When`/`Then`/`And`/`But`/`*`)
- Data tables and `"""` / ` ``` ` doc strings (with content-type label)
- `@tags` as chips, `# comments` as muted notes (toggleable)
- Auto dark/light theme with an in-page toggle, live reload on save

## Usage

```vim
:GherkinPreview    " start / toggle preview of the current buffer
:GherkinPreviewStop
:GherkinPreviewOpen
```

On save the browser reloads; with `refresh_on_change = true` it reloads on
every keystroke (debounced).

## Installation

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "brihaspati/gherkin_preview",
  ft = { "cucumber" },
  config = function()
    require("gherkin-preview").setup()
  end,
}
```

The plugin ships `ftdetect` so `*.feature` maps to the `cucumber` filetype.

## Configuration

```lua
require("gherkin-preview").setup({
  port = 0,                  -- 0 = OS-assigned; fixed value = stable URL
  browser = "auto",          -- "auto" | "none" | command string, e.g. "firefox {url}"
  refresh_on_change = false, -- live reload on every edit, not just save
  hide_comments = false,
  theme = "auto",            -- "auto" | "light" | "dark"
  dialect = nil,             -- custom Gherkin dialect
  keymaps = {
    toggle = nil,            -- e.g. "<leader>gp"
    stop = nil,
  },
})
```

## How it works

1. `gherkin-preview.parser` tokenizes the buffer into a document model.
2. `gherkin-preview.html` renders the model to self-contained HTML.
3. `gherkin-preview.server` serves it over a loopback `vim.uv` TCP server;
   the page holds a long-poll on `/__events` and reloads when the server
   signals.
4. `BufWritePost` (and optional `TextChanged`) re-renders and signals the
   browser.

## Requirements

- Neovim 0.8+ (uses `vim.uv`/`vim.loop`, `vim.api.nvim_create_user_command`,
  `vim.tbl_deep_extend`).

## License

MIT