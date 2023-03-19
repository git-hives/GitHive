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
    
    @State private var selectedStashName: String = ""
    @State private var selectedItemId: String = ""
    @State private var selectedItem: String = ""
    
    @State private var hoverItemId: String = ""
    
    @State var iconFoldLocal: Bool = false
    @State var iconFoldRemote: Bool = false
    
    @State var isPresentedForStashSave: Bool = false
    
    var repoPath: String {
        GitObservable.GitProjectPathProperty
    }
    
    var body: some View {
        VStack() {
            view_filter
            
            if stashList.isEmpty {
                view_empty(text: "No Stash")
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    view_stash
                }
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
        .onChange(of: selectedStashName) { value in
            GitObservable.stash_view_active_stash = value
        }
        .contextMenu {
            Button("Refresh", action: {
                getGitAllStashList()
            })
            Divider()
            Button("Create Stash", action: {
                self.isPresentedForStashSave.toggle()
            })
            Button("Clear Stash", action: {
                gitStashClear(repoPath: repoPath, selectedStashName: $selectedStashName)
            })
            .disabled(rawStashList.count == 0)
        }
        .sheet(isPresented: $isPresentedForStashSave) {
            git_stash_save_view(isPresented: $isPresentedForStashSave, title: "Create stash", placeholder: "stash message", onConfirm: { value in
                if !value.isEmpty {
                    gitStashSave(LocalRepoDir: repoPath, cmd: value)
                }
            })
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
            ForEach(stashList, id:\.id) { item in
                show_stash(repoPath: repoPath, item: item,  selectedStashName: $selectedStashName, selectedItemId: $selectedItemId, hoverItemId: $hoverItemId)
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
    
    @Binding var selectedStashName: String
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
            self.selectedStashName = item.name
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
                gitStashDrop(repoPath: repoPath, name: item.name, selectedStashName: $selectedStashName)
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
            _ = await showAlertAsync(title: "Error", msg: msg, ConfirmBtnText: "Ok")
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
                    _ = await showAlertAsync(title: "", msg: result, ConfirmBtnText: "OK")
                }
            }
        } catch let error {
            let msg = getErrorMessage(etype: error as! GitError)
            _ = await showAlertAsync(title: "Error", msg: msg, ConfirmBtnText: "Ok")
        }
    }
}

func gitStashDrop(repoPath: String, name: String, selectedStashName: Binding<String>) {
    Task {
        do {
            let msg_for_drop = "Are you sure you want to delete the '\(name)'?"
            let isDelete: Bool = await showAlertAsync(title: "Confirm Drop", msg: msg_for_drop, ConfirmBtnText: "Ok")
            if !isDelete {
                return
            }
            
            let result = try await GitStashHelper.drop(LocalRepoDir: repoPath, name: name)
            if !result.isEmpty {
                isRefreshStashList += 1
                if result != "success" {
                    _ = await showAlertAsync(title: "", msg: result, ConfirmBtnText: "OK")
                } else {
                    selectedStashName.wrappedValue = ""
                }
            }
        } catch let error {
            let msg = getErrorMessage(etype: error as! GitError)
            _ = await showAlertAsync(title: "Error", msg: msg, ConfirmBtnText: "Ok")
        }
    }
}


func gitStashClear(repoPath: String, selectedStashName: Binding<String>) {
    Task {
        do {
            let msg_for_drop = "Are you sure you want to remove all the stash entries?"
            let isDelete: Bool = await showAlertAsync(title: "Confirm Remove", msg: msg_for_drop, ConfirmBtnText: "Ok")
            if !isDelete {
                return
            }
            
            let result = try await GitStashHelper.clear(LocalRepoDir: repoPath)
            if result.isEmpty {
                isRefreshStashList += 1
                selectedStashName.wrappedValue = " "
            } else {
                _ = await showAlertAsync(title: "", msg: result, ConfirmBtnText: "OK")
            }
        } catch let error {
            let msg = getErrorMessage(etype: error as! GitError)
            _ = await showAlertAsync(title: "Error", msg: msg, ConfirmBtnText: "Ok")
        }
    }
}


func gitStashSave(LocalRepoDir: String, cmd: String) {
    Task {
        do {
            let result = try await GitStashHelper.save(LocalRepoDir: LocalRepoDir, cmd: cmd)
            if result == "success" {
                isRefreshStashList += 1
            } else {
                _ = await showAlertAsync(title: "", msg: result, ConfirmBtnText: "OK")
            }
        } catch let error {
            let msg = getErrorMessage(etype: error as! GitError)
            _ = await showAlertAsync(title: "Error", msg: msg, ConfirmBtnText: "Ok")
        }
    }
}
