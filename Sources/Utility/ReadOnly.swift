import Foundation
import Combine

/// Constructs a type with all properties of T set to readonly, meaning the properties of
/// the constructed type cannot be reassigned.
/// - note: A read-only object propagetes observable changes from its wrapped object.
///
/// ```
/// struct Todo { var title: String; var description: String }
/// let todo = Todo(title: "A Title", description: "A Description")
/// let readOnlyTodo = ReadOnly(todo)
/// readOnlyTodo.title // "A title"
/// ```
///
@dynamicMemberLookup
@propertyWrapper
open class ReadOnly<T>:
  ReadOnlyProtocol,
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

extension ReadOnly where T: PropertyObservableObject {
  /// Forwards the `ObservableObject.objectWillChangeSubscriber` to this proxy.
  func propagatePropertyObservableObject() {
    propertyDidChangeSubscriber = wrappedValue.propertyDidChange.sink { [weak self] change in
      self?.propertyDidChange.send(change)
    }
  }
}

extension ReadOnly where T: ObservableObject {
  /// Forwards the `ObservableObject.objectWillChangeSubscriber` to this proxy.
  func propagateObservableObject() {
    objectWillChangeSubscriber = wrappedValue.objectWillChange.sink { [weak self] change in
      self?.objectWillChange.send()
    }
  }
}

// MARK: - Internal

public protocol ReadOnlyProtocol {
  associatedtype ProxyType
  /// The wrapped proxied object.
  var wrappedValue: ProxyType { get set }
}

extension ReadOnlyProtocol {
  /// Use `@dynamicMemberLookup` keypath subscript to forward the value of the proxied object.
  public subscript<V>(dynamicMember keyPath: KeyPath<ProxyType, V>) -> V {
    return wrappedValue[keyPath: keyPath]
  }
}
