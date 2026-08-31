# myshell update.d drop-in — deployed by scripts/install and rewritten on every
# bootstrap. Edit it in the myshell repo, not in ~/.config/myshell/update.d.
#
# Sourced by ~/bin/myshell-update, so log/sublog/warn and $SUDO are already
# defined and set -e is suspended — see that script's update.d section for the
# three rules a drop-in must follow (guard every step with `|| warn`, keep any
# cd inside a subshell with warn outside it, and end the file with `true`).
#
# skill-jz is the live checkout behind ~/.claude/skills: the skills are symlinks
# into it, so `git pull` alone refreshes their *content*. Relinking is for the
# folder set changing — a skill added upstream has no link yet, and one renamed
# or removed leaves a dangling one behind.

skilljz_repo="$HOME/workspace/skill-jz"
skilljz_links="$HOME/.claude/skills"

# Silent no-op where the checkout isn't present (the NAS, a fresh box): this is
# a personal repo that bootstrap does not install, not a missing dependency.
if [[ -d "$skilljz_repo/.git" ]]; then
    log "Updating skill-jz and refreshing skill links..."

    # --ff-only: this checkout is read-mostly, so a diverged branch means real
    # local work that a merge commit would bury. Warn and let the user resolve
    # it; the relink below still runs against whatever is on disk.
    git -C "$skilljz_repo" pull --ff-only || warn "skill-jz: git pull failed"

    mkdir -p "$skilljz_links"

    # One link per top-level folder holding a SKILL.md — the layout skill-jz's
    # SKILLS-CLI.md defines. A real directory or file is never replaced, only a
    # symlink or a missing entry (skill-jz's AGENTS.md makes that a rule).
    skilljz_n=0
    for skilljz_md in "$skilljz_repo"/*/SKILL.md; do
        [[ -f "$skilljz_md" ]] || continue          # unmatched glob
        skilljz_src="${skilljz_md%/SKILL.md}"
        skilljz_dst="$skilljz_links/${skilljz_src##*/}"
        if [[ -e "$skilljz_dst" && ! -L "$skilljz_dst" ]]; then
            warn "skill-jz: $skilljz_dst is a real path, not a symlink — leaving it alone"
            continue
        fi
        # -n so an existing symlink is replaced rather than followed into its
        # target (without it, ln would create the link *inside* the old target).
        if ln -sfn "$skilljz_src" "$skilljz_dst"; then
            skilljz_n=$((skilljz_n + 1))
        else
            warn "skill-jz: could not link ${skilljz_dst##*/}"
        fi
    done
    sublog "$skilljz_n skill link(s) current"

    # Prune links this repo used to own: symlinks under ~/.claude/skills that
    # point into skill-jz but whose target no longer exists. Scoped to skill-jz
    # targets, so links into other checkouts — and any real directory — are
    # left alone.
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

# The sourcing loop reports the file's exit status, which is just whatever ran
# last — an `if` that didn't match returns 1. Land on a definite success.
true
