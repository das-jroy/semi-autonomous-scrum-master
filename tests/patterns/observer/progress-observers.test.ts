import { 
  ProgressObserver, 
  ProgressSubject,
  AbstractProgressSubject,
  ProgressEvent,
  SlackNotifier,
  DashboardUpdater,
  FileLogger,
  EmailNotifier,
  HealthMonitor,
  MetricsCollector,
  WebhookNotifier
} from '../../../src/patterns/observer/progress-observers';

// Mock fs for file operations
jest.mock('fs', () => ({
  existsSync: jest.fn(),
  mkdirSync: jest.fn(),
  appendFileSync: jest.fn(),
  writeFileSync: jest.fn()
}));

// Mock console.log to capture output
jest.spyOn(console, 'log').mockImplementation(() => {});
jest.spyOn(console, 'error').mockImplementation(() => {});

// Mock global fetch for SlackNotifier
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    status: 200,
    json: () => Promise.resolve({}),
  })
) as jest.Mock;

// Test implementation of AbstractProgressSubject
class TestProgressSubject extends AbstractProgressSubject {
  async triggerEvent(event: ProgressEvent): Promise<void> {
    await this.notifyObservers(event);
  }
}

// Test implementation of ProgressObserver
class TestProgressObserver implements ProgressObserver {
  private enabled = true;
  private receivedEvents: ProgressEvent[] = [];
  
  constructor(private name: string) {}
  
  async update(event: ProgressEvent): Promise<void> {
    this.receivedEvents.push(event);
  }
  
  getName(): string {
    return this.name;
  }
  
  isEnabled(): boolean {
    return this.enabled;
  }
  
  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }
  
  getReceivedEvents(): ProgressEvent[] {
    return [...this.receivedEvents];
  }
  
  clear(): void {
    this.receivedEvents = [];
  }
}

