/**
 * MATLAB MCP Server plugin for DeepSeek Harness
 *
 * This plugin connects the DSH agent to the official MATLAB MCP Server
 * from MathWorks, enabling the agent to:
 * - Start and quit MATLAB sessions
 * - Write and run MATLAB code
 * - Assess MATLAB code for style and correctness
 * - Run MATLAB test files
 * - Detect installed MATLAB toolboxes
 *
 * @module dsh-matlab-mcp-plugin
 */
import type { Context } from '@deepseek-ai/cordis'
import Schema from '@deepseek-ai/schemastery'

export const name = 'matlab-mcp-server'
export const inject = ['subprocess']

/** Configuration for connecting to the MATLAB MCP Server. */
export interface Config {
  /**
   * Path to the MATLAB MCP Server binary.
   * Download from https://github.com/matlab/matlab-mcp-server/releases/latest
   */
  serverBinary: string

  /**
   * Full path to MATLAB installation root (do not include /bin).
   * If omitted, the server searches the system PATH.
   */
  matlabRoot?: string

  /**
   * Initial working folder for MATLAB sessions.
   * If omitted, MATLAB starts at the agent's first Root or default Documents folder.
   */
  initialWorkingFolder?: string

  /**
   * MATLAB display mode: 'desktop' shows the MATLAB desktop,
   * 'nodesktop' runs MATLAB headlessly.
   * @default 'nodesktop'
   */
  matlabDisplayMode?: 'desktop' | 'nodesktop'

  /**
   * MATLAB session mode:
   * - 'new': always start a new MATLAB session
   * - 'auto' (default): try connecting to existing, fall back to new
   * - 'existing': connect to an existing MATLAB session only
   */
  matlabSessionMode?: 'new' | 'auto' | 'existing'

  /**
   * Whether to initialize MATLAB on server startup.
   * @default false
   */
  initializeMatlabOnStartup?: boolean

  /**
   * Log level for the MCP server.
   * @default 'info'
   */
  logLevel?: 'debug' | 'info' | 'warn' | 'error'

  /**
   * Disable anonymized telemetry data collection.
   * @default false
   */
  disableTelemetry?: boolean

  /**
   * Per-tool-call timeout in milliseconds.
   * MATLAB operations can be slow, so the default is generous.
   * @default 120000
   */
  toolCallTimeoutMs?: number

  /**
   * Fail plugin activation on initial connection or tool sync error.
   * @default false
   */
  failOnStartupError?: boolean
}

export const Config: Schema<Config> = Schema.object({
  serverBinary: Schema.string().required(),
  matlabRoot: Schema.string(),
  initialWorkingFolder: Schema.string(),
  matlabDisplayMode: Schema.union([
    Schema.const('desktop'),
    Schema.const('nodesktop'),
  ]),
  matlabSessionMode: Schema.union([
    Schema.const('new'),
    Schema.const('auto'),
    Schema.const('existing'),
  ]).default('auto'),
  initializeMatlabOnStartup: Schema.boolean().default(false),
  logLevel: Schema.union([
    Schema.const('debug'),
    Schema.const('info'),
    Schema.const('warn'),
    Schema.const('error'),
  ]).default('info'),
  disableTelemetry: Schema.boolean().default(false),
  toolCallTimeoutMs: Schema.natural().default(120_000),
  failOnStartupError: Schema.boolean().default(false),
})

/**
 * Build the command-line arguments for the MATLAB MCP Server binary
 * from the resolved plugin config.
 */
function buildArgs(config: Config): string[] {
  const args: string[] = []

  if (config.matlabRoot) {
    args.push('--matlab-root', config.matlabRoot)
  }
  if (config.initialWorkingFolder) {
    args.push('--initial-working-folder', config.initialWorkingFolder)
  }
  if (config.matlabDisplayMode) {
    args.push('--matlab-display-mode', config.matlabDisplayMode)
  }
  if (config.matlabSessionMode) {
    args.push('--matlab-session-mode', config.matlabSessionMode)
  }
  if (config.initializeMatlabOnStartup) {
    args.push('--initialize-matlab-on-startup=true')
  }
  if (config.logLevel && config.logLevel !== 'info') {
    args.push('--log-level', config.logLevel)
  }
  if (config.disableTelemetry) {
    args.push('--disable-telemetry=true')
  }

  return args
}

/**
 * Apply the MATLAB MCP Server plugin.
 *
 * This plugin registers itself as a configuration provider that other
 * parts of the harness can use. The actual MCP connection is managed
 * by the cordis.patch.yml composition layer using @deepseek-ai/dsh-mcp-client.
 *
 * @param ctx - Cordis plugin context
 * @param config - Resolved plugin configuration
 */
export async function apply(ctx: Context, config: Config): Promise<void> {
  const args = buildArgs(config)

  // Log configuration for diagnostics
  console.log(`[matlab-mcp] MATLAB MCP Server plugin configured:`)
  console.log(`[matlab-mcp]   Binary: ${config.serverBinary}`)
  console.log(`[matlab-mcp]   Args: ${args.length > 0 ? args.join(' ') : '(none)'}`)
  console.log(`[matlab-mcp]   Timeout: ${config.toolCallTimeoutMs}ms`)

  if (config.matlabRoot) {
    console.log(`[matlab-mcp]   MATLAB root: ${config.matlabRoot}`)
  }
  if (config.initialWorkingFolder) {
    console.log(`[matlab-mcp]   Working folder: ${config.initialWorkingFolder}`)
  }

  // Store the resolved config on context for other plugins to access
  ctx.effect(() => {
    // Register a simple service that exposes the resolved MATLAB MCP config
    ;(ctx as any).matlabMcpConfig = {
      serverBinary: config.serverBinary,
      args,
      toolCallTimeoutMs: config.toolCallTimeoutMs,
      failOnStartupError: config.failOnStartupError,
    }

    return () => {
      // Cleanup on dispose
      delete (ctx as any).matlabMcpConfig
    }
  })
}
