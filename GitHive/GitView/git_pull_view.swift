//
//  git_pull.swift
//  easy-git
//
//  Created by 1 on 3/4/23.
//

import SwiftUI

struct git_pull: View {
    
    @EnvironmentObject var GitObservable: GitObservable
    
    var repoDir: String
    var repoName: String
    
    @State var isButtonDisabled = false
    @State var Behind: String = ""
    
    @State private var isManuallyTriggerTheExecutionOfGit: Bool = false
    
    @State private var isRotatingForFetch = false

    var body: some View {
        HStack(alignment: .center) {
            fetchButton
            
            HStack {
                pullButton
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 20)
                
                pullButtonMore
            }
            .foregroundColor(.black.opacity(0.75))
            .background(.gray.opacity(0.1))
            .cornerRadius(3)
        }
        .onAppear() {
            g_fetch()
        }
        .onChange(of: GitObservable.GitBranchProperty) { value in
            if !value.isEmpty {
                get_pull_behind()
            }
        }
        .onChange(of: GitObservable.monitoring_git_pull) { value in
            if !self.isManuallyTriggerTheExecutionOfGit {
                get_pull_behind()
            }
        }
    }
    
    // 应用启动后立即fetch
    var fetchButton: some View {
        HStack {
            Button(action: {
                g_fetch()
            }, label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .rotationEffect(.degrees(isRotatingForFetch ? 360 : 0))
                    .animation(Animation.linear(duration: 2), value: isRotatingForFetch)
                    .help("Fetch")
            })
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: 30, height: 30)
    }
    
    // 按钮：git pull
    var pullButton: some View {
        Button(action: {
            g_pull_action(param: .pull)
        }, label: {
            HStack() {
                Label("", systemImage: "arrow.down")
                    .labelStyle(.iconOnly)
                Text(Behind.isEmpty ? "Pull" : Behind)
                    .padding(.trailing, -6)
            }
            .frame(width:60, height: 30, alignment: .center)
            .background(Color.clear)
            .contentShape(Rectangle())
        })
        .disabled(isButtonDisabled)
        .buttonStyle(PlainButtonStyle())
        .frame(width:60, height: 30, alignment: .center)
        .help("git pull")
    }
    
    // 按钮：更多git pull操作
    var pullButtonMore: some View {
        HStack(alignment: .center) {
            Menu {
                Button("pull", action: {
                    g_pull_action(param: .pull)
                })
                Button("pull --rebase", action: {
                    g_pull_action(param: .rebase)
                })
                Button("pull --rebase --autostash", action: {
                    g_pull_action(param: .rebaseAutoStash)
                })
                Button("pull --ff-only", action: {
                    g_pull_action(param: .ffOnly)
                })
            } label: {
                
            }
            .buttonStyle(.plain)
        }
        .frame(width: 30, alignment: .center)
        .padding(.leading, -8)
    }
    
    // git fetch操作
    func g_fetch() {
        self.isManuallyTriggerTheExecutionOfGit = true
        self.isRotatingForFetch = true
        GitAction.fetchAsync(LocalRepoDir: repoDir, param: .fetch) { output in
            if let output = output, !output.contains("error") {
                get_pull_behind()
            }
            DispatchQueue.main.async {
                self.isRotatingForFetch = false
                self.isManuallyTriggerTheExecutionOfGit = false
            }
        }
    }
    
    // 获取pull behind数量
    func get_pull_behind() {
        print("[Git-behind]获取pull behind数量.....")
        let gitBehind = GitAction.get_behind_num(LocalRepoDir: repoDir)
        let behindNum = gitBehind["behind"]!
        if  behindNum == "" || behindNum.isAllDigits(){
            DispatchQueue.main.async {
                Behind = behindNum
                GitObservable.GitBehind = behindNum
            }
        }
    }
    
    // git pull操作，支持传入git pull 参数
    func g_pull_action(param: gitPullParam = .ffOnly) {
        if !isButtonDisabled {
            isButtonDisabled = true
        }

        GitAction.pullAsync(LocalRepoDir: repoDir, param: param) { output in
            if let output = output {
                print(output)
            }
            get_pull_behind()
            DispatchQueue.main.async {
                isButtonDisabled = false
                if output == "pull_success" {
                    Behind = ""
                }
            }
        }
    }
}
