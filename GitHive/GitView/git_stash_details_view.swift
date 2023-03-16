//
//  git_stash_details_view.swift
//  GitHive
//
//  Created by 1 on 3/15/23.
//

import SwiftUI

struct git_stash_details_view: View {
    @EnvironmentObject var GitObservable: GitObservable
    
    var repoPath: String {
        GitObservable.GitProjectPathProperty
    }
    
    var activeStashName: String {
        GitObservable.stash_view_active_stash
    }
    
    var body: some View {
        VStack {
            if activeStashName == "" {
                EmptyView()
            } else {
                show_details
            }
        }
        .onChange(of: GitObservable.stash_view_active_stash) { value in
            getStashDetails()
        }
    }
    
    var show_details: some View {
        ScrollView(.vertical, showsIndicators: true) {
            Text(activeStashName)
        }
    }
    
    func getStashDetails() {
        if activeStashName == "" || repoPath == "" {
            return
        }
        Task {
            do {
                let result = try await GitStashHelper.showDetails(LocalRepoDir: repoPath, name: activeStashName)
//                print(result)
            } catch let error {
                
            }
        }
    }
}
