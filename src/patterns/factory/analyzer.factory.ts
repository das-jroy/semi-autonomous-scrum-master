import { AnalysisStrategy } from '../strategy/analysis-strategy.interface';
import { WebAppAnalysisStrategy } from '../strategy/web-app-analysis.strategy';
import { ProjectType, ProjectModel } from '../../models/project.model';
import { Repository } from '../../models/repository.model';

/**
 * Placeholder strategy for analysis types not yet implemented
 */
class DefaultAnalysisStrategy implements AnalysisStrategy {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars, no-unused-vars
  async analyze(_repository: Repository): Promise<ProjectModel> {
    throw new Error('Analysis strategy not implemented');
  }
  
  // eslint-disable-next-line @typescript-eslint/no-unused-vars, no-unused-vars
  canAnalyze(_repository: Repository): boolean {
    return false;
  }
}

/**
 * Factory Pattern: Abstract Analyzer Factory
 * 
 * Defines the interface for creating analysis strategies
 */
export abstract class AnalyzerFactory {
  abstract createAnalyzer(projectType: ProjectType): AnalysisStrategy;
}

/**
 * Concrete Analyzer Factory
 * 
 * Creates specific analysis strategies based on project type
 */
export class ConcreteAnalyzerFactory extends AnalyzerFactory {
  
  createAnalyzer(projectType: ProjectType): AnalysisStrategy {
    switch (projectType) {
      case ProjectType.WEB_APPLICATION:
      case ProjectType.REACT_APPLICATION:
      case ProjectType.NEXT_JS_APPLICATION:
      case ProjectType.VUE_APPLICATION:
      case ProjectType.ANGULAR_APPLICATION:
        return new WebAppAnalysisStrategy();
      
      case ProjectType.API_SERVICE:
      case ProjectType.MICROSERVICE:
        return new DefaultAnalysisStrategy();
      
      case ProjectType.MOBILE_APPLICATION:
        return new DefaultAnalysisStrategy();
      
      case ProjectType.PYTHON_PACKAGE:
      case ProjectType.PYTHON_DJANGO:
      case ProjectType.PYTHON_FLASK:
      case ProjectType.PYTHON_FASTAPI:
        return new DefaultAnalysisStrategy();
      
      case ProjectType.NODE_LIBRARY:
        return new DefaultAnalysisStrategy();
      
      default:
        return new DefaultAnalysisStrategy();
    }
  }
}
