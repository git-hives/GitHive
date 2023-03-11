//
//  git_files_view.swift
//  easy-git
//
//  Created by 1 on 2/22/23.
//

import SwiftUI
import Foundation
import Combine


struct GitStatusItem: Identifiable {
    let id = UUID().uuidString
    let status: String
    let path: String
}

// 用于标识Git status 文件状态所属分类
enum innerFileStatus {
    case Modified
    case Staged
    case Untracked
    case Unmerged
}

struct git_files_view: View {
    @EnvironmentObject var GitObservable: GitObservable
    
    @State private var GitMessage: String = ""
    @State private var isCheckGitMessage: Bool = false
    @State private var checkPlaceholder: String = "Git提交消息不能为空"
    @State private var placeholder: String = "Git提交消息(回车提交)"
    
    @State private var gitFilesListForModified: [GitStatusItem] = []
    @State private var gitFilesListForStated: [GitStatusItem] = []
    @State private var gitFilesListForUntracked: [GitStatusItem] = []
    @State private var gitFilesListForUnmerged: [GitStatusItem] = []
    
    @State private var isManuallyTriggerTheExecutionOfGit: Bool = false
    
    var isCommitButtonDisabled: Bool {
        GitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || gitFilesListForStated.isEmpty
    }
    
    var GitRepoLocalPath: String {
        GitObservable.GitProjectPathProperty
    }
    
    var body: some View {
        VStack() {
            view_git_message_input
            
            ScrollView(.vertical, showsIndicators: true) {
                view_git_files
            }
            .padding(.bottom, 20)
            .font(.callout)
        }
        .onAppear() {
            showGitStatusFileList()
        }
        .onChange(of: GitRepoLocalPath) { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showGitStatusFileList()
            }
        }
        .onChange(of: GitObservable.GitBranchProperty) { value in
            self.isManuallyTriggerTheExecutionOfGit = true
            showGitStatusFileList()
        }
        .onChange(of: GitObservable.monitoring_git_HEAD) { value in
            if !isManuallyTriggerTheExecutionOfGit && (!do_git_pull_action && !do_git_push_action) {
                showGitStatusFileList()
            }
        }
        .onChange(of: GitObservable.monitoring_git_index) { value in
            if !isManuallyTriggerTheExecutionOfGit && (!do_git_pull_action && !do_git_push_action) {
                showGitStatusFileList()
            }
        }
        .onChange(of: GitObservable.monitoring_project_file) { value in
            if !isManuallyTriggerTheExecutionOfGit && (!do_git_pull_action && !do_git_push_action) {
                showGitStatusFileList()
            }
        }
    }
    
    var view_git_message_input: some View {
        VStack {
            if #available(macOS 13.0, *) {
                TextField(isCheckGitMessage ? checkPlaceholder : placeholder, text: $GitMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.white)
                    .lineLimit(3)
                    .onSubmit {
                        gitCommit()
                    }
            } else {
                TextField(isCheckGitMessage ? checkPlaceholder : placeholder, text: $GitMessage)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(.white)
                    .lineLimit(3)
                    .onSubmit {
                        gitCommit()
                    }
            }
            
            HStack {
                Button(action: { gitCommit() }, label: {
                    Label("commit", systemImage: "checkmark")
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(Color.blue.opacity(0.95))
                        .foregroundColor(.white)
                        .cornerRadius(3.0)
                })
                .disabled(isCommitButtonDisabled)
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}, label: {
                    Label("", systemImage: "paperplane")
                        .frame(maxWidth: .infinity, minHeight: 28, alignment: .center)
                        .background(Color.blue.opacity(0.95))
                        .foregroundColor(.white)
                        .cornerRadius(3.0)
                })
                .frame(width: 40)
                .disabled(isCommitButtonDisabled)
                .buttonStyle(PlainButtonStyle())
                .help("commit & push")
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 15)
    }
    
    // 视图：更改的文件
    var view_git_files: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 更改的文件
            GitShowFilesListView(repoDir: GitRepoLocalPath, gitSection: .Modified, gitFilesList: gitFilesListForModified, refreshAction: { showGitStatusFileList() }, isManually: $isManuallyTriggerTheExecutionOfGit)
            
            // 暂存的文件
            GitShowFilesListView(repoDir: GitRepoLocalPath, gitSection: .Staged, gitFilesList: gitFilesListForStated, refreshAction: { showGitStatusFileList() }, isManually: $isManuallyTriggerTheExecutionOfGit)
            
            // 未跟踪的文件
            if !gitFilesListForUntracked.isEmpty {
                GitShowFilesListView(repoDir: GitRepoLocalPath, gitSection: .Untracked, gitFilesList: gitFilesListForUntracked, refreshAction: { showGitStatusFileList() }, isManually: $isManuallyTriggerTheExecutionOfGit)
            }
            
            // 合并更改冲突
            if !gitFilesListForUnmerged.isEmpty {
                GitShowFilesListView(repoDir: GitRepoLocalPath, gitSection: .Unmerged, gitFilesList: gitFilesListForUnmerged, refreshAction: { showGitStatusFileList() }, isManually: $isManuallyTriggerTheExecutionOfGit)
            }
        }
    }
    
    
    // 操作：git commit 提交
    func gitCommit() {
        let trimmed = GitMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            self.isCheckGitMessage.toggle()
            return
        }
        let cmd: [String] = ["commit", "-m", self.GitMessage]
        let output = runGit.executeGit(at: GitRepoLocalPath, command: cmd)
        //print("Git commit -m: ", output)
        if ((output?.contains("changed")) != nil) {
            self.GitMessage = ""
            showGitStatusFileList()
        }
        
        let gitBehindAhead = GitAction.get_behind_ahead_num(LocalRepoDir: GitRepoLocalPath)
        GitObservable.GitAhead = gitBehindAhead["ahead"] ?? ""
        GitObservable.GitBehind = gitBehindAhead["behind"] ?? ""
    }
    
    
    func showGitStatusFileList() {
        print("[获取文件列表] --> 项目路径： ",GitRepoLocalPath)
        let result = getAndParseGitStatusResult(at: GitRepoLocalPath)
        DispatchQueue.main.async {
            self.gitFilesListForUntracked = result.untracked
            self.gitFilesListForModified = result.modified
            self.gitFilesListForStated = result.staged
            self.gitFilesListForUnmerged = result.unmerged
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isManuallyTriggerTheExecutionOfGit = false
        }
    }
}


