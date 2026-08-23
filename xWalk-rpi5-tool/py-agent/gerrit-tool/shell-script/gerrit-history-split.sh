#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck source=xwalk-gerrit-common.sh
source "$script_dir/xwalk-gerrit-common.sh"

mode="${1:---dry-run}"
[[ "$#" -eq 1 ]] || { echo "Usage: gerrit-history-split.sh --dry-run|--apply" >&2; exit 2; }
xwalk_mode "$mode"
xwalk_load_config
source_root="$(git rev-parse --show-toplevel)"
source_commit="$(git -C "$source_root" rev-parse HEAD)"
output_root="${XWALK_SPLIT_OUTPUT_DIR:-}"
import_mode="${XWALK_IMPORT_MODE:-none}"

validate_source()
{
    [[ -f "$source_root/AGENTS.md" ]] || { echo "Source is not the xWalk workspace" >&2; return 2; }
    case "$import_mode" in none|review|direct) ;; *) echo "XWALK_IMPORT_MODE must be none, review or direct" >&2; return 2 ;; esac
    if [[ "$XWALK_MODE" == "apply" ]]; then
        [[ -z "$(git -C "$source_root" status --porcelain)" ]] || {
            echo "History splitting requires a clean source repository" >&2
            return 2
        }
        command -v git-filter-repo >/dev/null 2>&1 || command -v git-filter-repo.py >/dev/null 2>&1 || {
            echo "Missing git-filter-repo. Ask the administrator to provide the approved git-filter-repo command." >&2
            return 2
        }
        [[ "${XWALK_CONFIRM_SPLIT:-}" == "SPLIT_COMPONENT_HISTORY" ]] || {
            echo "Set XWALK_CONFIRM_SPLIT=SPLIT_COMPONENT_HISTORY for explicit apply" >&2
            return 2
        }
        output_root="$(xwalk_new_output_path "$output_root" "$source_root")"
        echo "Selected split output: $output_root"
    fi
}

split_component()
{
    local component="$1" source_path legacy_path after remote ref
    local -a filter_arguments
    source_path="$(xwalk_integration_path "$component")"
    legacy_path="$(xwalk_legacy_integration_path "$component")"
    local destination_root="${output_root:-[XWALK_SPLIT_OUTPUT_DIR]}"
    local destination="$destination_root/$component"
    printf '[%s] split %s at %s\n' "$XWALK_MODE" "$component" "$source_commit"
    if [[ "$XWALK_MODE" == "dry-run" ]]; then
        xwalk_log "split-history" "migration" "$component" "$source_path/" "$source_commit" \
            "filtered-master" "Plan history-preserving component split" \
            "Independent Gerrit review requires component-scoped history." "Planned" \
            "Fixed component allowlist and source commit validated" "" "" "$source_commit"
        xwalk_log "add-gerrit-remote" "migration" "$component" "remote:gerrit" "none" \
            "sanitized-gerrit-url" "Plan component Gerrit remote" \
            "Component repositories must never receive GitHub remotes." "Planned"
        case "$import_mode" in
            none)
                xwalk_log "initial-import" "migration" "$component" "master" "not-pushed" \
                    "not-pushed" "Skip initial Gerrit push" \
                    "XWALK_IMPORT_MODE=none requires later authorization." "Skipped" \
                    "No remote write planned"
                ;;
            review)
                echo "[dry-run] git -C '$destination' push gerrit HEAD:refs/for/master"
                xwalk_log "initial-import" "migration" "$component" "refs/for/master" \
                    "not-pushed" "planned" "Plan review-based initial import" \
                    "The destination does not authorize direct branch bootstrap." "Planned"
                ;;
            direct)
                echo "[dry-run] git -C '$destination' push gerrit HEAD:refs/heads/master"
                xwalk_log "initial-import" "migration" "$component" "refs/heads/master" \
                    "not-pushed" "planned" "Plan administrator-authorized initial import" \
                    "An empty repository requires an explicitly authorized baseline." "Planned"
                ;;
        esac
        return
    fi
    git clone --quiet --no-local "$source_root" "$destination"
    filter_arguments=(
        --force --path "$source_path/" --path-rename "$source_path/:"
    )
    if [[ "$legacy_path" != "$source_path" ]]; then
        filter_arguments+=(
            --path "$legacy_path/" --path-rename "$legacy_path/:"
        )
    fi
    git -C "$destination" filter-repo "${filter_arguments[@]}"
    git -C "$destination" branch -M master
    after="$(git -C "$destination" rev-parse HEAD)"
    xwalk_log "split-history" "migration" "$component" "$source_path/" "$source_commit" "$after" \
        "Split component history" "Independent Gerrit review requires component-scoped history." \
        "Applied" "git filter-repo completed in an independent clone" "" "" "$source_commit" "$after"
    remote="ssh://$GERRIT_ADMIN_USERNAME@$GERRIT_SERVER_HOST:$GERRIT_SSH_PORT/$component"
    git -C "$destination" remote remove origin 2>/dev/null || true
    git -C "$destination" remote add gerrit "$remote"
    xwalk_log "add-gerrit-remote" "migration" "$component" "remote:gerrit" "none" \
        "sanitized-gerrit-url" "Configured initial Gerrit import remote" \
        "Component repositories must never receive GitHub remotes." "Applied" \
        "git remote get-url gerrit succeeded"
    case "$import_mode" in
        none)
            xwalk_log "initial-import" "migration" "$component" "master" "not-pushed" "not-pushed" \
                "Skipped initial Gerrit push" "XWALK_IMPORT_MODE=none requires later authorization." \
                "Skipped" "Split repository retained locally"
            ;;
        review) ref="refs/for/master" ;;
        direct) ref="refs/heads/master" ;;
    esac
    case "$import_mode" in
        review|direct)
            [[ "${XWALK_CONFIRM_IMPORT:-}" == "PUSH_COMPONENTS_TO_GERRIT" ]] || {
                xwalk_log "initial-import" "migration" "$component" "$ref" "not-pushed" "not-pushed" \
                    "Skipped initial Gerrit push" "Explicit import confirmation was unavailable." \
                    "Skipped" "Set XWALK_CONFIRM_IMPORT=PUSH_COMPONENTS_TO_GERRIT"
                return
            }
            if git -C "$destination" push gerrit "HEAD:$ref"; then
                xwalk_log "initial-import" "migration" "$component" "$ref" "absent" "$after" \
                    "Pushed initial component history to Gerrit" \
                    "The independent repository requires its history baseline." "Applied" \
                    "Gerrit accepted the explicit refspec" "" "" "" "$after"
            else
                xwalk_log "initial-import" "migration" "$component" "$ref" "absent" "unchanged" \
                    "Initial Gerrit push failed" "The destination rejected the import." "Failed" \
                    "" "Sanitized git push failure"
                return 1
            fi
            ;;
    esac
}

main()
{
    validate_source
    [[ "$XWALK_MODE" == "dry-run" ]] || mkdir -m 700 "$output_root"
    local component source_path
    for component in "${xwalk_components[@]}"; do
        source_path="$(xwalk_integration_path "$component")"
        [[ -d "$source_root/$source_path" ]] || {
            echo "Missing allowlisted component: $component" >&2
            return 2
        }
        split_component "$component"
    done
    [[ -d "$source_root/xWalk-rpi5-tool" ]] || {
        echo "Missing allowlisted component: xWalk-rpi5-tool" >&2
        return 2
    }
    split_component xWalk-rpi5-tool
    [[ "$(git -C "$source_root" rev-parse HEAD)" == "$source_commit" ]] || {
        echo "Source repository changed during split" >&2
        return 1
    }
}

main
