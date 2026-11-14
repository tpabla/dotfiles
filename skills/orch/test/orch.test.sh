#!/bin/sh
# Tests for scripts/orch and scripts/install-hooks against fake hc, herdr-app and herdr.
# Run: sh test/orch.test.sh
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ORCH="$ROOT/scripts/orch"
PASS=0 FAIL=0

# Each fake answers from $FAKE/<cli>-<args joined by _>.json, or .N.json in order across calls,
# and logs every call to $FAKE/log.
make_fakes() {
  FAKE=$(mktemp -d)
  mkdir -p "$FAKE/bin"
  cat >"$FAKE/bin/fake" <<'EOF'
#!/bin/sh
cli=$(basename "$0")
printf '%s %s\n' "$cli" "$*" >>"$FAKE/log"
key="$cli"
for a in "$@"; do
  case $a in --*) break ;; esac
  key="${key}_$a"
done
n=$(cat "$FAKE/count-$key" 2>/dev/null || echo 0); n=$((n + 1)); echo $n >"$FAKE/count-$key"
if [ -f "$FAKE/$key.$n.json" ]; then cat "$FAKE/$key.$n.json"
elif [ -f "$FAKE/$key.json" ]; then cat "$FAKE/$key.json"
else
  last=$(ls "$FAKE"/"$key".*.json 2>/dev/null | sort -t. -k2 -n | tail -n 1)
  if [ -n "$last" ]; then cat "$last"; else echo '{}'; fi
fi
EOF
  chmod +x "$FAKE/bin/fake"
  for c in hc herdr-app herdr; do ln -s fake "$FAKE/bin/$c"; done
  export FAKE PATH="$FAKE/bin:$PATH" ORCH_POLL=0
  unset HERDR_ENV HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID HC_TERMINAL_ID
}

fixture() { cat >"$FAKE/$1.json"; }
log() { cat "$FAKE/log" 2>/dev/null; }

app_env() {
  export HC_TERMINAL_ID=t1
  fixture hc_get_t1 <<'EOF'
{"address":"t1","turn":3,"labels":{"herdr.space":"sp1","herdr.tab":"tb1"}}
EOF
  fixture herdr-app_ls <<'EOF'
{"spaces":[{"id":"sp1","name":"My API (v2)","tabs":[
  {"id":"tb1","name":"x","terminals":[{"terminal":"t1"}]},
  {"id":"tb2","name":"w","terminals":[{"terminal":"t2"}]}]}]}
EOF
}

tui_env() {
  export HERDR_ENV=1 HERDR_PANE_ID=w1:p1 HERDR_TAB_ID=w1:t1 HERDR_WORKSPACE_ID=w1
  fixture herdr_workspace_get_w1 <<'EOF'
{"result":{"workspace":{"workspace_id":"w1","label":"Fortress"}}}
EOF
}

eq() { if [ "$1" = "$2" ]; then return 0; fi; echo "    expected: $2"; echo "    actual:   $1"; return 1; }
has() { if printf '%s' "$1" | grep -qF -- "$2"; then return 0; fi; echo "    missing: $2"; echo "    in: $1"; return 1; }
lacks() { if printf '%s' "$1" | grep -qF -- "$2"; then echo "    unexpected: $2"; return 1; fi; return 0; }

run_test() {
  name=$1
  out=$( (make_fakes; cd "$FAKE" || exit 1; "$name") 2>&1 )
  if [ $? -eq 0 ]; then PASS=$((PASS + 1)); echo "ok   $name"
  else FAIL=$((FAIL + 1)); echo "FAIL $name"; printf '%s\n' "$out"; fi
}

# slug and env -------------------------------------------------------------------

test_slug() {
  eq "$("$ORCH" slug "My API (v2)")" "my-api-v2" &&
  eq "$("$ORCH" slug "Fortress")" "fortress" &&
  eq "$("$ORCH" slug "  --dotfiles--  ")" "dotfiles" &&
  eq "$("$ORCH" slug "~")" ""
}

test_env_detection() {
  eq "$("$ORCH" env)" "none" &&
  eq "$(HC_TERMINAL_ID=t1 "$ORCH" env)" "herdr-app" &&
  eq "$(HERDR_ENV=1 HERDR_PANE_ID=w1:p1 "$ORCH" env)" "tui"
}

# project ------------------------------------------------------------------------

test_project_from_app_space_name() {
  app_env
  eq "$("$ORCH" project)" "my-api-v2"
}

test_project_from_tui_workspace_label() {
  tui_env
  eq "$("$ORCH" project)" "fortress"
}

