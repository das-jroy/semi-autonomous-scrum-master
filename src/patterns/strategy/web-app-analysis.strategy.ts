import { AnalysisStrategy } from './analysis-strategy.interface';
import { Repository } from '../../models/repository.model';
import { 
  ProjectModel, 
  ProjectType, 
  TechnologyStack, 
  ProjectComplexity, 
  ComplexityLevel,
  ProjectCurrentState,
  ScrumRecommendations,
  EffortEstimation,
  RiskAssessment,
  RiskLevel,
  ConfidenceLevel,
  DocumentationQuality,
  CIStatus
} from '../../models/project.model';

/**
 * Web Application Analysis Strategy
 * 
 * Analyzes web application repositories and generates appropriate
 * project models with web-specific recommendations
 */
export class WebAppAnalysisStrategy implements AnalysisStrategy {
  
  async analyze(repository: Repository): Promise<ProjectModel> {
    const technologyStack = this.detectTechnologyStack(repository);
    const complexity = this.assessComplexity(repository, technologyStack);
    const currentState = this.assessCurrentState(repository);
    
    return {
      repository,
      projectType: this.determineProjectType(repository, technologyStack),
      technologyStack,
      complexity,
      currentState,
      recommendations: this.generateRecommendations(repository, technologyStack, complexity),
      estimatedEffort: this.estimateEffort(repository, complexity),
      riskAssessment: this.assessRisks(repository, technologyStack, complexity),
      estimatedDuration: this.estimateProjectDuration(repository, complexity),
      teamSize: this.calculateTeamSize(repository, complexity),
      mainFeatures: this.identifyMainFeatures(repository, technologyStack),
      technicalRequirements: this.defineTechnicalRequirements(repository, technologyStack),
      risks: this.identifyProjectRisks(repository, technologyStack, complexity),
      createdAt: new Date(),
      lastAnalyzed: new Date()
    };
  }

  canAnalyze(repository: Repository): boolean {
    // Check if this is a web application by looking at:
    // 1. Package.json with web frameworks
    // 2. HTML files
    // 3. Common web development patterns
    
    if (repository.packageJson) {
      const deps = {
        ...(repository.packageJson.dependencies as Record<string, unknown> || {}),
        ...(repository.packageJson.devDependencies as Record<string, unknown> || {})
      };
      
      // Check for web frameworks
      const webFrameworks = ['react', 'vue', 'angular', 'next', 'nuxt', 'svelte', 'gatsby', 'express', 'fastify', 'koa'];
      if (webFrameworks.some(framework => Object.prototype.hasOwnProperty.call(deps, framework))) {
        return true;
      }
    }
    
    // Check for HTML files in file structure
    if (repository.fileStructure?.documentationFiles?.some(file => file.endsWith('.html'))) {
      return true;
    }
    
    // Check for common web development patterns
    const webPatterns = ['public', 'static', 'assets', 'src/components', 'src/pages'];
    if (webPatterns.some(pattern => repository.fileStructure?.sourceDirectoryName?.includes(pattern))) {
      return true;
    }
    
    return false;
  }

  // eslint-disable-next-line complexity
  private detectTechnologyStack(repository: Repository): TechnologyStack {
    const stack: TechnologyStack = {
      primaryLanguage: repository.language,
      languages: repository.languages || {},
      frameworks: [],
      databases: [],
      cloudPlatforms: [],
      cicdTools: [],
      testingFrameworks: [],
      buildTools: [],
      packageManagers: [],
      containerization: [],
      infrastructure: []
    };

    // Detect frameworks based on files and dependencies
    if (repository.packageJson) {
      const deps = {
        ...(repository.packageJson.dependencies as Record<string, unknown> || {}),
        ...(repository.packageJson.devDependencies as Record<string, unknown> || {})
      };

      // React ecosystem
      if (deps.react) {
        stack.frameworks.push('React');
        if (deps['next']) stack.frameworks.push('Next.js');
        if (deps['gatsby']) stack.frameworks.push('Gatsby');
      }

      // Vue ecosystem
      if (deps.vue) {
        stack.frameworks.push('Vue.js');
        if (deps['nuxt']) stack.frameworks.push('Nuxt.js');
      }

      // Angular ecosystem
      if (deps['@angular/core']) {
        stack.frameworks.push('Angular');
      }

      // Backend frameworks
      if (deps.express) stack.frameworks.push('Express.js');
      if (deps.fastify) stack.frameworks.push('Fastify');
      if (deps.nestjs) stack.frameworks.push('NestJS');

      // Testing frameworks
      if (deps.jest) stack.testingFrameworks.push('Jest');
      if (deps.cypress) stack.testingFrameworks.push('Cypress');
      if (deps.playwright) stack.testingFrameworks.push('Playwright');

      // Build tools
      if (deps.webpack) stack.buildTools.push('Webpack');
      if (deps.vite) stack.buildTools.push('Vite');
      if (deps.rollup) stack.buildTools.push('Rollup');

      // Package managers
      if (repository.packageJson.packageManager) {
        stack.packageManagers.push(repository.packageJson.packageManager as string);
      } else {
        stack.packageManagers.push('npm'); // default
      }
    }

    // Detect containerization
    if (repository.dockerfile) {
      stack.containerization.push('Docker');
    }

    // Detect CI/CD
    if (repository.ciConfig?.hasGitHubActions) {
      stack.cicdTools.push('GitHub Actions');
    }

    return stack;
  }

