import Foundation
import Combine

/// Creates an observable Proxy for the object passed as argument.
@dynamicMemberLookup
@propertyWrapper
open class ObservableProxy<T>:
  ProxyProtocol,
  AnySubscription,
  ObservableObject,
  PropertyObservableObject,
  NSCopying {
  // Observable internals.
  public var objectWillChangeSubscriber: Cancellable?
  public var propertyDidChangeSubscriber: Cancellable?
  public var propertyDidChange = PassthroughSubject<AnyPropertyChangeEvent, Never>()

  open var wrappedValue: T

  /// Constructs a new proxy for the object passed as argument.
  init(of object: T) {
    wrappedValue = object
  }

  /// Returns a new instance that’s a copy of the receiver.
  public func copy(with zone: NSZone? = nil) -> Any {
    return ObservableProxy(of: wrappedValue)
  }

  /// Subclasses to override this method.
  /// - note: Remember to invoke the `super` implementation.
  open func willSetValue<V>(keyPath: KeyPath<T, V>, value: V) { }

  /// Subclasses to override this method.
  /// - note: Remember to invoke the `super` implementation.
  open func didSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    objectWillChange.send()
    propertyDidChange.send(AnyPropertyChangeEvent(object: self.wrappedValue, keyPath: keyPath))
    // Subclasses to implement this method.
  }
}

extension ObservableProxy: Equatable where T: Equatable {
  /// Two `MutableObservableProxy` are considered equal if they are proxies for the same object.
  public static func == (lhs: ObservableProxy<T>, rhs: ObservableProxy<T>) -> Bool {
    return lhs.wrappedValue == rhs.wrappedValue
  }
}

extension ObservableProxy: Hashable where T: Hashable {
  /// Hashes the essential components of this value by feeding them into the given hasher.
  public func hash(into hasher: inout Hasher) {
    return wrappedValue.hash(into: &hasher)
  }
}

extension ObservableProxy where T: PropertyObservableObject {
  /// Forwards the `ObservableObject.objectWillChangeSubscriber` to this proxy.
  func propagatePropertyObservableObject() {
    propertyDidChangeSubscriber = wrappedValue.propertyDidChange.sink { [weak self] change in
      self?.propertyDidChange.send(change)
    }
  }
}

extension ObservableProxy where T: ObservableObject {
  /// Forwards the `ObservableObject.objectWillChangeSubscriber` to this proxy.
  func propagateObservableObject() {
    objectWillChangeSubscriber = wrappedValue.objectWillChange.sink { [weak self] change in
      self?.objectWillChange.send()
    }
  }
}

// MARK: - Internal

public protocol ProxyProtocol: ReadOnlyProtocol {
  /// The proxied object is about to be mutated with value `value`.
  func willSetValue<V>(keyPath: KeyPath<ProxyType, V>, value: V)
  /// The proxied object was mutated with value `value`.
  func didSetValue<V>(keyPath: KeyPath<ProxyType, V>, value: V)
}

extension ProxyProtocol {
  /// Extends `ReadOnlyProtocol` by adding the the `set` subscript for `WritableKeyPath`s.
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<ProxyType, T>) -> T {
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
