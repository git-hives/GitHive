//
//  git_tag_view.swift
//  easy-git
//
//  Created by 1 on 2/23/23.
//

import SwiftUI

struct git_tags_view: View {
    @EnvironmentObject var GitObservable: GitObservable
    
    @State private var tagsList: [gitTagItem] = []
    @State private var rawTagsList: [gitTagItem] = []
    
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
                view_tag
            }
        }
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                getGitAllTagsList(repoPath: repoPath)
            }
            
        }
        .onChange(of: repoPath) { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                getGitAllTagsList(repoPath: repoPath)
            }
        }
    }
    
    // 视图：过滤
    var view_filter: some View {
        SearchTextField(text: $searchText, placeholder: "Filter Tag Name")
            .padding(.vertical, 15)
            .onSubmit {
                filterTag()
            }
            .onChange(of: searchText) { value in
                filterTag()
            }
    }
    
    // 视图：显示tag
    var view_tag: some View {
        Section {
            if !iconFoldLocal {
                ForEach(tagsList, id:\.id) { item in
                    show_tag(repoPath: repoPath, item: item, selectedItemId: $selectedItemId, hoverItemId: $hoverItemId)
                }
            }
        }
        .padding(.trailing, 7)
    }
    
    
    // tag列表：获取git tag列表
    func getGitAllTagsList(repoPath: String) {
        if repoPath.isEmpty {
            return
        }
        
        // 获取tag
        var tList: [gitTagItem] = []
        GitTagHelper.getTagListAsync(at: repoPath) { output in
            if !output.isEmpty {
                for i in output {
                    tList.append(gitTagItem(name: i))
                }
            }
            if !tList.isEmpty {
                DispatchQueue.main.async {
                    self.tagsList = tList
                    self.rawTagsList = tList
                }
            }
        }
    }
    
    // 过滤tag
    func filterTag() {
        let fileterText = self.searchText.trimming()
        
        self.tagsList = self.rawTagsList
        
        if fileterText.isEmpty {
            return
        }
        self.tagsList = self.rawTagsList.filter {
            $0.name.contains(fileterText)
        }
    }
}

// 视图：tag
private struct show_tag: View {
    var repoPath: String
    var item: gitTagItem
    
    @Binding var selectedItemId: String
    @Binding var hoverItemId: String
    
    @State private var showCreateBranchWindow: Bool = false
    @State private var selectedBranchName: String = ""
    
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
            Button("Details...", action: {
                
            })
            Divider()
            Button("Create Branch", action: {
                self.showCreateBranchWindow = true
                self.selectedBranchName = "tags/\(item.name)"
            })
            Divider()
            Button("Checkout \(item.name)", action: {

            })
            Divider()
            Button("Push \(item.name)", action: {

            })
            Group {
                Divider()
                Button("Delete \(item.name)", action: {

                })
                Button("Delete \(item.name) from origin", action: {

                })
                Divider()
            }
            Button("Copy Tag Name to Clipboard", action: {

            })
        }
        .sheet(isPresented: $showCreateBranchWindow) {
            git_branch_create_view(projectPath: repoPath, userSelectedRef: selectedBranchName, isShowWindow: $showCreateBranchWindow)
        }
    }
}


struct git_tags_view_Previews: PreviewProvider {
    static var previews: some View {
        git_tags_view()
    }
}
