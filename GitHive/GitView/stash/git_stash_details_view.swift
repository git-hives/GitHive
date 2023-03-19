//
//  git_stash_details_view.swift
//  GitHive
//
//  Created by 1 on 3/15/23.
//

import SwiftUI

struct stashFileItem: Identifiable {
    let id = UUID()
    let filename: String
    let add_line: String
    let del_line: String
}

struct git_stash_details_view: View {
    @EnvironmentObject var GitObservable: GitObservable
    
    var repoPath: String {
        GitObservable.GitProjectPathProperty
    }
    
    var activeStashName: String {
        GitObservable.stash_view_active_stash
    }
    
    @State private var statFiles:  [stashFileItem] = []
    @State private var statSummary: Dictionary<String, String> = [:]
    
    var body: some View {
        VStack(alignment: .leading) {
            if statFiles.count == 0 {
                EmptyView()
            } else {
                show_summary
                show_fileList
            }
        }
        .onChange(of: GitObservable.stash_view_active_stash) { value in
            DispatchQueue.main.async {
                if value.trimming() != "" {
                    getStashSummaryInfo()
                } else {
                    self.statFiles = []
                    self.statSummary = [:]
                }
            }
        }
    }
    
    var show_summary: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(statSummary["Message"] ?? "")")
                    .font(.title2)
            }
            .padding(.vertical, 10)
            
            HStack {
                VStack(alignment: .leading, spacing:10) {
                    Text("Date")
                    Text("Author")
                    Text("Commit Hash")
                    Text("Tree")
                    Text("Parents")
                }
                .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing:10) {
                    Text("\(statSummary["AuthorDate"] ?? "")")
                    Text("\(statSummary["Author"] ?? "")")
                    Text("\(statSummary["Commit Hash"] ?? "")")
                    Text("\(statSummary["Tree"] ?? "")")
                    Text("\(statSummary["Parents"] ?? "")")
                }
            }
        }
    }
    
    var show_fileList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading) {
                ForEach(statFiles, id: \.id) { item in
                    HStack {
                        Text(item.filename)
                            .fontWeight(.medium)
                        Text("+\(item.add_line)")
                            .padding(2)
                            .background(.green.opacity(0.2))
                            .cornerRadius(3)
                        Text("-\(item.del_line)")
                            .padding(2)
                            .background(.red.opacity(0.2))
                            .cornerRadius(5)
                    }
//                    .padding(.horizontal, 20)
                    .frame(height: 30)
                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .background(.cyan.opacity(0.3))
                }
            }
        }
    }
    
    // 获取stash的创建日期、作者、变更的文件列表等。但是不包含文件修改详情
    func getStashSummaryInfo() {
        if activeStashName == "" || repoPath == "" {
            return
        }
        Task {
            do {
                let result = try await GitStashHelper.showStashStat(LocalRepoDir: repoPath, name: activeStashName)
                self.statFiles = result.statFiles
                self.statSummary = result.statSummary
            } catch let error {
                let msg = getErrorMessage(etype: error as! GitError)
                _ = showAlert(title: "Error", msg: msg, ConfirmBtnText: "Ok")
            }
        }
    }
}
