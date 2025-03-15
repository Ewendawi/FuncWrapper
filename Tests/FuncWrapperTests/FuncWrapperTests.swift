// In Tests/FuncWrapperTests/FuncWrapperTests.swift

import Testing
import Foundation
@testable import FuncWrapper

@Suite("FuncWrapper Tests")
struct FuncWrapperTests {
    /// A custom error for our throwing tests.
    private enum TestError: Error, Equatable {
        case operationFailed
    }
    
    // --- Test for Synchronous, Non-throwing Wrapper ---
    @Test("Sync non-throwing wrapper executes in correct order and returns value")
    func testSyncNonThrowingWrapper() {
        // 1. Arrange
        var executionLog: [String] = []

        let loggingWrapper:FuncWrapper.SyncWrapper = FuncWrapper.makeWrapper { work in
            executionLog.append("wrapper.start")
            let result = work()
            executionLog.append("wrapper.end")
            return result
        }

        let action: () -> Int? = {
            executionLog.append("action.executed")
            return nil
        }
        
        let actionVoid: () -> Void = {
            executionLog.append("actionVoid.executed")
        }

        // 2. Act
        let finalResult = loggingWrapper { action() }
        loggingWrapper { actionVoid() }

        // 3. Assert
        #expect(finalResult == nil, "The final result should be passed through the wrapper.")
        #expect(executionLog == [
            "wrapper.start",
            "action.executed",
            "wrapper.end",
            
            "wrapper.start",
            "actionVoid.executed",
            "wrapper.end"
        ], "The execution order should be correct.")
    }
    
    // --- Tests for Synchronous, Throwing Wrapper ---
    @Test("Sync throwing wrapper succeeds when action does not throw")
    func testSyncThrowingWrapper_SuccessPath() throws {
        // 1. Arrange
        var executionLog: [String] = []

        let rethrowingWrapper = FuncWrapper.makeWrapper { work in
            executionLog.append("wrapper.start")
            let result = try work()
            executionLog.append("wrapper.end")
            return result
        }

        let successfulAction: () throws -> String = {
            executionLog.append("action.executed")
            return "Success"
        }

        // 2. Act
        let finalResult = try rethrowingWrapper(successfulAction)

        // 3. Assert
        #expect(finalResult == "Success")
        #expect(executionLog == ["wrapper.start", "action.executed", "wrapper.end"])
    }

    @Test("Sync throwing wrapper propagates error when action throws")
    func testSyncThrowingWrapper_FailurePath() {
        // 1. Arrange
        let rethrowingWrapper = FuncWrapper.makeWrapper { work in
            // This wrapper just rethrows any error from the action.
            let result = try work()
            return result
        }
        
        let failingAction: () throws -> Void = {
            throw TestError.operationFailed
        }

        // 2. Act & 3. Assert
        // We expect the wrapper to throw the exact error the action threw.
        #expect(throws: TestError.operationFailed) {
            try rethrowingWrapper(failingAction)
        }
    }
    
    // --- Tests for Asynchronous, Non-throwing Wrapper ---
    @Test("Async non-throwing wrapper executes in correct order")
    func testAsyncNonThrowingWrapper() async {
        // 1. Arrange
        var executionLog: [String] = []
        
        let asyncWrapper = FuncWrapper.makeWrapper { (work: FuncWrapper.AsyncActionFunc) in
            executionLog.append("wrapper.start")
            let result = await work()
            executionLog.append("wrapper.end")
            return result
        }
        
        let asyncAction: () async -> String = {
            executionLog.append("action.start")
            await Task.yield() // Simulate async work
            executionLog.append("action.end")
            return "Async Complete"
        }
        
        // 2. Act
        let finalResult = await asyncWrapper(asyncAction)
        
        // 3. Assert
        #expect(finalResult == "Async Complete")
        #expect(executionLog == [
            "wrapper.start",
            "action.start",
            "action.end",
            "wrapper.end"
        ], "The async execution order should be correct.")
    }
    
    // --- Tests for Asynchronous, Throwing Wrapper ---
    @Test("Async throwing wrapper succeeds when action does not throw")
    func testAsyncThrowingWrapper_SuccessPath() async throws {
        // 1. Arrange
        let rethrowingWrapper = FuncWrapper.makeWrapper { work in
            try await work()
        }
        
        let successfulAction: () async throws -> String = {
            await Task.yield()
            return "Async Success"
        }
        
        // 2. Act
        let finalResult = try await rethrowingWrapper(successfulAction)
        
        // 3. Assert
        #expect(finalResult == "Async Success")
    }

    @Test("Async throwing wrapper propagates error when action throws")
    func testAsyncThrowingWrapper_FailurePath() async {
        // 1. Arrange
        let rethrowingWrapper = FuncWrapper.makeWrapper { work in
            try await work()
        }

        let failingAction: () async throws -> Void = {
            await Task.yield()
            throw TestError.operationFailed
        }
        
        // 2. Act & 3. Assert
        await #expect(throws: TestError.operationFailed) {
            try await rethrowingWrapper(failingAction)
            try await rethrowingWrapper {
                await Task.yield()
                throw TestError.operationFailed
            }
        }
    }
}

