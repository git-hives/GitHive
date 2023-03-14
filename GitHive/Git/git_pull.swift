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
    
    // git pull
    static func pullAsync(LocalRepoDir: String, param: gitPullParam = .rebase, completion: @escaping ([String:String]) -> Void) {
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
        
        runGit.executeGitAsync(at: LocalRepoDir, command: pullCmd) { output in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                do_git_pull_action = false
            }
            
            guard let output = output else {
                completion(pullResult)
                return
            }
            
            if output.contains("git pull <remote>") {
                if let extractedString = extractString(in: output, before: "See git-pull", after: "There is no tracking") {
                    pullResult["msg"] = extractedString
                } else {
                    pullResult["msg"] = output
                }
            } else if output.contains("Already up to date.") {
                pullResult["type"] = "success"
            } else {
                pullResult["msg"] = output
            }
            completion(pullResult)
       }
    }
    
}
