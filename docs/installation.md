# How Installation Works

## Current Method: curl + symlinks

The one-liner fetches `install.sh` and runs it locally:

```
~/.claude/
├── plugins/
│   └── claude-onboarding-agent/   ← full repo cloned here
│       ├── skills/
│       │   ├── onboarding/SKILL.md
│       │   ├── coding-setup/SKILL.md
│       │   └── ...
│       └── .claude-plugin/plugin.json
└── skills/
    ├── onboarding → ../plugins/claude-onboarding-agent/skills/onboarding/   (symlink)
    ├── coding-setup → ...
    └── ...
```

**How Claude Code discovers skills:** it scans `~/.claude/skills/` at session start and loads any `SKILL.md` it finds there. Each skill becomes a `/slash-command` available in every project. The symlinks mean updates (`git pull` in the plugin dir) are picked up immediately without re-running any install step.

The `plugin.json` manifest at `.claude-plugin/plugin.json` declares which skill folders and which slash-command names belong to the plugin. Claude Code doesn't consume this file yet — today it only matters for the future plugin system.

**Update:** re-run the same curl command. The script detects an existing clone and does `git pull` instead of re-cloning.

**Uninstall:** the uninstall script removes all symlinks in `~/.claude/skills/` that point into the plugin directory, then deletes the clone.

| Aspekt | Bewertung |
|--------|-----------|
| Transparenz | Vollständig — `install.sh` ist lesbar, jeder Schritt nachvollziehbar |
| Sicherheitsmodell | Kein Sandboxing — das Skript läuft mit vollen Shell-Rechten des Nutzers |
| Update-Kontrolle | Explizit — `git pull` nur wenn der Nutzer es auslöst, kein Auto-Update |
| Abhängigkeiten | `git` und `bash` müssen im System vorhanden sein |
| Wiederherstellbarkeit | Einfach und vollständig transparent — Symlinks entfernen, Verzeichnis löschen |

---

## Future Method: Claude Plugin Marketplace

Anthropic is building a first-class plugin system for Claude Code. When it ships, installation will be a single command:

```
/plugin install claude-onboarding-agent
```

Under the hood, Claude Code will:

1. Look up the plugin in a central registry (similar to npm or Homebrew)
2. Download and verify the plugin archive
3. Register skills, commands, permissions, and MCP integrations declared in `plugin.json`
4. Make all slash-commands available immediately — no shell script, no symlinks, no `~/.claude/skills/` directory required

The `plugin.json` file in this repo is already structured to be compatible with that future format. The fields `skills[]`, `commands[]`, `author`, `version`, and `homepage` mirror what the plugin registry will expect. When the marketplace launches, this plugin should require little or no changes to be listable.

**Key difference from today:** the current curl approach requires the user's shell to run a bash script with `git` and filesystem access. The plugin system will handle all of that inside Claude Code itself, with sandboxing and signature verification — closer to how browser extensions or VS Code extensions work today.

| Aspekt | Bewertung |
|--------|-----------|
| Transparenz | Geringer — Installation läuft innerhalb Claude Code, kein lesbares Shell-Skript |
| Sicherheitsmodell | Sandboxed — Claude Code verifiziert Signaturen, keine Shell-Rechte erforderlich |
| Update-Kontrolle | Über Claude Codes eigenen Mechanismus — Details noch offen |
| Abhängigkeiten | Nur Claude Code selbst |
| Wiederherstellbarkeit | `/plugin uninstall` — einfach, aber weniger transparent als manuelles Löschen |
