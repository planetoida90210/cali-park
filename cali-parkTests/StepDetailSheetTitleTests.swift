//
//  StepDetailSheetTitleTests.swift
//  cali-parkTests
//
//  The rung sheet's title at accessibility sizes (row 16 of the second
//  visual pass: "Wiosłowanie na podwyż…").
//

import SwiftUI
import Testing

@testable import cali_park

@MainActor
struct StepDetailSheetTitleTests {
    @Test
    func theNameMovesIntoTheContentAtAccessibilitySizes() {
        let name = "Wiosłowanie na podwyższeniu"
        #expect(StepDetailSheetView.inlineTitle(name, typeSize: .large) == name)
        #expect(StepDetailSheetView.inlineTitle(name, typeSize: .xxxLarge) == name)
        #expect(StepDetailSheetView.inlineTitle(name, typeSize: .accessibility1).isEmpty)
        #expect(StepDetailSheetView.inlineTitle(name, typeSize: .accessibility3).isEmpty)
    }
}
