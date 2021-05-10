import Foundation

public struct TaggedPointer<T: OptionSet, E> where T.RawValue == Int {
  public var rawValue = 0

  @inlinable
  subscript(tag: T) -> Bool {
    get { rawValue & tag.rawValue != 0 }
    set { newValue ? (rawValue |= tag.rawValue) : (rawValue &= ~tag.rawValue) }
  }

  @inlinable
  public var pointer: UnsafeMutablePointer<E>? {
    get { UnsafeMutablePointer(bitPattern: pointerAddress) }
    set { rawValue = Int(bitPattern: newValue) | (rawValue & 7) }
  }

  @inlinable
  public var pointerAddress: Int {
    rawValue & ~7
  }

  @inlinable
  public var counter: Int32 {
    get { getCounter() }
    set { setCounter(newValue) }
  }

  public func getCounter() -> Int32 {
    withUnsafeBytes(of: rawValue) {
      ($0.baseAddress! + 2).assumingMemoryBound(to: Int32.self).pointee
    }
  }

  public mutating func setCounter(_ counter: Int32) {
    withUnsafeMutableBytes(of: &rawValue) {
      ($0.baseAddress! + 2).assumingMemoryBound(to: Int32.self).pointee = counter
    }
  }

}
