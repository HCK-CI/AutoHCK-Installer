#!/bin/bash

set -e

export INSTALL_SILENT=false

work_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
bootstrap="${work_dir}/bootstrap"
dependencies="${work_dir}/dependencies.sh"

source "${dependencies}"
source "${work_dir}/logger.sh"
source "${work_dir}/helpers.sh"
source "${work_dir}/qemu.sh"
source "${work_dir}/virtiofsd.sh"
source "${work_dir}/autohck.sh"

for i in "$@"; do
  case $i in
    --silent)
      export INSTALL_SILENT=true
      ;;
    *)
      log_error "Unknown option: ${i}"
      print_usage
      exit 1
      ;;
  esac
done

if [ "${DISABLE_KVM_CHECK}" != "yes" ]; then
    [ -r /dev/kvm ] || log_fatal '/dev/kvm is not readable. Make sure /dev/kvm has right permissions and the user belongs to the corresponding group.'
    [ -w /dev/kvm ] || log_fatal '/dev/kvm is not writable. Make sure /dev/kvm has right permissions and the user belongs to the corresponding group.'
fi

command_exists jq || log_fatal "jq command does not exist"

[ ! -f "${bootstrap}" ] || source "${bootstrap}"

repos_dir="$(from_env_or_read "REPOS_DIR" "Please provide path to repos directory")"
iso_path="$(from_env_or_read "ISO_PATH" "Please provide path to ISO directory")"
images_path="$(from_env_or_read "IMAGES_PATH" "Please provide path to images directory")"
workspace_path="$(from_env_or_read "WORKSPACE_PATH" "Please provide path to workspace directory")"

echo "REPOS_DIR='${repos_dir}'" > "${bootstrap}"
echo >>"${bootstrap}"
echo "ISO_PATH='${iso_path}'" >>"${bootstrap}"
echo "IMAGES_PATH='${images_path}'" >>"${bootstrap}"
echo "WORKSPACE_PATH='${workspace_path}'" >>"${bootstrap}"
echo >>"${bootstrap}"
echo >>"${bootstrap}"

mkdir -vp "${repos_dir}" "${iso_path}" "${images_path}" "${workspace_path}"

log_info "Processing repositories"

for dependency in "${DEPENDENCIES[@]}"; do
    log_info "Processing ${dependency}"

    dependency_dir_var="${dependency}_DIR"
    dependency_git_var="${dependency}_GIT"
    dependency_ref_var="${dependency}_REF"

    if is_redefined_by_file "${dependency_ref_var}" "${dependencies}"; then
        echo "${dependency_ref_var}='${!dependency_ref_var}'" >>"${bootstrap}"
    fi

    repo_url="${!dependency_git_var}"
    repo_name="$(basename ${repo_url})"
    repo_ref="${!dependency_ref_var}"

    if [ -z "${!dependency_dir_var}" ]; then
        repo_path="${repos_dir}/${repo_name}"
    else
        log_info "${dependency} dir overridden: ${!dependency_dir_var}"
        repo_path="${!dependency_dir_var}"
    fi
    echo "${dependency_dir_var}='${repo_path}'" >>"${bootstrap}"

    source "${bootstrap}"

    if [ -d "${repo_path}" ]; then
        (
            cd "${repo_path}"

            git fetch
            mapfile -d ' ' -t current_refs < <(git log -n1 --format='%h %H %D')

            already_ref=0
            for ref in "${current_refs[@]}"; do
                if [ "$(echo ${ref} | tr -d '\n' | tr -d ',')" == "${repo_ref}" ]; then
                    already_ref=1
                fi
            done

            if [ "${already_ref}" == "0" ]; then
                git fetch
                git checkout "${repo_ref}"
                if [ "$(LC_ALL=C type -t "post_clone_${dependency}")" == "function" ]; then
                    log_info "Execution post_clone_${dependency} ${repo_path}"
                    "post_clone_${dependency}" "${repo_path}"
                fi
            else
                log_info "${repo_name} already at ${repo_ref}"
            fi
        )
    else
        git clone "${repo_url}" "${repo_path}"
        (
            cd "${repo_path}"
            git checkout "${repo_ref}"

            if [ "$(LC_ALL=C type -t "post_clone_${dependency}")" == "function" ]; then
                log_info "Execution post_clone_${dependency} ${repo_path}"
                "post_clone_${dependency}" "${repo_path}"
            fi
        )
    fi

    if [ "$(LC_ALL=C type -t "process_${dependency}")" == "function" ]; then
        log_info "Execution "process_${dependency}" ${repo_path}"
        "process_${dependency}" "${repo_path}"
    fi
done

log_info "Generating config overwrite file"

source "${work_dir}/config.sh" | tee "${AUTOHCK_DIR}/override.install.json"

if [ -f "${AUTOHCK_DIR}/override.json" ]; then
    log_info "Old overwrite file present, merging..."

    mv -vf "${AUTOHCK_DIR}/override.json" "${AUTOHCK_DIR}/override.old"

    jq -s '.[0] * .[1]' "${AUTOHCK_DIR}/override.old" \
        "${AUTOHCK_DIR}/override.install.json" | tee "${AUTOHCK_DIR}/override.json"
else
    mv -vf "${AUTOHCK_DIR}/override.install.json" "${AUTOHCK_DIR}/override.json"
fi
