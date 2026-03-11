# basrc

Portable Bash setup for a quick `git clone` + install workflow.

The goal of this repo is simple:

- keep preferred Bash aliases, functions, and login-shell settings in git
- install them onto a machine without replacing the machine's existing shell startup flow
- leave clear extension points for host-specific overrides

## What it installs

Running `./install.sh` installs these pieces into your home directory:

- `~/.bash_profile_extras`
- `~/.bashrc_extras`
- `~/.bash_custom`

It also ensures `~/.bash_profile` loads:

1. `~/.profile`
2. `~/.bash_profile_extras`

and ensures `~/.bashrc` loads:

1. `~/.bashrc_extras`

For SSH config, it installs this repo's managed entries into:

- `~/.ssh/config.d/basrc.conf`

and makes sure your main `~/.ssh/config` includes `~/.ssh/config.d/*.conf`.

That avoids clobbering an existing SSH config and makes the setup extensible.

## Install

```bash
git clone <repo-url> ~/code/basrc
cd ~/code/basrc
./install.sh
source ~/.bash_profile
```

The installer is designed to be rerun safely:

- it asks for your code directory and defaults to `~/code`
- it also accepts `CODE_DIR=/path/to/code ./install.sh` for non-interactive installs
- it creates the code directory if it does not already exist
- it works from any current directory
- it verifies required repo files before changing your home directory
- it keeps `~/.profile` in the login-shell path
- it wires interactive shortcuts into `~/.bashrc`, so new terminal windows get them automatically
- it writes managed SSH hosts to `~/.ssh/config.d/basrc.conf`
- it creates `*.basrc.bak` backups before modifying `~/.bash_profile` or `~/.ssh/config`

## File layout

- `.bash_profile_extras`: shared login-shell settings, aliases, functions
- `.bashrc_extras`: shared interactive-shell settings
- `.bash_custom`: personal overrides copied to the target machine
- `.ssh/config`: SSH hosts managed by this repo
- `install.sh`: idempotent installer

## Included shortcuts

This repo now includes a portable baseline of shell helpers:

- Navigation: `mkcd`, `take`, `up`, `cdf`
- File search: `ff`, `rgf`
- Listing: `ls`, `ll`, `la`, `l`, `lt`
- Disk usage: `du1`, `largest`, `howfull`, `foldersize`
- Shell helpers: `reload`, `path`, `backup`, `extract`, `serve`
- Networking: `myip`, `ports`
- Docker: `dps`
- Git: `gst`, `gco`, `gsw`, `gcm`, `gl`, `gundo`, `branchpurge`

The shortcuts are designed to degrade cleanly:

- if `fzf` is missing, `cdf`, `ff`, and `rgf` print a clear message
- if `eza` or `tree` is missing, `lt` falls back to `find`
- if `ss` is missing, `ports` falls back to `lsof` or `netstat`
- if `docker`, `curl`, `wget`, or Python are missing, the related helpers fail cleanly instead of breaking shell startup

## Extension points

Use these for machine-specific or private settings that should not live in the shared repo:

- `~/.bash_profile_local`
- `~/.bashrc_local`
- `~/.bash_custom`
- `~/.ssh/config.d/*.conf`

Recommended split:

- put reusable defaults in this repo
- put per-machine or secret values in the local override files
- keep `install.sh` responsible only for wiring files together safely

## Design choices

- Idempotent install: re-running the installer should not duplicate profile blocks.
- Preserve normal shell startup: `~/.profile` is still loaded.
- Safe SSH setup: existing `~/.ssh/config` is not overwritten.
- Portable defaults: shell config should prefer `$HOME` over hardcoded usernames and tolerate missing tools.
- Cross-platform shell behavior: command wrappers account for GNU/Linux, macOS, WSL, and stripped-down SSH hosts where tool availability differs.

## Notes

- `~/.bash_custom` is only created if it does not already exist, so local edits survive reinstalls.
- If you want to keep a personal `.bash_custom` in git, replace that behavior with a symlink-based install strategy.
