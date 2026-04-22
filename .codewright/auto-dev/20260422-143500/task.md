# Task: Upgrade Skill

## Original Request
Erstelle einen Upgrade-Skill für Codewright, der je nach Plattform (Claude Code / OpenCode) die Skills & Co auf die neueste Version upgradet.

## Key Findings
- Claude Code: Plugin-Marketplace-basiert (.claude-plugin/plugin.json, v0.3.9)
- OpenCode: setup.sh-basiert (platforms/opencode/, v0.1.0)
- Keine bestehende Plattformerkennung
- GitHub Releases API für Versionsprüfung
- Dateisystem-basierte Plattformerkennung am zuverlässigsten
