import Foundation

// MARK: - Atomic

@propertyWrapper
public final class LockAtomic<L: Locking, T> {
  private let lock: L
  private var value: T

  public init(wrappedValue: T, _ lock: L.Type) {
    self.lock = L.init()
    self.value = wrappedValue
  }

  public var wrappedValue: T {
    get {
      var value: T! = nil
      lock.lock()
      value = self.value
      lock.unlock()
      return value
    }
    set {
      lock.lock()
      self.value = newValue
      lock.unlock()
    }
  }

  /// Used for multi-statement atomic access to the wrapped property.
  /// This is especially useful to wrap index-subscripts in value type collections that
  /// otherwise would result in a call to get, a value copy and a subsequent call to set.
  public func mutate(_ block: (inout T) -> Void) {
    lock.lock()
    block(&value)
    lock.unlock()
  }

  /// The $-prefixed value.
  public var projectedValue: LockAtomic<L, T> { self }
}

// MARK: - SyncDispatchQueueAtomic

@propertyWrapper
public final class SyncDispatchQueueAtomic<T> {
  private let queue: DispatchQueue
  private var value: T
  private let concurrentReads: Bool

  public init(wrappedValue: T, concurrentReads: Bool = true) {
    self.value = wrappedValue
    self.concurrentReads = concurrentReads
    let label = "SyncDispatchQueueAtomic.\(UUID().uuidString)"
    self.queue =  DispatchQueue(label: label, attributes: concurrentReads ? [.concurrent] : [])
  }

  public var wrappedValue: T {
    get { queue.sync { value } }
    set { queue.sync(flags: concurrentReads ? [.barrier] : []) { value = newValue } }
  }

  /// Used for multi-statement atomic access to the wrapped property.
  /// This is especially useful to wrap index-subscripts in value type collections that
  /// otherwise would result in a call to get, a value copy and a subsequent call to set.
  public func mutate(_ block: (inout T) -> Void) {
    queue.sync {
      block(&value)
    }
  }

  /// The $-prefixed value.
  public var projectedValue: SyncDispatchQueueAtomic<T> { self }
}

// MARK: - ReadersWriterAtomic

@propertyWrapper
public final class ReadersWriterAtomic<T> {
  private let lock = ReadersWriterLock()
  private var value: T

  public init(wrappedValue: T) {
    self.value = wrappedValue
  }

  public var wrappedValue: T {
    get {
      var value: T! = nil
      lock.withReadLock {
        value = self.value
      }
      return value
    }
    set {
      lock.withWriteLock {
        self.value = newValue
      }
    }
  }

  /// Used for multi-statement atomic access to the wrapped property.
  /// This is especially useful to wrap index-subscripts in value type collections that
  /// otherwise would result in a call to get, a value copy and a subsequent call to set.
  public func mutate(_ block: (inout T) -> Void) {
    lock.withWriteLock {
      block(&value)
    }
  }

  /// The $-prefixed value.
  public var projectedValue: ReadersWriterAtomic<T> { self }
}
