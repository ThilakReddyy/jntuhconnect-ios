import Testing
@testable import JntuhConnect

struct ResultFlowTests {
    @Test func singleRollFlowsProduceOneValidatedRequest() throws {
        let request = try ResultFlow.allResults.makeRequest(primary: " 18e51a0479 ", secondary: "")
        #expect(request.primary.rawValue == "18E51A0479")
        #expect(request.secondary == nil)
    }

    @Test func contrastRequiresTwoDifferentValidRollNumbers() {
        #expect(throws: ResultFlowValidationError.self) {
            try ResultFlow.contrast.makeRequest(primary: "18E51A0479", secondary: "18E51A0479")
        }
        #expect(throws: ResultFlowValidationError.self) {
            try ResultFlow.contrast.makeRequest(primary: "18E51A0479", secondary: "bad")
        }
    }
}
