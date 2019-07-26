import Foundation
#if canImport(Combine)
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
open class Proxy<T>: MutableProxyProtocol, ObservableProxy, NSCopying {
  // Observable internals.
  public var willChangeSubscription: Cancellable?
  public var didChangeSubscription: Cancellable?
  public var willChange = PassthroughSubject<PropertyChange, Never>()
  public var didChange = PassthroughSubject<PropertyChange, Never>()
  /// Triggers the `willChange` and `didChange` subjects whenever this proxy setters are accessed.
  open var signalPropertyChangeOnProxyMutation = true

  open var wrappedValue: T

  /// Constructs a new proxy for the object passed as argument.
  init(of object: T) {
    wrappedValue = object
    propagateSubjectsIfNeeded()
  }

  /// Returns a new instance that’s a copy of the receiver.
  public func copy(with zone: NSZone? = nil) -> Any {
    return Proxy(of: wrappedValue)
  }

  open func willSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    guard signalPropertyChangeOnProxyMutation else { return }
    willChange.send(PropertyChange(object: self.wrappedValue, keyPath: keyPath))
    // Subclasses to implement this method.
  }

  open func didSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    guard signalPropertyChangeOnProxyMutation else { return }
    didChange.send(PropertyChange(object: self.wrappedValue, keyPath: keyPath))
    // Subclasses to implement this method.
  }
}

@available(OSX 10.15, iOS 13.0, *)
extension Proxy: Equatable where T: Equatable {
  /// Two `MutableObservableProxy` are considered equal if they are proxies for the same object.
  public static func ==(lhs: Proxy<T>, rhs: Proxy<T>) -> Bool {
    return lhs.wrappedValue == rhs.wrappedValue
  }
}

@available(OSX 10.15, iOS 13.0, *)
extension Proxy: Hashable where T: Hashable {
  /// Hashes the essential components of this value by feeding them into the given hasher.
  public func hash(into hasher: inout Hasher) {
    return wrappedValue.hash(into: &hasher)
  }
}

@available(OSX 10.15, iOS 13.0, *)
open class AtomicProxy<T>: Proxy<T> {
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
