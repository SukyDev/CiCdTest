//
//  CiCdTestingUITests.swift
//  CiCdTestingUITests
//
//  Created by New on 16.12.24..
//

import XCTest
import SnapshotTesting
import SwiftUI

final class CiCdTestingUITests: CiCdSnapshotTestCase {

    func testDefaultAppearance() {
        let mainView = ContentView()
        snapshotTest(view: mainView, devices: [.iPhoneSe, .iPhone13])
    }
}
