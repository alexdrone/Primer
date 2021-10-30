import Foundation
import Logging
import Combine
#if canImport(SwiftUI)
import SwiftUI

/// Creates an observable proxy for the object passed as argument.
///
/// Mutations of the wrapped object performed via `get`, `set` or the dynamic keypath subscript
/// are thread-safe and trigger an event through the `objectWillChangeSubscriber` and
/// `propertyDidChangeSubscriber` streams.
@dynamicMemberLookup
open class ObservableStore<T>: ObservableObject, PropertyObservableObject, UncheckedSendable {
  
  public struct Options<S: Scheduler> {
    public enum SchedulingStrategy {
      /// The time the publisher should wait before publishing an element.
      case debounce(Double)
      /// The interval at which to find and emit either the most recent expressed in the time system
      /// of the scheduler.
      case throttle(Double)
      /// Events are being emitted as they're sent through the publisher.
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
  private let objectLock: Locking
  
  /// Subsystem logger.
  public private(set) lazy var logger: Logger = {
    let type = String(describing: T.self)
    let pointer = String(format:"%02x", Unmanaged.passUnretained(self).toOpaque().hashValue)
    let label = "\(type)(\(pointer))"
    return Logger(label: label)
  }()

  /// The wrapped object.
  private var object: Binding<T>

  /// The underlying value referenced by the binding variable.
  /// This property provides primary access to the value's data. However, you
  /// don't access `wrappedValue` directly.
  public var wrappedValue: T { object.wrappedValue }

  /// Internal subject used to propagate `objectWillChange` and `propertyDidChange` events.
  private var objectDidChange = PassthroughSubject<Void, Never>()
  
  private var subscriptions = Set<AnyCancellable>()
  private var objectSubscriptions = Set<AnyCancellable>()

  /// Constructs a new proxy for the object passed as argument.
  public init<S: Scheduler>(
    object: Binding<T>,
    objectLock: Locking = UnfairLock(),
    options: Options<S>
  ) {
    self.object = object
    self.objectLock = objectLock
    
    var objectWillChange: AnyPublisher = objectDidChange.eraseToAnyPublisher()
    let propertyDidChange: AnyPublisher = propertyDidChange.eraseToAnyPublisher()
    
    switch options.schedulingStrategy {
    case .debounce(let seconds):
      objectWillChange = objectWillChange
        .debounce(for: .seconds(seconds), scheduler: options.scheduler)
        .eraseToAnyPublisher()
    case .throttle(let seconds):
      objectWillChange = objectWillChange
        .throttle(for: .seconds(seconds), scheduler: options.scheduler, latest: true)
        .eraseToAnyPublisher()
    case .none:
      objectWillChange = objectWillChange
        .receive(on: options.scheduler)
        .eraseToAnyPublisher()
    }

    bind(objectWillChange: objectWillChange, propertyDidChange: propertyDidChange)
  }
  
  public init(
    object: Binding<T>,
    objectLock: Locking = UnfairLock()
  ) {
    self.object = object
    self.objectLock = objectLock
    
    let objectWillChange: AnyPublisher = objectDidChange.eraseToAnyPublisher()
    let propertyDidChange: AnyPublisher = propertyDidChange.eraseToAnyPublisher()
    bind(objectWillChange: objectWillChange, propertyDidChange: propertyDidChange)
  }
  
  /// Initialize the publisher bindings.
  private func bind(
    objectWillChange: AnyPublisher<Void, Never>,
    propertyDidChange: AnyPublisher<AnyPropertyChangeEvent, Never>
  ) {
    subscriptions.insert(propertyDidChange.sink { [weak self] in
      self?.objectDidChange.send()
      let property = $0.debugLabel != nil ? ".\($0.debugLabel!)" : "*"
      self?.logger.info("send { propertyDidChange(\(property)) }");
    });
    subscriptions.insert(objectWillChange.sink { [weak self] in
      self?.objectWillChange.send()
      self?.logger.info("send { objectWillChange }");
    })
  }
  
  /// Notifies the subscribers for the wrapped object changes.
  open func didSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    propertyDidChange.send(AnyPropertyChangeEvent(
      object: object.wrappedValue,
      keyPath: keyPath,
      debugLabel: keyPath.readableFormat))
  }
  
  /// Read the value of the property for the wrapped object.
  public func get<V>(keyPath: KeyPath<T, V>) -> V {
    objectLock.withLock {
      object.wrappedValue[keyPath: keyPath]
    }
  }
  
  /// Sets a new value for the property at the given keypath in the wrapped object.
  public func set<V>(keyPath: WritableKeyPath<T, V>, value: V, label: String = #function) {
    let oldValue = objectLock.withLock { () -> V in 
      let oldValue = object.wrappedValue[keyPath: keyPath]
      object.wrappedValue[keyPath: keyPath] = value
      return oldValue
    }
    let keyPathReadableFormat = keyPath.readableFormat ?? "unknown"
    let valueChangeFormat = "\(String(describing: oldValue)) ⟶ \(value)"
    logger.info("set @ [\(label)] .\(keyPathReadableFormat) = { \(valueChangeFormat) }")
    didSetValue(keyPath: keyPath, value: value)
  }
  
  /// Perfom a batch update to the wrapped object.
  public func mutate(_ mutation: (inout T) -> Void, label: String = #function) {
    objectLock.withLock {
      mutation(&object.wrappedValue)
    }
    logger.info("mutate @ [\(label)]")
    objectDidChange.send()
  }
  
  /// Returns a binding to one of the properties of the wrapped object.
  ///
  /// - Note: The returned binding can itself be used as the argument for a new
  /// `ObservableStore` instance.
  public func binding<V>(keyPath: WritableKeyPath<T, V>) -> Binding<V> {
    Binding(
      get: { self.get(keyPath: keyPath) },
      set: { self.set(keyPath: keyPath, value: $0) })
  }
  
  public subscript<V>(dynamicMember keyPath: KeyPath<T, V>) -> V {
    get { get(keyPath: keyPath) }
  }

  public subscript<V>(dynamicMember keyPath: WritableKeyPath<T, V>) -> V {
    get { get(keyPath: keyPath) }
    set { set(keyPath: keyPath, value: newValue, label: "dynamic_member") }
  }
}

// MARK: - Extensions

extension ObservableStore: Equatable where T: Equatable {
  public static func == (lhs: ObservableStore<T>, rhs: ObservableStore<T>) -> Bool {
    lhs.object.wrappedValue == rhs.object.wrappedValue
  }
}

extension ObservableStore: Hashable where T: Hashable {
  /// Hashes the essential components of this value by feeding them into the given hasher.
  public func hash(into hasher: inout Hasher) {
    object.wrappedValue.hash(into: &hasher)
  }
}

extension ObservableStore: Identifiable where T: Identifiable {
  /// The stable identity of the entity associated with this instance.
  public var id: T.ID { object.wrappedValue.id }
}

extension ObservableStore where T: PropertyObservableObject {
  /// Forwards the `ObservableObject.objectWillChangeSubscriber` to this proxy.
  func trampolinePropertyObservablePublisher() {
    objectSubscriptions.insert(object.wrappedValue.propertyDidChange.sink { [weak self] change in
      self?.propertyDidChange.send(change)
    })
  }
}

extension ObservableStore where T: ObservableObject {
  /// Forwards the `ObservableObject.objectWillChangeSubscriber` to this proxy.
  func trampolineObservableObjectPublisher() {
    objectSubscriptions.insert(object.wrappedValue.objectWillChange.sink { [weak self] _ in
      guard let self = self else { return }
      self.objectDidChange.send()
    })
  }
}

#endif
