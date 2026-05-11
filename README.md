# claude-code-semantic-memory

Claude Code **plugin** with bundled **LogosDB** MCP ([`logosdb-mcp-server`](https://www.npmjs.com/package/logosdb-mcp-server)), local embeddings by default, and slash-invoked skills.

Structure follows Anthropic’s **[example-plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/example-plugin)** ([README](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/example-plugin/README.md)): `.claude-plugin/plugin.json`, root **`.mcp.json`**, and **`skills/*/SKILL.md`** (preferred over legacy `commands/*.md`).

## Layout

```
claude-code-semantic-memory/
├── .claude-plugin/
│   └── plugin.json          # metadata + "mcpServers": "./.mcp.json"
├── .mcp.json                # logosdb MCP server
├── commands/
│   └── README.md            # note: slash skills live under skills/
├── skills/
│   ├── semantic-memory/     # model-invoked guidance + CLAUDE.md template
│   │   ├── SKILL.md
│   │   └── .claude/commands/   # optional copy → project /index /search /forget
│   ├── memory-index/        # user-invoked → /memory-index
│   ├── memory-search/       # user-invoked → /memory-search
│   └── memory-forget/       # user-invoked → /memory-forget
└── README.md
```

## Install

```text
/plugin marketplace add jose-compu/claude-code-semantic-memory
/plugin install semantic-memory
```

MCP is wired from **`.mcp.json`** via **`plugin.json`** (`mcpServers`). Default **`LOGOSDB_PATH`**: **`${CLAUDE_PLUGIN_DATA}/.logosdb`**.

## Slash commands (skills format)

| Command | Skill |
|---------|--------|
| `/memory-index` | [`skills/memory-index/SKILL.md`](skills/memory-index/SKILL.md) |
| `/memory-search` | [`skills/memory-search/SKILL.md`](skills/memory-search/SKILL.md) |
| `/memory-forget` | [`skills/memory-forget/SKILL.md`](skills/memory-forget/SKILL.md) |

Optional short names **`/index`**, **`/search`**, **`/forget`**: copy [`skills/semantic-memory/.claude/commands/`](skills/semantic-memory/.claude/commands/) into your project **`.claude/commands/`**.

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
