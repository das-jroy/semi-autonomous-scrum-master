/**
 * Observer Pattern Implementation for Progress Monitoring
 * 
 * Replaces functionality from multiple shell scripts:
 * - progress-monitor.sh
 * - slack-notifications.sh
 * - dashboard-updates.sh
 * - health-monitoring.sh
 * - status-reporting.sh
 */

/* eslint-disable no-console, max-lines */

export interface ProgressEvent {
  type: 'project_created' | 'issue_created' | 'sprint_setup' | 'board_updated' | 'error' | 'completion' | 
        'progress' | 'project_setup_started' | 'repository_analysis_started' | 'repository_analysis_completed' |
        'project_creation_started' | 'issue_generation_started' | 'issues_created' | 'sprint_setup_started' |
        'board_configuration_started';
  data: unknown;
  timestamp: Date;
  phase: string;
  progress: number; // 0-100
  message: string;
}

/**
 * Observer Interface
 */
export interface ProgressObserver {
  update(event: ProgressEvent): Promise<void>;
  getName(): string;
  isEnabled(): boolean;
}

/**
 * Subject Interface
 */
export interface ProgressSubject {
  addObserver(observer: ProgressObserver): void;
  removeObserver(observer: ProgressObserver): void;
  notifyObservers(event: ProgressEvent): Promise<void>;
}

/**
 * Abstract Progress Subject
 */
export abstract class AbstractProgressSubject implements ProgressSubject {
  private observers: ProgressObserver[] = [];
  private eventHistory: ProgressEvent[] = [];

  addObserver(observer: ProgressObserver): void {
    if (!this.observers.includes(observer)) {
      this.observers.push(observer);
      console.log(`📡 Added observer: ${observer.getName()}`);
    }
  }

  removeObserver(observer: ProgressObserver): void {
    const index = this.observers.indexOf(observer);
    if (index > -1) {
      this.observers.splice(index, 1);
      console.log(`📡 Removed observer: ${observer.getName()}`);
    }
  }

  async notifyObservers(event: ProgressEvent): Promise<void> {
    this.eventHistory.push(event);
    
    // Keep only last 100 events
    if (this.eventHistory.length > 100) {
      this.eventHistory.shift();
    }

    console.log(`📢 Notifying ${this.observers.length} observers: ${event.message}`);
    
    // Notify all observers in parallel
    const notifications = this.observers
      .filter(observer => observer.isEnabled())
      .map(observer => this.notifyObserver(observer, event));
    
    await Promise.allSettled(notifications);
  }

  private async notifyObserver(observer: ProgressObserver, event: ProgressEvent): Promise<void> {
    try {
      await observer.update(event);
    } catch (error) {
      console.error(`❌ Observer ${observer.getName()} failed to process event:`, error);
    }
  }

  getEventHistory(): ProgressEvent[] {
    return [...this.eventHistory];
  }

  getLastEvent(): ProgressEvent | null {
    return this.eventHistory[this.eventHistory.length - 1] || null;
  }

  getObserverCount(): number {
    return this.observers.length;
  }

  /**
   * Advanced Observer Management Features
   */
  
  // Get observers by type
  getObserversByType<T extends ProgressObserver>(type: new (...args: unknown[]) => T): T[] {
    return this.observers.filter(observer => observer instanceof type) as T[];
  }
  
  // Get event statistics
  getEventStatistics(): {
    totalEvents: number;
    eventsByType: Record<string, number>;
    averageProgress: number;
    errorRate: number;
  } {
    const stats = {
      totalEvents: this.eventHistory.length,
      eventsByType: {} as Record<string, number>,
      averageProgress: 0,
      errorRate: 0
    };
    
    if (this.eventHistory.length === 0) return stats;
    
    // Count events by type
    for (const event of this.eventHistory) {
      stats.eventsByType[event.type] = (stats.eventsByType[event.type] || 0) + 1;
    }
    
    // Calculate average progress
    const totalProgress = this.eventHistory.reduce((sum, event) => sum + event.progress, 0);
    stats.averageProgress = totalProgress / this.eventHistory.length;
    
    // Calculate error rate
    const errorCount = stats.eventsByType['error'] || 0;
    stats.errorRate = (errorCount / this.eventHistory.length) * 100;
    
    return stats;
  }
  
  // Filter events by criteria
  getFilteredEvents(filter: {
    type?: string;
    phase?: string;
    minProgress?: number;
    maxProgress?: number;
    since?: Date;
  }): ProgressEvent[] {
    return this.eventHistory.filter(event => {
      if (filter.type && event.type !== filter.type) return false;
      if (filter.phase && event.phase !== filter.phase) return false;
      if (filter.minProgress !== undefined && event.progress < filter.minProgress) return false;
      if (filter.maxProgress !== undefined && event.progress > filter.maxProgress) return false;
      if (filter.since && event.timestamp < filter.since) return false;
      return true;
    });
  }
  
