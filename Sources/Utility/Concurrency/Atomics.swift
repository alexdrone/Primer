import Foundation
import Atomics

#if swift(<5.5)
public protocol UnsafeSendable { }
#endif
/// The `UncheckedSendable` protocol indicates that value of the given type can be safely used
/// in concurrent code, but disables some safety checking at the conformance site.
public protocol UncheckedSendable: UnsafeSendable { }

extension ManagedAtomic: UncheckedSendable { }
