import Foundation
import CxxUtility

/// Fine-grained atomic operations allowing for lockless concurrent programming.
/// Each atomic operation is indivisible with regards to any other atomic operation that involves
/// the same object.
/// This synchronization mechanism works only with value types.
public struct LocklessAtomic<T: LocklessAtomicWrappable> {
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
  
  @discardableResult
  private mutating func internalUpdate(_ transform: (T) -> T) -> (old: T, new: T) {
    let (old, new) = atomicUpdate(&rawValue) {
      let obj = unsafeBitCast($0, to: T.self)
      return unsafeBitCast(transform(obj), to: Int.self)
    }
    return (unsafeBitCast(old, to: T.self), unsafeBitCast(new, to: T.self))
  }
  
  @discardableResult
  public mutating func update(_ transform: (inout T) -> Void) -> T {
    internalUpdate {
      var obj = $0
      transform(&obj)
      return obj
    }.old
  }
  
  @discardableResult
  public mutating func update<V>(keyPath: WritableKeyPath<T, V>, with value: V) -> V {
    internalUpdate {
      var obj = $0
      obj[keyPath: keyPath] = value
      return obj
    }.old[keyPath: keyPath]
  }
  
  ///  Atomically replaces the value currently owned with the value of `newValue`.
  public mutating func exchange(with newValue: T) {
    let _ = atomicExchange(&rawValue, with: unsafeBitCast(newValue, to: Int.self))
  }
  
  /// Compares the contents of the value currently owned with `expected` and  if `true`, it replaces
  /// it with `desired`.
  /// The entire operation is atomic: the value cannot be modified by other threads between
  /// the instant its value is read and the moment it is replaced.
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

// MARK: - Internal

@inlinable func atomicIsLockFree(_ pointer: UnsafeMutablePointer<Int>) -> Bool {
  __atomicIsLockFree(OpaquePointer(pointer)) != 0
}

@inlinable func atomicStore(_ pointer: UnsafeMutablePointer<Int>, value: Int) {
  __atomicStore(OpaquePointer(pointer), value)
}

@inlinable @discardableResult
func atomicAdd(_ pointer: UnsafeMutablePointer<Int>, value: Int) -> Int {
  __atomicFetchAdd(OpaquePointer(pointer), value)
}

@inlinable
func atomicExchange(_ pointer: UnsafeMutablePointer<Int>, with value: Int) -> Int {
  __atomicExchange(OpaquePointer(pointer), value)
}

@discardableResult @inlinable
func atomicCompareExchange(_ pointer: UnsafeMutablePointer<Int>, expected: Int, desired: Int
) -> Bool {
  var expected = expected
  return __atomicCompareExchange(OpaquePointer(pointer), &expected, desired) != 0
}

@discardableResult @inlinable
func atomicUpdate(
  _ pointer: UnsafeMutablePointer<Int>,
  transform: (Int) -> Int
) -> (old: Int, new: Int) {
  var oldValue = pointer.pointee
  var newValue: Int
  repeat {
    newValue = transform(oldValue)
  } while __atomicCompareExchange(OpaquePointer(pointer), &oldValue, newValue) == 0
  return (oldValue, newValue)
}

// MARK: - Lockless Atomic Types

public protocol LocklessAtomicWrappable {
}

extension Int: LocklessAtomicWrappable {
}
