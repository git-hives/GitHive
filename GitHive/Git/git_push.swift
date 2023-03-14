//
//  git_push.swift
//  GitHive
//
//  Created by 1 on 3/14/23.
//

import Foundation

enum gitPushParam {
    case push
    case force          // 强制推送本地分支，并覆盖远程分支的修改
    case noVerify       // 跳过 Git 钩子的执行，强制将修改推送到远程仓库
    case tags
}


class GitPushHelper: runGit {
    
    //  使用正则匹配push结果
    static func matchPushResult(_ string: String) -> Bool {
        let pattern = "(?=.*\\.{2})(?=.*->)"
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
        return !matches.isEmpty
    }
    
    // git push
    static func pushAsync(LocalRepoDir: String, param: gitPushParam = .push, completion: @escaping (String?) -> Void) {
        var pushCmd: [String] = []
        switch param {
        case .push:
            pushCmd = ["push"]
        case .force:
            pushCmd = ["push", "--force"]
        case .noVerify:
            pushCmd = ["push", "--no-verify"]
        case .tags:
            pushCmd = ["push", "--tags"]
        }
        //print("git push命令行：", pushCmd)
        do_git_push_action = true
        runGit.executeGitAsync(at: LocalRepoDir, command: pushCmd) { output in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                do_git_push_action = false
            }
            guard var output = output else {
                return completion(nil)
            }
            print("git push命令运行结果:", output)
            if matchPushResult(output) {
                output = "push_success"
            }
            completion(output)
       }
    }
}
