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

components=()
paths=()
revisions=()
while read -r component path; do
    [[ "$(git -C "$root" config -f .gitmodules --get "submodule.$component.path")" == "$path" ]] || \
        fail "Unexpected path for $component"
    [[ "$(git -C "$root" config -f .gitmodules --get "submodule.$component.branch")" == master ]] || \
        fail "Unexpected branch for $component"
    [[ "$(realpath -m "$root/$path")" == "$root/$path" ]] || fail "Unsafe component path: $path"
    read -r mode type revision tree_path < <(git -C "$root" ls-tree HEAD -- "$path")
    [[ "$mode" == 160000 && "$type" == commit && "$tree_path" == "$path" ]] || \
        fail "Missing committed gitlink for $component"
    components+=("$component")
    paths+=("$path")
    revisions+=("$revision")
done <<'MAPPINGS'
devloper-note devloper-note
xWalkDriver xWalk-rpi5-hw/xWalkDriver
xWalkAudioResources xWalk-rpi5-hw/xWalkAudioResources
xWalkController xWalk-rpi5-hw/xWalkController
xWalkHal xWalk-rpi5-hw/xWalkHal
xWalkLibrary xWalk-rpi5-hw/xWalkLibrary
xWalk-rpi5-trace xWalk-rpi5-trace
xWalk-rpi5-iw xWalk-rpi5-iw
xWalk-rpi5-node xWalk-rpi5-node
xWalk-rpi5-tool xWalk-rpi5-tool
MAPPINGS

mapfile -t configured_paths < <(git -C "$root" config -f .gitmodules --get-regexp '^submodule\..*\.path$')
(( ${#configured_paths[@]} == ${#components[@]} )) || fail 'Unexpected component mappings'

for index in "${!components[@]}"; do
    component="${components[$index]}"
    path="${paths[$index]}"
    url="ssh://$username@$host:$port/$component"
    git -C "$root" config --local "submodule.$component.url" "$url"
    # Reused runner checkouts may still carry a former GitHub component remote.
    if [[ -e "$root/$path/.git" ]]; then
        git -C "$root/$path" remote set-url origin "$url"
    fi
done

git -C "$root" submodule update --init --checkout -- "${paths[@]}"
for index in "${!components[@]}"; do
    path="${paths[$index]}"
    revision="${revisions[$index]}"
    git -C "$root/$path" fetch --no-tags origin '+refs/heads/master:refs/remotes/origin/master'
    [[ "$(git -C "$root/$path" rev-parse HEAD)" == "$revision" ]] || fail "Incorrect checkout: $path"
    git -C "$root/$path" merge-base --is-ancestor "$revision" refs/remotes/origin/master || \
        fail "Component revision has not been submitted to Gerrit master: $path $revision"
done
echo 'Checked out all exact component gitlinks from submitted Gerrit master history'
