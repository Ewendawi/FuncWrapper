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
let logAndMeasure = FuncWrapper.makeWrapper {
    print("️Starting task...")
    let start = Date()
    return start
} after: { start in
    let duration = Date().timeIntervalSince(start)
    print("Finished in \(duration)s.")
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

// Create a wrapper with independent pre- and post-logic.
let simpleLogger = FuncWrapper.makeWrapper {
    print("️Task started.")
} after: {
    print("Task finished.")
}

// Create a wrapper which the logic after executing the action is dependent on the logic before executing the action.
let timeExecution = FuncWrapper.makeWrapper {
    print("️Starting task...")
    let start = Date()
    return start
} after: { start in
    let duration = Date().timeIntervalSince(start)
    print("Finished in \(duration)s.")
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

## API Reference

The `FuncWrapper` provides four `makeWrapper` overloads. The compiler will choose the correct one based on the logic you provide.

1. **`makeWrapper<T>(before: () -> T, after: (T) -> Void)`**: Both pre- and post-logic
2. **`makeWrapper(before: () -> Void)`**: Only pre-logic
3. **`makeWrapper(after: () -> Void)`**: Only post-logic
   
## Contributing

Contributions are welcome! If you have an idea for an improvement or find a bug, please open an issue or submit a pull request.

## License

FuncWrapper is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
