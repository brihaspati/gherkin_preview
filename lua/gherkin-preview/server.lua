-- Minimal blocking-free HTTP server built on Neovim's bundled libuv.
-- Serves the rendered document at "/" and a long-poll endpoint at "/__events"
-- used for live reload (the browser re-fetches "/" after a reload signal).
local M = {}

local uv = vim.uv or vim.loop

local MAX_WAITERS = 100

local function http_response(code, reason, headers, body)
  body = body or ""
  local parts = { "HTTP/1.1 " .. code .. " " .. reason .. "\r\n" }
  for k, v in pairs(headers or {}) do
    parts[#parts + 1] = k .. ": " .. v .. "\r\n"
  end
  parts[#parts + 1] = "Content-Length: " .. #body .. "\r\n"
  parts[#parts + 1] = "Connection: close\r\n"
  parts[#parts + 1] = "Cache-Control: no-store\r\n"
  parts[#parts + 1] = "\r\n"
  parts[#parts + 1] = body
  return table.concat(parts)
end

local function write_then_close(client, data)
  if client:is_closing() then
    return
  end
  client:write(data, function(err)
    if not client:is_closing() then
      client:close()
    end
  end)
end

--- Start the server.
-- @param port number preferred port (0 = ephemeral)
-- @param get_html function() -> string
-- @return state table {server, port, waiters, get_html}
function M.start(port, get_html)
  local srv = uv.new_tcp()
  local state = { server = srv, waiters = {}, get_html = get_html, port = nil }

  local function route(client, method, path)
    if method ~= "GET" then
      write_then_close(
        client,
        http_response("405", "Method Not Allowed", { ["Allow"] = "GET" }, "method not allowed")
      )
      return
    end
    if path == "/__events" then
      if #state.waiters >= MAX_WAITERS then
        write_then_close(client, http_response("503", "Service Unavailable", nil, "too many watchers"))
      else
        state.waiters[#state.waiters + 1] = client
      end
      return
    end
    if path == "/" or path == "/index.html" then
      local body = state.get_html() or ""
      write_then_close(
        client,
        http_response("200", "OK", { ["Content-Type"] = "text/html; charset=utf-8" }, body)
      )
      return
    end
    if path == "/favicon.ico" then
      write_then_close(client, http_response("200", "OK", { ["Content-Type"] = "image/x-icon" }, ""))
      return
    end
    write_then_close(client, http_response("404", "Not Found", { ["Content-Type"] = "text/plain" }, "not found"))
  end

  local function on_connection()
    local client = uv.new_tcp()
    local ok = srv:accept(client)
    if not ok then
      client:close()
      return
    end
    local buf = ""
    client:read_start(function(err, chunk)
      if err then
        if not client:is_closing() then
          client:close()
        end
        return
      end
      if chunk then
        buf = buf .. chunk
        local he_crlf = buf:find("\r\n\r\n", 1, true)
        local he_lf = buf:find("\n\n", 1, true)
        local pos, sep
        if he_crlf and (not he_lf or he_crlf < he_lf) then
          pos, sep = he_crlf, 4
        elseif he_lf then
          pos, sep = he_lf, 2
        end
        if pos then
          client:read_stop()
          local first = buf:sub(1, pos):match("^[^\r\n]+")
          local method, path = first:match("^(%S+)%s+(%S+)")
          route(client, method, path or "/")
        end
      end
    end)
  end

  local function actual_port()
    local sock = srv:getsockname()
    return sock and sock.port or nil
  end

  local function bind(p)
    pcall(function()
      srv:bind("127.0.0.1", p)
    end)
    return actual_port()
  end

  local preferred = port or 0
  local actual = bind(preferred)
  if not actual and preferred ~= 0 then
    -- Preferred port unavailable: fall back to an ephemeral one.
    actual = bind(0)
  end
  if not actual then
    error("gherkin-preview: failed to bind server socket")
  end
  state.port = actual
  srv:listen(128, on_connection)

  return state
end

--- Signal connected browsers to reload. Leaves the long-poll clients with a full
-- JSON response; each re-fetches "/" for fresh HTML.
function M.reload(state)
  local ws = state.waiters
  state.waiters = {}
  for _, client in ipairs(ws) do
    write_then_close(
      client,
      http_response("200", "OK", { ["Content-Type"] = "application/json" }, '{"reload":true}')
    )
  end
end

--- Stop the server and release all pending watchers.
function M.stop(state)
  for _, client in ipairs(state.waiters) do
    write_then_close(
      client,
      http_response("200", "OK", { ["Content-Type"] = "application/json" }, '{"reload":true}')
    )
  end
  state.waiters = {}
  if state.server and not state.server:is_closing() then
    state.server:close()
  end
end

return M