  // Enable/disable observers by name pattern
  setObserversEnabled(pattern: string | RegExp, enabled: boolean): void {
    this.observers.forEach(observer => {
      const name = observer.getName();
      const matches = pattern instanceof RegExp ? pattern.test(name) : name.includes(pattern);
      if (matches && 'setEnabled' in observer && typeof observer.setEnabled === 'function') {
        (observer as { setEnabled: (enabled: boolean) => void }).setEnabled(enabled);
      }
    });
  }
}

/**
 * Advanced Metrics Collector Observer
 * Provides detailed analytics and performance tracking
 */
export class MetricsCollector implements ProgressObserver {
  private enabled = true;
  private metrics = {
    totalEvents: 0,
    errorCount: 0,
    completedPhases: new Set<string>(),
    phaseCompletionTimes: new Map<string, number>(),
    phaseStartTimes: new Map<string, number>(),
    averageProgressPerPhase: new Map<string, number[]>(),
    performanceMetrics: {
      fastestPhase: '',
      slowestPhase: '',
      mostErrorPronePhase: '',
      overallEfficiency: 0
    }
  };

  async update(event: ProgressEvent): Promise<void> {
    this.metrics.totalEvents++;
    
    // Track errors
    if (event.type === 'error') {
      this.metrics.errorCount++;
    }
    
    // Track phase timing
    if (event.progress === 0 && !this.metrics.phaseStartTimes.has(event.phase)) {
      this.metrics.phaseStartTimes.set(event.phase, Date.now());
    }
    
    if (event.progress === 100 || event.type === 'completion') {
      this.metrics.completedPhases.add(event.phase);
      const startTime = this.metrics.phaseStartTimes.get(event.phase);
      if (startTime) {
        const duration = Date.now() - startTime;
        this.metrics.phaseCompletionTimes.set(event.phase, duration);
      }
    }
    
    // Track progress per phase
    if (!this.metrics.averageProgressPerPhase.has(event.phase)) {
      this.metrics.averageProgressPerPhase.set(event.phase, []);
    }
    this.metrics.averageProgressPerPhase.get(event.phase)!.push(event.progress);
    
    this.updatePerformanceMetrics();
  }

  private updatePerformanceMetrics(): void {
    // Find fastest and slowest phases
    let fastestTime = Infinity;
    let slowestTime = 0;
    let fastestPhase = '';
    let slowestPhase = '';
    
    for (const [phase, time] of this.metrics.phaseCompletionTimes) {
      if (time < fastestTime) {
        fastestTime = time;
        fastestPhase = phase;
      }
      if (time > slowestTime) {
        slowestTime = time;
        slowestPhase = phase;
      }
    }
    
    this.metrics.performanceMetrics.fastestPhase = fastestPhase;
    this.metrics.performanceMetrics.slowestPhase = slowestPhase;
    
    // Calculate overall efficiency (completion rate vs error rate)
    const completionRate = (this.metrics.completedPhases.size / Math.max(1, this.metrics.phaseStartTimes.size)) * 100;
    const errorRate = (this.metrics.errorCount / Math.max(1, this.metrics.totalEvents)) * 100;
    this.metrics.performanceMetrics.overallEfficiency = Math.max(0, completionRate - errorRate);
  }

  getName(): string {
    return 'MetricsCollector';
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }

  getMetrics() {
    return {
      ...this.metrics,
      performanceMetrics: { ...this.metrics.performanceMetrics }
    };
  }

  generateReport(): string {
    const report = [
      '📊 METRICS REPORT',
      '=================',
      `Total Events: ${this.metrics.totalEvents}`,
      `Error Count: ${this.metrics.errorCount}`,
      `Error Rate: ${((this.metrics.errorCount / Math.max(1, this.metrics.totalEvents)) * 100).toFixed(2)}%`,
      `Completed Phases: ${this.metrics.completedPhases.size}`,
      `Overall Efficiency: ${this.metrics.performanceMetrics.overallEfficiency.toFixed(2)}%`,
      '',
      '⚡ Performance:',
      `Fastest Phase: ${this.metrics.performanceMetrics.fastestPhase}`,
      `Slowest Phase: ${this.metrics.performanceMetrics.slowestPhase}`,
      '',
      '📈 Phase Details:'
    ];

    for (const [phase, progressArray] of this.metrics.averageProgressPerPhase) {
      const avgProgress = progressArray.reduce((a, b) => a + b, 0) / progressArray.length;
      const duration = this.metrics.phaseCompletionTimes.get(phase);
      report.push(
        `  ${phase}: ${avgProgress.toFixed(1)}% avg progress${duration ? ` (${duration}ms)` : ''}`
      );
    }

    return report.join('\n');
  }

