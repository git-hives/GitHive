//
//  git_branch_view.swift
//  easy-git
//
//  Created by 1 on 2/23/23.
//

import SwiftUI

struct gitBranchItem2: Identifiable {
    let id = UUID().uuidString
    let name: String
    let hash: String
    let authorname: String
    let authoremail: String
    let subject: String
    let type: String
}

struct git_branch_view: View {
    @EnvironmentObject var GitObservable: GitObservable
    
    @State private var LocalBranchList: [gitBranchItem2] = []
    @State private var remoteBranchList: [gitBranchItem2] = []
    
    @State private var searchText: String = ""
    
    @State private var selectedItemId: String = ""
    @State private var selectedItem: String = ""
    
    @State private var hoverItemId: String = ""
    
    @State var iconFoldLocal: Bool = false
    @State var iconFoldRemote: Bool = false
    
    var repoPath: String {
        GitObservable.GitProjectPathProperty
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
                getGitAllBranchList(repoPath: repoPath, local: $LocalBranchList, remote: $remoteBranchList)
            }
            
        }
        .onChange(of: repoPath) { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                getGitAllBranchList(repoPath: repoPath, local: $LocalBranchList, remote: $remoteBranchList)
            }
        }
        .onChange(of: GitObservable.GitBranchProperty) { value in
            getGitAllBranchList(repoPath: repoPath, local: $LocalBranchList, remote: $remoteBranchList)
        }
    }
    
    var view_filter: some View {
        SearchTextField(text: $searchText)
            .padding(.vertical, 15)
            .onSubmit {
                filterBranch()
            }
            .onChange(of: searchText) { value in
                filterBranch()
            }
    }
    
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
                    show_branch(item: item, selectedItemId: $selectedItemId, hoverItemId: $hoverItemId)
                }
            }
        }
        .padding(.trailing, 7)
    }
    
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
                    show_branch(item: item, selectedItemId: $selectedItemId, hoverItemId: $hoverItemId)
                }
            }
        }
        .padding(.trailing, 7)
    }
    
    // 过滤分支
    func filterBranch() {
        
    }
}

// 视图：分支
struct show_branch: View {
    var item: gitBranchItem2
    
    @Binding var selectedItemId: String
    @Binding var hoverItemId: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(item.name)
                    .foregroundColor(selectedItemId == item.id ? .white : .primary)
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
            Button("Checkout \(item.name)", action: {

            })
            Divider()
            Button("Merge \(item.name) into xxx", action: {
                
            })
            Divider()
            if item.type == "local" {
                Button("Rename...", action: {
                    
                })
            }
            Button("Delete \(item.name)", action: {
                
            })
            Divider()
            Button("Copy Branch Name to Clipboard", action: {
                
            })
        }
    }
}


// 视图：段落标题
struct GitBranchSectionTitleDisplayAndOperation: View {
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

// 分支列表：获取git 分支列表
fileprivate func getGitAllBranchList(repoPath: String, local: Binding<[gitBranchItem2]>, remote: Binding<[gitBranchItem2]>) {
    if repoPath.isEmpty {
        return
    }
    
    // 获取本地分支
    var localList: [gitBranchItem2] = []
    GitBranchHelper.getLocalBranchListAsync(at: repoPath) { output in
        if let bList = output as? [Dictionary<String, String>] {
            for i in bList {
                localList.append(gitBranchItem2(name: i["name"]!, hash: i["hash"]!, authorname: i["authorname"]!, authoremail: i["authoremail"]!, subject: i["subject"]!, type: i["type"]!))
            }
        }
        if !localList.isEmpty {
            DispatchQueue.main.async {
                local.wrappedValue = localList
            }
        }
    }
    
    // 获取远程分支
    var remoteList: [gitBranchItem2] = []
    GitBranchHelper.getRemoteBranchListAsync(at: repoPath) { output in
        if let bList = output as? [Dictionary<String, String>] {
            for i in bList {
                remoteList.append(gitBranchItem2(name: i["name"]!, hash: i["hash"]!, authorname: i["authorname"]!, authoremail: i["authoremail"]!, subject: i["subject"]!, type: i["type"]!))
            }
        }
        if !remoteList.isEmpty {
            DispatchQueue.main.async {
                remote.wrappedValue = remoteList
            }
        }
    }
}


struct git_branch_view_Previews: PreviewProvider {
    static var previews: some View {
        git_branch_view()
    }
}
