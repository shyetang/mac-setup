#!/usr/bin/env python3
"""
macOS 环境回滚脚本 (配合 mac-setup.py 使用)

回滚模式:
- soft: 仅禁用自动配置块（最安全，不删除任何软件）
- env:  恢复用户环境（删除语言环境目录，推荐）
- full: 完全回滚（卸载 Brewfile 软件，高风险）
"""

import argparse
import re
import shutil
import subprocess
import sys
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Optional

# ================= Configuration =================


class RollbackMode(Enum):
    SOFT = "soft"
    ENV = "env"
    FULL = "full"


ZSHRC_PATH = Path.home() / ".zshrc"
BREWFILE_PATH = Path.home() / "Brewfile"
BACKUP_DIR = Path.home() / ".mac-setup-backup"

# Mise 相关目录（Python 脚本使用 Mise 而非 pyenv/fnm/jenv）
MISE_DIRS = [
    Path.home() / ".local" / "share" / "mise",
    Path.home() / ".config" / "mise",
]

# 语言环境目录
ENV_DIRS = [
    Path.home() / ".oh-my-zsh",
    Path.home() / ".cargo",  # Rust
    Path.home() / "go",  # GOPATH
    *MISE_DIRS,  # Mise 数据
]


# ================= Helpers =================


def log(msg: str, level: str = "INFO") -> None:
    """带颜色的日志输出"""
    colors = {
        "INFO": "\033[94m",
        "SUCCESS": "\033[92m",
        "WARN": "\033[93m",
        "ERROR": "\033[91m",
        "RESET": "\033[0m",
    }
    icons = {"INFO": "ℹ️", "SUCCESS": "✅", "WARN": "⚠️", "ERROR": "❌"}
    print(f"{colors.get(level, '')}{icons.get(level, '')} {msg}{colors['RESET']}")


def run_cmd(cmd: str, check: bool = True) -> bool:
    """运行 shell 命令"""
    try:
        subprocess.run(cmd, shell=True, check=check, executable="/bin/zsh")
        return True
    except subprocess.CalledProcessError:
        return False


def ensure_backup_dir() -> Path:
    """确保备份目录存在"""
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    return BACKUP_DIR


def backup_file(file_path: Path, prefix: str = "") -> Optional[Path]:
    """备份文件"""
    if not file_path.exists():
        return None

    backup_dir = ensure_backup_dir()
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    backup_name = f"{prefix}{file_path.name}.{timestamp}"
    backup_path = backup_dir / backup_name

    shutil.copy2(file_path, backup_path)
    log(f"  备份创建: {backup_path}")
    return backup_path


def read_file(path: Path) -> str:
    """读取文件内容"""
    if not path.exists():
        return ""
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        return f.read()


def write_file(path: Path, content: str) -> None:
    """写入文件内容"""
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


# ================= Rollback Operations =================


def disable_auto_blocks(zshrc_path: Path) -> None:
    """禁用脚本生成的配置块"""
    if not zshrc_path.exists():
        log("  .zshrc 不存在，跳过", "WARN")
        return

    content = read_file(zshrc_path)

    # 匹配所有脚本生成的配置块标记
    # 包括: AUTO-*, HOMEBREW-PATH, MISE-ACTIVATE
    markers = ["AUTO-", "HOMEBREW-PATH", "MISE-ACTIVATE"]

    for marker in markers:
        pattern = rf"^### {marker}"
        replacement = f"### DISABLED-{marker}"
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

    write_file(zshrc_path, content)
    log("  已禁用所有脚本配置块")


def remove_auto_blocks(zshrc_path: Path) -> None:
    """移除脚本生成的配置块"""
    if not zshrc_path.exists():
        log("  .zshrc 不存在，跳过", "WARN")
        return

    content = read_file(zshrc_path)

    # 移除所有脚本生成的配置块
    # 匹配: ### xxx START ### ... ### xxx END ###
    new_content = re.sub(
        r"### [A-Z]+-?[A-Z]* START ###\n.*?### [A-Z]+-?[A-Z]* END ###\n?",
        "",
        content,
        flags=re.DOTALL,
    )
    write_file(zshrc_path, new_content)
    log("  已移除所有脚本配置块")


def restore_original_zshrc_backup(backup_dir: Path, zshrc_path: Path) -> None:
    """从备份恢复原始 .zshrc"""
    latest_backup = backup_dir / "original-.zshrc.latest"

    if latest_backup.exists() or latest_backup.is_symlink():
        # 读取符号链接指向的实际文件
        actual_backup = (
            latest_backup.resolve() if latest_backup.is_symlink() else latest_backup
        )
        if actual_backup.exists():
            log(f"  从备份恢复 .zshrc: {actual_backup}")
            shutil.copy2(actual_backup, zshrc_path)
            return

    log("  未找到 .zshrc 备份文件，跳过恢复", "WARN")


def delete_env_dirs(dirs: list) -> None:
    """删除环境目录"""
    for dir_path in dirs:
        if dir_path.exists():
            log(f"  删除: {dir_path}")
            shutil.rmtree(dir_path, ignore_errors=True)


