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
    static func DeleteAsync(LocalRepoDir: String, name: String, DeleteType: String, completion: @escaping (Bool) -> Void) {
        var cmd: [String] = ["tag", "-d", name]
        if DeleteType == "Remote" {
            cmd = ["push", "origin", "--delete", name]
        }
        runGit.executeGitAsync(at: LocalRepoDir, command: cmd) { output in
            guard let output = output else {
                completion(false)
                return
            }
            let lines = output.replacingOccurrences(of: "\n", with: "")
            print("Git Tag删除结果: ", output)
            if lines.contains("Deleted tag") || lines.contains("- [deleted]") {
                completion(true)
            } else {
                _ = showAlertOnlyPrompt(msgType: "warning", title: "", msg: lines, ConfirmBtnText: "OK")
                completion(false)
            }
        }
    }
}
