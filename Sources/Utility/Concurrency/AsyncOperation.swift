import Foundation

/// Base class for an asynchronous operation.
/// Subclasses are expected to override the 'execute' function and call
/// the function 'finish' when they're done with their task.
open class AsyncOperation: Operation {
  
  /// The completion block type for this operation.
  public typealias CompletionBlock = () -> Void

  // Internal properties override.
  @objc dynamic override public var isAsynchronous: Bool { true }
  @objc dynamic override public var isConcurrent: Bool { true }
  @objc dynamic override public var isExecuting: Bool { __executing }
  @objc dynamic override public var isFinished: Bool { __finished }

  // __ to avoid name clashes with the superclass.
  @objc dynamic private var __executing = false {
    willSet { willChangeValue(forKey: "isExecuting") }
    didSet { didChangeValue(forKey: "isExecuting") }
  }

  // __ to avoid name clashes with the superclass.
  @objc dynamic private var __finished = false {
    willSet { willChangeValue(forKey: "isFinished") }
    didSet { didChangeValue(forKey: "isFinished") }
  }

  /// Begins the execution of the operation.
  @objc dynamic open override func start() {
    __executing = true
    execute()
  }

  /// Subclasses are expected to override the `execute` function and call the function `finish`
  /// when they're done with their task.
  @objc open func execute() {
    fatalError("Your subclass must override this")
  }

  /// This function should be called inside `execute` when the task for this operation is completed.
  @objc dynamic open func finish() {
    __executing = false
    __finished = true
  }
}
