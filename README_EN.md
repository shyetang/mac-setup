# mac-setup

🚀 **Fully Automated macOS Development Environment Initialization Script**

> **Design Philosophy**: Born from a personal experience of downgrading and reinstalling macOS 15 to 14. Designed to provide a one-click solution for **"System Reinstall"**, **"New Mac Setup"**, or **"Disaster Recovery"**, restoring a clean Mac to a familiar productivity powerhouse in the time it takes to drink a coffee.

One-click deployment of a full-stack development environment, supporting intelligent configuration detection and batch management of common software via a manifest file.

[中文文档](README.md) | **English**

## ✨ Features

- ✅ **One-Click Initialization** - Automatically installs and configures the entire development environment (Node, Python, Rust, Go, Java)
- ✅ **Manifest Management** - Declaratively manage all CLI and GUI software via `brew-packages.txt`; migration only requires one file
- ✅ **Intelligent Config Merging** - Automatically detects existing Oh My Zsh configurations and intelligently merges plugin lists without breaking original settings
- ✅ **Full Backup & Restore** - Auto-backup before changes; `rollback` provides complete rollback capability
- ✅ **Smart Idempotency** - Safe to run multiple times without duplicate installations or conflicts
- ✅ **Dual Scripts** - Both Shell and Python implementations available

## 🎯 What's Included

| Category        | Tools                                                      |
| :-------------- | :--------------------------------------------------------- |
| **System**      | Homebrew, Oh My Zsh, Starship, fzf, zoxide                 |
| **OMZ Plugins** | zsh-syntax-highlighting, zsh-autosuggestions               |
| **Languages**   | Python, Node.js, Java (Mise), Rust (rustup), Go (Homebrew) |
| **Packages**    | Defined by `brew-packages.txt`                             |

## 🚀 Quick Start

### Option 1: Python Script (Recommended)

```bash
git clone <repo-url> mac-setup && cd mac-setup

# Execute installation
python3 mac-setup.py

# Or skip confirmation
python3 mac-setup.py --yes
```

### Option 2: Shell Script

```bash
chmod +x setup-macos.sh
./setup-macos.sh
```

### Verify Environment

```bash
exec zsh  # Reload terminal
python --version && node --version && rustc --version && go version
```

## 📦 Script Comparison

| Feature            | `mac-setup.py` | `setup-macos.sh` |
| ------------------ | -------------- | ---------------- |
| Version Manager    | **Mise**       | pyenv/fnm/jenv   |
| Rust Installation  | **rustup**     | rustup           |
| Go Installation    | **Homebrew**   | Homebrew         |
| CLI Arguments      | ✅ `--yes` etc | ❌               |
| External Config    | ✅             | ✅               |
| Smart Config Merge | ✅ OOP         | ✅ awk           |

> 💡 **Recommended: `mac-setup.py`**: Mise is a modern all-in-one version manager replacing pyenv/fnm/jenv

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

> 💡 See `supplementary-application.txt` for optional software recommendations

## ⚙️ Customization

### Python Script (`mac-setup.py`)

Edit the configuration at the top:

```python
# Languages managed by Mise
MISE_VERSIONS = {
    "python": "3.12",
    "node": "22",
    "java": "temurin-21",
}

# Go and Rust use official tools
# - Go: Homebrew installation
# - Rust: rustup official tool
```

### Command Line Arguments

```bash
python3 mac-setup.py --help

# Available options:
#   --yes, -y       Skip confirmation prompts
#   --no-starship   Don't use Starship theme
#   --dry-run       Simulation only
```

## 🔄 Rollback

### Python Rollback (For use with `mac-setup.py`)

```bash
python3 rollback.py --mode soft   # Disable config blocks
python3 rollback.py --mode env    # Delete env directories ✨
python3 rollback.py --mode full   # Full rollback (High Risk)
```

### Shell Rollback (For use with `setup-macos.sh`)

```bash
./rollback.sh soft   # Disable config blocks
./rollback.sh env    # Delete env directories
./rollback.sh full   # Full rollback
```

| Mode     | Effect                                            |
| :------- | :------------------------------------------------ |
| **soft** | Disables config blocks (deletes nothing)          |
| **env**  | Removes configs, deletes language environments ✨ |
| **full** | Uninstalls all software (High Risk)               |

> 💡 **Recommended: env mode**: Completely restores the state to before the script was run.

## 🔧 Troubleshooting

### Homebrew Install Failed

```bash
# Check network
ping -c 3 github.com

# Manual install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Apple Silicon PATH
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
```

### .zshrc Config Issues

```bash
# Check backups
ls -la ~/.mac-setup-backup/

# Restore backup
cp ~/.mac-setup-backup/original-.zshrc.latest ~/.zshrc

# Or run rollback
python3 rollback.py --mode env
```

## 📁 File Descriptions

| File                            | Purpose                          |
| :------------------------------ | :------------------------------- |
| `mac-setup.py`                  | **Python install (Recommended)** |
| `rollback.py`                   | **Python rollback script**       |
| `setup-macos.sh`                | Shell installation script        |
| `rollback.sh`                   | Shell rollback script            |
| `brew-packages.txt`             | Package configuration list       |
| `supplementary-application.txt` | Optional software list           |

## 🌍 Compatibility

| System                      | Status       | Notes                    |
| :-------------------------- | :----------- | :----------------------- |
| macOS 14 Sonoma             | ✅ Tested    | Dev/Test environment     |
| macOS (Intel/Apple Silicon) | ✅ Supported | Homebrew path auto-adapt |
| macOS 12 Monterey+          | ✅ Supported | Dependency compatibility |

## 📄 License

MIT License
