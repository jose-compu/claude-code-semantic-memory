# Legacy `commands/` layout

This plugin follows Anthropic’s [example-plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/example-plugin): **user-invoked slash commands live under `skills/<name>/SKILL.md`** (preferred).

| Slash command | Skill path |
|---------------|------------|
| `/memory-index` | [`skills/memory-index/SKILL.md`](../skills/memory-index/SKILL.md) |
| `/memory-search` | [`skills/memory-search/SKILL.md`](../skills/memory-search/SKILL.md) |
| `/memory-forget` | [`skills/memory-forget/SKILL.md`](../skills/memory-forget/SKILL.md) |

The old `commands/*.md` files were removed to avoid duplicating the same three commands.
