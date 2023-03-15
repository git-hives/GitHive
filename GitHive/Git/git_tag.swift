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
    
    // Tag：获取本地所有tag
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
    
    // Tag：删除
    static func deleteAsync(LocalRepoDir: String, name: String, DeleteType: String) async throws -> String {
        var cmd: [String] = ["tag", "-d", name]
        if DeleteType == "Remote" {
            cmd = ["push", "origin", "--delete", name]
        }
        
        let output = try await executeGitAsync2(at: LocalRepoDir, command: cmd)
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        //print("Git Tag删除结果: ", output)
        
        let lines = output.replacingOccurrences(of: "\n", with: "")
        if lines.contains("Deleted tag") || lines.contains("- [deleted]") {
            return "success"
        } else {
            return output
        }
    }
}
