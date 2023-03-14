//
//  git_logs_view.swift
//  easy-git
//
//  Created by 1 on 2/23/23.
//

import SwiftUI

struct GitLogItem: Identifiable {
    let id = UUID().uuidString
    let abbrHash: String
    let CommitHash: String
    let Author: String
    let Email: String
    let DisplayDate: String
    let Date: String
    let Message: String
}


struct git_logs_view: View {
    @EnvironmentObject var GitObservable: GitObservable
    
    @State private var gitLogList: [GitLogItem] = []
    
    @State private var selectedItemId: String = ""
    @State private var selectedItem: String = ""
    
    @State private var hoverItemId: String = ""
    
    var repoPath: String {
        GitObservable.GitProjectPathProperty
    }
    
    var body: some View {
        VStack() {
            ScrollView(.vertical, showsIndicators: true) {
                ForEach(gitLogList, id:\.id) { item in
                    show_log(item: item, selectedItemId: $selectedItemId, hoverItemId: $hoverItemId)
                }
                .padding(.vertical, 20)
                .padding(.trailing, 7)
            }
        }
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                getGitLogList(repoPath: repoPath, dataList: $gitLogList)
            }
            
        }
        .onChange(of: repoPath) { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                getGitLogList(repoPath: repoPath, dataList: $gitLogList)
            }
        }
        .onChange(of: GitObservable.GitBranchProperty) { value in
            getGitLogList(repoPath: repoPath, dataList: $gitLogList)
        }
        .onChange(of: GitObservable.monitoring_git_pull) { value in
            getGitLogList(repoPath: repoPath, dataList: $gitLogList)
        }
    }
}

struct show_log: View {
    var item: GitLogItem
    
    @Binding var selectedItemId: String
    @Binding var hoverItemId: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.Message)
                .foregroundColor(selectedItemId == item.CommitHash ? .white : .primary)
            HStack {
                Text(item.Author)
                Spacer()
                Text(item.DisplayDate)
            }
            .font(.callout)
            .foregroundColor(selectedItemId == item.CommitHash ? .white : .gray)
            .lineLimit(1)
        }
        .frame(height: 50)
        .padding(.horizontal, 10)
        .background(hoverItemId == item.CommitHash ? Color.gray.opacity(0.1) : Color.clear)
        .background(selectedItemId == item.CommitHash  ? Color.blue.opacity(0.95) : Color.clear)
        .cornerRadius(3)
        .onTapGesture {
            self.selectedItemId = item.CommitHash
        }
        .onHover { isHovered in
            hoverItemId = isHovered ? item.CommitHash : ""
        }
        .contextMenu {
            Button("Checkout...", action: {

            })
            Divider()
            Button("Create Branch", action: {
                
            })
            Button("Create Tag", action: {
                
            })
            Divider()
            Button("Revert commit", action: {
                
            })
            Button("Reset to this commit", action: {
                
            })
            Divider()
            Button("Copy", action: {
                actionCopy(selected: item, copyType: "")
            })
            Button("Copy \(item.abbrHash)...", action: {
                actionCopy(selected: item, copyType: "hash")
            })
        }
    }
}


// 日志列表：获取git 日志列表
fileprivate func getGitLogList(repoPath: String, dataList: Binding<[GitLogItem]>) {
    if repoPath.isEmpty {
        return
    }
    
    var tmpLogList: [GitLogItem] = []
    GitLog.get(LocalRepoDir: repoPath, cmd: []) { output in
        if let bList = output as? [Dictionary<String, String>] {
            for i in bList {
                var date = i["Date"]!
                if let formattedString = formatDateString(dateString: date) {
                    date = formattedString
                }
                tmpLogList.append(GitLogItem(abbrHash: i["abbrHash"]!, CommitHash: i["CommitHash"]!, Author: i["Author"]!, Email: i["Email"]!, DisplayDate: date, Date: i["Date"]!, Message: i["Message"]!))
            }
        }
        if !tmpLogList.isEmpty {
            DispatchQueue.main.async {
                dataList.wrappedValue = tmpLogList
            }
        }
    }
}

// 日志列表：右键菜单
fileprivate func actionCopy(selected: GitLogItem, copyType: String) {
    if copyType == "hash" {
        copyToPasteboard(at: selected.CommitHash)
    } else {
        let content: String = " \(selected.Date) \(selected.CommitHash)  \(selected.Message) \(selected.Author) \(selected.Email)"
        copyToPasteboard(at: content)
    }
}


struct git_logs_view_Previews: PreviewProvider {
    static var previews: some View {
        git_logs_view()
    }
}
