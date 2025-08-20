# AI/Ensemble & Data Pipeline Fixes

## Issues Fixed

### 1. AI Confidence Stuck at 50%
- **Root Cause**: Multiple hardcoded `max(0.5, score)` floors in SignalManager
- **Fix**: Remove artificial floors, implement proper confidence normalization
- **Files**: SignalManager.swift, AIModelManager.swift, StrategyEngine.swift

### 2. Only 2/15 Strategies Voting  
- **Root Cause**: Strategies default to disabled in SettingsRepository
- **Fix**: Enable all strategies by default, add debug logging for vote counts
- **Files**: SettingsRepository.swift, StrategyManager.swift

### 3. Cache Key Inconsistencies
- **Root Cause**: Mixed formats "BTC-m5" vs "BTC/USDT-m5" 
- **Fix**: Standardize to "SYMBOL:TIMEFRAME" format with CandleFetchCoordinator
- **Files**: MarketDataService.swift, new CandleFetchCoordinator.swift

### 4. Missing Model Fallback
- **Root Cause**: No proper fallback when ML models unavailable
- **Fix**: Strategy-only mode with proper status indication
- **Files**: AIStatusStore.swift, SignalManager.swift

### 5. Missing Fee Calculation
- **Root Cause**: No trading fee implementation
- **Fix**: Add TradingFeeCalculator with configurable rates and tests
- **Files**: new TradingFeeCalculator.swift, tests

## Implementation Commits

1. `fix(ai): remove artificial confidence floors, normalize properly`
2. `fix(strategies): enable all 15 strategies by default, add debug logging` 
3. `fix(cache): standardize cache keys, add fetch coordinator`
4. `fix(ai): add model unavailable fallback, strategy-only mode`
5. `feat(trading): add fee calculator with tests`
6. `test(integration): add comprehensive AI pipeline tests`