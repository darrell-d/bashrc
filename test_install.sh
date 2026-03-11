#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
tmp_home="$(mktemp -d)"
tmp_code_dir="${tmp_home}/projects/code"
trap 'rm -rf "$tmp_home"' EXIT

cat > "${tmp_home}/.profile" <<'EOF'
if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
fi
EOF

touch "${tmp_home}/.bashrc"
mkdir -p "${tmp_home}/.ssh"
cat > "${tmp_home}/.bash_profile" <<'EOF'
if [ -f ~/.profile ]; then
	. ~/.profile
fi
EOF
cat > "${tmp_home}/.ssh/config" <<'EOF'
Host existing
  HostName example.com
EOF

HOME="$tmp_home" CODE_DIR="$tmp_code_dir" "${repo_dir}/install.sh"
HOME="$tmp_home" CODE_DIR="$tmp_code_dir" "${repo_dir}/install.sh"

grep -Fq '. ~/.bash_profile_extras' "${tmp_home}/.bash_profile"
grep -Fq '. ~/.bashrc_extras' "${tmp_home}/.bashrc"
grep -Fq 'Include ~/.ssh/config.d/*.conf' "${tmp_home}/.ssh/config"
grep -Fq 'Host existing' "${tmp_home}/.ssh/config"
test -f "${tmp_home}/.ssh/config.d/basrc.conf"
test -f "${tmp_home}/.bash_custom"
test -d "${tmp_code_dir}"
test -f "${tmp_home}/.bash_profile.basrc.bak"
test -f "${tmp_home}/.bashrc.basrc.bak"
test -f "${tmp_home}/.bash_custom.basrc.bak"
test -f "${tmp_home}/.ssh/config.basrc.bak"

profile_matches="$(grep -Fc '. ~/.bash_profile_extras' "${tmp_home}/.bash_profile")"
ssh_matches="$(grep -Fc 'Include ~/.ssh/config.d/*.conf' "${tmp_home}/.ssh/config")"

test "$profile_matches" -eq 1
test "$ssh_matches" -eq 1
grep -Fq "alias ..code='cd ${tmp_code_dir}'" "${tmp_home}/.bash_custom"

HOME="$tmp_home" bash -ic 'alias ls' 2>/dev/null | grep -Fq "alias ls='__basrc_ls -la'"

echo "install.sh passed"
