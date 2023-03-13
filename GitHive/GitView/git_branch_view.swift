//
//  git_branch_view.swift
//  easy-git
//
//  Created by 1 on 2/23/23.
//

import SwiftUI

struct git_branch_view: View {
    @EnvironmentObject var GitObservable: GitObservable
    
    @State private var LocalBranchList: [gitBranchItem2] = []
    @State private var remoteBranchList: [gitBranchItem2] = []
    @State private var rawLocalBranchList: [gitBranchItem2] = []
    @State private var rawRemoteBranchList: [gitBranchItem2] = []
    
    @State private var searchText: String = ""
    
    @State private var selectedItemId: String = ""
    @State private var selectedItem: String = ""
    
    @State private var hoverItemId: String = ""
    
    @State var iconFoldLocal: Bool = false
    @State var iconFoldRemote: Bool = false
    
    var repoPath: String {
        GitObservable.GitProjectPathProperty
    }
    
    var currentBranch: String {
        GitObservable.GitBranchProperty
    }
    
    var body: some View {
        VStack() {
            view_filter
            
            ScrollView(.vertical, showsIndicators: true) {
                view_local_branch
                view_remote_branch
            }
        }
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                getGitAllBranchList(repoPath: repoPath)
            }
            
        }
        .onChange(of: repoPath) { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                getGitAllBranchList(repoPath: repoPath)
            }
        }
        .onChange(of: GitObservable.GitBranchProperty) { value in
            getGitAllBranchList(repoPath: repoPath)
        }
        .onChange(of: GitObservable.monitoring_git_push) { value in
            getGitAllBranchList(repoPath: repoPath)
        }
    }
    
    var view_filter: some View {
        SearchTextField(text: $searchText, placeholder: "Filter Branch Name")
            .padding(.vertical, 15)
            .onSubmit {
                filterBranch()
            }
            .onChange(of: searchText) { value in
                filterBranch()
            }
    }
    
    // 视图：本地分支
    var view_local_branch: some View {
        Section {
            HStack {
                GitBranchSectionTitleDisplayAndOperation(iconStatus: iconFoldLocal, title: "Local Branchs (\(LocalBranchList.count))", action: {
                    self.iconFoldLocal.toggle()
                })
                Spacer()
            }
            .frame(height: 30)
            
            if !iconFoldLocal {
                ForEach(LocalBranchList, id:\.id) { item in
                    show_branch(repoPath: repoPath, item: item, currentBranch: currentBranch, selectedItemId: $selectedItemId, hoverItemId: $hoverItemId, refreshAction: { getGitAllBranchList(repoPath: repoPath) })
                }
            }
        }
        .padding(.trailing, 7)
    }
    
    // 视图: 远程分支
    var view_remote_branch: some View {
        Section {
            HStack {
                GitBranchSectionTitleDisplayAndOperation(iconStatus: iconFoldRemote, title: "Remote Branchs (\(remoteBranchList.count))", action: {
                    self.iconFoldRemote.toggle()
                })
                Spacer()
            }
            .frame(height: 30)
            
            if !iconFoldRemote {
                ForEach(remoteBranchList, id:\.id) { item in
                    show_branch(repoPath: repoPath, item: item, currentBranch: currentBranch, selectedItemId: $selectedItemId, hoverItemId: $hoverItemId, refreshAction: { getGitAllBranchList(repoPath: repoPath) })
                }
            }
        }
        .padding(.trailing, 7)
    }
    
    // 分支列表：获取git 分支列表
    func getGitAllBranchList(repoPath: String) {
        if repoPath.isEmpty {
            return
        }
        
        // 获取本地分支
        var localList: [gitBranchItem2] = []
        GitBranchHelper.getLocalBranchListAsync(at: repoPath) { output in
            if let bList = output as? [Dictionary<String, String>] {
                for i in bList {
                    localList.append(gitBranchItem2(name: i["name"]!, objectname: i["objectname"]!, authorname: i["authorname"]!, authoremail: i["authoremail"]!, subject: i["subject"]!, reftype: i["reftype"]!))
                }
            }
            if !localList.isEmpty {
                DispatchQueue.main.async {
                    self.LocalBranchList = localList
                    self.rawLocalBranchList = localList
                }
            }
        }
        
        // 获取远程分支
        var remoteList: [gitBranchItem2] = []
        GitBranchHelper.getRemoteBranchListAsync(at: repoPath) { output in
            if let bList = output as? [Dictionary<String, String>] {
                for i in bList {
                    remoteList.append(gitBranchItem2(name: i["name"]!, objectname: i["objectname"]!, authorname: i["authorname"]!, authoremail: i["authoremail"]!, subject: i["subject"]!, reftype: i["reftype"]!))
                }
            }
            if !remoteList.isEmpty {
                DispatchQueue.main.async {
                    self.remoteBranchList = remoteList
                    self.rawRemoteBranchList = remoteList
                }
            }
        }
    }
    
    // 过滤分支
    func filterBranch() {
        let fileterText = self.searchText.trimming()
        
        self.LocalBranchList = self.rawLocalBranchList
        self.remoteBranchList = self.rawRemoteBranchList
        
        if fileterText.isEmpty {
            return
        }
        self.LocalBranchList = self.rawLocalBranchList.filter {
            $0.name.contains(fileterText)
        }
        
        self.remoteBranchList = self.rawRemoteBranchList.filter {
            $0.name.contains(fileterText)
        }
    }
}

