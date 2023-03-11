//
//  Config.swift
//  GitHive
//
//  Created by 1 on 3/11/23.
//

import Foundation

// 通过此项 控制日志打印
let isDebug = false

// 应用程序名称
public let appName: String = "nGit"

// 应用程序配置文件，主要用来存储历史记录
public let appSessionFileName: String = "Session.json"

// 是否正在操作git_pull
public var do_git_pull_action: Bool = false

// 是否正在操作git_push
public var do_git_push_action: Bool = false
