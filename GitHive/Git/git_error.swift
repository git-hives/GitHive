//
//  git_error.swift
//  GitHive
//
//  Created by 1 on 3/14/23.
//

import Foundation

enum GitError: Error {
    case preCheckFailed
    case gitPathNotFound
    case changeGitDirectoryFailed
    case gitRunFailed
}

func getErrorMessage(etype: GitError) -> String {
    switch(etype) {
    case .gitRunFailed:
        return "Git command execution failed."
    case .changeGitDirectoryFailed:
        return "Unable to access git repository directory."
    case .gitPathNotFound:
        return "Could not find the git command line tool path."
    case .preCheckFailed:
        return "Git environment check failed."
    }
}
