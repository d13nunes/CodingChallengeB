import Foundation

enum DependencyScope {
    /// A single instance is created on the first fetch, cached, and reused forever.
    case shared
    /// A brand new instance is created and returned every single time.
    case ephemeral
}

final class DependencyContainer {
    static let shared = DependencyContainer()

    /// We only store factories (how to make the objects) at registration
    private var factories: [ObjectIdentifier: () -> Any] = [:]

    /// We store the actual shared instances as they are fetched lazily
    private var sharedInstances: [ObjectIdentifier: Any] = [:]

    /// The lock is strictly required again to protect `sharedInstances`
    private let lock = NSLock()

    private init() {}

    /// Registers ONLY the blueprint (factory) for the dependency.
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }

        let key = ObjectIdentifier(type)
        factories[key] = factory
    }

    /// Resolves the dependency, allowing the caller to decide the scope.
    func resolve<T>(_ type: T.Type, scope: DependencyScope = .ephemeral) -> T {
        lock.lock()
        defer { lock.unlock() }

        let key = ObjectIdentifier(type)

        // Ensure we actually know how to build this type
        guard let factory = factories[key] else {
            fatalError("No factory registered for \(type).")
        }

        switch scope {
        case .shared:
            // 1. If it already exists, return it
            if let existingInstance = sharedInstances[key] as? T {
                return existingInstance
            }

            // 2. If it doesn't exist, build it, cache it, and return it
            guard let newInstance = factory() as? T else {
                fatalError("Factory for \(type) returned the wrong type.")
            }
            sharedInstances[key] = newInstance
            return newInstance

        case .ephemeral:
            // Just build a new one and return it directly. Do not cache it.
            guard let newInstance = factory() as? T else {
                fatalError("Factory for \(type) returned the wrong type.")
            }
            return newInstance
        }
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        factories.removeAll()
        sharedInstances.removeAll()
    }
}
