#!/bin/bash
# Claude Code statusline: modell · effort · repo · matare for kontext och usage.
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
} <<JQ
$(printf '%s' "$input" | jq -r '
  def pct(v): if (v|type) == "number" then (v|round|tostring) else "-" end;
  def epoch(v):
    if   (v|type) == "number" then (v|floor|tostring)
    elif (v|type) == "string" then (try (v|fromdateiso8601|tostring) catch "-")
    else "-" end;
  (.model.display_name // "-"),
  (.effort.level // "-"),
  (if .fast_mode == true then "fast" else "-" end),
  (if .workspace.repo then (.workspace.repo.owner + "/" + .workspace.repo.name) else "-" end),
  (((.workspace.project_dir // .workspace.current_dir // "") | split("/") | map(select(length>0)) | last) // "-"),
  (.workspace.git_worktree // "-"),
  pct(.context_window.used_percentage),
  pct(.rate_limits.five_hour.used_percentage),
  epoch(.rate_limits.five_hour.resets_at),
  pct(.rate_limits.seven_day.used_percentage),
  epoch(.rate_limits.seven_day.resets_at)
')
JQ

[ "$name" = "-" ] && name="okänd modell"

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

printf '%s' "$out"
