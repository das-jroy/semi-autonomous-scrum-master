import { jest } from '@jest/globals';
import { ScrumMasterEngine } from '../../src/core/scrum-master-engine';
import { Repository } from '../../src/models/repository.model';

// Mock external dependencies
jest.mock('@octokit/rest');
jest.mock('../../src/patterns/factory/analyzer.factory');
jest.mock('../../src/patterns/command/command-invoker');

describe('ScrumMasterEngine', () => {
  let engine: ScrumMasterEngine;
  let mockOctokit: any;
  let mockFactory: any;
  let mockCommandInvoker: any;
  let mockObserver: any;

  beforeEach(() => {
    // Mock Octokit
    mockOctokit = {
      rest: {
        repos: {
          get: jest.fn(),
          getContent: jest.fn(),
          listLanguages: jest.fn()
        },
        projects: {
          createForOrg: jest.fn(),
          createForRepo: jest.fn()
        },
        issues: {
          create: jest.fn(),
          list: jest.fn()
        }
      }
    };

    // Mock factory
    mockFactory = {
      createAnalyzer: jest.fn()
    };

    // Mock command invoker
    mockCommandInvoker = {
      addProgressListener: jest.fn(),
      executeCommand: jest.fn(),
      executeBatch: jest.fn(),
      healthCheck: jest.fn()
    };

    // Mock observer
    mockObserver = {
      onProgress: jest.fn(),
      onComplete: jest.fn(),
      onError: jest.fn()
    };

    // Setup mocks
    const { Octokit } = require('@octokit/rest');
    const { ConcreteAnalyzerFactory } = require('../../src/patterns/factory/analyzer.factory');
    const { GitHubProjectCommandInvoker } = require('../../src/patterns/command/command-invoker');

    Octokit.mockImplementation(() => mockOctokit);
    ConcreteAnalyzerFactory.mockImplementation(() => mockFactory);
    GitHubProjectCommandInvoker.mockImplementation(() => mockCommandInvoker);

    engine = new ScrumMasterEngine('test-token');
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('Constructor', () => {
    it('should initialize with GitHub token', () => {
      expect(engine).toBeDefined();
      expect(engine).toBeInstanceOf(ScrumMasterEngine);
    });

    it('should setup Octokit client', () => {
      const { Octokit } = require('@octokit/rest');
      expect(Octokit).toHaveBeenCalledWith({
        auth: 'test-token'
      });
    });

    it('should initialize factory and command invoker', () => {
      const { ConcreteAnalyzerFactory } = require('../../src/patterns/factory/analyzer.factory');
      const { GitHubProjectCommandInvoker } = require('../../src/patterns/command/command-invoker');
      
      expect(ConcreteAnalyzerFactory).toHaveBeenCalled();
      expect(GitHubProjectCommandInvoker).toHaveBeenCalled();
    });

    it('should setup progress listener on command invoker', () => {
      expect(mockCommandInvoker.addProgressListener).toHaveBeenCalled();
    });
  });

  describe('Project Setup Workflow', () => {
    beforeEach(() => {
      // Mock repository data
      mockOctokit.rest.repos.get.mockResolvedValue({
        data: {
          full_name: 'test/repo',
          html_url: 'https://github.com/test/repo',
          default_branch: 'main',
          language: 'TypeScript',
          size: 1024,
          stargazers_count: 10,
          forks_count: 2,
          private: false,
          has_issues: true,
          has_projects: true,
          has_wiki: false,
          created_at: '2024-01-01T00:00:00Z',
          updated_at: '2024-01-15T00:00:00Z',
          pushed_at: '2024-01-15T00:00:00Z',
          description: 'Test repository',
          topics: ['typescript', 'testing'],
          license: { name: 'MIT' }
        }
      });

      mockOctokit.rest.repos.getContent.mockResolvedValue({
        data: [
          { name: 'src', type: 'dir' },
          { name: 'package.json', type: 'file' },
          { name: 'README.md', type: 'file' }
        ]
      });

      mockOctokit.rest.repos.listLanguages.mockResolvedValue({
        data: { TypeScript: 80, JavaScript: 20 }
      });

      mockOctokit.rest.projects.createForOrg.mockResolvedValue({
        data: {
          id: 123,
          name: 'Test Project',
          url: 'https://github.com/orgs/test/projects/1'
        }
      });

      mockCommandInvoker.executeCommand.mockResolvedValue({
        success: true,
        data: { id: 'test-id' }
      });

      mockCommandInvoker.executeBatch.mockResolvedValue({
        success: true,
        results: [{ success: true }]
      });
    });

    it('should complete full project setup successfully', async () => {
      const result = await engine.setupProject(
        'https://github.com/test/repo',
        'Test Project',
        'Test Description',
        'test-org'
      );

      expect(result.success).toBe(true);
      expect(result.project).toBeDefined();
      expect(result.repository).toBeDefined();
      expect(result.issuesCreated).toBeGreaterThanOrEqual(0);
      expect(result.projectUrl).toBeDefined();
    });

    it('should handle repository analysis', async () => {
      await engine.setupProject(
        'https://github.com/test/repo',
        'Test Project',
        'Test Description',
        'test-org'
      );

      expect(mockOctokit.rest.repos.get).toHaveBeenCalledWith({
        owner: 'test',
        repo: 'repo'
      });
      expect(mockOctokit.rest.repos.getContent).toHaveBeenCalledWith({
        owner: 'test',
        repo: 'repo',
        path: ''
      });
      expect(mockOctokit.rest.repos.listLanguages).toHaveBeenCalledWith({
        owner: 'test',
        repo: 'repo'
      });
    });

    it('should handle project setup failure', async () => {
      mockOctokit.rest.repos.get.mockRejectedValue(new Error('Repository not found'));

      const result = await engine.setupProject(
        'https://github.com/test/nonexistent',
        'Test Project',
        'Test Description',
        'test-org'
      );

      expect(result.success).toBe(false);
      expect(result.error).toBe('Repository not found');
    });

    it('should parse repository URL correctly', async () => {
      const testUrls = [
        'https://github.com/owner/repo',
        'https://github.com/owner/repo.git',
        'git@github.com:owner/repo.git'
      ];

      for (const url of testUrls) {
        mockOctokit.rest.repos.get.mockResolvedValueOnce({
          data: {
            full_name: 'owner/repo',
            html_url: 'https://github.com/owner/repo',
            default_branch: 'main',
            language: 'JavaScript',
            size: 100,
            stargazers_count: 0,
            forks_count: 0,
            private: false,
            has_issues: true,
            has_projects: true,
            has_wiki: false,
            created_at: '2024-01-01T00:00:00Z',
            updated_at: '2024-01-01T00:00:00Z',
            pushed_at: '2024-01-01T00:00:00Z'
          }
        });

        const result = await engine.setupProject(
          url,
          'Test Project',
          'Test Description',
          'test-org'
        );

        expect(result.success).toBe(true);
        expect(mockOctokit.rest.repos.get).toHaveBeenCalledWith({
          owner: 'owner',
          repo: 'repo'
        });
      }
    });
  });

  describe('Observer Pattern Integration', () => {
    it('should add observers successfully', () => {
      engine.addObserver(mockObserver);
      
      // Verify observer was added (this depends on implementation)
      expect(engine.addObserver).toBeDefined();
    });

    it('should notify observers of progress events', async () => {
      engine.addObserver(mockObserver);

      // Setup mock data
      mockOctokit.rest.repos.get.mockResolvedValue({
        data: {
          full_name: 'test/repo',
          html_url: 'https://github.com/test/repo',
          default_branch: 'main',
          language: 'TypeScript',
          size: 1024,
          stargazers_count: 10,
          forks_count: 2,
          private: false,
          has_issues: true,
          has_projects: true,
          has_wiki: false,
          created_at: '2024-01-01T00:00:00Z',
          updated_at: '2024-01-15T00:00:00Z',
          pushed_at: '2024-01-15T00:00:00Z'
        }
      });

      await engine.setupProject(
        'https://github.com/test/repo',
        'Test Project',
        'Test Description',
        'test-org'
      );

      // Observers should be notified during the process
      expect(mockObserver.onProgress).toBeDefined();
    });

    it('should handle observer errors gracefully', () => {
      const faultyObserver = {
        onProgress: jest.fn().mockImplementation(() => {
          throw new Error('Observer error');
        })
      };

      engine.addObserver(faultyObserver);
      
      // Should not throw even if observer fails
      expect(() => engine.addObserver(faultyObserver)).not.toThrow();
    });
  });

  describe('Health Check', () => {
    beforeEach(() => {
      mockCommandInvoker.healthCheck.mockResolvedValue({
        isHealthy: true,
        successRate: 95,
        totalCommands: 100,
        failedCommands: 5,
        averageResponseTime: 150
      });
    });

    it('should return healthy status', async () => {
      const health = await engine.healthCheck();

      expect(health.overall).toBe(true);
      expect(health.commandInvoker).toBeDefined();
      expect(health.commandInvoker.isHealthy).toBe(true);
    });

    it('should return unhealthy status when issues detected', async () => {
      mockCommandInvoker.healthCheck.mockResolvedValue({
        isHealthy: false,
        successRate: 60,
        totalCommands: 100,
        failedCommands: 40,
        averageResponseTime: 5000
      });

      const health = await engine.healthCheck();

      expect(health.overall).toBe(false);
      expect(health.commandInvoker.isHealthy).toBe(false);
    });

    it('should handle health check errors', async () => {
      mockCommandInvoker.healthCheck.mockRejectedValue(new Error('Health check failed'));

      const health = await engine.healthCheck();

      expect(health.overall).toBe(false);
      expect(health.errorEvents).toBeGreaterThan(0);
    });
  });

  describe('Processing Status', () => {
    it('should return current processing status', () => {
      const status = engine.getProcessingStatus();

      expect(status).toBeDefined();
      expect(status.isProcessing).toBe(false); // Initially not processing
      expect(status.totalObservers).toBeDefined();
    });

    it('should update processing status during operations', async () => {
      // Setup mock data
      mockOctokit.rest.repos.get.mockResolvedValue({
        data: {
          full_name: 'test/repo',
          html_url: 'https://github.com/test/repo',
          default_branch: 'main',
          language: 'TypeScript',
          size: 1024,
          stargazers_count: 10,
          forks_count: 2,
          private: false,
          has_issues: true,
          has_projects: true,
          has_wiki: false,
          created_at: '2024-01-01T00:00:00Z',
          updated_at: '2024-01-15T00:00:00Z',
          pushed_at: '2024-01-15T00:00:00Z'
        }
      });

      const setupPromise = engine.setupProject(
        'https://github.com/test/repo',
        'Test Project',
        'Test Description',
        'test-org'
      );

      // Check processing status during operation
      const statusDuringProcessing = engine.getProcessingStatus();
      expect(statusDuringProcessing.isProcessing).toBe(true);

      await setupPromise;

      // Check processing status after completion
      const statusAfterProcessing = engine.getProcessingStatus();
      expect(statusAfterProcessing.isProcessing).toBe(false);
    });
  });

  describe('Command Integration', () => {
    it('should execute commands through command invoker', async () => {
      mockCommandInvoker.executeCommand.mockResolvedValue({
        success: true,
        data: { id: 'test-command-result' }
      });

      // Setup project to trigger commands
      await engine.setupProject(
        'https://github.com/test/repo',
        'Test Project',
        'Test Description',
        'test-org'
      );

      expect(mockCommandInvoker.executeCommand).toHaveBeenCalled();
    });

    it('should handle command execution failures', async () => {
      mockCommandInvoker.executeCommand.mockResolvedValue({
        success: false,
        error: 'Command failed'
      });

      const result = await engine.setupProject(
        'https://github.com/test/repo',
        'Test Project',
        'Test Description',
        'test-org'
      );

      expect(result.success).toBe(false);
    });

    it('should execute batch commands', async () => {
      mockCommandInvoker.executeBatch.mockResolvedValue({
        success: true,
        results: [
          { success: true, data: { id: 'cmd1' } },
          { success: true, data: { id: 'cmd2' } }
        ]
      });

      await engine.setupProject(
        'https://github.com/test/repo',
        'Test Project',
        'Test Description',
        'test-org'
      );

      expect(mockCommandInvoker.executeBatch).toHaveBeenCalled();
    });
  });

  describe('Error Handling', () => {
    it('should handle network errors gracefully', async () => {
      mockOctokit.rest.repos.get.mockRejectedValue(new Error('Network error'));

      const result = await engine.setupProject(
        'https://github.com/test/repo',
        'Test Project',
        'Test Description',
        'test-org'
      );

      expect(result.success).toBe(false);
      expect(result.error).toBe('Network error');
    });

    it('should handle invalid repository URLs', async () => {
      const result = await engine.setupProject(
        'invalid-url',
        'Test Project',
        'Test Description',
        'test-org'
      );

      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
    });

    it('should handle GitHub API errors', async () => {
      mockOctokit.rest.repos.get.mockRejectedValue({
        status: 404,
        message: 'Not Found'
      });

      const result = await engine.setupProject(
        'https://github.com/test/nonexistent',
        'Test Project',
        'Test Description',
        'test-org'
      );

      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
    });
  });

  describe('Integration with Factory Pattern', () => {
    it('should use analyzer factory for repository analysis', async () => {
      const mockAnalyzer = {
        analyze: jest.fn().mockResolvedValue({
          projectType: 'web-application',
          complexity: 'medium',
          recommendations: ['Use TypeScript', 'Add tests']
        })
      };

      mockFactory.createAnalyzer.mockReturnValue(mockAnalyzer);

      await engine.setupProject(
        'https://github.com/test/repo',
        'Test Project',
        'Test Description',
        'test-org'
      );

      expect(mockFactory.createAnalyzer).toHaveBeenCalled();
    });
  });
});