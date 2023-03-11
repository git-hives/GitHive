//
//  os_file_path.swift
//  easy-git
//
//  Created by 1 on 3/4/23.
//

import Foundation


class FileHelper {

    // 检查路径是否存在，当checkType=dir时，会判断是否是目录
    static func checkPathExists(atPath path: String, checkType: String) -> Bool {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: path) else {
            return false
        }
        
        if checkType == "Dir" {
            var isDirectory: ObjCBool = false
            if !fileManager.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
                return false
            }
        }
        return true
    }
    
    // 获取路径basename
    static func getPathBasename(asPath path: String) -> String {
        guard checkPathExists(atPath: path, checkType: "dir") else {
            return ""
        }
        return URL(fileURLWithPath: path).lastPathComponent
    }
    
}


