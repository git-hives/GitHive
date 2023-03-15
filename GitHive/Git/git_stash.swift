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
}

