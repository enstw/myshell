# myshell update.d drop-in — deployed by scripts/install and rewritten on every
# bootstrap. Edit it in the myshell repo, not in ~/.config/myshell/update.d.
# See 10-skill-jz.sh's header for the contract this file follows.
#
# simplenote-sync reconciles ~/workspace/simplenote-sync/notes with Simplenote
# (pull then push; it stops on conflicts rather than guessing). Auth lives in
# the checkout's .sn/state.json, so there is nothing to pass in here.

sn_repo="$HOME/workspace/simplenote-sync"

# Silent no-op without the checkout. uv is required too: it owns the venv for
# this project (pyproject.toml + uv.lock), per myshell's Python-via-uv-only rule.
if [[ -f "$sn_repo/sn.py" ]] && command -v uv >/dev/null 2>&1; then
    log "Syncing Simplenote notes..."
    # cd inside a subshell so the updater's own cwd survives — but `warn` stays
    # OUTSIDE it, or the WARNINGS increment would die with the subshell (the
    # same trap scripts/install's header calls out).
    ( cd "$sn_repo" && uv run sn.py sync ) || warn "simplenote sync failed"
fi

# See 10-skill-jz.sh: land on a definite success so the sourcing loop doesn't
# read a non-matching `if` as a failed drop-in.
true
