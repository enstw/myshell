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

    skilljz_installed=0
    if command -v claude >/dev/null 2>&1; then
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
    fi

    mkdir -p "$skilljz_links"

    if [[ "$skilljz_installed" -eq 1 ]]; then
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
