//
//  toolbar_branch.swift
//  easy-git
//
//  Created by 1 on 3/5/23.
//

import SwiftUI


struct toolbar_branch_view: View {
    @EnvironmentObject var GitObservable: GitObservable
    
    @Binding var projectName: String
    @Binding var projectPath: String
    @Binding var branchName: String
    
    @State private var searchText: String = ""
    
    @State private var BranchList: [GitBranchItem] = []
    @State private var rawBranchList: [GitBranchItem] = []
    
    @State private var isMenuVisible = false
    @State private var isContextMenuVisible = false
    @State private var hoverItem: String = ""
    @State private var hoverBranchRef: String = ""
    @State private var hoverArea: Bool = false
    
    @State private var showCreateBranchWindow: Bool = false
    @State private var userSelectedRef: String = ""
    
    var body: some View {
        HStack {
            Button(action: {
                self.isMenuVisible.toggle()
                getGitRefsList()
            }, label: {
                Image("git-branch")
                    .resizable()
                    .frame(width: 24, height: 24)
                VStack(alignment: .leading) {
                    Text(projectName)
                    HStack {
                        Text(branchName)
//                        Label("", systemImage: "chevron.down")
//                            .labelStyle(.iconOnly)
//                            .padding(.leading, -5)
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                    .help("Git Branch is: \(branchName)")
                }
            })
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $isMenuVisible, arrowEdge: .bottom) {
                view_popover
            }
            .onHover { isHovered in
                self.hoverArea = isHovered ? true : false
            }
        }
        .padding(.trailing, 20)
        .frame(width: 170, alignment: .trailing)
        .sheet(isPresented: $showCreateBranchWindow) {
            git_branch_create_view(projectPath: projectPath, userSelectedRef: userSelectedRef, isShowWindow: $showCreateBranchWindow)
        }
        .onAppear() {
            getCurrentBranchName()
        }
        .onChange(of: projectPath) { newValue in
            getCurrentBranchName()
        }
        .onChange(of: GitObservable.monitoring_git_HEAD) { value in
            getCurrentBranchName()
        }
    }
    
    var view_popover: some View {
        VStack(alignment: .leading) {
            SearchTextField(text: $searchText)
                .onSubmit {
                    gotoSearch()
                }
                .onChange(of: searchText) { value in
                    gotoSearch()
                }
            
            ScrollView {
                ForEach(BranchList) { item in
                    HStack {
                        Text(item.reftype).foregroundColor(item.reftype == "L" ? .blue.opacity(0.8) : .purple.opacity(0.8))
                        VStack(alignment: .leading) {
                            Text(item.name).lineLimit(1)
                            Text("\(item.authorname)  \(item.authordate)").lineLimit(1).font(.system(size: 10, weight: .light)).foregroundColor(.gray)
                        }
                        Spacer()
                        if hoverItem == item.id {
                            view_ref_contextMenu
                        }
                    }
                    .padding(.leading, 12)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(hoverItem.contains(item.id) ? Color.gray.opacity(0.2) : Color.clear)
                    .cornerRadius(3)
                    .onHover { isHovered in
                        hoverItem = isHovered ? item.id : ""
                        hoverBranchRef = isHovered ? item.name : ""
                    }
                    .onTapGesture {
                        gitSwitchBranch(reftype: item.reftype, name: item.name)
                    }
                }
            }
        }
        .padding(.bottom, 10)
        .cornerRadius(8)
        .background(.gray.opacity(0.01))
        .frame(width: 280)
        .frame(minHeight: 190, maxHeight: 210)
    }
    
    var view_ref_contextMenu: some View {
        Label("", systemImage: "ellipsis.circle")
            .contextMenu {
                Button("Create Branch...", action: {
                    if hoverBranchRef != "" {
                        self.userSelectedRef = hoverBranchRef
                    }
                    self.showCreateBranchWindow = true
                })
            }
    }
    
    func open_ref_contextMenu() {
        
    }
    
    // 打开下拉列表
    private func open(refname: String) {
        DispatchQueue.main.async {
            isMenuVisible = false
        }
    }
    
    // 分支：搜索过滤
    private func gotoSearch() {
        if self.searchText.isEmpty {
            DispatchQueue.main.async {
                self.BranchList = rawBranchList
            }
            return
        }
        
        let word = searchText.lowercased()
        var result: [GitBranchItem] = []
        
        for i1 in rawBranchList {
            let name: String = i1.name.lowercased()
            if name.contains(word){
                result.append(i1)
            }
        }
        DispatchQueue.main.async {
            self.BranchList = result
        }
    }
    
    // 分支：获取所有的分支、tags
    private func getGitRefsList() {
        DispatchQueue.global(qos: .background).async {
            var tmpBranchList: [GitBranchItem] = []
            GitBranchHelper.getAllRefs(at: projectPath) { output in
                if !output.isEmpty {
                    if let bList = output as? [Dictionary<String, String>] {
                        for i in bList {
                            tmpBranchList.append(GitBranchItem(name: i["name"]!, reftype: i["reftype"]!, refname: i["refname"]!, authordate: i["authordate"]!, authorname: i["authorname"]!))
                        }
                    }
                }
                if !tmpBranchList.isEmpty {
                    DispatchQueue.main.async {
                        self.BranchList = tmpBranchList
                        self.rawBranchList = tmpBranchList
                    }
                }
            }
        }
    }
    
    // 分支：获取当前分支名称
    private func getCurrentBranchName() {
        GitBranchHelper.getCurrentBranchNameAsync(at: projectPath) { output in
            DispatchQueue.main.async {
                branchName = output
            }
        }
    }
    
    // 分支：切换
    private func gitSwitchBranch(reftype: String, name: String) {
        if reftype == "L" && name == projectName {
            return
        }
        if reftype == "L" {
            // 切换分支前，弹窗确认
            let msg = "Do you want to switch to \"\(name)\" ?"
            let isAllow = showAlert(title: msg, msg: "", ConfirmBtnText: "Switch")
            if !isAllow {
                return
            }
            
            let result = GitBranchHelper.BranchSwitch(LocalRepoDir: projectPath, name: name)
            if result {
                DispatchQueue.main.async {
                    self.branchName = name
                    self.isMenuVisible = false
                }
            }
        } else {
            self.userSelectedRef = name
            self.showCreateBranchWindow = true
        }
    }
}

