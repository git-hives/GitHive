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
    
    // 分支：获取Stash列表
    static func getStashListAsync(at LocalRepoDir: String, completion: @escaping ([String]) -> Void)  {
        var result: [String] = []
        let cmd: [String] = ["stash", "list"]
        runGit.executeGitAsync(at: LocalRepoDir, command: cmd) { output in
            guard let output = output else {
                completion(result)
                return
            }
            let lines = output.split(separator: "\n")
            result = lines.map {
                String($0)
            }
            completion(result)
        }
    }
}

