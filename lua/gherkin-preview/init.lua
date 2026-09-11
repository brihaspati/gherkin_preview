local parser = require("gherkin-preview.parser")
local html = require("gherkin-preview.html")
local server = require("gherkin-preview.server")
local util = require("gherkin-preview.util")

local M = {}

local config = {
  --- TCP port for the preview server. 0 (default) = OS-assigned ephemeral port;
  --- set a fixed value if you want a stable URL.
  port = 0,
  --- Browser launcher. "auto" (default) uses the platform default; "none"
  --- disables launching (URL still printed); otherwise a command string, with
  --- an optional {url} placeholder.
  browser = "auto",
  --- Re-render on every change (debounced), not just on save.
  refresh_on_change = false,
  --- Do not render `# comment` lines.
  hide_comments = false,
  --- "auto" | "light" | "dark".
  theme = "auto",
  --- Custom dialect, same shape as require("gherkin-preview.dialect").en.
  dialect = nil,
  --- Optional keymaps applied in "n"ormal mode.
  keymaps = {
    toggle = nil,
    stop = nil,
  },
}

local state = {
  buf = nil, -- previewed buffer handle
  server = nil,
  url = nil,
  html = nil, -- last rendered HTML (served from the libuv fast context)
}

local group = vim.api.nvim_create_augroup("GherkinPreview", { clear = true })
local debounce_timer = nil

local function current_buffer()
  return vim.api.nvim_get_current_buf()
end

local function render_html(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local doc = parser.parse(lines, { dialect = config.dialect })
  return html.render(doc, {
    file = vim.api.nvim_buf_get_name(buf):match("([^/]+)$") or "gherkin",
    hide_comments = config.hide_comments,
    theme = config.theme,
  })
end

local function render_and_cache(buf)
  state.html = render_html(buf)
end

local function refresh()
  if state.server and state.buf then
    render_and_cache(state.buf)
    server.reload(state.server)
  end
end

local function schedule_refresh()
  if debounce_timer then
    vim.fn.timer_stop(debounce_timer)
  end
  debounce_timer = vim.fn.timer_start(300, function()
    debounce_timer = nil
    refresh()
  end)
end

local function register_autocmds()
  vim.api.nvim_create_augroup("GherkinPreview", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(a)
      if state.server and state.buf == a.buf then
        refresh()
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(a)
      if state.buf == a.buf then
        M.stop()
      end
    end,
  })

  if config.refresh_on_change then
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = group,
      callback = function(a)
        if state.server and state.buf == a.buf then
          schedule_refresh()
        end
      end,
    })
  end
end

local function start(buf)
  state.buf = buf
  if not state.server then
    state.server = server.start(config.port, function()
      return state.html
    end)
    state.url = "http://127.0.0.1:" .. state.server.port
    vim.notify("gherkin-preview: " .. state.url, vim.log.levels.INFO)
  end
  render_and_cache(buf)
  server.reload(state.server)
  util.open_browser(state.url, config.browser)
end

local function stop()
  if state.server then
    server.stop(state.server)
    state.server = nil
  end
  state.buf = nil
  state.url = nil
end

--- Toggle preview for the current buffer.
function M.toggle()
  local buf = current_buffer()
  if state.server and state.buf == buf then
    stop()
    return
  end
  start(buf)
end

--- Force re-render and reload the connected browser.
function M.refresh()
  refresh()
end

--- Stop the server (does not close the browser tab).
function M.stop()
  stop()
end

--- (Re)open the preview URL in the browser if the server is running.
function M.open()
  if not state.url then
    vim.notify("gherkin-preview: not running; run :GherkinPreview first", vim.log.levels.WARN)
    return
  end
  util.open_browser(state.url, config.browser)
end

--- Preview a specific buffer (defaults to current).
function M.preview(buf)
  start(buf or current_buffer())
end

function M.get_url()
  return state.url
end

--- Configure the plugin. Optional.
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  if config.dialect then
    require("gherkin-preview.dialect").current = config.dialect
  end

  local km = config.keymaps or {}
  if km.toggle then
    vim.keymap.set("n", km.toggle, M.toggle, { desc = "Gherkin preview (toggle)" })
  end
  if km.stop then
    vim.keymap.set("n", km.stop, M.stop, { desc = "Gherkin preview (stop)" })
  end

  register_autocmds()
end

-- Live reload works even without setup().
register_autocmds()

return M