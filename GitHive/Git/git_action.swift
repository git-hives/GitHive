//
//  git_action.swift
//  easy-git
//
//  Created by 1 on 3/4/23.
//

import Cocoa
import Foundation


class GitAction: runGit {
    
    // git behind and ahead
    static func get_behind_ahead_num(LocalRepoDir: String) -> [String: String] {
        var result = ["behind": "", "ahead": ""]
        
        let cmd_behind = ["rev-list", "--count", "HEAD..@{u}"]
        let behind_result = executeGit(at: LocalRepoDir, command: cmd_behind)
        if let behind_result = behind_result {
            let behind = behind_result.trimmingCharacters(in: .newlines)
            if behind.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil && behind != "0" {
                result["behind"] = behind
            }
        }
        
        let cmd_ahead = ["rev-list", "--count", "@{u}..HEAD"]
        let ahead_result = executeGit(at: LocalRepoDir, command: cmd_ahead)
        if let ahead_result = ahead_result {
            let ahead = ahead_result.trimmingCharacters(in: .newlines)
            if ahead.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil && ahead != "0" {
                result["ahead"] = ahead
            }
        }
        return result
    }
    
    // git behind
    static func get_behind_num(LocalRepoDir: String) -> [String: String] {
        var result = ["behind": ""]
        
        let cmd_behind = ["rev-list", "--count", "HEAD..@{u}"]
        let behind_result = executeGit(at: LocalRepoDir, command: cmd_behind)
        if let behind_result = behind_result {
            let behind = behind_result.trimmingCharacters(in: .newlines)
            if behind.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil && behind != "0" {
                result["behind"] = behind
            }
        }
        return result
    }
    
    // git ahead
    static func get_ahead_num(LocalRepoDir: String) -> [String: String] {
        var result = ["ahead": ""]
        let cmd_ahead = ["rev-list", "--count", "@{u}..HEAD"]
        let ahead_result = executeGit(at: LocalRepoDir, command: cmd_ahead)
        
        if let ahead_result = ahead_result {
            let ahead = ahead_result.trimmingCharacters(in: .newlines)
            if ahead.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil && ahead != "0" {
                result["ahead"] = ahead
            }
        }
        return result
    }
    
    // git add
    static func add(LocalRepoDir: String, filePath: String) -> [String:String] {
        var result = ["status": "success", "msg": ""]
        let cmd: [String] = ["add", filePath]
        //print("git add 传入的参数:", cmd)
        let output = runGit.executeGit(at: LocalRepoDir, command: cmd)
        let lines = output?.split(separator: "\n") ?? []
        if !lines.isEmpty {
            result["status"] = "fail"
            result["msg"] = output!
        }
        return result
    }
    
    // git restore
    static func restore(LocalRepoDir: String, filePath: String) -> [String:String] {
        var result = ["status": "success", "msg": ""]
        let cmd: [String] = ["restore", filePath]
        let output = runGit.executeGit(at: LocalRepoDir, command: cmd)
        let lines = output?.split(separator: "\n") ?? []
        if !lines.isEmpty {
            result["status"] = "fail"
            result["msg"] = output!
        }
        return result
    }
    
    // git restore
    static func restoreStaged(LocalRepoDir: String, filePath: String) -> [String:String] {
        var result = ["status": "success", "msg": ""]
        let cmd: [String]  = ["restore", "--staged", filePath]
        //print("git restore --stage命令工具:", cmd)
        let output = runGit.executeGit(at: LocalRepoDir, command: cmd)
        let lines = output?.split(separator: "\n") ?? []
        if !lines.isEmpty {
            result["status"] = "fail"
            result["msg"] = output!
        }
        return result
    }
    
    // git clean -df
    static func cleanDF(LocalRepoDir: String, filePath: String) -> Bool {
        // 删除操作，弹窗，需要用户确认是否删除
        var message = "Delete file " + filePath + " ?"
        if filePath == "*" {
            message = "This will delete all untracked files in the working directory. \n\n Are you sure you want to continue?"
        }
        let userSelected:Bool = showAlert(title: "", msg: message, ConfirmBtnText: "Delete")
        if !userSelected {
            return false
        }

        let cmd: [String]  = ["clean", "-d", "-f",filePath]
        let output = runGit.executeGit(at: LocalRepoDir, command: cmd)
        let lines = output?.split(separator: "\n") ?? []
        //print("git clean -df: 执行结果", lines)
        
        let checkResult = lines.allSatisfy { $0.contains("Removing") }
        if !checkResult {
            let gitMsg = "Failed to delete file。\n\n" + output!
            _ = showAlert(title: "", msg: gitMsg, ConfirmBtnText: "Delete")
            return false
        }
        return true
    }
    
    // git commit && git push
    static func gitCommitPush() {
        
    }
    
}
