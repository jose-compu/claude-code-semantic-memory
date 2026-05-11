# Legacy `commands/` layout

This plugin follows Anthropic’s [example-plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/example-plugin): **user-invoked slash commands live under `skills/<name>/SKILL.md`**.

| Slash command | Skill path |
|---------------|------------|
| `/index` | [`skills/index/SKILL.md`](../skills/index/SKILL.md) |
| `/search` | [`skills/search/SKILL.md`](../skills/search/SKILL.md) |
| `/forget` | [`skills/forget/SKILL.md`](../skills/forget/SKILL.md) |

There are no `commands/*.md` entrypoints here (only this README).
