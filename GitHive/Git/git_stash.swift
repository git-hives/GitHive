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

func isDiffGitLine(_ line: String) -> Bool {
    let pattern = "^diff --git.*\n$"
    if let range = line.range(of: pattern, options: .regularExpression) {
        return range.lowerBound == line.startIndex && range.upperBound == line.endIndex
    }
    return false
}

// 解析 git stash show -p stash@{0}的输出
func parseDiffOutput(_ output: String) -> [(filename: String, content: String, addedLines: Int, deletedLines: Int)] {
    let pattern = #"diff --git a\/(?<filename>[\w\.]+) b\/\1\n.*?\n@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@.*?\n(?<content>[\s\S]+?)(?=diff|$)"#
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let matches = regex.matches(in: output, options: [], range: NSRange(output.startIndex..., in: output))
    return matches.map { match in
        let filenameRange = match.range(withName: "filename")
        let filename = String(output[Range(filenameRange, in: output)!])
        let contentRange = match.range(withName: "content")
        let content = String(output[Range(contentRange, in: output)!])
        let addedLines = match.range(at: 3).length
        let deletedLines = match.range(at: 5).length
        return (filename: filename, content: content, addedLines: addedLines, deletedLines: deletedLines)
    }
}

func splitString(_ str: String, delimiter: String) -> [String] {
    let components = str.components(separatedBy: delimiter)
    guard let lastComponent = components.last, components.count > 1 else {
        return [str]
    }
    let lastIndex = str.index(str.endIndex, offsetBy: -lastComponent.count - delimiter.count)
    var prefix = str[..<lastIndex]
    if prefix.first == " " {
        prefix.removeFirst()
    }
    return [String(prefix)] + [lastComponent]
}

class GitStashHelper: runGit {
    