  private determineProjectType(repository: Repository, stack: TechnologyStack): ProjectType {
    // React applications
    if (stack.frameworks.includes('React')) {
      if (stack.frameworks.includes('Next.js')) {
        return ProjectType.NEXT_JS_APPLICATION;
      }
      return ProjectType.REACT_APPLICATION;
    }

    // Vue applications
    if (stack.frameworks.includes('Vue.js')) {
      return ProjectType.VUE_APPLICATION;
    }

    // Angular applications
    if (stack.frameworks.includes('Angular')) {
      return ProjectType.ANGULAR_APPLICATION;
    }

    // API services
    if (stack.frameworks.some(f => ['Express.js', 'Fastify', 'NestJS'].includes(f))) {
      return ProjectType.API_SERVICE;
    }

    // Default to web application
    return ProjectType.WEB_APPLICATION;
  }

  private assessComplexity(repository: Repository, stack: TechnologyStack): ProjectComplexity {
    let complexityScore = 0;

    // Repository size factor
    if (repository.size > 100000) complexityScore += 3;
    else if (repository.size > 50000) complexityScore += 2;
    else if (repository.size > 10000) complexityScore += 1;

    // Language diversity
    const languageCount = Object.keys(repository.languages || {}).length;
    if (languageCount > 5) complexityScore += 2;
    else if (languageCount > 3) complexityScore += 1;

    // Framework complexity
    const frameworkCount = stack.frameworks.length;
    if (frameworkCount > 3) complexityScore += 2;
    else if (frameworkCount > 1) complexityScore += 1;

    // Determine overall complexity
    let overall: ComplexityLevel;
    if (complexityScore >= 6) overall = ComplexityLevel.VERY_HIGH;
    else if (complexityScore >= 4) overall = ComplexityLevel.HIGH;
    else if (complexityScore >= 2) overall = ComplexityLevel.MEDIUM;
    else overall = ComplexityLevel.LOW;

    return {
      overall,
      codebase: this.assessCodebaseComplexity(repository),
      architecture: this.assessArchitectureComplexity(stack),
      dependencies: this.assessDependencyComplexity(repository),
      testing: this.assessTestingComplexity(repository, stack),
      documentation: this.assessDocumentationComplexity(repository),
      factors: [
        {
          factor: 'Repository Size',
          impact: repository.size > 50000 ? ComplexityLevel.HIGH : ComplexityLevel.LOW,
          description: `Repository size: ${repository.size} bytes`
        },
        {
          factor: 'Technology Stack',
          impact: frameworkCount > 2 ? ComplexityLevel.MEDIUM : ComplexityLevel.LOW,
          description: `Using ${frameworkCount} frameworks: ${stack.frameworks.join(', ')}`
        }
      ]
    };
  }

  private assessCodebaseComplexity(repository: Repository): ComplexityLevel {
    // Simple heuristic based on repository size and file count
    if (repository.size > 100000) return ComplexityLevel.HIGH;
    if (repository.size > 50000) return ComplexityLevel.MEDIUM;
    return ComplexityLevel.LOW;
  }

  private assessArchitectureComplexity(stack: TechnologyStack): ComplexityLevel {
    const frameworkCount = stack.frameworks.length;
    if (frameworkCount > 3) return ComplexityLevel.HIGH;
    if (frameworkCount > 1) return ComplexityLevel.MEDIUM;
    return ComplexityLevel.LOW;
  }

