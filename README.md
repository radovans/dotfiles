# dotfiles

Personal Mac setup — everything needed to rebuild from scratch on a new machine.

## What's inside

| Directory | Contents |
|-----------|----------|
| `macos/` | `Brewfile`, `defaults.sh` (system preferences) |
| `shell/` | `.zshrc`, `aliases.sh`, `exports.sh` |
| `git/` | `.gitconfig`, `.gitignore_global` |
| `claude/` | Claude Code skills |
| `scripts/` | Individual install steps + `update.sh` |
| `tools/` | Custom programs |
| `apps/` | App-specific config files |

## Fresh Mac setup

Clone the repo anywhere and run the installer:

```bash
git clone https://github.com/radovansinko/dotfiles.git ~/Developer/personal/repo/dotfiles
cd ~/Developer/personal/repo/dotfiles
./install.sh
```

The script handles everything in order:

| Step | What it does |
|------|-------------|
| 1 | Xcode Command Line Tools |
| 2 | Oh My Zsh |
| 3 | Homebrew + all packages from `macos/Brewfile` |
| 4 | App Store apps via `mas` |
| 5 | Shell config symlinks (`.zshrc`, aliases, exports) |
| 6 | Git config + global gitignore |
| 7 | Claude Code skills |
| 8 | macOS system defaults |
| 9 | Node via nvm |
| 10 | `~/Developer` folder structure |
| 11 | `.env` file check |

## Keeping up to date

After the initial setup, run this anytime to pull changes and re-apply:

```bash
dotfiles-update
# or directly:
bash scripts/update.sh
```

## Manual steps (post-install)

Some things can't be automated:

- Sign in to App Store, iCloud, and other services
- Restore secrets from your password manager into `.env`
- Configure SSH keys (`~/.ssh/`)
- Activate any app licenses

## Environment variables

```bash
cp .env.example .env
# fill in your values
```

## Structure

```
dotfiles/
├── install.sh
├── .env.example
├── .gitignore
│
├── macos/
│   ├── Brewfile           # Homebrew packages, casks, fonts
│   └── defaults.sh        # macOS system preference overrides
│
├── shell/
│   ├── .zshrc
│   ├── aliases.sh
│   └── exports.sh
│
├── git/
│   ├── .gitconfig
│   └── .gitignore_global
│
├── scripts/
│   ├── lib.sh             # shared colors + helpers
│   ├── xcode.sh
│   ├── ohmyzsh.sh
│   ├── homebrew.sh
│   ├── mas.sh             # App Store apps
│   ├── shell.sh
│   ├── git.sh
│   ├── claude.sh
│   ├── macos.sh
│   ├── node.sh
│   ├── dirs.sh
│   ├── env.sh
│   └── update.sh          # pull + re-apply
│
├── claude/
│   └── skills/
│
├── tools/
└── apps/
```

## License

[MIT](LICENSE)