def uninstall_brewfile_packages() -> None:
    """卸载 Brewfile 中的软件包"""
    if not BREWFILE_PATH.exists():
        log("  Brewfile 不存在，跳过卸载", "WARN")
        return

    log("▶ 卸载 Brewfile 中的软件包")
    if not run_cmd("brew bundle cleanup --force", check=False):
        log("  Brewfile cleanup 失败（可能文件为空）", "WARN")


def uninstall_homebrew() -> None:
    """卸载 Homebrew"""
    log("▶ 卸载 Homebrew")
    run_cmd(
        '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"',
        check=False,
    )


# ================= Rollback Modes =================


def rollback_soft() -> None:
    """soft 模式：仅禁用自动配置（最安全）"""
    log("▶ 执行 SOFT 回滚（禁用配置块）")

    disable_auto_blocks(ZSHRC_PATH)

    print("")
    log("soft 回滚完成（不删除任何软件）", "SUCCESS")
    print("━" * 40)
    print("后续步骤：")
    print("  1. 重新打开终端（或执行: exec zsh）")
    print("  2. 如需完全移除，请使用 --mode env 或 --mode full")


def rollback_env() -> None:
    """env 模式：恢复用户环境（推荐）"""
    log("▶ 执行 ENV 回滚（恢复用户环境）")

    # 1. 备份当前 .zshrc
    if ZSHRC_PATH.exists():
        log("▶ 备份当前 .zshrc")
        backup_file(ZSHRC_PATH, "zshrc.before-env.")

    # 2. 移除 AUTO 块
    log("▶ 移除 AUTO 配置块")
    remove_auto_blocks(ZSHRC_PATH)

    # 3. 尝试从备份恢复原始 .zshrc（如果用户选择）
    latest_backup = BACKUP_DIR / "original-.zshrc.latest"
    if latest_backup.exists() or latest_backup.is_symlink():
        try:
            choice = input("是否从备份恢复原始 .zshrc？[y/N]: ").strip().lower()
            if choice == "y":
                restore_original_zshrc_backup(BACKUP_DIR, ZSHRC_PATH)
        except EOFError:
            pass

    # 4. 删除环境目录
    log("▶ 删除语言环境目录")
    delete_env_dirs(ENV_DIRS)

    print("")
    log("env 回滚完成", "SUCCESS")
    print("━" * 40)
    print("后续步骤：")
    print("  1. 重新打开终端")
    print(f"  2. 备份文件已保存至: {BACKUP_DIR}")


def rollback_full() -> None:
    """full 模式：完全回滚（高风险）"""
    log("即将执行 FULL 回滚（危险）", "WARN")
    print("这会卸载 Brewfile 中的软件，并删除用户环境")
    print("")

    try:
        confirm = input("确认继续？[y/N]: ").strip().lower()
        if confirm != "y":
            log("用户取消操作", "WARN")
            return
    except EOFError:
        log("非交互式模式，取消操作", "WARN")
        return

    # 1. 备份当前 .zshrc
    if ZSHRC_PATH.exists():
        log("▶ 备份当前 .zshrc")
        backup_file(ZSHRC_PATH, "zshrc.before-full.")

    # 2. 移除 AUTO 块
    log("▶ 移除 AUTO 配置块")
    remove_auto_blocks(ZSHRC_PATH)

    # 3. 备份并处理 Brewfile
    if BREWFILE_PATH.exists():
        log("▶ 备份 Brewfile")
        backup_file(BREWFILE_PATH, "Brewfile.before-full.")
        uninstall_brewfile_packages()

    # 4. 删除环境目录
    log("▶ 删除用户环境目录")
    delete_env_dirs(ENV_DIRS)

    # 5. 询问是否卸载 Homebrew
    print("")
    try:
        remove_brew = input("是否卸载 Homebrew？[y/N]: ").strip().lower()
        if remove_brew == "y":
            uninstall_homebrew()
    except EOFError:
        pass

    print("")
    log("full 回滚完成！", "SUCCESS")
    print("━" * 40)
    print("后续步骤：")
    print("  1. 重新打开终端")
    print(f"  2. 备份文件已保存至: {BACKUP_DIR}")


# ================= Main =================


def main():
    parser = argparse.ArgumentParser(
        description="macOS 环境回滚脚本 (配合 mac-setup.py 使用)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
回滚模式说明:
  soft  仅禁用自动配置块（最安全，不删除任何软件）
  env   恢复用户环境（删除 Mise/Oh My Zsh 等目录，推荐）
  full  完全回滚（卸载 Brewfile 软件包，高风险）

示例:
  python3 rollback.py --mode soft
  python3 rollback.py --mode env
  python3 rollback.py --mode full
        """,
    )
    parser.add_argument(
        "--mode",
        "-m",
        type=str,
        choices=["soft", "env", "full"],
        required=True,
        help="回滚模式: soft | env | full",
    )
    args = parser.parse_args()

    print("🔄 macOS 环境回滚脚本")
    print("")

    mode = RollbackMode(args.mode)
    log(f"回滚模式: {mode.value}")
    print("")

    if mode == RollbackMode.SOFT:
        rollback_soft()
    elif mode == RollbackMode.ENV:
        rollback_env()
    elif mode == RollbackMode.FULL:
        rollback_full()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log("\n用户取消操作", "WARN")
        sys.exit(0)
    except Exception as e:
        log(f"发生未预期的错误: {e}", "ERROR")
        sys.exit(1)
