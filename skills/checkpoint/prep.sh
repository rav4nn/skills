#!/bin/sh
# Checkpoint helper: one Bash call per mode.
#   prep.sh stop [TOPIC [PROJECT]]  write: make DIR, point this terminal's relay at it, list + stop dev servers
#   prep.sh find [WORD...]          resume: this terminal's relay pointer + newest briefings (filtered by WORDs)
#   prep.sh                         list dev servers only
H=${HANDOFFS:-$HOME/.claude/handoffs}
PANE=${CMUX_SURFACE_ID:-${TERM_SESSION_ID:-noterm}}
G=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
R=${G:+$(dirname "$G")}; R=${R:-$PWD}          # main repo root (worktree-safe), else cwd
PROJECT=$(basename "$R")

if [ "$1" = find ]; then
  shift
  P=$(cat "$H/.relay/$PANE" 2>/dev/null)
  [ -f "$P/briefing.md" ] || P=""
  echo "POINTER=$P"
  echo "PROJECT=$PROJECT"
  list=$(ls -t "$H"/*/*/briefing.md 2>/dev/null)
  for w; do list=$(printf '%s\n' "$list" | grep -i -- "$w"); done
  echo "<briefings newest-first>"
  printf '%s\n' "$list" | head -8 | while IFS= read -r b; do
    [ -n "$b" ] && echo "$(stat -f %Sm -t "%Y-%m-%d %H:%M" "$b" 2>/dev/null || stat -c %y "$b" | cut -c1-16) | $(dirname "$b")"
  done
  echo "</briefings>"
  exit 0
fi

[ -n "$3" ] && PROJECT=$3
echo "PROJECT=$PROJECT"
echo "ROOT=$R"
if [ "$1" = stop ] && [ -n "$2" ]; then
  DIR="$H/$PROJECT/$(date +%F)-$2"
  mkdir -p "$DIR" "$H/.relay" && echo "$DIR" > "$H/.relay/$PANE"
  echo "DIR=$DIR"
fi

# A dev server = a TCP listener whose cwd sits under ROOT (or one of its worktrees).
# OS and app services have cwd "/". A container ROOT (not a git repo) can hold
# other terminals' servers, so there the script only lists; the agent stops its own.
roots=$R
[ -n "$G" ] && roots=$(git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p')
if [ "$1" = stop ] && [ -n "$G" ]; then mode=stopped; else mode=list-only; fi
echo "<dev-servers mode=\"$mode\">"
pids=""
for pid in $(lsof -iTCP -sTCP:LISTEN -P -n -Fp 2>/dev/null | sed -n 's/^p//p' | sort -u); do
  cwd=$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')
  printf '%s\n' "$roots" | while IFS= read -r r; do case "$cwd/" in "$r"/*) echo y;; esac; done | grep -q y || continue
  cmd=$(ps -p "$pid" -o command=)
  # ponytail: substring match keeps MCP servers of live sessions alive; tighten if a project named *mcp* needs a stop
  case "$cmd" in *mcp*) continue;; esac
  ports=$(lsof -a -p "$pid" -iTCP -sTCP:LISTEN -P -n -Fn | sed -n 's/^n.*://p' | sort -u | paste -sd, -)
  echo "$pid | $ports | $cwd | $cmd"
  pids="$pids $pid"
done
echo "</dev-servers>"

[ "$mode" = stopped ] && [ -n "$pids" ] || exit 0
kill $pids 2>/dev/null
for _ in 1 2 3 4; do
  alive=""
  for p in $pids; do kill -0 "$p" 2>/dev/null && alive="$alive $p"; done
  [ -z "$alive" ] && exit 0
  sleep 0.5
done
kill -9 $alive 2>/dev/null
exit 0
