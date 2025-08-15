import SwiftUI
import Charts

struct CandlePoint: Identifiable {
    let id = UUID()
    let time: Date
    let open, high, low, close: Double
    
    var isGreen: Bool { close >= open }
}

struct CandleChartView: View {
    let data: [CandlePoint]
    
    var body: some View {
        Chart {
            ForEach(data) { candle in
                // Wicks (high-low range)
                RuleMark(
                    x: .value("Time", candle.time),
                    yStart: .value("Low", candle.low),
                    yEnd: .value("High", candle.high)
                )
                .foregroundStyle(.secondary)
                .lineStyle(.init(lineWidth: 1))
                
                // Body (open-close range) 
                RectangleMark(
                    x: .value("Time", candle.time),
                    yStart: .value("Open", min(candle.open, candle.close)),
                    yEnd: .value("Close", max(candle.open, candle.close)),
                    width: .fixed(8)
                )
                .foregroundStyle(candle.isGreen ? .green : .red)
                .opacity(0.8)
                
                // Handle doji candles (open == close)
                if abs(candle.open - candle.close) < 0.01 {
                    RuleMark(
                        x: .value("Time", candle.time),
                        yStart: .value("Price", candle.open),
                        yEnd: .value("Price", candle.open)
                    )
                    .foregroundStyle(.secondary)
                    .lineStyle(.init(lineWidth: 2))
                }
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: .automatic(desiredCount: 5)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.hour().minute())
                            .font(.caption)
                    }
                    AxisGridLine()
                    AxisTick()
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 6)) { value in
                if let price = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(price, specifier: "%.0f")")
                            .font(.caption)
                    }
                    AxisGridLine()
                    AxisTick()
                }
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension DashboardVM {
    var chartData: [CandlePoint] {
        candles.suffix(50).map { candle in
            CandlePoint(
                time: candle.openTime,
                open: candle.open,
                high: candle.high,
                low: candle.low,
                close: candle.close
            )
        }
    }
}

#Preview {
    let sampleData = (0..<20).map { i in
        let basePrice = 45000.0
        let time = Date().addingTimeInterval(-Double(i * 300))
        let volatility = basePrice * 0.01
        
        let open = basePrice + Double.random(in: -volatility...volatility)
        let close = open + Double.random(in: -volatility/2...volatility/2)
        let high = max(open, close) + Double.random(in: 0...volatility/3)
        let low = min(open, close) - Double.random(in: 0...volatility/3)
        
        return CandlePoint(time: time, open: open, high: high, low: low, close: close)
    }.reversed()
    
    return CandleChartView(data: sampleData)
        .padding()
}