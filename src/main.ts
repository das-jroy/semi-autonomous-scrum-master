#!/usr/bin/env node

import { ScrumMasterEngine } from './core/scrum-master-engine';
import { 
  SlackNotifier, 
  DashboardUpdater, 
  FileLogger, 
  EmailNotifier, 
  HealthMonitor 
} from './patterns/observer/progress-observers';
import { config } from 'dotenv';
import { program } from 'commander';

// Load environment variables
config();

interface SetupOptions {
  repository: string;
  organization: string;
  title?: string;
  description?: string;
  slackWebhook?: string;
  email?: string;
}

/**
 * Main CLI Entry Point
 * 
 * Replaces functionality from:
 * - main.sh
 * - setup-master.sh
 * - complete-automation.sh
 * - health-monitor.sh
 * - status-dashboard.sh
 */

/* eslint-disable no-console */

// Validate required environment variables
function validateEnvironment(): void {
  const required = ['GITHUB_TOKEN'];
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    console.error('❌ Missing required environment variables:');
    missing.forEach(key => console.error(`  - ${key}`));
    console.error('\nPlease set these environment variables and try again.');
    process.exit(1);
  }
}

// Setup CLI commands
function setupCommands(): void {
  program
    .name('scrum-master')
    .description('Semi-Autonomous Scrum Master CLI')
    .version('1.0.0');

  // Setup project command
  program
    .command('setup')
    .description('Setup a new GitHub project with scrum methodology')
    .requiredOption('-r, --repository <url>', 'GitHub repository URL')
    .requiredOption('-o, --organization <id>', 'GitHub organization ID')
    .option('-t, --title <title>', 'Project title (defaults to repository name)')
    .option('-d, --description <description>', 'Project description')
    .option('--slack-webhook <url>', 'Slack webhook URL for notifications')
    .option('--email <addresses>', 'Email addresses for notifications (comma-separated)')
    .action(async (options) => {
      await runProjectSetup(options);
    });

  // Health check command
  program
    .command('health')
    .description('Check system health and status')
    .action(async () => {
      await runHealthCheck();
    });

  // Status command
  program
    .command('status')
    .description('Show current processing status')
    .action(async () => {
      await runStatusCheck();
    });

  // Monitor command
  program
    .command('monitor')
    .description('Start continuous monitoring mode')
    .option('--interval <seconds>', 'Check interval in seconds', '60')
    .action(async (options) => {
      await runMonitoringMode(parseInt(options.interval));
    });

  // Interactive mode command
  program
    .command('interactive')
    .description('Start interactive mode for project setup')
    .action(async () => {
      await runInteractiveMode();
    });

  program.parse();
}

// Project setup workflow
async function runProjectSetup(options: SetupOptions): Promise<void> {
  validateEnvironment();
  
  console.log('🚀 Starting Semi-Autonomous Scrum Master...');
  console.log('==========================================');
  
  // Initialize engine
  const engine = new ScrumMasterEngine(process.env.GITHUB_TOKEN!);
  
  // Setup observers
  setupObservers(engine, options);
  
  // Extract repository info
  const repositoryUrl = options.repository;
  const organizationId = options.organization;
  const projectTitle = options.title || extractRepoName(repositoryUrl);
  const projectDescription = options.description || `Scrum project for ${projectTitle}`;
  
  try {
    console.log(`📋 Project: ${projectTitle}`);
    console.log(`🔗 Repository: ${repositoryUrl}`);
    console.log(`🏢 Organization: ${organizationId}`);
    console.log('');
    
    // Run project setup
    const result = await engine.setupProject(
      repositoryUrl,
      projectTitle,
      projectDescription,
      organizationId
    );
    
    if (result.success) {
      console.log('✅ Project setup completed successfully!');
      console.log(`🔗 Project URL: ${result.projectUrl}`);
      console.log(`📊 Issues Created: ${result.issuesCreated}`);
      console.log(`🏃 Sprint Configured: ${result.sprintConfigured ? 'Yes' : 'No'}`);
    } else {
      console.error('❌ Project setup failed:');
      console.error(result.error);
      process.exit(1);
    }
    
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error('❌ Fatal error during project setup:');
    console.error(errorMessage);
    process.exit(1);
  }
}

// Health check
async function runHealthCheck(): Promise<void> {
  validateEnvironment();
  
  console.log('🔍 System Health Check');
  console.log('=====================');
  
  const engine = new ScrumMasterEngine(process.env.GITHUB_TOKEN!);
  const health = await engine.healthCheck();
  
  console.log(`Overall Health: ${health.overall ? '✅ Healthy' : '❌ Unhealthy'}`);
  console.log(`Command Invoker: ${health.commandInvoker.isHealthy ? '✅ Healthy' : '❌ Unhealthy'}`);
  console.log(`Recent Events: ${health.recentEvents}`);
  console.log(`Error Events: ${health.errorEvents}`);
  console.log(`Currently Processing: ${health.isProcessing ? 'Yes' : 'No'}`);
  console.log(`Last Activity: ${health.lastActivity ? health.lastActivity.toISOString() : 'None'}`);
  
  if (!health.overall) {
    console.log('\n⚠️  Issues detected:');
    if (!health.commandInvoker.isHealthy) {
      console.log('  - Command invoker is unhealthy');
    }
    if (health.errorEvents > 0) {
      console.log(`  - ${health.errorEvents} error events in recent history`);
    }
  }
}

