# MyTradeMate Project Analysis

## Project Tree Structure

```
MyTradeMate/
├── MyTradeMateApp.swift
├── AI/
│   ├── FeatureBuilder.swift
├── AI/StrategyEngine/
│   ├── BreakoutStrategy.swift
│   ├── EMAStrategy.swift
│   ├── EnsembleDecider.swift
│   ├── MACDStrategy.swift
│   ├── MeanReversionStrategy.swift
│   ├── RSIStrategy.swift
│   ├── RegimeDetector.swift
│   ├── Strategy.swift
│   ├── StrategyEngine.swift
│   ├── StrategyManager.swift
├── Core/
│   ├── AppConfig.swift
│   ├── AppError.swift
│   ├── BinanceClient.swift
│   ├── BinanceExchangeClient.swift
│   ├── BinanceModels.swift
│   ├── ErrorManager.swift
│   ├── KeychainStore.swift
│   ├── KrakenClient.swift
│   ├── KrakenExchangeClient.swift
│   ├── KrakenModels.swift
│   ├── Logger.swift
│   ├── NavigationCoordinator.swift
│   ├── SignalEngine.swift
│   ├── SymbolCatalog.swift
│   ├── TradeStore.swift
│   ├── TrialManager.swift
│   ├── WebSocketManager.swift
│   ├── WidgetDataManager.swift
├── Core/Data/
│   ├── SymbolCatalog.swift
├── Core/DependencyInjection/
│   ├── ServiceContainer.swift
│   ├── ServiceProtocols.swift
│   ├── ViewModelFactory.swift
├── Core/Exchange/
│   ├── BinanceClient.swift
│   ├── BinanceExchangeClient.swift
│   ├── BinanceModels.swift
│   ├── KrakenClient.swift
│   ├── KrakenExchangeClient.swift
│   ├── KrakenModels.swift
│   ├── WebSocketManager.swift
├── Core/Performance/
│   ├── ConnectionManager.swift
│   ├── DataCacheManager.swift
│   ├── InferenceThrottler.swift
│   ├── MemoryPressureManager.swift
│   ├── PerformanceOptimizer.swift
├── Core/Trading/
│   ├── SignalEngine.swift
│   ├── TradeStore.swift
├── Core/Utilities/
│   ├── HapticFeedback.swift
├── Diagnostics/
│   ├── Audit.swift
│   ├── CoreMLInspector.swift
│   ├── Log.swift
├── Managers/
│   ├── MarketPriceCache.swift
│   ├── OrderStatusTracker.swift
│   ├── PnLManager.swift
│   ├── RiskManager.swift
│   ├── StopMonitor.swift
│   ├── TradeManager.swift
├── Models/
│   ├── Account.swift
│   ├── AppSettings.swift
│   ├── Candle.swift
│   ├── Exchange.swift
│   ├── LegacyStrategy.swift
│   ├── Order.swift
│   ├── OrderFill.swift
│   ├── OrderRequest.swift
│   ├── OrderSide.swift
│   ├── OrderStatus.swift
│   ├── OrderTypes.swift
│   ├── Position.swift
│   ├── PredictionResult.swift
│   ├── PriceTick.swift
│   ├── RiskModels.swift
│   ├── Signal.swift
│   ├── SignalInfo.swift
│   ├── Symbol.swift
│   ├── Ticker.swift
│   ├── Timeframe.swift
│   ├── TradeRequest.swift
│   ├── TradingMode.swift
├── Protocols/
│   ├── AIModelManagerProtocol.swift
│   ├── ModelKind.swift
├── Scripts/
│   ├── final_build_validation.swift
│   ├── final_compilation_test.swift
│   ├── final_fix_summary.swift
│   ├── optional_unwrap_fix.swift
│   ├── run_widget_performance_tests.swift
│   ├── test_ai_integration.swift
│   ├── test_aimanager.swift
│   ├── test_async_fix.swift
│   ├── test_compilation.swift
│   ├── test_final_build.swift
│   ├── test_simple_build.swift
│   ├── validate_build.swift
│   ├── validate_widget_performance.swift
├── Security/
│   ├── KeychainStore.swift
│   ├── NetworkSecurityManager.swift
├── Services/
│   ├── AIModelManager.swift
│   ├── BinanceLiveClient.swift
│   ├── Calibration.swift
│   ├── CandleProvider.swift
│   ├── Conformal.swift
│   ├── ExchangeClient.swift
│   ├── KrakenLiveClient.swift
│   ├── MarketDataService.swift
│   ├── MetaConfidence.swift
│   ├── ModeEngine.swift
│   ├── PaperExchangeClient.swift
│   ├── SimpleUIAdapter.swift
│   ├── TradingTypes.swift
│   ├── Uncertainty.swift
├── Services/AI/
│   ├── CalibrationUtils.swift
│   ├── ConformalGate.swift
│   ├── MetaConfidenceCalculator.swift
│   ├── ModeEngine.swift
│   ├── UIAdapter.swift
│   ├── UncertaintyModule.swift
├── Services/Data/
│   ├── CandleProvider.swift
│   ├── MarketDataService.swift
├── Services/Exchange/
│   ├── BinanceLiveClient.swift
│   ├── ExchangeClient.swift
│   ├── KrakenLiveClient.swift
│   ├── PaperExchangeClient.swift
├── Settings/
│   ├── AppConfig.swift
│   ├── AppSettings.swift
│   ├── SettingsValidator.swift
├── Strategies/
│   ├── LegacyStrategy.swift
├── Strategies/Implementations/
│   ├── BreakoutStrategy.swift
│   ├── EMAStrategy.swift
│   ├── EnsembleDecider.swift
│   ├── MACDStrategy.swift
│   ├── MeanReversionStrategy.swift
│   ├── RSIStrategy.swift
│   ├── RegimeDetector.swift
│   ├── Strategy.swift
│   ├── StrategyManager.swift
├── Tests/
│   ├── TestReportGenerator.swift
│   ├── ValidationSuite.swift
├── Tests/Integration/
│   ├── BinanceIntegrationTests.swift
│   ├── EmptyStatePerformanceIntegrationTests.swift
│   ├── FinalIntegrationTest.swift
│   ├── IntegrationTestSuite.swift
│   ├── KrakenIntegrationTests.swift
│   ├── PerformanceOptimizationIntegrationTests.swift
│   ├── WebSocketIntegrationTests.swift
│   ├── WidgetBatteryImpactIntegrationTests.swift
├── Tests/Mocks/
│   ├── MockServices.swift
├── Tests/Unit/
│   ├── AIMLTestSuite.swift
│   ├── ChartTooltipLegendTests.swift
│   ├── ConfirmationDialogTests.swift
│   ├── CoreMLModelTests.swift
│   ├── CoreTradingLogicTestSuite.swift
│   ├── CredentialValidationTests.swift
│   ├── EmptyStateIllustrationsPerformanceTests.swift
│   ├── EmptyStateIllustrationsTests.swift
│   ├── EmptyStatePerformanceValidation.swift
│   ├── EmptyStateTests.swift
│   ├── FeaturePreparationTests.swift
│   ├── HelpIconViewTests.swift
│   ├── ImageOptimizationTests.swift
│   ├── KeychainStoreTests.swift
│   ├── LoadingStateViewTests.swift
│   ├── LogExporterTests.swift
│   ├── OrderExecutionTests.swift
│   ├── OrderStatusTrackingTests.swift
│   ├── PnLFilteringTests.swift
│   ├── PnLLoadingStateTests.swift
│   ├── PnLPerformanceMetricsTests.swift
│   ├── PositionTrackingTests.swift
│   ├── PredictionHandlingTests.swift
│   ├── RiskManagementTests.swift
│   ├── SecureDataHandlingTests.swift
│   ├── SecurityTestSuite.swift
│   ├── SettingsSearchTests.swift
│   ├── SignalVisualizationViewTests.swift
│   ├── TabIconTests.swift
│   ├── TimeframeStandardizationTests.swift
│   ├── ToastViewTests.swift
│   ├── TradeConfirmationDialogTests.swift
│   ├── TradeExecutionErrorHandlingTests.swift
│   ├── TradeExecutionLoadingStateTests.swift
│   ├── TradeExecutionToastTests.swift
│   ├── TradeFilteringSortingTests.swift
│   ├── TradingModeIndicatorTests.swift
│   ├── WidgetConfigurationTests.swift
│   ├── WidgetDataManagerTests.swift
│   ├── WidgetPerformanceTests.swift
├── Themes/
│   ├── ThemeManager.swift
├── UI/Candles/
│   ├── CandleChartView.swift
├── UI/Charts/
│   ├── CandlestickChart.swift
├── Utils/
│   ├── BackgroundExporter.swift
│   ├── CSVExporter+PnLMetrics.swift
│   ├── CSVExporter.swift
│   ├── DateFormatter+Extensions.swift
│   ├── EmptyStatePerformanceMonitor.swift
│   ├── Haptics.swift
│   ├── ImageOptimizer.swift
│   ├── JSONExporter.swift
│   ├── KeychainHelper.swift
│   ├── LogExporter.swift
│   ├── PnLAggregator.swift
│   ├── PnLCSVExporter.swift
│   ├── PnLMetrics.swift
│   ├── PredictionLogger.swift
│   ├── SafeTask.swift
│   ├── TabIconValidator.swift
│   ├── TimeframeValidator.swift
├── ViewModels/
│   ├── DashboardVM.swift
│   ├── PnLVM.swift
│   ├── SettingsVM.swift
│   ├── StrategiesVM.swift
│   ├── TradeHistoryVM.swift
│   ├── TradesVM.swift
├── ViewModels/Components/
│   ├── MarketDataManager.swift
│   ├── RegimeDetectionManager.swift
│   ├── SignalManager.swift
│   ├── StrategyConfigurationManager.swift
│   ├── TradeConfirmationViewModel.swift
│   ├── TradingManager.swift
├── ViewModels/Dashboard/
│   ├── DashboardVM.swift
│   ├── RefactoredDashboardVM.swift
├── ViewModels/Settings/
│   ├── ExchangeKeysViewModel.swift
│   ├── SettingsVM.swift
├── ViewModels/Strategies/
│   ├── RefactoredStrategiesVM.swift
│   ├── StrategiesVM.swift
│   ├── StrategiesViewModel.swift
├── ViewModels/Trading/
│   ├── PnLVM.swift
│   ├── TradeHistoryVM.swift
│   ├── TradesVM.swift
├── Views/
│   ├── DashboardView.swift
│   ├── DesignSystem.swift
│   ├── ExchangeKeysView.swift
│   ├── PnLDetailView.swift
│   ├── RootTabs.swift
│   ├── SettingsView.swift
│   ├── StrategiesView.swift
│   ├── TradeHistoryView.swift
│   ├── TradesView.swift
├── Views/Components/
│   ├── AccountDeletionConfirmationDialog.swift
│   ├── ActiveOrdersView.swift
│   ├── ButtonStylePreview.swift
│   ├── ChartExplanation.swift
│   ├── ChartLegend.swift
│   ├── ChartTooltip.swift
│   ├── ConfirmationDialog.swift
│   ├── EmptyStateIllustrationHelpers.swift
│   ├── EmptyStateIllustrationsTestView.swift
│   ├── EmptyStateView.swift
│   ├── HelpIconView.swift
│   ├── IllustratedEmptyStateView.swift
│   ├── LoadingStateView.swift
│   ├── OrderStatusView.swift
│   ├── PnLWidget.swift
│   ├── SettingsConfirmationDialog.swift
│   ├── SignalVisualizationView.swift
│   ├── StrategyConfirmationDialog.swift
│   ├── TabIconPreview.swift
│   ├── ToastDemoView.swift
│   ├── ToastManager.swift
│   ├── ToastView.swift
│   ├── ToggleStylePreview.swift
│   ├── TradeConfirmationDialog.swift
│   ├── TradingModeIndicator.swift
├── Views/Dashboard/
│   ├── DashboardView.swift
├── Views/Debug/
│   ├── PerformanceMonitorView.swift
│   ├── ValidationView.swift
├── Views/Settings/
│   ├── ExchangeKeysView.swift
│   ├── SettingsView.swift
├── Views/Settings/Sections/
│   ├── AISection.swift
│   ├── DiagnosticsSection.swift
│   ├── ExchangesSection.swift
│   ├── InterfaceSection.swift
│   ├── MarketDataSection.swift
│   ├── StrategiesSection.swift
│   ├── TradingSection.swift
├── Views/Settings/Sheets/
│   ├── BinanceKeysView.swift
│   ├── KrakenKeysView.swift
│   ├── WidgetConfigurationView.swift
├── Views/Shared/
│   ├── ShareSheet.swift
├── Views/Strategies/
│   ├── StrategiesView.swift
├── Views/Trading/
│   ├── PnLDetailView.swift
│   ├── TradeHistoryView.swift
│   ├── TradesView.swift
```

