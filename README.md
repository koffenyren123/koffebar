# koffebar

En statusrad för [Claude Code](https://claude.com/claude-code) som visar det viktigaste på en enda rad:

```
◆ Opus · high   mitt-repo   ctx ███▒▒▒ 42%   5h █▒▒▒▒ 18% (16:13)   7d ███▒▒ 55% (fre 03:33)
```

- **Modell** och effort-nivå (plus `1M`-badge och `fast` när det är aktivt)
- **Repo eller mapp** du jobbar i, samt git-worktree om du har en
- **ctx**: hur full kontexten är, med varning vid 70 % (`fylls på`) och 85 % (`NYTT FÖNSTER`)
- **5h** och **7d**: usage-gränserna för 5 timmar och 7 dagar, med stapel, procent och när de nollställs

Staplarna byter färg: grönt under 70 %, gult från 70 %, rött från 90 %.

## Installation

Kräver `jq` (`brew install jq` på macOS, `sudo apt install jq` på Linux).

```bash
git clone https://github.com/koffenyren123/koffebar.git
cd koffebar
./install.sh
```

Installationsskriptet kopierar `statusline.sh` till `~/.claude/`, lägger till nyckeln `statusLine` i `~/.claude/settings.json` utan att röra något annat, och anpassar `date`-anropet om du kör Linux. Starta sedan om Claude Code.

### Manuellt

1. Kopiera `statusline.sh` till `~/.claude/statusline.sh` och gör den körbar.
2. Lägg till i `~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "~/.claude/statusline.sh", "padding": 0 }
```

3. På Linux: byt `date -r "$reset"` mot `date -d @"$reset"` i skriptet.

## Testa

```bash
echo '{"model":{"display_name":"Opus"},"effort":{"level":"high"},"workspace":{"current_dir":"/tmp/demo"},"context_window":{"used_percentage":42},"rate_limits":{"five_hour":{"used_percentage":18,"resets_at":1790000000},"seven_day":{"used_percentage":55,"resets_at":1790300000}}}' | ~/.claude/statusline.sh
```

## Typsnitt

Skriptet använder bara glyfer som finns i Monaco (`█`, `▒`, `◆`, `·`) så att staplarna får rätt bredd i terminalen.

## Licens

MIT
