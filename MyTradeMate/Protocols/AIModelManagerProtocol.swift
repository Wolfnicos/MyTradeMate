import Foundation
import CoreML

protocol AIModelManagerProtocol {
    var models: [AnyHashable: MLModel] { get }
    func validateModels() -> Bool
}
