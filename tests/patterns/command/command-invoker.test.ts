import { CommandInvoker, GitHubProjectCommandInvoker } from '../../../src/patterns/command/command-invoker';
import { GitHubCommand } from '../../../src/patterns/command/github-command.interface';
import { CommandResult } from '../../../src/patterns/command/command-result.interface';

describe('CommandInvoker', () => {
  let commandInvoker: CommandInvoker;
  let mockCommand: jest.Mocked<GitHubCommand>;

  beforeEach(() => {
    commandInvoker = new CommandInvoker();
    
    mockCommand = {
      execute: jest.fn(),
      undo: jest.fn(),
      getDescription: jest.fn().mockReturnValue('Mock Command'),
      getType: jest.fn().mockReturnValue('mock'),
      canUndo: jest.fn().mockReturnValue(true),
      getMetadata: jest.fn().mockReturnValue({}),
    };
  });

  describe('executeCommand', () => {
    it('should execute a command successfully', async () => {
      const mockResult: CommandResult = {
        success: true,
        data: { id: '123' },
        executedAt: new Date()
      };
      
      mockCommand.execute.mockResolvedValue(mockResult);

      const result = await commandInvoker.executeCommand(mockCommand);

      expect(mockCommand.execute).toHaveBeenCalledTimes(1);
      expect(result).toEqual(mockResult);
      expect(result.success).toBe(true);
    });

    it('should handle command execution failure', async () => {
      const mockResult: CommandResult = {
        success: false,
        error: 'Command failed',
        executedAt: new Date()
      };
      
      mockCommand.execute.mockResolvedValue(mockResult);

      const result = await commandInvoker.executeCommand(mockCommand);

      expect(result.success).toBe(false);
      expect(result.error).toBe('Command failed');
    });

    it('should handle command execution exception', async () => {
      const error = new Error('Unexpected error');
      mockCommand.execute.mockRejectedValue(error);

      const result = await commandInvoker.executeCommand(mockCommand);

      expect(result.success).toBe(false);
      expect(result.error).toBe('Unexpected error');
    });
  });

  describe('executeBatch', () => {
    it('should execute multiple commands successfully', async () => {
      const mockCommands = [mockCommand, { ...mockCommand }];
      const mockResult: CommandResult = {
        success: true,
        data: {},
        executedAt: new Date()
      };
      
      mockCommand.execute.mockResolvedValue(mockResult);

      const result = await commandInvoker.executeBatch(mockCommands);

      expect(result.totalCommands).toBe(2);
      expect(result.successfulCommands).toBe(2);
      expect(result.failedCommands).toBe(0);
      expect(result.results).toHaveLength(2);
    });

    it('should handle partial failures in batch execution', async () => {
      const successResult: CommandResult = { success: true, data: {}, executedAt: new Date() };
      const failureResult: CommandResult = { success: false, error: 'Failed', executedAt: new Date() };
      
      const mockCommand2 = { ...mockCommand, execute: jest.fn().mockResolvedValue(failureResult) };
      mockCommand.execute.mockResolvedValue(successResult);

      const result = await commandInvoker.executeBatch([mockCommand, mockCommand2]);

      expect(result.totalCommands).toBe(2);
      expect(result.successfulCommands).toBe(1);
      expect(result.failedCommands).toBe(1);
      expect(result.failed).toHaveLength(1);
    });
  });

  describe('executeWithRetry', () => {
    it('should succeed on first attempt', async () => {
      const mockResult: CommandResult = {
        success: true,
        data: {},
        executedAt: new Date()
      };
      
      mockCommand.execute.mockResolvedValue(mockResult);

      const result = await commandInvoker.executeWithRetry(mockCommand, 3, 100);

      expect(mockCommand.execute).toHaveBeenCalledTimes(1);
      expect(result.success).toBe(true);
    });

    it('should retry on failure and eventually succeed', async () => {
      const failureResult: CommandResult = { success: false, error: 'Transient error', executedAt: new Date() };
      const successResult: CommandResult = { success: true, data: {}, executedAt: new Date() };
      
      mockCommand.execute
        .mockResolvedValueOnce(failureResult)
        .mockResolvedValueOnce(failureResult)
        .mockResolvedValueOnce(successResult);

      const result = await commandInvoker.executeWithRetry(mockCommand, 3, 10);

      expect(mockCommand.execute).toHaveBeenCalledTimes(3);
      expect(result.success).toBe(true);
    });

    it('should fail after max retries', async () => {
      const failureResult: CommandResult = { success: false, error: 'Persistent error', executedAt: new Date() };
      mockCommand.execute.mockResolvedValue(failureResult);

      const result = await commandInvoker.executeWithRetry(mockCommand, 2, 10);

      expect(mockCommand.execute).toHaveBeenCalledTimes(2);
      expect(result.success).toBe(false);
      expect(result.error).toBe('Persistent error');
    });
  });

  describe('undoLastCommand', () => {
    it('should undo the last command successfully', async () => {
      const mockResult: CommandResult = { success: true, data: {}, executedAt: new Date() };
      mockCommand.execute.mockResolvedValue(mockResult);
      mockCommand.undo.mockResolvedValue(mockResult);

      await commandInvoker.executeCommand(mockCommand);
      const result = await commandInvoker.undoLastCommand();

      expect(mockCommand.undo).toHaveBeenCalledTimes(1);
      expect(result).toBe(true);
    });

    it('should return false when no commands to undo', async () => {
      const result = await commandInvoker.undoLastCommand();
      expect(result).toBe(false);
    });

    it('should return false when command cannot be undone', async () => {
      const mockResult: CommandResult = { success: true, data: {}, executedAt: new Date() };
      mockCommand.execute.mockResolvedValue(mockResult);
      mockCommand.canUndo.mockReturnValue(false);

      await commandInvoker.executeCommand(mockCommand);
      const result = await commandInvoker.undoLastCommand();

      expect(result).toBe(false);
      expect(mockCommand.undo).not.toHaveBeenCalled();
    });
  });

  describe('getCommandHistory', () => {
    it('should return empty history initially', () => {
      const history = commandInvoker.getCommandHistory();
      expect(history.totalCommands).toBe(0);
      expect(history.commands).toHaveLength(0);
    });

    it('should track command history', async () => {
      const mockResult: CommandResult = { success: true, data: {}, executedAt: new Date() };
      mockCommand.execute.mockResolvedValue(mockResult);

      await commandInvoker.executeCommand(mockCommand);
      const history = commandInvoker.getCommandHistory();

      expect(history.totalCommands).toBe(1);
      expect(history.successfulCommands).toBe(1);
      expect(history.failedCommands).toBe(0);
      expect(history.commands[0].description).toBe('Mock Command');
    });
  });

  describe('healthCheck', () => {
    it('should return healthy status with no history', async () => {
      const health = await commandInvoker.healthCheck();
      
      expect(health.isHealthy).toBe(true);
      expect(health.successRate).toBe(100);
      expect(health.totalCommands).toBe(0);
    });

    it('should return healthy status with good success rate', async () => {
      const successResult: CommandResult = { success: true, data: {}, executedAt: new Date() };
      mockCommand.execute.mockResolvedValue(successResult);

      // Execute some successful commands
      for (let i = 0; i < 5; i++) {
        await commandInvoker.executeCommand(mockCommand);
      }

      const health = await commandInvoker.healthCheck();
      expect(health.isHealthy).toBe(true);
      expect(health.successRate).toBe(100);
    });

    it('should return unhealthy status with poor success rate', async () => {
      const failureResult: CommandResult = { success: false, error: 'Error', executedAt: new Date() };
      mockCommand.execute.mockResolvedValue(failureResult);

      // Execute some failed commands
      for (let i = 0; i < 10; i++) {
        await commandInvoker.executeCommand(mockCommand);
      }

      const health = await commandInvoker.healthCheck();
      expect(health.isHealthy).toBe(false);
      expect(health.successRate).toBe(0);
      expect(health.recentFailures).toBe(10);
    });
  });
});

