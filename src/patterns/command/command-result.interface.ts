/**
 * Command Result Interface
 * Standardizes the result structure for all command operations
 */
export interface CommandResult<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  timestamp?: Date;
  executedAt?: Date;
  executionTime?: number;
  metadata?: Record<string, unknown>;
}

/**
 * Command execution context
 */
export interface CommandContext {
  retryCount?: number;
  maxRetries?: number;
  timeout?: number;
  rollbackOnError?: boolean;
  metadata?: Record<string, unknown>;
}
