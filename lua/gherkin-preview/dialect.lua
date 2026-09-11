-- Gherkin dialect definitions.
--
-- Only English ("en") is bundled. Extend or replace it via
-- require("gherkin-preview").setup({ dialect = { ... } }); the shape must
-- match `M.en` below.

local M = {}

M.en = {
  name = "en",
  keywords = {
    feature = { "Feature", "Business Need", "Ability" },
    background = { "Background" },
    rule = { "Rule" },
    scenario = { "Scenario", "Example" },
    scenario_outline = { "Scenario Outline", "Scenario Template" },
    examples = { "Examples", "Scenarios" },
  },
  steps = {
    given = { "Given" },
    when = { "When" },
    ["then"] = { "Then" },
    ["and"] = { "And" },
    but = { "But" },
  },
  star = "*",
}

M.current = M.en

return M