test_project_falls_back_to_repo_name_for_unlabelled_workspace() {
  tui_env
  fixture herdr_workspace_get_w1 <<'EOF'
{"result":{"workspace":{"label":"~"}}}
EOF
  mkdir -p "$FAKE/Cool Repo" && cd "$FAKE/Cool Repo" && git init -q . &&
  eq "$("$ORCH" project)" "cool-repo"
}

test_project_uses_main_repo_name_inside_a_worktree() {
  tui_env
  fixture herdr_workspace_get_w1 <<'EOF'
{"result":{"workspace":{"label":"3"}}}
EOF
  mkdir -p "$FAKE/mainrepo" && cd "$FAKE/mainrepo" && git init -q . &&
  git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init &&
  git worktree add -q "$FAKE/wt-feature" 2>/dev/null && cd "$FAKE/wt-feature" &&
  eq "$("$ORCH" project)" "mainrepo"
}

# claim and sync -----------------------------------------------------------------

test_claim_app_labels_self_and_renames_tab() {
  app_env
  eq "$("$ORCH" claim)" "my-api-v2" &&
  has "$(log)" "hc label t1 orch=my-api-v2 orch.role=orchestrator" &&
  has "$(log)" "herdr-app do tab.rename --id tb1 --name my-api-v2 orchestrator" &&
  lacks "$(log)" "space.rename"
}

test_claim_app_with_a_different_name_renames_the_space() {
  app_env
  eq "$("$ORCH" claim "Billing")" "billing" &&
  has "$(log)" "herdr-app do space.rename --id sp1 --name Billing" &&
  has "$(log)" "hc label t1 orch=billing orch.role=orchestrator"
}

test_claim_app_with_the_space_name_does_not_rename_the_space() {
  app_env
  "$ORCH" claim "my-api-v2" >/dev/null &&
  lacks "$(log)" "space.rename"
}

test_claim_tui_renames_tab_and_keeps_a_labelled_workspace() {
  tui_env
  eq "$("$ORCH" claim)" "fortress" &&
  has "$(log)" "herdr tab rename w1:t1 fortress orchestrator" &&
  lacks "$(log)" "workspace rename"
}

test_claim_tui_labels_an_unlabelled_workspace() {
  tui_env
  fixture herdr_workspace_get_w1 <<'EOF'
{"result":{"workspace":{"label":"~"}}}
EOF
  mkdir -p "$FAKE/proj" && cd "$FAKE/proj" &&
  eq "$("$ORCH" claim)" "proj" &&
  has "$(log)" "herdr workspace rename w1 proj"
}

test_sync_unchanged() {
  app_env
  fixture hc_get_t1 <<'EOF'
{"address":"t1","labels":{"herdr.space":"sp1","herdr.tab":"tb1","orch":"my-api-v2"}}
EOF
  eq "$("$ORCH" sync)" "unchanged my-api-v2" &&
  lacks "$(log)" "hc label"
}

test_sync_after_space_rename_relabels_self_and_workers() {
  app_env
  fixture hc_get_t1 <<'EOF'
{"address":"t1","labels":{"herdr.space":"sp1","herdr.tab":"tb1","orch":"old-name"}}
EOF
  fixture hc_ls <<'EOF'
{"terminals":[{"address":"t1"},{"address":"t2"},{"address":"t3"}]}
EOF
  fixture hc_get_t2 <<'EOF'
{"address":"t2","labels":{"orch":"old-name","orch.role":"worker"}}
EOF
  fixture hc_get_t3 <<'EOF'
{"address":"t3","labels":{"orch":"other","orch.role":"worker"}}
EOF
  eq "$("$ORCH" sync)" "renamed old-name -> my-api-v2" &&
  has "$(log)" "hc label t1 orch=my-api-v2 orch.role=orchestrator" &&
  has "$(log)" "hc label t2 orch=my-api-v2" &&
  lacks "$(log)" "hc label t3" &&
  has "$(log)" "tab.rename --id tb1 --name my-api-v2 orchestrator"
}

test_sync_before_claim_fails() {
  app_env
  ! "$ORCH" sync 2>/dev/null
}

# workers ------------------------------------------------------------------------

