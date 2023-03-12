//
//  git_tag.swift
//  GitHive
//
//  Created by 1 on 3/12/23.
//

import Foundation

struct gitTagItem: Identifiable {
    let id = UUID().uuidString
    let name: String
}


class GitTagHelper: runGit {
    
    // 分支：获取本地所有tag
    static func getTagListAsync(at LocalRepoDir: String, completion: @escaping ([String]) -> Void)  {
        var result: [String] = []
        let cmd: [String] = ["tag", "--list"]
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