struct GitShowFilesListView: View {
    var repoDir: String
    var gitSection: innerFileStatus = .Modified
    var gitFilesList: [GitStatusItem]
    //var action_add: (() -> Void)?
    var refreshAction: () -> Void
    @Binding var isManually: Bool
    
    @State var SectionTile: String = ""
    @State var iconFoldStatus: Bool = true
    @State var hoverSection: Bool = false
    @State var hoverFileItemId: String = ""
    @State var hoverFilePath: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack() {
                GitFileSectionTitleDisplayAndOperation(
                    iconStatus: iconFoldStatus,
                    title: SectionTile + " (\(gitFilesList.count))",
                    action: {
                        self.iconFoldStatus.toggle()
                    }
                )
                Spacer()
                if hoverSection && !gitFilesList.isEmpty {
                    section_icon_action_view
                }
            }
            .padding(.trailing, 10)
            .frame(height: 24)
            .background(hoverSection ? .gray.opacity(0.1) : .clear)
            .onAppear() {
                switch gitSection {
                case .Unmerged:
                    SectionTile = "Unmerged Files"
                case .Untracked:
                    SectionTile = "Untracked Files"
                case .Staged:
                    SectionTile = "Staged Files"
                case .Modified:
                    SectionTile = "Modified File"
                }
            }
            .onHover { isHovered in
                self.hoverSection = isHovered
            }
            .contextMenu {
                if !gitFilesList.isEmpty {
                    section_contextMenu_action_view
                }
            }
            
