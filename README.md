# dotfiles

Personal Mac setup — everything needed to rebuild from scratch on a new machine.

## What's inside

| Directory | Contents |
|-----------|----------|
| `macos/` | `Brewfile`, `defaults.sh` (system preferences) |
| `shell/` | `.zshrc`, `aliases.sh`, `exports.sh` |
| `git/` | `.gitconfig`, `.gitignore_global` |
| `apps/ai/` | Shared MCP server config (`mcp.json`) |
| `apps/claude/` | Claude Code settings, statusline script |
| `apps/idea/` | IntelliJ IDEA file templates and live templates |
| `scripts/` | Individual install steps |
| `tools/` | Custom programs |

## Configuration

Before running, review `config.sh` — single place to change:

| Variable | Description |
|----------|-------------|
| `COMPUTER_NAME` | Machine hostname |
| `ZSH_THEME` | Oh My Zsh theme |
| `JAVA_VERSION` | Active Java version |
| `NODE_VERSION` | Node version installed via nvm |
| `MARKETPLACE_REPO` | Claude skills marketplace repo |

## Fresh Mac setup

```bash
git clone https://github.com/radovansinko/dotfiles.git ~/Developer/personal/repo/dotfiles
cd ~/Developer/personal/repo/dotfiles
./install.sh
```

## Running individual steps

```bash
./install.sh --list           # list all available steps
./install.sh --step homebrew  # run a single step by name
./install.sh --step node
```

## All steps

| Step | Name | What it does |
|------|------|-------------|
| 1 | `xcode` | Xcode Command Line Tools |
| 2 | `ohmyzsh` | Oh My Zsh |
| 3 | `homebrew` | Homebrew + all packages from `Brewfile` |
| 4 | `mas` | App Store apps |
| 5 | `shell` | Shell config symlinks |
| 6 | `git` | Git config + global gitignore |
| 7 | `marketplace` | Claude skills marketplace |
| 8 | `claude` | Claude Code settings + MCP servers |
| 9 | `cursor` | Cursor MCP servers symlink |
| 10 | `idea` | IntelliJ IDEA settings + plugins |
| 11 | `macos` | macOS system defaults |
| 12 | `node` | Node via nvm |
| 13 | `dirs` | `~/Developer` folder structure |
| 14 | `env` | `.env` file check |

## Keeping up to date

```bash
./update.sh
# or via alias:
dotfiles-update
```

Pulls latest changes and re-applies symlinks, updates Oh My Zsh, marketplace skills, and Homebrew packages.

## Manual steps (post-install)

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
├── install.sh             # Bootstrap — run this on a new Mac
├── update.sh              # Updater — run anytime after setup
├── config.sh              # Central config (names, versions, URLs)
├── macos/
│   ├── Brewfile
│   └── defaults.sh
├── shell/
│   ├── .zshrc
│   ├── aliases.sh
│   └── exports.sh
├── git/
│   ├── .gitconfig
│   └── .gitignore_global
├── apps/
│   ├── ai/                # Shared MCP config (Claude, Cursor)
│   ├── claude/            # Claude Code settings + statusline
│   └── idea/              # IntelliJ IDEA settings
├── scripts/
└── tools/
```

## License

[MIT](LICENSE)
