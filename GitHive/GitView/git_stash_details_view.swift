//
//  git_stash_details_view.swift
//  GitHive
//
//  Created by 1 on 3/15/23.
//

import SwiftUI

struct git_stash_details_view: View {
    var repoDir: String = ""
    var stashName: String = ""
    
    var body: some View {
        VStack {
            if stashName == "" {
                EmptyView()
            } else {
                show_details
            }
            Text("xxxx \(stashName)")
        }
    }
    
    var show_details: some View {
        ScrollView(.vertical, showsIndicators: true) {
            Text("xxx")
            Text(repoDir)
            Text(stashName)
        }
    }
    
    func getStashDetails() {
        if stashName == "" || repoDir == "" {
            return
        }
        Task {
            do {
                
                let result = try await GitStashHelper.showDetails(LocalRepoDir: repoDir, name: stashName)
                print(result)
            } catch let error {
                
            }
        }
    }
}