test_workers_app_lists_only_this_projects_workers() {
  app_env
  fixture hc_get_t1 <<'EOF'
{"address":"t1","labels":{"orch":"p","orch.role":"orchestrator"}}
EOF
  fixture hc_ls <<'EOF'
{"terminals":[{"address":"t1"},{"address":"t2"},{"address":"t3"}]}
EOF
  fixture hc_get_t2 <<'EOF'
{"address":"t2","name":"fix-a","status":{"state":"done"},"labels":{"orch":"p","orch.role":"worker","orch.item":"A","orch.status":"ready-for-review - done"}}
EOF
  fixture hc_get_t3 <<'EOF'
{"address":"t3","name":"other","labels":{"orch":"q","orch.role":"worker"}}
EOF
  out=$("$ORCH" workers)
  eq "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" "1" &&
  eq "$(printf '%s' "$out" | jq -r '[.address,.name,.item,.state,.status] | join("|")')" "t2|fix-a|A|done|ready-for-review - done"
}

test_workers_tui_lists_labelled_tabs() {
  tui_env
  fixture herdr_tab_list <<'EOF'
{"result":{"tabs":[{"tab_id":"w1:t1","label":"fortress orchestrator"},{"tab_id":"w1:t2","label":"work: FRT-1","agent_status":"working"},{"tab_id":"w1:t3","label":"review: FRT-2 #12","agent_status":"done"}]}}
EOF
  out=$("$ORCH" workers)
  eq "$(printf '%s' "$out" | jq -r .tab | tr '\n' ' ')" "w1:t2 w1:t3 "
}

# spawn --------------------------------------------------------------------------

test_spawn_app_runs_labels_keeps_and_renames_the_tab() {
  app_env
  fixture hc_get_t1 <<'EOF'
{"address":"t1","labels":{"herdr.space":"sp1","herdr.tab":"tb1","orch":"p"}}
EOF
  fixture hc_run <<'EOF'
{"address":"t2","name":"fix-a","state":"live","turn":0}
EOF
  printf 'Do the thing.\nCarefully.' >brief.md
  out=$("$ORCH" spawn --name fix-a --cwd "$FAKE" --item "FRT-1" --tab "work: FRT-1" --brief-file brief.md)
  eq "$out" '{"address":"t2","name":"fix-a","tab":"tb2"}' &&
  has "$(log)" "hc run --bg --json --keep --outlive-parent --name fix-a --parent t1 --label orch=p --label orch.role=worker --label orch.item=FRT-1 --label herdr.space=sp1 --cwd $FAKE -- claude Do the thing." &&
  has "$(log)" "herdr-app do terminal.keep --terminal t2" &&
  has "$(log)" "herdr-app do tab.rename --id tb2 --name work: FRT-1"
}

test_spawn_app_resume_passes_the_session() {
  app_env
  fixture hc_get_t1 <<'EOF'
{"address":"t1","labels":{"herdr.space":"sp1","orch":"p"}}
EOF
  fixture hc_run <<'EOF'
{"address":"t2"}
EOF
  "$ORCH" spawn --name fix-a --cwd "$FAKE" --item A --tab "work: A" --resume abc-123 >/dev/null &&
  has "$(log)" "-- claude --resume abc-123"
}

test_spawn_app_waits_for_the_tab_to_appear() {
  app_env
  fixture hc_get_t1 <<'EOF'
{"address":"t1","labels":{"herdr.space":"sp1","herdr.tab":"tb1","orch":"p"}}
EOF
  fixture hc_run <<'EOF'
{"address":"t9"}
EOF
  fixture herdr-app_ls.1 <<'EOF'
{"spaces":[{"id":"sp1","tabs":[]}]}
EOF
  fixture herdr-app_ls.2 <<'EOF'
{"spaces":[{"id":"sp1","tabs":[{"id":"tb9","terminals":[{"terminal":"t9"}]}]}]}
EOF
  rm -f "$FAKE/herdr-app_ls.json"
  printf 'x' >b.md
  out=$("$ORCH" spawn --name n --cwd "$FAKE" --item A --tab "work: A" --brief-file b.md)
  eq "$(printf '%s' "$out" | jq -r .tab)" "tb9"
}

test_spawn_rejects_bad_input() {
  app_env
  printf 'x' >b.md
  ! "$ORCH" spawn --name Bad_Name --cwd "$FAKE" --item A --tab t --brief-file b.md 2>/dev/null &&
  ! "$ORCH" spawn --name ok --cwd /nope --item A --tab t --brief-file b.md 2>/dev/null &&
  ! "$ORCH" spawn --name ok --cwd "$FAKE" --item A --tab t 2>/dev/null &&
  ! "$ORCH" spawn --name ok --cwd "$FAKE" --item A --tab t --brief-file missing.md 2>/dev/null &&
  lacks "$(log)" "hc run"
}

