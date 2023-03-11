//
//  UI.swift
//  easy-git
//
//  Created by hx on 3/3/23.
//

import Cocoa
import Foundation
import SwiftUI

func showAlert(title: String, msg: String, ConfirmBtnText: String, CancelBtnText: String = "Cancel") -> Bool {
    let alert = NSAlert()
    if title != "" {
        alert.messageText = title
    }
    alert.informativeText = msg
    alert.addButton(withTitle: ConfirmBtnText)
    alert.addButton(withTitle: CancelBtnText)
    
    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
        return true
    } else if response == .alertSecondButtonReturn {
        return false
    }
    return false
}

func showAlertOnlyPrompt(msgType: String, title: String, msg: String, ConfirmBtnText: String) -> Bool {
    let alert = NSAlert()
    if msgType == "warning" {
        alert.alertStyle = .critical
    }
    if title != "" {
        alert.messageText = title
    }
    alert.informativeText = msg
    alert.addButton(withTitle: ConfirmBtnText)
    
    _ = alert.runModal()
    return false
}


// 视图：操作按钮
struct ActionButtonForMenu: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActionButtonForSilderNav: View {
    let title: String
    let systemImage: String
    let help: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }, label: {
            Label(title, systemImage: systemImage)
        })
        .buttonStyle(LeftNavButtonStyle())
        // 使用focusable解决应用程序首次启动 此入口出现蓝边的问题
        .focusable(false)
        .foregroundColor(isActive ? .blue : .gray)
        .help(help)
    }
}


// 搜索类型的输入框
struct SearchTextField: View {
    @Binding var text: String
//    @Binding var height: CGFloat
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .padding(.leading, 10)
                
            TextField("Filter", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }, label: {
                    Label("",systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                })
                .buttonStyle(.plain)
                .padding(.trailing, 10)
            }
        }
        .frame(height: 20)
        .padding(.top, 10)
    }
}
