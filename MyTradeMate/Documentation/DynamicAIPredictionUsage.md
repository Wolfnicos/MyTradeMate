# Dynamic AI Prediction Pipeline Usage

## Overview

The enhanced AI prediction pipeline automatically detects and adapts to different CoreML model input requirements:

- **5m Model**: Uses `dense_input` key with 10-feature MLMultiArray
- **1h Model**: Uses `dense_4_input` key with 10-feature MLMultiArray  
- **4h Model**: Uses explicit features (OHLC + engineered features)

## Enhanced Features

### 1. Automatic Input Detection
```swift
// The system automatically detects model input requirements
let inputType = analyzeModelInputType(model: model)

// Builds appropriate input based on detection
let inputProvider = try buildModelInput(inputType: inputType, features: features, candle: candle)
```

### 2. Enhanced Prediction Results
```swift
struct PredictionResult {
    let signal: String              // "BUY", "SELL", "HOLD"
    let confidence: Double          // 0.0 to 1.0
    let confidencePercentage: Int   // 0 to 100
    let modelName: String          
    let timeframe: String          // "5m", "1h", "4h"
    let meta: [String: String]     // Additional metadata
    
    var formattedOutput: String    // "[5m] Prediction: BUY (85%)"
}
```

### 3. Console Logging Format
The system now outputs clean, formatted predictions:
```
[5m] Prediction: SELL (92%)
[1h] Prediction: HOLD (47%)
[4h] Prediction: BUY (68%)
```

## Usage Examples

### Single Model Prediction
```swift
let result = await AIModelManager.shared.singleModelPrediction(
    timeframe: .h4, 
    candles: latestCandles
)
print(result.formattedOutput)
// Output: [4h] Prediction: BUY (68%)
```

### Test All Models
```swift
await AIModelManager.shared.testAllModels(candles: sampleCandles)
// Outputs formatted predictions for all three models
```

### Access Individual Values
```swift
let result = await AIModelManager.shared.predict(
    symbol: "BTC/USDT",
    timeframe: .m5, 
    candles: candles,
    precision: false
)

print("Signal: \(result.signal)")           // "BUY"
print("Confidence: \(result.confidence)")   // 0.85
print("Percentage: \(result.confidencePercentage)%") // 85%
print("Timeframe: \(result.timeframe)")     // "5m"
```

## Model Input Compatibility

### 5m Model (BitcoinAI_5m_enhanced.mlmodelc)
- **Input**: `dense_input` key
- **Shape**: [1, 10] MLMultiArray
- **Features**: Unified 10-feature vector

### 1h Model (BitcoinAI_1h_enhanced.mlmodelc)  
- **Input**: `dense_4_input` key
- **Shape**: [1, 10] MLMultiArray
- **Features**: Unified 10-feature vector

### 4h Model (BTC_4H_Model.mlmodelc)
- **Input**: Explicit feature dictionary
- **Keys**: `["open", "high", "low", "close", "volume", "return_1", "return_3", "return_5", "rsi", "volatility", "price_position", "volume_ratio"]`
- **Format**: Individual scalar MLMultiArrays for each feature

## Error Handling

The system includes comprehensive error handling:

- **Insufficient Data**: Returns HOLD with appropriate metadata
- **Model Loading Errors**: Graceful fallback with error details
- **Feature Calculation Errors**: Safe defaults (0.0) for missing values
- **CoreML Prediction Errors**: Detailed error logging

## Safe Fallbacks

- Missing features default to 0.0
- Unsupported models fall back to explicit feature mode
- Low confidence predictions (< 30%) return HOLD
- Failed predictions return HOLD with error metadata

This dynamic system ensures that all three models work reliably without hardcoded input assumptions.