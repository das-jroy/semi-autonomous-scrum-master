import { Repository } from './repository.model';

/**
 * Project Model
 * 
 * Represents the complete analysis result of a repository,
 * including project type, technology stack, and scrum recommendations
 */
export interface ProjectModel {
  repository: Repository;
  projectType: ProjectType;
  technologyStack: TechnologyStack;
  complexity: ProjectComplexity;
  currentState: ProjectCurrentState;
  recommendations: ScrumRecommendations;
  estimatedEffort: EffortEstimation;
  riskAssessment: RiskAssessment;
  estimatedDuration: number; // in days
  teamSize: number; // recommended team size
  mainFeatures: string[]; // key features of the project
  technicalRequirements: string[]; // technical requirements
  risks: string[]; // identified risks
  createdAt: Date;
  lastAnalyzed: Date;
}

/**
 * Project type classification
 */
export enum ProjectType {
  WEB_APPLICATION = 'web-application',
  API_SERVICE = 'api-service',
  MOBILE_APPLICATION = 'mobile-application',
  DESKTOP_APPLICATION = 'desktop-application',
  PYTHON_PACKAGE = 'python-package',
  PYTHON_DJANGO = 'python-django',
  PYTHON_FLASK = 'python-flask',
  PYTHON_FASTAPI = 'python-fastapi',
  NODE_LIBRARY = 'node-library',
  REACT_APPLICATION = 'react-application',
  NEXT_JS_APPLICATION = 'next-js-application',
  VUE_APPLICATION = 'vue-application',
  ANGULAR_APPLICATION = 'angular-application',
  MICROSERVICE = 'microservice',
  MONOLITH = 'monolith',
  UNKNOWN = 'unknown'
}

/**
 * Technology stack detected in the project
 */
export interface TechnologyStack {
  primaryLanguage: string;
  languages: Record<string, number>;
  frameworks: string[];
  databases: string[];
  cloudPlatforms: string[];
  cicdTools: string[];
  testingFrameworks: string[];
  buildTools: string[];
  packageManagers: string[];
  containerization: string[];
  infrastructure: string[];
}

/**
 * Project complexity assessment
 */
export interface ProjectComplexity {
  overall: ComplexityLevel;
  codebase: ComplexityLevel;
  architecture: ComplexityLevel;
  dependencies: ComplexityLevel;
  testing: ComplexityLevel;
  documentation: ComplexityLevel;
  factors: ComplexityFactor[];
}

export enum ComplexityLevel {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  VERY_HIGH = 'very-high'
}

export interface ComplexityFactor {
  factor: string;
  impact: ComplexityLevel;
  description: string;
}

/**
 * Current state of the project
 */
export interface ProjectCurrentState {
  hasActiveIssues: boolean;
  issueCount: number;
  hasActivePullRequests: boolean;
  pullRequestCount: number;
  hasRecentCommits: boolean;
  lastCommitDate: Date;
  hasDocumentation: boolean;
  documentationQuality: DocumentationQuality;
  hasTests: boolean;
  testCoverage?: number;
  hasCI: boolean;
  ciStatus?: CIStatus;
  codeQuality: CodeQuality;
}

export enum DocumentationQuality {
  EXCELLENT = 'excellent',
  GOOD = 'good',
  ADEQUATE = 'adequate',
  POOR = 'poor',
  MISSING = 'missing'
}

export enum CIStatus {
  PASSING = 'passing',
  FAILING = 'failing',
  UNKNOWN = 'unknown'
}

export interface CodeQuality {
  maintainability: number; // 0-100
  reliability: number; // 0-100
  security: number; // 0-100
  technicalDebt: number; // hours
  codeSmells: number;
  duplications: number;
  vulnerabilities: number;
  bugs: number;
}

/**
 * Scrum recommendations based on project analysis
 */
export interface ScrumRecommendations {
  recommendedSprintLength: number; // days
  recommendedTeamSize: number;
  recommendedVelocity: number; // story points per sprint
  suggestedEpics: Epic[];
  suggestedUserStories: UserStory[];
  suggestedTasks: Task[];
  riskMitigations: RiskMitigation[];
  improvementSuggestions: string[];
}

export interface Epic {
  title: string;
  description: string;
  priority: Priority;
  estimatedStoryPoints: number;
  estimatedSprints: number;
  dependencies: string[];
}

export interface UserStory {
  title: string;
  description: string;
  acceptanceCriteria: string[];
  priority: Priority;
  estimatedStoryPoints: number;
  epic?: string;
  labels: string[];
}

export interface Task {
  title: string;
  description: string;
  priority: Priority;
  estimatedHours: number;
  assigneeType: AssigneeType;
  prerequisites: string[];
  userStory?: string;
}

export enum Priority {
  CRITICAL = 'critical',
  HIGH = 'high',
  MEDIUM = 'medium',
  LOW = 'low'
}

export enum AssigneeType {
  SENIOR_DEVELOPER = 'senior-developer',
  JUNIOR_DEVELOPER = 'junior-developer',
  FRONTEND_DEVELOPER = 'frontend-developer',
  BACKEND_DEVELOPER = 'backend-developer',
  FULL_STACK_DEVELOPER = 'full-stack-developer',
  DEVOPS_ENGINEER = 'devops-engineer',
  QA_ENGINEER = 'qa-engineer',
  PRODUCT_OWNER = 'product-owner',
  SCRUM_MASTER = 'scrum-master'
}

/**
 * Effort estimation for the project
 */
export interface EffortEstimation {
  totalStoryPoints: number;
  totalDevelopmentHours: number;
  totalTestingHours: number;
  totalDocumentationHours: number;
  totalDeploymentHours: number;
  estimatedSprints: number;
  estimatedTeamSize: number;
  estimatedDuration: number; // weeks
  confidenceLevel: ConfidenceLevel;
}

export enum ConfidenceLevel {
  HIGH = 'high',
  MEDIUM = 'medium',
  LOW = 'low'
}

/**
 * Risk assessment for the project
 */
export interface RiskAssessment {
  overallRisk: RiskLevel;
  technicalRisks: Risk[];
  businessRisks: Risk[];
  teamRisks: Risk[];
  timelineRisks: Risk[];
  mitigationStrategies: RiskMitigation[];
}

export enum RiskLevel {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  CRITICAL = 'critical'
}

export interface Risk {
  id: string;
  category: RiskCategory;
  title: string;
  description: string;
  probability: number; // 0-100
  impact: RiskLevel;
  riskScore: number; // probability * impact
  identifiedDate: Date;
  status: RiskStatus;
}

export enum RiskCategory {
  TECHNICAL = 'technical',
  BUSINESS = 'business',
  TEAM = 'team',
  TIMELINE = 'timeline',
  EXTERNAL = 'external'
}

export enum RiskStatus {
  IDENTIFIED = 'identified',
  ANALYZING = 'analyzing',
  MITIGATING = 'mitigating',
  MONITORING = 'monitoring',
  RESOLVED = 'resolved'
}

export interface RiskMitigation {
  riskId: string;
  strategy: string;
  actions: string[];
  owner: string;
  targetDate: Date;
  status: MitigationStatus;
  effectiveness?: number; // 0-100
}

export enum MitigationStatus {
  PLANNED = 'planned',
  IN_PROGRESS = 'in-progress',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled'
}
