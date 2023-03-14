//
//  git_pull.swift
//  GitHive
//
//  Created by 1 on 3/14/23.
//

import Foundation

enum gitPullParam {
    case pull
    case rebase
    case rebaseAutoStash
    case ffOnly
}


// 截取第二个换行符之前的字符
func extractString(in sourceString: String, before: String, after: String) -> String? {
    do {
        if let startRange = sourceString.range(of: after),
            let endRange = sourceString.range(of: before) {
                let result = try? String(sourceString[startRange.lowerBound..<endRange.lowerBound])
                return result
        } else {
            return nil
        }
    } catch {
        return nil
    }
}


class GitPullHelper: runGit {
    
    static func matchPullResult(_ result: String) -> Bool {
        let pattern = "[0-9a-zA-Z]+\\.\\.[0-9a-zA-Z]+"
        return result.range(of: pattern, options: .regularExpression) != nil
    }
    
    // git pull
    static func pullAsync(LocalRepoDir: String, param: gitPullParam = .rebase) async throws -> [String:String] {
        var pullCmd: [String] = []
        switch param {
        case .pull:
            pullCmd = ["pull"]
        case .rebase:
            pullCmd = ["pull", "--rebase"]
        case .rebaseAutoStash:
            pullCmd = ["pull", "--rebase", "--autostash"]
        case .ffOnly:
            pullCmd = ["pull", "--ff-only"]
        }
        
        do_git_pull_action = true
        var pullResult = ["type": "error" ,"msg": ""]
        
        let output = try await executeGitAsync2(at: LocalRepoDir, command: pullCmd)
        guard var output = output else {
            throw GitError.gitRunFailed
        }
        
        // 使用正则匹配 aeaeb29..4a8768b
        let isMatch = matchPullResult(output)
        
        //print("git pull命令运行结果:", output)
        if output.contains("git pull <remote>") {
            if let extractedString = extractString(in: output, before: "See git-pull", after: "There is no tracking") {
                pullResult["msg"] = extractedString
            } else {
                pullResult["msg"] = output
            }
        } else if output.contains("Already up to date.") || isMatch {
            pullResult["type"] = "success"
        } else {
            pullResult["msg"] = output
        }
        return pullResult
    }
    
}
