# dotfiles

Personal Mac setup — everything needed to rebuild from scratch on a new machine.

## What's inside

| Directory | Contents |
|-----------|----------|
| `macos/` | System preferences, Homebrew `Brewfile` |
| `shell/` | `.zshrc`, aliases, exports, prompt config |
| `claude/` | Claude Code skills and configuration |
| `tools/` | Custom programs |
| `apps/` | App-specific configs (IntelliJ IDEA, etc.) |

## Fresh Mac setup

### 1. Prerequisites

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Clone & bootstrap

```bash
git clone https://github.com/<your-username>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

That's it. The script handles the rest.

## Manual steps (post-install)

Some things can't be automated. After running `install.sh`:

- Sign in to App Store, iCloud, and other services
- Restore any secrets from your password manager into `.env`
- Configure SSH keys (`~/.ssh/`) — generate new ones or restore from backup
- Set up any app licenses that require manual activation

## Environment variables

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

## Structure

```
dotfiles/
├── README.md              # This file
├── .env.example           # Environment variable template
├── install.sh             # Bootstrap script
│
├── macos/
│   ├── Brewfile           # Homebrew packages, casks, and MAS apps
│   └── defaults.sh        # macOS system preference overrides
│
├── shell/
│   ├── .zshrc
│   ├── aliases.sh
│   └── exports.sh
│
├── claude/
│   └── skills/            # Custom Claude Code skills
│
├── tools/                 # Custom programs and scripts
│
└── apps/                  # App-specific config files
```

## License

[MIT](LICENSE)
