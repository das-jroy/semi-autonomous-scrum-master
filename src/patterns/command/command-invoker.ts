import { GitHubCommand } from './github-command.interface';
import { CommandResult } from './command-result.interface';

/* eslint-disable no-console */

/**
 * Command Invoker - Command Pattern Implementation
 * 
 * Orchestrates the execution of GitHub API commands with support for:
 * - Command history and rollback
 * - Batch operations
 * - Error handling and retry logic
 * - Progress monitoring
 * 
 * Replaces functionality from multiple shell scripts:
 * - command-invoker.sh
 * - batch-operations.sh
 * - error-handling.sh
 * - rollback-operations.sh
 */
export class CommandInvoker {
  private commandHistory: GitHubCommand[] = [];
  private executionResults: CommandResult[] = [];
  private isExecuting = false;
  private progressListeners: ((progress: ExecutionProgress) => void)[] = [];

  /**
   * Execute a single command
   * @param command - The command to execute
   * @returns Promise<CommandResult>
   */
  async executeCommand(command: GitHubCommand): Promise<CommandResult> {
    console.log(`🔄 Executing: ${command.getDescription()}`);
    
    try {
      const result = await command.execute();
      
      if (result.success) {
        this.commandHistory.push(command);
        this.executionResults.push(result);
        console.log(`✅ Completed: ${command.getDescription()}`);
      } else {
        console.error(`❌ Failed: ${command.getDescription()} - ${result.error}`);
      }
      
      return result;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      const errorResult: CommandResult = {
        success: false,
        error: errorMessage,
        executedAt: new Date()
      };
      
      console.error(`💥 Error: ${command.getDescription()} - ${errorMessage}`);
      return errorResult;
    }
  }

  /**
   * Execute multiple commands in sequence
   * Replaces: batch-operations.sh
   */
  async executeBatch(commands: GitHubCommand[]): Promise<BatchResult> {
    this.isExecuting = true;
    const results: CommandResult[] = [];
    const failed: GitHubCommand[] = [];
    
    console.log(`🚀 Starting batch execution of ${commands.length} commands`);
    
    for (let i = 0; i < commands.length; i++) {
      const command = commands[i];
      
      // Notify progress listeners
      this.notifyProgress({
        currentStep: i + 1,
        totalSteps: commands.length,
        currentCommand: command.getDescription(),
        completedCommands: i,
        failedCommands: failed.length
      });
      
      const result = await this.executeCommand(command);
      results.push(result);
      
      if (!result.success) {
        failed.push(command);
        
        // Decide whether to continue or stop based on error severity
        if (this.shouldStopOnError(result)) {
          console.error(`🛑 Stopping batch execution due to critical error`);
          break;
        }
      }
      
      // Add delay between commands to respect rate limits
      await this.delay(500);
    }
    
    this.isExecuting = false;
    
    const batchResult: BatchResult = {
      totalCommands: commands.length,
      successfulCommands: results.filter(r => r.success).length,
      failedCommands: failed.length,
      results,
      failed,
      startTime: results[0]?.executedAt || new Date(),
      endTime: new Date()
    };
    
    console.log(`📊 Batch execution completed: ${batchResult.successfulCommands}/${batchResult.totalCommands} successful`);
    
    return batchResult;
  }

  /**
   * Execute commands with retry logic
   * Replaces: retry-operations.sh
   */
  async executeWithRetry(
    command: GitHubCommand,
    maxRetries: number = 3,
    retryDelay: number = 1000
  ): Promise<CommandResult> {
    let lastResult: CommandResult = {
      success: false,
      error: 'No attempt made',
      executedAt: new Date()
    };
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      console.log(`🔄 Attempt ${attempt}/${maxRetries}: ${command.getDescription()}`);
      
      lastResult = await this.executeCommand(command);
      
      if (lastResult.success) {
        return lastResult;
      }
      
      if (attempt < maxRetries) {
        console.log(`⏳ Waiting ${retryDelay}ms before retry...`);
        await this.delay(retryDelay);
        retryDelay *= 2; // Exponential backoff
      }
    }
    
