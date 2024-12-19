//
//  UIWindowScene+Extension.swift
//  CiCdTesting
//
//  Created by New on 18.12.24..
//

import Foundation
import UIKit

public extension UIWindowScene {
    static var layoutDidChangeNotification: Notification.Name = .init("UIWindowSceneLayoutDidChange")
    static var traitCollectionUserDataKey: String = "traitCollectionUserDataKey"
}
