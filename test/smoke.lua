-- Headless smoke test. Run from the repo root:
--   nvim --headless --clean -u NONE -c "lua dofile('test/smoke.lua')"
local root = vim.fn.getcwd()
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local function fail(msg)
  print("SMOKE_FAIL: " .. tostring(msg))
  os.exit(1)
end

local function body_of(t)
  return table.concat(t, "")
end

-- 1) parser + renderer checks (synchronous) ----------------------------------
local sync_ok, sync_err = pcall(function()
  local parser = require("gherkin-preview.parser")
  local htmlmod = require("gherkin-preview.html")

  local lines = vim.fn.readfile("examples/calculator.feature")
  local doc = parser.parse(lines)

  assert(doc.feature.name == "Calculator", "feature name = " .. doc.feature.name)
  assert(doc.language == "en", "language = " .. doc.language)

  local top = {}
  for _, c in ipairs(doc.feature.children) do
    top[c.type] = true
  end
  for _, want in ipairs({ "background", "scenario", "scenario_outline", "rule" }) do
    assert(top[want], "missing top-level child: " .. want)
  end

  -- Locate the outline and confirm examples table header + two data rows.
  local outline = nil
  for _, c in ipairs(doc.feature.children) do
    if c.type == "scenario_outline" then
      outline = c
      break
    end
  end
  assert(outline, "scenario outline present")
  assert(#outline.examples == 1, "scenario outline has one examples block")
  local ex = outline.examples[1]
  assert(ex.table[1][1] == "a" and ex.table[1][3] == "sum", "examples header row")
  assert(#ex.table == 3, "examples header + 2 data rows, got " .. #ex.table)

  -- Confirm a docstring (with content type) and a step data table were captured.
  local doc_scenario = nil
  for _, c in ipairs(doc.feature.children) do
    if c.type == "scenario" and c.name:find("table and payload", 1, true) then
      doc_scenario = c
    end
  end
  assert(doc_scenario, "docstring scenario present")
  assert(doc_scenario.steps[1].docstring, "docstring present")
  assert(doc_scenario.steps[1].docstring.content_type == "json", "docstring content type")
  assert(doc_scenario.steps[2].table and #doc_scenario.steps[2].table == 3, "step data table")

  local h = htmlmod.render(doc, { file = "calculator.feature", theme = "light" })
  for _, needle in ipairs({ "Calculator", "Scenario Outline", "Given", "Examples", "&lt;a&gt;" }) do
    assert(h:find(needle, 1, true), "html missing: " .. needle)
  end
end)
if not sync_ok then
  fail(sync_err)
end
print("SMOKE: parser + renderer OK")

-- 2) server checks (async) ----------------------------------------------------
local setup_ok, setup_err = pcall(function()
  local gp = require("gherkin-preview")
  gp.setup({ browser = "none", port = 0 })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.fn.readfile("examples/calculator.feature"))
  gp.preview(0)
  local url = gp.get_url()
  assert(url, "preview URL")
end)
if not setup_ok then
  fail(setup_err)
end

local gp = require("gherkin-preview")
local url = gp.get_url()

local finished = false
local out_main = {}
local out_events = {}

vim.fn.jobstart({ "curl", "-s", url }, {
  on_stdout = function(_, d)
    if d and #d > 0 then
      out_main[#out_main + 1] = table.concat(d, "")
    end
  end,
  on_exit = function(_, code)
    local b = body_of(out_main)
    if code ~= 0 or not b:find("Calculator", 1, true) then
      fail("GET / failed: code=" .. tostring(code) .. " len=" .. #b)
      return
    end
    print("SMOKE: GET / OK")

    vim.fn.jobstart({ "curl", "-s", "--max-time", "5", url .. "/__events" }, {
      on_stdout = function(_, d)
        if d and #d > 0 then
          out_events[#out_events + 1] = table.concat(d, "")
        end
      end,
      on_exit = function(_, code2)
        local b2 = body_of(out_events)
        if code2 ~= 0 or not b2:find('"reload":true', 1, true) then
          fail("GET /__events failed: code=" .. tostring(code2) .. " body=" .. b2)
          return
        end
        print("SMOKE: /__events reload OK")
        gp.stop()
        finished = true
      end,
    })

    vim.defer_fn(function()
      gp.refresh()
    end, 300)
  end,
})

vim.wait(6000, function()
  return finished
end)

if not finished then
  fail("timed out waiting for server checks")
end

print("SMOKE_OK")
vim.cmd("qa!")