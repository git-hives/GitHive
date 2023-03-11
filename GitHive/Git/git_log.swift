//
//  git_log.swift
//  easy-git
//
//  Created by hx on 3/10/23.
//

import Foundation

class GitLog: runGit {
    
    static func get(LocalRepoDir: String, cmd: [String], completion: @escaping ([Dictionary<String, Any>]) -> Void) {
        
        var result = [Dictionary<String, String>]()
        var cmd: [String] = ["log", "--pretty=format:'{\"abbrHash\":\"%h\",\"CommitHash\":\"%H\",\"Author\":\"%an\",\"Email\":\"%ae\",\"Date\":\"%ad\",\"Message\":\"%s\"}'", "-n", "100"]
        
        runGit.executeGitAsync(at: LocalRepoDir, command: cmd) { output in
            guard let output = output else {
                return completion(result)
            }
            let lines = output.split(separator: "\n")
            for line in lines {
                let lineWithoutQuotes = line.replacingOccurrences(of: "\'", with: "")
                guard let data = lineWithoutQuotes.data(using: .utf8) else {
                    continue
                }
                do {
                    guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
                        continue
                    }
                    result.append(dictionary)
                } catch { }
            }
            completion(result)
        }
    }
}
