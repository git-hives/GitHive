//
//  utils.swift
//  easy-git
//
//  Created by 1 on 2/24/23.
//

import Cocoa
import Foundation


class appSettingHelper {
    
    static func getSessionJsonFilePath() -> String {
        guard let appDir = getAppSupportDirectory() else {
            return ""
        }
        
        let sessionFilePath = appDir + "/" + appSessionFileName
        return sessionFilePath
    }
    
    static func writeSessionJsonFile(key: String, value: String) {
        print("[正在读写配置文件]...... Session.json")
        let sessionFile = getSessionJsonFilePath()
        if sessionFile.isEmpty {
           return
        }
        
        var fileContent = [String : Any]()
        
        var readFileContent = JsonHelper.readJSON(fromFile: sessionFile)
        
        if let dict = readFileContent {
            readFileContent?[key] = value
            if key == "lastGitProjectDir" {
                if dict.keys.contains("gitRepoList") {
                    let gitRepoList = dict["gitRepoList"]
                    if var gitRepoList = gitRepoList as? [String] {
                        if !gitRepoList.contains(value) {
                            gitRepoList.insert(value, at: 0)
                            readFileContent?["gitRepoList"] = gitRepoList
                        }
                    } else {
                        readFileContent?["gitRepoList"] = [value]
                    }
                } else {
                    readFileContent?["gitRepoList"] = [value]
                }
            }
            fileContent = readFileContent!
        } else {
            fileContent[key] = value
            if key == "lastGitProjectDir" {
                fileContent["gitRepoList"] = [value]
            }
        }
        let writeResult = JsonHelper.writeJSON(fileContent, toFile: sessionFile)
        print("json文件写入结果: ", writeResult)
    }
    
    static func readSessionJsonFile<T>(key: String, defaultValue: T) -> T {
        let sessionFilePath = getSessionJsonFilePath()

        guard let fileContent = JsonHelper.readJSON(fromFile: sessionFilePath),
              let result = fileContent[key] as? T else {
            return defaultValue
        }

        return result
    }
}


