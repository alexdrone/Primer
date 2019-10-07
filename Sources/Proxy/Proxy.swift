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

extension MutableProxyProtocol {
  /// Extends `ImmutableProxyProtocol` by adding the the `set` subscript for `WritableKeyPath`s.
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

@available(OSX 10.15, iOS 13.0, *)
@dynamicMemberLookup
@propertyWrapper
open class ProxyRef<T>:
  MutableProxyProtocol, AnySubscription, ObservableObject, PropertyObservableObject, NSCopying
{

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
    return ProxyRef(of: wrappedValue)
  }

  open func willSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    // Subclasses to implement this method.
  }

  open func didSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    objectWillChange.send()
    propertyDidChange.send(AnyPropertyChangeEvent(object: self.wrappedValue, keyPath: keyPath))
    // Subclasses to implement this method.
  }
}

@available(OSX 10.15, iOS 13.0, *)
extension ProxyRef: Equatable where T: Equatable {
  /// Two `MutableObservableProxy` are considered equal if they are proxies for the same object.
  public static func == (lhs: ProxyRef<T>, rhs: ProxyRef<T>) -> Bool {
    return lhs.wrappedValue == rhs.wrappedValue
  }
}

@available(OSX 10.15, iOS 13.0, *)
extension ProxyRef: Hashable where T: Hashable {
  /// Hashes the essential components of this value by feeding them into the given hasher.
  public func hash(into hasher: inout Hasher) {
    return wrappedValue.hash(into: &hasher)
  }
}

@available(OSX 10.15, iOS 13.0, *)
extension ProxyRef where T: PropertyObservableObject {
  /// Forwards the `ObservableObject.objectWillChangeSubscriber` to this proxy.
  func propagatePropertyObservableObject() {
    propertyDidChangeSubscriber
      = wrappedValue.propertyDidChange.sink { [weak self] change in
        self?.propertyDidChange.send(change)
      }
  }
}

@available(OSX 10.15, iOS 13.0, *)
extension ProxyRef where T: ObservableObject {
  /// Forwards the `ObservableObject.objectWillChangeSubscriber` to this proxy.
  func propagateObservableObject() {
    objectWillChangeSubscriber
      = wrappedValue.objectWillChange.sink { [weak self] change in
        self?.objectWillChange.send()
      }
  }
}
