# mac-setup

🚀 **Fully Automated macOS Development Environment Initialization Script**

> **Design Philosophy**: Born from a personal experience of downgrading and reinstalling macOS 15 to 14. Designed to provide a one-click solution for **"System Reinstall"**, **"New Mac Setup"**, or **"Disaster Recovery"**, restoring a clean Mac to a familiar productivity powerhouse in the time it takes to drink a coffee.

One-click deployment of a full-stack development environment, supporting intelligent configuration detection and batch management of common software via a manifest file.

[中文文档](README.md) | **English**

## ✨ Features

- ✅ **One-Click Initialization** - Automatically installs and configures the entire development environment (Node, Python, Rust, Go, Java)
- ✅ **Manifest Management** - Declaratively manage all CLI and GUI software via `brew-packages.txt`; migration only requires one file
- ✅ **Intelligent Config Merging** - Automatically detects existing Oh My Zsh configurations and intelligently merges plugin lists without breaking original settings
- ✅ **Full Backup & Restore** - Auto-backup before changes; `rollback.sh env` provides a complete rollback, giving you peace of mind even when experimenting
- ✅ **Smart Idempotency** - Safe to run multiple times without duplicate installations or conflicts

## 🎯 What's Included

| Category        | Tools                                                                                 |
| :-------------- | :------------------------------------------------------------------------------------ |
| **System**      | Homebrew, Oh My Zsh, Starship, fzf, zoxide                                            |
| **OMZ Plugins** | zsh-syntax-highlighting (Syntax Highlighting), zsh-autosuggestions (Auto Suggestions) |
| **Languages**   | Python (pyenv), Node.js (fnm), Rust (rustup), Java (jenv), Go (Homebrew)              |
| **Packages**    | Defined by `brew-packages.txt`                                                        |

## 🚀 Quick Start

### 1. Clone & Configure

```bash
git clone <repo-url> mac-setup && cd mac-setup

# View/Edit software list
cat brew-packages.txt
vim brew-packages.txt  # Optional: Customize
```

### 2. Execute Install

```bash
chmod +x setup-macos.sh
./setup-macos.sh
```

### 3. Verify Environment

```bash
exec zsh  # Reload terminal
python --version && node --version && java -version
```

## 📦 brew-packages.txt Format

```bash
# ===== Formulae (CLI Tools) =====
git
ripgrep
fzf

# ===== Casks (GUI Apps) =====
visual-studio-code
google-chrome
```

**Rules:**

- `# ===== Formulae` marks CLI tools, `# ===== Casks` marks GUI apps
- One package name per line, other lines starting with `#` are comments
- **File must end with a newline**

### Default Software List

#### CLI Tools (Formulae)

| Software     | Description                             |
| :----------- | :-------------------------------------- |
| `git`        | Version control system                  |
| `wget`       | File retrieval tool                     |
| `ripgrep`    | Fast text search (10x faster than grep) |
| `fd`         | Modern file finding (find alternative)  |
| `fzf`        | Fuzzy finder (Ctrl+R history search)    |
| `jq`         | JSON processor                          |
| `bat`        | Cat clone with syntax highlighting      |
| `htop`       | Interactive process viewer              |
| `zoxide`     | Smarter cd command                      |
| `cmake`      | Cross-platform build tool               |
| `pkg-config` | Compile time library locating           |
| `starship`   | Modern command prompt                   |

#### GUI Apps (Casks)

| Software             | Description                          |
| :------------------- | :----------------------------------- |
| `keka`               | File archiver                        |
| `drawio`             | Diagramming tool                     |
| `iina`               | Modern video player                  |
| `baidunetdisk`       | Baidu Netdisk                        |
| `appcleaner`         | Uninstaller                          |
| `warp`               | Modern terminal (Rust-based)         |
| `raycast`            | Spotlight replacement and launcher   |
| `openinterminal`     | Open terminal from Finder            |
| `devtoys`            | Developer utilities                  |
| `popclip`            | Text selection actions               |
| `google-chrome`      | Web browser                          |
| `buzz`               | Audio to text (Whisper based)        |
| `betterdisplay`      | Display management                   |
| `aldente`            | Battery charge limiter               |
| `visual-studio-code` | Code editor                          |
| `zed`                | High-performance editor (Rust-based) |
| `iterm2`             | Terminal emulator                    |

> 💡 Add or remove software in `brew-packages.txt` as needed.

### Optional/Recommended Software

See `supplementary-application.txt` for a list of recommended tools like Cursor, Docker, OrbStack, etc.

## ⚙️ Customization

Edit the top of `setup-macos.sh`:

```bash
# Set to 0 to skip specific language installation
INSTALL_NODE=1
INSTALL_PYTHON=1
INSTALL_RUST=1
INSTALL_JAVA=1
INSTALL_GO=1

# Version Strategy (Major version lock)
PYTHON_MAJOR="3.12"   # → 3.12.x latest
NODE_MAJOR="22"       # → 22.x latest
JAVA_MAJOR="21"       # → 21 LTS
# Go is managed by Homebrew, always latest
```

## 🔄 Rollback

| Mode     | Command              | Effect                                                                        |
| :------- | :------------------- | :---------------------------------------------------------------------------- |
| **soft** | `./rollback.sh soft` | Disables config blocks (deletes nothing)                                      |
| **env**  | `./rollback.sh env`  | Removes configs, deletes language environments, restores original settings ✨ |
| **full** | `./rollback.sh full` | Uninstalls all software (High Risk)                                           |

> 💡 **Recommended: env mode**: Completely restores the state to before the script was run.

## 🔧 Troubleshooting

### Homebrew Install Failed/Network Issues

Use the manual install command or check your network connection to GitHub.

### Python/Node Version Not Found

Check available versions with `pyenv install -l` or `fnm list-remote` and update the versions in `setup-macos.sh`.

### .zshrc Config Issues

Check `~/.mac-setup-backup/` for backups and restore if necessary, or run `./rollback.sh env`.

## 📁 File Descriptions

| File                            | Purpose                    |
| :------------------------------ | :------------------------- |
| `setup-macos.sh`                | Main installation script   |
| `rollback.sh`                   | 3-level rollback script    |
| `brew-packages.txt`             | Package configuration list |
| `supplementary-application.txt` | Optional software list     |
| `test-backup-restore.sh`        | Backup/Restore test script |

## 🌍 Compatibility

| System                      | Status       | Notes                    |
| :-------------------------- | :----------- | :----------------------- |
| macOS 14 Sonoma             | ✅ Tested    | Dev/Test environment     |
| macOS (Intel/Apple Silicon) | ✅ Supported | Homebrew path auto-adapt |
| macOS 12 Monterey+          | ✅ Supported | Dependency compatibility |

## 📄 License

MIT License
