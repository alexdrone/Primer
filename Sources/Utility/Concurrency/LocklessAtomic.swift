import Foundation
import CxxUtility

/// Lockfree atomic enum/options set.
public struct AtomicFlag<T: RawRepresentable>: Sendable where T.RawValue == Int {
  private var backingStorage: LockfreeAtomicStorage<Int>
  
  public var value: T {
    get { T(rawValue: backingStorage.value)! }
    set { backingStorage.exchange(with: newValue.rawValue) }
  }
  
  public init(value: T) {
    backingStorage = LockfreeAtomicStorage<Int>(wrappedValue: value.rawValue)
  }
  
  /// Compares the contents of the value currently stored with `expected` and  if it matches,
  /// it replaces it with `desired`.
  /// The entire operation is atomic: the value cannot be modified by other threads between
  /// the instant its value is read and the moment it is replaced.
  public mutating func compareAndExchange(expected: T, desired: T) -> Bool {
    backingStorage.compareAndExchange(expected: expected.rawValue, desired: desired.rawValue)
  }
}

/// Lockfree atomic boolean.
public struct AtomicBool: Sendable {
  private var backingStorage: LockfreeAtomicStorage<Int>
  
  public var value: Bool {
    get { backingStorage.value != 0 }
    set { backingStorage.exchange(with: (newValue ? 1 : 0)) }
  }
  
  public init(value: Bool) {
    backingStorage = LockfreeAtomicStorage<Int>(wrappedValue: value ? 1 : 0)
  }
  
  /// Compares the contents of the value currently stored with `expected` and  if it matches,
  /// it replaces it with `desired`.
  /// The entire operation is atomic: the value cannot be modified by other threads between
  /// the instant its value is read and the moment it is replaced.
  public mutating func compareAndExchange(expected: Bool, desired: Bool) -> Bool {
    backingStorage.compareAndExchange(expected: expected ? 1 : 0, desired: desired ? 1 : 0)
  }
  
  /// Toggles the Boolean variable's value.
  public mutating func toggle() -> Bool {
    backingStorage.xor() != 0
  }
}

// MARK: - Storage

/// Fine-grained atomic operations allowing for Lockfree concurrent programming.
/// Each atomic operation is indivisible with regards to any other atomic operation that involves
/// the same object.
struct LockfreeAtomicStorage<T>: Sendable {
  private var rawValue = 0

  private init() { }
  
  init(wrappedValue: T) {
    assert(atomicIsLockFree(&rawValue), "The wrapped type is not a built-in atomic type.")
    assert(MemoryLayout.size(ofValue: wrappedValue) == MemoryLayout.size(ofValue: rawValue))
    self.value = wrappedValue
  }

  @inlinable
  @inline(__always)
  var value: T {
      get { unsafeBitCast(rawValue, to: T.self) }
      set { atomicStore(&rawValue, value: unsafeBitCast(newValue, to: Int.self)) }
  }
  
  ///  Atomically replaces the value currently owned with the value of `newValue`.
  @inlinable
  @inline(__always)
  mutating func exchange(with newValue: T) {
    let _ = atomicExchange(&rawValue, with: unsafeBitCast(newValue, to: Int.self))
  }
  
  @inlinable
  @inline(__always)
  mutating func compareAndExchange(expected: T, desired: T) -> Bool {
    atomicCompareExchange(
      &rawValue,
      expected: unsafeBitCast(expected, to: Int.self),
      desired: unsafeBitCast(desired, to: Int.self))
  }
}

extension LockfreeAtomicStorage where T == Int {
  @inlinable @inline(__always)
  mutating func fetchAdd(_ ammount: Int) -> Int {
    atomicAdd(&rawValue, value: ammount)
  }

  @inlinable @inline(__always)
  mutating func update(transform: @Sendable (Int) -> Int) -> (old: Int, new: Int) {
    atomicUpdate(&rawValue, transform: transform)
  }

  @inlinable @inline(__always)
  mutating func xor() -> Int {
    atomicXor(&rawValue)
  }
}

@inlinable @inline(__always)
public func atomicIsLockFree(_ pointer: UnsafeMutablePointer<Int>) -> Bool {
  std_atomic_is_lock_free(OpaquePointer(pointer)) != 0
}

@inlinable @inline(__always)
public func atomicStore(_ pointer: UnsafeMutablePointer<Int>, value: Int) {
  std_atomic_store(OpaquePointer(pointer), value)
}

@discardableResult @inlinable @inline(__always)
public func atomicAdd(_ pointer: UnsafeMutablePointer<Int>, value: Int) -> Int {
  std_atomic_fetch_add(OpaquePointer(pointer), value)
}

@discardableResult @inlinable @inline(__always)
public func atomicExchange(_ pointer: UnsafeMutablePointer<Int>, with value: Int) -> Int {
  std_atomic_exchange(OpaquePointer(pointer), value)
}

@discardableResult @inlinable @inline(__always)
public func atomicXor(_ pointer: UnsafeMutablePointer<Int>) -> Int {
  std_atomic_fetch_xor(OpaquePointer(pointer))
}

@discardableResult @inlinable @inline(__always)
public func atomicCompareExchange(_ pointer: UnsafeMutablePointer<Int>, expected: Int, desired: Int
) -> Bool {
  var expected = expected
  return std_atomic_compare_exchange_strong(OpaquePointer(pointer), &expected, desired) != 0
}

@discardableResult @inlinable @inline(__always)
public func atomicUpdate(
  _ pointer: UnsafeMutablePointer<Int>,
  transform: @Sendable (Int) -> Int
) -> (old: Int, new: Int) {
  var oldValue = pointer.pointee, newValue: Int
  repeat {
    newValue = transform(oldValue)
  }
  while std_atomic_compare_exchange_strong(OpaquePointer(pointer), &oldValue, newValue) == 0
  return (oldValue, newValue)
}