@Suite("TypedFuncWrapper Tests")
struct TypedFuncWrapperTests {
    
    /// A custom error for our throwing tests.
    private enum TestError: Error, Equatable {
        case operationFailed
    }
    
    // --- Test for Synchronous, Non-throwing Wrapper ---
    @Test("Sync non-throwing wrapper executes in correct order and returns value")
    func testSyncNonThrowingWrapper() {
        // 1. Arrange
        var executionLog: [String] = []
        
        let loggingWrapper = FuncWrapper.makeWrapper { (work: ()->Int?) in
            executionLog.append("wrapper.start")
            let result = work()
            executionLog.append("wrapper.end")
            return result
        }
        
        let action: () -> Int? = {
            executionLog.append("action.executed")
            return nil
        }
        
        // 2. Act
        let finalResult = loggingWrapper { action() }
        
        // 3. Assert
        #expect(finalResult == nil, "The final result should be passed through the wrapper.")
        #expect(executionLog == [
            "wrapper.start",
            "action.executed",
            "wrapper.end",
        ], "The execution order should be correct.")
    }
   
    // --- Tests for Synchronous, Throwing Wrapper ---
    @Test("Sync throwing wrapper succeeds when action does not throw")
    func testSyncThrowingWrapper_SuccessPath() throws {
        // 1. Arrange
        var executionLog: [String] = []

        let rethrowingWrapper = FuncWrapper.makeWrapper { (work: () throws -> String) in
            executionLog.append("wrapper.start")
            let result = try work()
            executionLog.append("wrapper.end")
            return result
        }

        let successfulAction: () throws -> String = {
            executionLog.append("action.executed")
            return "Success"
        }

        // 2. Act
        let finalResult = try rethrowingWrapper(successfulAction)

        // 3. Assert
        #expect(finalResult == "Success")
        #expect(executionLog == ["wrapper.start", "action.executed", "wrapper.end"])
    }
}



@Suite("FuncWrapper Tests")
struct FuncWrapper2Tests {
    /// A custom error for our throwing tests.
    private enum TestError: Error, Equatable {
        case operationFailed
    }
    
