import Foundation
import Combine

public protocol ImmutableProxyProtocol {
  associatedtype ProxyType
  /// The wrapped proxied object.
  var wrappedValue: ProxyType { get set }
}

extension ImmutableProxyProtocol {
  /// Use `@dynamicMemberLookup` keypath subscript to forward the value of the proxied object.
  public subscript<V>(dynamicMember keyPath: KeyPath<ProxyType, V>) -> V {
    return wrappedValue[keyPath: keyPath]
  }
}

@dynamicMemberLookup
@propertyWrapper
open class ImmutableProxyRef<T>:
  ImmutableProxyProtocol,
  AnySubscription,
  ObservableObject,
  PropertyObservableObject {
  // Observable internals.
  public var objectWillChangeSubscriber: Cancellable?
  public var propertyDidChangeSubscriber: Cancellable?
  public var propertyDidChange = PassthroughSubject<AnyPropertyChangeEvent, Never>()

  open var wrappedValue: T

  /// Constructs a new read-only proxy for the object passed as argument.
  init(of object: T) {
    wrappedValue = object
  }
}

extension ImmutableProxyRef where T: PropertyObservableObject {
  /// Forwards the `ObservableObject.objectWillChangeSubscriber` to this proxy.
  func propagatePropertyObservableObject() {
    propertyDidChangeSubscriber = wrappedValue.propertyDidChange.sink { [weak self] change in
      self?.propertyDidChange.send(change)
    }
  }
}

extension ImmutableProxyRef where T: ObservableObject {
  /// Forwards the `ObservableObject.objectWillChangeSubscriber` to this proxy.
  func propagateObservableObject() {
    objectWillChangeSubscriber = wrappedValue.objectWillChange.sink { [weak self] change in
      self?.objectWillChange.send()
    }
  }
}