// Status check
async function runStatusCheck(): Promise<void> {
  validateEnvironment();
  
  console.log('📊 Processing Status');
  console.log('===================');
  
  const engine = new ScrumMasterEngine(process.env.GITHUB_TOKEN!);
  const status = engine.getProcessingStatus();
  
  console.log(`Processing: ${status.isProcessing ? '🔄 Active' : '⏸️  Idle'}`);
  console.log(`Current Repository: ${status.currentRepository || 'None'}`);
  console.log(`Current Project: ${status.currentProject || 'None'}`);
  console.log(`Active Observers: ${status.totalObservers}`);
  
  if (status.lastEvent) {
    console.log(`Last Event: ${status.lastEvent.type} at ${status.lastEvent.timestamp.toISOString()}`);
    console.log(`Message: ${status.lastEvent.message}`);
  }
}

// Monitoring mode
async function runMonitoringMode(interval: number): Promise<void> {
  validateEnvironment();
  
  console.log('🔄 Starting Monitoring Mode');
  console.log(`Check Interval: ${interval} seconds`);
  console.log('Press Ctrl+C to stop');
  console.log('========================');
  
  const engine = new ScrumMasterEngine(process.env.GITHUB_TOKEN!);
  
  // Setup monitoring observer
  const monitor = new HealthMonitor({
    maxErrorRate: 10,
    alertOnError: true,
    maxExecutionTime: 60
  });
  engine.addObserver(monitor);
  
  // Periodic health checks
  setInterval(async () => {
    try {
      const health = await engine.healthCheck();
      const timestamp = new Date().toISOString();
      
      if (health.overall) {
        console.log(`[${timestamp}] ✅ System healthy`);
      } else {
        console.log(`[${timestamp}] ❌ System issues detected`);
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error(`[${new Date().toISOString()}] ❌ Health check failed: ${errorMessage}`);
    }
  }, interval * 1000);
}

// Interactive mode
async function runInteractiveMode(): Promise<void> {
  validateEnvironment();
  
  console.log('🎯 Interactive Project Setup');
  console.log('============================');
  
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  
  const question = (prompt: string): Promise<string> => {
    return new Promise((resolve) => {
      rl.question(prompt, resolve);
    });
  };
  
  try {
    // Gather project information
    const repositoryUrl = await question('Enter GitHub repository URL: ');
    const organizationId = await question('Enter GitHub organization ID: ');
    const projectTitle = await question('Enter project title (or press Enter for default): ') || extractRepoName(repositoryUrl);
    const projectDescription = await question('Enter project description (optional): ') || `Scrum project for ${projectTitle}`;
    
    // Optional notification settings
    const slackWebhook = await question('Enter Slack webhook URL (optional): ');
    const emailAddresses = await question('Enter email addresses for notifications (comma-separated, optional): ');
    
    rl.close();
    
    // Run setup
    const options = {
      repository: repositoryUrl,
      organization: organizationId,
      title: projectTitle,
      description: projectDescription,
      slackWebhook: slackWebhook || undefined,
      email: emailAddresses || undefined
    };
    
    await runProjectSetup(options);
    
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error('❌ Interactive setup failed:', errorMessage);
    rl.close();
    process.exit(1);
  }
}

// Setup observers based on options
function setupObservers(engine: ScrumMasterEngine, options: SetupOptions): void {
  // Always add file logger
  const fileLogger = new FileLogger('./logs/scrum-master.log');
  engine.addObserver(fileLogger);
  
  // Add Slack notifier if webhook provided
  if (options.slackWebhook) {
    const slackNotifier = new SlackNotifier(options.slackWebhook);
    engine.addObserver(slackNotifier);
  }
  
  // Add email notifier if addresses provided
  if (options.email) {
    const emailAddresses = options.email.split(',').map((email: string) => email.trim());
    const emailConfig = {
      smtpHost: 'smtp.example.com',
      smtpPort: 587,
      fromEmail: 'scrum@example.com',
      recipients: emailAddresses,
      username: 'scrum@example.com',
      password: 'password123'
    };
    const emailNotifier = new EmailNotifier(emailConfig);
    engine.addObserver(emailNotifier);
  }
  
  // Add dashboard updater
  const dashboardUpdater = new DashboardUpdater('./dashboard', 'default-api-key');
  engine.addObserver(dashboardUpdater);
  
  // Add health monitor
  const healthMonitor = new HealthMonitor({
    maxErrorRate: 10,
    alertOnError: true,
    maxExecutionTime: 60
  });
  engine.addObserver(healthMonitor);
}

// Helper functions
function extractRepoName(url: string): string {
  const match = url.match(/github\.com\/[^/]+\/([^/]+)/);
  return match ? match[1] : 'unknown-project';
}

// Error handling
process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n👋 Shutting down gracefully...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n👋 Shutting down gracefully...');
  process.exit(0);
});

// Run CLI if called directly
if (require.main === module) {
  setupCommands();
}
