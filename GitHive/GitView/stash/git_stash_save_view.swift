//
//  git_stash_save_view.swift
//  GitHive
//
//  Created by 1 on 3/19/23.
//

import SwiftUI

struct git_stash_save_view: View {
    @Binding var isPresented: Bool
    
    @State private var inputValue = ""
    
    @State private var option_all: Bool = false
    @State private var option_staged: Bool = false
    @State private var option_keep_index: Bool = false
    @State private var option_include_untracked: Bool = false
    
    var title: String
    var placeholder: String = ""
    var onConfirm: ((String) -> Void)?
    var onCancel: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading) {
                TextField(placeholder, text: $inputValue)
                    .frame(height: 40)
                
                Toggle("--all", isOn: $option_all)
                    .toggleStyle(.checkbox)
                Toggle("--include-untracked (Stash all untracked files.)", isOn: $option_include_untracked)
                    .toggleStyle(.checkbox)
                Toggle("--staged (Stash only the changes that are currently staged.)", isOn: $option_staged)
                    .toggleStyle(.checkbox)
                Toggle("--keep-index", isOn: $option_keep_index)
                    .toggleStyle(.checkbox)
            }
            .padding(.horizontal)
            
            
            HStack(alignment: .lastTextBaseline) {
                Spacer()
                Button("Cancel") {
                    self.isPresented = false
                    self.onCancel?()
                }
                
                Button("Confirm") {
                    var cmd: String = "stash push"
                    if option_all {
                        cmd = cmd + " --all"
                    }
                    if option_staged {
                        cmd = cmd + " --staged"
                    }
                    if option_keep_index {
                        cmd = cmd + " --keep-index"
                    }
                    if option_include_untracked {
                        cmd = cmd + " --include-untracked"
                    }
                    cmd = cmd + " -m " + "\"\(self.inputValue)\""
                    self.isPresented = false
                    self.onConfirm?(cmd)
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.inputValue.isEmpty)
            }
        }
        .padding()
        .frame(width: 460, height: 260)
    }
}