## File Analysis

| File | On Disk | In PBXProj | In Sources | Notes/Action |
|------|---------|------------|------------|-------------|
| MyTradeMateWidget.swift | ❌ | ✅ | ✅ | Remove from project or restore file |
| SmokeTests.swift | ❌ | ✅ | ✅ | Remove from project or restore file |
| AIMLTestSuite.swift | ✅ | ❌ | ❌ | Add to project |
| AccountDeletionConfirmationDialog.swift | ✅ | ❌ | ❌ | Add to project |
| ActiveOrdersView.swift | ✅ | ❌ | ❌ | Add to project |
| BinanceIntegrationTests.swift | ✅ | ❌ | ❌ | Add to project |
| ButtonStylePreview.swift | ✅ | ❌ | ❌ | Add to project |
| Calibration.swift | ✅ | ❌ | ❌ | Add to project |
| CalibrationUtils.swift | ✅ | ❌ | ❌ | Add to project |
| ChartExplanation.swift | ✅ | ❌ | ❌ | Add to project |
| ChartLegend.swift | ✅ | ❌ | ❌ | Add to project |
| ChartTooltip.swift | ✅ | ❌ | ❌ | Add to project |
| ChartTooltipLegendTests.swift | ✅ | ❌ | ❌ | Add to project |
| ConfirmationDialog.swift | ✅ | ❌ | ❌ | Add to project |
| ConfirmationDialogTests.swift | ✅ | ❌ | ❌ | Add to project |
| Conformal.swift | ✅ | ❌ | ❌ | Add to project |
| ConformalGate.swift | ✅ | ❌ | ❌ | Add to project |
| ConnectionManager.swift | ✅ | ❌ | ❌ | Add to project |
| CoreMLModelTests.swift | ✅ | ❌ | ❌ | Add to project |
| CoreTradingLogicTestSuite.swift | ✅ | ❌ | ❌ | Add to project |
| CredentialValidationTests.swift | ✅ | ❌ | ❌ | Add to project |
| DataCacheManager.swift | ✅ | ❌ | ❌ | Add to project |
| EmptyStateIllustrationHelpers.swift | ✅ | ❌ | ❌ | Add to project |
| EmptyStateIllustrationsPerformanceTests.swift | ✅ | ❌ | ❌ | Add to project |
| EmptyStateIllustrationsTestView.swift | ✅ | ❌ | ❌ | Add to project |
| EmptyStateIllustrationsTests.swift | ✅ | ❌ | ❌ | Add to project |
| EmptyStatePerformanceIntegrationTests.swift | ✅ | ❌ | ❌ | Add to project |
| EmptyStatePerformanceMonitor.swift | ✅ | ❌ | ❌ | Add to project |
| EmptyStatePerformanceValidation.swift | ✅ | ❌ | ❌ | Add to project |
| EmptyStateTests.swift | ✅ | ❌ | ❌ | Add to project |
| EmptyStateView.swift | ✅ | ❌ | ❌ | Add to project |
| ExchangeKeysViewModel.swift | ✅ | ❌ | ❌ | Add to project |
| FeaturePreparationTests.swift | ✅ | ❌ | ❌ | Add to project |
| FinalIntegrationTest.swift | ✅ | ❌ | ❌ | Add to project |
| HapticFeedback.swift | ✅ | ❌ | ❌ | Add to project |
| HelpIconView.swift | ✅ | ❌ | ❌ | Add to project |
| HelpIconViewTests.swift | ✅ | ❌ | ❌ | Add to project |
| IllustratedEmptyStateView.swift | ✅ | ❌ | ❌ | Add to project |
| ImageOptimizationTests.swift | ✅ | ❌ | ❌ | Add to project |
| ImageOptimizer.swift | ✅ | ❌ | ❌ | Add to project |
| InferenceThrottler.swift | ✅ | ❌ | ❌ | Add to project |
| IntegrationTestSuite.swift | ✅ | ❌ | ❌ | Add to project |
| KeychainStoreTests.swift | ✅ | ❌ | ❌ | Add to project |
| KrakenIntegrationTests.swift | ✅ | ❌ | ❌ | Add to project |
| LoadingStateView.swift | ✅ | ❌ | ❌ | Add to project |
| LoadingStateViewTests.swift | ✅ | ❌ | ❌ | Add to project |
| LogExporter.swift | ✅ | ❌ | ❌ | Add to project |
| LogExporterTests.swift | ✅ | ❌ | ❌ | Add to project |
| MarketDataManager.swift | ✅ | ❌ | ❌ | Add to project |
| MemoryPressureManager.swift | ✅ | ❌ | ❌ | Add to project |
| MetaConfidence.swift | ✅ | ❌ | ❌ | Add to project |
| MetaConfidenceCalculator.swift | ✅ | ❌ | ❌ | Add to project |
| MockServices.swift | ✅ | ❌ | ❌ | Add to project |
| ModeEngine.swift | ✅ | ❌ | ❌ | Add to project |
| ModeEngine.swift | ✅ | ❌ | ❌ | Add to project |
| NavigationCoordinator.swift | ✅ | ❌ | ❌ | Add to project |
| OrderExecutionTests.swift | ✅ | ❌ | ❌ | Add to project |
| OrderFill.swift | ✅ | ❌ | ❌ | Add to project |
| OrderRequest.swift | ✅ | ❌ | ❌ | Add to project |
| OrderStatus.swift | ✅ | ❌ | ❌ | Add to project |
| OrderStatusTracker.swift | ✅ | ❌ | ❌ | Add to project |
| OrderStatusTrackingTests.swift | ✅ | ❌ | ❌ | Add to project |
| OrderStatusView.swift | ✅ | ❌ | ❌ | Add to project |
| PerformanceMonitorView.swift | ✅ | ❌ | ❌ | Add to project |
| PerformanceOptimizationIntegrationTests.swift | ✅ | ❌ | ❌ | Add to project |
| PerformanceOptimizer.swift | ✅ | ❌ | ❌ | Add to project |
| PnLFilteringTests.swift | ✅ | ❌ | ❌ | Add to project |
| PnLLoadingStateTests.swift | ✅ | ❌ | ❌ | Add to project |
| PnLPerformanceMetricsTests.swift | ✅ | ❌ | ❌ | Add to project |
| PositionTrackingTests.swift | ✅ | ❌ | ❌ | Add to project |
| PredictionHandlingTests.swift | ✅ | ❌ | ❌ | Add to project |
| PredictionLogger.swift | ✅ | ❌ | ❌ | Add to project |
| RefactoredDashboardVM.swift | ✅ | ❌ | ❌ | Add to project |
| RefactoredStrategiesVM.swift | ✅ | ❌ | ❌ | Add to project |
| RegimeDetectionManager.swift | ✅ | ❌ | ❌ | Add to project |
| RiskManagementTests.swift | ✅ | ❌ | ❌ | Add to project |
| SecureDataHandlingTests.swift | ✅ | ❌ | ❌ | Add to project |
| SecurityTestSuite.swift | ✅ | ❌ | ❌ | Add to project |
| ServiceContainer.swift | ✅ | ❌ | ❌ | Add to project |
| ServiceProtocols.swift | ✅ | ❌ | ❌ | Add to project |
| SettingsConfirmationDialog.swift | ✅ | ❌ | ❌ | Add to project |
| SettingsSearchTests.swift | ✅ | ❌ | ❌ | Add to project |
| SignalInfo.swift | ✅ | ❌ | ❌ | Add to project |
| SignalManager.swift | ✅ | ❌ | ❌ | Add to project |
| SignalVisualizationView.swift | ✅ | ❌ | ❌ | Add to project |
| SignalVisualizationViewTests.swift | ✅ | ❌ | ❌ | Add to project |
| SimpleUIAdapter.swift | ✅ | ❌ | ❌ | Add to project |
| StrategiesViewModel.swift | ✅ | ❌ | ❌ | Add to project |
| StrategyConfigurationManager.swift | ✅ | ❌ | ❌ | Add to project |
| StrategyConfirmationDialog.swift | ✅ | ❌ | ❌ | Add to project |
| StrategyEngine.swift | ✅ | ❌ | ❌ | Add to project |
| TabIconPreview.swift | ✅ | ❌ | ❌ | Add to project |
| TabIconTests.swift | ✅ | ❌ | ❌ | Add to project |
| TabIconValidator.swift | ✅ | ❌ | ❌ | Add to project |
| TestReportGenerator.swift | ✅ | ❌ | ❌ | Add to project |
| TimeframeStandardizationTests.swift | ✅ | ❌ | ❌ | Add to project |
| TimeframeValidator.swift | ✅ | ❌ | ❌ | Add to project |
| ToastDemoView.swift | ✅ | ❌ | ❌ | Add to project |
| ToastManager.swift | ✅ | ❌ | ❌ | Add to project |
| ToastView.swift | ✅ | ❌ | ❌ | Add to project |
| ToastViewTests.swift | ✅ | ❌ | ❌ | Add to project |
| ToggleStylePreview.swift | ✅ | ❌ | ❌ | Add to project |
| TradeConfirmationDialog.swift | ✅ | ❌ | ❌ | Add to project |
| TradeConfirmationDialogTests.swift | ✅ | ❌ | ❌ | Add to project |
| TradeConfirmationViewModel.swift | ✅ | ❌ | ❌ | Add to project |
| TradeExecutionErrorHandlingTests.swift | ✅ | ❌ | ❌ | Add to project |
| TradeExecutionLoadingStateTests.swift | ✅ | ❌ | ❌ | Add to project |
| TradeExecutionToastTests.swift | ✅ | ❌ | ❌ | Add to project |
| TradeFilteringSortingTests.swift | ✅ | ❌ | ❌ | Add to project |
| TradeRequest.swift | ✅ | ❌ | ❌ | Add to project |
| TradingManager.swift | ✅ | ❌ | ❌ | Add to project |
| TradingModeIndicator.swift | ✅ | ❌ | ❌ | Add to project |
| TradingModeIndicatorTests.swift | ✅ | ❌ | ❌ | Add to project |
| TradingTypes.swift | ✅ | ❌ | ❌ | Add to project |
| UIAdapter.swift | ✅ | ❌ | ❌ | Add to project |
| Uncertainty.swift | ✅ | ❌ | ❌ | Add to project |
| UncertaintyModule.swift | ✅ | ❌ | ❌ | Add to project |
| ValidationSuite.swift | ✅ | ❌ | ❌ | Add to project |
| ValidationView.swift | ✅ | ❌ | ❌ | Add to project |
| ViewModelFactory.swift | ✅ | ❌ | ❌ | Add to project |
| WebSocketIntegrationTests.swift | ✅ | ❌ | ❌ | Add to project |
| WidgetBatteryImpactIntegrationTests.swift | ✅ | ❌ | ❌ | Add to project |
| WidgetConfigurationTests.swift | ✅ | ❌ | ❌ | Add to project |
| WidgetConfigurationView.swift | ✅ | ❌ | ❌ | Add to project |
| WidgetDataManager.swift | ✅ | ❌ | ❌ | Add to project |
| WidgetDataManagerTests.swift | ✅ | ❌ | ❌ | Add to project |
| WidgetPerformanceTests.swift | ✅ | ❌ | ❌ | Add to project |
| final_build_validation.swift | ✅ | ❌ | ❌ | Add to project |
| final_compilation_test.swift | ✅ | ❌ | ❌ | Add to project |
| final_fix_summary.swift | ✅ | ❌ | ❌ | Add to project |
| optional_unwrap_fix.swift | ✅ | ❌ | ❌ | Add to project |
| run_widget_performance_tests.swift | ✅ | ❌ | ❌ | Add to project |
| test_ai_integration.swift | ✅ | ❌ | ❌ | Add to project |
| test_aimanager.swift | ✅ | ❌ | ❌ | Add to project |
| test_async_fix.swift | ✅ | ❌ | ❌ | Add to project |
| test_compilation.swift | ✅ | ❌ | ❌ | Add to project |
| test_final_build.swift | ✅ | ❌ | ❌ | Add to project |
| test_simple_build.swift | ✅ | ❌ | ❌ | Add to project |
| validate_build.swift | ✅ | ❌ | ❌ | Add to project |
| validate_widget_performance.swift | ✅ | ❌ | ❌ | Add to project |
| AIModelManager.swift | ✅ | ✅ | ✅ | ✅ OK |
| AIModelManagerProtocol.swift | ✅ | ✅ | ✅ | ✅ OK |
| AISection.swift | ✅ | ✅ | ✅ | ✅ OK |
| Account.swift | ✅ | ✅ | ✅ | ✅ OK |
| AppConfig.swift | ✅ | ✅ | ✅ | ✅ OK |
| AppConfig.swift | ✅ | ✅ | ✅ | ✅ OK |
| AppError.swift | ✅ | ✅ | ✅ | ✅ OK |
| AppSettings.swift | ✅ | ✅ | ✅ | ✅ OK |
| AppSettings.swift | ✅ | ✅ | ✅ | ✅ OK |
| Audit.swift | ✅ | ✅ | ✅ | ✅ OK |
| BackgroundExporter.swift | ✅ | ✅ | ✅ | ✅ OK |
| BinanceClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| BinanceClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| BinanceExchangeClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| BinanceExchangeClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| BinanceKeysView.swift | ✅ | ✅ | ✅ | ✅ OK |
| BinanceLiveClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| BinanceLiveClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| BinanceModels.swift | ✅ | ✅ | ✅ | ✅ OK |
| BinanceModels.swift | ✅ | ✅ | ✅ | ✅ OK |
| BreakoutStrategy.swift | ✅ | ✅ | ✅ | ✅ OK |
| BreakoutStrategy.swift | ✅ | ✅ | ✅ | ✅ OK |
| CSVExporter+PnLMetrics.swift | ✅ | ✅ | ✅ | ✅ OK |
| CSVExporter.swift | ✅ | ✅ | ✅ | ✅ OK |
| Candle.swift | ✅ | ✅ | ✅ | ✅ OK |
| CandleChartView.swift | ✅ | ✅ | ✅ | ✅ OK |
| CandleProvider.swift | ✅ | ✅ | ✅ | ✅ OK |
| CandleProvider.swift | ✅ | ✅ | ✅ | ✅ OK |
| CandlestickChart.swift | ✅ | ✅ | ✅ | ✅ OK |
| CoreMLInspector.swift | ✅ | ✅ | ✅ | ✅ OK |
| DashboardVM.swift | ✅ | ✅ | ✅ | ✅ OK |
| DashboardVM.swift | ✅ | ✅ | ✅ | ✅ OK |
| DashboardView.swift | ✅ | ✅ | ✅ | ✅ OK |
| DashboardView.swift | ✅ | ✅ | ✅ | ✅ OK |
| DateFormatter+Extensions.swift | ✅ | ✅ | ✅ | ✅ OK |
| DesignSystem.swift | ✅ | ✅ | ✅ | ✅ OK |
| DiagnosticsSection.swift | ✅ | ✅ | ✅ | ✅ OK |
| EMAStrategy.swift | ✅ | ✅ | ✅ | ✅ OK |
| EMAStrategy.swift | ✅ | ✅ | ✅ | ✅ OK |
| EnsembleDecider.swift | ✅ | ✅ | ✅ | ✅ OK |
| EnsembleDecider.swift | ✅ | ✅ | ✅ | ✅ OK |
| ErrorManager.swift | ✅ | ✅ | ✅ | ✅ OK |
| Exchange.swift | ✅ | ✅ | ✅ | ✅ OK |
| ExchangeClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| ExchangeClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| ExchangeKeysView.swift | ✅ | ✅ | ✅ | ✅ OK |
| ExchangeKeysView.swift | ✅ | ✅ | ✅ | ✅ OK |
| ExchangesSection.swift | ✅ | ✅ | ✅ | ✅ OK |
| FeatureBuilder.swift | ✅ | ✅ | ✅ | ✅ OK |
| Haptics.swift | ✅ | ✅ | ✅ | ✅ OK |
| InterfaceSection.swift | ✅ | ✅ | ✅ | ✅ OK |
| JSONExporter.swift | ✅ | ✅ | ✅ | ✅ OK |
| KeychainHelper.swift | ✅ | ✅ | ✅ | ✅ OK |
| KeychainStore.swift | ✅ | ✅ | ✅ | ✅ OK |
| KeychainStore.swift | ✅ | ✅ | ✅ | ✅ OK |
| KrakenClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| KrakenClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| KrakenExchangeClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| KrakenExchangeClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| KrakenKeysView.swift | ✅ | ✅ | ✅ | ✅ OK |
| KrakenLiveClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| KrakenLiveClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| KrakenModels.swift | ✅ | ✅ | ✅ | ✅ OK |
| KrakenModels.swift | ✅ | ✅ | ✅ | ✅ OK |
| LegacyStrategy.swift | ✅ | ✅ | ✅ | ✅ OK |
| LegacyStrategy.swift | ✅ | ✅ | ✅ | ✅ OK |
| Log.swift | ✅ | ✅ | ✅ | ✅ OK |
| Logger.swift | ✅ | ✅ | ✅ | ✅ OK |
| MACDStrategy.swift | ✅ | ✅ | ✅ | ✅ OK |
| MACDStrategy.swift | ✅ | ✅ | ✅ | ✅ OK |
| MarketDataSection.swift | ✅ | ✅ | ✅ | ✅ OK |
| MarketDataService.swift | ✅ | ✅ | ✅ | ✅ OK |
| MarketDataService.swift | ✅ | ✅ | ✅ | ✅ OK |
| MarketPriceCache.swift | ✅ | ✅ | ✅ | ✅ OK |
| MeanReversionStrategy.swift | ✅ | ✅ | ✅ | ✅ OK |
| MeanReversionStrategy.swift | ✅ | ✅ | ✅ | ✅ OK |
| ModelKind.swift | ✅ | ✅ | ✅ | ✅ OK |
| MyTradeMateApp.swift | ✅ | ✅ | ✅ | ✅ OK |
| NetworkSecurityManager.swift | ✅ | ✅ | ✅ | ✅ OK |
| Order.swift | ✅ | ✅ | ✅ | ✅ OK |
| OrderSide.swift | ✅ | ✅ | ✅ | ✅ OK |
| OrderTypes.swift | ✅ | ✅ | ✅ | ✅ OK |
| PaperExchangeClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| PaperExchangeClient.swift | ✅ | ✅ | ✅ | ✅ OK |
| PnLAggregator.swift | ✅ | ✅ | ✅ | ✅ OK |
| PnLCSVExporter.swift | ✅ | ✅ | ✅ | ✅ OK |
| PnLDetailView.swift | ✅ | ✅ | ✅ | ✅ OK |
| PnLDetailView.swift | ✅ | ✅ | ✅ | ✅ OK |
| PnLManager.swift | ✅ | ✅ | ✅ | ✅ OK |
| PnLMetrics.swift | ✅ | ✅ | ✅ | ✅ OK |
| PnLVM.swift | ✅ | ✅ | ✅ | ✅ OK |
| PnLVM.swift | ✅ | ✅ | ✅ | ✅ OK |
| PnLWidget.swift | ✅ | ✅ | ✅ | ✅ OK |
| Position.swift | ✅ | ✅ | ✅ | ✅ OK |
| PredictionResult.swift | ✅ | ✅ | ✅ | ✅ OK |
| PriceTick.swift | ✅ | ✅ | ✅ | ✅ OK |
| RSIStrategy.swift | ✅ | ✅ | ✅ | ✅ OK |
| RSIStrategy.swift | ✅ | ✅ | ✅ | ✅ OK |
| RegimeDetector.swift | ✅ | ✅ | ✅ | ✅ OK |
| RegimeDetector.swift | ✅ | ✅ | ✅ | ✅ OK |
| RiskManager.swift | ✅ | ✅ | ✅ | ✅ OK |
| RiskModels.swift | ✅ | ✅ | ✅ | ✅ OK |
| RootTabs.swift | ✅ | ✅ | ✅ | ✅ OK |
| SafeTask.swift | ✅ | ✅ | ✅ | ✅ OK |
| SettingsVM.swift | ✅ | ✅ | ✅ | ✅ OK |
| SettingsVM.swift | ✅ | ✅ | ✅ | ✅ OK |
| SettingsValidator.swift | ✅ | ✅ | ✅ | ✅ OK |
| SettingsView.swift | ✅ | ✅ | ✅ | ✅ OK |
| SettingsView.swift | ✅ | ✅ | ✅ | ✅ OK |
| ShareSheet.swift | ✅ | ✅ | ✅ | ✅ OK |
| Signal.swift | ✅ | ✅ | ✅ | ✅ OK |
| SignalEngine.swift | ✅ | ✅ | ✅ | ✅ OK |
| SignalEngine.swift | ✅ | ✅ | ✅ | ✅ OK |
| StopMonitor.swift | ✅ | ✅ | ✅ | ✅ OK |
| StrategiesSection.swift | ✅ | ✅ | ✅ | ✅ OK |
| StrategiesVM.swift | ✅ | ✅ | ✅ | ✅ OK |
| StrategiesVM.swift | ✅ | ✅ | ✅ | ✅ OK |
| StrategiesView.swift | ✅ | ✅ | ✅ | ✅ OK |
| StrategiesView.swift | ✅ | ✅ | ✅ | ✅ OK |
| Strategy.swift | ✅ | ✅ | ✅ | ✅ OK |
| Strategy.swift | ✅ | ✅ | ✅ | ✅ OK |
| StrategyManager.swift | ✅ | ✅ | ✅ | ✅ OK |
| StrategyManager.swift | ✅ | ✅ | ✅ | ✅ OK |
| Symbol.swift | ✅ | ✅ | ✅ | ✅ OK |
| SymbolCatalog.swift | ✅ | ✅ | ✅ | ✅ OK |
| SymbolCatalog.swift | ✅ | ✅ | ✅ | ✅ OK |
| ThemeManager.swift | ✅ | ✅ | ✅ | ✅ OK |
| Ticker.swift | ✅ | ✅ | ✅ | ✅ OK |
| Timeframe.swift | ✅ | ✅ | ✅ | ✅ OK |
| TradeHistoryVM.swift | ✅ | ✅ | ✅ | ✅ OK |
| TradeHistoryVM.swift | ✅ | ✅ | ✅ | ✅ OK |
| TradeHistoryView.swift | ✅ | ✅ | ✅ | ✅ OK |
| TradeHistoryView.swift | ✅ | ✅ | ✅ | ✅ OK |
| TradeManager.swift | ✅ | ✅ | ✅ | ✅ OK |
| TradeStore.swift | ✅ | ✅ | ✅ | ✅ OK |
| TradeStore.swift | ✅ | ✅ | ✅ | ✅ OK |
| TradesVM.swift | ✅ | ✅ | ✅ | ✅ OK |
| TradesVM.swift | ✅ | ✅ | ✅ | ✅ OK |
| TradesView.swift | ✅ | ✅ | ✅ | ✅ OK |
| TradesView.swift | ✅ | ✅ | ✅ | ✅ OK |
| TradingMode.swift | ✅ | ✅ | ✅ | ✅ OK |
| TradingSection.swift | ✅ | ✅ | ✅ | ✅ OK |
| TrialManager.swift | ✅ | ✅ | ✅ | ✅ OK |
| WebSocketManager.swift | ✅ | ✅ | ✅ | ✅ OK |
| WebSocketManager.swift | ✅ | ✅ | ✅ | ✅ OK |

