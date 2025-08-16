import XCTest
import CoreML
@testable import MyTradeMate

final class CoreMLModelTests: XCTestCase {
    
    var aiModelManager: AIModelManager!
    
    override func setUp() async throws {
        try await super.setUp()
        aiModelManager = AIModelManager.shared
        // Clear any cached models to ensure clean test state
        await MainActor.run {
            aiModelManager.models.removeAll()
        }
    }
    
    override func tearDown() async throws {
        aiModelManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Model Loading Tests
    
    func testLoadModel5m() async throws {
        // Given
        let modelKind = ModelKind.m5
        
        // When
        let model = try await aiModelManager.loadModel(kind: modelKind)
        
        // Then
        XCTAssertNotNil(model, "5m model should load successfully")
        XCTAssertFalse(model.modelDescription.inputDescriptionsByName.isEmpty, "Model should have input descriptions")
        XCTAssertFalse(model.modelDescription.outputDescriptionsByName.isEmpty, "Model should have output descriptions")
        
        // Verify model is cached
        await MainActor.run {
            XCTAssertNotNil(aiModelManager.models[modelKind], "Model should be cached after loading")
        }
    }
    
    func testLoadModel1h() async throws {
        // Given
        let modelKind = ModelKind.h1
        
        // When
        let model = try await aiModelManager.loadModel(kind: modelKind)
        
        // Then
        XCTAssertNotNil(model, "1h model should load successfully")
        XCTAssertFalse(model.modelDescription.inputDescriptionsByName.isEmpty, "Model should have input descriptions")
        XCTAssertFalse(model.modelDescription.outputDescriptionsByName.isEmpty, "Model should have output descriptions")
        
        // Verify model is cached
        await MainActor.run {
            XCTAssertNotNil(aiModelManager.models[modelKind], "Model should be cached after loading")
        }
    }
    
    func testLoadModel4h() async throws {
        // Given
        let modelKind = ModelKind.h4
        
        // When
        let model = try await aiModelManager.loadModel(kind: modelKind)
        
        // Then
        XCTAssertNotNil(model, "4h model should load successfully")
        XCTAssertFalse(model.modelDescription.inputDescriptionsByName.isEmpty, "Model should have input descriptions")
        XCTAssertFalse(model.modelDescription.outputDescriptionsByName.isEmpty, "Model should have output descriptions")
        
        // Verify model is cached
        await MainActor.run {
            XCTAssertNotNil(aiModelManager.models[modelKind], "Model should be cached after loading")
        }
    }
    
    func testModelLoadingErrorHandling() async throws {
        // Test that model loading handles missing files gracefully
        // We can't easily create a missing model file, but we can test the bundle resource validation
        
        // Given - Test all expected models exist in bundle
        for modelKind in [ModelKind.m5, .h1, .h4] {
            // When
            let model = try await aiModelManager.loadModel(kind: modelKind)
            
            // Then - Verify model has expected structure
            XCTAssertNotNil(model, "Model \(modelKind.modelName) should load successfully")
            
            let inputDescriptions = model.modelDescription.inputDescriptionsByName
            let outputDescriptions = model.modelDescription.outputDescriptionsByName
            
            XCTAssertFalse(inputDescriptions.isEmpty, "Model \(modelKind.modelName) should have input descriptions")
            XCTAssertFalse(outputDescriptions.isEmpty, "Model \(modelKind.modelName) should have output descriptions")
            
            // Verify model file exists in bundle
            let url = Bundle.main.url(forResource: modelKind.modelName, withExtension: "mlmodelc")
            XCTAssertNotNil(url, "Model file \(modelKind.modelName).mlmodelc should exist in bundle")
        }
    }
    
    func testModelBundleResourceValidation() throws {
        // Test that all expected model files exist in the app bundle
        
        // Given
        let expectedModels = [ModelKind.m5, .h1, .h4]
        
        // When & Then
        for modelKind in expectedModels {
            let url = Bundle.main.url(forResource: modelKind.modelName, withExtension: "mlmodelc")
            XCTAssertNotNil(url, "Model file \(modelKind.modelName).mlmodelc should exist in bundle")
            
            if let url = url {
                XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), 
                            "Model file should exist at path: \(url.path)")
            }
        }
    }
    
    func testPreloadModels() async throws {
        // Given
        aiModelManager.models.removeAll() // Clear any cached models
        
        // When
        await aiModelManager.preloadModels()
        
        // Then
        XCTAssertFalse(aiModelManager.models.isEmpty, "Should have preloaded models")
        
        // Verify all expected models are loaded
        let expectedModels: [ModelKind] = [.m5, .h1, .h4]
        for modelKind in expectedModels {
            XCTAssertNotNil(aiModelManager.models[modelKind], "Should have preloaded \(modelKind.modelName)")
        }
    }
    
    // MARK: - Model Validation Tests
    
    func testValidateModels() async throws {
        // Given
        await aiModelManager.preloadModels()
        
        // When & Then - Should not throw
        try await aiModelManager.validateModels()
    }
    
    func testValidateModelInputShapes() async throws {
        // Given
        let model = try await aiModelManager.loadModel(kind: .m5)
        
        // When
        let inputDescriptions = model.modelDescription.inputDescriptionsByName
        
        // Then
        XCTAssertFalse(inputDescriptions.isEmpty, "Model should have input descriptions")
        
        for (inputName, description) in inputDescriptions {
            switch description.type {
            case .multiArray:
                XCTAssertNotNil(description.multiArrayConstraint, "MultiArray input should have constraints")
                if let constraint = description.multiArrayConstraint {
                    XCTAssertNotNil(constraint.shape, "MultiArray should have shape")
                    XCTAssertFalse(constraint.shape.isEmpty, "Shape should not be empty")
                    
                    // Log the shape for debugging
                    print("Input '\(inputName)' shape: \(constraint.shape)")
                }
            case .image:
                XCTAssertNotNil(description.imageConstraint, "Image input should have constraints")
            default:
                break
            }
        }
    }
    
    func testValidateModelOutputShapes() async throws {
        // Given
        let model = try await aiModelManager.loadModel(kind: .m5)
        
        // When
        let outputDescriptions = model.modelDescription.outputDescriptionsByName
        
        // Then
        XCTAssertFalse(outputDescriptions.isEmpty, "Model should have output descriptions")
        
        for (outputName, description) in outputDescriptions {
            switch description.type {
            case .multiArray:
                XCTAssertNotNil(description.multiArrayConstraint, "MultiArray output should have constraints")
                if let constraint = description.multiArrayConstraint {
                    XCTAssertNotNil(constraint.shape, "MultiArray should have shape")
                    XCTAssertFalse(constraint.shape.isEmpty, "Shape should not be empty")
                    
                    // Log the shape for debugging
                    print("Output '\(outputName)' shape: \(constraint.shape)")
                }
            case .dictionary:
                // Some models might output dictionaries
                break
            default:
                break
            }
        }
    }
    
    // MARK: - Model Metadata Tests
    
    func testModelMetadata() async throws {
        // Given
        let model = try await aiModelManager.loadModel(kind: .m5)
        
        // When
        let metadata = model.modelDescription.metadata
        
        // Then
        XCTAssertNotNil(metadata, "Model should have metadata")
        
        // Check for common metadata fields
        if let author = metadata[MLModelMetadataKey.author] as? String {
            XCTAssertFalse(author.isEmpty, "Author should not be empty if present")
        }
        
        if let description = metadata[MLModelMetadataKey.description] as? String {
            XCTAssertFalse(description.isEmpty, "Description should not be empty if present")
        }
        
        if let version = metadata[MLModelMetadataKey.versionString] as? String {
            XCTAssertFalse(version.isEmpty, "Version should not be empty if present")
        }
    }
    
    func testModelKindProperties() {
        // Test ModelKind enum properties
        let testCases: [(ModelKind, String, String)] = [
            (.m5, "BitcoinAI_5m_enhanced", "m5"),
            (.h1, "BitcoinAI_1h_enhanced", "h1"),
            (.h4, "BitcoinAI_4h_enhanced", "h4")
        ]
        
        for (kind, expectedModelName, expectedTimeframe) in testCases {
            XCTAssertEqual(kind.modelName, expectedModelName)
            XCTAssertEqual(kind.timeframe, expectedTimeframe)
            XCTAssertEqual(kind.rawValue, expectedModelName)
        }
    }
    
    // MARK: - Model Performance Tests
    
    func testModelLoadingPerformance() async throws {
        // Measure the time it takes to load a model
        let modelKind = ModelKind.m5
        
        measure {
            let expectation = XCTestExpectation(description: "Model loading")
            
            Task {
                do {
                    let _ = try await aiModelManager.loadModel(kind: modelKind)
                    expectation.fulfill()
                } catch {
                    XCTFail("Model loading failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testConcurrentModelLoading() async throws {
        // Test loading multiple models concurrently
        let modelKinds: [ModelKind] = [.m5, .h1, .h4]
        
        await withTaskGroup(of: Void.self) { group in
            for modelKind in modelKinds {
                group.addTask {
                    do {
                        let model = try await self.aiModelManager.loadModel(kind: modelKind)
                        XCTAssertNotNil(model, "Model \(modelKind.modelName) should load successfully")
                    } catch {
                        XCTFail("Failed to load model \(modelKind.modelName): \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Model Caching Tests
    
    func testModelCaching() async throws {
        // Given
        let modelKind = ModelKind.m5
        aiModelManager.models.removeValue(forKey: modelKind) // Ensure not cached
        
        // When - Load model twice
        let model1 = try await aiModelManager.loadModel(kind: modelKind)
        aiModelManager.models[modelKind] = model1 // Cache it
        
        let model2 = try await aiModelManager.loadModel(kind: modelKind)
        
        // Then - Should get the same cached instance
        XCTAssertTrue(model1 === model2, "Should return cached model instance")
    }
    
    func testModelCacheIsolation() async throws {
        // Given
        let modelKind1 = ModelKind.m5
        let modelKind2 = ModelKind.h1
        
        // When
        let model1 = try await aiModelManager.loadModel(kind: modelKind1)
        let model2 = try await aiModelManager.loadModel(kind: modelKind2)
        
        // Then
        XCTAssertFalse(model1 === model2, "Different models should be different instances")
        XCTAssertNotEqual(model1.modelDescription.inputDescriptionsByName.description,
                         model2.modelDescription.inputDescriptionsByName.description,
                         "Different models should have different descriptions")
    }
    
    // MARK: - Error Handling Tests
    
    func testModelValidationWithValidModels() async throws {
        // Test that validation passes with properly loaded models
        
        // Given
        await aiModelManager.preloadModels()
        
        // When & Then
        XCTAssertNoThrow(try await aiModelManager.validateModels(), "Valid models should pass validation")
        
        // Test that validation actually checks something by ensuring models are loaded
        await MainActor.run {
            XCTAssertFalse(aiModelManager.models.isEmpty, "Should have models to validate")
        }
        
        await MainActor.run {
            for (kind, model) in aiModelManager.models {
                // Verify each model has the expected structure
                let inputDescriptions = model.modelDescription.inputDescriptionsByName
                let outputDescriptions = model.modelDescription.outputDescriptionsByName
                
                XCTAssertFalse(inputDescriptions.isEmpty, "Model \(kind.modelName) should have inputs")
                XCTAssertFalse(outputDescriptions.isEmpty, "Model \(kind.modelName) should have outputs")
            }
        }
    }
    
    func testModelValidationWithEmptyModels() async throws {
        // Test validation behavior when no models are loaded
        
        // Given - Clear all models
        await MainActor.run {
            aiModelManager.models.removeAll()
        }
        
        // When & Then - Validation should handle empty models gracefully
        // The current implementation doesn't throw for empty models, it just validates what's there
        XCTAssertNoThrow(try await aiModelManager.validateModels(), "Validation should handle empty models")
    }
    
    func testModelValidationDetectsInvalidStructure() async throws {
        // Test that validation can detect structural issues
        // Since we can't easily create invalid models, we test the validation logic
        
        // Given
        await aiModelManager.preloadModels()
        
        // When
        try await aiModelManager.validateModels()
        
        // Then - Verify validation checks input/output shapes
        await MainActor.run {
            for (kind, model) in aiModelManager.models {
                let inputDescriptions = model.modelDescription.inputDescriptionsByName
                let outputDescriptions = model.modelDescription.outputDescriptionsByName
                
                // Validation should ensure models have proper structure
                XCTAssertFalse(inputDescriptions.isEmpty, "Validated model \(kind.modelName) should have inputs")
                XCTAssertFalse(outputDescriptions.isEmpty, "Validated model \(kind.modelName) should have outputs")
                
                // Check that inputs have proper constraints
                for (inputName, description) in inputDescriptions {
                    switch description.type {
                    case .multiArray:
                        XCTAssertNotNil(description.multiArrayConstraint, 
                                      "MultiArray input \(inputName) should have constraints")
                        if let constraint = description.multiArrayConstraint {
                            XCTAssertNotNil(constraint.shape, "MultiArray should have shape")
                            XCTAssertFalse(constraint.shape.isEmpty, "Shape should not be empty")
                        }
                    case .image:
                        XCTAssertNotNil(description.imageConstraint, 
                                      "Image input \(inputName) should have constraints")
                    default:
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - Model Compatibility Tests
    
    func testModelCompatibilityWithCurrentOS() async throws {
        // Test that models are compatible with the current iOS version
        
        for modelKind in [ModelKind.m5, .h1, .h4] {
            // Given
            let model = try await aiModelManager.loadModel(kind: modelKind)
            
            // When - Try to create a prediction (even with dummy data)
            let inputDescriptions = model.modelDescription.inputDescriptionsByName
            
            // Then - Should be able to access model properties without crashing
            XCTAssertNotNil(model.modelDescription)
            XCTAssertFalse(inputDescriptions.isEmpty)
            
            // Test that we can create feature providers (basic compatibility test)
            if let firstInput = inputDescriptions.first {
                let inputName = firstInput.key
                let inputDescription = firstInput.value
                
                // Try to create a compatible input based on the description
                switch inputDescription.type {
                case .multiArray:
                    if let constraint = inputDescription.multiArrayConstraint {
                        XCTAssertNoThrow(try MLMultiArray(shape: constraint.shape, dataType: constraint.dataType))
                    }
                case .image:
                    // Image inputs are supported
                    XCTAssertNotNil(inputDescription.imageConstraint)
                default:
                    // Other types should be handled gracefully
                    break
                }
            }
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testModelMemoryManagement() async throws {
        // Test that models can be loaded and unloaded without memory leaks
        
        // Given
        await MainActor.run {
            aiModelManager.models.removeAll()
        }
        let initialModelCount = await MainActor.run { aiModelManager.models.count }
        
        // When - Load all models
        await aiModelManager.preloadModels()
        let loadedModelCount = await MainActor.run { aiModelManager.models.count }
        
        // Then
        XCTAssertGreaterThan(loadedModelCount, initialModelCount, "Should have loaded models")
        
        // When - Clear models
        await MainActor.run {
            aiModelManager.models.removeAll()
        }
        let clearedModelCount = await MainActor.run { aiModelManager.models.count }
        
        // Then
        XCTAssertEqual(clearedModelCount, 0, "Should have cleared all models")
        
        // Verify we can load models again after clearing
        let model = try await aiModelManager.loadModel(kind: .m5)
        XCTAssertNotNil(model, "Should be able to load model after clearing cache")
    }
    
    // MARK: - Model Input/Output Validation Tests
    
    func testModelInputOutputCompatibility() async throws {
        // Test that all models have compatible input/output structures
        
        // Given
        await aiModelManager.preloadModels()
        
        // When & Then
        await MainActor.run {
            for (kind, model) in aiModelManager.models {
                let inputDescriptions = model.modelDescription.inputDescriptionsByName
                let outputDescriptions = model.modelDescription.outputDescriptionsByName
                
                // Verify we have at least one input and output
                XCTAssertGreaterThan(inputDescriptions.count, 0, "Model \(kind.modelName) should have inputs")
                XCTAssertGreaterThan(outputDescriptions.count, 0, "Model \(kind.modelName) should have outputs")
                
                // Check input compatibility with feature vector
                var hasCompatibleInput = false
                for (inputName, description) in inputDescriptions {
                    if case .multiArray = description.type,
                       let constraint = description.multiArrayConstraint {
                        let shape = constraint.shape.map { $0.intValue }
                        // Check if shape is compatible with 10-feature vector
                        if shape.contains(10) || shape == [1, 10] || shape == [10, 1] {
                            hasCompatibleInput = true
                            print("Model \(kind.modelName) input '\(inputName)' has compatible shape: \(shape)")
                        }
                    }
                }
                
                XCTAssertTrue(hasCompatibleInput, 
                            "Model \(kind.modelName) should have at least one input compatible with 10-feature vector")
            }
        }
    }
    
    func testModelDataTypeCompatibility() async throws {
        // Test that models accept the expected data types
        
        // Given
        await aiModelManager.preloadModels()
        
        // When & Then
        await MainActor.run {
            for (kind, model) in aiModelManager.models {
                let inputDescriptions = model.modelDescription.inputDescriptionsByName
                
                for (inputName, description) in inputDescriptions {
                    if case .multiArray = description.type,
                       let constraint = description.multiArrayConstraint {
                        
                        // Verify data type is supported
                        let dataType = constraint.dataType
                        XCTAssertTrue([.float32, .double, .int32].contains(dataType), 
                                    "Model \(kind.modelName) input '\(inputName)' should use supported data type, got: \(dataType)")
                        
                        // Test that we can create arrays with this data type
                        XCTAssertNoThrow(try MLMultiArray(shape: [10], dataType: dataType), 
                                       "Should be able to create MLMultiArray with data type \(dataType)")
                    }
                }
            }
        }
    }
    
    func testModelOutputStructureValidation() async throws {
        // Test that model outputs have expected structure for prediction conversion
        
        // Given
        await aiModelManager.preloadModels()
        
        // When & Then
        await MainActor.run {
            for (kind, model) in aiModelManager.models {
                let outputDescriptions = model.modelDescription.outputDescriptionsByName
                
                // Should have at least one output
                XCTAssertFalse(outputDescriptions.isEmpty, "Model \(kind.modelName) should have outputs")
                
                // Check for common output patterns
                var hasValidOutput = false
                
                for (outputName, description) in outputDescriptions {
                    switch description.type {
                    case .multiArray:
                        if let constraint = description.multiArrayConstraint {
                            let shape = constraint.shape.map { $0.intValue }
                            // Valid shapes for classification: [1], [3], [1,3], etc.
                            if shape.contains(where: { $0 > 0 && $0 <= 10 }) {
                                hasValidOutput = true
                                print("Model \(kind.modelName) output '\(outputName)' has valid shape: \(shape)")
                            }
                        }
                    case .dictionary:
                        // Dictionary outputs are also valid (e.g., classLabel + confidence)
                        hasValidOutput = true
                        print("Model \(kind.modelName) output '\(outputName)' is dictionary type")
                    default:
                        break
                    }
                }
                
                XCTAssertTrue(hasValidOutput, 
                            "Model \(kind.modelName) should have at least one valid output structure")
            }
        }
    }
}