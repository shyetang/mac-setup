#!/usr/bin/env python3
"""
macOS 全自动化环境配置脚本 (Powered by Python & Mise)

功能:
- 安装 Homebrew 和软件包
- 配置 Oh My Zsh 和插件
- 使用 Mise 统一管理编程语言版本
- 智能配置合并与备份
"""

import argparse
import os
import platform
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import List

# ================= Configuration =================
# Mise 管理的语言版本（Python/Node/Java 多版本需求高）
MISE_VERSIONS = {
    "python": "3.12",
    "node": "22",
    "java": "temurin-21",  # 推荐使用 Temurin (Adoptium) 发行版（mise ls-remote java 查看可用版本）
}

# Go 和 Rust 使用官方推荐的工具管理
# - Go: Homebrew 直接安装（单版本足够）
# - Rust: rustup 官方工具（生态深度绑定）

# 基础编译依赖 (构建 Python/Ruby 等必须)
BASE_BREW_PACKAGES = [
    "git",
    "curl",
    "wget",
    "openssl@3",
    "readline",
    "sqlite3",
    "xz",
    "zlib",
    "tcl-tk",
    "go",  # Go 语言（Homebrew 直接安装）
    "rustup",  # Rust 官方版本管理器
]

# 默认用户软件列表 (作为 fallback，与 brew-packages.txt 保持同步)
DEFAULT_BREW_FORMULAE = [
    "git",
    "wget",
    "ripgrep",
    "fd",
    "fzf",
    "jq",
    "bat",
    "htop",
    "zoxide",
    "cmake",
    "pkg-config",
    "starship",
]
DEFAULT_BREW_CASKS = [
    "keka",
    "iina",
    "appcleaner",
    "warp",
    "raycast",
    "openinterminal",
    "popclip",
    "google-chrome",
    "betterdisplay",
    "visual-studio-code",
    "zed",
    "iterm2",
    "switchhosts",
    "jordanbaird-ice",
    "battery-toolkit",
    "font-maple-mono-nf-cn",
]

# Oh My Zsh 默认插件
OMZ_PLUGINS = [
    "git",
    "sudo",
    "extract",
    "fzf",
    "colored-man-pages",
    "zsh-syntax-highlighting",
    "zsh-autosuggestions",
]

# 路径
ZSHRC_PATH = Path.home() / ".zshrc"
BACKUP_DIR = Path.home() / ".mac-setup-backup"
SCRIPT_DIR = Path(__file__).parent.resolve()
PACKAGES_FILE = SCRIPT_DIR / "brew-packages.txt"

# ================= Helpers =================

# 日志文件路径
LOG_FILE = BACKUP_DIR / f"setup-{datetime.now().strftime('%Y%m%d%H%M%S')}.log"
_log_file_handle = None


def _init_log_file():
    """初始化日志文件"""
    global _log_file_handle
    if _log_file_handle is None:
        BACKUP_DIR.mkdir(parents=True, exist_ok=True)
        _log_file_handle = open(LOG_FILE, "a", encoding="utf-8")
    return _log_file_handle


def log(msg, level="INFO"):
    """带颜色的日志输出，同时写入日志文件"""
    colors = {
        "INFO": "\033[94m",  # Blue
        "SUCCESS": "\033[92m",  # Green
        "WARN": "\033[93m",  # Yellow
        "ERROR": "\033[91m",  # Red
        "RESET": "\033[0m",
    }
    icons = {"INFO": "ℹ️", "SUCCESS": "✅", "WARN": "⚠️", "ERROR": "❌"}

    # 控制台输出（带颜色）
    print(f"{colors.get(level, '')}{icons.get(level, '')} {msg}{colors['RESET']}")

    # 写入日志文件（无颜色）
    try:
        f = _init_log_file()
        timestamp = datetime.now().strftime("%H:%M:%S")
        f.write(f"[{timestamp}] [{level}] {msg}\n")
        f.flush()
    except Exception:
        pass  # 日志文件写入失败不影响主流程


