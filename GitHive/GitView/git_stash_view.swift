//
//  git_stash_view.swift
//  easy-git
//
//  Created by 1 on 2/23/23.
//

import SwiftUI

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
                getGitAllStashList(repoPath: repoPath)
            }
            
        }
        .onChange(of: repoPath) { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                getGitAllStashList(repoPath: repoPath)
            }
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
    
    // 视图：显示tag
    var view_stash: some View {
        Section {
            if !iconFoldLocal {
                ForEach(stashList, id:\.id) { item in
                    show_stash(item: item, selectedItemId: $selectedItemId, hoverItemId: $hoverItemId)
                }
            }
        }
        .padding(.trailing, 7)
    }
    
    
    // tag列表：获取git tag列表
    func getGitAllStashList(repoPath: String) {
        if repoPath.isEmpty {
            return
        }
        
        // 获取tag
        var tList: [gitStashItem] = []
        GitStashHelper.getStashListAsync(at: repoPath) { output in
            if !output.isEmpty {
                for i in output {
                    tList.append(gitStashItem(name: i))
                }
            }
            if !tList.isEmpty {
                DispatchQueue.main.async {
                    self.stashList = tList
                    self.rawStashList = tList
                }
            }
        }
    }
    
    // 过滤tag
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
struct show_stash: View {
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
                
            })
            Divider()
            Button("Apply Stash", action: {

            })
            Divider()
            Button("Drop Stash", action: {

            })
        }
    }
}


struct git_stash_view_Previews: PreviewProvider {
    static var previews: some View {
        git_stash_view()
    }
}
