//
//  git_fetch.swift
//  GitHive
//
//  Created by 1 on 3/14/23.
//

import Foundation

enum gitFetchParam {
    case fetch
    case fetchPrune
    case fetchTags
}


class GitFetchHelper: runGit {
    
    static func matchFetchResult(_ result: String) -> Bool {
        let pattern = "[0-9a-zA-Z]+\\.\\.[0-9a-zA-Z]+"
        return result.range(of: pattern, options: .regularExpression) != nil
    }
    
    // git fetch
    static func fetchAsync(LocalRepoDir: String, param: gitFetchParam = .fetch) async throws -> String? {
        var fetchCmd: [String] = []
        switch param {
        case .fetch:
            fetchCmd = ["fetch"]
        case .fetchPrune:
            fetchCmd = ["fetch", "--prune"]
        case .fetchTags:
            fetchCmd = ["fetch", "--tags"]
        }
        
        let output = try await executeGitAsync2(at: LocalRepoDir, command: fetchCmd)
        
        guard let output = output else {
            return nil
        }
        //print("git fetch命令运行结果:", output)
        
        let isMatch = matchFetchResult(output)
        
        if  output.count == 0 {
            return nil
        }
        if output.contains("error") {
            return output
        }
        if output.contains("-> ") || isMatch {
            return "success"
        }
        if output.hasSuffix("sqlite3_open_v2\n") {
            return nil
        }
        return output
    }
    
}