    console.error(`❌ All retry attempts failed for: ${command.getDescription()}`);
    return lastResult;
  }

  /**
   * Rollback the last executed command
   * Replaces: rollback-operations.sh
   */
  async undoLastCommand(): Promise<boolean> {
    if (this.commandHistory.length === 0) {
      console.warn('⚠️ No commands to undo');
      return false;
    }
    
    const lastCommand = this.commandHistory[this.commandHistory.length - 1];
    
    if (!lastCommand.canUndo()) {
      console.warn(`⚠️ Cannot undo: ${lastCommand.getDescription()}`);
      return false;
    }
    
    try {
      console.log(`🔙 Undoing: ${lastCommand.getDescription()}`);
      await lastCommand.undo();
      
      this.commandHistory.pop();
      this.executionResults.pop();
      
      console.log(`✅ Successfully undone: ${lastCommand.getDescription()}`);
      return true;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error(`❌ Failed to undo: ${lastCommand.getDescription()} - ${errorMessage}`);
      return false;
    }
  }

  /**
   * Rollback multiple commands
   * Replaces: batch-rollback.sh
   */
  async undoLastCommands(count: number): Promise<number> {
    let undoneCount = 0;
    
    for (let i = 0; i < count; i++) {
      const success = await this.undoLastCommand();
      if (success) {
        undoneCount++;
      } else {
        break;
      }
    }
    
    console.log(`🔙 Rolled back ${undoneCount}/${count} commands`);
    return undoneCount;
  }

  /**
   * Get command execution history
   * Replaces: command-history.sh
   */
  getCommandHistory(): CommandHistory {
    return {
      commands: this.commandHistory.map((cmd, index) => ({
        description: cmd.getDescription(),
        result: this.executionResults[index],
        canUndo: cmd.canUndo()
      })),
      totalCommands: this.commandHistory.length,
      successfulCommands: this.executionResults.filter(r => r.success).length,
      failedCommands: this.executionResults.filter(r => !r.success).length
    };
  }

  /**
   * Health check for command execution system
   * Replaces: command-health-check.sh
   */
  async healthCheck(): Promise<HealthCheckResult> {
    const recentResults = this.executionResults.slice(-10);
    const successRate = recentResults.length > 0 
      ? (recentResults.filter(r => r.success).length / recentResults.length) * 100
      : 100;
    
    return {
      isHealthy: successRate >= 80,
      successRate,
      recentFailures: recentResults.filter(r => !r.success).length,
      totalCommands: this.commandHistory.length,
      isCurrentlyExecuting: this.isExecuting,
      lastExecutionTime: this.executionResults[this.executionResults.length - 1]?.executedAt
    };
  }

  /**
   * Add progress listener
   */
  addProgressListener(listener: (progress: ExecutionProgress) => void): void {
    this.progressListeners.push(listener);
  }

  /**
   * Remove progress listener
   */
  removeProgressListener(listener: (progress: ExecutionProgress) => void): void {
    const index = this.progressListeners.indexOf(listener);
    if (index > -1) {
      this.progressListeners.splice(index, 1);
    }
  }

  /**
   * Clear command history
   */
  clearHistory(): void {
    this.commandHistory = [];
    this.executionResults = [];
    console.log('🧹 Command history cleared');
  }

  // Private helper methods

  private shouldStopOnError(result: CommandResult): boolean {
    // Define critical errors that should stop batch execution
    const criticalErrors = [
      'rate limit exceeded',
      'authentication failed',
      'insufficient permissions',
      'project not found'
    ];
    
    return criticalErrors.some(error => 
      result.error?.toLowerCase().includes(error.toLowerCase())
    );
  }

  private async delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private notifyProgress(progress: ExecutionProgress): void {
    for (const listener of this.progressListeners) {
      try {
        listener(progress);
      } catch (error) {
        console.error('Error in progress listener:', error);
      }
    }
  }
}

