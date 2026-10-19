# myshell update.d drop-in — deployed by scripts/install and rewritten on every
# bootstrap. Edit it in the myshell repo, not in ~/.config/myshell/update.d.
#
# Sourced by ~/bin/myshell-update, so log/sublog/warn and $SUDO are already
# defined and set -e is suspended — see that script's update.d section for the
# three rules a drop-in must follow (guard every step with `|| warn`, keep any
# cd inside a subshell with warn outside it, and end the file with `true`).
#
# skill-jz reaches Claude Code as the `enstw` plugin from its own marketplace
# (`skill-jz`, github.com/enstw/skill-jz, private), installed from GitHub rather
# than from this checkout. The plugin has no version field, so its version is
# the commit: every push is an update. The checkout is still pulled for editing.
# The same marketplace carries two mods, accept-edits-autoallow and
# long-run-resume, installed and updated alongside it; sessions are set to start
# in acceptEdits mode, the one accept-edits-autoallow works in. All of this is
# skipped when claude is missing or not signed in.
#
# Before the plugin (until 2026-10-18) the skills were symlinks from
# ~/.claude/skills into the checkout. With the plugin installed those links are
# removed, or every skill would be listed twice (`flush` and `enstw:flush`).
# Without it (no claude, no access to the private repo) the skills stay linked,
# so a failed install never leaves a machine without them.

skilljz_repo="$HOME/workspace/skill-jz"
skilljz_links="$HOME/.claude/skills"
skilljz_plugin="enstw@skill-jz"

