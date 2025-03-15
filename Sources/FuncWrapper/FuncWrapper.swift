// The Swift Programming Language
// https://docs.swift.org/swift-book


/// A namespace for creating and managing generic function wrappers.
enum FuncWrapper {
    
    // MARK: - Type Aliases for Wrapping Logic
    typealias ActionFunc = () -> Any
    typealias ThrowingActionFunc = () throws -> Any
    typealias AsyncActionFunc = () async -> Any
    typealias AsyncThrowingActionFunc = () async throws -> Any

    typealias SyncWrappingLogic = (ActionFunc) -> Any
    typealias ThrowingWrappingLogic = (ThrowingActionFunc) throws -> Any
    typealias AsyncWrappingLogic = (AsyncActionFunc) async -> Any
    typealias AsyncThrowingWrappingLogic = (AsyncThrowingActionFunc) async throws -> Any

    struct splitWrapper<K> {
        private let _pre : () -> K
        private let _post : (K) -> Void

        init(
            pre: @escaping () -> K,
            post: @escaping (K) -> Void
        ) {
            self._pre = pre
            self._post = post
        }
        
        func callAsFunction<T>(_ action: @escaping () -> T) -> T {
            let preResult = _pre()
            let actionResult = action()
            _post(preResult)
            return actionResult
        }
        
        func callAsFunction<T>(_ action: @escaping () throws -> T) throws -> T {
            let preResult = _pre()
            let actionResult = try action()
            _post(preResult)
            return actionResult
        }
        
        func callAsFunction<T>(_ action: @escaping () async -> T) async -> T {
            let preResult = _pre()
            let actionResult = await action()
            _post(preResult)
            return actionResult
        }
        
        func callAsFunction<T>(_ action: @escaping () async throws -> T) async throws -> T {
            let preResult = _pre()
            let actionResult = try await action()
            _post(preResult)
            return actionResult
        }
    }
    
    // MARK: - Wrapper Structs
    // These are the type-erased containers that hold the wrapping logic.
    // Their public `callAsFunction` API is generic, but their internal storage is not.
    struct SyncWrapper {
        private let _execute: SyncWrappingLogic
        
        init(_ logic: @escaping SyncWrappingLogic) {
            self._execute = logic
        }
        
        /// Executes the wrapped action with the configured logic. The generic type `T` is
        /// inferred here at the call site.
        func callAsFunction<T>(_ action: @escaping () -> T) -> T {
            let result = _execute { action() }
            if T.self == Void.self { return () as! T } // Handle Void return type
            return result as! T // Safe cast, as we control the type flow
        }
    }

    struct ThrowingWrapper {
        private let _execute: ThrowingWrappingLogic
        
        init(_ logic: @escaping ThrowingWrappingLogic) {
            self._execute = logic
        }
        
        func callAsFunction<T>(_ action: @escaping () throws -> T) throws -> T {
            let result = try _execute { try action() }
            if T.self == Void.self { return () as! T }
            return result as! T
        }
    }

    struct AsyncWrapper {
        private let _execute: AsyncWrappingLogic
        
        init(_ logic: @escaping AsyncWrappingLogic) {
            self._execute = logic
        }
        
        func callAsFunction<T>(_ action: @escaping () async -> T) async -> T {
            let result = await _execute { await action() }
            if T.self == Void.self { return () as! T }
            return result as! T
        }
    }

    struct AsyncThrowingWrapper {
        private let _execute: AsyncThrowingWrappingLogic
        
        init(_ logic: @escaping AsyncThrowingWrappingLogic) {
            self._execute = logic
        }
        
        func callAsFunction<T>(_ action: @escaping () async throws -> T) async throws -> T {
            let result = try await _execute { try await action() }
            if T.self == Void.self { return () as! T }
            return result as! T
        }
    }


    // MARK: - Factory Methods
    
    static func makeWrapper(wrappingWith logic: @escaping SyncWrappingLogic) -> SyncWrapper {
        return SyncWrapper(logic)
    }
    
    static func makeWrapper(wrappingWith logic: @escaping ThrowingWrappingLogic) -> ThrowingWrapper {
        return ThrowingWrapper(logic)
    }
    
    static func makeWrapper(wrappingWith logic: @escaping AsyncWrappingLogic) -> AsyncWrapper {
        return AsyncWrapper(logic)
    }
    
    static func makeWrapper(wrappingWith logic: @escaping AsyncThrowingWrappingLogic) -> AsyncThrowingWrapper {
        return AsyncThrowingWrapper(logic)
    }
    
    static func makeWrapper<T>(before pre: @escaping () -> T, after post: @escaping (T) -> Void) -> splitWrapper<T> {
        return splitWrapper(pre: pre, post: post)
    }
    
    static func makeWrapper(before pre: @escaping () -> Void) -> splitWrapper<Void> {
        return splitWrapper(pre: pre, post: {} )
    }
    
    static func makeWrapper(after post: @escaping () -> Void) -> splitWrapper<Void> {
        return splitWrapper(pre: {}, post: post)
    }
}

extension FuncWrapper {
    // MARK: - Action Types
    typealias TypedAction<T> = () -> T
    typealias TypedThrowingAction<T> = () throws -> T
    typealias TypedAsyncAction<T> = () async -> T
    typealias TypedAsyncThrowingAction<T> = () async throws -> T

    // MARK: - Wrapper Types
    // These define the signature of the wrapper functions themselves.
    typealias TypedWrapper<T> = (_ work: @escaping TypedAction<T>) -> T
    typealias TypedThrowingWrapper<T> = (_ work: @escaping TypedThrowingAction<T>) throws -> T
    typealias TypedAsyncWrapper<T> = (_ work: @escaping TypedAsyncAction<T>) async -> T
    typealias TypedAsyncThrowingWrapper<T> = (_ work: @escaping TypedAsyncThrowingAction<T>) async throws -> T
    
    // 1. Sync, Non-throwing
    static func makeWrapper<T>(
        wrappingWith logic: @escaping TypedWrapper<T>
    ) -> TypedWrapper<T> {
        return logic
    }
    
    // 2. Sync, Throwing
    static func makeWrapper<T>(
        wrappingWith logic: @escaping TypedThrowingWrapper<T>
    ) -> TypedThrowingWrapper<T> {
        return logic
    }
    
    // 3. Async, Non-throwing
    static func makeWrapper<T>(
        wrappingWith logic: @escaping TypedAsyncWrapper<T>
    ) -> TypedAsyncWrapper<T> {
        return logic
    }
    
    // 4. Async, Throwing
    static func makeWrapper<T>(
        wrappingWith logic: @escaping TypedAsyncThrowingWrapper<T>
    ) -> TypedAsyncThrowingWrapper<T> {
        return logic
    }
}