// 视图：分支
private struct show_branch: View {
    var repoPath: String
    var item: gitBranchItem2
    var currentBranch: String
    
    @Binding var selectedItemId: String
    @Binding var hoverItemId: String
    var refreshAction: () -> Void
    
    @State private var showCreateBranchWindow: Bool = false
    @State private var showRenameBranchWindow: Bool = false
    
    @State private var selectedBranchName: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if currentBranch == item.name {
                    Text("* \(item.name)")
                        .foregroundColor(selectedItemId == item.id ? .white : .primary)
                        .fontWeight(.bold)
                } else {
                    Text(item.name)
                        .foregroundColor(selectedItemId == item.id ? .white : .primary)
                }
                
                Spacer()
            }
        }
        .frame(height: 24)
        .padding(.horizontal, 10)
        .background(hoverItemId == item.id ? Color.gray.opacity(0.1) : Color.clear)
        .background(selectedItemId == item.id  ? Color.blue.opacity(0.95) : Color.clear)
        .cornerRadius(3)
        .onTapGesture {
            self.selectedItemId = item.id
        }
        .onHover { isHovered in
            hoverItemId = isHovered ? item.id : ""
        }
        .contextMenu {
            if item.reftype == "local" {
                Button("Switch Branch to \(item.name)", action: {
                    self.selectedItemId = item.id
                    _ = GitBranchHelper.BranchSwitch(LocalRepoDir: repoPath, name: item.name)
                })
                .disabled(currentBranch == item.name)
            }
            Divider()
            Button("Create Branch", action: {
                self.selectedItemId = item.id
                self.showCreateBranchWindow = true
                self.selectedBranchName = item.name
            })
            Divider()
            Button("Merge \(item.name) into xxx", action: {
                self.selectedItemId = item.id
            })
            Divider()
            if item.reftype == "local" {
                Button("Rename...", action: {
                    self.selectedItemId = item.id
                    self.showRenameBranchWindow = true
                })
                Button("Delete \(item.name)", action: {
                    self.selectedItemId = item.id
                    branchDelete(name: item.name, DeleteType: "local")
                })
                .disabled(currentBranch == item.name)
            }
            if item.reftype == "remote" {
                Button("Delete \(item.name)", action: {
                    self.selectedItemId = item.id
                    branchDelete(name: item.name, DeleteType: "remote")
                })
            }
            Divider()
            Button("Copy Branch Name to Clipboard", action: {
                self.selectedItemId = item.id
                copyToPasteboard(at: item.name)
            })
        }
        .sheet(isPresented: $showCreateBranchWindow) {
            git_branch_create_view(projectPath: repoPath, userSelectedRef: selectedBranchName, isShowWindow: $showCreateBranchWindow)
        }
        .sheet(isPresented: $showRenameBranchWindow) {
            ui_alert_with_inputbox(isPresented: $showRenameBranchWindow, title: "Branch Rename", placeholder: "New Branch Name", onConfirm: { value in
                if !value.isEmpty {
                    branchRename(source: item.name, target: value)
                }
            })
        }
    }
    
    // 删除本地分支和远程分支
    func branchDelete(name: String, DeleteType: String) {
        let isDelete = showAlert(title: "Delete Branch \(name)?", msg: "", ConfirmBtnText: "Delete")
        if !isDelete {
            return
        }
        GitBranchHelper.BranchDelete(LocalRepoDir: repoPath, name: name, DeleteType: DeleteType) { output in
            if output == true {
                refreshAction()
            }
        }
    }
    
    // 重命名本地分支
    func branchRename(source: String, target: String) {
        let cmd = ["branch", "-m", source, target]
        GitBranchHelper.BranchRename(LocalRepoDir: repoPath, cmd: cmd) { output in
            if output == true {
                refreshAction()
            }
        }
    }
}


// 视图：段落标题
private struct GitBranchSectionTitleDisplayAndOperation: View {
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


struct git_branch_view_Previews: PreviewProvider {
    static var previews: some View {
        git_branch_view()
    }
}
