//
//  ObservableLayout.swift
//  CiCdTesting
//
//  Created by New on 18.12.24..
//

import Foundation
import UIKit
import Combine
import SwiftUI

// MARK: - ObservableLayout

public enum LayoutMode {
    case landscape
    case portrait
    case unknown
}

public enum ScreenLayout {
    case full
    case oneThird
    case half
    case twoThirds
    case unknown
}

public final class ObservableLayout: ObservableObject {
    public static let shared: ObservableLayout = ObservableLayout()

    public var layoutSource: LayoutSourceProtocol = LayoutSource() {
        willSet {
            willChange()
        }
        didSet {
            layoutSource.delegate = self
        }
    }

    public var orientation: UIInterfaceOrientation {
        layoutSource.orientation
    }
    public var screenLayout: ScreenLayout {
        layoutSource.screenLayout
    }
    public var mode: LayoutMode {
        layoutSource.layoutMode
    }
    public var screenBounds: CGRect {
        layoutSource.screenBounds
    }
    public var windowBounds: CGRect {
        layoutSource.windowBounds
    }

    public var horizontalSizeClass: UserInterfaceSizeClass {
        UserInterfaceSizeClass(layoutSource.traitCollection.horizontalSizeClass) ?? .regular
    }
    public var verticalSizeClass: UserInterfaceSizeClass {
        UserInterfaceSizeClass(layoutSource.traitCollection.verticalSizeClass) ?? .regular
    }

    func willChange() {
        objectWillChange.send()
    }

    private init() {
        layoutSource.delegate = self
    }
}

// MARK: - LayoutSourceDelegate

extension ObservableLayout: LayoutSourceDelegate {
    public func layoutSourceWillChange(_ layoutSource: LayoutSourceProtocol) {
        willChange()
    }
}

public protocol LayoutSourceDelegate: AnyObject {
    func layoutSourceWillChange(_ layoutSource: LayoutSourceProtocol)
}

// MARK: - LayoutSourceProtocol

public protocol LayoutSourceProtocol {
    var orientation: UIInterfaceOrientation { get }
    var screenLayout: ScreenLayout { get }
    var layoutMode: LayoutMode { get }
    var screenBounds: CGRect { get }
    var windowBounds: CGRect { get }
    var traitCollection: UITraitCollection { get }

    var delegate: LayoutSourceDelegate? { get set }
}

// MARK: - LayoutSource

public class LayoutSource: LayoutSourceProtocol {

    public weak var delegate: LayoutSourceDelegate?

    public var orientation: UIInterfaceOrientation {
        guard let scene = UIApplication.shared.connectedScenes.first,
           let sceneDelegate = scene as? UIWindowScene  else {
            return .unknown
        }
        return  sceneDelegate.interfaceOrientation
    }

    public var screenLayout: ScreenLayout {
        guard let keyWindow = UIApplication.shared.keyWindow else {
            return .unknown
        }
        let screenSize = UIScreen.main.bounds
        let windowSize = keyWindow.bounds

        if windowSize == screenSize {
            return .full
        }

        let ratio: CGFloat = windowSize.width / screenSize.width

        if ratio >= 0.45 && ratio <= 0.55 {
            return .half
        } else if ratio > 0.55 {
            return .twoThirds
        } else {
            return .oneThird
        }
    }

    public var screenBounds: CGRect {
        UIScreen.main.bounds
    }

    public var windowBounds: CGRect {
        guard let keyWindow = UIApplication.shared.keyWindow else {
            return .zero
        }
        return keyWindow.bounds
    }

    public private(set) var traitCollection: UITraitCollection = .current

    public var layoutMode: LayoutMode {
        switch (orientation, screenLayout) {
            case (orientation, .full) where orientation.isLandscape:
                return .landscape
            default:
                return .portrait
        }
    }

    private var subscriptions = Set<AnyCancellable>()

    public init() {
        NotificationCenter.default.publisher(
            for: UIWindowScene.layoutDidChangeNotification
        )
            .merge(
                with: NotificationCenter.default.publisher(
                    for: UIDevice.orientationDidChangeNotification
                )
            )
            .sink { [weak self] notification in
                guard let self = self else { return }

                self.delegate?.layoutSourceWillChange(self)

                if let traitCollection = notification.userInfo?[UIWindowScene.traitCollectionUserDataKey] as? UITraitCollection {
                    self.traitCollection = traitCollection
                }
            }
            .store(in: &subscriptions)

    }
}

// MARK: - LayoutSourceMock
public class LayoutSourceMock: LayoutSourceProtocol {
    public weak var delegate: LayoutSourceDelegate?

    public var orientation: UIInterfaceOrientation
    public var screenLayout: ScreenLayout
    public var layoutMode: LayoutMode
    public var screenBounds: CGRect
    public var windowBounds: CGRect
    public var traitCollection: UITraitCollection

    public init(
        screenBounds: CGRect,
        windowBounds: CGRect,
        traitCollection: UITraitCollection,
        orientation: UIInterfaceOrientation = .portrait,
        screenLayout: ScreenLayout = .full,
        layoutMode: LayoutMode = .portrait
    ) {
        self.orientation = orientation
        self.screenLayout = screenLayout
        self.layoutMode = layoutMode
        self.screenBounds = screenBounds
        self.windowBounds = windowBounds
        self.traitCollection = traitCollection
    }

    public func willChange() {
        delegate?.layoutSourceWillChange(self)
    }
}