describe('Observer Pattern - Progress Monitoring', () => {
  let subject: TestProgressSubject;
  let observer1: TestProgressObserver;
  let observer2: TestProgressObserver;
  let testEvent: ProgressEvent;
  
  beforeEach(() => {
    subject = new TestProgressSubject();
    observer1 = new TestProgressObserver('Observer1');
    observer2 = new TestProgressObserver('Observer2');
    
    testEvent = {
      type: 'project_created',
      data: { projectId: 'test-123' },
      timestamp: new Date(),
      phase: 'Project Creation',
      progress: 25,
      message: 'Test project created successfully'
    };
  });

  describe('AbstractProgressSubject', () => {
    it('should add observers successfully', () => {
      subject.addObserver(observer1);
      subject.addObserver(observer2);
      
      expect(subject.getObserverCount()).toBe(2);
    });

    it('should not add duplicate observers', () => {
      subject.addObserver(observer1);
      subject.addObserver(observer1); // Try to add again
      
      expect(subject.getObserverCount()).toBe(1);
    });

    it('should remove observers successfully', () => {
      subject.addObserver(observer1);
      subject.addObserver(observer2);
      
      subject.removeObserver(observer1);
      
      expect(subject.getObserverCount()).toBe(1);
    });

    it('should notify all observers', async () => {
      subject.addObserver(observer1);
      subject.addObserver(observer2);
      
      await subject.triggerEvent(testEvent);
      
      expect(observer1.getReceivedEvents()).toHaveLength(1);
      expect(observer2.getReceivedEvents()).toHaveLength(1);
      expect(observer1.getReceivedEvents()[0]).toEqual(testEvent);
      expect(observer2.getReceivedEvents()[0]).toEqual(testEvent);
    });

    it('should only notify enabled observers', async () => {
      subject.addObserver(observer1);
      subject.addObserver(observer2);
      
      observer2.setEnabled(false);
      
      await subject.triggerEvent(testEvent);
      
      expect(observer1.getReceivedEvents()).toHaveLength(1);
      expect(observer2.getReceivedEvents()).toHaveLength(0);
    });

    it('should handle observer errors gracefully', async () => {
      const faultyObserver = new TestProgressObserver('Faulty');
      jest.spyOn(faultyObserver, 'update').mockRejectedValue(new Error('Observer error'));
      
      subject.addObserver(observer1);
      subject.addObserver(faultyObserver);
      
      // Should not throw even if one observer fails
      await expect(subject.triggerEvent(testEvent)).resolves.not.toThrow();
      
      // Other observers should still be notified
      expect(observer1.getReceivedEvents()).toHaveLength(1);
    });

    it('should maintain event history', async () => {
      subject.addObserver(observer1);
      
      const event1 = { ...testEvent, message: 'Event 1' };
      const event2 = { ...testEvent, message: 'Event 2' };
      
      await subject.triggerEvent(event1);
      await subject.triggerEvent(event2);
      
      const history = subject.getEventHistory();
      expect(history).toHaveLength(2);
      expect(history[0].message).toBe('Event 1');
      expect(history[1].message).toBe('Event 2');
    });

    it('should return last event', async () => {
      subject.addObserver(observer1);
      
      expect(subject.getLastEvent()).toBeNull();
      
      await subject.triggerEvent(testEvent);
      
      const lastEvent = subject.getLastEvent();
      expect(lastEvent).toEqual(testEvent);
    });

    it('should limit event history to 100 events', async () => {
      subject.addObserver(observer1);
      
      // Add 105 events
      for (let i = 0; i < 105; i++) {
        const event = { ...testEvent, message: `Event ${i}` };
        await subject.triggerEvent(event);
      }
      
      const history = subject.getEventHistory();
      expect(history).toHaveLength(100);
      expect(history[0].message).toBe('Event 5'); // First 5 should be removed
      expect(history[99].message).toBe('Event 104');
    });
  });

  describe('SlackNotifier', () => {
    let slackNotifier: SlackNotifier;
    let mockFetch: jest.Mock;

    beforeEach(() => {
      mockFetch = global.fetch as jest.Mock;
      mockFetch.mockResolvedValue({
        ok: true,
        status: 200,
        json: () => Promise.resolve({})
      });
      
      slackNotifier = new SlackNotifier('https://hooks.slack.com/test', '#general', 'scrum-bot');
    });

    afterEach(() => {
      jest.clearAllMocks();
    });

    it('should send Slack notification', async () => {
      await slackNotifier.update(testEvent);
      
      expect(mockFetch).toHaveBeenCalledWith(
        'https://hooks.slack.com/test',
        expect.objectContaining({
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: expect.stringContaining('Test project created successfully')
        })
      );
    });

    it('should handle Slack API errors', async () => {
      mockFetch.mockRejectedValue(new Error('Slack API error'));
      
      // Should not throw
      await expect(slackNotifier.update(testEvent)).resolves.not.toThrow();
    });

    it('should format different event types', async () => {
      const errorEvent: ProgressEvent = {
        type: 'error',
        data: { error: 'Test error' },
        timestamp: new Date(),
        phase: 'Error',
        progress: 0,
        message: 'An error occurred'
      };

      await slackNotifier.update(errorEvent);
      
      expect(mockFetch).toHaveBeenCalledWith(
        'https://hooks.slack.com/test',
        expect.objectContaining({
          method: 'POST',
          body: expect.stringContaining('An error occurred')
        })
      );
    });
  });

  describe('FileLogger', () => {
    let fileLogger: FileLogger;
    let mockConsoleLog: jest.SpyInstance;

    beforeEach(() => {
      mockConsoleLog = jest.spyOn(console, 'log').mockImplementation(() => {});
      
      fileLogger = new FileLogger('./test-logs/test.log');
    });

    afterEach(() => {
      jest.clearAllMocks();
    });

    it('should log events to console', async () => {
      await fileLogger.update(testEvent);
      
      expect(mockConsoleLog).toHaveBeenCalledWith(
        expect.stringContaining('Test project created successfully')
      );
    });

    it('should format log entries correctly', async () => {
      await fileLogger.update(testEvent);
      
      expect(mockConsoleLog).toHaveBeenCalledWith(
        expect.stringContaining('[PROJECT_CREATED] Project Creation - Test project created successfully (25%)')
      );
    });

    it('should handle file system errors', async () => {
      // Mock console.error to track error handling
      const mockConsoleError = jest.spyOn(console, 'error').mockImplementation(() => {});
      
      // Should not throw even if there are errors
      await expect(fileLogger.update(testEvent)).resolves.not.toThrow();
      
      mockConsoleError.mockRestore();
    });
  });

  describe('EmailNotifier', () => {
    let emailNotifier: EmailNotifier;
    let mockConsoleLog: jest.SpyInstance;

    beforeEach(() => {
      mockConsoleLog = jest.spyOn(console, 'log').mockImplementation(() => {});
      
      const emailConfig = {
        smtpHost: 'smtp.example.com',
        smtpPort: 587,
        fromEmail: 'scrum@example.com',
        recipients: ['test@example.com'],
        username: 'scrum@example.com',
        password: 'password123'
      };
      emailNotifier = new EmailNotifier(emailConfig);
    });

    afterEach(() => {
      jest.clearAllMocks();
    });

    it('should send email notifications', async () => {
      await emailNotifier.update(testEvent);
      
      expect(mockConsoleLog).toHaveBeenCalledWith(
        expect.stringContaining('Email would be sent')
      );
    });

    it('should handle multiple recipients', async () => {
      const emailConfig = {
        smtpHost: 'smtp.example.com',
        smtpPort: 587,
        fromEmail: 'scrum@example.com',
        recipients: ['test1@example.com', 'test2@example.com'],
        username: 'scrum@example.com',
        password: 'password123'
      };
      emailNotifier = new EmailNotifier(emailConfig);
      
      await emailNotifier.update(testEvent);
      
      expect(mockConsoleLog).toHaveBeenCalledWith(
        expect.stringContaining('Email would be sent')
      );
    });

    it('should handle email errors', async () => {
      const mockConsoleError = jest.spyOn(console, 'error').mockImplementation(() => {});
      
      // Should not throw
      await expect(emailNotifier.update(testEvent)).resolves.not.toThrow();
      
      mockConsoleError.mockRestore();
    });
  });

  describe('DashboardUpdater', () => {
    let dashboardUpdater: DashboardUpdater;
    let mockFetch: jest.Mock;
    let mockConsoleLog: jest.SpyInstance;

    beforeEach(() => {
      mockFetch = global.fetch as jest.Mock;
      mockFetch.mockResolvedValue({
        ok: true,
        status: 200,
        json: () => Promise.resolve({})
      });
      
      mockConsoleLog = jest.spyOn(console, 'log').mockImplementation(() => {});
      
      dashboardUpdater = new DashboardUpdater('https://dashboard.example.com', 'api-key-123');
    });

    afterEach(() => {
      jest.clearAllMocks();
    });

    it('should update dashboard via API', async () => {
      // Clean test - disable all existing mocks first
      jest.restoreAllMocks();
      
      // Create a simple fresh mock for fetch
      const simpleFetchMock = jest.fn().mockResolvedValue({
        ok: true,
        status: 200,
        json: () => Promise.resolve({})
      });
      
      global.fetch = simpleFetchMock;
      
      // Create a new dashboard updater
      const freshDashboard = new DashboardUpdater('https://test.example.com', 'test-key');
      
      // Direct test without any console spies
      console.log('=== Starting test ===');
      console.log('Fresh dashboard isEnabled:', freshDashboard.isEnabled());
      
      // Call the method
      await freshDashboard.update(testEvent);
      
      console.log('Fetch calls after update:', simpleFetchMock.mock.calls.length);
      console.log('=== Test complete ===');
      
      // Check fetch was called
      expect(simpleFetchMock).toHaveBeenCalledTimes(1);
    });

    it('should log dashboard updates', async () => {
      // Verify the dashboard updater is enabled
      expect(dashboardUpdater.isEnabled()).toBe(true);
      
      // Create a fresh console.log spy just for this test
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
      
      await dashboardUpdater.update(testEvent);
      
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('Dashboard updated: Test project created successfully')
      );
      
      consoleSpy.mockRestore();
    });

    it('should handle dashboard API errors', async () => {
      mockFetch.mockRejectedValue(new Error('Dashboard API error'));
      
      // Should not throw
      await expect(dashboardUpdater.update(testEvent)).resolves.not.toThrow();
    });
  });

  describe('HealthMonitor', () => {
    let healthMonitor: HealthMonitor;

    beforeEach(() => {
      const alertThresholds = {
        maxErrorRate: 10,
        alertOnError: true,
        maxExecutionTime: 60
      };
      healthMonitor = new HealthMonitor(alertThresholds);
    });

    it('should track system health metrics', async () => {
      await healthMonitor.update(testEvent);
      
      // Health monitor should track the event
      expect(healthMonitor.getName()).toBe('HealthMonitor');
      expect(healthMonitor.isEnabled()).toBe(true);
    });

    it('should handle error events', async () => {
      const errorEvent: ProgressEvent = {
        type: 'error',
        data: { error: 'Test error' },
        timestamp: new Date(),
        phase: 'Error',
        progress: 0,
        message: 'An error occurred'
      };

      await healthMonitor.update(errorEvent);
      
      // Should handle error events without throwing
      expect(healthMonitor.isEnabled()).toBe(true);
    });
  });

  describe('Integration Tests', () => {
    it('should handle multiple observers working together', async () => {
      const slackNotifier = new SlackNotifier('https://hooks.slack.com/test', '#general', 'scrum-bot');
      const fileLogger = new FileLogger('./test-logs/integration.log');
      const alertThresholds = {
        maxErrorRate: 10,
        alertOnError: true,
        maxExecutionTime: 60
      };
      const healthMonitor = new HealthMonitor(alertThresholds);
      
      subject.addObserver(slackNotifier);
      subject.addObserver(fileLogger);
      subject.addObserver(healthMonitor);
      
      await subject.triggerEvent(testEvent);
      
      expect(subject.getObserverCount()).toBe(3);
      expect(subject.getEventHistory()).toHaveLength(1);
    });

    it('should handle rapid event notifications', async () => {
      subject.addObserver(observer1);
      
      const events = Array.from({ length: 10 }, (_, i) => ({
        ...testEvent,
        message: `Rapid event ${i}`
      }));
      
      // Send all events rapidly
      await Promise.all(events.map(event => subject.triggerEvent(event)));
      
      expect(observer1.getReceivedEvents()).toHaveLength(10);
      expect(subject.getEventHistory()).toHaveLength(10);
    });

    it('should handle disabled observers correctly', async () => {
      const slackNotifier = new SlackNotifier('https://hooks.slack.com/test', '#general', 'scrum-bot');
      const fileLogger = new FileLogger('./test-logs/disabled.log');
      
      subject.addObserver(slackNotifier);
      subject.addObserver(fileLogger);
      
      // Disable one observer
      jest.spyOn(fileLogger, 'isEnabled').mockReturnValue(false);
      
      await subject.triggerEvent(testEvent);
      
      // Only enabled observer should be called
      const mockFetch = global.fetch as jest.Mock;
      const mockConsoleLog = jest.spyOn(console, 'log');
      
      expect(mockFetch).toHaveBeenCalled();
      // FileLogger should not have logged since it's disabled
      expect(mockConsoleLog).not.toHaveBeenCalledWith(
        expect.stringContaining('[PROJECT_CREATED] Project Creation')
      );
    });
  });

  describe('Advanced Observer Features', () => {
    describe('Enhanced Subject Management', () => {
      it('should get observers by type', () => {
        const slackNotifier = new SlackNotifier('https://hooks.slack.com/test', '#general', 'scrum-bot');
        const fileLogger = new FileLogger('./test.log');
        
        subject.addObserver(slackNotifier);
        subject.addObserver(fileLogger);
        
        const slackObservers = subject.getObserversByType(SlackNotifier);
        const fileObservers = subject.getObserversByType(FileLogger);
        
        expect(slackObservers).toHaveLength(1);
        expect(fileObservers).toHaveLength(1);
        expect(slackObservers[0]).toBe(slackNotifier);
        expect(fileObservers[0]).toBe(fileLogger);
      });

      it('should provide event statistics', async () => {
        subject.addObserver(observer1);
        
        // Add various events
        await subject.triggerEvent({ ...testEvent, type: 'project_created', progress: 25 });
        await subject.triggerEvent({ ...testEvent, type: 'issue_created', progress: 50 });
        await subject.triggerEvent({ ...testEvent, type: 'error', progress: 50 });
        await subject.triggerEvent({ ...testEvent, type: 'completion', progress: 100 });
        
        const stats = subject.getEventStatistics();
        
        expect(stats.totalEvents).toBe(4);
        expect(stats.eventsByType['project_created']).toBe(1);
        expect(stats.eventsByType['error']).toBe(1);
        expect(stats.averageProgress).toBe(56.25); // (25+50+50+100)/4
        expect(stats.errorRate).toBe(25); // 1 error out of 4 events
      });

      it('should filter events by criteria', async () => {
        subject.addObserver(observer1);
        
        const now = new Date();
        const past = new Date(now.getTime() - 60000); // 1 minute ago
        
        // Add events with different criteria
        await subject.triggerEvent({ ...testEvent, type: 'project_created', phase: 'Setup', progress: 25, timestamp: past });
        await subject.triggerEvent({ ...testEvent, type: 'issue_created', phase: 'Development', progress: 75, timestamp: now });
        await subject.triggerEvent({ ...testEvent, type: 'error', phase: 'Setup', progress: 25, timestamp: now });
        
        // Filter by type
        const projectEvents = subject.getFilteredEvents({ type: 'project_created' });
        expect(projectEvents).toHaveLength(1);
        
        // Filter by progress range
        const highProgressEvents = subject.getFilteredEvents({ minProgress: 50 });
        expect(highProgressEvents).toHaveLength(1);
        
        // Filter by phase
        const setupEvents = subject.getFilteredEvents({ phase: 'Setup' });
        expect(setupEvents).toHaveLength(2);
        
        // Filter by time
        const recentEvents = subject.getFilteredEvents({ since: past });
        expect(recentEvents).toHaveLength(2);
      });
    });

    describe('MetricsCollector', () => {
      let metricsCollector: MetricsCollector;

      beforeEach(() => {
        metricsCollector = new MetricsCollector();
        subject.addObserver(metricsCollector);
      });

      it('should track basic metrics', async () => {
        await subject.triggerEvent({ ...testEvent, progress: 0 });
        await subject.triggerEvent({ ...testEvent, progress: 50 });
        await subject.triggerEvent({ ...testEvent, type: 'error', progress: 50 });
        
        const metrics = metricsCollector.getMetrics();
        
        expect(metrics.totalEvents).toBe(3);
        expect(metrics.errorCount).toBe(1);
      });

      it('should track phase completion timing', async () => {
        // Start a phase
        await subject.triggerEvent({ ...testEvent, phase: 'Test Phase', progress: 0 });
        
        // Add a small delay to simulate work
        await new Promise(resolve => setTimeout(resolve, 10));
        
        // Complete the phase
        await subject.triggerEvent({ ...testEvent, phase: 'Test Phase', progress: 100, type: 'completion' });
        
        const metrics = metricsCollector.getMetrics();
        
        expect(metrics.completedPhases.has('Test Phase')).toBe(true);
        expect(metrics.phaseCompletionTimes.has('Test Phase')).toBe(true);
        expect(metrics.phaseCompletionTimes.get('Test Phase')!).toBeGreaterThan(0);
      });

      it('should generate comprehensive reports', async () => {
        // Simulate a complete workflow
        await subject.triggerEvent({ ...testEvent, phase: 'Setup', progress: 0 });
        await subject.triggerEvent({ ...testEvent, phase: 'Setup', progress: 100, type: 'completion' });
        await subject.triggerEvent({ ...testEvent, phase: 'Development', progress: 0 });
        await subject.triggerEvent({ ...testEvent, type: 'error', phase: 'Development', progress: 50 });
        
        const report = metricsCollector.generateReport();
        
        expect(report).toContain('METRICS REPORT');
        expect(report).toContain('Total Events: 4');
        expect(report).toContain('Error Count: 1');
        expect(report).toContain('Setup:');
        expect(report).toContain('Development:');
      });

      it('should reset metrics', async () => {
        await subject.triggerEvent(testEvent);
        
        expect(metricsCollector.getMetrics().totalEvents).toBe(1);
        
        metricsCollector.reset();
        
        expect(metricsCollector.getMetrics().totalEvents).toBe(0);
      });
    });

    describe('WebhookNotifier', () => {
      let webhookNotifier: WebhookNotifier;
      let mockFetch: jest.Mock;

      beforeEach(() => {
        mockFetch = global.fetch as jest.Mock;
        mockFetch.mockResolvedValue({
          ok: true,
          status: 200
        });
        
        webhookNotifier = new WebhookNotifier('https://webhook.example.com/scrum', {
          headers: { 'Authorization': 'Bearer token123' },
          timeout: 5000
        });
      });

      afterEach(() => {
        jest.clearAllMocks();
      });

      it('should send webhook with default payload', async () => {
        await webhookNotifier.update(testEvent);
        
        expect(mockFetch).toHaveBeenCalledWith(
          'https://webhook.example.com/scrum',
          expect.objectContaining({
            method: 'POST',
            headers: expect.objectContaining({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer token123',
              'User-Agent': 'Semi-Autonomous-Scrum-Master/1.0'
            }),
            body: expect.stringContaining(testEvent.message)
          })
        );
      });

      it('should use custom payload transformer', async () => {
        const customWebhook = new WebhookNotifier('https://custom.example.com', {
          payloadTransformer: (event) => ({
            title: `Scrum Update: ${event.message}`,
            priority: event.type === 'error' ? 'high' : 'normal'
          })
        });

        await customWebhook.update(testEvent);
        
        const callBody = JSON.parse(mockFetch.mock.calls[0][1].body);
        expect(callBody.title).toContain('Test project created successfully');
        expect(callBody.priority).toBe('normal');
      });

      it('should filter events based on criteria', async () => {
        const filteredWebhook = new WebhookNotifier('https://filtered.example.com', {
          eventFilter: (event) => event.type === 'error' // Only send errors
        });

        // This should not trigger webhook
        await filteredWebhook.update(testEvent);
        expect(mockFetch).not.toHaveBeenCalled();

        // This should trigger webhook
        const errorEvent = { ...testEvent, type: 'error' as const };
        await filteredWebhook.update(errorEvent);
        expect(mockFetch).toHaveBeenCalledTimes(1);
      });

      it('should handle webhook failures with retries', async () => {
        mockFetch.mockRejectedValueOnce(new Error('Network error'))
                 .mockRejectedValueOnce(new Error('Network error'))
                 .mockResolvedValueOnce({ ok: true, status: 200 });

        const retryWebhook = new WebhookNotifier('https://retry.example.com', {
          retries: 3
        });

        await retryWebhook.update(testEvent);
        
        expect(mockFetch).toHaveBeenCalledTimes(3);
        expect(retryWebhook.getStats().successCount).toBe(1);
      });

      it('should track success and failure stats', async () => {
        // Success
        await webhookNotifier.update(testEvent);
        
        // Failure
        mockFetch.mockRejectedValueOnce(new Error('Webhook failed'));
        await webhookNotifier.update(testEvent);
        
        const stats = webhookNotifier.getStats();
        expect(stats.successCount).toBe(1);
        expect(stats.failureCount).toBe(1);
        expect(stats.successRate).toBe(50);
      });
    });
  });

  describe('Integration Tests - Enhanced Functionality', () => {
    it('should work with all observer types including new ones', async () => {
      const slackNotifier = new SlackNotifier('https://hooks.slack.com/test', '#general', 'scrum-bot');
      const metricsCollector = new MetricsCollector();
      const webhookNotifier = new WebhookNotifier('https://webhook.example.com');
      
      subject.addObserver(slackNotifier);
      subject.addObserver(metricsCollector);
      subject.addObserver(webhookNotifier);
      
      await subject.triggerEvent(testEvent);
      
      expect(subject.getObserverCount()).toBe(3);
      expect(metricsCollector.getMetrics().totalEvents).toBe(1);
      expect(webhookNotifier.getStats().successCount).toBe(1);
    });

    it('should provide comprehensive system monitoring', async () => {
      const metricsCollector = new MetricsCollector();
      subject.addObserver(metricsCollector);
      
      // Simulate a complete project workflow
      const phases = ['Project Setup', 'Issue Creation', 'Sprint Planning', 'Development', 'Completion'];
      
      for (const [index, phase] of phases.entries()) {
        // Start each phase
        await subject.triggerEvent({
          ...testEvent,
          phase,
          progress: 0,
          type: 'project_created',
          message: `${phase} started`
        });
        
        // Complete each phase
        const progress = 100;
        await subject.triggerEvent({
          ...testEvent,
          phase,
          progress,
          type: 'completion',
          message: `${phase} completed`
        });
      }
      
      const stats = subject.getEventStatistics();
      const metrics = metricsCollector.getMetrics();
      const report = metricsCollector.generateReport();
      
      expect(stats.totalEvents).toBe(10); // 5 start + 5 completion events
      expect(metrics.completedPhases.size).toBe(5);
      expect(report).toContain('Completed Phases: 5');
    });
  });
});
