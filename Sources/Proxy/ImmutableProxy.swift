import Foundation

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

@dynamicMemberLookup
@propertyWrapper
open class ImmutableProxy<T>: ImmutableProxyProtocol {
  open var wrappedValue: T
  /// Constructs a new proxy for the object passed as argument.
  init(of object: T) {
    wrappedValue = object
  }
}