  reset(): void {
    this.metrics = {
      totalEvents: 0,
      errorCount: 0,
      completedPhases: new Set<string>(),
      phaseCompletionTimes: new Map<string, number>(),
      phaseStartTimes: new Map<string, number>(),
      averageProgressPerPhase: new Map<string, number[]>(),
      performanceMetrics: {
        fastestPhase: '',
        slowestPhase: '',
        mostErrorPronePhase: '',
        overallEfficiency: 0
      }
    };
  }
}

/**
 * Generic Webhook Notifier Observer
 * Sends events to any webhook endpoint with customizable payloads
 */
export class WebhookNotifier implements ProgressObserver {
  private enabled = true;
  private successCount = 0;
  private failureCount = 0;

  constructor(
    private webhookUrl: string,
    private config: {
      headers?: Record<string, string>;
      timeout?: number;
      retries?: number;
      payloadTransformer?: (event: ProgressEvent) => unknown;
      eventFilter?: (event: ProgressEvent) => boolean;
    } = {}
  ) {}

  async update(event: ProgressEvent): Promise<void> {
    try {
      // Apply event filter if provided
      if (this.config.eventFilter && !this.config.eventFilter(event)) {
        return;
      }

      const payload = this.config.payloadTransformer 
        ? this.config.payloadTransformer(event)
        : this.createDefaultPayload(event);

      const maxRetries = this.config.retries || 1;
      let lastError: Error | null = null;

      for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          await this.sendWebhook(payload);
          this.successCount++;
          console.log(`🔗 Webhook sent successfully to ${this.webhookUrl} (attempt ${attempt})`);
          return;
        } catch (error) {
          lastError = error as Error;
          if (attempt < maxRetries) {
            const delay = Math.pow(2, attempt - 1) * 1000; // Exponential backoff
            await new Promise(resolve => setTimeout(resolve, delay));
          }
        }
      }

      throw lastError;
    } catch (error) {
      this.failureCount++;
      console.error(`❌ Webhook failed for ${this.webhookUrl}:`, error);
    }
  }

  private async sendWebhook(payload: unknown): Promise<void> {
    const controller = new AbortController();
    const timeout = this.config.timeout || 10000;
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    try {
      const response = await fetch(this.webhookUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Semi-Autonomous-Scrum-Master/1.0',
          ...this.config.headers
        },
        body: JSON.stringify(payload),
        signal: controller.signal
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
    } finally {
      clearTimeout(timeoutId);
    }
  }

  private createDefaultPayload(event: ProgressEvent): Record<string, unknown> {
    return {
      timestamp: event.timestamp.toISOString(),
      event: {
        type: event.type,
        phase: event.phase,
        progress: event.progress,
        message: event.message,
        data: event.data
      },
      metadata: {
        source: 'semi-autonomous-scrum-master',
        version: '1.0.0'
      }
    };
  }

  getName(): string {
    return `WebhookNotifier(${this.webhookUrl})`;
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }

  getStats(): { successCount: number; failureCount: number; successRate: number } {
    const total = this.successCount + this.failureCount;
    return {
      successCount: this.successCount,
      failureCount: this.failureCount,
      successRate: total > 0 ? (this.successCount / total) * 100 : 0
    };
  }

  reset(): void {
    this.successCount = 0;
    this.failureCount = 0;
  }
}

/**
 * Slack Notifier Observer
 * Replaces: slack-notifications.sh
 */
export class SlackNotifier implements ProgressObserver {
  private webhookUrl: string;
  private channel: string;
  private username: string;
  private enabled: boolean;

  constructor(webhookUrl: string, channel: string = '#scrum-updates', username: string = 'Scrum Master Bot') {
    this.webhookUrl = webhookUrl;
    this.channel = channel;
    this.username = username;
    this.enabled = !!webhookUrl;
  }