  private assessDependencyComplexity(repository: Repository): ComplexityLevel {
    if (!repository.packageJson) return ComplexityLevel.LOW;
    
    const depCount = Object.keys(repository.packageJson.dependencies || {}).length;
    const devDepCount = Object.keys(repository.packageJson.devDependencies || {}).length;
    const totalDeps = depCount + devDepCount;

    if (totalDeps > 100) return ComplexityLevel.HIGH;
    if (totalDeps > 50) return ComplexityLevel.MEDIUM;
    return ComplexityLevel.LOW;
  }

  private assessTestingComplexity(repository: Repository, stack: TechnologyStack): ComplexityLevel {
    const hasTests = repository.fileStructure?.hasTests || false;
    const testFrameworkCount = stack.testingFrameworks.length;

    if (!hasTests) return ComplexityLevel.HIGH; // No tests = high complexity
    if (testFrameworkCount > 2) return ComplexityLevel.MEDIUM;
    return ComplexityLevel.LOW;
  }

  private assessDocumentationComplexity(repository: Repository): ComplexityLevel {
    const hasReadme = repository.readme !== undefined;
    const hasWiki = repository.hasWiki;
    const docFiles = repository.fileStructure?.documentationFiles || [];

    if (!hasReadme && !hasWiki && docFiles.length === 0) return ComplexityLevel.HIGH;
    if (hasReadme && (hasWiki || docFiles.length > 0)) return ComplexityLevel.LOW;
    return ComplexityLevel.MEDIUM;
  }

  private assessCurrentState(repository: Repository): ProjectCurrentState {
    // Implementation for current state assessment
    return {
      hasActiveIssues: repository.hasIssues,
      issueCount: 0, // Would need to fetch from API
      hasActivePullRequests: false, // Would need to fetch from API
      pullRequestCount: 0,
      hasRecentCommits: true,
      lastCommitDate: repository.pushedAt,
      hasDocumentation: repository.readme !== undefined,
      documentationQuality: DocumentationQuality.ADEQUATE,
      hasTests: repository.fileStructure?.hasTests || false,
      testCoverage: undefined,
      hasCI: repository.ciConfig?.hasGitHubActions || false,
      ciStatus: CIStatus.UNKNOWN,
      codeQuality: {
        maintainability: 70,
        reliability: 70,
        security: 70,
        technicalDebt: 0,
        codeSmells: 0,
        duplications: 0,
        vulnerabilities: 0,
        bugs: 0
      }
    };
  }

  private generateRecommendations(repository: Repository, stack: TechnologyStack, complexity: ProjectComplexity): ScrumRecommendations {
    // Generate scrum recommendations based on analysis
    const isComplexProject = complexity.overall === ComplexityLevel.HIGH || complexity.overall === ComplexityLevel.VERY_HIGH;
    
    return {
      recommendedSprintLength: isComplexProject ? 14 : 7, // 2 weeks for complex, 1 week for simple
      recommendedTeamSize: isComplexProject ? 5 : 3,
      recommendedVelocity: isComplexProject ? 40 : 20,
      suggestedEpics: [],
      suggestedUserStories: [],
      suggestedTasks: [],
      riskMitigations: [],
      improvementSuggestions: [
        'Add comprehensive testing suite',
        'Implement CI/CD pipeline',
        'Add API documentation',
        'Set up monitoring and logging'
      ]
    };
  }

  private estimateEffort(repository: Repository, complexity: ProjectComplexity): EffortEstimation {
    // Simple effort estimation based on complexity
    const baseHours = 160; // 1 month base
    const complexityMultiplier = {
      [ComplexityLevel.LOW]: 1,
      [ComplexityLevel.MEDIUM]: 1.5,
      [ComplexityLevel.HIGH]: 2,
      [ComplexityLevel.VERY_HIGH]: 3
    };

    const multiplier = complexityMultiplier[complexity.overall];
    const totalHours = baseHours * multiplier;

    return {
      totalStoryPoints: Math.round(totalHours / 8), // 8 hours per story point
      totalDevelopmentHours: Math.round(totalHours * 0.6),
      totalTestingHours: Math.round(totalHours * 0.2),
      totalDocumentationHours: Math.round(totalHours * 0.1),
      totalDeploymentHours: Math.round(totalHours * 0.1),
      estimatedSprints: Math.ceil(totalHours / 80), // 80 hours per sprint
      estimatedTeamSize: complexity.overall === ComplexityLevel.HIGH ? 5 : 3,
      estimatedDuration: Math.ceil(totalHours / 160), // 160 hours per month
      confidenceLevel: ConfidenceLevel.MEDIUM
    };
  }

