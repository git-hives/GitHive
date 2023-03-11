//
//  runGit.swift
//  easy-git
//
//  Created by 1 on 2/21/23.
//

import Foundation
import Cocoa


enum GitError: Error {
    case preCheckFailed
    case gitPathNotFound
    case changeGitDirectoryFailed
    case gitRunFailed
}

class runGit {
    
    static var customGitPath: String?
    static var osGitPath: String = ""
    
    static var PreCheckResult: Bool = true
    
    // 获取Git路径
    static func getGitPath() -> String? {
        var gitPath: String?
        if let customGitPath = customGitPath {
            gitPath = customGitPath
        } else if osGitPath != "" {
            gitPath = osGitPath
        } else {
            // 查找shell路径
            let processInfo = ProcessInfo.processInfo
            let environment = processInfo.environment
            let shellPath = environment["SHELL"]  ?? ""
            
            let whichTask = Process()
            whichTask.launchPath = shellPath
            whichTask.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"]
            whichTask.arguments = ["-l", "-c", "which git"]

            let whichPipe = Pipe()
            whichTask.standardOutput = whichPipe
            whichTask.standardError = whichPipe
            whichTask.launch()
            
            let whichData = whichPipe.fileHandleForReading.readDataToEndOfFile()
            gitPath = String(data: whichData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            
        }
        
        guard let gitPath = gitPath else {
            print("Failed to find git command.")
            return nil
        }
        osGitPath = gitPath
        
        // Check if git path exists and is executable
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: gitPath) {
            return nil
        }
        if !fileManager.isExecutableFile(atPath: gitPath) {
            return nil
        }
        //print("[查找] Git路径 = ", gitPath)
        return gitPath
    }
    
    // 检查当前传入的路径是否是Git项目
    static func isGitRepository(atPath gitDir: String, gitPath: String) -> Bool {
        guard FileHelper.checkPathExists(atPath: gitDir, checkType: "dir") else {
            return false
        }
        
        // 检查是否是git仓库的命令
        let command = "rev-parse --is-inside-work-tree"

        let task = Process()
        task.launchPath = gitPath
        task.arguments = command.components(separatedBy: " ")
        task.currentDirectoryPath = gitDir

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.launch()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return output == "true"
    }
    
    // 检查git路径是否存在、检查是否是有效的Git仓库
    static func PreCheck(at path: String)  ->  [String: String] {
        var lastResult = ["type": "error" ,"errMsg": "", "data": ""]
        
        // 获取Git路径
        guard let gitPath = getGitPath() else {
            print("Failed to find git command.")
            PreCheckResult = false
            lastResult["errMsg"] = "Failed to find git command. Please check if the Git command line tool is installed."
            return lastResult
        }
        
        // 检查是否是Git仓库
        let isGit = isGitRepository(atPath: path, gitPath: gitPath)
        if !isGit {
            PreCheckResult = false
            lastResult["errMsg"] = "The current path is not a valid Git repository."
            return lastResult
        }
        
        PreCheckResult = true
        lastResult["type"] = "success"
        return lastResult
    }
    
    // 执行Git命令行
    static func executeGit(at path: String, command: [String]) -> String? {
        if path.isEmpty {
            return nil
        }
        if !PreCheckResult {
            return nil
        }
        
        if osGitPath == "" {
            guard getGitPath() != nil else {
                return nil
            }
        }
        
        // 切换目录
        let fileManager = FileManager.default
        guard fileManager.changeCurrentDirectoryPath(path) else {
            print("Failed to change directory to: \(path)")
            return nil
        }
        
        // Launch the git command with the found git path
        let task = Process()
        task.launchPath = osGitPath
        task.arguments = command
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
        } catch let error {
            print("Failed to run task with error: \(error.localizedDescription)")
            return nil
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        return output
    }
    
    // 执行Git命令行
    static func executeGitAsync(at path: String, command: [String], completion: @escaping (String?) -> Void) {
        if !PreCheckResult {
            completion(nil)
            return
        }
        
        if osGitPath == "" {
            guard getGitPath() != nil else {
                completion(nil)
                return
            }
        }
        
        // 切换目录
        let fileManager = FileManager.default
        guard fileManager.changeCurrentDirectoryPath(path) else {
            print("Failed to change directory to: \(path)")
            completion(nil)
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            // Launch the git command with the found git path
            let task = Process()
            task.launchPath = osGitPath
            task.arguments = command
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            do {
                try task.run()
            } catch let error {
                print("Failed to run task with error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)
            DispatchQueue.main.async {
                completion(output)
            }
        }
    }
}








