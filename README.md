# DSH MATLAB MCP Server 插件

DSH bundle 插件：将 [MATLAB MCP Server](https://github.com/matlab/matlab-mcp-server)（MathWorks 官方）接入 DeepSeek Harness，Agent 由此获得 MATLAB / Simulink 能力。

本包只有一个功能文件 `cordis.patch.yml`（bundle 层 patch），通过 `@deepseek-ai/dsh-mcp-client` 以 stdio 子进程拉起 MCP Server；无 JS 运行时代码。

## 提供的工具

基础 5 工具 + Simulink Agentic Toolkit 扩展 9 工具（共 14）：

| 工具 | 说明 |
|------|------|
| `detect_matlab_toolboxes` | 检测 MATLAB 版本与工具箱 |
| `check_matlab_code` | 静态分析 .m 代码 |
| `evaluate_matlab_code` | 执行 MATLAB 代码字符串 |
| `run_matlab_file` | 运行 .m 脚本 |
| `run_matlab_test_file` | 运行 MATLAB 单元测试 |
| `model_overview` / `model_read` / `model_edit` / `model_check` / `model_test` / `model_scan` / `model_query_params` / `model_resolve_params` / `model_read_diagnostics` | Simulink 模型查看 / 编辑 / 校验 / 测试 |

工具名统一为 `mcp__matlab__<上表名称>`。

## 前置条件

1. MATLAB R2021a+。
2. MATLAB MCP Server 二进制，二选一：
   - **MathWorks Agentic Toolkits**（推荐，自带 Simulink 扩展）：安装后位于 `~/.matlab/agentic-toolkits/bin/matlab-mcp-server`，插件默认即指向它；
   - **独立 release 二进制**：`bash setup.sh` 下载，或从 [releases](https://github.com/matlab/matlab-mcp-server/releases/latest) 手动下载，然后设置 `MATLAB_MCP_SERVER_BINARY` 指向它。

## 安装

```bash
# 试跑
dsh web --patch /path/to/dsh-matlab-mcp-plugin/cordis.patch.yml

# 长期使用（profile bundle）
cd ~/.dsh/profiles/web && dsh plugin add /path/to/dsh-matlab-mcp-plugin
```

## 配置（环境变量）

| 变量 | 说明 | 默认 |
|------|------|------|
| `MATLAB_MCP_SERVER_BINARY` | MCP Server 二进制路径 | `~/.matlab/agentic-toolkits/bin/matlab-mcp-server`，否则 PATH 查找 |
| `MATLAB_SIMULINK_TOOLS_FILE` | Simulink 扩展 tools.json | `~/.matlab/agentic-toolkits/simulink/tools/tools.json` |
| `MW_MCP_SERVER_MATLAB_ROOT` | MATLAB 安装根目录（不含 /bin） | 自动搜索 PATH |
| `MW_MCP_SERVER_INITIAL_WORKING_FOLDER` | MATLAB 初始工作目录 | 用户 Documents |

自定义覆盖（profile 的 `cordis.patch.yml` 中按 id 覆盖；注意 `args` 是**整体替换**，需带全所有 flag）：

```yaml
- id: matlab-mcp
  config:
    command: '/custom/path/matlab-mcp-server'
    args:
      - '--matlab-root=/usr/local/MATLAB/R2024b'
      - '--matlab-session-mode=new'
      - '--initialize-matlab-on-startup=false'
      - '--extension-file'
      - '/path/to/agentic-toolkits/simulink/tools/tools.json'
    toolCallTimeoutMs: 300000
```

常用 server flag：`--matlab-root`、`--initial-working-folder`、`--matlab-display-mode=desktop|nodesktop`、`--matlab-session-mode=new|auto|existing`、`--initialize-matlab-on-startup`、`--log-level`、`--disable-telemetry`。

## 故障排查

- **只有 5 个工具（无 model_\*）**：`--extension-file` 与其路径必须作为**两个独立 arg** 成对出现，裸路径会被当位置参数静默忽略（2026-09-27 实测）。
- **工具全部缺失**：`failOnStartupError: false` 会静默降级；用 `--log-level=debug` 看 server 日志，通常是二进制路径不对（检查 `MATLAB_MCP_SERVER_BINARY`）。
- **找不到 MATLAB**：设置 `MW_MCP_SERVER_MATLAB_ROOT`。
- **长仿真超时**：调大 `toolCallTimeoutMs`（默认 120000）。

## 架构

```
DSH Agent → @deepseek-ai/dsh-mcp-client → (stdio) MATLAB MCP Server → MATLAB Runtime
```

## 许可

MIT（仅覆盖本包源码；MathWorks 二进制及其依赖受各自许可约束）。
