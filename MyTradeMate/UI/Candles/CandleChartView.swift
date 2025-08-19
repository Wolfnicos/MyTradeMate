import SwiftUI
import Charts
import Foundation

// DashboardVM is defined in ViewModels/DashboardVM.swift

// Candle model is defined in Models/Candle.swift

struct CandlePoint: Identifiable {
    let id = UUID()
    let time: Date
    let open, high, low, close: Double
    
    var isGreen: Bool { close >= open }
}

struct CandlestickChartView: View {
    let data: [CandlePoint]
    
    var body: some View {
        Group {
            if data.isEmpty {
                // Empty state for charts when no data is available
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("No Chart Data")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("No candle data available for the selected timeframe")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No Chart Data. No candle data available for the selected timeframe")
            } else {
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
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// DashboardVM extension would be in ViewModels/DashboardVM.swift

#Preview {
    VStack {
        Text("Candle Chart Preview")
            .font(.headline)
        Text("Chart would be displayed here")
            .foregroundColor(.secondary)
    }
    .padding()
}