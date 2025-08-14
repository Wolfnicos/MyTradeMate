import Foundation

func safeTask(priority: TaskPriority = .userInitiated, _ body: @escaping @Sendable () async -> Void) {
    Task(priority: priority) {
        await body()
    }
}
