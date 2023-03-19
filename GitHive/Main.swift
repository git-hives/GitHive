//
//  ContentView.swift
//  easy-git
//
//  Created by 1 on 2/21/23.
//

import SwiftUI
import Combine

// 左侧应用程序导航入口
enum AppNavName {
    case Welcome
    case Files
    case Logs
    case Branch
    case Tags
    case Stash
}

// 应用程序界面绘制入口
struct Main: View {
    
    @EnvironmentObject var GitObservable: GitObservable
    
    @State var activeNavName: AppNavName = .Logs
    
    @State var showAlertForOpenLocalProject: Bool = false
    
    @State var showCloneWindow: Bool = false
    
    @State var isShowSilder: Bool = true
    
    // 本地Git项目仓库路径
    var projectPath: String {
        GitObservable.GitProjectPathProperty
    }
    
    // 本地Git项目名称
    var projectName: String {
        GitObservable.GitProjectNameProperty
    }
    
    // git push待push的数量
    var Behind: String {
        GitObservable.GitBehind
    }
    
    // git pull待拉取的数量
    var Ahead: String {
        GitObservable.GitAhead
    }
        
        
    var body: some View {
        HSplitView {
            if isShowSilder {
                HStack(alignment: .center) {
                    nav_view
                        .frame(width: 50)
                        .frame(minWidth: 50, maxWidth: 50, minHeight: 700, maxHeight: .infinity, alignment: .topTrailing)
                        .background(.gray.opacity(0.1))
                    
                    middle_view
                        .frame(width: 280)
                        .frame(minWidth: 280, maxWidth: 280, minHeight: 700, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            main_view
                .padding()
                .frame(minWidth: 700, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(.white)
        }
        .navigationTitle("")
        .onAppear() {
            DispatchQueue.main.async {
                initToolbarInfo()
            }
        }
        .sheet(isPresented: $showCloneWindow) {
            git_clone_view(isPresented: $showCloneWindow)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                HStack {
                    // 工具栏：折叠图标
                    showSilder
                    
                    // 工具栏：项目按钮
                    toolbar_projectinfo(projectName: $GitObservable.GitProjectNameProperty, projectPath: $GitObservable.GitProjectPathProperty)
                    
                    toolbar_button_for_other
                }
                .frame(width: 220, alignment: .leading)
                
                // 工具栏：分支按钮
                toolbar_branch_view(projectName: $GitObservable.GitProjectNameProperty, projectPath: $GitObservable.GitProjectPathProperty, branchName: $GitObservable.GitBranchProperty)
            }
            
            ToolbarItemGroup(placement: .automatic) {
                HStack {
                    git_pull(repoDir: projectPath, repoName: projectName)
                    git_push(repoDir: projectPath, repoName: projectName)
                }
            }
        }
    }
    
    // 工具栏：折叠图标
    var showSilder: some View {
        Button {
            //NSApp.keyWindow?.firstResponder?.tryToPerform(
            //        #selector(NSSplitViewController.toggleSidebar(_:)), with: nil
            //)
            self.isShowSilder.toggle()
        } label: {
            Label("", systemImage: "sidebar.left")
        }
    }
    
    
    // App左侧导航
    var nav_view: some View {
        VStack {
            ActionButtonForSilderNav(title: "", systemImage: "doc.plaintext", help: "Files", isActive: activeNavName == .Files, action: { self.activeNavName = .Files })
            ActionButtonForSilderNav(title: "", systemImage: "clock", help: "Logs", isActive: activeNavName == .Logs, action: { self.activeNavName = .Logs })
            ActionButtonForSilderNav(title: "", systemImage: "arrow.triangle.branch", help: "Branch", isActive: activeNavName == .Branch, action: { self.activeNavName = .Branch })
            ActionButtonForSilderNav(title: "", systemImage: "tag", help: "Tags", isActive: activeNavName == .Tags, action: { self.activeNavName = .Tags })
            ActionButtonForSilderNav(title: "", systemImage: "s.circle", help: "Stash", isActive: activeNavName == .Stash, action: { self.activeNavName = .Stash })
        }
    }
    
    var middle_view: some View {
        VStack {
            switch(self.activeNavName) {
            case .Welcome:
                welcome_view()
            case .Files:
                git_files_view()
            case .Logs:
                git_logs_view()
            case .Branch:
                git_branch_view()
            case .Tags:
                git_tags_view()
            case .Stash:
                git_stash_view()
            default:
                welcome_view()
            }
        }
    }
    
    var main_view: some View {
        VStack {
            switch(self.activeNavName) {
            case .Files:
                git_files_details_view()
            case .Logs:
                git_log_details_view()
            case .Tags:
                git_tag_details_view()
            case .Stash:
                git_stash_details_view()
            default:
                git_default_view()
            }
        }
    }
    
    // Git other
    var toolbar_button_for_other: some View {
        HStack {
            Button(action: {
                openLocalGitProject()
            }, label: {
                Label("Open Local Git Project", systemImage: "plus.rectangle.on.folder")
            })
            .help("Open Local Git Project")
            .keyboardShortcut("O", modifiers: .command)
            
            Button(action: {
                self.showCloneWindow.toggle()
            }, label: {
                Label("Git Clone", systemImage: "square.and.arrow.down")
            })
            .help("Git Clone")
        }
    }
    
    // 操作：导入本地Git项目
    func openLocalGitProject() {
        guard let selected = OpenFinderSelectDirectory() else {
            return
        }
        let selectedDir: String = selected.path
        print("[Finder]选择的路径是:", selectedDir)
        initToolbarInfo(atPath: selectedDir)
    }
    
    // 工具栏数据显示，如分支信息、项目信息、pull和push数字
    func initToolbarInfo(atPath selectedDir: String = "") {
        // 如果本地没有上次历史记录，则无需进行下一步
        if !GitObservable.isExistHistoryProject {
            return
        }
        
        var gitRepoDir: String = GitObservable.GitProjectPathProperty
        if selectedDir != "" {
            gitRepoDir = selectedDir
        }
        let checkResult = runGit.PreCheck(at: gitRepoDir)
        print("[initToolbarInfo] gitRepoDir = ", gitRepoDir)
        
        if checkResult["type"] == "error" {
            GitObservable.GitProjectPathProperty = ""
            let msg = checkResult["errMsg"]!
            _ = showAlertOnlyPrompt(msgType: "warning", title: "", msg: msg, ConfirmBtnText: "Ok")
            return
        } else {
            GitObservable.GitProjectPathProperty = gitRepoDir
            if selectedDir != "" {
                // 如果选择的信息是有效的，则写入配置文件
                appSettingHelper.writeSessionJsonFile(key: "lastGitProjectDir", value: gitRepoDir)
            }
        }
        
        // 从路径解析项目名称
        let basename: String = FileHelper.getPathBasename(asPath: gitRepoDir)
        DispatchQueue.main.async {
            if !basename.isEmpty {
                GitObservable.GitProjectNameProperty = basename
            }
        }
    }
}

// 左侧导航视图：按钮样式
struct LeftNavButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title)
            .padding(.vertical, 10)
            .padding(.leading, 10)
            .cornerRadius(5)
            .background(.clear)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
    }
}
