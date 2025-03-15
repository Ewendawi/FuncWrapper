# FuncWrapper

[![Swift Version](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)

A lightweight, powerful Swift library for creating generic, reusable function wrappers. Abstract away cross-cutting concerns like logging, timing, error handling, and retries with a clean, declarative API.

## Why FuncWrapper?

Ever find yourself writing the same boilerplate logic around your function calls?

**Before FuncWrapper:** Repetitive and error-prone.

```swift
func fetchUserData() -> User {
    print("️Starting fetchUserData...")
    let start = Date()
    
    // The actual work
    let user = networkService.fetchUser()
    
    let duration = Date().timeIntervalSince(start)
    print("Finished fetchUserData in \(duration)s.")
    return user
}

func generateReport() -> Report {
    print("️Starting generateReport...")
    let start = Date()

    // The actual work
    let report = reportService.generate()
    
    let duration = Date().timeIntervalSince(start)
    print("Finished generateReport in \(duration)s.")
    return report
}
```

**After FuncWrapper:** Clean, reusable, and declarative.

```swift
// 1. Define your wrapper once
let logAndMeasure = FuncWrapper.makeWrapper { (action: () -> Any) in
    print("️Starting task...")
    let start = Date()
    let result = action() // Execute any action
    let duration = Date().timeIntervalSince(start)
    print("Finished in \(duration)s.")
    return result
}

// 2. Apply it anywhere
let user: User = logAndMeasure { networkService.fetchUser() }
let report: Report = logAndMeasure { reportService.generate() }
```

## Features

- **Declarative:** Define wrapper logic once, apply it everywhere.
- **Type-Safe:** Full compile-time safety and autocompletion, with the generic type `T` inferred at the call site.
- **Universal:** Supports all four function signatures:
    - Synchronous (`() -> T`)
    - Throwing (`() throws -> T`)
    - Asynchronous (`() async -> T`)
    - Asynchronous Throwing (`() async throws -> T`)
- **Composable:** Chain wrappers together for powerful combinations.
- **Lightweight:** A single file with zero external dependencies.

## Basic Usage

Using `FuncWrapper` is a simple two-step process: **create** your wrapper template, then **use** it to execute your functions.

### 1. Create a Wrapper

Use `FuncWrapper.makeWrapper` to define the behavior. Inside the logic closure, you receive a `action` function that you must execute.

```swift
import FuncWrapper
import Foundation

// Create a wrapper that times the execution of any synchronous function.
// NOTE: The anotation `() -> Any` is necessary to enable type derivation. 
//       More details in the "How It Works" section below.
let timeExecution = FuncWrapper.makeWrapper { (action: () -> Any) in
    let start = Date()
    let result = action() // The 'action' closure returns `Any` internally
    let duration = Date().timeIntervalSince(start)
    print("️Task finished in \(String(format: "%.4f", duration))s")
    return result
}
```

### 2. Use the Wrapper

Call your wrapper as if it were a function, passing your actual action in a trailing closure. The generic return type is automatically inferred.

```swift
// Use it on a function returning a String
let report: String = timeExecution {
    Thread.sleep(forTimeInterval: 0.5)
    return "Monthly Report"
}
// Prints: ️Task finished in 0.5012s
print("Result: \(report)") // "Monthly Report"


// Use it on a function returning an Int
let answer: Int = timeExecution {
    return 42
}
// Prints: ️Task finished in 0.0001s
print("Result: \(answer)") // 42


// Use it on a function returning Void
timeExecution {
    print("Doing some work...")
}
// Prints: Task finished in 0.0000s
```

## Advanced Usage

`FuncWrapper` shines when dealing with complex asynchronous and error-handling logic. The factory provides overloads for all common function types.

### Handling `throws`

Create a wrapper using the `ThrowingWrappingLogic` overload. This is perfect for centralizing error handling.

```swift
enum DataError: Error { case failedToSave }

// This wrapper attempts a risky operation and logs failures.
let resilientAttempt = FuncWrapper.makeWrapper { action in
    print("️Attempting risky operation...")
    do {
        return try action()
    } catch {
        print("Operation failed: \(error)")
        throw error
    }
}

// Use it
let successfulID: UUID? = try? resilientAttempt {
    // This action succeeds
    return UUID()
}

let failedID: UUID? = try? resilientAttempt {
    // This action throws
    throw DataError.failedToSave
}
// Console for the second call:
// ️Attempting risky operation...
// Operation failed: failedToSave
```

### Handling `async`

```swift
// An async wrapper that prints when the task starts and ends
let trackAsyncTask = FuncWrapper.makeWrapper { (action: () async -> Any) in
    print("Starting async task...")
    let result = await action()
    print("Async task complete.")
    return result
}

// Async action
func fetchUserProfile(id: Int) async -> String {
    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 sec delay
    return "User Profile \(id)"
}

// Use the async wrapper
let profile: String = await trackAsyncTask { await fetchUserProfile(id: 123) }
print("Result: \(profile)\n")
```

### Handling `async` and `async throws`

The factory provides `async` and `async throws` overloads.

```swift
enum NetworkError: Error { case serverDown }
var didFailOnce = false

// Create a wrapper that retries an async, throwing task once upon failure.
let retryOnce = FuncWrapper.makeWrapper { action in
    do {
        return try await action()
    } catch {
        print("️First attempt failed: \(error). Retrying...")
        return try await action() // Second attempt
    }
}

// A function that fails the first time it's called
func postData() async throws -> Bool {
    if !didFailOnce {
        didFailOnce = true
        throw NetworkError.serverDown
    }
    return true
}

// Use the wrapper
do {
    let success: Bool = try await retryOnce { try await postData() }
    print("Successfully posted data after one retry.")
} catch {
    print("Posting failed even after retry.")
}
// Console:
// ️First attempt failed: serverDown. Retrying...
// Successfully posted data after one retry.
```

## API Reference

The `FuncWrapper` provides four `makeWrapper` overloads. The compiler will choose the correct one based on the logic you provide.

1.  **`makeWrapper(wrappingWith: (() -> Any) -> Any)`**
    -   For actions of type: `() -> T`, returning `SyncWrapper`
2.  **`makeWrapper(wrappingWith: (() throws -> Any) throws -> Any)`**
    -   For actions of type: `() throws -> T`, returning `ThrowingWrapper`
3.  **`makeWrapper(wrappingWith: (() async -> Any) -> Any)`**
    -   For actions of type: `() async -> T`, returning `AsyncWrapper`
4.  **`makeWrapper(wrappingWith: (() async throws -> Any) throws -> Any)`**
    -   For actions of type: `() async throws -> T`, returning `AsyncThrowingWrapper`

## How It Works

The magic of `FuncWrapper` lies in a two-step process that leverages Swift's powerful type inference and a technique called type erasure.

### 1. Creating a Wrapper: Type Inference

When you call `FuncWrapper.makeWrapper`, you provide a closure that defines your custom logic. The Swift compiler analyzes the code inside your closure to infer its type. Specifically, it looks at how you call the `action` closure that is passed to you:

*   If you call `action()` without any keywords, the compiler infers a synchronous function type. But it has no idea whether it's a throwing or non-throwing function type. Here, you need to provide a type hint to resolve the ambiguity (see the note below).
*   If you call `try action()`, the compiler infers a `throwing` function type.
*   If you call `await action()`, the compiler infers an `async` function type. The throwing nature is still ambiguous here, so a type hint be needed as well.
*   If you call `try await action()`, the compiler infers an `async throws` function type.

Based on this inferred type, the factory creates and returns one of four specialized, type-erased wrapper structs: `SyncWrapper`, `ThrowingWrapper`, `AsyncWrapper`, or `AsyncThrowingWrapper`. Each struct stores your logic but hides the specific function signature from the outside world.

> **⚠️ Important Note on Type Inference**
> 
> For the closure without `try`, the signature is ambiguous because it could be `() -> T` or `() throws -> T` (`() async -> T` or `() async throws -> T` for `async`). 
>  
> You must provide a type hint to resolve this ambiguity, for example:
```swift
//❌ Incorrect (Compiler Error):
// AMBIGUOUS: Is this a SyncWrapper or a ThrowingWrapper?
let timeExecution = FuncWrapper.makeWrapper { action in
    // ... logic without `try` or `await`
    return action()
}

//✅ Correct (Provide a type hint):

//Option 1: Explicitly type the variable.
let timeExecution: FuncWrapper.SyncWrapper = FuncWrapper.makeWrapper { action in
    // Now the compiler knows exactly which overload to use.
    let result = action()
    // ...
    return result
}

//Option 2: Annotate the closure's parameter.
let timeExecution = FuncWrapper.makeWrapper { (action: () -> Any) in
    // The type annotation on `action` resolves the ambiguity.
    let result = action()
    // ...
    return result
}
```

### 2. Calling the Wrapper: Generic Execution

Each wrapper struct (`SyncWrapper`, etc.) has a public `callAsFunction<T>(...)` method. This makes the wrapper instance callable like a function.

When you call your created wrapper, this generic `callAsFunction` is executed.

```swift
// The generic type `T` is inferred here as `String`
let report: String = timeExecution {
    return "Monthly Report"
}
```

Internally, `callAsFunction` takes your specific action (e.g., one that returns a `String`), wraps it in a closure that returns `Any` to match the stored logic's signature, and executes it. The `Any` result is then safely cast back to the inferred generic type `T` (`String` in this case) before being returned to you.

This design allows a single wrapper instance to be defined once and then used to execute any function that matches its signature (sync, async, etc.), regardless of its specific return type.


## Contributing

Contributions are welcome! If you have an idea for an improvement or find a bug, please open an issue or submit a pull request.

## License

FuncWrapper is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
