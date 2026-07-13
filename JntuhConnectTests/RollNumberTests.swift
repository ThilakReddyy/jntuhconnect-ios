import Testing
@testable import JntuhConnect

struct RollNumberTests {
    @Test func normalizesWhitespaceAndCase() {
        let roll = RollNumber("  22j21a0501  ")
        #expect(roll.rawValue == "22J21A0501")
    }

    @Test func acceptsTenCharacterJntuhRollNumber() {
        #expect(RollNumber("22J21A0501").isValid)
    }

    @Test func rejectsIncorrectLengthOrSymbols() {
        #expect(!RollNumber("22J21A501").isValid)
        #expect(!RollNumber("22J21A05-1").isValid)
    }
}
