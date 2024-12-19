//
//  CiCdSnapshotTestCase.swift
//  CiCdTesting
//
//  Created by New on 18.12.24..
//

import Foundation
import SnapshotTesting
import SwiftUI
import XCTest

open class CiCdSnapshotTestCase: XCTestCase {
    public var isRecording = false
    private var hostingVc: UIViewController?
    
    open override func setUpWithError() throws {
        try super.setUpWithError()
        
        verifyDeviceTarget()
        SnapshotTesting.diffTool = "ksdiff"
    }
    
    public override func tearDown() {
        super.tearDown()
        hostingVc = nil
    }
    
    public struct Device {
        let config: ViewImageConfig
        let name: String
        public let layoutSource: LayoutSourceMock
    }
    
    public func snapshotTest<Value: Encodable>(
        matching: Value,
        as snapshotting: Snapshotting<Value, String>,
        named name: String? = nil,
        file: StaticString = #file,
        filePath: String = #filePath,
        testName: String = #function
    ) {
        let name = [testName, name].compactMap { $0 }.joined(separator: " ")
        
        let result = verifySnapshot(
            of: matching,
            as: snapshotting,
            record: isRecording,
            snapshotDirectory: snapshotDirectory(filePath),
            file: file,
            testName: normalize(name)
        )
        
        XCTAssertNil(result, errorMessage(name, filePath: filePath), file: file)
    }
    
    public func snapshotTest<Content: View>(
        view: Content,
        named name: String? = nil,
        precision: Float = 1,
        embedInNavigation: Bool = false,
        wait: TimeInterval? = nil,
        file: StaticString = #file,
        filePath: String = #filePath,
        testName: String = #function,
        devices: [Device] = .alliPhone,
        height: CGFloat? = nil
    ) {
        
        let rootView = view
        
        let vc = hostingVc ?? UIHostingController(rootView: rootView)
        hostingVc = vc
        
        devices.forEach { device in
            let snapshot: Snapshotting<UIViewController, UIImage>
            
            let size: CGSize = .init(
                width: device.config.size?.width ?? 375,
                height: height ?? device.config.size?.height ?? 667
            )
            
            ObservableLayout.shared.layoutSource = device.layoutSource
            vc.view.frame = CGRect(origin: .zero, size: size)
            
            if let wait = wait {
                snapshot = .wait(for: wait, on: .image(precision: precision, size: size, traits: device.config.traits))
            } else {
                snapshot = .image(precision: precision, size: size, traits: device.config.traits)
            }
            
            let name = [testName, name, device.name].compactMap { $0 }.joined(separator: " ")
            
            let result = verifySnapshot(
                of: vc,
                as: snapshot,
                record: isRecording,
                snapshotDirectory: snapshotDirectory(filePath),
                file: file,
                testName: normalize(name)
            )
            
            XCTAssertNil(result, errorMessage(name, filePath: filePath), file: file)
        }
    }
}

// MARK: - Testable Devices

extension CiCdSnapshotTestCase.Device {
    public static var iPhoneSe: Self {
        .init(
            config: .iPhoneSe,
            name: "iPhoneSE",
            layoutSource: LayoutSourceMock(
                screenBounds: CGRect(origin: .zero, size: ViewImageConfig.iPhoneSe.size ?? .zero),
                windowBounds: CGRect(origin: .zero, size: ViewImageConfig.iPhoneSe.size ?? .zero),
                traitCollection: .init(
                    traitsFrom: [
                        .init(horizontalSizeClass: .compact),
                        .init(verticalSizeClass: .regular),
                        .init(userInterfaceIdiom: .phone)
                    ]
                )
            )
        )
    }
    
    public static var iPhone13: Self {
        .init(config: .iPhone13,
              name: "iPhone13",
              layoutSource: LayoutSourceMock(
                screenBounds: CGRect(origin: .zero, size: ViewImageConfig.iPhone13.size ?? .zero),
                windowBounds: CGRect(origin: .zero, size: ViewImageConfig.iPhone13.size ?? .zero),
                traitCollection: .init(
                    traitsFrom: [
                        .init(horizontalSizeClass: .compact),
                        .init(verticalSizeClass: .regular),
                        .init(userInterfaceIdiom: .phone)
                    ]
                )
              )
        )
    }
    
    public static var iPhone13ProMax: Self {
        .init(config: .iPhone13ProMax,
              name: "iPhone13ProMax",
              layoutSource: LayoutSourceMock(
                screenBounds: CGRect(origin: .zero, size: ViewImageConfig.iPhone13ProMax.size ?? .zero),
                windowBounds: CGRect(origin: .zero, size: ViewImageConfig.iPhone13ProMax.size ?? .zero),
                traitCollection: .init(
                    traitsFrom: [
                        .init(horizontalSizeClass: .compact),
                        .init(verticalSizeClass: .regular),
                        .init(userInterfaceIdiom: .phone)
                    ]
                )
              )
        )
    }
    
