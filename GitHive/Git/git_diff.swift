import Foundation

struct GitDiffRange {
    let start: Int
    let length: Int
}

struct GitDiffLine {
    let content: String
    let type: Character
    
    init?(line: String) {
        guard let firstChar = line.first else { return nil }
        type = firstChar
        content = String(line.dropFirst())
    }
}

struct GitDiffHunk {
    let oldRange: GitDiffRange
    let newRange: GitDiffRange
    let lines: [GitDiffLine]
}

struct GitDiff {
    let oldFile: String
    let newFile: String
    let hunks: [GitDiffHunk]
}

extension GitDiffHunk {
    init?(header: String, lines: [String]) {
        let tokens = header.components(separatedBy: " ")
        guard tokens.count == 4,
              let oldRange = GitDiffRange(from: tokens[1]),
              let newRange = GitDiffRange(from: tokens[2])
        else { return nil }
        
        self.oldRange = oldRange
        self.newRange = newRange
        
        var currentOldLine = oldRange.start
        var currentNewLine = newRange.start
        
        self.lines = lines.compactMap { line in
            guard let diffLine = GitDiffLine(line: line) else { return nil }
            
            switch diffLine.type {
            case " ":
                currentOldLine += 1
                currentNewLine += 1
            case "-":
                currentOldLine += 1
            case "+":
                currentNewLine += 1
            default:
                break
            }
            
            return diffLine
        }
    }
}

extension GitDiffRange {
    init?(from string: String) {
        let components = string.split(separator: ",")
        if let start = Int(components[0]), let length = components.last.flatMap({ Int($0) }) ?? Optional(1) {
            self.start = start
            self.length = length
        } else {
            return nil
        }
    }
}

func parseGitDiff(_ input: String) -> GitDiff? {
    let lines = input.components(separatedBy: .newlines)
    guard lines.count >= 5,
          lines[0].hasPrefix("diff --git"),
          let oldFile = lines[1].split(separator: " ").last.map(String.init),
          let newFile = lines[2].split(separator: " ").last.map(String.init),
          lines[3].hasPrefix("--- "),
          lines[4].hasPrefix("+++ ")
    else { return nil }
    
    var currentIndex = 5
    var hunks = [GitDiffHunk]()
    
    while currentIndex < lines.count {
        guard let header = lines[currentIndex].hasPrefix("@@ ") ? lines[currentIndex] : nil else {
            currentIndex += 1
            continue
        }
        
        let start = currentIndex + 1
        var end = start
        while end < lines.count, !lines[end].hasPrefix("@@ ") {
            end += 1
        }
        
        let hunkLines = Array(lines[start..<end])
        guard let hunk = GitDiffHunk(header: header, lines: hunkLines) else {
            currentIndex = end
            continue
        }
        
        hunks.append(hunk)
        currentIndex = end
    }
    
    return GitDiff(oldFile: oldFile, newFile: newFile, hunks: hunks)
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
