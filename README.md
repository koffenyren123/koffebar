# koffebar

En statusrad för [Claude Code](https://claude.com/claude-code) som visar det viktigaste på en enda rad:

```
◆ Opus · high   mitt-repo   ctx ███▒▒▒ 42%   5h █▒▒▒▒ 18% (16:13)   7d ███▒▒ 55% (fre 03:33)   💧 0,37 L (≈ ölburk)
```

- **Modell** och effort-nivå (plus `1M`-badge och `fast` när det är aktivt)
- **Repo eller mapp** du jobbar i, samt git-worktree om du har en
- **ctx**: hur full kontexten är, med varning vid 70 % (`fylls på`) och 85 % (`NYTT FÖNSTER`)
- **5h** och **7d**: usage-gränserna för 5 timmar och 7 dagar, med stapel, procent och när de nollställs
- **💧**: ett hypotetiskt estimat av hur mycket vatten konversationen har förbrukat, i liter, med en jämförelse (tesked, ölburk, mjölkpaket, hink, badkar ... Vättern, Östersjön, Stilla havet)

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
echo '{"model":{"display_name":"Opus"},"effort":{"level":"high"},"workspace":{"current_dir":"/tmp/demo"},"context_window":{"used_percentage":42},"rate_limits":{"five_hour":{"used_percentage":18,"resets_at":1790000000},"seven_day":{"used_percentage":55,"resets_at":1790300000}},"cost":{"total_cost_usd":3.7}}' | ~/.claude/statusline.sh
```

## Vattenestimatet

Siffran är en grov uppskattning, inte en mätning. Den bygger på sessionens kostnad (`cost.total_cost_usd`), som är det enda värdet Claude Code skickar som ackumuleras över hela konversationen, och speglar både antal tokens och modellstorlek. Standardfaktorn är **0,1 liter per dollar**, härledd ur ungefär 1 joule per token, ungefär 2 liter vatten per kWh (kylning plus elproduktion) och ungefär 5 dollar per miljon tokens.

Justera eller stäng av med miljövariabler i din shell-profil:

```bash
export KOFFEBAR_L_PER_USD=0.3   # egen faktor, liter per dollar
export KOFFEBAR_WATER=0         # dölj vattendroppen helt
```

Jämförelsen väljer det största referensobjektet som ryms i volymen och visar en multiplikator när det behövs, till exempel `5 × mjölkpaket`.

## Typsnitt

Skriptet använder bara glyfer som finns i Monaco (`█`, `▒`, `◆`, `·`) så att staplarna får rätt bredd i terminalen.

## Licens

MIT
