import Foundation
#if canImport(Combine)
import SwiftUI
import Combine
#endif

public protocol MutableProxyProtocol: ImmutableProxyProtocol {
  /// The proxied object is about to be mutated with value `value`.
  func willSetValue<V>(keyPath: KeyPath<ProxyType, V>, value: V)
  /// The proxied object was mutated with value `value`.
  func didSetValue<V>(keyPath: KeyPath<ProxyType, V>, value: V)
}

public extension MutableProxyProtocol {
  /// Extends `ImmutableProxyProtocol` by adding the the `set` subscript for `WritableKeyPath`s.
  subscript<T>(dynamicMember keyPath: WritableKeyPath<ProxyType, T>) -> T {
    get {
      return wrappedValue[keyPath: keyPath]
    }
    set {
      willSetValue(keyPath: keyPath, value: newValue)
      wrappedValue[keyPath: keyPath] = newValue
      didSetValue(keyPath: keyPath, value: newValue)
    }
  }
}

@available(OSX 10.15, iOS 13.0, *)
@dynamicMemberLookup
@propertyWrapper
open class ObservableMutableProxy<T>: MutableProxyProtocol, BindableObject, NSCopying {
  /// Represent an object mutation (performed by accessing to this proxy).
  public struct Change<T> {
    /// The target object.
    public let object: ObservableMutableProxy<T>
    /// The mutated keyPath.
    public let keyPath: AnyKeyPath
  }

  open var wrappedValue: T
  /// An instance that publishes an event immediately before the object changes.
  public var willChange = PassthroughSubject<Change<T>, Never>()
  /// An instance that publishes an event immediately after the object changes.
  public var didChange = PassthroughSubject<Change<T>, Never>()

  /// Constructs a new proxy for the object passed as argument.
  init(of object: T) {
    wrappedValue = object
  }

  /// Returns a new instance that’s a copy of the receiver.
  public func copy(with zone: NSZone? = nil) -> Any {
    return ObservableMutableProxy(of: wrappedValue)
  }

  open func willSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    willChange.send(Change(object: self, keyPath: keyPath))
    // Subclasses to implement this method.
  }

  open func didSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    didChange.send(Change(object: self, keyPath: keyPath))
    // Subclasses to implement this method.
  }
}

@available(OSX 10.15, iOS 13.0, *)
extension ObservableMutableProxy: Equatable where T: Equatable {
  /// Two `MutableObservableProxy` are considered equal if they are proxies for the same object.
  public static func ==(lhs: ObservableMutableProxy<T>, rhs: ObservableMutableProxy<T>) -> Bool {
    return lhs.wrappedValue == rhs.wrappedValue
  }
}

@available(OSX 10.15, iOS 13.0, *)
extension ObservableMutableProxy: Hashable where T: Hashable {
  /// Hashes the essential components of this value by feeding them into the given hasher.
  public func hash(into hasher: inout Hasher) {
    return wrappedValue.hash(into: &hasher)
  }
}

@available(OSX 10.15, iOS 13.0, *)
open class AtomicObservableMutableProxy<T>: ObservableMutableProxy<T> {
  /// Low-level lock that allows waiters to block efficiently on contention.
  private var unfairLock = os_unfair_lock_s()

  open override func willSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    super.willSetValue(keyPath: keyPath, value: value)
    os_unfair_lock_lock(&unfairLock)
  }

  open override func didSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    os_unfair_lock_unlock(&unfairLock)
    super.didSetValue(keyPath: keyPath, value: value)
  }
}