## Build Status
✅ **Current Build Status:** SUCCESSFUL (tested on iOS Simulator)

## Summary

- **Total Swift files analyzed:** 285
- **Files missing from disk:** 2
- **Files not in project:** 138
- **Files not in Sources build phase:** 138

### ⚠️ Critical Issues
- 1 file is referenced in the project but missing from disk:
  - `SmokeTests.swift` - Missing test file (in MyTradeMateTests target)
- **Note:** `MyTradeMateWidget.swift` exists in the MyTradeMateWidget directory and is properly referenced
- **Impact:** Missing test file should be removed from project references or restored

### 📁 Orphaned Files
- 138 files exist on disk but are not included in the project
- **Categories of orphaned files:**
  - **Scripts/** (13 files) - Build validation and testing scripts
  - **Services/AI/** (6 files) - New AI service modules
  - **Tests/** (55+ files) - Test suites and validation
  - **Views/Components/** (25+ files) - UI components and helpers
  - **Core/Performance/** (5 files) - Performance optimization modules
  - **Protocols/** (2 files) - New protocol definitions

### 🏗️ Resources Status
- **CoreML Models:** ✅ All 3 models properly referenced
  - `BTC_4H_Model.mlpackage`
  - `BitcoinAI_1h_enhanced.mlmodel`
  - `BitcoinAI_5m_enhanced.mlmodel`
- **Info.plist:** ✅ Properly referenced for both main app and widget
- **Dependencies:** ✅ Charts framework included via Swift Package Manager
- **Targets:** ✅ 3 targets configured (MyTradeMate, MyTradeMateTests, MyTradeMateWidget)

### 🧪 Test Coverage
- **Test Files on Disk:** 55+ test files
- **Test Files in Project:** Limited (many orphaned)
- **Test Categories:** Unit tests, Integration tests, Performance tests, Security tests

## Recommendations

### High Priority
1. **Remove missing file references:**
   ```bash
   # Remove references to missing files from project
   # MyTradeMateWidget.swift, SmokeTests.swift
   ```

2. **Add critical orphaned files to project:**
   - Core service files in `Services/AI/`
   - Protocol definitions in `Protocols/`
   - Essential UI components

### Medium Priority
3. **Organize test files:**
   - Add test files to appropriate test targets
   - Ensure test discovery works properly

4. **Scripts management:**
   - Consider if build scripts should be included in project
   - Move to a separate folder if they're development-only tools

### Low Priority
5. **Code cleanup:**
   - Remove duplicate implementations where they exist
   - Consolidate similar functionality

## Priority Orphaned Files to Add

### Critical (Must Add)
- `MyTradeMate/Protocols/AIModelManagerProtocol.swift` ✅ (Already in project)
- `MyTradeMate/Protocols/ModelKind.swift` ✅ (Already in project)
- `MyTradeMate/Services/AI/CalibrationUtils.swift`
- `MyTradeMate/Services/AI/ConformalGate.swift`
- `MyTradeMate/Services/AI/MetaConfidenceCalculator.swift`
- `MyTradeMate/Services/AI/UncertaintyModule.swift`

### Important UI Components
- `MyTradeMate/Views/Components/EmptyStateView.swift`
- `MyTradeMate/Views/Components/LoadingStateView.swift`
- `MyTradeMate/Views/Components/ToastView.swift`
- `MyTradeMate/Views/Components/ConfirmationDialog.swift`

### Performance & Architecture
- `MyTradeMate/Core/Performance/PerformanceOptimizer.swift`
- `MyTradeMate/Core/Performance/MemoryPressureManager.swift`
- `MyTradeMate/Core/DependencyInjection/ServiceContainer.swift`
- `MyTradeMate/Core/DependencyInjection/ViewModelFactory.swift`

---

*Analysis generated on 2025-08-17 for MyTradeMate iOS project.*