test_spawn_app_before_claim_fails() {
  app_env
  printf 'x' >b.md
  ! "$ORCH" spawn --name ok --cwd "$FAKE" --item A --tab t --brief-file b.md 2>/dev/null
}

test_spawn_tui_creates_tab_starts_agent_then_prompts() {
  tui_env
  fixture herdr_tab_create <<'EOF'
{"result":{"tab":{"tab_id":"w1:t4"},"root_pane":{"pane_id":"w1:p7"}}}
EOF
  printf 'Brief text' >b.md
  out=$("$ORCH" spawn --name fix-a --cwd "$FAKE" --item A --tab "work: A" --brief-file b.md)
  eq "$out" '{"name":"fix-a","tab":"w1:t4","pane":"w1:p7"}' &&
  has "$(log)" "herdr tab create --workspace w1 --cwd $FAKE --label work: A --no-focus" &&
  has "$(log)" "herdr agent start fix-a --kind claude --pane w1:p7" &&
  has "$(log)" "herdr agent prompt fix-a Brief text"
}

test_spawn_tui_resume() {
  tui_env
  fixture herdr_tab_create <<'EOF'
{"result":{"tab":{"tab_id":"w1:t4"},"root_pane":{"pane_id":"w1:p7"}}}
EOF
  "$ORCH" spawn --name fix-a --cwd "$FAKE" --item A --tab "work: A" --resume s-1 >/dev/null &&
  has "$(log)" "herdr agent start fix-a --kind claude --pane w1:p7 -- --resume s-1" &&
  lacks "$(log)" "agent prompt"
}

# send ---------------------------------------------------------------------------

test_send_app_returns_once_the_turn_starts() {
  app_env
  fixture hc_get_w.1 <<'EOF'
{"turn":4,"labels":{"orch.status":"ready-for-review - old"}}
EOF
  fixture hc_get_w.2 <<'EOF'
{"turn":4,"labels":{"orch.status":"ready-for-review - old"}}
EOF
  fixture hc_get_w.3 <<'EOF'
{"turn":4,"labels":{"orch.status":"working - new input: fix it"}}
EOF
  eq "$("$ORCH" send w "fix it")" "sent" &&
  has "$(log)" "hc send w fix it" &&
  eq "$(cat "$FAKE/count-hc_get_w")" "3"
}

# wait ---------------------------------------------------------------------------

test_wait_app_settles_on_the_status_label() {
  app_env
  fixture hc_wait_w <<'EOF'
{"ended":true,"exit_code":null,"reason":"status","status":"done"}
EOF
  fixture hc_get_w <<'EOF'
{"labels":{"orch.status":"ready-for-review - PR #12 is green"}}
EOF
  eq "$("$ORCH" wait w 30)" '{"name":"w","result":"settled","state":"done","status":"ready-for-review - PR #12 is green"}'
}

test_wait_app_waits_for_the_stop_hook_to_replace_the_started_label() {
  app_env
  fixture hc_wait_w <<'EOF'
{"ended":true,"exit_code":null,"status":"idle"}
EOF
  fixture hc_get_w.1 <<'EOF'
{"labels":{"orch.status":"working - new input: go"}}
EOF
  fixture hc_get_w.2 <<'EOF'
{"labels":{"orch.status":"working - new input: go"}}
EOF
  fixture hc_get_w.3 <<'EOF'
{"labels":{"orch.status":"needs-orchestrator - question"}}
EOF
  eq "$("$ORCH" wait w 30 | jq -r .result,.status | tr '\n' '|')" "settled|needs-orchestrator - question|"
}

test_wait_app_keeps_waiting_through_working() {
  app_env
  fixture hc_wait_w.1 <<'EOF'
{"ended":false,"reason":"timeout","status":"working"}
EOF
  fixture hc_wait_w.2 <<'EOF'
{"ended":true,"exit_code":null,"status":"done"}
EOF
  fixture hc_get_w <<'EOF'
{"labels":{"orch.status":"blocked - needs npm auth"}}
EOF
  eq "$("$ORCH" wait w 30 | jq -r .result)" "settled" &&
  eq "$(cat "$FAKE/count-hc_wait_w")" "2"
}

test_wait_app_reports_blocked() {
  app_env
  fixture hc_wait_w <<'EOF'
{"ended":true,"exit_code":null,"status":"blocked"}
EOF
  eq "$("$ORCH" wait w 30 | jq -r .result)" "blocked"
}

