import SwiftUI
import Charts

struct PnLDetailView: View {
    @StateObject private var vm = PnLVM()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with equity information
                HStack {
                    VStack(alignment: .leading) {
                        Text("Equity").font(.caption)
                        Text(vm.equity, format: .currency(code: "USD"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                            .monospacedDigit()
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Today (realized)").font(.caption)
                        Text(formatPnL(vm.today))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(vm.today >= 0 ? .green : .red)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                            .monospacedDigit()
                    }
                }
            
                // Unrealized PnL and timeframe picker
                HStack {
                    VStack(alignment: .leading) {
                        Text("Unrealized").font(.caption)
                        Text(formatPnL(vm.unrealized))
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(vm.unrealized >= 0 ? .green : .red)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                            .monospacedDigit()
                    }
                    
                    Spacer()
                    
                    Picker("Timeframe", selection: $vm.timeframe) {
                        ForEach(Timeframe.allCases, id: \.rawValue) { tf in
                            Text(tf.rawValue).tag(tf)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 200)
                    .onChange(of: vm.timeframe) { newValue in
                        vm.setTimeframe(newValue)
                        print("🖥️ PnL timeframe=\(newValue.rawValue)")
                    }
                }
            
            Group {
                if vm.isLoading {
                    // Loading state for P&L calculations
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                            
                            Text("Calculating performance...")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                } else if vm.history.isEmpty {
                    // Empty state for P&L charts when no trading data exists
                    VStack(spacing: 16) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("No P&L History")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Your profit and loss chart will appear here once you start trading")
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
                    .accessibilityLabel("No P&L History. Your profit and loss chart will appear here once you start trading")
                } else {
                    VStack(spacing: 12) {
                        // Chart legend explaining what the chart shows
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Equity Over Time")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("Shows your account balance changes over time")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 8, height: 8)
                                    Text("Profit")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 8, height: 8)
                                    Text("Loss")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        
                        Chart {
                            ForEach(Array(vm.history.enumerated()), id: \.offset) { index, item in
                                LineMark(
                                    x: .value("Time", item.0),
                                    y: .value("Equity", item.1)
                                )
                                .foregroundStyle(vm.equity >= 10000 ? .green : .red)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .hour, count: vm.timeframeHours)) { value in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)).minute())
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .currency(code: "USD"))
                            }
                        }
                        .frame(height: 280)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 8)
            
            // Performance metrics summary
            VStack(spacing: 16) {
                HStack {
                    Text("Performance Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                if let metrics = vm.performanceMetrics, metrics.trades > 0 {
                    VStack(spacing: 12) {
                        // First row: Trades and Win Rate
                        HStack(spacing: 16) {
                            MetricCardView(
                                title: "Total Trades",
                                value: "\(metrics.trades)",
                                color: .primary
                            )
                            
                            MetricCardView(
                                title: "Win Rate",
                                value: "\(Int(metrics.winRate * 100))%",
                                color: metrics.winRate >= 0.5 ? .green : .red
                            )
                        }
                        
                        // Second row: Net P&L and Max Drawdown
                        HStack(spacing: 16) {
                            MetricCardView(
                                title: "Net P&L",
                                value: formatCurrency(metrics.netPnL),
                                color: metrics.netPnL >= 0 ? .green : .red
                            )
                            
                            MetricCardView(
                                title: "Max Drawdown",
                                value: formatCurrency(metrics.maxDrawdown),
                                color: .red
                            )
                        }
                        
                        // Third row: Average Win/Loss
                        HStack(spacing: 16) {
                            MetricCardView(
                                title: "Avg Win",
                                value: formatCurrency(metrics.avgWin),
                                color: .green
                            )
                            
                            MetricCardView(
                                title: "Avg Loss",
                                value: formatCurrency(metrics.avgLoss),
                                color: .red
                            )
                        }
                    }
                } else {
                    // Empty state when no trades exist
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        
                        Text("No Trading Data")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Performance metrics will appear here after you complete some trades")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.bottom, 20)
            
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
        .navigationTitle("PnL")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
    
    private func formatPnL(_ v: Double) -> String {
        let sign = v >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", v))"
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        
        if abs(value) >= 1000 {
            formatter.maximumFractionDigits = 0
        }
        
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

struct MetricCardView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}
