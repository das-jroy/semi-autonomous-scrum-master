import { Octokit } from '@octokit/rest';
import { Repository } from '../models/repository.model';
import { ProjectModel, ProjectType, Epic, UserStory, Task } from '../models/project.model';
import { ConcreteAnalyzerFactory } from '../patterns/factory/analyzer.factory';
import { GitHubProjectCommandInvoker, ExecutionProgress, HealthCheckResult as CommandHealthCheckResult } from '../patterns/command/command-invoker';
import { AbstractProgressSubject, ProgressEvent } from '../patterns/observer/progress-observers';
import { 
  CreateProjectCommand, 
  CreateIssuesCommand, 
  SetupSprintCommand, 
  UpdateBoardCommand,
  ProjectData,
  IssueData,
  SprintData,
  BoardData
} from '../patterns/command/github-commands';

/**
 * Scrum Master Engine - Main Orchestrator
 * 
 * Integrates all design patterns and replaces functionality from multiple shell scripts:
 * - setup-project.sh
 * - working-project-setup.sh
 * - complete-project-setup.sh
 * - sprint-planning.sh
 * - health-check.sh
 * - progress-monitoring.sh
 * - roadmap-setup-complete.sh
 * - project-automation-summary.sh
 */
/* eslint-disable max-lines */
export class ScrumMasterEngine extends AbstractProgressSubject {
  private octokit: Octokit;
  private analyzerFactory: ConcreteAnalyzerFactory;
  private commandInvoker: GitHubProjectCommandInvoker;
  private isProcessing: boolean = false;
  private currentRepository?: Repository;
  private currentProject?: ProjectModel;

  constructor(githubToken: string) {
    super();
    
    this.octokit = new Octokit({
      auth: githubToken
    });
    
    this.analyzerFactory = new ConcreteAnalyzerFactory();
    this.commandInvoker = new GitHubProjectCommandInvoker();
    
    // Setup command invoker progress notifications
    this.commandInvoker.addProgressListener((progress: ExecutionProgress) => {
      this.notifyObservers({
        type: 'progress',
        data: progress,
        timestamp: new Date(),
        phase: 'Command Execution',
        progress: (progress.currentStep / progress.totalSteps) * 100,
        message: `Executing: ${progress.currentCommand}`
      });
    });
  }

  /**
   * Full project setup workflow
   * Replaces: complete-project-setup.sh
   */
  async setupProject(
    repositoryUrl: string,
    projectTitle: string,
    projectDescription: string,
    organizationId: string
  ): Promise<ProjectSetupResult> {
    this.isProcessing = true;
    
    try {
      await this.notifyObservers({
        type: 'project_setup_started',
        data: { repositoryUrl, projectTitle },
        timestamp: new Date(),
        phase: 'Initialization',
        progress: 0,
        message: `Starting project setup for ${projectTitle}`
      });

      // Step 1: Analyze repository
      const repository = await this.analyzeRepository(repositoryUrl);
      
      // Step 2: Create GitHub project
      const project = await this.createGitHubProject(organizationId, projectTitle, projectDescription);
      
      // Step 3: Generate and create issues
      const issues = await this.generateAndCreateIssues(repository, project);
      
      // Step 4: Setup sprint
      const sprint = await this.setupSprint(repository, project, issues);
      
      // Step 5: Configure board
      await this.configureBoard(project, issues);
      
      // Step 6: Final setup completion
      await this.completeProjectSetup(project, issues, sprint);

      await this.notifyObservers({
        type: 'completion',
        data: { project, issues, sprint },
        timestamp: new Date(),
        phase: 'Completion',
        progress: 100,
        message: `Project setup completed successfully for ${projectTitle}`
      });

      return {
        success: true,
        project,
        repository,
        issuesCreated: issues.length,
        sprintConfigured: !!sprint,
        projectUrl: project.url,
        message: 'Project setup completed successfully'
      };
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      await this.notifyObservers({
        type: 'error',
        data: { error: errorMessage },
        timestamp: new Date(),
        phase: 'Error',
        progress: 0,
        message: `Project setup failed: ${errorMessage}`
      });
      
      return {
        success: false,
        error: errorMessage,
        message: 'Project setup failed'
      };
    } finally {
      this.isProcessing = false;
    }
  }