test_wait_app_reports_exited() {
  app_env
  fixture hc_wait_w <<'EOF'
{"ended":true,"exit_code":0,"status":"done"}
EOF
  eq "$("$ORCH" wait w 30 | jq -r .result)" "exited"
}

test_wait_app_times_out_without_a_status() {
  app_env
  fixture hc_wait_w <<'EOF'
{"ended":true,"exit_code":null,"status":"idle"}
EOF
  fixture hc_get_w <<'EOF'
{"labels":{}}
EOF
  eq "$("$ORCH" wait w 1 | jq -r .result,.state | tr '\n' '|')" "timeout|idle|"
}

test_wait_tui_reads_the_status_line_from_the_pane() {
  tui_env
  fixture herdr_agent_get_w <<'EOF'
{"result":{"agent":{"name":"w","agent_status":"done"}}}
EOF
  fixture herdr_agent_read_w <<'EOF'
{"result":{"text":"STATUS: working - old turn\nmore output\nSTATUS: ready-for-review - PR #3 green\n> "}}
EOF
  eq "$("$ORCH" wait w 30 | jq -r .result,.status | tr '\n' '|')" "settled|ready-for-review - PR #3 green|"
}

# doctor and install-hooks -------------------------------------------------------

test_install_hooks_links_and_registers_once() {
  export ORCH_SETTINGS="$FAKE/settings.json" ORCH_HOOKS_DIR="$FAKE/hooks"
  printf '%s' '{"model":"x","hooks":{"Stop":[{"hooks":[{"type":"command","command":"other.sh"}]}]}}' >"$ORCH_SETTINGS"
  "$ROOT/scripts/install-hooks" >/dev/null &&
  eq "$(readlink "$FAKE/hooks/herdr-context.sh")" "$ROOT/hooks/herdr-context.sh" &&
  eq "$(readlink "$FAKE/hooks/orch-worker-activity.sh")" "$ROOT/hooks/orch-worker-activity.sh" &&
  eq "$(jq -r .model "$ORCH_SETTINGS")" "x" &&
  eq "$(jq -r '.hooks.Stop | length' "$ORCH_SETTINGS")" "2" &&
  eq "$(jq -r '.hooks.Stop[1].hooks[0].command' "$ORCH_SETTINGS")" "sh '$FAKE/hooks/orch-worker-activity.sh' stop" &&
  eq "$(jq -r '.hooks.UserPromptSubmit[0].hooks[0].async' "$ORCH_SETTINGS")" "true" &&
  eq "$(jq -r '.hooks.SessionStart[0].matcher' "$ORCH_SETTINGS")" '^(startup|resume|clear|compact|fork)$' &&
  before=$(cat "$ORCH_SETTINGS") &&
  second=$("$ROOT/scripts/install-hooks") &&
  eq "$(cat "$ORCH_SETTINGS")" "$before" &&
  lacks "$second" "added"
}

test_install_hooks_backs_up_a_regular_file() {
  export ORCH_SETTINGS="$FAKE/settings.json" ORCH_HOOKS_DIR="$FAKE/hooks"
  mkdir -p "$FAKE/hooks" && echo old >"$FAKE/hooks/herdr-context.sh"
  "$ROOT/scripts/install-hooks" >/dev/null &&
  eq "$(cat "$FAKE"/hooks/herdr-context.sh.bak.*)" "old" &&
  [ -L "$FAKE/hooks/herdr-context.sh" ]
}

test_install_hooks_register_only_skips_links() {
  export ORCH_SETTINGS="$FAKE/settings.json" ORCH_HOOKS_DIR="$FAKE/hooks"
  "$ROOT/scripts/install-hooks" --register-only >/dev/null &&
  [ ! -e "$FAKE/hooks/herdr-context.sh" ] &&
  eq "$(jq -r '.hooks | keys | join(",")' "$ORCH_SETTINGS")" "SessionStart,Stop,UserPromptSubmit"
}

test_doctor_reports_missing_hooks_then_passes() {
  app_env
  export ORCH_SETTINGS="$FAKE/settings.json" ORCH_HOOKS_DIR="$FAKE/hooks"
  echo '{}' >"$ORCH_SETTINGS"
  out=$("$ORCH" doctor); rc=$?
  eq "$rc" "1" && has "$out" "missing  Stop hook orch-worker-activity.sh" &&
  "$ROOT/scripts/install-hooks" >/dev/null &&
  "$ORCH" doctor >/dev/null
}

tests=$(grep -Eo '^test_[a-z0-9_]+' "$0")
for t in $tests; do run_test "$t"; done
echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
