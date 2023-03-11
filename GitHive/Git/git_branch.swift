//
//  git_branch.swift
//  easy-git
//
//  Created by 1 on 3/4/23.
//

import Foundation


class GitBranchHelper: runGit {
    
    // 获取当前分支信息。 git branch --show-current某些情况下无法获取到分支信息。弃用
    static func getShowCurrentBranchNameAsync(at LocalRepoDir: String, completion: @escaping (String) -> Void) {
        let result: String = ""
        let cmd: [String] = ["branch", "--show-current"]
        runGit.executeGitAsync(at: LocalRepoDir, command: cmd) { output in
            guard let output = output else {
                completion(result)
                return
            }
            let lines = output.replacingOccurrences(of: "\n", with: "")
            completion(lines)
        }
    }
    
    static func getCurrentBranchNameAsync(at LocalRepoDir: String, completion: @escaping (String) -> Void) {
        var result: String = ""
        let cmd: [String] = ["branch", "-l", "--format='%(HEAD)%(refname:short):%(objectname:short)'"]
        runGit.executeGitAsync(at: LocalRepoDir, command: cmd) { output in
            guard let output = output else {
                completion(result)
                return
            }
            let lines = output.split(separator: "\n")
            if !lines.isEmpty {
                for line in lines {
                    let data = line.replacingOccurrences(of: "\'", with: "")
                    if data.first == "*" {
                        let branch = data.split(separator: ":")
                        if data.contains("rebasing") {
                            result = branch[1] + "!" + " (rebasing)"
                        } else {
                            result = String(String(branch[0]).dropFirst())
                        }
                        break
                    }
                }
            }
            completion(result)
        }
    }
    
    // 分支切换
    static func switchBranch(at LocalRepoDir: String, at branchname: String) -> Bool {
        var result: Bool = false
        let cmd: [String] = ["checkout", branchname]
        let output = runGit.executeGit(at: LocalRepoDir, command: cmd)
        if let res = output {
            if res.contains("error:") {
                _ = showAlertOnlyPrompt(msgType: "warning", title: "", msg: res, ConfirmBtnText: "Ok")
            } else {
                result = true
            }
        }
        return result
    }
    
    static func refnameHandling(at name: String) -> [String]{
        var result: [String] = ["", ""]
        if name.contains("refs/heads/") {
            let r1 = name.replacingOccurrences(of: "refs/heads/", with: "")
            result = ["L", r1]
        } else if name.contains("refs/remotes/") {
            let r1 = name.replacingOccurrences(of: "refs/remotes/", with: "")
            result = ["R", r1]
        } else if name.contains("refs/tags/") {
            let r1 = name.replacingOccurrences(of: "refs/tags/", with: "tags/")
            result = ["T", r1]
        } else {
            result = ["other", name]
        }
        return result
    }
    
    // 分支：获取的本地、远程分支、以及tags
    static func getAllRefs(at LocalRepoDir: String, completion: @escaping ([Dictionary<String, Any>]) -> Void) {
        var dicts = [Dictionary<String, String>]()
        let cmd: [String] = ["for-each-ref", "--format='{\"refname\":\"%(refname)\",\"objectname\":\"%(objectname)\",\"authordate\":\"%(authordate:local)\",\"author\":\"%(authorname)\",\"subject\":\"%(subject)\"}'"
        ]
        
        runGit.executeGitAsync(at: LocalRepoDir, command: cmd) { output in
            guard let output = output else {
                completion(dicts)
                return
            }
            
            let lines = output.split(separator: "\n")
            for line in lines {
                let lineWithoutQuotes = line.replacingOccurrences(of: "\'", with: "")
                guard let data = lineWithoutQuotes.data(using: .utf8) else {
                    continue
                }
                do {
                    guard var dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
                        continue
                    }
                    dictionary["reftype"] = ""
                    dictionary["name"] = ""
                    if dictionary.contains(where: { $0.key == "refname" }) {
                        let tmp = refnameHandling(at: dictionary["refname"]!)
                        dictionary["reftype"] = tmp[0]
                        dictionary["name"] = tmp[1]
                    }
                    if dictionary["refname"] != "refs/remotes/origin/HEAD" {
                        dicts.append(dictionary)
                    }
                } catch {
                    print("Failed to deserialize line as JSON: \(line)")
                }
            }
            completion(dicts)
       }
    }
    
    // 分支：创建
    static func BranchCreate(LocalRepoDir: String, from: String, to: String, completion: @escaping (Bool) -> Void) {
        let cmd: [String] = ["checkout", "-b", to, from]
        runGit.executeGitAsync(at: LocalRepoDir, command: cmd) { output in
            guard let output = output else {
                completion(false)
                return
            }
            let lines = output.replacingOccurrences(of: "\n", with: "")
            print("Git分支创建结果: ", output)
            if lines.contains("Switched to a new branch") {
                completion(true)
            } else {
                _ = showAlertOnlyPrompt(msgType: "warning", title: "", msg: lines, ConfirmBtnText: "OK")
                completion(false)
            }
        }
    }
}