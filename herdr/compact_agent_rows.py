#!/usr/bin/env python3
"""Rewrite herdr-agent-quota's default (verbose) sidebar rows into a single
compact row per agent: status icon, color-coded agent name, context % used.
Run once right after `herdr plugin action invoke herdr-agent-quota.configure`,
which is what generates the block this replaces."""
import re
import sys

COMPACT = """[ui.sidebar.agents]
row_gap = 1 # herdr-agent-quota
rows = [["state_icon", { token = "$quota_provider", bold = true, dim = false }, { token = "$quota_context", fg = "#9b8fd8", bold = true, dim = false }]]

[ui.sidebar.agents.rows_by_agent]
claude = [["state_icon", { token = "agent", fg = "#c47f6a", bold = true, dim = false }, { token = "$quota_context", fg = "#9b8fd8", bold = true, dim = false }]] # herdr-agent-quota-provider
codex = [["state_icon", { token = "agent", fg = "#7998b7", bold = true, dim = false }, { token = "$quota_context", fg = "#9b8fd8", bold = true, dim = false }]] # herdr-agent-quota-provider
grok = [["state_icon", { token = "agent", fg = "#acb4c3", bold = true, dim = false }, { token = "$quota_context", fg = "#9b8fd8", bold = true, dim = false }]] # herdr-agent-quota-provider
agy = [["state_icon", { token = "agent", fg = "#84b0af", bold = true, dim = false }, { token = "$quota_context", fg = "#9b8fd8", bold = true, dim = false }]] # herdr-agent-quota-provider"""

path = sys.argv[1]
text = open(path).read()

if "sidebar_width" not in text:
    text = text.replace(
        'agent_panel_sort = "spaces"',
        'agent_panel_sort = "spaces"\nsidebar_width = 44',
        1,
    )

# Replace from "[ui.sidebar.agents]" through the last "... # herdr-agent-quota-provider"
# line, however verbose the plugin's default turned out to be.
pattern = re.compile(
    r"\[ui\.sidebar\.agents\].*# herdr-agent-quota-provider\n", re.DOTALL
)
if pattern.search(text):
    text = pattern.sub(COMPACT + "\n", text, count=1)
    open(path, "w").write(text)
    print("compacted agent-quota sidebar rows")
else:
    print("no default agent-quota rows found to compact (already compact, or configure didn't run) — leaving as-is")
