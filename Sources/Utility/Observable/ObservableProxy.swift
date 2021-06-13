import Foundation
import Combine

/// Creates an observable proxy for the object passed as argument.
///
/// Mutations of the wrapped object performed via `get`, `set` or the dynamic keypath subscript
/// are thread-safe and trigger an event through the `objectWillChangeSubscriber` and
/// `propertyDidChangeSubscriber` streams.
@dynamicMemberLookup
open class ObservableProxy<T>:
  AnySubscription,
  ObservableObject,
  PropertyObservableObject,
  NSCopying,
  UncheckedSendable {
  // Observable internals.
  public var objectWillChangeSubscriber: Cancellable?
  public var propertyDidChangeSubscriber: Cancellable?
  public var propertyDidChange = PassthroughSubject<AnyPropertyChangeEvent, Never>()

  private var wrappedValue: T
  
  /// Synchronize the access to the wrapped object.
  private let objectLock = ReadersWriterLock()

  /// Constructs a new proxy for the object passed as argument.
  public init(object: T) {
    wrappedValue = object
  }

  /// Returns a new instance that’s a copy of the receiver.
  public func copy(with zone: NSZone? = nil) -> Any {
    ObservableProxy(object: wrappedValue)
  }

  /// Subclasses to override this method.
  /// - note: Remember to invoke the `super` implementation.
  open func didSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    objectWillChange.send()
    propertyDidChange.send(AnyPropertyChangeEvent(object: wrappedValue, keyPath: keyPath))
    // Subclasses to implement this method.
  }
  
  open func get<V>(keyPath: KeyPath<T, V>) -> V {
    objectLock.withReadLock {
      self.wrappedValue[keyPath: keyPath]
    }
  }
  
  open func set<V>(keyPath: WritableKeyPath<T, V>, value: V) {
    objectLock.withWriteLock {
      self.wrappedValue[keyPath: keyPath] = value
    }
    didSetValue(keyPath: keyPath, value: value)
  }
  
  public subscript<V>(dynamicMember keyPath: WritableKeyPath<T, V>) -> V {
    get { get(keyPath: keyPath) }
    set { set(keyPath: keyPath, value: newValue) }
  }
}

extension ObservableProxy: Equatable where T: Equatable {
  public static func == (lhs: ObservableProxy<T>, rhs: ObservableProxy<T>) -> Bool {
    lhs.wrappedValue == rhs.wrappedValue
  }
}

extension ObservableProxy: Hashable where T: Hashable {
  /// Hashes the essential components of this value by feeding them into the given hasher.
  public func hash(into hasher: inout Hasher) {
    wrappedValue.hash(into: &hasher)
  }
}

extension ObservableProxy: Identifiable where T: Identifiable {
  /// The stable identity of the entity associated with this instance.
  public var id: T.ID { wrappedValue.id }
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
