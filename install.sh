#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
profile_block='if [ -f ~/.bash_profile_extras ]; then
	. ~/.bash_profile_extras
fi
'
bashrc_block='if [ -f ~/.bashrc_extras ]; then
	. ~/.bashrc_extras
fi'
ssh_include='Include ~/.ssh/config.d/*.conf'
required_files=(
    ".bash_profile_extras"
    ".bashrc_extras"
    ".bash_custom"
    ".ssh/config"
)
code_dir=""

log() {
    printf '[basrc] %s\n' "$1"
}

die() {
    printf '[basrc] Error: %s\n' "$1" >&2
    exit 1
}

backup_file() {
    local file="$1"

    if [ -f "$file" ]; then
        cp "$file" "$file.basrc.bak"
    fi
}

append_once() {
    local needle="$1"
    local file="$2"
    local block="$3"

    if [ ! -f "$file" ]; then
        printf '%s\n' "$block" > "$file"
        return
    fi

    if ! grep -Fq "$needle" "$file"; then
        printf '\n%s\n' "$block" >> "$file"
    fi
}

install_file() {
    local src="$1"
    local dest="$2"
    local mode="${3:-}"
    local tmp

    tmp="$(mktemp "${dest}.tmp.XXXXXX")"
    cp "$src" "$tmp"
    if [ -n "$mode" ]; then
        chmod "$mode" "$tmp"
    fi
    mv "$tmp" "$dest"
}

expand_path() {
    local path="$1"

    case "$path" in
        "~")
            printf '%s\n' "$HOME"
            ;;
        "~/"*)
            printf '%s\n' "${HOME}/${path#~/}"
            ;;
        /*)
            printf '%s\n' "$path"
            ;;
        *)
            printf '%s\n' "${HOME}/${path}"
            ;;
    esac
}

prompt_code_dir() {
    local default_dir="${CODE_DIR:-$HOME/code}"
    local reply=""

    if [ -n "${CODE_DIR:-}" ]; then
        code_dir="$(expand_path "$CODE_DIR")"
        return
    fi

    if [ -t 0 ]; then
        printf 'Code directory [%s]: ' "$default_dir"
        read -r reply || true
    fi

    code_dir="$(expand_path "${reply:-$default_dir}")"
}

set_code_dir_alias() {
    local file="$1"
    local code_dir_alias
    local tmp

    code_dir_alias="alias ..code='cd ${code_dir}'"
    tmp="$(mktemp "${file}.tmp.XXXXXX")"

    if [ -f "$file" ]; then
        awk -v alias_line="$code_dir_alias" '
            BEGIN { replaced = 0 }
            /^alias \.\.code=/ {
                if (!replaced) {
                    print alias_line
                    replaced = 1
                }
                next
            }
            { print }
            END {
                if (!replaced) {
                    print alias_line
                }
            }
        ' "$file" > "$tmp"
    else
        printf '%s\n' "$code_dir_alias" > "$tmp"
    fi

    chmod 0644 "$tmp"
    mv "$tmp" "$file"
}

preflight() {
    [ -n "${HOME:-}" ] || die "HOME is not set."
    [ -d "$HOME" ] || die "HOME directory does not exist: $HOME"

    local file
    for file in "${required_files[@]}"; do
        [ -f "${script_dir}/${file}" ] || die "Required repo file is missing: ${file}"
    done

    command -v cp >/dev/null 2>&1 || die "cp is required."
    command -v grep >/dev/null 2>&1 || die "grep is required."
    command -v mktemp >/dev/null 2>&1 || die "mktemp is required."
}

main() {
    preflight
    prompt_code_dir

    log "Installing into ${HOME}"
    mkdir -p "${HOME}/.ssh" "${HOME}/.ssh/config.d"
    mkdir -p "${code_dir}"
    chmod 700 "${HOME}/.ssh" || true

    install_file "${script_dir}/.bash_profile_extras" "${HOME}/.bash_profile_extras" 0644
    install_file "${script_dir}/.bashrc_extras" "${HOME}/.bashrc_extras" 0644
    install_file "${script_dir}/.ssh/config" "${HOME}/.ssh/config.d/basrc.conf" 0600

    if [ ! -f "${HOME}/.bash_custom" ]; then
        install_file "${script_dir}/.bash_custom" "${HOME}/.bash_custom" 0644
    fi
    backup_file "${HOME}/.bash_custom"
    set_code_dir_alias "${HOME}/.bash_custom"

    if [ ! -f "${HOME}/.bash_profile" ]; then
        cat > "${HOME}/.bash_profile" <<'EOF'
if [ -f ~/.profile ]; then
	. ~/.profile
fi
EOF
    fi

    backup_file "${HOME}/.bash_profile"
    append_once '. ~/.bash_profile_extras' "${HOME}/.bash_profile" "${profile_block}"

    if [ ! -f "${HOME}/.bashrc" ]; then
        printf '%s\n' "${bashrc_block}" > "${HOME}/.bashrc"
    fi

    backup_file "${HOME}/.bashrc"
    append_once '. ~/.bashrc_extras' "${HOME}/.bashrc" "${bashrc_block}"

    if [ ! -f "${HOME}/.ssh/config" ]; then
        printf '%s\n' "${ssh_include}" > "${HOME}/.ssh/config"
        chmod 600 "${HOME}/.ssh/config" || true
    else
        backup_file "${HOME}/.ssh/config"
        append_once "${ssh_include}" "${HOME}/.ssh/config" "${ssh_include}"
    fi

    grep -Fq '. ~/.bash_profile_extras' "${HOME}/.bash_profile" || die "Failed to update ~/.bash_profile"
    grep -Fq '. ~/.bashrc_extras' "${HOME}/.bashrc" || die "Failed to update ~/.bashrc"
    grep -Fq "${ssh_include}" "${HOME}/.ssh/config" || die "Failed to update ~/.ssh/config"
    [ -f "${HOME}/.ssh/config.d/basrc.conf" ] || die "Failed to install SSH config fragment"
    [ -d "${code_dir}" ] || die "Failed to create code directory: ${code_dir}"
    grep -Fq "alias ..code='cd ${code_dir}'" "${HOME}/.bash_custom" || die "Failed to update ~/.bash_custom"

    log "Install complete."
    log "Code directory: ${code_dir}"
    log "Open a new login shell or run: source ~/.bash_profile"
}

main "$@"
