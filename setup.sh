#!/bin/bash
# 下载并安装 MATLAB MCP Server 独立发布二进制。
# （若已安装 MathWorks Agentic Toolkits（~/.matlab/agentic-toolkits），
#   则无需本脚本——插件默认使用其自带二进制。）
# 用法: bash setup.sh [-y]

set -e

ASSUME_YES=0
[ "${1:-}" = "-y" ] && ASSUME_YES=1
[ "${ASSUME_YES_ENV:-}" = "1" ] && ASSUME_YES=1

OS="$(uname -s)"
ARCH="$(uname -m)"
[ "$ARCH" = "amd64" ] && ARCH="x86_64"
[ "$ARCH" = "aarch64" ] && ARCH="arm64"

echo "=== MATLAB MCP Server 安装脚本 ==="
echo "操作系统: $OS  架构: $ARCH"

case "$OS" in
  Linux*)
    case "$ARCH" in
      x86_64) BINARY_NAME="matlab-mcp-server-linux-amd64" ;;
      arm64)  BINARY_NAME="matlab-mcp-server-linux-arm64" ;;
      *) echo "错误: 不支持的 Linux 架构 $ARCH（支持 x86_64/arm64）" >&2; exit 1 ;;
    esac
    EXE=""
    ;;
  Darwin*)
    case "$ARCH" in
      arm64)  BINARY_NAME="matlab-mcp-server-macos-arm64" ;;
      x86_64) BINARY_NAME="matlab-mcp-server-macos-x64" ;;
      *) echo "错误: 不支持的 macOS 架构 $ARCH" >&2; exit 1 ;;
    esac
    EXE=""
    ;;
  MINGW*|CYGWIN*|MSYS*)
    BINARY_NAME="matlab-mcp-server-windows-x64.exe"
    EXE=".exe"
    ;;
  *)
    echo "错误: 不支持的操作系统 $OS" >&2; exit 1 ;;
esac

RELEASE_URL="https://github.com/matlab/matlab-mcp-server/releases/latest/download"
DOWNLOAD_URL="${RELEASE_URL}/${BINARY_NAME}"

INSTALL_DIR="${MATLAB_MCP_INSTALL_DIR:-${HOME}/.local/bin}"
LOCAL_BINARY="${INSTALL_DIR}/matlab-mcp-server${EXE}"

command -v curl >/dev/null 2>&1 || { echo "错误: 需要 curl" >&2; exit 1; }

echo "下载地址: $DOWNLOAD_URL"
echo "安装目标: $LOCAL_BINARY"

if [ "$ASSUME_YES" != "1" ]; then
  REPLY=""
  read -r -p "是否继续下载并安装？(y/N) " -n 1 || REPLY=""
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消。可手动下载: $DOWNLOAD_URL"
    exit 0
  fi
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "下载中..."
curl -fL --retry 3 --show-error -o "${WORKDIR}/${BINARY_NAME}" "$DOWNLOAD_URL"

mkdir -p "$INSTALL_DIR"
SUDO=""
[ -w "$INSTALL_DIR" ] || SUDO="sudo"
$SUDO mv "${WORKDIR}/${BINARY_NAME}" "$LOCAL_BINARY"
$SUDO chmod +x "$LOCAL_BINARY"

echo ""
echo "=== 安装完成: $LOCAL_BINARY ==="
echo "若该路径不在 PATH 中，启动前设置: export MATLAB_MCP_SERVER_BINARY=$LOCAL_BINARY"
echo "加载插件: dsh web --patch /path/to/dsh-matlab-mcp-plugin/cordis.patch.yml"
