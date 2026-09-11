local util = require("gherkin-preview.util")

local M = {}

local esc = util.escape_html

local CSS = [==[
:root {
  color-scheme: light dark;
  --bg: #ffffff; --fg: #1f2328; --muted: #6e7781;
  --border: #d8dee4; --card: #f6f8fa; --card-border: #e7ecf0;
  --given: #1a7f37; --when: #9a6700; --then: #0969da; --conj: #57606a;
  --feature-accent: #8250df; --scenario-accent: #0969da; --rule-accent: #bc4c00;
  --bg-accent: #0366d6;
  --tag-bg: #ddf4ff; --tag-fg: #0969da;
  --code-bg: #f0f2f5; --code-fg: #1f2328;
  --comment: #6e7781;
  --table-th: #f6f8fa;
}
html[data-theme="dark"] {
  --bg: #0d1117; --fg: #e6edf3; --muted: #8b949e;
  --border: #30363d; --card: #161b22; --card-border: #21262d;
  --given: #3fb950; --when: #d29922; --then: #58a6ff; --conj: #8b949e;
  --feature-accent: #d2a8ff; --scenario-accent: #58a6ff; --rule-accent: #ffa657;
  --bg-accent: #1f6feb;
  --tag-bg: #0d2d46; --tag-fg: #58a6ff;
  --code-bg: #161b22; --code-fg: #e6edf3;
  --comment: #8b949e;
  --table-th: #161b22;
}
@media (prefers-color-scheme: dark) {
  html[data-theme="auto"] {
    --bg: #0d1117; --fg: #e6edf3; --muted: #8b949e;
    --border: #30363d; --card: #161b22; --card-border: #21262d;
    --given: #3fb950; --when: #d29922; --then: #58a6ff; --conj: #8b949e;
    --feature-accent: #d2a8ff; --scenario-accent: #58a6ff; --rule-accent: #ffa657;
    --bg-accent: #1f6feb;
    --tag-bg: #0d2d46; --tag-fg: #58a6ff;
    --code-bg: #161b22; --code-fg: #e6edf3;
    --comment: #8b949e;
    --table-th: #161b22;
  }
}

* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
body {
  background: var(--bg);
  color: var(--fg);
  font: 15px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
}
a { color: var(--then); }

.toolbar {
  position: sticky; top: 0; z-index: 10;
  display: flex; align-items: center; justify-content: space-between;
  padding: 8px 20px;
  background: color-mix(in srgb, var(--bg) 84%, transparent);
  backdrop-filter: blur(6px);
  border-bottom: 1px solid var(--border);
}
.toolbar .file { font-weight: 600; font-size: 13px; color: var(--muted); font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
.toolbar .controls { display: flex; align-items: center; gap: 12px; }
.status { font-size: 12px; color: var(--muted); }
.status .dot { color: var(--given); }
button#theme {
  background: none; border: 1px solid var(--border); color: var(--fg);
  border-radius: 6px; cursor: pointer; padding: 2px 9px; font-size: 13px;
}

main { max-width: 860px; margin: 0 auto; padding: 28px 20px 80px; }

.banner {
  border: 1px solid var(--border); color: var(--muted);
  border-radius: 8px; padding: 8px 14px; margin-bottom: 20px; font-size: 13px;
}

.feature { }
.feature .tags { margin-bottom: 6px; }
.feature-name {
  font-size: 30px; line-height: 1.25; margin: 0 0 4px;
  color: var(--fg); font-weight: 700; letter-spacing: -0.01em;
}
.feature-kw {
  display: inline-block; font-size: 12px; font-weight: 700; text-transform: uppercase;
  letter-spacing: 0.06em; color: var(--feature-accent); margin-bottom: 6px;
}

.tag {
  display: inline-block; background: var(--tag-bg); color: var(--tag-fg);
  border-radius: 999px; padding: 1px 9px; font-size: 12px; font-family: ui-monospace, Menlo, monospace;
  margin-right: 5px;
}

.description { color: var(--fg); margin: 8px 0 18px; }
.description p { margin: 0 0 10px; }

.rule {
  margin: 18px 0; padding: 14px 16px 8px;
  border: 1px solid var(--card-border); border-left: 3px solid var(--rule-accent);
  border-radius: 10px; background: var(--card);
}
.rule-head { font-weight: 600; margin-bottom: 6px; }
.rule-head .kw { color: var(--rule-accent); font-size: 12px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 700; margin-right: 8px; }

.scenario, .background {
  margin: 18px 0; padding: 16px 18px;
  border: 1px solid var(--card-border); border-radius: 10px; background: var(--card);
}
.scenario .head, .background .head { display: flex; align-items: baseline; flex-wrap: wrap; gap: 8px; }
.scenario .kw, .background .kw {
  font-weight: 700; font-size: 13px; text-transform: uppercase; letter-spacing: 0.04em;
}
.scenario .kw { color: var(--scenario-accent); }
.background .kw { color: var(--bg-accent); }
.scenario .name, .background .name { font-weight: 600; font-size: 16px; }
.scenario .tags { margin-left: auto; }

.steps { margin-top: 12px; display: flex; flex-direction: column; gap: 2px; }
.step { display: flex; align-items: baseline; padding: 4px 0; }
.step .kw {
  flex: 0 0 auto; min-width: 74px; font-weight: 700; text-align: right;
  margin-right: 14px; font-size: 13px;
}
.kw-given, .kw-when, .kw-then, .kw-and, .kw-but, .kw-star { }
.kw-given { color: var(--given); }
.kw-when  { color: var(--when); }
.kw-then  { color: var(--then); }
.kw-and, .kw-but, .kw-star { color: var(--conj); }
.step .text { white-space: pre-wrap; }

table.gherkin {
  border-collapse: collapse; margin: 10px 0 4px 88px;
  font-size: 13px; min-width: 40%;
}
table.gherkin th, table.gherkin td {
  border: 1px solid var(--border); padding: 6px 12px; text-align: left;
}
table.gherkin th { background: var(--table-th); font-weight: 600; }

.docstring { margin: 10px 0 4px 88px; }
.docstring .doctype {
  font-size: 11px; text-transform: uppercase; letter-spacing: 0.05em;
  color: var(--muted); margin-bottom: 2px;
}
pre.doc {
  margin: 0; background: var(--code-bg); color: var(--code-fg);
  border: 1px solid var(--border); border-radius: 8px; padding: 12px 14px;
  overflow-x: auto; font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 13px; line-height: 1.5;
}
pre.doc code { font-family: inherit; }

.examples-block { margin-top: 12px; }
.examples-block .ex-head { margin: 8px 0 2px 88px; font-weight: 600; font-size: 14px; }
.examples-block .ex-head .kw { color: var(--muted); font-size: 12px; text-transform: uppercase; letter-spacing: 0.05em; margin-right: 6px; }

.comments { margin-top: 26px; border-top: 1px dashed var(--border); padding-top: 14px; }
.comments .comment { color: var(--comment); font-size: 13px; font-family: ui-monospace, Menlo, monospace; white-space: pre-wrap; padding: 1px 0; }
.comments .comment .mark { color: var(--muted); margin-right: 6px; }

@media (max-width: 560px) {
  .step { flex-direction: column; }
  .step .kw { text-align: left; margin-bottom: 2px; }
  table.gherkin, .docstring, .examples-block .ex-head { margin-left: 0; }
}
]==]

