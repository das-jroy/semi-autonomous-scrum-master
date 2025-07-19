import { WebAppAnalysisStrategy } from '../../../src/patterns/strategy/web-app-analysis.strategy';
import { AnalysisStrategy } from '../../../src/patterns/strategy/analysis-strategy.interface';
import { Repository } from '../../../src/models/repository.model';
import { ProjectType } from '../../../src/models/project.model';

describe('WebAppAnalysisStrategy', () => {
  let strategy: AnalysisStrategy;
  let mockRepository: Repository;

  beforeEach(() => {
    strategy = new WebAppAnalysisStrategy();
    
    mockRepository = {
      name: 'test-webapp',
      owner: 'testowner',
      description: 'A test web application',
      language: 'TypeScript',
      framework: 'React',
      size: 'medium',
      complexity: 'moderate',
      topics: ['javascript', 'react', 'typescript', 'web-app'],
      hasReadme: true,
      hasPackageJson: true,
      hasTests: true,
      dependencies: [
        'react',
        'react-dom',
        'typescript',
        '@types/react',
        '@types/react-dom',
        'webpack',
        'babel-loader'
      ],
      fileStructure: {
        'src/': ['components/', 'hooks/', 'utils/', 'types/'],
        'public/': ['index.html', 'favicon.ico'],
        'package.json': null,
        'tsconfig.json': null,
        'README.md': null
      },
      lastActivity: '2024-01-15',
      contributors: 3,
      stars: 25,
      forks: 5
    };
  });

  describe('canAnalyze', () => {
    it('should return true for web applications', () => {
      const canAnalyze = strategy.canAnalyze(mockRepository);
      expect(canAnalyze).toBe(true);
    });

    it('should return true for React applications', () => {
      mockRepository.framework = 'React';
      const canAnalyze = strategy.canAnalyze(mockRepository);
      expect(canAnalyze).toBe(true);
    });

    it('should return true for Vue applications', () => {
      mockRepository.framework = 'Vue';
      const canAnalyze = strategy.canAnalyze(mockRepository);
      expect(canAnalyze).toBe(true);
    });

    it('should return true for Angular applications', () => {
      mockRepository.framework = 'Angular';
      const canAnalyze = strategy.canAnalyze(mockRepository);
      expect(canAnalyze).toBe(true);
    });

    it('should return true for repositories with web-related dependencies', () => {
      mockRepository.framework = 'Unknown';
      mockRepository.dependencies = ['express', 'webpack', 'babel'];
      const canAnalyze = strategy.canAnalyze(mockRepository);
      expect(canAnalyze).toBe(true);
    });

    it('should return false for non-web applications', () => {
      mockRepository.framework = 'Unknown';
      mockRepository.dependencies = ['pandas', 'numpy', 'scikit-learn'];
      mockRepository.topics = ['data-science', 'machine-learning'];
      const canAnalyze = strategy.canAnalyze(mockRepository);
      expect(canAnalyze).toBe(false);
    });
  });

  describe('analyze', () => {
    it('should generate analysis for React web application', async () => {
      const analysis = await strategy.analyze(mockRepository);

      expect(analysis).toBeDefined();
      expect(analysis.projectType).toBe(ProjectType.WEB_APPLICATION);
      expect(analysis.estimatedDuration).toBeGreaterThan(0);
      expect(analysis.teamSize).toBeGreaterThan(0);
      expect(analysis.complexity).toBeDefined();
      expect(analysis.mainFeatures).toBeDefined();
      expect(analysis.mainFeatures.length).toBeGreaterThan(0);
      expect(analysis.technicalRequirements).toBeDefined();
      expect(analysis.technicalRequirements.length).toBeGreaterThan(0);
      expect(analysis.risks).toBeDefined();
      expect(analysis.risks.length).toBeGreaterThan(0);
      expect(analysis.recommendations).toBeDefined();
      expect(analysis.recommendations.length).toBeGreaterThan(0);
    });

    it('should include React-specific features and requirements', async () => {
      mockRepository.framework = 'React';
      const analysis = await strategy.analyze(mockRepository);

      expect(analysis.mainFeatures).toEqual(
        expect.arrayContaining([
          expect.stringContaining('React')
        ])
      );
      
      expect(analysis.technicalRequirements).toEqual(
        expect.arrayContaining([
          expect.stringContaining('React')
        ])
      );
    });

    it('should include Vue-specific features for Vue applications', async () => {
      mockRepository.framework = 'Vue';
      mockRepository.dependencies = ['vue', '@vue/cli', 'vuex', 'vue-router'];
      
      const analysis = await strategy.analyze(mockRepository);

      expect(analysis.mainFeatures).toEqual(
        expect.arrayContaining([
          expect.stringContaining('Vue')
        ])
      );
    });

    it('should include Angular-specific features for Angular applications', async () => {
      mockRepository.framework = 'Angular';
      mockRepository.dependencies = ['@angular/core', '@angular/cli', 'rxjs', 'typescript'];
      
      const analysis = await strategy.analyze(mockRepository);

      expect(analysis.mainFeatures).toEqual(
        expect.arrayContaining([
          expect.stringContaining('Angular')
        ])
      );
    });

    it('should adjust complexity based on repository size', async () => {
      // Test small repository
      mockRepository.size = 'small';
      const smallAnalysis = await strategy.analyze(mockRepository);

      // Test large repository
      mockRepository.size = 'large';
      const largeAnalysis = await strategy.analyze(mockRepository);

      expect(smallAnalysis.complexity).toBe('Low');
      expect(largeAnalysis.complexity).toBe('High');
    });

    it('should adjust team size based on repository complexity', async () => {
      // Test simple repository
      mockRepository.complexity = 'simple';
      const simpleAnalysis = await strategy.analyze(mockRepository);

      // Test complex repository
      mockRepository.complexity = 'complex';
      const complexAnalysis = await strategy.analyze(mockRepository);

      expect(simpleAnalysis.teamSize).toBeLessThan(complexAnalysis.teamSize);
    });

    it('should adjust duration based on repository size and complexity', async () => {
      // Test small, simple repository
      mockRepository.size = 'small';
      mockRepository.complexity = 'simple';
      const shortAnalysis = await strategy.analyze(mockRepository);

      // Test large, complex repository
      mockRepository.size = 'large';
      mockRepository.complexity = 'complex';
      const longAnalysis = await strategy.analyze(mockRepository);

      expect(shortAnalysis.estimatedDuration).toBeLessThan(longAnalysis.estimatedDuration);
    });

    it('should include testing requirements when tests are present', async () => {
      mockRepository.hasTests = true;
      const analysis = await strategy.analyze(mockRepository);

      expect(analysis.technicalRequirements).toEqual(
        expect.arrayContaining([
          expect.stringMatching(/test/i)
        ])
      );
    });

    it('should include deployment and build requirements', async () => {
      const analysis = await strategy.analyze(mockRepository);

      expect(analysis.technicalRequirements).toEqual(
        expect.arrayContaining([
          expect.stringMatching(/build|deploy|ci\/cd/i)
        ])
      );
    });

    it('should identify performance and scalability risks', async () => {
      const analysis = await strategy.analyze(mockRepository);

      expect(analysis.risks).toEqual(
        expect.arrayContaining([
          expect.stringMatching(/performance|scalability|browser/i)
        ])
      );
    });

    it('should provide relevant recommendations', async () => {
      const analysis = await strategy.analyze(mockRepository);

      expect(analysis.recommendations).toEqual(
        expect.arrayContaining([
          expect.stringMatching(/component|state|testing|performance/i)
        ])
      );
    });

    it('should handle repositories without package.json', async () => {
      mockRepository.hasPackageJson = false;
      mockRepository.dependencies = [];

      const analysis = await strategy.analyze(mockRepository);

      expect(analysis).toBeDefined();
      expect(analysis.projectType).toBe(ProjectType.WEB_APPLICATION);
      expect(analysis.risks).toEqual(
        expect.arrayContaining([
          expect.stringMatching(/dependency/i)
        ])
      );
    });

    it('should handle repositories without README', async () => {
      mockRepository.hasReadme = false;

      const analysis = await strategy.analyze(mockRepository);

      expect(analysis).toBeDefined();
      expect(analysis.recommendations).toEqual(
        expect.arrayContaining([
          expect.stringMatching(/documentation/i)
        ])
      );
    });

    it('should provide different analysis for different frameworks', async () => {
      // Analyze React app
      mockRepository.framework = 'React';
      const reactAnalysis = await strategy.analyze(mockRepository);

      // Analyze Vue app
      mockRepository.framework = 'Vue';
      const vueAnalysis = await strategy.analyze(mockRepository);

      // Analyses should be different but both valid
      expect(reactAnalysis.mainFeatures).not.toEqual(vueAnalysis.mainFeatures);
      expect(reactAnalysis.technicalRequirements).not.toEqual(vueAnalysis.technicalRequirements);
      
      // But both should be web applications
      expect(reactAnalysis.projectType).toBe(ProjectType.WEB_APPLICATION);
      expect(vueAnalysis.projectType).toBe(ProjectType.WEB_APPLICATION);
    });

    it('should handle missing or undefined dependencies gracefully', async () => {
      mockRepository.dependencies = undefined as any;

      const analysis = await strategy.analyze(mockRepository);

      expect(analysis).toBeDefined();
      expect(analysis.projectType).toBe(ProjectType.WEB_APPLICATION);
    });

    it('should handle empty file structure', async () => {
      mockRepository.fileStructure = {};

      const analysis = await strategy.analyze(mockRepository);

      expect(analysis).toBeDefined();
      expect(analysis.projectType).toBe(ProjectType.WEB_APPLICATION);
    });
  });

  describe('getStrategyName', () => {
    it('should return correct strategy name', () => {
      const strategyName = strategy.getStrategyName();
      expect(strategyName).toBe('WebApp Analysis Strategy');
    });
  });

  describe('getProjectType', () => {
    it('should return WEB_APPLICATION project type', () => {
      const projectType = strategy.getProjectType();
      expect(projectType).toBe(ProjectType.WEB_APPLICATION);
    });
  });
});
