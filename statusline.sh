#!/bin/bash
# Claude Code statusline: modell · effort · repo · matare for kontext, usage och vatten.
#
# Tva plattformsdetaljer:
#  1. Endast glyfer som finns i Monaco anvands (U+2588 █, U+2592 ▒, ◆, ·).
#     Saknade glyfer substitueras fran annat typsnitt och far fel bredd.
#  2. `var="$var<multibyte-literal>"` tappar forsta byten i denna bash.
#     Darfor byggs staplarna med teckenbaserad substrang, aldrig loop-append.

input=$(cat)

{
  IFS= read -r name; IFS= read -r effort; IFS= read -r fast
  IFS= read -r repo; IFS= read -r proj;   IFS= read -r wt
  IFS= read -r ctx
  IFS= read -r h5;  IFS= read -r h5r
  IFS= read -r d7;  IFS= read -r d7r
  IFS= read -r h2o; IFS= read -r h2oref
} <<JQ
$(printf '%s' "$input" | jq -r '
  # Strangfalt rensas fran radbrytningar och kontrolltecken (inkl. ESC) sa att
  # faltordningen inte kan forskjutas och inget kan injiceras i terminalen.
  def clean: (if type == "string" then . else tostring end)
             | explode | map(select(. >= 32 and . != 127)) | implode;
  def pct(v): if (v|type) == "number" then (v|round|tostring) else "-" end;
  def epoch(v):
    if   (v|type) == "number" then (v|floor|tostring)
    elif (v|type) == "string" then (try (v|fromdateiso8601|tostring) catch "-")
    else "-" end;

  # --- Vattenestimat ---
  # Hypotetiskt: sessionens kostnad (det enda som ackumuleras over hela
  # konversationen) gangras med liter per dollar. Standard 0,1 L/USD bygger pa
  # ~1 J/token, ~2 L vatten/kWh (kylning + elproduktion) och ~5 USD/M tokens.
  # Justera med KOFFEBAR_L_PER_USD, stang av med KOFFEBAR_WATER=0.
  def sv: tostring | explode | map(if . == 46 then 44 else . end) | implode;   # "." -> ","
  def thousands: tostring | explode | reverse
    | [ range(0; length) as $i | .[$i], (if ($i+1) % 3 == 0 and ($i+1) < length then 32 else empty end) ]
    | reverse | implode;
  def fmt_l:
    if   . < 0.01 then "<0,01 L"
    elif . < 10   then (((. * 100 | round) / 100 | sv) + " L")
    elif . < 100  then (((. * 10 | round) / 10 | sv) + " L")
    elif . < 1e6  then ((round | thousands) + " L")
    elif . < 1e9  then (((. / 1e6 * 10 | round) / 10 | sv) + " milj. L")
    elif . < 1e12 then (((. / 1e9 * 10 | round) / 10 | sv) + " mdr L")
    else               (((. / 1e12 | round) | thousands) + " km³") end;
  def refs: [
    ["tesked", 0.005], ["espresso", 0.03], ["kaffekopp", 0.2], ["ölburk", 0.33],
    ["vinflaska", 0.75], ["mjölkpaket", 1], ["hink", 10], ["badkar", 150],
    ["bubbelpool", 1500], ["tankbil", 30000], ["olympisk simbassäng", 2.5e6],
    ["Globen", 6.05e8], ["Hjälmaren", 3e12], ["Mälaren", 1.4e13], ["Vättern", 7.4e13],
    ["Vänern", 1.53e14], ["Östersjön", 2.17e16], ["Medelhavet", 3.75e18],
    ["Atlanten", 3.1e20], ["Stilla havet", 7.1e20] ];
  def ref_for($l): ((refs | map(select(.[1] <= $l)) | last) // refs[0])
    | . as [$n, $v] | (($l / $v) | round) as $k
    | if $k >= 2 then "\($k) × \($n)" else $n end;
  def liters:
    if ($ENV.KOFFEBAR_WATER // "1") == "0" then null
    elif (.cost.total_cost_usd | type) != "number" then null
    else (.cost.total_cost_usd * (($ENV.KOFFEBAR_L_PER_USD // "0.1") | (try tonumber catch 0.1))) end;
  def water:    (liters | if . == null then "-" else fmt_l end);
  def waterref: (liters | if . == null then "-" else ref_for(.) end);

  ((.model.display_name // "-") | clean),
  ((.effort.level // "-") | clean),
  (if .fast_mode == true then "fast" else "-" end),
  ((if .workspace.repo then ((.workspace.repo.owner|tostring) + "/" + (.workspace.repo.name|tostring)) else "-" end) | clean),
  ((((.workspace.project_dir // .workspace.current_dir // "") | tostring | split("/") | map(select(length>0)) | last) // "-") | clean),
  ((.workspace.git_worktree // "-") | clean),
  pct(.context_window.used_percentage),
  pct(.rate_limits.five_hour.used_percentage),
  epoch(.rate_limits.five_hour.resets_at),
  pct(.rate_limits.seven_day.used_percentage),
  epoch(.rate_limits.seven_day.resets_at),
  water, waterref
')
JQ

# Varden som anvands i aritmetik maste vara rena heltal, annars "-".
num_or_dash() { case "$1" in ''|*[!0-9]*) printf '%s' '-' ;; *) printf '%s' "$1" ;; esac; }
ctx=$(num_or_dash "$ctx")
h5=$(num_or_dash "$h5");   h5r=$(num_or_dash "$h5r")
d7=$(num_or_dash "$d7");   d7r=$(num_or_dash "$d7r")

# Tomma strangfalt (t.ex. om jq misslyckades) behandlas som saknade.
for v in effort fast repo proj wt h2o h2oref; do [ -z "${!v}" ] && eval "$v='-'"; done

[ -z "$name" ] || [ "$name" = "-" ] && name="okänd modell"

# "Opus 5 (1M context)" -> namn "Opus 5" + badge "1M"
badge=""
case "$name" in
  *\ \(*context\)) badge="${name##*\(}"; badge="${badge%% *}"; name="${name%% (*}" ;;
esac

GAP='   '
BAR_FULL='████████'
BAR_TRACK='▒▒▒▒▒▒▒▒'

lvl_color() {
  if   [ "$1" -ge 90 ]; then printf '1;91'
  elif [ "$1" -ge 70 ]; then printf '1;33'
  else printf '32'; fi
}

bar() {   # bar <pct> <bredd> <fargkod>
  local p=$1 w=$2 c=$3 f e
  f=$(( (p * w + 50) / 100 ))
  [ "$f" -gt "$w" ] && f=$w
  [ "$f" -lt 0 ] && f=0
  e=$(( w - f ))
  printf '\033[%sm%s\033[90m%s\033[0m' "$c" "${BAR_FULL:0:$f}" "${BAR_TRACK:0:$e}"
}

# --- identitet ---
out=$(printf '\033[1;35m◆ %s\033[0m' "$name")
[ -n "$badge" ]      && out="$out$(printf ' \033[36m· %s\033[0m' "$badge")"
[ "$effort" != "-" ] && out="$out$(printf ' \033[36m· %s\033[0m' "$effort")"
[ "$fast"   != "-" ] && out="$out$(printf ' \033[1;33m· fast\033[0m')"

# --- plats ---
if [ "$repo" != "-" ]; then
  out="$out$GAP$(printf '\033[1;32m%s\033[0m' "$repo")"
elif [ "$proj" != "-" ]; then
  out="$out$GAP$(printf '\033[32m%s\033[0m' "$proj")"
fi
[ "$wt" != "-" ] && out="$out$(printf ' \033[32m[%s]\033[0m' "$wt")"

# --- kontext ---
if [ "$ctx" != "-" ]; then
  c=$(lvl_color "$ctx")
  out="$out$GAP$(printf '\033[37mctx\033[0m ')$(bar "$ctx" 6 "$c")$(printf ' \033[%sm%s%%\033[0m' "$c" "$ctx")"
  if [ "$ctx" -ge 85 ]; then
    out="$out$(printf ' \033[1;97;41m NYTT FÖNSTER \033[0m')"
  elif [ "$ctx" -ge 70 ]; then
    out="$out$(printf ' \033[1;33mfylls på\033[0m')"
  fi
fi

# --- usage-limits ---
gauge() {
  local label=$1 val=$2 reset=$3 fmt=$4 c when=""
  [ "$val" = "-" ] && return
  c=$(lvl_color "$val")
  if [ "$reset" != "-" ]; then
    when=$(date -r "$reset" +"$fmt" 2>/dev/null)
    [ -n "$when" ] && when=$(printf ' \033[90m(%s)\033[0m' "$when")
  fi
  printf '%s%s %s %s%s' "$GAP" "$(printf '\033[37m%s\033[0m' "$label")" \
    "$(bar "$val" 5 "$c")" "$(printf '\033[%sm%s%%\033[0m' "$c" "$val")" "$when"
}
out="$out$(gauge 5h "$h5" "$h5r" '%H:%M')$(gauge 7d "$d7" "$d7r" '%a %H:%M')"

# --- vatten (hypotetiskt estimat, se jq-delen) ---
if [ "$h2o" != "-" ]; then
  out="$out$GAP$(printf '\033[37mh2o\033[0m \033[36m%s\033[0m' "$h2o")"
  [ "$h2oref" != "-" ] && out="$out$(printf ' \033[90m(≈ %s)\033[0m' "$h2oref")"
fi

printf '%s' "$out"
