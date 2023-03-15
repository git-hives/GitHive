//
//  git_stash_view.swift
//  easy-git
//
//  Created by 1 on 2/23/23.
//

import SwiftUI

fileprivate var isRefreshStashList: Int = 0

struct git_stash_view: View {
    @EnvironmentObject var GitObservable: GitObservable
    
    @State private var stashList: [gitStashItem] = []
    @State private var rawStashList: [gitStashItem] = []
    
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
                view_stash
            }
        }
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                getGitAllStashList()
            }
            
        }
        .onChange(of: repoPath) { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                getGitAllStashList()
            }
        }
        .onChange(of: GitObservable.monitoring_git_index) { value in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                getGitAllStashList()
            }
        }
        .onChange(of: isRefreshStashList) { value in
            getGitAllStashList()
        }
    }
    
    // 视图：过滤
    var view_filter: some View {
        SearchTextField(text: $searchText, placeholder: "Filter Stash")
            .padding(.vertical, 15)
            .onSubmit {
                filterStash()
            }
            .onChange(of: searchText) { value in
                filterStash()
            }
    }
    
    // 视图：显示stash
    var view_stash: some View {
        Section {
            if !iconFoldLocal {
                ForEach(stashList, id:\.id) { item in
                    show_stash(repoPath: repoPath, item: item, selectedItemId: $selectedItemId, hoverItemId: $hoverItemId)
                }
            }
        }
        .padding(.trailing, 7)
    }
    
    
    // stash列表：获取git stash列表
    func getGitAllStashList() {
        if repoPath.isEmpty {
            return
        }
        Task {
            do {
                var tList: [gitStashItem] = []
                let output = try await GitStashHelper.get(at: repoPath)
                if !output.isEmpty {
                    for i in output {
                        tList.append(gitStashItem(name: i))
                    }
                }
                DispatchQueue.main.async {
                    self.stashList = tList
                    self.rawStashList = tList
                }
            } catch let error {
                let msg = getErrorMessage(etype: error as! GitError)
                _ = showAlert(title: "Error", msg: msg, ConfirmBtnText: "Ok")
            }
        }
    }
    
    // 过滤stash
    func filterStash() {
        let fileterText = self.searchText.trimming()
        
        self.stashList = self.rawStashList
        
        if fileterText.isEmpty {
            return
        }
        self.stashList = self.rawStashList.filter {
            $0.name.contains(fileterText)
        }
    }
}

// 视图：stash
private struct show_stash: View {
    var repoPath: String
    var item: gitStashItem
    
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
            Button("Pop Stash", action: {
                gitStashPop(repoPath: repoPath)
            })
            Divider()
            Button("Apply Stash", action: {
                gitStashApply(repoPath: repoPath, name: item.name)
            })
            Divider()
            Button("Drop Stash", action: {
                gitStashDrop(repoPath: repoPath, name: item.name)
            })
        }
    }
}


func gitStashPop(repoPath: String) {
    Task {
        do {
            let result = try await GitStashHelper.pop(LocalRepoDir: repoPath)
            if !result.isEmpty {
                isRefreshStashList += 1
            }
        } catch let error {
            let msg = getErrorMessage(etype: error as! GitError)
            _ = showAlert(title: "Error", msg: msg, ConfirmBtnText: "Ok")
        }
    }
}

func gitStashApply(repoPath: String, name: String) {
    Task {
        do {
            let result = try await GitStashHelper.apply(LocalRepoDir: repoPath, name: name)
            if !result.isEmpty {
                isRefreshStashList += 1
                if result != "success" {
                    _ = showAlert(title: "", msg: result, ConfirmBtnText: "OK")
                }
            }
        } catch let error {
            let msg = getErrorMessage(etype: error as! GitError)
            _ = showAlert(title: "Error", msg: msg, ConfirmBtnText: "Ok")
        }
    }
}

func gitStashDrop(repoPath: String, name: String) {
    Task {
        do {
            let result = try await GitStashHelper.drop(LocalRepoDir: repoPath, name: name)
            if !result.isEmpty {
                isRefreshStashList += 1
                if result != "success" {
                    _ = showAlert(title: "", msg: result, ConfirmBtnText: "OK")
                }
            }
        } catch let error {
            let msg = getErrorMessage(etype: error as! GitError)
            _ = showAlert(title: "Error", msg: msg, ConfirmBtnText: "Ok")
        }
    }
}

struct git_stash_view_Previews: PreviewProvider {
    static var previews: some View {
        git_stash_view()
    }
}
