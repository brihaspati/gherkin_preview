local M = {}

local escapes = {
  ["&"] = "&amp;",
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ['"'] = "&quot;",
  ["'"] = "&#39;",
}

--- Escape a string for safe interpolation into HTML text nodes.
function M.escape_html(s)
  if s == nil then
    return ""
  end
  return (tostring(s):gsub("[&<>\"']", escapes))
end

--- Open a URL in the system browser.
-- @param url string
-- @param browser "auto" (platform default) | "none" | command string
--   A command string may embed `{url}` (or `%s`) as the URL placeholder;
--   if absent, the URL is appended as the last argument.
-- @return boolean true if a launcher was invoked
function M.open_browser(url, browser)
  browser = browser or "auto"
  if browser == "none" then
    return false
  end

  local cmd, args
  if browser == "auto" then
    if vim.fn.has("mac") == 1 then
      cmd, args = "open", { url }
    elseif vim.fn.has("linux") == 1 then
      cmd, args = "xdg-open", { url }
    elseif vim.fn.has("win32") == 1 then
      cmd, args = "cmd", { "/c", "start", "", url }
    else
      vim.notify(
        "gherkin-preview: cannot detect a browser launcher; open manually:\n" .. url,
        vim.log.levels.WARN
      )
      return false
    end
  else
    local resolved = browser:gsub("{[Uu][Rr][Ll]}", url):gsub("%%s", url)
    if not resolved:find(url, 1, true) then
      resolved = resolved .. " " .. url
    end
    local parts = vim.fn.split(vim.fn.trim(resolved), "%s+")
    cmd = parts[1]
    args = {}
    for i = 2, #parts do
      args[i - 1] = parts[i]
    end
  end

  local ok = pcall(vim.fn.jobstart, { cmd, unpack(args) }, { detach = true })
  if not ok then
    vim.notify(
      "gherkin-preview: failed to launch browser (" .. tostring(cmd) .. ")",
      vim.log.levels.ERROR
    )
    return false
  end
  return true
end

return M