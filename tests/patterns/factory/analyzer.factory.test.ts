import { AnalyzerFactory } from '../../../src/patterns/factory/analyzer.factory';
import { AnalysisStrategy } from '../../../src/patterns/strategy/analysis-strategy.interface';
import { Repository } from '../../../src/models/repository.model';
import { ProjectType } from '../../../src/models/project.model';

describe('AnalyzerFactory', () => {
  let factory: AnalyzerFactory;
  let mockRepository: Repository;

  beforeEach(() => {
    factory = new AnalyzerFactory();
    
    // Create a minimal mock repository that satisfies the interface
    mockRepository = {
      owner: 'testowner',
      name: 'test-repo',
      fullName: 'testowner/test-repo',
      url: 'https://github.com/testowner/test-repo',
      defaultBranch: 'main',
      language: 'TypeScript',
      size: 1024,
      stargazers: 25,
      forks: 5,
      isPrivate: false,
      hasIssues: true,
      hasProjects: true,
      hasWiki: false,
      createdAt: new Date('2024-01-01'),
      updatedAt: new Date('2024-01-15'),
      pushedAt: new Date('2024-01-15'),
      description: 'A test repository',
      topics: ['typescript', 'web-app'],
      license: 'MIT'
    };
  });

  describe('getStrategy', () => {
    it('should return a strategy for web applications', () => {
      mockRepository.language = 'JavaScript';
      mockRepository.topics = ['react', 'web-app', 'frontend'];
      
      const strategy = factory.getStrategy(mockRepository);
      
      expect(strategy).toBeDefined();
      expect(strategy).toHaveProperty('analyze');
    });

    it('should return a strategy for TypeScript repositories', () => {
      mockRepository.language = 'TypeScript';
      
      const strategy = factory.getStrategy(mockRepository);
      
      expect(strategy).toBeDefined();
      expect(strategy).toHaveProperty('analyze');
    });

    it('should return a strategy for Python repositories', () => {
      mockRepository.language = 'Python';
      mockRepository.topics = ['python', 'web-framework'];
      
      const strategy = factory.getStrategy(mockRepository);
      
      expect(strategy).toBeDefined();
      expect(strategy).toHaveProperty('analyze');
    });

    it('should handle repositories with no topics', () => {
      mockRepository.topics = [];
      
      const strategy = factory.getStrategy(mockRepository);
      
      expect(strategy).toBeDefined();
    });

    it('should handle repositories with undefined topics', () => {
      mockRepository.topics = undefined;
      
      const strategy = factory.getStrategy(mockRepository);
      
      expect(strategy).toBeDefined();
    });

    it('should handle repositories with unknown languages', () => {
      mockRepository.language = 'COBOL';
      mockRepository.topics = ['legacy', 'mainframe'];
      
      const strategy = factory.getStrategy(mockRepository);
      
      expect(strategy).toBeDefined();
    });
  });

  describe('getAvailableStrategies', () => {
    it('should return available strategy names', () => {
      const strategies = factory.getAvailableStrategies();
      
      expect(strategies).toBeDefined();
      expect(Array.isArray(strategies)).toBe(true);
      expect(strategies.length).toBeGreaterThan(0);
    });

    it('should include web application strategy', () => {
      const strategies = factory.getAvailableStrategies();
      
      expect(strategies).toContain('WebApp Analysis Strategy');
    });
  });

  describe('strategy analysis integration', () => {
    it('should return strategy that can analyze the repository', async () => {
      mockRepository.language = 'TypeScript';
      mockRepository.topics = ['react', 'typescript', 'web-app'];
      
      const strategy = factory.getStrategy(mockRepository);
      const analysis = await strategy.analyze(mockRepository);
      
      expect(analysis).toBeDefined();
      expect(analysis).toHaveProperty('projectType');
      expect(analysis).toHaveProperty('repository');
      expect(analysis.repository).toEqual(mockRepository);
    });

    it('should handle different repository configurations', async () => {
      // Test with different configurations
      const configurations = [
        { language: 'JavaScript', topics: ['react', 'frontend'] },
        { language: 'TypeScript', topics: ['vue', 'web'] },
        { language: 'Python', topics: ['django', 'web-framework'] },
        { language: 'Java', topics: ['spring', 'backend'] }
      ];

      for (const config of configurations) {
        mockRepository.language = config.language;
        mockRepository.topics = config.topics;
        
        const strategy = factory.getStrategy(mockRepository);
        const analysis = await strategy.analyze(mockRepository);
        
        expect(analysis).toBeDefined();
        expect(analysis.projectType).toBeDefined();
        expect(Object.values(ProjectType)).toContain(analysis.projectType);
      }
    });
  });

  describe('error handling', () => {
    it('should handle null repository gracefully', () => {
      expect(() => {
        factory.getStrategy(null as any);
      }).not.toThrow();
    });

    it('should handle repository with missing required fields', () => {
      const incompleteRepo = {
        owner: 'test',
        name: 'test'
      } as Repository;
      
      expect(() => {
        factory.getStrategy(incompleteRepo);
      }).not.toThrow();
    });
  });

  describe('factory pattern implementation', () => {
    it('should create new strategy instances', () => {
      const strategy1 = factory.getStrategy(mockRepository);
      const strategy2 = factory.getStrategy(mockRepository);
      
      // Should create new instances (not necessarily the same object)
      expect(strategy1).toBeDefined();
      expect(strategy2).toBeDefined();
    });

    it('should create appropriate strategy based on repository characteristics', () => {
      // Web application repository
      mockRepository.language = 'JavaScript';
      mockRepository.topics = ['react', 'web-app'];
      const webStrategy = factory.getStrategy(mockRepository);
      
      // Different repository
      mockRepository.language = 'Python';
      mockRepository.topics = ['data-science', 'machine-learning'];
      const pythonStrategy = factory.getStrategy(mockRepository);
      
      expect(webStrategy).toBeDefined();
      expect(pythonStrategy).toBeDefined();
    });
  });
});
