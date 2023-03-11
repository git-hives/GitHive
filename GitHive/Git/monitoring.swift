//
//  mm.swift
//  easy-git
//
//  Created by 1 on 3/7/23.
//

import Foundation
import AppKit
import Combine


class GitObserverMonitoring: NSObject, NSFilePresenter, ObservableObject {
    
    var presentedItemURL: URL?
    var presentedItemOperationQueue: OperationQueue
    var fileCoordinator: NSFileCoordinator
    
    @Published var monitoring_project_file: String = ""
    @Published var monitoring_git_HEAD: Int = 0
    @Published var monitoring_git_index: Int = 0
    @Published var monitoring_git_pull: Int = 0
    @Published var monitoring_git_push: Int = 0
    @Published var monitoring_git_ci: Int = 0
    
    var last_fetch_time: Int64 = 0
    
    override init() {
        self.presentedItemOperationQueue = OperationQueue()
        self.fileCoordinator = NSFileCoordinator()
        super.init()
    }
    
    func presentedSubitemDidChange(at url: URL) {
        let fpath: String = url.absoluteString
        if fpath.suffix(5) == ".lock" && fpath.contains("/.git/") {
            return
        }
        if fpath.contains(".git/objects/") || fpath.contains(".git/logs/") {
            return
        }
        
        var relativePath: String = fpath
        let projectPath: String = presentedItemURL!.absoluteString
        if let range = fpath.range(of: projectPath) {
            relativePath = String(fpath[range.upperBound...])
        }
        
        var currentTimestamp = getCurrentTimeInMilliseconds()
        
        print("[.git监听]---：", relativePath)
        if relativePath.prefix(5) != ".git/" {
            DispatchQueue.main.async {
                self.monitoring_project_file = relativePath
            }
            return
        }
        
        if relativePath == ".git/HEAD" {
            DispatchQueue.main.async {
                self.monitoring_git_HEAD += 1
            }
        }
        if relativePath == ".git/index" {
            DispatchQueue.main.async {
                self.monitoring_git_index += 1
            }
        }
        if relativePath == ".git/FETCH_HEAD" {
            if currentTimestamp - last_fetch_time > 4800 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.monitoring_git_pull += 1
                }
            }
            last_fetch_time = currentTimestamp
        }
        if relativePath == ".git/COMMIT_EDITMSG" {
            DispatchQueue.main.async {
                self.monitoring_git_ci += 1
            }
        }
        if fpath.contains(".git/refs/remotes/") {
            DispatchQueue.main.async {
                self.monitoring_git_push += 1
            }
        }
    }
    
    func startObserving(url: URL) {
        self.presentedItemURL = url
        fileCoordinator.coordinate(
            readingItemAt: presentedItemURL!,
            options: [.withoutChanges, .resolvesSymbolicLink],
            error: nil) { (url) in
                self.presentedItemURL = url
                NSFileCoordinator.addFilePresenter(self)
        }
    }
    
    func stopObserving() {
        NSFileCoordinator.removeFilePresenter(self)
    }
}
