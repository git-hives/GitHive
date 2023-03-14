//
//  git_fetch.swift
//  GitHive
//
//  Created by 1 on 3/14/23.
//

import Foundation

enum gitFetchParam {
    case fetch
}


class GitFetchHelper: runGit {
    
    // git fetch
    static func fetchAsync(LocalRepoDir: String, param: gitFetchParam = .fetch, completion: @escaping (String?) -> Void) {
        var fetchCmd: [String] = []
        switch param {
        case .fetch:
            fetchCmd = ["fetch"]
        }
        
        runGit.executeGitAsync(at: LocalRepoDir, command: fetchCmd) { output in
            guard let output = output else {
                return completion(nil)
            }
            //print("git fetch命令运行结果:", output)
            if  output.count == 0 {
                return completion(nil)
            }
            if output.contains("error") {
                return completion("network_error")
            }
            if output.contains("-> ") {
                return completion("success")
            }
            completion(output)
       }
    }
    
}
