//
//  utils.swift
//  easy-git
//
//  Created by 1 on 2/24/23.
//

import Cocoa
import Foundation

// 获取应用程序数据目录
func getAppSupportDirectory() -> String? {
    let applicationSupportURLs = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)

    if let applicationSupportURL = applicationSupportURLs.first {
        let appSupportURL = applicationSupportURL.appendingPathComponent(appName)
        
        if FileManager.default.fileExists(atPath: appSupportURL.path) {
            return appSupportURL.path
        }
        
        do {
            try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
            return appSupportURL.path
        } catch {
            print("无法创建应用程序支持目录：\(error.localizedDescription)")
        }
    } else {
        print("无法获取应用程序支持目录")
    }
    return nil
}


