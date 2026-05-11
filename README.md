# claude-code-semantic-memory

Claude Code **plugin** with bundled **LogosDB** MCP ([`logosdb-mcp-server`](https://www.npmjs.com/package/logosdb-mcp-server)), local embeddings by default, and slash-invoked skills.

Structure follows Anthropic’s **[example-plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/example-plugin)** ([README](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/example-plugin/README.md)): `.claude-plugin/plugin.json`, root **`.mcp.json`**, and **`skills/*/SKILL.md`** (preferred over legacy `commands/*.md`).

## Layout

```
claude-code-semantic-memory/
├── .claude-plugin/
│   └── plugin.json          # metadata + inline mcpServers.logosdb
├── scripts/
│   └── logosdb-mcp-wrap.sh  # sets LOGOSDB_PATH from CLAUDE_PROJECT_DIR, runs npx server
├── .mcp.json                # same MCP block as plugin.json (mirror)
├── commands/
│   └── README.md            # note: slash skills live under skills/
├── skills/
│   ├── semantic-memory/     # model-invoked guidance + CLAUDE.md template
│   │   ├── SKILL.md
│   │   └── .claude/commands/   # optional copy → project /index /search /forget
│   ├── index/               # user-invoked → /index
│   ├── search/              # user-invoked → /search
│   └── forget/              # user-invoked → /forget
└── README.md
```

## Install

```text
/plugin marketplace add jose-compu/claude-code-semantic-memory
/plugin install semantic-memory
```

MCP **`logosdb`** runs **`/bin/sh`** + **`scripts/logosdb-mcp-wrap.sh`** (declared in **`.claude-plugin/plugin.json`** and mirrored in **`.mcp.json`**). The wrapper sets **`LOGOSDB_PATH`** to **`$CLAUDE_PROJECT_DIR/.logosdb`** so user-scoped plugins do not write under the plugin cache cwd ([claude-code#42687](https://github.com/anthropics/claude-code/issues/42687)). One diagnostic line goes to **stderr**; use **`claude --debug`** if tools are missing. Add **`.logosdb/`** to **`.gitignore`**.

**Older Claude Code:** upgrade so **`CLAUDE_PROJECT_DIR`** is set for stdio MCP, or install this plugin with **`--scope project`**.

## Slash commands (skills format)

| Command | Skill |
|---------|--------|
| `/index` | [`skills/index/SKILL.md`](skills/index/SKILL.md) |
| `/search` | [`skills/search/SKILL.md`](skills/search/SKILL.md) |
| `/forget` | [`skills/forget/SKILL.md`](skills/forget/SKILL.md) |

Optional project-only prompts (without the plugin): copy [`skills/semantic-memory/.claude/commands/`](skills/semantic-memory/.claude/commands/) into **`.claude/commands/`** (same idea as upstream LogosDB).

## Model-invoked guidance

[`skills/semantic-memory/SKILL.md`](skills/semantic-memory/SKILL.md) — routing, `CLAUDE.md` snippet, troubleshooting.

## Local development

```bash
cd /path/to/claude-code-semantic-memory
claude --plugin-dir .
```

Then **`/mcp`** or **`logosdb_list`** to confirm the server.

## License

MIT — see [LICENSE](LICENSE).
