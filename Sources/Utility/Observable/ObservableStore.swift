import Foundation
import Logging
import Combine
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
    let label = "ObservableStore.\(type(of: T.self)).\(Unmanaged.passUnretained(self).toOpaque())"
    return Logger(label: label)
  }()

  /// The wrapped object.
  private var object: Binding<T>
  public var wrappedValue: T { object.wrappedValue }
  public var projectedValue: ObservableStore<T> { self }

  /// Internal subject used to propagate `objectWillChange` and `propertyDidChange` events.
  private var objectDidChange = PassthroughSubject<AnyPropertyChangeEvent, Never>()
  
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
  
  public init(object: Binding<T>) {
    self.object = object
    self.objectLock = UnfairLock()
    bind(publisher: objectDidChange.eraseToAnyPublisher())
  }
  
  private func bind(publisher: AnyPublisher<AnyPropertyChangeEvent, Never>) {
    subscriptions.insert(publisher.sink { [weak self] in
      self?.objectWillChange.send()
      guard $0.keyPath != nil else { return }
      self?.propertyDidChange.send($0)
    })
  }
  
  open func didSetValue<V>(keyPath: KeyPath<T, V>, value: V) {
    objectDidChange.send(AnyPropertyChangeEvent(object: object.wrappedValue, keyPath: keyPath))
  }
  
  public func read<V>(keyPath: KeyPath<T, V>) -> V {
    objectLock.withLock {
      object.wrappedValue[keyPath: keyPath]
    }
  }
  
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
  
  public func mutate(_ mutation: (inout T) -> Void, label: String = #function) {
    objectLock.withLock {
      mutation(&object.wrappedValue)
    }
    logger.info("mutation @ [\(label)]")
    objectDidChange.send(AnyPropertyChangeEvent(object: object.wrappedValue, keyPath: nil))
  }
  
  /// Replace the wrapped object with another instance.
  public func replace(object: T) {
    objectSubscriptions = Set<AnyCancellable>()
    objectLock.withLock {
      self.object.wrappedValue = object
    }
    objectDidChange.send(AnyPropertyChangeEvent(object: object, keyPath: nil))
  }
  
  public subscript<V>(dynamicMember keyPath: KeyPath<T, V>) -> V {
    get { read(keyPath: keyPath) }
  }
  public subscript<V>(dynamicMember keyPath: WritableKeyPath<T, V>) -> V {
    get { read(keyPath: keyPath) }
    set { set(keyPath: keyPath, value: newValue) }
  }
}

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
      self?.objectDidChange.send(change)
    })
  }
}

extension ObservableStore where T: ObservableObject {
  /// Forwards the `ObservableObject.objectWillChangeSubscriber` to this proxy.
  func trampolineObservableObjectPublisher() {
    objectSubscriptions.insert(object.wrappedValue.objectWillChange.sink { [weak self] _ in
      guard let self = self else { return }
      self.objectDidChange.send(
        AnyPropertyChangeEvent(object: self.object.wrappedValue, keyPath: nil))
    })
  }
}
