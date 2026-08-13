#!/bin/bash
# MATLAB MCP Server 安装脚本
# 
# 此脚本帮助下载和安装 MATLAB MCP Server 二进制文件。
# 用法: bash setup.sh

set -e

# 检测操作系统和架构
OS="$(uname -s)"
ARCH="$(uname -m)"

echo "=== MATLAB MCP Server 安装脚本 ==="
echo "操作系统: $OS"
echo "架构: $ARCH"

# 确定下载 URL 和文件名
case "$OS" in
  Linux*)
    if [ "$ARCH" = "x86_64" ]; then
      BINARY_NAME="matlab-mcp-server-linux-amd64"
    else
      echo "错误: 不支持的架构 $ARCH"
      exit 1
    fi
    ;;
  Darwin*)
    if [ "$ARCH" = "arm64" ]; then
      BINARY_NAME="matlab-mcp-server-macos-arm64"
    elif [ "$ARCH" = "x86_64" ]; then
      BINARY_NAME="matlab-mcp-server-macos-x64"
    else
      echo "错误: 不支持的架构 $ARCH"
      exit 1
    fi
    ;;
  MINGW*|CYGWIN*|MSYS*)
    BINARY_NAME="matlab-mcp-server-windows-x64.exe"
    ;;
  *)
    echo "错误: 不支持的操作系统 $OS"
    exit 1
    ;;
esac

RELEASE_URL="https://github.com/matlab/matlab-mcp-server/releases/latest/download"
DOWNLOAD_URL="${RELEASE_URL}/${BINARY_NAME}"

# 安装目标目录
INSTALL_DIR="${MATLAB_MCP_INSTALL_DIR:-/usr/local/bin}"
LOCAL_BINARY="${INSTALL_DIR}/matlab-mcp-server"

echo ""
echo "检测到的二进制文件: $BINARY_NAME"
echo "下载地址: $DOWNLOAD_URL"
echo "安装目标: $LOCAL_BINARY"
echo ""

# 确认安装
read -p "是否继续下载并安装？(y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "安装已取消。"
  echo "你可以手动下载: $DOWNLOAD_URL"
  exit 0
fi

# 创建临时目录
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "下载中..."
curl -L -o "${TMPDIR}/${BINARY_NAME}" "$DOWNLOAD_URL"

# 移动到安装目录并设置权限
if [ "$OS" = "Linux" ] || [ "$OS" = "Darwin" ]; then
  sudo mv "${TMPDIR}/${BINARY_NAME}" "$LOCAL_BINARY"
  sudo chmod +x "$LOCAL_BINARY"
else
  # Windows
  mkdir -p "$INSTALL_DIR"
  cp "${TMPDIR}/${BINARY_NAME}" "${LOCAL_BINARY}.exe"
fi

echo ""
echo "=== 安装完成 ==="
echo "MATLAB MCP Server 已安装到: $LOCAL_BINARY"
echo ""
echo "下一步:"
echo "1. 启动 DSH: dsh web --patch /path/to/dsh-matlab-mcp-plugin/cordis.patch.yml"
echo "2. 或在 ~/.dsh/profiles/web/cordis.patch.yml 中添加 MATLAB MCP 配置"
