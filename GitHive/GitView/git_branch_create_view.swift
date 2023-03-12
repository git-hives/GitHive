//
//  git_branch_create_view.swift
//  easy-git
//
//  Created by hx on 3/7/23.
//

import SwiftUI

struct refItem: Identifiable {
    let id = UUID().uuidString
    let name: String
}

struct git_branch_create_view: View {
    
    var projectPath: String
    var userSelectedRef: String
    @Binding var isShowWindow: Bool
    
    @State private var refsList: [refItem] = []
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
            getGitRefsList()
        }
    }
    
    // 分支：获取所有的分支、tags
    func getGitRefsList() {
        var tmpList: [refItem] = []
        var selectedOptionIndex: String = ""
        GitBranchHelper.getAllRefs(at: projectPath) { output in
            if !output.isEmpty {
                if let bList = output as? [Dictionary<String, String>] {
                    tmpList = bList.map { refItem(name:$0["name"]!) }
                    for i in tmpList {
                        if i.name == userSelectedRef {
                            selectedOptionIndex = i.id
                        }
                    }
                }
            }
            if !tmpList.isEmpty {
                DispatchQueue.main.async {
                    self.refsList = tmpList
                    self.selectedOptionIndex = selectedOptionIndex
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
