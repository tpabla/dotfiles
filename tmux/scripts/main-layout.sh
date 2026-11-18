#!/usr/bin/env bash
# main-vertical that leaves the agenmux sidebar alone: the sidebar keeps its
# width at its edge, and main-pane-width applies to the space that remains.
set -euo pipefail

win="${1:-$(tmux display-message -p '#{window_id}')}"

ids=()
p=-1
while IFS='|' read -r id title; do
  [ "$title" = agenmux ] && p=${#ids[@]}
  ids+=("$id")
done < <(tmux list-panes -t "$win" -F '#{pane_id}|#{pane_title}')

if [ "$p" -lt 0 ] || [ "${#ids[@]}" -lt 2 ]; then
  exec tmux select-layout -t "$win" main-vertical
fi

pos="$(tmux show-options -gqv @agenmux-sidebar-position)"

# select-layout fills cells in pane-index order, so the sidebar must sit at
# the index end matching its edge; adjacent swaps keep the others' order.
if [ "$pos" = right ]; then t=$((${#ids[@]} - 1)); step=1; else t=0; step=-1; fi
while [ "$p" -ne "$t" ]; do
  q=$((p + step))
  tmux swap-pane -d -s "${ids[$p]}" -t "${ids[$q]}"
  tmp="${ids[$p]}"; ids[p]="${ids[$q]}"; ids[q]="$tmp"
  p=$q
done

sidebar="${ids[$p]#%}"
others=()
for i in "${!ids[@]}"; do [ "$i" -ne "$p" ] && others+=("${ids[$i]#%}"); done

read -r W H < <(tmux display-message -p -t "$win" '#{window_width} #{window_height}')
sw="$(tmux show-options -gqv @agenmux-width)"
sw="${sw:-30}"
main_opt="$(tmux show-window-options -gv main-pane-width)"

R=$((W - sw - 1))
if [ "$pos" = right ]; then rx=0; sx=$((R + 1)); else rx=$((sw + 1)); sx=0; fi

if [ "${#others[@]}" -eq 1 ]; then
  rest="${R}x${H},${rx},0,${others[0]}"
else
  case "$main_opt" in
    *%) M=$((R * ${main_opt%\%} / 100)) ;;
    *) M="$main_opt" ;;
  esac
  S=$((R - M - 1))
  stack=("${others[@]:1}")
  k=${#stack[@]}
  sxp=$((rx + M + 1))
  if [ "$k" -eq 1 ]; then
    col="${S}x${H},${sxp},0,${stack[0]}"
  else
    avail=$((H - (k - 1)))
    base=$((avail / k)); extra=$((avail % k)); y=0; cells=()
    for i in "${!stack[@]}"; do
      h=$base; [ "$i" -lt "$extra" ] && h=$((h + 1))
      cells+=("${S}x${h},${sxp},${y},${stack[$i]}")
      y=$((y + h + 1))
    done
    col="${S}x${H},${sxp},0[$(IFS=,; echo "${cells[*]}")]"
  fi
  rest="${M}x${H},${rx},0,${others[0]},${col}"
fi

side="${sw}x${H},${sx},0,${sidebar}"
if [ "$pos" = right ]; then body="${rest},${side}"; else body="${side},${rest}"; fi
layout="${W}x${H},0,0{${body}}"

# tmux's layout checksum
csum=0
for ((i = 0; i < ${#layout}; i++)); do
  c=$(printf '%d' "'${layout:i:1}")
  csum=$(((csum >> 1) + ((csum & 1) << 15) + c))
  csum=$((csum & 0xffff))
done

tmux select-layout -t "$win" "$(printf '%04x' "$csum"),${layout}"