def run_cmd(cmd, shell=False, check=True, capture=False, env=None):
    """运行系统命令，增强错误信息显示"""
    try:
        merged_env = {**os.environ, **(env or {})}
        if shell:
            result = subprocess.run(
                cmd,
                shell=True,
                check=check,
                executable="/bin/zsh",
                capture_output=True,  # 始终捕获以便显示错误
                text=True,
                env=merged_env,
            )
        else:
            result = subprocess.run(
                cmd, check=check, capture_output=True, text=True, env=merged_env
            )
        return result if capture else None
    except subprocess.CalledProcessError as e:
        # 显示详细错误信息
        cmd_str = cmd if isinstance(cmd, str) else " ".join(cmd)
        log(f"命令执行失败: {cmd_str}", "ERROR")
        if e.stderr:
            # 只显示前 500 字符避免刷屏
            stderr_preview = e.stderr.strip()[:500]
            log(f"  错误详情: {stderr_preview}", "ERROR")
        if check:
            sys.exit(1)
        return None


def check_environment():
    """检测运行环境"""
    # 检测操作系统
    if platform.system() != "Darwin":
        log("此脚本仅支持 macOS 系统！", "ERROR")
        sys.exit(1)

    # 检测 CPU 架构
    arch = platform.machine()
    if arch == "arm64":
        log("检测到 Apple Silicon (M1/M2/M3) 芯片")
    else:
        log(f"检测到 Intel 芯片 ({arch})")

    return arch


def confirm_execution():
    """用户确认流程"""
    print("\n📋 macOS 初始化脚本")
    print("━" * 40)
    print("将执行以下操作：")
    print("  ✓ 安装/更新 Homebrew")
    print("  ✓ 安装 brew-packages.txt 中的软件包")
    print("  ✓ 安装 Oh My Zsh 和配置")
    print("  ✓ 安装编程语言环境：")
    # Mise 管理的语言
    for lang, ver in MISE_VERSIONS.items():
        print(f"    - {lang.capitalize()} {ver} (Mise)")
    # 独立管理的语言
    print("    - Go (Homebrew)")
    print("    - Rust (rustup)")
    print("")

    try:
        confirm = input("确认继续？[y/N]: ").strip().lower()
        if confirm != "y":
            log("用户取消操作", "WARN")
            sys.exit(0)
    except EOFError:
        # 非交互式模式直接继续
        log("非交互式模式，自动继续...")


def ensure_backup_dir():
    """确保备份目录存在"""
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    return BACKUP_DIR


def backup_file(file_path, prefix=""):
    """备份文件"""
    if not file_path.exists():
        return None

    backup_dir = ensure_backup_dir()
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    backup_name = f"{prefix}{file_path.name}.{timestamp}"
    backup_path = backup_dir / backup_name

    shutil.copy2(file_path, backup_path)
    log(f"  备份创建: {backup_path}")

    # 创建 latest 符号链接（使用相对路径，避免目录移动后失效）
    latest_link = backup_dir / f"{prefix}{file_path.name}.latest"
    if latest_link.exists() or latest_link.is_symlink():
        latest_link.unlink()
    latest_link.symlink_to(backup_name)

    return backup_path


def read_file_content(file_path):
    """安全读取文件内容"""
    if not file_path.exists():
        return ""
    with open(file_path, "r") as f:
        return f.read()


def write_file_content(file_path, content):
    """写入文件内容"""
    with open(file_path, "w") as f:
        f.write(content)


