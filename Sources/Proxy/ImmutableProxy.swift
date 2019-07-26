import Foundation
#if canImport(Combine)
import Combine
#endif

public protocol ImmutableProxyProtocol {
  associatedtype ProxyType
  /// The wrapped proxied object.
  var wrappedValue: ProxyType { get set }
}

public extension ImmutableProxyProtocol {
  /// Use `@dynamicMemberLookup` keypath subscript to forward the value of the proxied object.
  subscript<V>(dynamicMember keyPath: KeyPath<ProxyType, V>) -> V {
    return wrappedValue[keyPath: keyPath]
  }
}

@available(OSX 10.15, iOS 13.0, *)
@dynamicMemberLookup
@propertyWrapper
open class ImmutableProxy<T>: ImmutableProxyProtocol, ObservableProxy {
  // Observable internals.
  public var willChangeSubscription: Cancellable?
  public var didChangeSubscription: Cancellable?
  public var willChange = PassthroughSubject<PropertyChange, Never>()
  public var didChange = PassthroughSubject<PropertyChange, Never>()

  open var wrappedValue: T
  /// Constructs a new proxy for the object passed as argument.
  init(of object: T) {
    wrappedValue = object
    propagateSubjectsIfNeeded()
  }
}