  async update(event: ProgressEvent): Promise<void> {
    if (!this.enabled) return;

    const message = this.formatSlackMessage(event);
    
    try {
      const response = await fetch(this.webhookUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          channel: this.channel,
          username: this.username,
          text: message.text,
          attachments: message.attachments
        })
      });

      if (!response.ok) {
        throw new Error(`Slack API error: ${response.status}`);
      }

      console.log(`📱 Slack notification sent: ${event.message}`);
    } catch (error) {
      console.error(`❌ Failed to send Slack notification:`, error);
    }
  }

  private formatSlackMessage(event: ProgressEvent): SlackMessage {
    const emoji = this.getEventEmoji(event.type);
    const color = this.getEventColor(event.type);
    
    return {
      text: `${emoji} ${event.message}`,
      attachments: [
        {
          color: color,
          fields: [
            {
              title: 'Phase',
              value: event.phase,
              short: true
            },
            {
              title: 'Progress',
              value: `${event.progress}%`,
              short: true
            },
            {
              title: 'Time',
              value: event.timestamp.toLocaleString(),
              short: true
            }
          ]
        }
      ]
    };
  }

  private getEventEmoji(type: string): string {
    const emojis: { [key: string]: string } = {
      'project_created': '🎯',
      'issue_created': '📋',
      'sprint_setup': '🏃',
      'board_updated': '📊',
      'error': '❌',
      'completion': '🎉'
    };
    return emojis[type] || '📢';
  }

  private getEventColor(type: string): string {
    const colors: { [key: string]: string } = {
      'project_created': 'good',
      'issue_created': 'good',
      'sprint_setup': 'good',
      'board_updated': 'good',
      'error': 'danger',
      'completion': 'good'
    };
    return colors[type] || 'warning';
  }

  getName(): string {
    return 'SlackNotifier';
  }

  isEnabled(): boolean {
    return this.enabled;
  }
}

/**
 * Dashboard Updater Observer
 * Replaces: dashboard-updates.sh, real-time-dashboard.sh
 */
export class DashboardUpdater implements ProgressObserver {
  private dashboardUrl: string;
  private apiKey: string;
  private enabled: boolean;

  constructor(dashboardUrl: string, apiKey: string) {
    this.dashboardUrl = dashboardUrl;
    this.apiKey = apiKey;
    this.enabled = !!dashboardUrl && !!apiKey;
  }

