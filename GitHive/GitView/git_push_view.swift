//
//  git_push.swift
//  easy-git
//
//  Created by 1 on 3/4/23.
//

import SwiftUI

struct git_push: View {
    
    @EnvironmentObject var GitObservable: GitObservable
    
    var repoDir: String
    var repoName: String
    
    @State var Ahead: String = ""
    @State var isButtonDisabled = false
    
    // Git push按钮
    var body: some View {
        HStack {
            pushButton
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1, height: 20)
            
            pushButtonMore  
        }
        .foregroundColor(.black.opacity(0.75))
        .background(.gray.opacity(0.1))
        .cornerRadius(3)
        .onAppear() {
            get_push_Ahead()
        }
        .onChange(of: GitObservable.GitBranchProperty) { value in
            if !value.isEmpty {
                get_push_Ahead()
            }
        }
        .onChange(of: GitObservable.monitoring_git_push) { value in
            get_push_Ahead()
        }
        .onChange(of: GitObservable.monitoring_git_ci) { value in
            get_push_Ahead()
        }
    }
    
    var pushButton: some View {
        Button(action: {
            g_push_action(param: .push)
        }, label: {
            HStack() {
                Label("", systemImage: "arrow.up")
                    .labelStyle(.iconOnly)
                Text(Ahead.isEmpty ? "Push" : Ahead)
                    .padding(.trailing, -6)
            }
            .frame(width:60, height: 30, alignment: .center)
            .background(Color.clear)
            .contentShape(Rectangle())
        })
        .disabled(isButtonDisabled)
        .buttonStyle(PlainButtonStyle())
        .frame(width:60, height: 30, alignment: .center)
        
    }
    
    var pushButtonMore: some View {
        HStack(alignment: .center) {
            Menu {
                Button("push", action: {
                    g_push_action(param: .push)
                })
                Button("push --force", action: {
                    g_push_action(param: .force)
                })
                Button("push --no-verify", action: {
                    g_push_action(param: .noVerify)
                })
                Button("push --tags", action: {
                    g_push_action(param: .tags)
                })
            } label: {
                
            }
            .buttonStyle(.plain)
        }
        .frame(width: 30, alignment: .center)
        .padding(.leading, -8)
    }
    
    func get_push_Ahead() {
        print("[Git-ahead]获取push ahead数量.....")
        let gitAhead = GitAction.get_ahead_num(LocalRepoDir: repoDir)
        let aheadNum: String = gitAhead["ahead"]!
        if aheadNum == "" || aheadNum.isAllDigits() {
            DispatchQueue.main.async {
                Ahead = aheadNum
                GitObservable.GitAhead = aheadNum
            }
        }
    }
    
    func g_push_action(param: gitPushParam = .push) {
        if !isButtonDisabled {
            isButtonDisabled = true
        }

        GitPushHelper.pushAsync(LocalRepoDir: repoDir, param: param) { output in
            if let output = output {
                print(output)
            }
            DispatchQueue.main.async {
                isButtonDisabled = false
                if output == "push_success" {
                    Ahead = ""
                }
            }
        }
    }
}