# Silent no-op where the checkout isn't present (the NAS, a fresh box): this is
# a personal repo that bootstrap does not install, not a missing dependency.
if [[ -d "$skilljz_repo/.git" ]]; then
    log "Updating skill-jz and its Claude Code plugin..."

    # --ff-only: this checkout is read-mostly, so a diverged branch means real
    # local work that a merge commit would bury. Warn and carry on with the
    # plugin, which comes from GitHub, not from this checkout.
    git -C "$skilljz_repo" pull --ff-only || warn "skill-jz: git pull failed"

    # Plugins need a claude that is installed and signed in; without either,
    # skip them. Signed out, the links are left as they are too: the plugin
    # may already be installed, and relinking would list every skill twice.
    skilljz_installed=0
    skilljz_skip_links=0
    if ! command -v claude >/dev/null 2>&1; then
        :
    elif ! claude auth status 2>/dev/null | grep -q '"loggedIn": true'; then
        sublog "claude is not signed in — skipping the plugin, mods and settings"
        skilljz_skip_links=1
    else
        if claude plugin list --json 2>/dev/null | grep -q "\"id\": \"$skilljz_plugin\""; then
            claude plugin marketplace update skill-jz >/dev/null 2>&1 \
                || warn "skill-jz: marketplace refresh failed"
            # update prints "already at the latest version" or "updated from X
            # to Y"; a disabled plugin is updated on disk and stays disabled.
            if skilljz_out=$(claude plugin update "$skilljz_plugin" 2>&1); then
                sublog "${skilljz_out##*$'\n'}"
            else
                warn "skill-jz: plugin update failed: ${skilljz_out##*$'\n'}"
            fi
            skilljz_installed=1
        elif claude plugin install enstw --marketplace enstw/skill-jz --scope user >/dev/null 2>&1; then
            sublog "installed the $skilljz_plugin plugin (run /reload-plugins in open sessions)"
            skilljz_installed=1
        else
            warn "skill-jz: could not install the $skilljz_plugin plugin — keeping the skill links"
        fi

        # The two mods ship in the same marketplace (skill-jz's mods/), so they
        # ride on the refresh above and are skipped when the marketplace was
        # unreachable. Until 2026-10-19 they came from the claude-mods
        # marketplace, whose repository is gone: an entry from it is replaced,
        # never updated, and one the user disabled is dropped, not reinstalled.
        if [[ "$skilljz_installed" -eq 1 ]]; then
            skilljz_list=$(claude plugin list --json 2>/dev/null)
            for skilljz_mod in accept-edits-autoallow long-run-resume; do
                if grep -q "\"id\": \"$skilljz_mod@claude-mods\"" <<<"$skilljz_list"; then
                    # Pretty-printed JSON: "enabled" follows its entry's "id".
                    skilljz_enabled=$(awk -v id="\"$skilljz_mod@claude-mods\"" \
                        '/"id":/ { cur = ($2 == id ",") } cur && /"enabled":/ { print $2; exit }' \
                        <<<"$skilljz_list")
                    if ! claude plugin uninstall "$skilljz_mod@claude-mods" >/dev/null 2>&1; then
                        warn "skill-jz: could not uninstall $skilljz_mod@claude-mods"
                        continue
                    fi
                    if [[ "${skilljz_enabled%,}" == "false" ]]; then
                        sublog "removed $skilljz_mod@claude-mods (was disabled, not reinstalled)"
                        continue
                    fi
                    skilljz_list=""
                fi
                if grep -q "\"id\": \"$skilljz_mod@skill-jz\"" <<<"$skilljz_list"; then
                    if skilljz_out=$(claude plugin update "$skilljz_mod@skill-jz" 2>&1); then
                        sublog "${skilljz_out##*$'\n'}"
                    else
                        warn "skill-jz: $skilljz_mod update failed: ${skilljz_out##*$'\n'}"
                    fi
                elif claude plugin install "$skilljz_mod" --marketplace enstw/skill-jz --scope user >/dev/null 2>&1; then
                    sublog "installed the $skilljz_mod@skill-jz mod (run /reload-plugins in open sessions)"
                else
                    warn "skill-jz: could not install the $skilljz_mod@skill-jz mod"
                fi
            done
        fi

        # Start sessions in accept-edits mode, the mode accept-edits-autoallow
        # answers prompts in. Merged into settings.json with every other key
        # kept; a file jq cannot parse is left alone.
        skilljz_settings="$HOME/.claude/settings.json"
        if ! command -v jq >/dev/null 2>&1; then
            warn "skill-jz: no jq — cannot set the default mode to acceptEdits"
        elif [[ -f "$skilljz_settings" ]] \
            && [[ "$(jq -r '.permissions.defaultMode // empty' "$skilljz_settings" 2>/dev/null)" == "acceptEdits" ]]; then
            :
        elif { [[ -f "$skilljz_settings" ]] && cat "$skilljz_settings" || echo '{}'; } \
                | jq '.permissions.defaultMode = "acceptEdits"' >"$skilljz_settings.tmp" 2>/dev/null \
            && mv "$skilljz_settings.tmp" "$skilljz_settings"; then
            sublog "default mode set to acceptEdits in ~/.claude/settings.json"
        else
            rm -f "$skilljz_settings.tmp"
            warn "skill-jz: could not set the default mode in $skilljz_settings"
        fi
    fi

    mkdir -p "$skilljz_links"

    if [[ "$skilljz_skip_links" -eq 1 ]]; then
        :
    elif [[ "$skilljz_installed" -eq 1 ]]; then
        # Remove every link into the checkout, live or dangling. Links into
        # other checkouts, and any real directory, are left alone.
        skilljz_removed=0
        for skilljz_dst in "$skilljz_links"/*; do
            [[ -L "$skilljz_dst" ]] || continue
            skilljz_src=$(readlink "$skilljz_dst")
            [[ "$skilljz_src" == "$skilljz_repo/"* ]] || continue
            if rm -f "$skilljz_dst"; then
                skilljz_removed=$((skilljz_removed + 1))
            else
                warn "skill-jz: could not remove the link ${skilljz_dst##*/}"
            fi
        done
        if [[ "$skilljz_removed" -gt 0 ]]; then
            sublog "removed $skilljz_removed skill link(s) the plugin replaces"
        fi
    else
        # Fallback: one link per top-level folder holding a SKILL.md — the
        # layout skill-jz's SKILLS-CLI.md defines. A real directory or file is
        # never replaced, only a symlink or a missing entry.
        skilljz_n=0
        for skilljz_md in "$skilljz_repo"/*/SKILL.md; do
            [[ -f "$skilljz_md" ]] || continue          # unmatched glob
            skilljz_src="${skilljz_md%/SKILL.md}"
            skilljz_dst="$skilljz_links/${skilljz_src##*/}"
            if [[ -e "$skilljz_dst" && ! -L "$skilljz_dst" ]]; then
                warn "skill-jz: $skilljz_dst is a real path, not a symlink — leaving it alone"
                continue
            fi
            # -n so an existing symlink is replaced rather than followed into
            # its target (without it, ln would create the link *inside* the
            # old target).
            if ln -sfn "$skilljz_src" "$skilljz_dst"; then
                skilljz_n=$((skilljz_n + 1))
            else
                warn "skill-jz: could not link ${skilljz_dst##*/}"
            fi
        done
        sublog "$skilljz_n skill link(s) current"

        # Prune links this repo used to own: symlinks into skill-jz whose
        # target no longer exists.
        skilljz_pruned=0
        for skilljz_dst in "$skilljz_links"/*; do
            [[ -L "$skilljz_dst" ]] || continue
            skilljz_src=$(readlink "$skilljz_dst")
            [[ "$skilljz_src" == "$skilljz_repo/"* ]] || continue
            [[ -d "$skilljz_src" ]] && continue
            if rm -f "$skilljz_dst"; then
                skilljz_pruned=$((skilljz_pruned + 1))
            else
                warn "skill-jz: could not prune ${skilljz_dst##*/}"
            fi
        done
        if [[ "$skilljz_pruned" -gt 0 ]]; then
            sublog "pruned $skilljz_pruned dangling link(s)"
        fi
    fi
fi

# The sourcing loop reports the file's exit status, which is just whatever ran
# last — an `if` that didn't match returns 1. Land on a definite success.
true
