import Foundation
import CxxUtility

/// Fine-grained atomic operations allowing for lockless concurrent programming.
/// Each atomic operation is indivisible with regards to any other atomic operation that involves
/// the same object.
/// This synchronization mechanism works only with value types.
public struct LocklessAtomic<T> {
  private var rawValue = 0
  
  private init() { }
  
  public init(wrappedValue: T) {
    assert(atomicIsLockFree(&rawValue), "The wrapped type is not a built-in atomic type.")
    assert(MemoryLayout.size(ofValue: wrappedValue) == MemoryLayout.size(ofValue: rawValue))
    self.value = wrappedValue
  }

  @inline(__always)
  public var value: T {
      get { unsafeBitCast(rawValue, to: T.self) }
      set { atomicStore(&rawValue, value: unsafeBitCast(newValue, to: Int.self)) }
  }
  
  ///  Atomically replaces the value currently owned with the value of `newValue`.
  @inline(__always)
  public mutating func exchange(with newValue: T) {
    let _ = atomicExchange(&rawValue, with: unsafeBitCast(newValue, to: Int.self))
  }
  
  /// Compares the contents of the value currently owned with `expected` and  if `true`, it replaces
  /// it with `desired`.
  /// The entire operation is atomic: the value cannot be modified by other threads between
  /// the instant its value is read and the moment it is replaced.
  @inline(__always)
  public mutating func compareAndExchange(expected: T, desired: T) -> Bool {
    atomicCompareExchange(
      &rawValue,
      expected: unsafeBitCast(expected, to: Int.self),
      desired: unsafeBitCast(desired, to: Int.self))
  }
}

extension LocklessAtomic where T == Int {
  
  /// Atomically add `ammount` to this wrapped integer.
  public mutating func fetchAdd(_ ammount: Int) {
    atomicAdd(&rawValue, value: ammount)
  }
}

// MARK: - LocklessAtomicBacked

public struct LocklessAtomicBacked<T: RawRepresentable> where T.RawValue == Int {
  
  /// The atomic int backing this value.
  public private(set) var backingStorage: LocklessAtomic<Int>
  
  /// Casts the backing storage to the desired type.
  public var value: T {
    get { T(rawValue: backingStorage.value)! }
    set { backingStorage.exchange(with: newValue.rawValue) }
  }
  
  public init(value: T) {
    backingStorage = LocklessAtomic<Int>(wrappedValue: value.rawValue)
  }
  
  /// Compares the contents of the value currently owned with `expected` and  if `true`, it replaces
  /// it with `desired`.
  /// The entire operation is atomic: the value cannot be modified by other threads between
  /// the instant its value is read and the moment it is replaced.
  public mutating func compareAndExchange(expected: T, desired: T) -> Bool {
    backingStorage.compareAndExchange(expected: expected.rawValue, desired: desired.rawValue)
  }
}

// MARK: - Internal

@inlinable
func atomicIsLockFree(_ pointer: UnsafeMutablePointer<Int>) -> Bool {
  __atomicIsLockFree(OpaquePointer(pointer)) != 0
}

@inlinable
func atomicStore(_ pointer: UnsafeMutablePointer<Int>, value: Int) {
  __atomicStore(OpaquePointer(pointer), value)
}

@inlinable
@discardableResult
func atomicAdd(_ pointer: UnsafeMutablePointer<Int>, value: Int) -> Int {
  __atomicFetchAdd(OpaquePointer(pointer), value)
}

@inlinable
@discardableResult
func atomicExchange(_ pointer: UnsafeMutablePointer<Int>, with value: Int) -> Int {
  __atomicExchange(OpaquePointer(pointer), value)
}

@inlinable
@discardableResult
func atomicCompareExchange(_ pointer: UnsafeMutablePointer<Int>, expected: Int, desired: Int
) -> Bool {
  var expected = expected
  return __atomicCompareExchange(OpaquePointer(pointer), &expected, desired) != 0
}
