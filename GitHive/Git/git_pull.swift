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

class GitPullHelper: runGit {
    
    // git pull
    static func pullAsync(LocalRepoDir: String, param: gitPullParam = .rebase, completion: @escaping (String?) -> Void) {
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
        //print("git pull命令行：", pullCmd)
        do_git_pull_action = true
        runGit.executeGitAsync(at: LocalRepoDir, command: pullCmd) { output in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                do_git_pull_action = false
            }
            guard let output = output else {
                completion(nil)
                return
            }
            print("git pull命令运行结果:", output)
            completion(output)
       }
    }
    
}
