import { Repository } from '../../models/repository.model';
import { ProjectModel } from '../../models/project.model';

/**
 * Strategy Pattern: Analysis Strategy Interface
 * 
 * Defines the contract for different project analysis strategies.
 * Each strategy analyzes a repository and returns a project model.
 */
export interface AnalysisStrategy {
  /**
   * Analyzes a repository and returns a project model
   * @param repository - The repository to analyze
   * @returns Promise<ProjectModel> - The analyzed project model
   */
  analyze(repository: Repository): Promise<ProjectModel>;
  
  /**
   * Determines if this strategy can analyze the given repository
   * @param repository - The repository to check
   * @returns boolean - Whether this strategy can analyze the repository
   */
  canAnalyze(repository: Repository): boolean;
}