  /**
   * Analyze repository using strategy pattern
   * Replaces: repository-analysis.sh
   */
  private async analyzeRepository(repositoryUrl: string): Promise<Repository> {
    await this.notifyObservers({
      type: 'repository_analysis_started',
      data: { repositoryUrl },
      timestamp: new Date(),
      phase: 'Repository Analysis',
      progress: 10,
      message: 'Analyzing repository structure and content'
    });

    const { owner, repo } = this.parseRepositoryUrl(repositoryUrl);
    
    // Fetch repository data from GitHub
    const repoData = await this.octokit.rest.repos.get({
      owner,
      repo
    });
    
    // Get repository contents and structure
    const contents = await this.octokit.rest.repos.getContent({
      owner,
      repo,
      path: ''
    });
    
    // Get languages
    const languages = await this.octokit.rest.repos.listLanguages({
      owner,
      repo
    });
    
    // Build repository model
    const repository: Repository = {
      owner,
      name: repo,
      fullName: repoData.data.full_name,
      url: repoData.data.html_url,
      defaultBranch: repoData.data.default_branch,
      language: repoData.data.language || 'Unknown',
      languages: languages.data,
      size: repoData.data.size,
      stargazers: repoData.data.stargazers_count,
      forks: repoData.data.forks_count,
      isPrivate: repoData.data.private,
      hasIssues: repoData.data.has_issues,
      hasProjects: repoData.data.has_projects,
      hasWiki: repoData.data.has_wiki,
      createdAt: new Date(repoData.data.created_at),
      updatedAt: new Date(repoData.data.updated_at),
      pushedAt: new Date(repoData.data.pushed_at),
      description: repoData.data.description || undefined,
      topics: repoData.data.topics || [],
      license: repoData.data.license?.name || undefined,
      fileStructure: await this.analyzeFileStructure(contents.data)
    };

    this.currentRepository = repository;
    
    // Use strategy pattern for detailed analysis
    const analyzer = this.analyzerFactory.createAnalyzer(
      this.determineProjectType(repository)
    );
    
    this.currentProject = await analyzer.analyze(repository);
    
    await this.notifyObservers({
      type: 'repository_analysis_completed',
      data: { repository, project: this.currentProject },
      timestamp: new Date(),
      phase: 'Repository Analysis',
      progress: 20,
      message: `Repository analysis completed: ${this.currentProject.projectType}`
    });

    return repository;
  }

  /**
   * Create GitHub project with custom fields
   * Replaces: working-project-setup.sh, setup-project-board.sh
   */
  private async createGitHubProject(
    organizationId: string,
    title: string,
    description: string
  ): Promise<GitHubProject> {
    await this.notifyObservers({
      type: 'project_creation_started',
      data: { title, description },
      timestamp: new Date(),
      phase: 'Project Creation',
      progress: 25,
      message: `Creating GitHub project: ${title}`
    });

    const projectData: ProjectData = {
      name: title,
      ownerId: organizationId,
      title,
      description
    };

    const createProjectCommand = new CreateProjectCommand(this.octokit, projectData);
    const result = await this.commandInvoker.executeCommand(createProjectCommand);

    if (!result.success) {
      throw new Error(`Failed to create project: ${result.error}`);
    }

    const projectResult = result.data as { projectId: string; projectUrl: string; projectNumber: number };
    const project: GitHubProject = {
      id: projectResult.projectId,
      url: projectResult.projectUrl,
      number: projectResult.projectNumber,
      title,
      description
    };

    await this.notifyObservers({
      type: 'project_created',
      data: project,
      timestamp: new Date(),
      phase: 'Project Creation',
      progress: 30,
      message: `GitHub project created: ${title}`
    });

    return project;
  }

  /**
   * Generate and create issues based on repository analysis
   * Replaces: create-github-issues.sh, secure-github-issues.sh
   */
  private async generateAndCreateIssues(
    repository: Repository,
    // eslint-disable-next-line @typescript-eslint/no-unused-vars, no-unused-vars
    _project: GitHubProject
  ): Promise<GitHubIssue[]> {
    await this.notifyObservers({
      type: 'issue_generation_started',
      data: { repository: repository.name },
      timestamp: new Date(),
      phase: 'Issue Generation',
      progress: 40,
      message: 'Generating issues based on repository analysis'
    });

    if (!this.currentProject) {
      throw new Error('Project analysis not completed');
    }

    // Generate issues based on project recommendations
    const issueDataList: IssueData[] = [];
    
    // Create epic issues
    for (const epic of this.currentProject.recommendations.suggestedEpics) {
      issueDataList.push({
        owner: repository.owner,
        repo: repository.name,
        title: epic.title,
        body: this.generateEpicDescription(epic),
        labels: ['epic', `priority-${epic.priority}`],
        issueType: 'feature'
      });
    }

    // Create user story issues
    for (const story of this.currentProject.recommendations.suggestedUserStories) {
      issueDataList.push({
        owner: repository.owner,
        repo: repository.name,
        title: story.title,
        body: this.generateUserStoryDescription(story),
        labels: ['user-story', `priority-${story.priority}`, ...story.labels],
        issueType: story.priority === 'critical' ? 'bug' : 'feature'
      });
    }

    // Create task issues
    for (const task of this.currentProject.recommendations.suggestedTasks) {
      issueDataList.push({
        owner: repository.owner,
        repo: repository.name,
        title: task.title,
        body: this.generateTaskDescription(task),
        labels: ['task', `priority-${task.priority}`],
        issueType: 'task'
      });
    }

    // Execute create issues command
    const createIssuesCommand = new CreateIssuesCommand(this.octokit, issueDataList);
    const result = await this.commandInvoker.executeCommand(createIssuesCommand);

    if (!result.success) {
      throw new Error(`Failed to create issues: ${result.error}`);
    }

    const issuesResult = result.data as { issues: GitHubIssue[] };
    const issues: GitHubIssue[] = issuesResult.issues;

    await this.notifyObservers({
      type: 'issues_created',
      data: { issues },
      timestamp: new Date(),
      phase: 'Issue Generation',
      progress: 60,
      message: `Created ${issues.length} issues`
    });

    return issues;
  }

