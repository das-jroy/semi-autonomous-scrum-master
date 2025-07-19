import { ScrumMasterFacade } from './patterns/facade/scrum-master.facade';

/**
 * Main Entry Point for Semi-Autonomous Scrum Master
 * 
 * Demonstrates the use of design patterns in a TypeScript implementation
 * that can be called from GitHub Actions workflows
 */

// CLI interface for GitHub Actions
async function cli() {
  /* eslint-disable no-console */
  const command = process.argv[2];
  const scrumMaster = new ScrumMasterFacade();
  
  switch (command) {
    case 'init': {
      const repoUrl = process.argv[3];
      if (!repoUrl) {
        console.error('Usage: npm start init <repo-url>');
        process.exit(1);
      }
      await scrumMaster.initializeProject(repoUrl);
      break;
    }
      
    case 'sprint': {
      const sprintNumber = parseInt(process.argv[3] || '1');
      await scrumMaster.generateSprint(sprintNumber);
      break;
    }
      
    case 'progress':
      await scrumMaster.updateProgress();
      break;
      
    default:
      console.log('Available commands:');
      console.log('  init <repo-url>  - Initialize project');
      console.log('  sprint <number>  - Generate sprint');
      console.log('  progress         - Update progress');
      process.exit(1);
  }
  /* eslint-enable no-console */
}

// Run CLI if called directly
if (require.main === module) {
  cli().catch(console.error);
}

export { ScrumMasterFacade };
export * from './patterns/facade/scrum-master.facade';
export * from './patterns/strategy/analysis-strategy.interface';
export * from './patterns/factory/analyzer.factory';
export * from './models/project.model';
export * from './models/repository.model';