            if iconFoldStatus {
                ForEach(gitFilesList, id: \.id) { item in
                    HStack {
                        showGitFilePath(path: item.path, status: item.status)
                        Spacer()

                        if hoverFileItemId == item.id {
                            file_item_icon_action_view
                        }
                        showGitFileStatus(status: item.status)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 24)
                    .background(hoverFileItemId.contains(item.id) ? Color.gray.opacity(0.1) : Color.clear)
                    .onHover { isHovered in
                        hoverFileItemId = isHovered ? item.id : ""
                        hoverFilePath = isHovered ? item.path : ""
                        if isHovered && item.status == "R " {
                            let components = hoverFilePath.components(separatedBy: " -> ")
                            hoverFilePath = components.last ?? hoverFilePath
                        }
                    }
                    .contextMenu {
                        contextMenu_fileItem_View
                    }
                }
            }
        }
    }
    
    var contextMenu_fileItem_View: some View {
        Section {
            file_item_contextMenu_action_view

            Divider()
            Button("Reveal in Finder") {
                let absPath = self.repoDir + "/" + hoverFilePath
                RevealInFinder(at: absPath)
            }
            Button("Copy File Path") {
                let absPath = self.repoDir + "/" + hoverFilePath
                copyToPasteboard(at: absPath)
            }
        }
    }
    
    // 所有文件: icon点击事件
    var section_icon_action_view: some View {
        Section {
            if gitSection == .Staged {
                ActionButton(lableStyle: "2", title: "", systemImageName: "arrow.counterclockwise", helpText: "Unstage All File", action: {g_restore_staged(filepath: "*", source: "section_icon_action_view")})
            }
            if gitSection == .Modified {
                ActionButton(lableStyle: "2", title: "", systemImageName: "arrow.counterclockwise", helpText: "Discard All Modified File", action: {g_restore(filepath: ".")})
                ActionButton(lableStyle: "2", title: "", systemImageName: "plus", helpText: "Stage All Modified File", action: {g_add(filepath: ".")})
            }
            if gitSection == .Unmerged {
                ActionButton(lableStyle: "2", title: "", systemImageName: "plus", helpText: "Stage All Unmerged File", action: {g_add(filepath: ".")})
            }
            if gitSection == .Untracked {
                ActionButton(lableStyle: "2", title: "", systemImageName: "multiply", helpText: "Delete All Untracked File", action: {g_cleanDF(filePath: "*")})
                ActionButton(lableStyle: "2", title: "", systemImageName: "plus", helpText: "Stage All Untracked File", action: {g_add(filepath: ".")})
            }
        }
    }
    
    // 所有文件: 右键菜单
    var section_contextMenu_action_view: some View {
        Section {
            if gitSection == .Staged {
                ActionButtonForMenu(title: "Unstage All Files", action: { g_restore_staged(filepath: ".") })
            }
            if gitSection == .Modified {
                ActionButtonForMenu(title: "Stage All Modified Files", action: { g_add(filepath: ".") })
                ActionButtonForMenu(title: "Discard All Modified Files", action: { g_restore(filepath: ".") })
            }
            if gitSection == .Unmerged {
                ActionButtonForMenu(title: "Stage All Unmerged Files", action: { g_add(filepath: ".") })
            }
            if gitSection == .Untracked {
                ActionButtonForMenu(title: "Stage All Untracked Files", action: { g_add(filepath: ".") })
                ActionButtonForMenu(title: "Delete All Untracked Files", action: { g_cleanDF(filePath: "*") })
            }
        }
    }
    
    // 单个文件: icon点击事件
    var file_item_icon_action_view: some View {
        Section {
            if gitSection == .Staged {
                ActionButton(lableStyle: "", title: "Unstage", systemImageName: "minus", helpText: "Unstage", action: { g_restore_staged(filepath: hoverFilePath) })
            }
            if gitSection == .Modified {
                ActionButton(lableStyle: "", title: "Discard", systemImageName: "arrow.counterclockwise", helpText: "Discard", action: { g_restore(filepath: hoverFilePath) })
                ActionButton(lableStyle: "", title: "Stage", systemImageName: "plus", helpText: "Stage", action: { g_add(filepath: hoverFilePath) })
            }
            if gitSection == .Unmerged {
                ActionButton(lableStyle: "", title: "Stage", systemImageName: "plus", helpText: "Stage", action: { g_add(filepath: hoverFilePath) })
            }
            if gitSection == .Untracked {
                ActionButton(lableStyle: "", title: "Delete", systemImageName: "multiply", helpText: "Delete", action: { g_cleanDF(filePath: hoverFilePath) })
                ActionButton(lableStyle: "", title: "Stage", systemImageName: "plus", helpText: "Stage", action: { g_add(filepath: hoverFilePath) })
            }
        }
    }
    
    // 单个文件: 右键菜单
    var file_item_contextMenu_action_view: some View {
        Section {
            if gitSection == .Staged {
                ActionButtonForMenu(title: "Unstage", action: { g_restore_staged(filepath: hoverFilePath) })
            }
            if gitSection == .Modified {
                ActionButtonForMenu(title: "Stage", action: { g_add(filepath: hoverFilePath) })
                ActionButtonForMenu(title: "Discard", action: { g_restore(filepath: hoverFilePath) })
            }
            if gitSection == .Unmerged {
                ActionButtonForMenu(title: "Discard", action: { g_add(filepath: hoverFilePath) })
            }
            if gitSection == .Untracked {
                ActionButtonForMenu(title: "Stage", action: { g_add(filepath: hoverFilePath) })
                ActionButtonForMenu(title: "Delete", action: { g_cleanDF(filePath: hoverFilePath) })
            }
        }
    }
    
    func g_add(filepath: String) {
        isManually = true
        let result = GitAction.add(LocalRepoDir: repoDir, filePath: filepath)
        if (result["status"] == "success") {
            refreshAction()
        }
    }
    
    func g_restore(filepath: String) {
        isManually = true
        let result = GitAction.restore(LocalRepoDir: repoDir, filePath: filepath)
        if (result["status"] == "success") {
            refreshAction()
        }
    }
    
    func g_restore_staged(filepath: String, source: String = "") {
        isManually = true
        let result = GitAction.restoreStaged(LocalRepoDir: repoDir, filePath: filepath)
        if (result["status"] == "success") {
            refreshAction()
        }
    }
    
    func g_cleanDF(filePath: String) {
        isManually = true
        let result = GitAction.cleanDF(LocalRepoDir: repoDir, filePath: filePath)
        if (result) {
            refreshAction()
        }
    }
}


