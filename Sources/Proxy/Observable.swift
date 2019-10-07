import Foundation

#if canImport(Combine)
  import Combine
#endif

@available(OSX 10.15, iOS 13.0, *)
public protocol PropertyObservableObject: class {
  /// A publisher that emits when an object property has changed.
  var propertyDidChange: PassthroughSubject<AnyPropertyChangeEvent, Never> { get }
}

@available(OSX 10.15, iOS 13.0, *)
public protocol AnySubscription: class {
  /// Used to subscribe to any `ObservableObject`.
  var objectWillChangeSubscriber: Cancellable? { get set }

  /// Used to subscribe to any `PropertyObservableObject`.
  var propertyDidChangeSubscriber: Cancellable? { get set }
}

/// Represent an object mutation.
public struct AnyPropertyChangeEvent {
  /// The proxy's wrapped value.
  public let object: Any

  /// The mutated keyPath.
  public let keyPath: AnyKeyPath?

  /// Returns a new `allChanged` event.
  public static func allChangedEvent<T>(object: T) -> AnyPropertyChangeEvent {
    return AnyPropertyChangeEvent(object: object, keyPath: nil)
  }

  /// This event signal that the whole object changed and all of its properties should be marked
  /// as dirty.
  public func allChanged<T>(type: T.Type) -> Bool {
    guard let _ = object as? T, keyPath == nil else {
      return false
    }
    return true
  }

  /// Returns the tuple `object, value` if this property change matches the `keyPath` passed as
  /// argument.
  public func match<T, V>(keyPath: KeyPath<T, V>) -> (T, V)? {
    guard self.keyPath === keyPath, let obj = self.object as? T else {
      return nil
    }
    return (obj, obj[keyPath: keyPath])
  }
}