  /**
   * Setup sprint with issues
   * Replaces: setup-sprint-assignment.sh, sprint1-preparation.sh
   */
  private async setupSprint(
    repository: Repository,
    project: GitHubProject,
    issues: GitHubIssue[]
  ): Promise<SprintSetup> {
    await this.notifyObservers({
      type: 'sprint_setup_started',
      data: { issueCount: issues.length },
      timestamp: new Date(),
      phase: 'Sprint Setup',
      progress: 70,
      message: 'Setting up initial sprint'
    });

    const sprintData: SprintData = {
      owner: repository.owner,
      repo: repository.name,
      number: 1,
      name: 'Foundation Sprint',
      startDate: new Date().toISOString().split('T')[0],
      duration: 2 // 2 weeks
    };

    const setupSprintCommand = new SetupSprintCommand(this.octokit, sprintData, project.id);
    const result = await this.commandInvoker.executeCommand(setupSprintCommand);

    if (!result.success) {
      throw new Error(`Failed to setup sprint: ${result.error}`);
    }

    const sprintResult = result.data as { issuesAssigned: number; sprintLabel: string };
    const sprint: SprintSetup = {
      number: sprintData.number,
      name: sprintData.name,
      startDate: sprintData.startDate,
      issuesAssigned: sprintResult.issuesAssigned,
      sprintLabel: sprintResult.sprintLabel
    };

    await this.notifyObservers({
      type: 'sprint_setup',
      data: sprint,
      timestamp: new Date(),
      phase: 'Sprint Setup',
      progress: 80,
      message: `Sprint setup completed: ${sprint.name}`
    });

    return sprint;
  }

  /**
   * Configure board with views and automation
   * Replaces: automated-kanban-setup.sh, status-lane-optimization.sh
   */
  private async configureBoard(
    project: GitHubProject,
    issues: GitHubIssue[]
  ): Promise<void> {
    await this.notifyObservers({
      type: 'board_configuration_started',
      data: { project },
      timestamp: new Date(),
      phase: 'Board Configuration',
      progress: 90,
      message: 'Configuring project board views and automation'
    });

    const boardData: BoardData = {
      items: issues.map(issue => ({
        id: issue.id,
        fieldId: 'status-field-id', // Would be retrieved from project
        value: 'Todo'
      }))
    };

    const updateBoardCommand = new UpdateBoardCommand(this.octokit, boardData, project.id);
    const result = await this.commandInvoker.executeCommand(updateBoardCommand);

    if (!result.success) {
      throw new Error(`Failed to configure board: ${result.error}`);
    }

    const boardResult = result.data as { itemsUpdated: number };
    await this.notifyObservers({
      type: 'board_updated',
      data: { itemsUpdated: boardResult.itemsUpdated },
      timestamp: new Date(),
      phase: 'Board Configuration',
      progress: 95,
      message: 'Board configuration completed'
    });
  }

  /**
   * Complete project setup with final configuration
   * Replaces: roadmap-setup-complete.sh, final-project-setup.sh
   */
  private async completeProjectSetup(
    project: GitHubProject,
    issues: GitHubIssue[],
    sprint: SprintSetup
  ): Promise<void> {
    // Log completion
    /* eslint-disable no-console */
    console.log('🎉 Project Setup Complete!');
    console.log('========================');
    console.log(`📋 Project: ${project.title}`);
    console.log(`🔗 URL: ${project.url}`);
    console.log(`📊 Issues Created: ${issues.length}`);
    console.log(`🏃 Sprint: ${sprint.name}`);
    console.log('');
    console.log('Next Steps:');
    console.log('1. Review project board and customize views');
    console.log('2. Assign team members to issues');
    console.log('3. Begin sprint planning');
    console.log('4. Start development workflow');
    /* eslint-enable no-console */
  }