// 视图：段落标题，主要是：Modified Files
struct GitFileSectionTitleDisplayAndOperation: View {
    var iconStatus: Bool
    var title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label("", systemImage: iconStatus ? "chevron.down" : "chevron.right")
                .labelStyle(.iconOnly)
                .font(.caption)
                .padding(.leading, 10)
                .frame(width: 15)
            
            Text(title)
                .fontWeight(.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 视图：操作按钮
struct ActionButton: View {
    let lableStyle: String
    let title: String
    let systemImageName: String
    let helpText: String
    let action: () -> Void
    
    @State private var isHoverIcon: Bool = false

    var body: some View {
        Button(action: action) {
            if lableStyle == "1" {
                Label(title, systemImage: systemImageName)
                    .frame(maxWidth: .infinity, minHeight: 28)
                    .background(Color.blue.opacity(0.95))
                    .foregroundColor(.white)
                    .cornerRadius(3.0)
            } else {
                Label(title, systemImage: systemImageName)
                    .labelStyle(.iconOnly)
                    .frame(width: 20,height: 20)
                    .background(isHoverIcon ? .gray.opacity(0.2) : .clear)
                    .cornerRadius(5)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered in
            isHoverIcon = isHovered ? true : false
        }
        .help(helpText)
    }
}


// 视图：显示git文件路径
struct showGitFilePath: View {
    let path: String
    let status: String
    
    var body: some View {
        Text(path)
            .foregroundColor(.black.opacity(0.7))
            .strikethrough(String(status).contains("D"), color: .secondary)
            .truncationMode(.middle)
            .help(path)
    }
}


// 视图：显示git文件状态，比如D、A
struct showGitFileStatus: View {
    let status: String
    
    var body: some View {
        Text(status)
            .foregroundColor(String(status).contains("D") ? Color.red : Color.primary)
    }
}

// 解析git status -su命令行返回结果
func getAndParseGitStatusResult(at localRepoDir: String) -> (untracked: [GitStatusItem], modified: [GitStatusItem], staged: [GitStatusItem], unmerged: [GitStatusItem])  {
    
    // Git文件路径列表, 暂时无用
    //var gitChangeFilePathList: [String] = []
    
    var gitUntrackedList: [GitStatusItem] = []
    var gitModifiedList: [GitStatusItem] = []
    var gitStatedList: [GitStatusItem] = []
    var gitUnmergedList: [GitStatusItem] = []
    
    let output = runGit.executeGit(at: localRepoDir, command: ["status", "-su"])
    if output == nil { return ([], [], [], []) }
    let lines = output?.split(separator: "\n") ?? []
    
    for i in lines {
        var status: String = String(i.prefix(2))
        var filepath: String = String(i.suffix(from: i.index(i.startIndex, offsetBy: 3)))
        if filepath.hasPrefix("\"") && filepath.hasSuffix("\"") {
            filepath = String(filepath.dropFirst().dropLast())
        }
        // MD CA U N !! C
        if status == "??" {
            gitUntrackedList.append(GitStatusItem(status: "?", path: filepath))
        } else if [" M", " D"].contains(status){
            status = status.trimming()
            gitModifiedList.append(GitStatusItem(status: status, path: filepath))
        } else if ["M ", "D ", "A ", "R "].contains(status) {
            status = status.trimming()
            gitStatedList.append(GitStatusItem(status: status, path: filepath))
        } else if ["DD","AU","UD","UA","DU","AA","UU"].contains(status) {
            gitUnmergedList.append(GitStatusItem(status: status, path: filepath))
        } else if ["AD" ,"AM", "MM", "RM"].contains(status){
            if status == "MM" {
                status = "M"
            }
            gitModifiedList.append(GitStatusItem(status: status, path: filepath))
            gitStatedList.append(GitStatusItem(status: status, path: filepath))
        } else {
            gitModifiedList.append(GitStatusItem(status: status, path: filepath))
        }
    }
    
    return (untracked: gitUntrackedList, modified: gitModifiedList, staged: gitStatedList, unmerged: gitUnmergedList)
}


struct git_files_view_Previews: PreviewProvider {
    static var previews: some View {
        git_files_view()
    }
}
