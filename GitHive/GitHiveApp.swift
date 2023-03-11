//
//  easy_gitApp.swift
//  easy-git
//
//  Created by 1 on 2/21/23.
//

import SwiftUI


class GitObservable: ObservableObject {
    
    @Published var isExistHistoryProject: Bool = false
    
    @Published var GitProjectPathProperty = ""
    @Published var GitProjectNameProperty = ""
    @Published var GitBranchProperty = ""
    @Published var GitAhead = ""
    @Published var GitBehind = ""
    
    @Published var monitoring_project_file: String = ""
    @Published var monitoring_git_index: Int = 0
    @Published var monitoring_git_pull: Int = 0
    @Published var monitoring_git_push: Int = 0
    @Published var monitoring_git_HEAD: Int = 0
    @Published var monitoring_git_ci: Int = 0
}



class AppDelegate: NSObject, NSApplicationDelegate {
    var gitObservable = GitObservable()
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        print("[AppDelegate] --> applicationWillFinishLaunching")
        
        // 从本地配置文件读取上次打开的Git项目
        let lastGitProjectDir = appSettingHelper.readSessionJsonFile(key: "lastGitProjectDir", defaultValue: "")
        if !lastGitProjectDir.isEmpty {
            let isCheck = FileHelper.checkPathExists(atPath: lastGitProjectDir, checkType: "dir")
            if isCheck {
                gitObservable.GitProjectPathProperty = lastGitProjectDir
                gitObservable.isExistHistoryProject = true
            }
            gitObservable.objectWillChange.send()
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[AppDelegate] --> applicationDidFinishLaunching")
    }
}


@main
struct GitHiveApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
//    @StateObject var git_Observable = GitObservable()
    @StateObject var gitMoitor = GitObserverMonitoring()
    
    var body: some Scene {
        WindowGroup {
            Main()
                .environmentObject(appDelegate.gitObservable)
                .onAppear() {
                    startMonitoringGit()
                }
                .onDisappear() {
                   gitMoitor.stopObserving()
                }
                .onChange(of: appDelegate.gitObservable.GitProjectPathProperty) { value in
                    if !value.isEmpty {
                        startMonitoringGit()
                    }
                }
                .onChange(of: gitMoitor) { gitMoitor in
                    updateGitObservable(gitMoitor: gitMoitor)
                }
        }
        .commands {
            menu_File()
            menu_Help()
            menu_Repository()
        }
        
        #if os(macOS)
        Settings {
            app_settings_view()
        }
        #endif
    }
    
    // 启动监听
    func startMonitoringGit() {
        gitMoitor.stopObserving()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            let projectPath = appDelegate.gitObservable.GitProjectPathProperty
            if !projectPath.isEmpty {
                print("[启动.git监听]", projectPath)
                let gitURL = URL(fileURLWithPath: projectPath)
                gitMoitor.startObserving(url: gitURL)
            }
        }
    }
    
    func updateGitObservable(gitMoitor: GitObserverMonitoring) {
        DispatchQueue.main.async {
            appDelegate.gitObservable.monitoring_git_HEAD = gitMoitor.monitoring_git_HEAD
            appDelegate.gitObservable.monitoring_git_index = gitMoitor.monitoring_git_index
            appDelegate.gitObservable.monitoring_git_push = gitMoitor.monitoring_git_push
            appDelegate.gitObservable.monitoring_git_pull = gitMoitor.monitoring_git_pull
            appDelegate.gitObservable.monitoring_git_ci = gitMoitor.monitoring_git_ci
            appDelegate.gitObservable.monitoring_project_file = gitMoitor.monitoring_project_file
        }
    }

}