/**
 * Specialized Command Invoker for GitHub Projects
 * Integrates with Observer Pattern for progress notifications
 */
export class GitHubProjectCommandInvoker extends CommandInvoker {
  private observers: ProjectProgressObserver[] = [];

  /**
   * Add observer for project progress
   */
  addObserver(observer: ProjectProgressObserver): void {
    this.observers.push(observer);
    
    // Add as progress listener
    this.addProgressListener((progress) => {
      observer.onProgress({
        phase: this.getCurrentPhase(progress),
        progress: (progress.currentStep / progress.totalSteps) * 100,
        currentTask: progress.currentCommand,
        completedTasks: progress.completedCommands,
        failedTasks: progress.failedCommands,
        timestamp: new Date()
      });
    });
  }

  /**
   * Remove observer
   */
  removeObserver(observer: ProjectProgressObserver): void {
    const index = this.observers.indexOf(observer);
    if (index > -1) {
      this.observers.splice(index, 1);
    }
  }

  /**
   * Execute project setup workflow
   * Replaces: complete-project-setup.sh
   */
  async executeProjectSetup(setupCommands: ProjectSetupCommands): Promise<ProjectSetupResult> {
    const allCommands = [
      setupCommands.createProject,
      ...setupCommands.createIssues,
      setupCommands.setupSprint,
      setupCommands.updateBoard
    ].filter((cmd): cmd is GitHubCommand => cmd !== undefined);

    const batchResult = await this.executeBatch(allCommands);
    
    return {
      success: batchResult.failedCommands === 0,
      projectCreated: batchResult.results[0]?.success || false,
      issuesCreated: setupCommands.createIssues.length,
      sprintConfigured: setupCommands.setupSprint ? true : false,
      boardConfigured: setupCommands.updateBoard ? true : false,
      totalExecutionTime: batchResult.endTime.getTime() - batchResult.startTime.getTime(),
      errors: batchResult.failed.map(cmd => cmd.getDescription())
    };
  }

  private getCurrentPhase(progress: ExecutionProgress): string {
    if (progress.currentStep <= 1) return 'Project Creation';
    if (progress.currentStep <= progress.totalSteps * 0.7) return 'Issue Creation';
    if (progress.currentStep <= progress.totalSteps * 0.9) return 'Sprint Setup';
    return 'Board Configuration';
  }
}

// Supporting interfaces

export interface BatchResult {
  totalCommands: number;
  successfulCommands: number;
  failedCommands: number;
  results: CommandResult[];
  failed: GitHubCommand[];
  startTime: Date;
  endTime: Date;
}

export interface ExecutionProgress {
  currentStep: number;
  totalSteps: number;
  currentCommand: string;
  completedCommands: number;
  failedCommands: number;
}

export interface CommandHistory {
  commands: {
    description: string;
    result: CommandResult;
    canUndo: boolean;
  }[];
  totalCommands: number;
  successfulCommands: number;
  failedCommands: number;
}

export interface HealthCheckResult {
  isHealthy: boolean;
  successRate: number;
  recentFailures: number;
  totalCommands: number;
  isCurrentlyExecuting: boolean;
  lastExecutionTime?: Date;
}

export interface ProjectProgressObserver {
  onProgress(progress: ProjectProgress): void;
}

export interface ProjectProgress {
  phase: string;
  progress: number; // 0-100
  currentTask: string;
  completedTasks: number;
  failedTasks: number;
  timestamp: Date;
}

export interface ProjectSetupCommands {
  createProject: GitHubCommand;
  createIssues: GitHubCommand[];
  setupSprint?: GitHubCommand;
  updateBoard?: GitHubCommand;
}

export interface ProjectSetupResult {
  success: boolean;
  projectCreated: boolean;
  issuesCreated: number;
  sprintConfigured: boolean;
  boardConfigured: boolean;
  totalExecutionTime: number;
  errors: string[];
}