def parse_brew_packages():
    """解析 brew-packages.txt 文件"""
    formulae = []
    casks = []

    if not PACKAGES_FILE.exists():
        log(f"未找到 {PACKAGES_FILE}，使用默认软件包列表", "WARN")
        return DEFAULT_BREW_FORMULAE, DEFAULT_BREW_CASKS

    current_type = None
    with open(PACKAGES_FILE, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            # 识别分类标记
            if re.search(r"^#.*Formulae", line, re.IGNORECASE):
                current_type = "formula"
                continue
            elif re.search(r"^#.*Casks", line, re.IGNORECASE):
                current_type = "cask"
                continue

            # 跳过其他注释
            if line.startswith("#"):
                continue

            # 去掉行内注释
            pkg = re.sub(r"#.*", "", line).strip()
            if not pkg:
                continue

            if current_type == "formula":
                formulae.append(pkg)
            elif current_type == "cask":
                casks.append(pkg)

    log(
        f"从 brew-packages.txt 读取: {len(formulae)} 个 formulae, {len(casks)} 个 casks"
    )
    return formulae, casks


def ensure_line_in_file(file_path, line, marker=None, prepend=False):
    """确保文件中包含某行内容，支持幂等操作

    Args:
        file_path: 目标文件路径
        line: 要添加的内容
        marker: 标记名称（用于创建 ### marker START/END ### 块）
        prepend: 是否插入到文件开头（默认追加到末尾）
    """
    file_path = Path(file_path)
    if not file_path.exists():
        file_path.touch()

    content = read_file_content(file_path)

    # 如果有标记块，检查标记块
    if marker:
        start_marker = f"### {marker} START ###"
        end_marker = f"### {marker} END ###"
        if start_marker in content:
            return  # 已经存在，不再重复添加

        full_block = f"{start_marker}\n{line}\n{end_marker}\n"

        if prepend:
            # 插入到文件开头
            new_content = full_block + "\n" + content
            write_file_content(file_path, new_content)
        else:
            # 追加到文件末尾
            with open(file_path, "a") as f:
                f.write(f"\n{full_block}")
    else:
        if line.strip() not in content:
            if prepend:
                new_content = line + "\n" + content
                write_file_content(file_path, new_content)
            else:
                with open(file_path, "a") as f:
                    f.write(f"\n{line}\n")


# ================= Oh My Zsh Logic (Object Oriented) =================


class ZshConfig:
    """处理 Zsh 配置文件的解析与修改

    功能:
    - 检测 Oh My Zsh 配置
    - 提取/更新 plugins 和 theme
    - 自动排除脚本生成的 AUTO 块
    """

    # AUTO 块的标记模式
    AUTO_BLOCK_PATTERN = re.compile(
        r"(### AUTO-[^\n]*\n)(.*?)(### END AUTO-[^\n]*\n)", re.DOTALL
    )

    def __init__(self, path: Path):
        self.path = path
        self._content: str = ""
        self._load()

    def _load(self) -> None:
        """加载文件内容"""
        if not self.path.exists():
            self._content = ""
            return
        with open(self.path, "r", encoding="utf-8", errors="ignore") as f:
            self._content = f.read()

    def _save(self, content: str) -> None:
        """保存文件内容"""
        with open(self.path, "w", encoding="utf-8") as f:
            f.write(content)
        self._content = content  # 更新缓存

    def reload(self) -> None:
        """重新加载文件内容"""
        self._load()

    @property
    def content(self) -> str:
        """获取当前内容"""
        return self._content

    def backup(self) -> None:
        """备份当前 .zshrc"""
        if not self.path.exists():
            return
        backup_file(self.path, "original-")

    def _get_clean_content(self) -> str:
        """获取移除 AUTO 块后的纯净内容（用于检测用户原有配置）"""
        return self.AUTO_BLOCK_PATTERN.sub("", self._content)

    def has_omz(self) -> bool:
        """检测是否安装了 Oh My Zsh（排除 AUTO 块）"""
        clean = self._get_clean_content()
        return bool(
            re.search(
                r"^(export ZSH=|source \$ZSH/oh-my-zsh\.sh)",
                clean,
                re.MULTILINE,
            )
        )

    def get_plugins(self) -> List[str]:
        """获取用户原有的插件列表（排除 AUTO 块）"""
        clean = self._get_clean_content()
        # 支持单行和多行格式：plugins=(git sudo) 或 plugins=(\n  git\n  sudo\n)
        match = re.search(
            r"^\s*plugins=\(\s*([^)]*?)\s*\)",
            clean,
            re.MULTILINE | re.DOTALL,
        )
        if match:
            raw = match.group(1)
            # 处理换行和多余空格
            plugins = re.split(r"[\s\n]+", raw)
            return [p.strip() for p in plugins if p.strip()]
        return []

    def get_theme(self) -> str:
        """获取用户原有的主题（排除 AUTO 块）"""
        clean = self._get_clean_content()
        match = re.search(r'^\s*ZSH_THEME="([^"]*)"', clean, re.MULTILINE)
        if match:
            return match.group(1)
        return ""

    def update_plugins(self, new_plugins: List[str]) -> None:
        """更新插件列表（只修改非 AUTO 块中的定义）"""
        plugins_str = " ".join(new_plugins)

        # 策略：找到第一个不在 AUTO 块内的 plugins=() 并替换
        content = self._content

        # 获取所有 AUTO 块的位置范围
        auto_spans = [
            (m.start(), m.end()) for m in self.AUTO_BLOCK_PATTERN.finditer(content)
        ]

        # 查找所有 plugins=() 的位置
        plugins_pattern = re.compile(r"^\s*plugins=\([^)]*\)", re.MULTILINE | re.DOTALL)

        for match in plugins_pattern.finditer(content):
            start, end = match.start(), match.end()
            # 检查是否在 AUTO 块内
            in_auto = any(span[0] <= start < span[1] for span in auto_spans)
            if not in_auto:
                # 替换这个匹配
                new_content = (
                    content[:start] + f"plugins=({plugins_str})" + content[end:]
                )
                self._save(new_content)
                return

        # 如果没找到非 AUTO 块中的 plugins，不做任何修改

    def update_theme(self, theme: str) -> None:
        """更新主题（只修改非 AUTO 块中的定义）"""
        content = self._content

        # 获取所有 AUTO 块的位置范围
        auto_spans = [
            (m.start(), m.end()) for m in self.AUTO_BLOCK_PATTERN.finditer(content)
        ]

        # 查找所有 ZSH_THEME="" 的位置
        theme_pattern = re.compile(r'^\s*ZSH_THEME="[^"]*"', re.MULTILINE)

        for match in theme_pattern.finditer(content):
            start, end = match.start(), match.end()
            # 检查是否在 AUTO 块内
            in_auto = any(span[0] <= start < span[1] for span in auto_spans)
            if not in_auto:
                # 保留原有缩进
                indent = ""
                indent_match = re.match(r"^(\s*)", match.group())
                if indent_match:
                    indent = indent_match.group(1)

                new_content = (
                    content[:start] + f'{indent}ZSH_THEME="{theme}"' + content[end:]
                )
                self._save(new_content)
                return


def merge_plugins(existing: List[str], new_plugins: List[str]) -> List[str]:
    """合并插件列表（去重并保持顺序）"""
    seen = set()
    result = []
    # 优先保留原有的
    for p in existing:
        if p not in seen:
            seen.add(p)
            result.append(p)
    # 添加新的
    for p in new_plugins:
        if p not in seen:
            seen.add(p)
            result.append(p)
    return result


# ================= Installation Steps =================


def install_homebrew(arch):
    """安装或更新 Homebrew"""
    log("检查 Homebrew...")
    if shutil.which("brew"):
        log("Homebrew 已安装")
        run_cmd(["brew", "update"], check=False)
    else:
        log("正在安装 Homebrew...")
        cmd = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        run_cmd(cmd, shell=True)

    # Apple Silicon 芯片路径适配
    if arch == "arm64" and Path("/opt/homebrew/bin/brew").exists():
        # 添加到当前进程 PATH
        os.environ["PATH"] = (
            f"/opt/homebrew/bin:/opt/homebrew/sbin:{os.environ.get('PATH', '')}"
        )

        # 写入 .zshrc（确保 Homebrew 工具优先于系统工具）
        homebrew_path_config = '''# Homebrew (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"'''
        ensure_line_in_file(
            ZSHRC_PATH, homebrew_path_config, marker="HOMEBREW-PATH", prepend=True
        )
    elif arch != "arm64" and Path("/usr/local/bin/brew").exists():
        # Intel Mac
        homebrew_path_config = '''# Homebrew (Intel)
eval "$(/usr/local/bin/brew shellenv)"'''
        ensure_line_in_file(
            ZSHRC_PATH, homebrew_path_config, marker="HOMEBREW-PATH", prepend=True
        )


def install_brew_packages():
    """安装 Homebrew 软件包"""
    log("安装/更新 Homebrew 软件包...")

    # 1. 安装基础编译依赖
    log("安装编译依赖 (OpenSSL, Readline等)...")
    run_cmd(["brew", "install"] + BASE_BREW_PACKAGES, check=False)

    # 2. 解析外部配置文件
    formulae, casks = parse_brew_packages()

    # 3. 生成临时 Brewfile 并安装
    brewfile_content = ""
    for pkg in formulae:
        brewfile_content += f'brew "{pkg}"\n'
    for cask in casks:
        brewfile_content += f'cask "{cask}"\n'

    brewfile_path = Path("/tmp/Brewfile_setup_temp")
    write_file_content(brewfile_path, brewfile_content)

    log("执行 Brew Bundle...")
    run_cmd(["brew", "bundle", "--file", str(brewfile_path)], check=False)
    brewfile_path.unlink(missing_ok=True)


def install_oh_my_zsh():
    """安装 Oh My Zsh"""
    log("检查 Oh My Zsh...")
    omz_path = Path.home() / ".oh-my-zsh"

    if omz_path.exists():
        log("Oh My Zsh 已安装")
    else:
        log("安装 Oh My Zsh...")
        # 使用完整的环境变量控制，避免覆盖现有 .zshrc
        cmd = 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
        env = {"RUNZSH": "no", "CHSH": "no", "KEEP_ZSHRC": "yes"}
        run_cmd(cmd, shell=True, env=env)

    # 安装插件
    custom_plugins_dir = omz_path / "custom" / "plugins"
    plugins = {
        "zsh-syntax-highlighting": "https://github.com/zsh-users/zsh-syntax-highlighting.git",
        "zsh-autosuggestions": "https://github.com/zsh-users/zsh-autosuggestions.git",
    }

    for name, url in plugins.items():
        p_path = custom_plugins_dir / name
        if not p_path.exists():
            log(f"Cloning {name}...")
            run_cmd(["git", "clone", url, str(p_path)])


def setup_mise(skip_langs=None):
    """安装和配置 Mise (管理 Python/Node/Java)

    Args:
        skip_langs: 要跳过的语言集合
    """
    skip_langs = skip_langs or set()

    log("安装 Mise (版本管理器)...")
    if not shutil.which("mise"):
        run_cmd(["brew", "install", "mise"])

    # 激活 Mise 到 Zsh
    log("配置 Mise Shell 激活...")
    ensure_line_in_file(
        ZSHRC_PATH, 'eval "$(mise activate zsh)"', marker="MISE-ACTIVATE"
    )

    # 全局设置语言版本 (仅 Python/Node/Java，排除跳过的)
    tools_to_install = []
    descriptions = []

    for lang, ver in MISE_VERSIONS.items():
        if lang.lower() in skip_langs:
            log(f"  跳过 {lang}（--skip-langs {lang}）", "WARN")
            continue
        tools_to_install.append(f"{lang}@{ver}")
        descriptions.append(f"{lang} {ver}")

    if not tools_to_install:
        log("所有 Mise 语言均被跳过，无需安装", "WARN")
        return

    log(f"使用 Mise 安装编程语言环境: {', '.join(descriptions)}...")
    log(f"Mise: 正在安装 {', '.join(descriptions)} (这可能需要几分钟编译)...")

    # 批量安装
    cmd = f"mise use --global {' '.join(tools_to_install)}"
    run_cmd(cmd, shell=True)


def setup_rust():
    """配置 Rust (使用 rustup)"""
    log("配置 Rust (rustup)...")

    # rustup 已通过 Homebrew 安装，需要初始化
    if not shutil.which("rustc"):
        log("初始化 rustup...")
        run_cmd("rustup-init -y --no-modify-path", shell=True)
    else:
        log("Rust 已安装")
        # 更新到最新 stable
        run_cmd("rustup update stable", shell=True, check=False)

    # 添加 Rust 到 PATH
    rust_config = '''export PATH="$HOME/.cargo/bin:$PATH"'''
    ensure_line_in_file(ZSHRC_PATH, rust_config, marker="AUTO-RUST")


def setup_go():
    """配置 Go 环境变量"""
    log("配置 Go 环境变量...")

    # Go 已通过 Homebrew 安装，只需配置 GOPATH
    go_config = '''export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"'''
    ensure_line_in_file(ZSHRC_PATH, go_config, marker="AUTO-GO")


def configure_zsh_final(skip_starship_ask=False, force_no_starship=False):
    """最终配置 .zshrc

    Args:
        skip_starship_ask: 跳过询问，默认使用 starship
        force_no_starship: 强制不使用 starship（优先级高于 skip_starship_ask）
    """
    log("最终配置 .zshrc...")

    zsh_config = ZshConfig(ZSHRC_PATH)

    # 备份原始配置 (如果文件存在)
    zsh_config.backup()

    if zsh_config.has_omz():
        log("检测到现有 Oh My Zsh 配置，执行智能合并")

        # 提取现有配置
        existing_plugins = zsh_config.get_plugins()
        existing_theme = zsh_config.get_theme()

        log(f"  现有插件: {' '.join(existing_plugins) if existing_plugins else '无'}")
        log(f"  现有主题: {existing_theme or '无'}")

        # 合并插件
        merged_plugins = merge_plugins(existing_plugins, OMZ_PLUGINS)
        log(f"  合并后插件: {' '.join(merged_plugins)}")

        # 决定是否使用 Starship
        if force_no_starship:
            use_starship = False
            log("  参数 --no-starship 已启用，保留原有主题")
        elif skip_starship_ask:
            use_starship = True
        elif existing_theme and existing_theme != '""':
            log("")
            log("  💡 脚本推荐使用 starship（现代化命令行提示符）")
            log("     - 更美观的终端提示")
            log("     - 自动显示 git 分支、环境状态")
            log("     - 高性能（Rust 编写）")
            try:
                choice = input("  是否改用 starship？[Y/n]: ").strip().lower()
                use_starship = choice != "n"
            except EOFError:
                use_starship = True
        else:
            use_starship = True

        # 更新插件列表
        zsh_config.update_plugins(merged_plugins)

        # 如果使用 starship，清空主题
        if use_starship:
            zsh_config.update_theme("")

        # 添加 starship 配置块
        if use_starship:
            starship_block = """if command -v starship > /dev/null 2>&1; then
  eval "$(starship init zsh)"
fi"""
            ensure_line_in_file(ZSHRC_PATH, starship_block, marker="AUTO-SETUP-CORE")
    else:
        # 无现有配置，使用完整配置块
        log("未检测到 Oh My Zsh 配置，添加完整配置块")

        plugins_str = " ".join(OMZ_PLUGINS)
        full_config = f"""export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=({plugins_str})
source $ZSH/oh-my-zsh.sh

if command -v starship > /dev/null 2>&1; then
  eval "$(starship init zsh)"
fi"""
        ensure_line_in_file(ZSHRC_PATH, full_config, marker="AUTO-SETUP-CORE")

    # Zoxide 配置（运行时检测）
    zoxide_block = """if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi"""
    ensure_line_in_file(ZSHRC_PATH, zoxide_block, marker="AUTO-ZOXIDE")

    # 现代化 CLI 工具别名（运行时检测，避免覆盖用户习惯）
    aliases_block = """# 现代化 CLI 工具别名
command -v bat >/dev/null && alias cat='bat --paging=never'
command -v fd >/dev/null && alias find='fd'
command -v rg >/dev/null && alias grep='rg'
command -v htop >/dev/null && alias top='htop'
command -v eza >/dev/null && alias ls='eza' && alias ll='eza -lah'"""
    ensure_line_in_file(ZSHRC_PATH, aliases_block, marker="AUTO-ALIASES")


def configure_fzf():
    """配置 fzf 补全和快捷键"""
    log("配置 fzf 补全...")

    # 获取 brew prefix
    result = run_cmd(["brew", "--prefix"], capture=True, check=False)
    if not result or not result.stdout:
        return

    brew_prefix = result.stdout.strip()
    fzf_install = Path(brew_prefix) / "opt" / "fzf" / "install"

    if fzf_install.exists() and os.access(fzf_install, os.X_OK):
        # --no-update-rc 避免重复添加到 .zshrc（已通过 OMZ fzf 插件配置）
        run_cmd(
            [
                str(fzf_install),
                "--key-bindings",
                "--completion",
                "--no-update-rc",
                "--no-bash",
                "--no-fish",
            ],
            check=False,
        )


# ================= Main =================


def main():
    print("🚀 开始 macOS 全自动化环境配置 (Powered by Python & Mise)")
    print("")

    # 0. 参数解析
    parser = argparse.ArgumentParser(
        description="macOS 全自动化环境配置 (Powered by Python & Mise)"
    )
    parser.add_argument("--yes", "-y", action="store_true", help="跳过确认提示")
    parser.add_argument(
        "--no-starship", action="store_true", help="不使用 Starship 主题"
    )
    parser.add_argument("--dry-run", action="store_true", help="仅模拟运行 (部分功能)")
    parser.add_argument(
        "--skip-langs",
        type=str,
        default="",
        help="跳过指定语言安装，逗号分隔（如: python,rust,go）",
    )
    args = parser.parse_args()

    # 解析跳过的语言
    skip_langs = set(
        lang.strip().lower() for lang in args.skip_langs.split(",") if lang.strip()
    )

    # 1. 环境检测
    arch = check_environment()

    # 2. 用户确认
    if not args.yes:
        confirm_execution()
    else:
        log("参数 --yes 已启用，跳过确认环节", "INFO")

    if args.dry_run:
        log("DRY-RUN 模式：脚本到此为止，不执行实际更改。", "WARN")
        return

    # 3. 基础工具
    install_homebrew(arch)

    # 4. 软件与依赖
    install_brew_packages()

    # 5. Shell 美化
    install_oh_my_zsh()

    # 6. 语言环境 (Mise - Python/Node/Java)
    # 检查是否跳过所有 Mise 管理的语言
    mise_langs = set(MISE_VERSIONS.keys())
    if not mise_langs.issubset(skip_langs):
        setup_mise(skip_langs)
    else:
        log("跳过 Mise 语言安装（所有语言均在 --skip-langs 中）", "WARN")

    # 7. Rust (rustup)
    if "rust" not in skip_langs:
        setup_rust()
    else:
        log("跳过 Rust 安装（--skip-langs rust）", "WARN")

    # 8. Go (环境变量配置)
    if "go" not in skip_langs:
        setup_go()
    else:
        log("跳过 Go 配置（--skip-langs go）", "WARN")

    # 9. 收尾配置 (处理 Starship 参数)
    configure_zsh_final(skip_starship_ask=args.yes, force_no_starship=args.no_starship)

    # 10. fzf 配置
    configure_fzf()

    print("")
    log("🎉 所有任务完成！", "SUCCESS")
    print("━" * 40)
    print("后续步骤：")
    print("  1. 重新打开终端（或执行: exec zsh）")
    print(
        "  2. 验证环境: python --version, node --version, rustc --version, go version"
    )
    print(f"  3. 备份文件已保存至: {BACKUP_DIR}")
    print("")
    log("💡 提示: 以后安装新版本只需运行 'mise use --global node@22' 即可", "INFO")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log("\n用户取消操作", "WARN")
        sys.exit(0)
    except Exception as e:
        log(f"发生未预期的错误: {e}", "ERROR")
        sys.exit(1)
