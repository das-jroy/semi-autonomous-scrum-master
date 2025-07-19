/**
 * GitHub Commands Module
 * Exports all GitHub command implementations
 */

import type { GitHubCommand } from './github-command.interface';
import type { CommandResult } from './command-result.interface';
import { Octokit } from '@octokit/rest';

export type { GitHubCommand } from './github-command.interface';
export type { CommandResult } from './command-result.interface';
export { CommandInvoker, GitHubProjectCommandInvoker } from './command-invoker';

// Re-export common types for convenience
export type { HealthCheckResult, CommandHistory } from './command-invoker';

// Data types
export interface ProjectData {
  name: string;
  description: string;
  ownerId?: string;
  title?: string;
}

export interface IssueData {
  title: string;
  body: string;
  owner?: string;
  repo?: string;
  assignees?: string[];
  labels?: string[];
  issueType?: string;
}

export interface SprintData {
  name: string;
  startDate: Date | string;
  endDate?: Date | string;
  number?: number;
  owner?: string;
  repo?: string;
  duration?: number;
}

export interface BoardData {
  name?: string;
  columns?: string[];
  items?: Record<string, unknown>[];
}

// Command implementations
export class CreateProjectCommand implements GitHubCommand {
  constructor(private octokit: Octokit, private data: ProjectData) {}
  
  async execute(): Promise<CommandResult<{ projectId: string }>> { 
    return { success: true, data: { projectId: 'mock-project' }, timestamp: new Date() }; 
  }
  canUndo(): boolean { return false; }
  async undo(): Promise<CommandResult<unknown>> { 
    return { success: false, error: 'Project creation cannot be undone', timestamp: new Date() }; 
  }
  getDescription(): string { return `Create Project: ${this.data.name}`; }
  getType(): string { return 'create_project'; }
  getMetadata(): Record<string, unknown> { return { ...this.data }; }
}

export class CreateIssuesCommand implements GitHubCommand {
  constructor(private octokit: Octokit, private data: IssueData[]) {}
  
  async execute(): Promise<CommandResult<{ issueCount: number }>> { 
    return { success: true, data: { issueCount: this.data.length }, timestamp: new Date() }; 
  }
  canUndo(): boolean { return false; }
  async undo(): Promise<CommandResult<unknown>> { 
    return { success: false, error: 'Issue creation cannot be undone', timestamp: new Date() }; 
  }
  getDescription(): string { return `Create ${this.data.length} Issues`; }
  getType(): string { return 'create_issues'; }
  getMetadata(): Record<string, unknown> { return { count: this.data.length }; }
}

export class SetupSprintCommand implements GitHubCommand {
  constructor(private octokit: Octokit, private data: SprintData, private projectId: string) {}
  
  async execute(): Promise<CommandResult<{ sprintId: string }>> { 
    return { success: true, data: { sprintId: 'mock-sprint' }, timestamp: new Date() }; 
  }
  canUndo(): boolean { return false; }
  async undo(): Promise<CommandResult<unknown>> { 
    return { success: false, error: 'Sprint setup cannot be undone', timestamp: new Date() }; 
  }
  getDescription(): string { return `Setup Sprint: ${this.data.name}`; }
  getType(): string { return 'setup_sprint'; }
  getMetadata(): Record<string, unknown> { return { ...this.data, projectId: this.projectId }; }
}

export class UpdateBoardCommand implements GitHubCommand {
  constructor(private octokit: Octokit, private data: BoardData, private projectId: string) {}
  
  async execute(): Promise<CommandResult<{ boardId: string }>> { 
    return { success: true, data: { boardId: 'mock-board' }, timestamp: new Date() }; 
  }
  canUndo(): boolean { return false; }
  async undo(): Promise<CommandResult<unknown>> { 
    return { success: false, error: 'Board update cannot be undone', timestamp: new Date() }; 
  }
  getDescription(): string { return `Update Board: ${this.data.name}`; }
  getType(): string { return 'update_board'; }
  getMetadata(): Record<string, unknown> { return { ...this.data, projectId: this.projectId }; }
}