  async update(event: ProgressEvent): Promise<void> {
    if (!this.enabled) return;

    try {
      const dashboardData = this.formatDashboardData(event);
      
      const response = await fetch(`${this.dashboardUrl}/api/events`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`
        },
        body: JSON.stringify(dashboardData)
      });

      if (!response.ok) {
        throw new Error(`Dashboard API error: ${response.status}`);
      }

      console.log(`📊 Dashboard updated: ${event.message}`);
    } catch (error) {
      console.error(`❌ Failed to update dashboard:`, error);
    }
  }

  private formatDashboardData(event: ProgressEvent): DashboardEvent {
    return {
      id: `${Date.now()}-${Math.random()}`,
      type: event.type,
      phase: event.phase,
      progress: event.progress,
      message: event.message,
      timestamp: event.timestamp.toISOString(),
      data: event.data as Record<string, unknown>,
      metadata: {
        source: 'scrum-master-bot',
        version: '1.0.0'
      }
    };
  }

  getName(): string {
    return 'DashboardUpdater';
  }

  isEnabled(): boolean {
    return this.enabled;
  }
}

/**
 * File Logger Observer
 * Replaces: logging.sh, audit-trail.sh
 */
export class FileLogger implements ProgressObserver {
  private logFile: string;
  private enabled: boolean;

  constructor(logFile: string = './logs/scrum-master.log') {
    this.logFile = logFile;
    this.enabled = true;
  }

  async update(event: ProgressEvent): Promise<void> {
    if (!this.enabled) return;

    const logEntry = this.formatLogEntry(event);
    
    try {
      // In a real implementation, you'd use fs.appendFile
      console.log(`📝 [${event.timestamp.toISOString()}] ${logEntry}`);
    } catch (error) {
      console.error(`❌ Failed to write to log file:`, error);
    }
  }

  private formatLogEntry(event: ProgressEvent): string {
    return `[${event.type.toUpperCase()}] ${event.phase} - ${event.message} (${event.progress}%)`;
  }

  getName(): string {
    return 'FileLogger';
  }

  isEnabled(): boolean {
    return this.enabled;
  }
}

/**
 * Email Notifier Observer
 * Replaces: email-notifications.sh
 */
export class EmailNotifier implements ProgressObserver {
  private emailConfig: EmailConfig;
  private enabled: boolean;

  constructor(emailConfig: EmailConfig) {
    this.emailConfig = emailConfig;
    this.enabled = !!emailConfig.smtpHost && !!emailConfig.fromEmail;
  }

  async update(event: ProgressEvent): Promise<void> {
    if (!this.enabled) return;

    // Only send emails for important events
    if (!this.shouldSendEmail(event)) return;

    try {
      const emailData = this.formatEmailData(event);
      
      // In a real implementation, you'd use nodemailer or similar
      console.log(`📧 Email would be sent: ${emailData.subject}`);
    } catch (error) {
      console.error(`❌ Failed to send email:`, error);
    }
  }

  private shouldSendEmail(event: ProgressEvent): boolean {
    const importantEvents = ['project_created', 'error', 'completion'];
    return importantEvents.includes(event.type);
  }

  private formatEmailData(event: ProgressEvent): EmailData {
    return {
      to: this.emailConfig.recipients,
      subject: `Scrum Master: ${event.message}`,
      body: `
        <h2>Scrum Master Notification</h2>
        <p><strong>Phase:</strong> ${event.phase}</p>
        <p><strong>Progress:</strong> ${event.progress}%</p>
        <p><strong>Message:</strong> ${event.message}</p>
        <p><strong>Time:</strong> ${event.timestamp.toLocaleString()}</p>
        <p><strong>Data:</strong> ${JSON.stringify(event.data, null, 2)}</p>
      `
    };
  }

  getName(): string {
    return 'EmailNotifier';
  }

  isEnabled(): boolean {
    return this.enabled;
  }
}

/**
 * Health Monitor Observer
 * Replaces: health-monitoring.sh, alert-system.sh
 */
export class HealthMonitor implements ProgressObserver {
  private healthMetrics: HealthMetrics;
  private alertThresholds: AlertThresholds;
  private enabled: boolean;

  constructor(alertThresholds: AlertThresholds) {
    this.alertThresholds = alertThresholds;
    this.enabled = true;
    this.healthMetrics = {
      totalEvents: 0,
      errorEvents: 0,
      lastErrorTime: null,
      averageProgress: 0,
      errorRate: 0
    };
  }

  async update(event: ProgressEvent): Promise<void> {
    if (!this.enabled) return;

    this.updateMetrics(event);
    await this.checkAlerts(event);
  }

  private updateMetrics(event: ProgressEvent): void {
    this.healthMetrics.totalEvents++;
    
    if (event.type === 'error') {
      this.healthMetrics.errorEvents++;
      this.healthMetrics.lastErrorTime = event.timestamp;
    }
    
    this.healthMetrics.errorRate = (this.healthMetrics.errorEvents / this.healthMetrics.totalEvents) * 100;
    
    // Update average progress (simple moving average)
    this.healthMetrics.averageProgress = 
      (this.healthMetrics.averageProgress * (this.healthMetrics.totalEvents - 1) + event.progress) / 
      this.healthMetrics.totalEvents;
  }

  private async checkAlerts(event: ProgressEvent): Promise<void> {
    if (this.healthMetrics.errorRate > this.alertThresholds.maxErrorRate) {
      await this.triggerAlert('high_error_rate', `Error rate ${this.healthMetrics.errorRate.toFixed(2)}% exceeds threshold`);
    }
    
    if (event.type === 'error' && this.alertThresholds.alertOnError) {
      await this.triggerAlert('error_occurred', event.message);
    }
  }

  private async triggerAlert(alertType: string, message: string): Promise<void> {
    console.log(`🚨 ALERT [${alertType}]: ${message}`);
    
    // In a real implementation, you might integrate with PagerDuty, etc.
    // For now, just log and potentially send to other systems
  }

  getHealthMetrics(): HealthMetrics {
    return { ...this.healthMetrics };
  }

  getName(): string {
    return 'HealthMonitor';
  }

  isEnabled(): boolean {
    return this.enabled;
  }
}

// Supporting interfaces

interface SlackMessage {
  text: string;
  attachments: {
    color: string;
    fields: {
      title: string;
      value: string;
      short: boolean;
    }[];
  }[];
}

interface DashboardEvent {
  id: string;
  type: string;
  phase: string;
  progress: number;
  message: string;
  timestamp: string;
  data: Record<string, unknown>;
  metadata: {
    source: string;
    version: string;
  };
}

interface EmailConfig {
  smtpHost: string;
  smtpPort: number;
  fromEmail: string;
  recipients: string[];
  username?: string;
  password?: string;
}

interface EmailData {
  to: string[];
  subject: string;
  body: string;
}

interface HealthMetrics {
  totalEvents: number;
  errorEvents: number;
  lastErrorTime: Date | null;
  averageProgress: number;
  errorRate: number;
}

interface AlertThresholds {
  maxErrorRate: number; // percentage
  alertOnError: boolean;
  maxExecutionTime?: number; // minutes
}
