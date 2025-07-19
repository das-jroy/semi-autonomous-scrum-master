import { CommandResult } from './command-result.interface';

/**
 * Base GitHub Command Interface
 * All GitHub operations must implement this interface
 */
export interface GitHubCommand {
  /**
   * Execute the command
   */
  execute(): Promise<CommandResult>;

  /**
   * Undo the command if possible
   */
  undo(): Promise<CommandResult>;

  /**
   * Get command description for logging
   */
  getDescription(): string;

  /**
   * Get command type for categorization
   */
  getType(): string;

  /**
   * Check if the command can be undone
   */
  canUndo(): boolean;

  /**
   * Get command metadata
   */
  getMetadata(): Record<string, unknown>;
}

/**
 * Command with retry capability
 */
export interface RetryableCommand extends GitHubCommand {
  /**
   * Maximum number of retry attempts
   */
  getMaxRetries(): number;

  /**
   * Retry delay in milliseconds
   */
  getRetryDelay(): number;

  /**
   * Check if the command should be retried based on error
   */
  shouldRetry(error: Error): boolean;
}

/**
 * Batch command interface
 */
export interface BatchCommand extends GitHubCommand {
  /**
   * Get sub-commands in the batch
   */
  getCommands(): GitHubCommand[];

  /**
   * Execute commands in parallel or sequence
   */
  executeInParallel(): boolean;
}
