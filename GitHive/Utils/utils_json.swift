//
//  json.swift
//  easy-git
//
//  Created by 1 on 3/4/23.
//

import Foundation


class JsonHelper {
    
    static func readJSON(fromFile filePath: String) -> [String: Any]? {
        guard FileManager.default.fileExists(atPath: filePath) else {
            print("JSON文件不存在！")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? [String: Any]
        } catch {
            print("读取JSON文件失败：\(error.localizedDescription)")
            return nil
        }
    }

    static func writeJSON(_ json: [String: Any], toFile filePath: String) -> Bool {
        if !FileManager.default.fileExists(atPath: filePath) {
            FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            
            let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: filePath))
            defer {
                fileHandle.closeFile()
            }
            fileHandle.truncateFile(atOffset: 0)
            try fileHandle.write(contentsOf: data)
            return true
        } catch {
            print("写入JSON文件失败：\(error.localizedDescription)")
            return false
        }
    }
}
