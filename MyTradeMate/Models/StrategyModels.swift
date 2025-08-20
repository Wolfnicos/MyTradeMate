import Foundation

// MARK: - Strategy Info Model
public struct StrategyInfo: Identifiable, Codable {
    public let id: String
    public let name: String
    public let description: String
    public var isEnabled: Bool
    public var weight: Double
    public var parameters: [StrategyParameter]
    
    public init(id: String, name: String, description: String, isEnabled: Bool = true, weight: Double = 1.0, parameters: [StrategyParameter] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.isEnabled = isEnabled
        self.weight = weight
        self.parameters = parameters
    }
}

// MARK: - Strategy Parameter Model
public struct StrategyParameter: Identifiable, Codable {
    public enum ParameterType: String, Codable {
        case slider
        case stepper
        case textField
    }
    
    public let id: String
    public let name: String
    public let type: ParameterType
    public var value: Double
    public let minValue: Double
    public let maxValue: Double
    public let step: Double
    
    public init(id: String, name: String, type: ParameterType, value: Double, minValue: Double = 0, maxValue: Double = 100, step: Double = 1) {
        self.id = id
        self.name = name
        self.type = type
        self.value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.step = step
    }
}