//
//  git_branch_create_view.swift
//  easy-git
//
//  Created by hx on 3/7/23.
//

import SwiftUI

struct git_branch_create_view: View {
    
    var projectPath: String
    var refsList: [GitBranchItem]
    var userSelectedRef: String
    @Binding var isShowWindow: Bool
    
    @State private var dataList: [String] = []
    @State private var selectedRef: String = ""
    @State private var selectedOptionIndex: String = ""
    
    @FocusState var isFocused: Bool
    @State private var newBranchName: String = ""
    
    var isButtonDisabled: Bool {
        newBranchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Create Branch")
                .font(.title3)
            Text("Create a branch from the \"\(selectedRef)\" ")
                .font(.caption2)
                .foregroundColor(.gray)
            
            Form {
                Section("From") {
                    Picker("", selection: $selectedOptionIndex) {
                        ForEach(refsList, id: \.id) { item in
                            Text(item.name)
                        }
                    }
                    .onChange(of: selectedOptionIndex) { value in
                        for i in self.refsList {
                            if i.id == selectedOptionIndex {
                                self.selectedRef = i.name
                            }
                        }
                    }
                }
                
                Section("To") {
                    TextField("", text: $newBranchName)
                        .focused($isFocused)
                        .onAppear() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.isFocused = true
                            }
                        }
                }
            }
            .padding(.top, 15)
            
            HStack {
                Spacer()
                Button("Cancle", action: {
                    self.isShowWindow = false
                })
                Button("Create", action: {
                    create()
                })
                .disabled(isButtonDisabled)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(width: 400, height: 230)
        .cornerRadius(20)
        .background(.gray.opacity(0.05))
        .onAppear() {
            for i in self.refsList {
                self.dataList.append(i.name)
                if i.name == userSelectedRef {
                    self.selectedOptionIndex = i.id
                }
            }
        }
    }
    
    // Git分支创建
    func create() {
        self.isShowWindow = false
        
        GitBranchHelper.BranchCreate(LocalRepoDir: projectPath, from: selectedRef, to: newBranchName) { output in
            print(output)
        }
    }
}
