import Foundation
import Combine

/// Creates an observable proxy for the object passed as argument.
///
/// Mutations of the wrapped object performed via `get`, `set` or the dynamic keypath subscript
/// are thread-safe and trigger an event through the `objectWillChangeSubscriber` and
/// `propertyDidChangeSubscriber` streams.
@dynamicMemberLookup
open class ObservableProxy<T>: ObservableObject, PropertyObservableObject, UncheckedSendable {
  
  public struct Options<S: Scheduler> {
  
    public enum SchedulingStrategy {
      /// The time the publisher should wait before publishing an element.
      case debounce(Double)
      /// The interval at which to find and emit either the most recent expressed in the time system
      /// of the scheduler.
      case throttle(Double)
      case none
    }
    
    /// The scheduler on which this publisher delivers elements
    public let scheduler: S
    
    /// Schedule stratey.
    public let schedulingStrategy: SchedulingStrategy
  }

  /// Emits an event whenever any of the wrapped object has been mutated.
  public var propertyDidChange = PassthroughSubject<AnyPropertyChangeEvent, Never>()

  /// Synchronize the access to the wrapped object.
  private let objectLock = ReadersWriterLock()

  /// The wrapped object.
  private var wrappedValue: T

  /// Internal subject used to propagate `objectWillChange` and `propertyDidChange` events.
  private var objectDidChange = PassthroughSubject<AnyPropertyChangeEvent, Never>()
  
  private var subscriptions = Set<AnyCancellable>()
  private var objectSubscriptions = Set<AnyCancellable>()

  /// Constructs a new proxy for the object passed as argument.
  public init<S: Scheduler>(object: T, options: Options<S>) {
    wrappedValue = object
    
    var publisher: AnyPublisher = objectDidChange.eraseToAnyPublisher()
    switch options.schedulingStrategy {
    case .debounce(let seconds):
      publisher = publisher
        .debounce(for: .seconds(seconds), scheduler: options.scheduler)
        .eraseToAnyPublisher()
    case .throttle(let seconds):
      publisher = publisher
        .throttle(for: .seconds(seconds), scheduler: options.scheduler, latest: true)
        .eraseToAnyPublisher()
    case .none:
      publisher = publisher
        .receive(on: options.scheduler)
        .eraseToAnyPublisher()
    }
    bind(publisher: publisher)
  }
  
  public init(object: T) {
    wrappedValue = object
    bind(publisher: objectDidChange.eraseToAnyPublisher())
  }
  
  private func bind(publisher: AnyPublisher<AnyPropertyChangeEvent, Never>) {
    subscriptions.insert(publisher.sink { [weak self] in
      self?.objectWillChange.send()
      guard $0.keyPath != nil else { return }
      self?.propertyDidChange.send($0)
    })
  }

  /// Subclasses to override this method.
  /// - note: Remember to invoke the `super` implementation.
  open func didSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    objectDidChange.send(AnyPropertyChangeEvent(object: wrappedValue, keyPath: keyPath))
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
  
  /// Replace the wrapped object with another instance.
  public func replace(object: T) {
    objectSubscriptions = Set<AnyCancellable>()
    objectLock.withWriteLock {
      self.wrappedValue = object
    }
    objectDidChange.send(AnyPropertyChangeEvent(object: wrappedValue, keyPath: nil))
  }
  
  public subscript<V>(dynamicMember keyPath: KeyPath<T, V>) -> V {
    get { get(keyPath: keyPath) }
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
    objectSubscriptions.insert(wrappedValue.propertyDidChange.sink { [weak self] change in
      self?.objectDidChange.send(change)
    })
  }
}

extension ObservableProxy where T: ObservableObject {
  /// Forwards the `ObservableObject.objectWillChangeSubscriber` to this proxy.
  func propagateObservableObject() {
    objectSubscriptions.insert(wrappedValue.objectWillChange.sink { [weak self] _ in
      guard let self = self else { return }
      self.objectDidChange.send(AnyPropertyChangeEvent(object: self.wrappedValue, keyPath: nil))
    })
  }
}
