#!/usr/bin/env bash
set -Eeuo pipefail

root="$(git rev-parse --show-toplevel)"
key="${GERRIT_SUBMODULE_SSH_KEY_FILE:?Missing runner Gerrit key configuration}"
known_hosts="${GERRIT_SSH_KNOWN_HOSTS_FILE:?Missing pinned Gerrit host keys}"
username="${GERRIT_SUBMODULE_USERNAME:?Missing Gerrit username}"
host="${GERRIT_SERVER_HOST:?Missing Gerrit hostname}"
port="${GERRIT_SSH_PORT:-29418}"

fail()
{
    echo "$*" >&2
    exit 1
}

# Preserve runner edits in a reused worktree before switching it to another revision.
preserve_runner_changes()
{
    local path="$1" child
    if [[ -f "$root/$path/.gitmodules" ]]; then
        while read -r child; do
            [[ "$(realpath -m "$root/$path/$child")" == "$root/$path/$child" ]] || fail "Unsafe nested path"
            if [[ -e "$root/$path/$child/.git" ]]; then
                preserve_runner_changes "$path/$child"
            fi
        done < <(git -C "$root/$path" config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}')
    fi
    [[ -n "$(git -C "$root/$path" status --porcelain --untracked-files=normal --ignore-submodules=all)" ]] || return 0
    [[ "${GITHUB_ACTIONS:-}" == true && "${GITHUB_WORKSPACE:-}" == "$root" ]] || \
        fail "Refusing to stash changes outside the GitHub Actions workspace: $path"
    # Preserve tracked/index changes and generated untracked files before switching revisions.
    # The stash stays local in the worktree's Git metadata; source artifacts never include it.
    git -C "$root/$path" -c user.name='xWalk CI' -c user.email='xwalk-ci@localhost' \
        stash push --include-untracked --message \
        "xWalk CI checkout ${GITHUB_RUN_ID:-unknown}/${GITHUB_RUN_ATTEMPT:-unknown}"
    [[ -z "$(git -C "$root/$path" status --porcelain --untracked-files=normal --ignore-submodules=all)" ]] || \
        fail "Component remains modified after preserving runner changes: $path"
    echo "Preserved runner changes in $path at $(git -C "$root/$path" rev-parse refs/stash)"
}

