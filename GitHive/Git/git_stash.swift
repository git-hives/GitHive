//
//  git_stash.swift
//  GitHive
//
//  Created by 1 on 3/12/23.
//

import Foundation

struct gitStashItem: Identifiable {
    let id = UUID().uuidString
    let name: String
}

func isDiffGitLine(_ line: String) -> Bool {
    let pattern = "^diff --git.*\n$"
    if let range = line.range(of: pattern, options: .regularExpression) {
        return range.lowerBound == line.startIndex && range.upperBound == line.endIndex
    }
    return false
}

// 解析 git stash show -p stash@{0}的输出
func parseDiffOutput(_ output: String) -> [(filename: String, content: String, addedLines: Int, deletedLines: Int)] {
    let pattern = #"diff --git a\/(?<filename>[\w\.]+) b\/\1\n.*?\n@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@.*?\n(?<content>[\s\S]+?)(?=diff|$)"#
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let matches = regex.matches(in: output, options: [], range: NSRange(output.startIndex..., in: output))
    return matches.map { match in
        let filenameRange = match.range(withName: "filename")
        let filename = String(output[Range(filenameRange, in: output)!])
        let contentRange = match.range(withName: "content")
        let content = String(output[Range(contentRange, in: output)!])
        let addedLines = match.range(at: 3).length
        let deletedLines = match.range(at: 5).length
        return (filename: filename, content: content, addedLines: addedLines, deletedLines: deletedLines)
    }
}

func splitString(_ str: String, delimiter: String) -> [String] {
    let components = str.components(separatedBy: delimiter)
    guard let lastComponent = components.last, components.count > 1 else {
        return [str]
    }
    let lastIndex = str.index(str.endIndex, offsetBy: -lastComponent.count - delimiter.count)
    var prefix = str[..<lastIndex]
    if prefix.first == " " {
        prefix.removeFirst()
    }
    return [String(prefix)] + [lastComponent]
}

class GitStashHelper: runGit {
    
    static func matchStashReference(_ str: String) -> String? {
        let regex = try! NSRegularExpression(pattern: #"stash@\{\d+\}"#)
        if let match = regex.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)) {
            return (str as NSString).substring(with: match.range)
        }
        return nil
    }
    
    // stash：获取Stash列表
    static func get(at LocalRepoDir: String)  async throws -> [String] {
        var result: [String] = []
        let cmd: [String] = ["stash", "list"]
        let output = try await executeGitAsync2(at: LocalRepoDir, command: cmd)
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        let lines = output.split(separator: "\n")
        result = lines.map {
            String($0)
        }
        return result
    }
    
    // stash: pop
    static func pop(LocalRepoDir: String) async throws -> String {
        let cmd: [String] = ["stash", "pop"]
        let output = try await executeGitAsync2(at: LocalRepoDir, command: cmd)
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        print("git stash pop结果：", output)
        if output.hasPrefix("Dropped refs/stash@{") {
            return "success"
        } else {
            return output
        }
    }
    
    // stash: apply
    static func apply(LocalRepoDir: String, name: String) async throws -> String {
        var stashName = name
        if !name.isEmpty {
            stashName = matchStashReference(name) ?? name
        }
        
        let cmd: [String] = ["stash", "apply", stashName]
        let output = try await executeGitAsync2(at: LocalRepoDir, command: cmd)
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        if output.hasPrefix("On branch") {
            return "success"
        } else {
            return output
        }
    }
    
    // stash: pop
    static func drop(LocalRepoDir: String, name: String) async throws -> String {
        var stashName = name
        if !name.isEmpty {
            if let matchResult = matchStashReference(name) {
                stashName = matchResult
            }
        }
        
        let cmd: [String] = ["stash", "drop", stashName]
        //print("git Stash drop命令行:", cmd)
        
        let output = try await executeGitAsync2(at: LocalRepoDir, command: cmd)
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        //print("git Stash drop结果:", output)
        if output.hasPrefix("Dropped \(stashName)") {
            return "success"
        } else {
            return output
        }
    }
    
    
    // stash: stash summary
    static func showStashStat(LocalRepoDir: String, name: String) async throws -> (statFiles: [[String]], statSummary: String) {
        var statFiles: [[String]] = []
        var statSummary: String = ""
        
        let cmd: [String] = ["stash", "show", "--stat", name]
        let output = try await executeGitAsync2(at: LocalRepoDir, command: cmd)
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        if output.isEmpty {
            return (statFiles, statSummary)
        }
        
        let result = output.split(separator: "\n")
        if !result.isEmpty {
            let total = result.count
            for (index, value) in result.enumerated() {
                if index < total{
                    let tmp = splitString(String(value), delimiter: " | ")
                    statFiles.append(tmp)
                }
                if index + 1 == total {
                    statSummary = String(value)
                }
            }
        }
        
        return (statFiles, statSummary)
    }
    
    // stash: details
    static func showDetails(LocalRepoDir: String, name: String) async throws -> String {
        var stashName = name
        if !name.isEmpty {
            if let matchResult = matchStashReference(name) {
                stashName = matchResult
            }
        }
        
        let stashStat = try await showStashStat(LocalRepoDir: LocalRepoDir, name: stashName)
        print(stashStat)
        
        let cmd: [String] = ["stash", "show", "-p", stashName]
        let output = try await executeGitAsync2(at: LocalRepoDir, command: cmd)
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        if output.isEmpty {
            return "error"
        }
//        let ppp = showStashStat(output)
//        print(ppp)
//        print("-----------------------------")
//        print(output)
//        //print("git Stash drop结果:", output)
//        if output.hasPrefix("Dropped \(stashName)") {
//            return "success"
//        } else {
//            return output
//        }
        return output
    }
}