local JS = [==[
(function () {
  var root = document.documentElement;
  var scheme = root.getAttribute("data-theme") || "auto";
  var saved = null;
  try { saved = localStorage.getItem("gherkin-theme"); } catch (e) {}
  if (saved) { scheme = saved; root.setAttribute("data-theme", scheme); }

  var ORDER = ["auto", "light", "dark"];
  document.getElementById("theme").addEventListener("click", function () {
    var cur = root.getAttribute("data-theme") || "auto";
    var idx = ORDER.indexOf(cur);
    scheme = ORDER[(idx + 1) % ORDER.length];
    root.setAttribute("data-theme", scheme);
    try { localStorage.setItem("gherkin-theme", scheme); } catch (e) {}
  });

  function poll() {
    fetch("/__events", { cache: "no-store" })
      .then(function (r) { return r.ok ? r.json() : {}; })
      .then(function () { window.location.reload(); })
      .catch(function () { setTimeout(poll, 1500); });
  }
  poll();
})();
]==]

local function render_tags(tags)
  if not tags or #tags == 0 then
    return ""
  end
  local out = {}
  for _, t in ipairs(tags) do
    out[#out + 1] = '<span class="tag">' .. esc(t) .. "</span>"
  end
  return table.concat(out)
end

local function render_description(lines)
  if not lines or #lines == 0 then
    return ""
  end
  local paras, cur = {}, {}
  for _, l in ipairs(lines) do
    local t = l:gsub("^%s+", ""):gsub("%s+$", "")
    if t == "" then
      if #cur > 0 then
        paras[#paras + 1] = table.concat(cur, "<br>")
        cur = {}
      end
    else
      cur[#cur + 1] = esc(l)
    end
  end
  if #cur > 0 then
    paras[#paras + 1] = table.concat(cur, "<br>")
  end
  local out = {}
  for _, p in ipairs(paras) do
    out[#out + 1] = "<p>" .. p .. "</p>"
  end
  local html = table.concat(out)
  if html == "" then
    return ""
  end
  return '<div class="description">' .. html .. "</div>"
end

local function render_table(tbl, header)
  if not tbl or #tbl == 0 then
    return ""
  end
  local out = { '<table class="gherkin"><tbody>' }
  for idx, row in ipairs(tbl) do
    if header and idx == 1 then
      out[#out + 1] = "<tr>"
      for _, cell in ipairs(row) do
        out[#out + 1] = "<th>" .. esc(cell) .. "</th>"
      end
      out[#out + 1] = "</tr>"
    else
      out[#out + 1] = "<tr>"
      for _, cell in ipairs(row) do
        out[#out + 1] = "<td>" .. esc(cell) .. "</td>"
      end
      out[#out + 1] = "</tr>"
    end
  end
  out[#out + 1] = "</tbody></table>"
  return table.concat(out)
end

local function render_step(step)
  local out = { '<div class="step">' }
  out[#out + 1] = '<span class="kw kw-' .. esc(step.kind or "star") .. '">' .. esc(step.keyword) .. "</span>"
  out[#out + 1] = '<span class="text">' .. esc(step.text) .. "</span>"
  out[#out + 1] = "</div>"

  if step.table then
    out[#out + 1] = render_table(step.table, false)
  end
  if step.docstring then
    local content = table.concat(step.docstring.lines, "\n")
    local cls = step.docstring.content_type and step.docstring.content_type ~= "" and step.docstring.content_type or nil
    out[#out + 1] = '<div class="docstring">'
    if cls then
      out[#out + 1] = '<div class="doctype">' .. esc(cls) .. "</div>"
    end
    out[#out + 1] = "<pre class=\"doc\"><code>" .. esc(content) .. "</code></pre></div>"
  end
  return table.concat(out)
end

local function render_examples(ex)
  local out = { '<div class="examples-block">' }
  out[#out + 1] = '<div class="ex-head"><span class="kw">' .. esc(ex.keyword) .. "</span>"
    .. esc(ex.name) .. "</div>"
  out[#out + 1] = render_description(ex.description)
  out[#out + 1] = render_table(ex.table, true)
  out[#out + 1] = "</div>"
  return table.concat(out)
end

local function render_steps(steps)
  local out = { '<div class="steps">' }
  for _, s in ipairs(steps) do
    out[#out + 1] = render_step(s)
  end
  out[#out + 1] = "</div>"
  return table.concat(out)
end

local function render_scenario(node)
  local out = { '<section class="scenario">' }
  out[#out + 1] = '<div class="head"><span class="kw">' .. esc(node.keyword) .. "</span>"
    .. '<span class="name">' .. esc(node.name) .. "</span>"
    .. '<span class="tags">' .. render_tags(node.tags) .. "</span></div>"
  out[#out + 1] = render_description(node.description)
  out[#out + 1] = render_steps(node.steps)
  for _, ex in ipairs(node.examples or {}) do
    out[#out + 1] = render_examples(ex)
  end
  out[#out + 1] = "</section>"
  return table.concat(out)
end

local function render_background(node)
  local out = { '<section class="background">' }
  out[#out + 1] = '<div class="head"><span class="kw">' .. esc(node.keyword) .. "</span>"
    .. '<span class="name">' .. esc(node.name) .. "</span></div>"
  out[#out + 1] = render_description(node.description)
  out[#out + 1] = render_steps(node.steps)
  out[#out + 1] = "</section>"
  return table.concat(out)
end

local function render_rule(node)
  local out = { '<section class="rule">' }
  out[#out + 1] = '<div class="rule-head"><span class="kw">' .. esc(node.keyword) .. "</span>"
    .. esc(node.name) .. "</div>"
  out[#out + 1] = render_description(node.description)
  for _, child in ipairs(node.children or {}) do
    if child.type == "scenario" or child.type == "scenario_outline" then
      out[#out + 1] = render_scenario(child)
    elseif child.type == "background" then
      out[#out + 1] = render_background(child)
    end
  end
  out[#out + 1] = "</section>"
  return table.concat(out)
end

local function render_comments(comments)
  if not comments or #comments == 0 then
    return ""
  end
  local out = { '<section class="comments">' }
  for _, c in ipairs(comments) do
    out[#out + 1] = '<div class="comment"><span class="mark">#</span>' .. esc(c.text) .. "</div>"
  end
  out[#out + 1] = "</section>"
  return table.concat(out)
end

local function render_feature(feature)
  local out = {}
  out[#out + 1] = render_tags(feature.tags)
  out[#out + 1] = '<div class="feature-kw">' .. esc(feature.keyword) .. "</div>"
  out[#out + 1] = '<h1 class="feature-name">' .. esc(feature.name) .. "</h1>"
  out[#out + 1] = render_description(feature.description)
  for _, child in ipairs(feature.children or {}) do
    if child.type == "rule" then
      out[#out + 1] = render_rule(child)
    elseif child.type == "scenario" or child.type == "scenario_outline" then
      out[#out + 1] = render_scenario(child)
    elseif child.type == "background" then
      out[#out + 1] = render_background(child)
    end
  end
  return table.concat(out)
end

--- Render a parsed document to a self-contained HTML page.
-- @param doc table from parser.parse
-- @param opts {file?, hide_comments?, theme?}
function M.render(doc, opts)
  opts = opts or {}
  local theme = opts.theme or "auto"
  local title = opts.file and ('<title>' .. esc(opts.file) .. "</title>") or "<title>Gherkin Preview</title>"

  local banner = ""
  if doc.language and doc.language ~= "en" then
    banner = '<div class="banner">Dialect <code>' .. esc(doc.language)
      .. "</code> — parsed with English keywords; output may be incomplete.</div>"
  end

  local comments = opts.hide_comments and "" or render_comments(doc.comments)
  local body = render_feature(doc.feature) .. comments

  return table.concat({
    "<!doctype html>",
    '<html lang="en" data-theme="' .. esc(theme) .. '">',
    "<head>",
    '<meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1">',
    title,
    "<style>" .. CSS .. "</style>",
    "</head>",
    "<body>",
    '<header class="toolbar">',
    '<span class="file">' .. (opts.file and esc(opts.file) or "gherkin") .. "</span>",
    '<span class="controls"><span class="status"><span class="dot">&#9679;</span> live</span>'
      .. '<button id="theme" title="Toggle theme (auto/light/dark)">&#9681;</button></span>',
    "</header>",
    "<main>",
    banner,
    body,
    "</main>",
    "<script>" .. JS .. "</script>",
    "</body>",
    "</html>",
  }, "\n")
end

return M