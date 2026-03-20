---
description: Audit teammates' OpenCode configs for ideas to adopt or adapt
---

Audit teammate OpenCode configurations and compare them against my global config.

### Instructions

1. **Load the skill**: Load the `teammate-config-audit` skill for the full workflow and report template.
2. **Pull latest**: Pull the latest changes for each teammate repo listed in the skill.
3. **Scan all teammates** (or just `$ARGUMENTS` if a specific teammate name is provided).
4. **Build inventory**: For each teammate, inventory their skills, commands, agents, plugins, MCP config, and AGENTS.md patterns.
5. **Compare**: Compare everything found against my global config at `~/.config/opencode/`.
6. **Generate report**: Produce the structured audit report with ADOPT / ADAPT / INSPIRE / SKIP / CONFLICT classifications.
7. **Discuss**: Present the report and wait for my input before making any changes.