    public static var iPadPro129Landscape: Self {
        .init(config: .iPadPro12_9(.landscape),
              name: "iPadPro12Landscape",
              layoutSource: LayoutSourceMock(
                screenBounds: CGRect(origin: .zero, size: ViewImageConfig.iPadPro12_9(.landscape).size ?? .zero),
                windowBounds: CGRect(origin: .zero, size: ViewImageConfig.iPadPro12_9(.landscape).size ?? .zero),
                traitCollection: .init(
                    traitsFrom: [
                        .init(horizontalSizeClass: .regular),
                        .init(verticalSizeClass: .regular),
                        .init(userInterfaceIdiom: .pad)
                    ]
                ),
                orientation: .landscapeRight,
                screenLayout: .full,
                layoutMode: .landscape)
        )
    }
}

extension Array where Element == CiCdSnapshotTestCase.Device {
    public static var alliPhone: Self {
        [
            .iPhoneSe,
            .iPhone13,
            .iPhone13ProMax
        ]
    }
    
    public static var alliPad: Self {
        [
            .iPadPro129Landscape
        ]
    }
    
    public static var all: Self {
        alliPhone + alliPad
    }
}

// MARK: - Device target verification

extension CiCdSnapshotTestCase {
    private func verifyDeviceTarget() {
        if !["iPhone14,6"].contains(internalIdentifier()) {
            /// We need to set the `continueAfterFailure = false` only when we want to stop
            /// the test execution. Otherwise, it wouldn't record multiple snapshots from
            /// one same test.
            continueAfterFailure = false
            XCTFail("Snapshot tests must run on iPhone SE (3rd generation)")
        }
    }
    
    private func verifyDeviceOS() {
        if UIDevice.current.systemVersion != "18.0" {
            continueAfterFailure = false
            XCTFail("Snapshot tests must run on iOS 18.0")
        }
    }
    
    private func snapshotDirectory(_ testFilePath: String) -> String {
        let testLastComponent = URL(fileURLWithPath: testFilePath).lastPathComponent
        let folderName = testLastComponent.replacingOccurrences(of: "Tests.swift", with: "")
        let currentLastComponent = URL(fileURLWithPath: #filePath).lastPathComponent
        return #filePath.replacingOccurrences(of: currentLastComponent, with: "ReferenceImages/\(folderName)")
    }
    
    private func normalize(_ testName: String) -> String {
        guard testName.starts(with: "test") else { return testName }
        return String(testName.suffix(testName.count - 4))
    }
    
    private func errorMessage(_ testName: String, filePath: String) -> String {
        let lastComponent = URL(fileURLWithPath: filePath).lastPathComponent
        let testClass = lastComponent.replacingOccurrences(of: "Tests.swift", with: "")
        let method = testName.replacingOccurrences(of: "()", with: "")
        return "\(testClass).\(method) does not match reference snapshot."
    }
}

/// The model identifier of the current device (e.g., "iPhone9,2").
private func internalIdentifier() -> String {
    if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
        return simulatorModelIdentifier
    }
    
    var systemInfo = utsname()
    uname(&systemInfo)
    
    let machine = systemInfo.machine
    let mirror = Mirror(reflecting: machine)
    var identifier = ""
    
    for child in mirror.children {
        if let value = child.value as? Int8, value != 0 {
            identifier.append(String(UnicodeScalar(UInt8(value))))
        }
    }
    
    return identifier
}


//extension SnapshotTestCase {
//    private func verifyDeviceTarget() {
//            if !["iPhone14,6"].contains(internalIdentifier()) {
//                /// We need to set the `continueAfterFailure = false` only when we want to stop
//                /// the test execution. Otherwise, it wouldn't record multiple snapshots from
//                /// one same test.
//                continueAfterFailure = false
//                XCTFail("Snapshot tests must run on iPhone SE (3rd generation)")
//            }
//        }
//
//        private func verifyDeviceOS() {
//            if UIDevice.current.systemVersion != "18.0" {
//                continueAfterFailure = false
//                XCTFail("Snapshot tests must run on iOS 18.0")
//            }
//        }
//
//        private func snapshotDirectory(_ testFilePath: String) -> String {
//            let testLastComponent = URL(fileURLWithPath: testFilePath).lastPathComponent
//            let folderName = testLastComponent.replacingOccurrences(of: "Tests.swift", with: "")
//            let currentLastComponent = URL(fileURLWithPath: #filePath).lastPathComponent
//            return #filePath.replacingOccurrences(of: currentLastComponent, with: "ReferenceImages/\(folderName)")
//        }
//
//        private func normalize(_ testName: String) -> String {
//            guard testName.starts(with: "test") else { return testName }
//            return String(testName.suffix(testName.count - 4))
//        }
//
//        private func errorMessage(_ testName: String, filePath: String) -> String {
//            let lastComponent = URL(fileURLWithPath: filePath).lastPathComponent
//            let testClass = lastComponent.replacingOccurrences(of: "Tests.swift", with: "")
//            let method = testName.replacingOccurrences(of: "()", with: "")
//            return "\(testClass).\(method) does not match reference snapshot."
//        }
//    }
//
//    /// The model identifier of the current device (e.g., "iPhone9,2").
//    private func internalIdentifier() -> String {
//        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
//            return simulatorModelIdentifier
//        }
//
//        var systemInfo = utsname()
//        uname(&systemInfo)
//
//        let machine = systemInfo.machine
//        let mirror = Mirror(reflecting: machine)
//        var identifier = ""
//
//        for child in mirror.children {
//            if let value = child.value as? Int8, value != 0 {
//                identifier.append(String(UnicodeScalar(UInt8(value))))
//            }
//        }
//
//        return identifier
//    }
//
//}
