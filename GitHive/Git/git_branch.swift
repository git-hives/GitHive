//
//  git_branch.swift
//  easy-git
//
//  Created by 1 on 3/4/23.
//

import Foundation

// 目前用于工具栏分支下拉列表
struct GitBranchItem: Identifiable {
    let id = UUID().uuidString
    let name: String
    let reftype: String
    let refname: String
//    let subject: String
    let authordate: String
    let authorname: String
}

// 用于分支视图
struct gitBranchItem2: Identifiable {
    let id = UUID().uuidString
    let name: String
    let objectname: String
    let authorname: String
    let authoremail: String
    let subject: String
    let reftype: String
}


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
    
    // 获取当前分支名称
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
    
    // 分支：获取本地所有分支
    static func getLocalBranchListAsync(at LocalRepoDir: String, completion: @escaping ([Dictionary<String, Any>]) -> Void)  {
        var result = [Dictionary<String, String>]()
        
        let formatForLocal = "--format='{\"name\": \"%(refname:short)\",\"objectname\":\"%(objectname)\",\"authorname\":\" %(authorname)\",\"authoremail\":\" %(authoremail) \",\"committername\":\"%(committername)\",\"committeremail\":\" %(committeremail)\",\"subject\":\" %(subject)\", \"reftype\": \"local\"}'"
        let cmd: [String] = ["branch", "-l", "-vv" ,formatForLocal]
        runGit.executeGitAsync(at: LocalRepoDir, command: cmd) { output in
            guard let output = output else {
                completion(result)
                return
            }
            let lines = output.split(separator: "\n")
            for line in lines {
                print(line)
                let lineWithoutQuotes = line.replacingOccurrences(of: "\'", with: "")
                guard let data = lineWithoutQuotes.data(using: .utf8) else {
                    continue
                }
                do {
                    guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
                        continue
                    }
                    result.append(dictionary)
                } catch {
                    print("Failed to deserialize line as JSON: \(line)")
                }
            }
            completion(result)
        }
    }
    
    // 分支：获取远程所有分支
    static func getRemoteBranchListAsync(at LocalRepoDir: String, completion: @escaping ([Dictionary<String, Any>]) -> Void)  {
        var result = [Dictionary<String, String>]()
        
        let formatForRemote = "--format='{\"name\": \"%(refname:short)\",\"objectname\":\"%(objectname)\",\"authorname\":\" %(authorname)\",\"authoremail\":\" %(authoremail) \",\"committername\":\"%(committername)\",\"committeremail\":\" %(committeremail)\",\"subject\":\" %(subject)\", \"reftype\": \"remote\"}'"
        let cmd: [String] = ["branch", "-r", "-vv" , formatForRemote]
        runGit.executeGitAsync(at: LocalRepoDir, command: cmd) { output in
            guard let output = output else {
                completion(result)
                return
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
                    if dictionary["name"] != "origin/HEAD" {
                        result.append(dictionary)
                    }
                } catch {
                    print("Failed to deserialize line as JSON: \(line)")
                }
            }
            completion(result)
        }
    }
    
    // 分支切换
    static func BranchSwitch(LocalRepoDir: String, name: String) -> Bool {
        var result: Bool = false
        let cmd: [String] = ["checkout", name]
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
    
    // 分支：切换
    static func BranchSwitchAsync(LocalRepoDir: String, name: String, completion: @escaping (Bool) -> Void) {
        let cmd = ["switch", name]
        runGit.executeGitAsync(at: LocalRepoDir, command: cmd) { output in
            guard let output = output else {
                completion(false)
                return
            }
            let lines = output.replacingOccurrences(of: "\n", with: "")
            if lines.isEmpty {
                completion(true)
            } else {
                _ = showAlertOnlyPrompt(msgType: "warning", title: "", msg: lines, ConfirmBtnText: "OK")
                completion(false)
            }
        }
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
        let cmd: [String] = ["for-each-ref", "--format='{\"refname\":\"%(refname)\",\"objectname\":\"%(objectname)\",\"authordate\":\"%(authordate:local)\",\"authorname\":\"%(authorname)\",\"subject\":\"%(subject)\"}'"
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
                    if dictionary["refname"] != "refs/remotes/origin/HEAD" && dictionary["refname"] != "refs/stash" {
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
    
    // 分支：删除
    static func BranchDelete(LocalRepoDir: String, name: String, DeleteType: String, completion: @escaping (Bool) -> Void) {
        var cmd: [String] = ["branch", "-D", name]
        if DeleteType == "remote" {
            let splitResult: [String] = splitString(name, delimiter: "/")
            cmd = ["push", splitResult[0], "--delete", splitResult[1]]
        }
        runGit.executeGitAsync(at: LocalRepoDir, command: cmd) { output in
            guard let output = output else {
                completion(false)
                return
            }
            let lines = output.replacingOccurrences(of: "\n", with: "")
            print("Git分支删除结果: ", output)
            if lines.contains("Deleted branch \(name)") || lines.contains("- [deleted]") {
                completion(true)
            } else {
                _ = showAlertOnlyPrompt(msgType: "warning", title: "", msg: lines, ConfirmBtnText: "OK")
                completion(false)
            }
        }
    }
    
    // 分支：重命名
    static func BranchRename(LocalRepoDir: String, cmd: [String], completion: @escaping (Bool) -> Void) {
        runGit.executeGitAsync(at: LocalRepoDir, command: cmd) { output in
            guard let output = output else {
                completion(false)
                return
            }
            let lines = output.replacingOccurrences(of: "\n", with: "")
            print("Git分支重命名结果: ", output)
            if lines.isEmpty {
                completion(true)
            } else {
                _ = showAlertOnlyPrompt(msgType: "warning", title: "", msg: lines, ConfirmBtnText: "OK")
                completion(false)
            }
        }
    }
    
}
