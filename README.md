# DSH MATLAB MCP Server 插件

[English](README.md) | [中文](README.zh.md)

DeepSeek Harness 插件，用于连接 [MATLAB MCP Server](https://github.com/matlab/matlab-mcp-server)，使 DSH Agent 能够调用 MATLAB 执行代码、运行脚本、测试和分析 MATLAB 项目。

## 功能

通过此插件，DSH Agent 获得以下 MATLAB 能力：

| 工具 | 说明 |
|------|------|
| `mcp__matlab__detect_matlab_toolboxes` | 检测已安装的 MATLAB 版本和工具箱 |
| `mcp__matlab__check_matlab_code` | 静态分析 MATLAB 代码，检查代码风格和潜在错误 |
| `mcp__matlab__evaluate_matlab_code` | 执行 MATLAB 代码字符串并返回结果 |
| `mcp__matlab__run_matlab_file` | 运行 MATLAB 脚本文件（`.m`） |
| `mcp__matlab__run_matlab_test_file` | 运行 MATLAB 单元测试文件 |

## 前置条件

1. **安装 MATLAB** R2021a 或更高版本，并确保 `matlab` 命令在系统 PATH 中
2. **下载 MATLAB MCP Server 二进制文件**：
   - [访问发布页面](https://github.com/matlab/matlab-mcp-server/releases/latest)
   - 下载对应平台的二进制文件：
     - Linux: `matlab-mcp-server-linux-amd64`
     - macOS Apple Silicon: `matlab-mcp-server-macos-arm64`
     - macOS Intel: `matlab-mcp-server-macos-x64`
     - Windows: `matlab-mcp-server-windows-x64.exe`

## 安装

### 方式一：通过 `--patch` 参数（推荐用于测试）

```bash
# 将 MATLAB MCP Server 二进制文件放入 PATH 中
sudo cp matlab-mcp-server-linux-amd64 /usr/local/bin/matlab-mcp-server
sudo chmod +x /usr/local/bin/matlab-mcp-server

# 启动 DSH 并加载此插件
dsh web --patch /path/to/dsh-matlab-mcp-plugin/cordis.patch.yml
```

### 方式二：安装为 Profile 插件（推荐用于长期使用）

```bash
# 进入 DSH Profile 目录并安装此插件
cd ~/.dsh/profiles/web
dsh plugin add /path/to/dsh-matlab-mcp-plugin

# 或者直接添加为依赖
pnpm add --no-save file:/path/to/dsh-matlab-mcp-plugin
```

### 方式三：手动合并到 cordis.patch.yml

将以下内容合并到你的 Profile `cordis.patch.yml` 中：

```yaml
# 你的 cordis.patch.yml 中的其他 patch ...

- insert:
    - id: matlab-mcp
      name: '@deepseek-ai/dsh-mcp-client'
      config:
        serverName: matlab
        transport: stdio
        command: matlab-mcp-server
        args:
          - '--matlab-display-mode=nodesktop'
          - '--matlab-session-mode=auto'
          - '--disable-telemetry=true'
        cwd: !!js process.cwd()
        toolCallTimeoutMs: 120000
        failOnStartupError: false
```

## 配置

### 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `MATLAB_MCP_SERVER_BINARY` | MATLAB MCP Server 二进制文件路径 | `matlab-mcp-server`（从 PATH 查找） |
| `MW_MCP_SERVER_MATLAB_ROOT` | MATLAB 安装根目录（不含 /bin） | 自动搜索 PATH |
| `MW_MCP_SERVER_INITIAL_WORKING_FOLDER` | MATLAB 初始工作目录 | 用户 Documents 目录 |

### 自定义配置

通过 patch 覆盖默认配置：

```yaml
- id: matlab-mcp
  config:
    command: '/custom/path/to/matlab-mcp-server'
    args:
      - '--matlab-root=/usr/local/MATLAB/R2024b'
      - '--initial-working-folder=/home/user/projects'
      - '--matlab-display-mode=desktop'
      - '--matlab-session-mode=new'
      - '--log-level=debug'
    toolCallTimeoutMs: 300000  # 5分钟超时，适用于长时间模拟
```

### MATLAB MCP Server 参数

| 参数 | 说明 |
|------|------|
| `--matlab-root=<path>` | 指定 MATLAB 安装路径 |
| `--initial-working-folder=<path>` | 设置 MATLAB 初始工作目录 |
| `--matlab-display-mode=desktop\|nodesktop` | 是否显示 MATLAB 桌面 |
| `--matlab-session-mode=new\|auto\|existing` | MATLAB 会话模式 |
| `--initialize-matlab-on-startup=true\|false` | 启动时是否初始化 MATLAB |
| `--log-level=debug\|info\|warn\|error` | 日志级别 |
| `--disable-telemetry=true\|false` | 禁用匿名数据收集 |

## 使用示例

### 执行 MATLAB 代码

```
Evaluate the following MATLAB code: x = 1:10; y = sin(x); plot(x, y);
```

Agent 会自动调用 `mcp__matlab__evaluate_matlab_code` 工具来执行代码。

### 运行 MATLAB 脚本

```
Run the MATLAB script at /home/user/projects/analysis.m
```

### 检查代码质量

```
Check the MATLAB code quality of /home/user/projects/myFunction.m
```

### 运行测试

```
Run the MATLAB test file at /home/user/projects/tests/testMyFunction.m
```

## 工具命名约定

所有通过此插件暴露的工具都遵循 `mcp__<serverName>__<rawToolName>` 命名约定：

- `mcp__matlab__detect_matlab_toolboxes`
- `mcp__matlab__check_matlab_code`
- `mcp__matlab__evaluate_matlab_code`
- `mcp__matlab__run_matlab_file`
- `mcp__matlab__run_matlab_test_file`

## 故障排查

### MATLAB 找不到

如果 MATLAB MCP Server 无法找到 MATLAB，请设置 `MW_MCP_SERVER_MATLAB_ROOT` 环境变量或添加 `--matlab-root` 参数：

```yaml
args:
  - '--matlab-root=/usr/local/MATLAB/R2024b'
```

### 工具超时

MATLAB 长时间运行的操作可能导致超时。增加 `toolCallTimeoutMs`：

```yaml
toolCallTimeoutMs: 300000  # 5分钟
```

### MCP Server 二进制文件找不到

确保二进制文件在 PATH 中，或设置 `MATLAB_MCP_SERVER_BINARY` 环境变量指向其完整路径。

### 连接失败

检查 MATLAB MCP Server 日志（通过 `--log-level=debug` 启用详细日志），确认：
1. MATLAB 已正确安装并可从命令行启动
2. 网络连接正常（如果使用的是远程 MATLAB）
3. 许可证有效

## 架构

此插件通过 DSH 的 `@deepseek-ai/dsh-mcp-client` 桥接器连接到 MATLAB MCP Server：

```
DSH Agent
    │
    ▼
DSH MCP Client Plugin (@deepseek-ai/dsh-mcp-client)
    │  stdio
    ▼
MATLAB MCP Server (Go binary)
    │  MATLAB API
    ▼
MATLAB Runtime
```

## 许可

MIT

## 参考

- [DeepSeek Harness 文档](https://deepseek-harness.github.io/deepseek-harness/)
- [MATLAB MCP Server](https://github.com/matlab/matlab-mcp-server)
- [DSH MCP 客户端插件](https://github.com/deepseek-ai/deepseek-harness/tree/master/packages/mcp/mcp-client)