    // --- Test for Synchronous, Non-throwing Wrapper ---
    @Test("Sync non-throwing wrapper executes in correct order and returns value")
    func testSyncNonThrowingWrapper() {
        // 1. Arrange
        var executionLog: [String] = []

        let loggingWrapper = FuncWrapper.makeWrapper  {
            executionLog.append("wrapper.start")
        } after: {
            executionLog.append("wrapper.end")
        }

        let action: () -> Int? = {
            executionLog.append("action.executed")
            return nil
        }
        
        let actionVoid: () -> Void = {
            executionLog.append("actionVoid.executed")
        }

        // 2. Act
        let finalResult = loggingWrapper { action() }
        loggingWrapper { actionVoid() }

        // 3. Assert
        #expect(finalResult == nil, "The final result should be passed through the wrapper.")
        #expect(executionLog == [
            "wrapper.start",
            "action.executed",
            "wrapper.end",
            
            "wrapper.start",
            "actionVoid.executed",
            "wrapper.end"
        ], "The execution order should be correct.")
    }
    
    // --- Tests for Synchronous, Throwing Wrapper ---
    @Test("Sync throwing wrapper succeeds when action does not throw")
    func testSyncThrowingWrapper_SuccessPath() throws {
        // 1. Arrange
        var executionLog: [String] = []

        let rethrowingWrapper = FuncWrapper.makeWrapper {
            executionLog.append("wrapper.start")
            let start = Date()
            return start
        } after: { time in
            print("Wrapped action took \(time) seconds.")
            executionLog.append("wrapper.end")
        }

        let successfulAction: () throws -> String = {
            executionLog.append("action.executed")
            return "Success"
        }

        // 2. Act
        let finalResult = try rethrowingWrapper(successfulAction)

        // 3. Assert
        #expect(finalResult == "Success")
        #expect(executionLog == ["wrapper.start", "action.executed", "wrapper.end"])
    }

    @Test("Sync throwing wrapper propagates error when action throws")
    func testSyncThrowingWrapper_FailurePath() {
        // 1. Arrange
        let rethrowingWrapper = FuncWrapper.makeWrapper {
            // No-op
        } after: {
            // No-op
        }
        
        let failingAction: () throws -> Void = {
            throw TestError.operationFailed
        }

        // 2. Act & 3. Assert
        // We expect the wrapper to throw the exact error the action threw.
        #expect(throws: TestError.operationFailed) {
            try rethrowingWrapper(failingAction)
        }
    }
    
    // --- Tests for Asynchronous, Non-throwing Wrapper ---
    @Test("Async non-throwing wrapper executes in correct order")
    func testAsyncNonThrowingWrapper() async {
        // 1. Arrange
        var executionLog: [String] = []
        
        let asyncWrapper = FuncWrapper.makeWrapper {
            executionLog.append("wrapper.start")
        } after: {
            executionLog.append("wrapper.end")
        }
        
        let asyncAction: () async -> String = {
            executionLog.append("action.start")
            await Task.yield() // Simulate async work
            executionLog.append("action.end")
            return "Async Complete"
        }
        
        // 2. Act
        let finalResult = await asyncWrapper(asyncAction)
        
        // 3. Assert
        #expect(finalResult == "Async Complete")
        #expect(executionLog == [
            "wrapper.start",
            "action.start",
            "action.end",
            "wrapper.end"
        ], "The async execution order should be correct.")
    }
    
    // --- Tests for Asynchronous, Throwing Wrapper ---
    @Test("Async throwing wrapper succeeds when action does not throw")
    func testAsyncThrowingWrapper_SuccessPath() async throws {
        // 1. Arrange
        let rethrowingWrapper = FuncWrapper.makeWrapper {
            // No-op
        } after: {
            // No-op
        }
        
        let successfulAction: () async throws -> String = {
            await Task.yield()
            return "Async Success"
        }
        
        // 2. Act
        let finalResult = try await rethrowingWrapper(successfulAction)
        
        // 3. Assert
        #expect(finalResult == "Async Success")
    }

    @Test("Async throwing wrapper propagates error when action throws")
    func testAsyncThrowingWrapper_FailurePath() async {
        // 1. Arrange
        let rethrowingWrapper = FuncWrapper.makeWrapper() {
            // No-op
        } after: {
            // No-op
        }

        let failingAction: () async throws -> Void = {
            await Task.yield()
            throw TestError.operationFailed
        }
        
        // 2. Act & 3. Assert
        await #expect(throws: TestError.operationFailed) {
            try await rethrowingWrapper(failingAction)
            try await rethrowingWrapper {
                await Task.yield()
                throw TestError.operationFailed
            }
        }
    }
}
