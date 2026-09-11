local dialect = require("gherkin-preview.dialect")

local M = {}

local function trim(s)
  if not s then
    return ""
  end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function first_nonspace(line)
  local p = line:find("%S")
  return p and line:sub(p, p) or nil
end

--- Keyword matchers built from a dialect table. Longest keyword first so that
--- multi-word keywords (e.g. "Scenario Outline") win over prefixes.
local function build_matchers(dia)
  local sections = {}
  local kinds = { "feature", "background", "rule", "scenario", "scenario_outline", "examples" }
  for _, kind in ipairs(kinds) do
    for _, kw in ipairs(dia.keywords[kind] or {}) do
      sections[#sections + 1] = { kind = kind, kw = kw }
    end
  end
  table.sort(sections, function(a, b)
    return #a.kw > #b.kw
  end)

  local steps = {}
  local step_kinds = { "given", "when", "then", "and", "but" }
  for _, kind in ipairs(step_kinds) do
    for _, kw in ipairs(dia.steps[kind] or {}) do
      steps[#steps + 1] = { kind = kind, kw = kw }
    end
  end
  table.sort(steps, function(a, b)
    return #a.kw > #b.kw
  end)

  return sections, steps
end

--- Match a section keyword (Feature/Background/Rule/Scenario/...Outline/Examples).
-- Returns kind, keyword, name or nil.
local function match_section(line, sections)
  if line == "" then
    return nil
  end
  for _, s in ipairs(sections) do
    if line == s.kw then
      return s.kind, s.kw, ""
    end
    local rest = line:match("^" .. s.kw .. "[%s:]+(.*)$")
    if rest ~= nil then
      return s.kind, s.kw, trim(rest)
    end
  end
  return nil
end

--- Match a step keyword (Given/When/Then/And/But/*). Returns kind, keyword, text or nil.
local function match_step(line, steps, star)
  for _, s in ipairs(steps) do
    if line == s.kw then
      return s.kind, s.kw, ""
    end
    local rest = line:match("^" .. s.kw .. "%s+(.*)$")
    if rest ~= nil then
      return s.kind, s.kw, trim(rest)
    end
  end
  if star then
    if line == "*" then
      return "star", "*", ""
    end
    local rest = line:match("^%*%s+(.*)$")
    if rest ~= nil then
      return "star", "*", trim(rest)
    end
  end
  return nil
end

--- Parse a data-table row, honouring `\|`, `\\` and `\n` escapes. Returns cells or nil.
local function parse_table_row(raw)
  local s = trim(raw)
  if s:sub(1, 1) ~= "|" then
    return nil
  end
  local cells = {}
  local buf = ""
  local i = 2
  while i <= #s do
    local c = s:sub(i, i)
    if c == "\\" then
      local nx = s:sub(i + 1, i + 1)
      if nx == "|" or nx == "\\" then
        buf = buf .. nx
        i = i + 2
      elseif nx == "n" then
        buf = buf .. "\n"
        i = i + 2
      else
        buf = buf .. c
        i = i + 1
      end
    elseif c == "|" then
      cells[#cells + 1] = trim(buf)
      buf = ""
      i = i + 1
    else
      buf = buf .. c
      i = i + 1
    end
  end
  if buf ~= "" then
    cells[#cells + 1] = trim(buf)
  end
  return cells
end

local function new_node(kind, keyword, name, tags)
  local node = {
    type = kind,
    keyword = keyword,
    name = name or "",
    tags = tags or {},
    description = {},
  }
  if kind == "feature" or kind == "rule" then
    node.children = {}
  elseif kind == "scenario" or kind == "background" then
    node.steps = {}
  elseif kind == "scenario_outline" then
    node.steps = {}
    node.examples = {}
  elseif kind == "examples" then
    node.table = {}
  end
  return node
end

--- Parse feature source into a document model.
-- @param src string (whole buffer) or table of raw lines
-- @param opts {dialect?, }
-- @return document table
function M.parse(src, opts)
  opts = opts or {}
  local dia = opts.dialect or dialect.current
  local sections, steps = build_matchers(dia)
  local star = dia.star == "*" or dia.star == nil or dia.star == ""

  local lines
  if type(src) == "table" then
    lines = src
  else
    lines = {}
    local s = src:gsub("\r\n", "\n"):gsub("\r", "\n")
    for l in (s):gmatch("([^\n]*)") do
      lines[#lines + 1] = l
    end
    -- gmatch yields one empty element after a trailing newline; harmless
    -- (blank lines merely separate description paragraphs).
  end

  local feature = new_node("feature", dia.keywords.feature and dia.keywords.feature[1] or "Feature", "", {})
  local doc = { language = "en", feature = feature, comments = {} }
  local scope = feature
  local current = feature
  local pending_tags = {}
  local has_feature = false

  local ds = nil -- in-progress docstring {step, delim, content_type, lines}

  local function add_last_table_row(row, raw_line)
    if current.type == "examples" then
      current.table[#current.table + 1] = row
    elseif current.steps and #current.steps > 0 then
      local last = current.steps[#current.steps]
      last.table = last.table or {}
      last.table[#last.table + 1] = row
    else
      -- Invalid position; preserve text rather than drop it.
      current.description[#current.description + 1] = raw_line
    end
  end

  local i = 1
  local n = #lines
  while i <= n do
    local raw = lines[i]
    local line = trim(raw)
    i = i + 1

    if ds then
      if line == ds.delim then
        ds.step.docstring = {
          content_type = ds.content_type,
          lines = ds.lines,
          delim = ds.delim,
        }
        ds = nil
      else
        ds.lines[#ds.lines + 1] = raw
      end
    elseif line == "" then
      -- blank line: ignored (separates description paragraphs)
    elseif first_nonspace(raw) == "#" then
      local lang = line:match("^#%s*language%s*:%s*(%S+)")
      if lang then
        doc.language = lang:lower()
      else
        doc.comments[#doc.comments + 1] = { text = line:sub(3), line = i - 1 }
      end
    elseif first_nonspace(raw) == "@" then
      for t in line:gmatch("@%S+") do
        pending_tags[#pending_tags + 1] = t
      end
    elseif first_nonspace(raw) == "|" then
      local row = parse_table_row(raw)
      if row then
        add_last_table_row(row, raw)
      else
        current.description[#current.description + 1] = raw
      end
    else
      local ddelim, drest = raw:match('^%s*(""")(.*)$')
      if not ddelim then
        ddelim, drest = raw:match('^%s*(```)(.*)$')
      end
      if ddelim then
        local step = current.steps and current.steps[#current.steps] or nil
        if step then
          ds = { step = step, delim = ddelim, content_type = trim(drest), lines = {} }
        else
          current.description[#current.description + 1] = raw
        end
      else
        local kind, kw, name = match_section(line, sections)
        if kind then
          if kind == "feature" then
            if not has_feature then
              has_feature = true
              feature.keyword = kw
              feature.name = name
              feature.tags = pending_tags
              pending_tags = {}
              scope = feature
              current = feature
            end
          else
            local node = new_node(kind, kw, name, pending_tags)
            pending_tags = {}
            if kind == "rule" then
              feature.children[#feature.children + 1] = node
              scope = node
              current = node
            elseif kind == "examples" then
              if current.type == "scenario_outline" then
                current.examples[#current.examples + 1] = node
                current = node
              end
            else -- scenario / scenario_outline / background
              scope.children[#scope.children + 1] = node
              current = node
            end
          end
        else
          local skind, skw, stext = match_step(line, steps, star)
          if skind then
            local step = { keyword = skw, text = stext, kind = skind, line = i - 1 }
            if current.steps then
              current.steps[#current.steps + 1] = step
            else
              -- Step keyword outside a step container: keep as description.
              current.description[#current.description + 1] = raw
            end
          else
            current.description[#current.description + 1] = raw
          end
        end
      end
    end
  end

  return doc
end

return M