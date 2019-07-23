import Foundation

// MARK: - ImmutableProxy

public protocol ImmutableProxyProtocol {
  associatedtype ProxyType
  /// The wrapped proxied object.
  var proxiedObject: ProxyType { get }
  /// Whether a specific value for the given keyPath should be overriden.
  func shouldOverride<V>(keyPath: KeyPath<ProxyType, V>, value: V) -> Bool
  /// Override the value for the proxied object getter/setter.
  /// - note: Called only if `shouldOverride(dynamicMember:)` returns true.
  func override<V>(keyPath: KeyPath<ProxyType, V>, value: V) -> V
}

public extension ImmutableProxyProtocol {
  /// Iternal getter method.
  fileprivate func get<V>(dynamicMember keyPath: KeyPath<ProxyType, V>) -> V {
    let value = proxiedObject[keyPath: keyPath]
    guard !shouldOverride(keyPath: keyPath, value: value) else {
      return override(keyPath: keyPath, value: value)
    }
    return value
  }

  /// Use `@dynamicMemberLookup` keypath subscript to forward the value of the proxied object.
  subscript<V>(dynamicMember keyPath: KeyPath<ProxyType, V>) -> V {
    return get(dynamicMember: keyPath)
  }
}

@dynamicMemberLookup
open class ImmutableProxy<T>: ImmutableProxyProtocol {
  public let proxiedObject: T
  /// Constructs a new proxy for the object passed as argument.
  init(of object: T) {
    proxiedObject = object
  }

  open func shouldOverride<V>(keyPath: KeyPath<T, V>, value: V) -> Bool {
    return false
  }

  open func override<V>(keyPath: KeyPath<T, V>, value: V) -> V {
    return value
  }

}

// MARK: - MutableProxy

public protocol MutableProxyProtocol: ImmutableProxyProtocol {
  /// Override the `ImmutableProxyProtocol` property to make it mutable.
  var proxiedObject: ProxyType { get set }
  /// The proxied object is about to be mutated with value `value`.
  func willSetValue<V>(keyPath: KeyPath<ProxyType, V>, value: V)
  /// The proxied object was mutated with value `value`.
  func didSetValue<V>(keyPath: KeyPath<ProxyType, V>, value: V)
}

public extension MutableProxyProtocol {
  /// Extends `ImmutableProxyProtocol` by adding the the `set` subscript for `WritableKeyPath`s.
  subscript<T>(dynamicMember keyPath: WritableKeyPath<ProxyType, T>) -> T {
    get {
      get(dynamicMember: keyPath)
    }
    set {
      var value = newValue
      if shouldOverride(keyPath: keyPath, value: value) {
        value = override(keyPath: keyPath, value: value)
      }
      willSetValue(keyPath: keyPath, value: value)
      proxiedObject[keyPath: keyPath] = value
      didSetValue(keyPath: keyPath, value: value)
    }
  }
}

@dynamicMemberLookup
open class MutableProxy<T>: MutableProxyProtocol {
  public var proxiedObject: T

  /// Constructs a new proxy for the object passed as argument.
  init(of object: T) {
    proxiedObject = object
  }

  open func shouldOverride<V>(keyPath: KeyPath<T, V>, value: V) -> Bool {
    return false
  }

  open func override<V>(keyPath: KeyPath<T, V>, value: V) -> V {
    return value
  }

  open func willSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    // Subclasses to implement this method.
  }

  open func didSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    // Subclasses to implement this method.
  }
}