[[ "$username" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]*$ ]] || fail 'Invalid Gerrit username'
[[ "$host" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]] || fail 'Invalid Gerrit hostname'
[[ "$port" =~ ^[0-9]{1,5}$ ]] || fail 'Invalid Gerrit port'
((10#$port > 0 && 10#$port <= 65535)) || fail 'Invalid Gerrit port'
[[ -r "$key" && -s "$key" ]] || fail 'Cannot read runner Gerrit key'
[[ -r "$known_hosts" && -s "$known_hosts" ]] || fail 'Cannot read pinned Gerrit host keys'
key_mode="$(stat -Lc '%a' "$key")"
(( (8#$key_mode & 077) == 0 )) || fail 'Gerrit key must not be accessible by group or others'
printf -v GIT_SSH_COMMAND '%q ' ssh -i "$key" -p "$port" \
    -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes \
    -o "UserKnownHostsFile=$known_hosts"
export GIT_SSH_COMMAND
export GIT_TERMINAL_PROMPT=0
export GIT_ALLOW_PROTOCOL=ssh

# A reused runner can retain the former flat component worktrees inside this path.
# Adopt them in place so their Git metadata, ignored state and saved edits survive.
adopt_legacy_hardware()
{
    local path="$1" url="$2" revision="$3" child
    [[ "${GITHUB_ACTIONS:-}" == true && "${GITHUB_WORKSPACE:-}" == "$root" ]] || \
        fail "Refusing hardware migration outside the GitHub Actions workspace"
    for child in xWalkDriver xWalkAudioResources xWalkController xWalkHal xWalkLibrary; do
        [[ "$(realpath -m "$root/$path/$child")" == "$root/$path/$child" ]] || fail 'Unsafe legacy hardware path'
        if [[ -e "$root/$path/$child/.git" ]]; then
            preserve_runner_changes "$path/$child"
        fi
    done
    git -C "$root/$path" init --quiet
    git -C "$root/$path" remote add origin "$url"
    git -C "$root/$path" fetch --no-tags origin '+refs/heads/master:refs/remotes/origin/master'
    git -C "$root/$path" merge-base --is-ancestor "$revision" refs/remotes/origin/master || \
        fail "Hardware revision has not been submitted to Gerrit master"
    git -C "$root/$path" reset --mixed "$revision"
    if [[ ! -e "$root/$path/.gitignore" ]] && \
        git -C "$root/$path" cat-file -e "$revision:.gitignore" 2>/dev/null; then
        git -C "$root/$path" checkout "$revision" -- .gitignore
    fi
    preserve_runner_changes "$path"
    git -C "$root/$path" checkout --detach "$revision"
    echo 'Preserved and adopted the former flat hardware checkout'
}

checkout_group()
{
    local scope="$1" prefix="$2" kind="$3" component path revision mode type tree_path index url
    local -a components=() paths=() revisions=() mappings=() configured_paths=()
    if [[ "$kind" == hardware ]]; then
        mappings=("xWalkDriver xWalkDriver" "xWalkAudioResources xWalkAudioResources"
            "xWalkController xWalkController" "xWalkHal xWalkHal" "xWalkLibrary xWalkLibrary")
    else
        mappings=("devloper-note devloper-note" "xWalk-rpi5-trace xWalk-rpi5-trace"
            "xWalk-rpi5-iw xWalk-rpi5-iw" "xWalk-rpi5-node xWalk-rpi5-node" "xWalk-rpi5-tool xWalk-rpi5-tool")
        if git -C "$scope" config -f .gitmodules --get submodule.xWalk-rpi5-hw.path >/dev/null; then
            mappings+=("xWalk-rpi5-hw xWalk-rpi5-hw")
        else
            mappings+=("xWalkDriver xWalk-rpi5-hw/xWalkDriver" "xWalkAudioResources xWalk-rpi5-hw/xWalkAudioResources"
                "xWalkController xWalk-rpi5-hw/xWalkController" "xWalkHal xWalk-rpi5-hw/xWalkHal"
                "xWalkLibrary xWalk-rpi5-hw/xWalkLibrary")
        fi
        if git -C "$scope" config -f .gitmodules --get submodule.xWalk-rpi5-os.path >/dev/null; then
            mappings+=("xWalk-rpi5-os xWalk-rpi5-os")
        fi
    fi
    for entry in "${mappings[@]}"; do
        read -r component path <<< "$entry"
        [[ "$(git -C "$scope" config -f .gitmodules --get "submodule.$component.path")" == "$path" ]] || \
            fail "Unexpected path for $component"
        [[ "$(git -C "$scope" config -f .gitmodules --get "submodule.$component.branch")" == master ]] || \
            fail "Unexpected branch for $component"
        [[ "$(realpath -m "$scope/$path")" == "$scope/$path" ]] || fail "Unsafe component path: $path"
        read -r mode type revision tree_path < <(git -C "$scope" ls-tree HEAD -- "$path")
        [[ "$mode" == 160000 && "$type" == commit && "$tree_path" == "$path" ]] || \
            fail "Missing committed gitlink for $component"
        components+=("$component"); paths+=("$path"); revisions+=("$revision")
    done
    mapfile -t configured_paths < <(git -C "$scope" config -f .gitmodules --get-regexp '^submodule\..*\.path$')
    (( ${#configured_paths[@]} == ${#components[@]} )) || fail 'Unexpected component mappings'
    for index in "${!components[@]}"; do
        component="${components[$index]}"; path="${paths[$index]}"
        url="ssh://$username@$host:$port/$component"
        git -C "$scope" config --local "submodule.$component.url" "$url"
        if [[ "$component" == xWalk-rpi5-hw && -d "$scope/$path" && ! -e "$scope/$path/.git" ]] &&
            [[ -n "$(ls -A -- "$scope/$path")" ]]; then
            adopt_legacy_hardware "$prefix$path" "$url" "${revisions[$index]}"
        fi
        if [[ -e "$scope/$path/.git" ]]; then
            [[ "$(git -C "$scope/$path" rev-parse --show-toplevel)" == "$scope/$path" ]] || \
                fail "Unexpected component worktree: $path"
            preserve_runner_changes "$prefix$path"
            git -C "$scope/$path" remote set-url origin "$url"
        fi
    done
    git -C "$scope" submodule update --init --checkout -- "${paths[@]}"
    for index in "${!components[@]}"; do
        path="${paths[$index]}"; revision="${revisions[$index]}"
        git -C "$scope/$path" fetch --no-tags origin '+refs/heads/master:refs/remotes/origin/master'
        [[ "$(git -C "$scope/$path" rev-parse HEAD)" == "$revision" ]] || fail "Incorrect checkout: $path"
        git -C "$scope/$path" merge-base --is-ancestor "$revision" refs/remotes/origin/master || \
            fail "Component revision has not been submitted to Gerrit master: $path $revision"
        if [[ "${components[$index]}" == xWalk-rpi5-hw ]]; then
            checkout_group "$scope/$path" "$prefix$path/" hardware
        fi
    done
}
checkout_group "$root" "" product
echo 'Checked out all exact component gitlinks from submitted Gerrit master history'