    static func matchStashReference(_ str: String) -> String? {
        let regex = try! NSRegularExpression(pattern: #"stash@\{\d+\}"#)
        if let match = regex.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)) {
            return (str as NSString).substring(with: match.range)
        }
        return nil
    }
    
    // stash：获取Stash列表
    static func get(at LocalRepoDir: String)  async throws -> [String] {
        var result: [String] = []
        let cmd: [String] = ["stash", "list"]
        let output = try await executeGitAsync2(at: LocalRepoDir, command: cmd)
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        let lines = output.split(separator: "\n")
        result = lines.map {
            String($0)
        }
        return result
    }
    
    // stash: pop
    static func pop(LocalRepoDir: String) async throws -> String {
        let cmd: [String] = ["stash", "pop"]
        let output = try await executeGitAsync2(at: LocalRepoDir, command: cmd)
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        print("git stash pop结果：", output)
        if output.hasPrefix("Dropped refs/stash@{") {
            return "success"
        } else {
            return output
        }
    }
    
    // stash: apply
    static func apply(LocalRepoDir: String, name: String) async throws -> String {
        var stashName = name
        if !name.isEmpty {
            stashName = matchStashReference(name) ?? name
        }
        
        let cmd: [String] = ["stash", "apply", stashName]
        let output = try await executeGitAsync2(at: LocalRepoDir, command: cmd)
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        if output.hasPrefix("On branch") {
            return "success"
        } else {
            return output
        }
    }
    
    // stash: pop
    static func drop(LocalRepoDir: String, name: String) async throws -> String {
        var stashName = name
        if !name.isEmpty {
            if let matchResult = matchStashReference(name) {
                stashName = matchResult
            }
        }
        
        let cmd: [String] = ["stash", "drop", stashName]
        //print("git Stash drop命令行:", cmd)
        
        let output = try await executeGitAsync2(at: LocalRepoDir, command: cmd)
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        //print("git Stash drop结果:", output)
        if output.hasPrefix("Dropped \(stashName)") {
            return "success"
        } else {
            return output
        }
    }
    
    // stash: save
    static func save(LocalRepoDir: String, cmd: String) async throws -> String {
        let save_cmd = cmd.components(separatedBy: " ")
        let output = try await executeGitAsync2(at: LocalRepoDir, command: save_cmd)
        
        print("git Stash save命令行:", save_cmd)
        print("git Stash save结果:", output)
        
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        if output.contains("Saved") {
            return "success"
        } else {
            return output
        }
    }
    
    // stash: clear
    static func clear(LocalRepoDir: String) async throws -> String {
        let cmd: [String] = ["stash", "clear"]
        //print("git Stash drop命令行:", cmd)
        
        let output = try await executeGitAsync2(at: LocalRepoDir, command: cmd)
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        return output
    }
    
    
    // stash: 获取stash汇总信息
    // git show --numstat stash@{0} --pretty=format:'{"Commit Hash": "%H", "Author":"%an <%ae>", "AuthorDate": "%ad", "Parents": "%p", "Tree": "%T", "Message": "%s"}'
    static func showStashStat(LocalRepoDir: String, name: String) async throws -> (statFiles: [stashFileItem], statSummary: Dictionary<String, String>) {
        
        var statFiles: [stashFileItem] = []
        var statSummary: Dictionary<String, String> =  ["Tree": "", "Commit Hash": "", "AuthorDate": "", "Message": "", "Parents": "", "Author": ""]
        
        var stashName = name
        if !name.isEmpty {
            if let matchResult = matchStashReference(name) {
                stashName = matchResult
            }
        }
        
        let cmd: [String] = ["show", "--numstat", stashName, "--pretty=format:'{\"Commit Hash\": \"%H\", \"Author\":\"%an <%ae>\", \"AuthorDate\": \"%ad\", \"Parents\": \"%p\", \"Tree\": \"%T\", \"Message\": \"%s\"}'"]
        
        let output = try await executeGitAsync2(at: LocalRepoDir, command: cmd)
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        
        if output.isEmpty {
            return (statFiles, statSummary)
        }
        // 把命令行输出结果从字符串转成数组
        let result = output.split(separator: "\n")
        if result.count < 2 {
            return (statFiles, statSummary)
        }
        
        // 取数组第一项，即stash日期作者等信息
        let rawSummaryInfo = result[0]
        // 获取stash中的文件列表
        let rawFileList = result[1...]
        
        // 获取stash，包含日期、commitHash、作者等信息
        do {
            let lineWithoutQuotes = rawSummaryInfo.replacingOccurrences(of: "\'", with: "")
            guard let data = lineWithoutQuotes.data(using: .utf8) else {
                throw GitError.gitOutputParsingFailed
            }
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
                throw GitError.gitOutputParsingFailed
            }
            statSummary = dictionary
        } catch _ {
            throw GitError.gitOutputParsingFailed
        }
        
        // 解析文件列表
        for line in rawFileList {
            let info = line.split(separator: "\t")
            if info.count >= 3 {
                statFiles.append(stashFileItem(filename: String(info[2]), add_line: String(info[0]), del_line: String(info[1])))
            }
        }
        
        return (statFiles, statSummary)
    }
    
    // stash: details
    static func showDetails(LocalRepoDir: String, name: String) async throws -> String {
        var stashName = name
        if !name.isEmpty {
            if let matchResult = matchStashReference(name) {
                stashName = matchResult
            }
        }
        
        let cmd: [String] = ["stash", "show", "-p", stashName]
        let output = try await executeGitAsync2(at: LocalRepoDir, command: cmd)
        guard let output = output else {
            throw GitError.gitRunFailed
        }
        if output.isEmpty {
            return "error"
        }
        let input = """
        diff --git a/App.vue b/App.vue
        index 99f6e28..41e77c2 100644
        --- a/App.vue
        +++ b/App.vue
        @@ -7,11 +7,10 @@
                     console.log('App Show')
                 },
                 onHide: function() {
        -            console.log('App Hide')
        +            console.log('xxxApp Hide')
                 }
             }
         </script>
         
         <style>
        -    /*每个页面公共css */
         </style>
        """
        if let diff = parseGitDiff(input) {
            print(diff.oldFile) // "a/App.vue"
            print(diff.newFile) // "b/App.vue"
            print(diff.hunks.count) // 1
            print(diff.hunks[0].lines.count) // 6
        }
//        let ppp = showStashStat(output)
//        print(ppp)
//        print("-----------------------------")
//        print(output)
//        //print("git Stash drop结果:", output)
//        if output.hasPrefix("Dropped \(stashName)") {
//            return "success"
//        } else {
//            return output
//        }
        return output
    }
}

