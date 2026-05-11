# claude-code-semantic-memory

Custom [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) skill (plugin layout aligned with [academic-research-skills](https://github.com/Imbad0202/academic-research-skills): `.claude-plugin/` manifest + `SKILL.md` under `semantic-memory/`).

## Install (plugin)

```text
/plugin marketplace add jose-compu/claude-code-semantic-memory
/plugin install semantic-memory
```

## Skills

| Skill | Purpose |
|-------|---------|
| [semantic-memory](semantic-memory/SKILL.md) | LogosDB MCP (`logosdb-mcp-server`), default **local** embeddings, `.claude/mcp.json`, **required** `.claude/commands/` (`/index`, `/search`, `/forget` — [semantic-memory/.claude/commands/](semantic-memory/.claude/commands/)), **CLAUDE.md** habits |

## Traditional install

Clone this repository and symlink or copy the skill directory into your Claude Code skills path, or open the repo as a plugin source per your client’s docs.

## License

MIT — see [LICENSE](LICENSE).
