import Foundation
#if canImport(Combine)
import SwiftUI
import Combine
#endif

@available(OSX 10.15, iOS 13.0, *)
public protocol Observable {
  /// An instance that publishes an event immediately before the object changes.
  var willChange: PassthroughSubject<PropertyChange, Never> { get }
  /// An instance that publishes an event immediately after the object changes.
  var didChange: PassthroughSubject<PropertyChange, Never> { get }
}

/// Represent an object mutation.
public struct PropertyChange {
  /// The proxy's wrapped value.
  public let object: Any
  /// The mutated keyPath.
  public let keyPath: AnyKeyPath?

  /// Returns the tuple `object, value` if this property change matches the `keyPath` passed as
  /// argument.
  public func match<T, V>(keyPath: KeyPath<T, V>) -> (T, V)? {
    guard self.keyPath === keyPath, let obj = self.object as? T else {
      return nil
    }
    return (obj, obj[keyPath: keyPath])
  }
}

@available(OSX 10.15, iOS 13.0, *)
public protocol ObservableProxy: ImmutableProxyProtocol, BindableObject {
  /// Used for the internal subscription to `Observable.willChange` (if applicable).
  var willChangeSubscription: Cancellable? { get set }
  /// Used for the internal subscription to `Observable.didChange` (if applicable).
  var didChangeSubscription: Cancellable? { get set }
  /// An instance that publishes an event immediately before the object changes.
  var willChange: PassthroughSubject<PropertyChange, Never> { get }
  /// An instance that publishes an event immediately after the object changes.
  var didChange: PassthroughSubject<PropertyChange, Never> { get }
}

@available(OSX 10.15, iOS 13.0, *)
extension ObservableProxy {
  /// Forwards the `Observable.willChange` and `Observable.didChange` streams to the
  /// `ObservableProxy` ones.
  func propagateSubjectsIfNeeded() {
    guard let observableValue = wrappedValue as? Observable else {
      return
    }
    willChangeSubscription = observableValue.willChange.sink { [weak self] change in
      self?.willChange.send(change)
    }
    didChangeSubscription = observableValue.didChange.sink { [weak self] change in
      self?.didChange.send(change)
    }
  }

  /// Force emit a property change event down the passthrough subjects.
  func send(change: PropertyChange) {
    willChange.send(change)
    didChange.send(change)
  }
}
