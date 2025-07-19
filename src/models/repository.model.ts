/**
 * Repository Model
 * 
 * Represents a GitHub repository with metadata and analysis capabilities
 */
export interface Repository {
  owner: string;
  name: string;
  fullName: string;
  url: string;
  defaultBranch: string;
  language: string;
  languages?: Record<string, number>;
  size: number;
  stargazers: number;
  forks: number;
  isPrivate: boolean;
  hasIssues: boolean;
  hasProjects: boolean;
  hasWiki: boolean;
  createdAt: Date;
  updatedAt: Date;
  pushedAt: Date;
  description?: string;
  topics?: string[];
  license?: string;
  readme?: string;
  packageJson?: Record<string, unknown>;
  requirements?: string[];
  dockerfile?: boolean;
  ciConfig?: CIConfiguration;
  fileStructure?: FileStructure;
}

/**
 * CI Configuration detected in repository
 */
export interface CIConfiguration {
  hasGitHubActions: boolean;
  hasJenkins: boolean;
  hasTravis: boolean;
  hasCircleCI: boolean;
  workflows?: string[];
}

/**
 * File structure analysis
 */
export interface FileStructure {
  hasSourceDirectory: boolean;
  sourceDirectoryName?: string; // 'src', 'lib', 'app', etc.
  hasTests: boolean;
  testDirectoryName?: string;
  hasDocumentation: boolean;
  documentationFiles: string[];
  configFiles: string[];
  buildFiles: string[];
}

/**
 * Repository creation parameters
 */
export interface CreateRepositoryParams {
  owner: string;
  name: string;
  description?: string;
  isPrivate?: boolean;
  hasIssues?: boolean;
  hasProjects?: boolean;
  hasWiki?: boolean;
  defaultBranch?: string;
  gitignoreTemplate?: string;
  licenseTemplate?: string;
  allowSquashMerge?: boolean;
  allowMergeCommit?: boolean;
  allowRebaseMerge?: boolean;
}