  private assessRisks(repository: Repository, stack: TechnologyStack, complexity: ProjectComplexity): RiskAssessment {
    // Risk assessment logic
    return {
      overallRisk: complexity.overall === ComplexityLevel.HIGH ? RiskLevel.HIGH : RiskLevel.MEDIUM,
      technicalRisks: [],
      businessRisks: [],
      teamRisks: [],
      timelineRisks: [],
      mitigationStrategies: []
    };
  }

  private estimateProjectDuration(repository: Repository, complexity: ProjectComplexity): number {
    // Base duration in days based on complexity
    let baseDuration = 30; // 1 month for simple projects
    
    switch (complexity.overall) {
      case ComplexityLevel.LOW:
        baseDuration = 30;
        break;
      case ComplexityLevel.MEDIUM:
        baseDuration = 60;
        break;
      case ComplexityLevel.HIGH:
        baseDuration = 120;
        break;
    }
    
    // Adjust based on repository size as proxy for file count
    const sizeMultiplier = Math.max(1, (repository.size || 1000) / 5000);
    
    return Math.ceil(baseDuration * sizeMultiplier);
  }

  private calculateTeamSize(repository: Repository, complexity: ProjectComplexity): number {
    // Base team size
    let baseTeamSize = 2;
    
    switch (complexity.overall) {
      case ComplexityLevel.LOW:
        baseTeamSize = 2;
        break;
      case ComplexityLevel.MEDIUM:
        baseTeamSize = 4;
        break;
      case ComplexityLevel.HIGH:
        baseTeamSize = 6;
        break;
    }
    
    // Adjust based on repository size
    const sizeMultiplier = Math.max(1, (repository.size || 1000) / 10000);
    
    return Math.ceil(baseTeamSize * sizeMultiplier);
  }

  private identifyMainFeatures(repository: Repository, stack: TechnologyStack): string[] {
    const features: string[] = [];
    
    // Based on detected frameworks and technologies
    if (stack.frameworks.includes('React')) {
      features.push('Component-based UI', 'State management', 'Routing');
    }
    if (stack.frameworks.includes('Next.js')) {
      features.push('Server-side rendering', 'Static site generation', 'API routes');
    }
    if (stack.frameworks.includes('Vue')) {
      features.push('Reactive data binding', 'Component composition', 'Vue Router');
    }
    if (stack.frameworks.includes('Angular')) {
      features.push('TypeScript integration', 'Dependency injection', 'Angular CLI');
    }
    
    // Common web features
    features.push('Responsive design', 'Cross-browser compatibility');
    
    if (stack.databases.length > 0) {
      features.push('Data persistence', 'Database integration');
    }
    
    return features;
  }

  private defineTechnicalRequirements(repository: Repository, stack: TechnologyStack): string[] {
    const requirements: string[] = [];
    
    // Language requirements
    if (stack.primaryLanguage) {
      requirements.push(`${stack.primaryLanguage} runtime`);
    }
    
    // Framework requirements
    stack.frameworks.forEach(framework => {
      requirements.push(`${framework} framework`);
    });
    
    // Database requirements
    stack.databases.forEach(db => {
      requirements.push(`${db} database`);
    });
    
    // Build tool requirements
    stack.buildTools.forEach(tool => {
      requirements.push(`${tool} build system`);
    });
    
    // Common web requirements
    requirements.push('Web browser support', 'HTTP/HTTPS protocol', 'DOM manipulation capabilities');
    
    if (stack.containerization.length > 0) {
      requirements.push('Container runtime');
    }
    
    return requirements;
  }

  private identifyProjectRisks(repository: Repository, stack: TechnologyStack, complexity: ProjectComplexity): string[] {
    const risks: string[] = [];
    
    // Complexity-based risks
    if (complexity.overall === ComplexityLevel.HIGH) {
      risks.push('High technical complexity may lead to delays');
      risks.push('Integration challenges between multiple systems');
    }
    
    // Technology stack risks
    if (stack.frameworks.length > 3) {
      risks.push('Multiple frameworks may increase learning curve');
    }
    
    if (stack.databases.length > 1) {
      risks.push('Multiple databases may complicate data consistency');
    }
    
    // Size-based risks
    if ((repository.size || 0) > 50000) {
      risks.push('Large codebase may impact maintainability');
    }
    
    // Default risks for web applications
    risks.push('Browser compatibility issues');
    risks.push('Performance optimization challenges');
    risks.push('Security vulnerabilities in web components');
    
    return risks;
  }
}
