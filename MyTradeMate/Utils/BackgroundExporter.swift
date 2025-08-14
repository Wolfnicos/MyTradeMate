import Foundation

public enum BackgroundExporter {
    /// Runs work on a detached background task; calls completion on main actor.
    public static func run<T>(
        work: @escaping () throws -> T,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        Task.detached(priority: .utility) {
            do {
                let result = try work()
                await MainActor.run { completion(.success(result)) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
}
