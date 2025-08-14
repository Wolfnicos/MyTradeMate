import Foundation

public struct Account: Codable, Sendable {
    public var equity: Double
    public var cash: Double
    public var positions: [Position]
    public var balances: [Balance]
    
    public init(equity: Double, cash: Double, positions: [Position] = [], balances: [Balance] = []) {
        self.equity = equity
        self.cash = cash
        self.positions = positions
        self.balances = balances
    }
}

public struct Balance: Codable, Sendable {
    public let asset: String
    public let free: Double
    public let locked: Double
    
    public init(asset: String, free: Double, locked: Double) {
        self.asset = asset
        self.free = free
        self.locked = locked
    }
}