//
//  toolbar_projectinfo.swift
//  easy-git
//
//  Created by 1 on 3/5/23.
//

import SwiftUI


struct GitProjectItem: Identifiable {
    let id = UUID().uuidString
    let name: String
    let path: String
}

struct toolbar_projectinfo: View {
    @Binding var projectName: String
    @Binding var projectPath: String
    
    @State private var localGitRepoList: [GitProjectItem] = []
    @State private var rawLocalGitRepoList: [GitProjectItem] = []
    
    @State private var searchText: String = ""
    
    @State private var hoverItem: String = ""
    @State private var isMenuVisible = false
    @State private var menuPosition: CGPoint = .zero
    
    var body: some View {
        HStack {
            Button(action: {
                self.isMenuVisible.toggle()
                self.getHistoryGitList()
            }, label: {
                Label("", systemImage: "list.bullet")
                    .font(.title2)
            })
            .help("Switch Repository")
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $isMenuVisible, arrowEdge: .bottom) {
                view_popover
            }
            .contextMenu() {
                view_contextMenu
            }
        }
    }
    
    var view_popover: some View {
        VStack(alignment: .leading, spacing: 10) {
            SearchTextField(text: $searchText)
                .onSubmit {
                    gotoSearch()
                }
                .onChange(of: searchText) { value in
                    gotoSearch()
                }
            
            ScrollView {
                ForEach(localGitRepoList, id: \.id) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .lineLimit(1)
                            Text(item.path)
                                .lineLimit(1)
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .help(item.path)
                        }
                    }
                    .padding(.leading, 12)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(hoverItem.contains(item.id) ? Color.gray.opacity(0.2) : Color.clear)
                    .cornerRadius(3)
                    .onHover { isHovered in
                        hoverItem = isHovered ? item.id : ""
                    }
                    .onTapGesture {
                        openProject(name: item.name, path: item.path)
                    }
                }
            }
        }
        .cornerRadius(8)
        .background(.gray.opacity(0.01))
        .padding(.bottom, 10)
        .frame(width: 280)
        .frame(minHeight: 190, maxHeight: 210)
    }
    
    // 右键菜单
    var view_contextMenu: some View {
        Section {
            Button("Reveal in Finder") {
                RevealInFinder(at: projectPath)
            }
            Divider()
            Button("Copy Project Path") {
                copyToPasteboard(at: projectPath)
            }
        }
    }
    
    func openProject(name: String, path: String) {
        let checkResult = runGit.PreCheck(at: path)
        if checkResult["type"] == "success" {
            DispatchQueue.main.async {
                projectName = name
                projectPath = path
                isMenuVisible = false
            }
            appSettingHelper.writeSessionJsonFile(key: "lastGitProjectDir", value: path)
            print("[切换项目] --> 切换后的项目是", path)
        } else {
            let errorMsg = checkResult["errMsg"]
            _ = showAlertOnlyPrompt(msgType: "warning", title: "", msg: errorMsg ?? "Failed to open Git Repo.", ConfirmBtnText: "Ok")
        }
    }
    
    // 搜索过滤
    func gotoSearch() {
        if self.searchText.isEmpty {
            DispatchQueue.main.async {
                self.localGitRepoList = rawLocalGitRepoList
            }
            return
        }
        let word = searchText.lowercased()
        
        var result: [GitProjectItem] = []
        for i1 in rawLocalGitRepoList {
            let name: String = i1.name.lowercased()
            let path: String = i1.path.lowercased()
            if name.contains(word) || path.contains(word) {
                result.append(i1)
            }
        }
        DispatchQueue.main.async {
            self.localGitRepoList = result
        }
    }
    
    func getHistoryGitList() {
        var projectList: [GitProjectItem] = []
        let info = appSettingHelper.readSessionJsonFile(key: "gitRepoList", defaultValue: [])
        if let gList = info as? [String] {
            for item in gList {
                let basename = FileHelper.getPathBasename(asPath: item)
                let tmp = GitProjectItem(name: basename, path: item )
                projectList.append(tmp)
            }
        }
        if !projectList.isEmpty {
            DispatchQueue.main.async {
                self.localGitRepoList = projectList
                self.rawLocalGitRepoList = projectList
            }
        }
    }
}