  /**
   * Health check for the scrum master system
   * Replaces: health-check.sh, system-status.sh
   */
  async healthCheck(): Promise<HealthCheckResult> {
    const commandHealth = await this.commandInvoker.healthCheck();
    const recentEvents = this.getEventHistory().slice(-10);
    
    return {
      overall: commandHealth.isHealthy && recentEvents.filter(e => e.type === 'error').length === 0,
      commandInvoker: commandHealth,
      recentEvents: recentEvents.length,
      errorEvents: recentEvents.filter(e => e.type === 'error').length,
      isProcessing: this.isProcessing,
      lastActivity: this.getLastEvent()?.timestamp || null
    };
  }

  /**
   * Get current processing status
   * Replaces: progress-status.sh
   */
  getProcessingStatus(): ProcessingStatus {
    return {
      isProcessing: this.isProcessing,
      currentRepository: this.currentRepository?.name || null,
      currentProject: this.currentProject?.projectType || null,
      lastEvent: this.getLastEvent(),
      totalObservers: this.getObserverCount()
    };
  }

  // Private helper methods

  private parseRepositoryUrl(url: string): { owner: string; repo: string } {
    const match = url.match(/github\.com\/([^/]+)\/([^/]+)/);
    if (!match) {
      throw new Error('Invalid GitHub repository URL');
    }
    return { owner: match[1], repo: match[2] };
  }

  private determineProjectType(repository: Repository): ProjectType {
    // Simple project type detection
    if (repository.language === 'TypeScript' || repository.language === 'JavaScript') {
      return ProjectType.WEB_APPLICATION;
    }
    return ProjectType.UNKNOWN;
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars, no-unused-vars
  private async analyzeFileStructure(_contents: unknown): Promise<FileStructureAnalysis> {
    // Analyze file structure
    return {
      hasSourceDirectory: false,
      hasTests: false,
      hasDocumentation: false,
      documentationFiles: [],
      configFiles: [],
      buildFiles: []
    };
  }

  private generateEpicDescription(epic: Epic): string {
    return `## Epic: ${epic.title}\n\n${epic.description}\n\n**Estimated Story Points:** ${epic.estimatedStoryPoints}\n**Estimated Sprints:** ${epic.estimatedSprints}`;
  }

  private generateUserStoryDescription(story: UserStory): string {
    return `## User Story: ${story.title}\n\n${story.description}\n\n**Acceptance Criteria:**\n${story.acceptanceCriteria.map((criteria: string) => `- ${criteria}`).join('\n')}\n\n**Story Points:** ${story.estimatedStoryPoints}`;
  }

  private generateTaskDescription(task: Task): string {
    return `## Task: ${task.title}\n\n${task.description}\n\n**Estimated Hours:** ${task.estimatedHours}\n**Prerequisites:** ${task.prerequisites.join(', ')}`;
  }

  private generateProjectSummary(project: GitHubProject, issues: GitHubIssue[], sprint: SprintSetup): string {
    return `Project: ${project.title}\nIssues: ${issues.length}\nSprint: ${sprint.name}`;
  }
}

// Supporting interfaces

interface FileStructureAnalysis {
  hasSourceDirectory: boolean;
  hasTests: boolean;
  hasDocumentation: boolean;
  documentationFiles: string[];
  configFiles: string[];
  buildFiles: string[];
}

interface ProjectSetupResult {
  success: boolean;
  project?: GitHubProject;
  repository?: Repository;
  issuesCreated?: number;
  sprintConfigured?: boolean;
  projectUrl?: string;
  error?: string;
  message: string;
}

interface GitHubProject {
  id: string;
  url: string;
  number: number;
  title: string;
  description: string;
}

interface GitHubIssue {
  id: string;
  number: number;
  title: string;
  url: string;
}

interface SprintSetup {
  number?: number;
  name: string;
  startDate: string | Date;
  issuesAssigned: number;
  sprintLabel: string;
}

interface HealthCheckResult {
  overall: boolean;
  commandInvoker: CommandHealthCheckResult;
  recentEvents: number;
  errorEvents: number;
  isProcessing: boolean;
  lastActivity: Date | null;
}

interface ProcessingStatus {
  isProcessing: boolean;
  currentRepository: string | null;
  currentProject: string | null;
  lastEvent: ProgressEvent | null;
  totalObservers: number;
}
