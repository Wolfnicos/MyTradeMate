import SwiftUI
import Charts
import Foundation // for Date, Calendar, NumberFormatter

// Define PnLDateFilter here to avoid import issues
enum PnLDateFilter: String, CaseIterable, Identifiable {
    case all = "All Time"
    case today = "Today"
    case week = "7 Days"
    case month = "30 Days"
    case quarter = "90 Days"
    
    var id: String { rawValue }
    
    var dateRange: (Date?, Date?) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .all:
            return (nil, nil)
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now)
        case .week:
            return (calendar.date(byAdding: .day, value: -7, to: now), now)
        case .month:
            return (calendar.date(byAdding: .day, value: -30, to: now), now)
        case .quarter:
            return (calendar.date(byAdding: .day, value: -90, to: now), now)
        }
    }
}

// MARK: - Formatting helpers accessible to all subviews
fileprivate func formatPnL(_ value: Double) -> String {
    let sign = value >= 0 ? "+" : ""
    return "\(sign)\(String(format: "%.2f", value))"
}

fileprivate func formatCurrency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    formatter.maximumFractionDigits = abs(value) >= 1000 ? 0 : 2
    return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
}

// MARK: - Header Components
private struct EquityView: View {
    let equity: Double
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Equity").font(.caption)
            Text(formatCurrency(equity))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .monospacedDigit()
        }
    }
}

private struct TodayPnLView: View {
    let today: Double
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text("Today (realized)").font(.caption)
            Text(formatPnL(today))
                .font(.title3.weight(.semibold))
                .foregroundStyle(today >= 0 ? .green : .red)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .monospacedDigit()
        }
    }
}

private struct UnrealizedPnLView: View {
    let unrealized: Double
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Unrealized").font(.caption)
            Text(formatPnL(unrealized))
                .font(.headline.weight(.semibold))
                .foregroundStyle(unrealized >= 0 ? .green : .red)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .monospacedDigit()
        }
    }
}

private struct TimeframePickerView: View {
    @Binding var timeframe: Timeframe
    let onTimeframeChange: (Timeframe) -> Void
    
    var body: some View {
        Picker("Timeframe", selection: $timeframe) {
            ForEach(Timeframe.allCases, id: \.rawValue) { tf in
                Text(tf.rawValue).tag(tf)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 200)
        .onChange(of: timeframe) { _, newValue in
            onTimeframeChange(newValue)
        }
    }
}

private struct DateFilterView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Date Range")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("Date Filter", selection: .constant(PnLDateFilter.all)) {
                ForEach(PnLDateFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.menu)
            .disabled(true)
        }
    }
}

private struct SymbolFilterView: View {
    let selection: Binding<String>
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Symbol")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("Symbol Filter", selection: selection) {
                ForEach(options, id: \.self) { symbol in
                    Text(symbol).tag(symbol)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

struct PnLDetailView: View {
    var body: some View {
        PnLDetailContentView()
    }
}

struct PnLDetailContentView: View {
    @EnvironmentObject var pnlVM: PnLVM
    @State private var selectedSymbol: String = "All"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                controlsSection
                chartSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
        .navigationTitle("PnL")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedSymbol = pnlVM.symbolFilter
            pnlVM.start()
        }
        .onDisappear { pnlVM.stop() }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Header with equity information
            HStack {
                EquityView(equity: pnlVM.equity)
                Spacer()
                TodayPnLView(today: pnlVM.today)
            }
            
            // Unrealized PnL and timeframe picker
            HStack {
                UnrealizedPnLView(unrealized: pnlVM.unrealized)
                Spacer()
                TimeframePickerView(timeframe: $pnlVM.timeframe, onTimeframeChange: { newValue in
                    pnlVM.setTimeframe(newValue)
                    print("🖥️ PnL timeframe=\(newValue.rawValue)")
                })
            }
        }
    }
    
    private var controlsSection: some View {
        HStack(spacing: 16) {
            DateFilterView()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Symbol")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Symbol Filter", selection: $selectedSymbol) {
                    ForEach(pnlVM.availableSymbols, id: \.self) { symbol in
                        Text(symbol).tag(symbol)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedSymbol) { _, newValue in
                    pnlVM.updateSymbolFilter(newValue)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var chartSection: some View {
        Group {
            if pnlVM.isLoading {
                loadingView
            } else if pnlVM.history.isEmpty {
                emptyStateView
            } else {
                equityChartView
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.bottom, 20)
    }
    
    private var loadingView: some View {
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
    }
    
    private var emptyStateView: some View {
        Text("No P&L History")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.primary)
    }
    
    private var equityChartView: some View {
        VStack(spacing: 12) {
            chartLegendView
            equityChart
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var chartLegendView: some View {
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
    }
    
    private var equityChart: some View {
        Chart {
            ForEach(pnlVM.history.indices, id: \.self) { index in
                let item = pnlVM.history[index]
                LineMark(
                    x: .value("Time", item.0),
                    y: .value("Equity", item.1)
                )
                .foregroundStyle(pnlVM.equity >= 10000 ? .green : .red)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: pnlVM.timeframeHours)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .frame(height: 240)
    }
}

struct TradingMetricCardView: View {
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
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
    }
}
