import Foundation

public protocol PartialProtocol {
  associatedtype ObjectType
  /// The initial instance that is going to be used by the builder.
  var createInstanceClosure: () -> ObjectType { get }
  /// All of the `set` commands that will performed once the object is built.
  var keypathSetValueDictionary: [AnyKeyPath: (inout ObjectType) -> Void] { get set }
  /// All of the values currently set in this partial.
  var keypathGetValueDictionary: [AnyKeyPath: Any] { get set }
}

extension PartialProtocol {
  /// Use `@dynamicMemberLookup` keypath subscript to store the object configuration and postpone
  /// the object construction.
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<ObjectType, T>) -> T? {
    get {
      return keypathGetValueDictionary[keyPath] as? T
    }
    set {
      guard let newValue = newValue else {
        keypathGetValueDictionary.removeValue(forKey: keyPath)
        keypathSetValueDictionary.removeValue(forKey: keyPath)
        return
      }
      keypathGetValueDictionary[keyPath] = newValue
      keypathSetValueDictionary[keyPath] = { object in
        object[keyPath: keyPath] = newValue
      }
    }
  }

  /// Build the target object.
  fileprivate func buildObject() -> ObjectType {
    var obj = createInstanceClosure()
    for (_, setValueClosure) in keypathSetValueDictionary {
      setValueClosure(&obj)
    }
    return obj
  }
}

@dynamicMemberLookup
open class Partial<T>: PartialProtocol {
  public let createInstanceClosure: () -> T
  public var keypathSetValueDictionary: [AnyKeyPath: (inout T) -> Void] = [:]
  public var keypathGetValueDictionary: [AnyKeyPath: Any] = [:]

  init(createInstanceClosure: @escaping () -> T) {
    self.createInstanceClosure = createInstanceClosure
  }

  /// Build the target object.
  open func build() -> T {
    return buildObject()
  }
}