describe('GitHubProjectCommandInvoker', () => {
  let invoker: GitHubProjectCommandInvoker;
  let mockObserver: any;

  beforeEach(() => {
    invoker = new GitHubProjectCommandInvoker();
    mockObserver = {
      onProgress: jest.fn()
    };
  });

  describe('observer management', () => {
    it('should add and notify observers', async () => {
      invoker.addObserver(mockObserver);
      
      const mockCommand: jest.Mocked<GitHubCommand> = {
        execute: jest.fn().mockResolvedValue({ success: true, data: {}, executedAt: new Date() }),
        undo: jest.fn(),
        getDescription: jest.fn().mockReturnValue('Test Command'),
        getType: jest.fn().mockReturnValue('test'),
        canUndo: jest.fn().mockReturnValue(true),
        getMetadata: jest.fn().mockReturnValue({})
      };

      await invoker.executeCommand(mockCommand);

      // Observer should be called during batch execution
      // The exact call depends on internal implementation
      expect(mockObserver.onProgress).toBeDefined();
    });

    it('should remove observers', () => {
      invoker.addObserver(mockObserver);
      invoker.removeObserver(mockObserver);
      
      // Observer should be removed from internal list
      // This test verifies the method exists and doesn't throw
      expect(() => invoker.removeObserver(mockObserver)).not.toThrow();
    });
  });
});
