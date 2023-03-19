//
//  git_clone_view.swift
//  easy-git
//
//  Created by 1 on 2/28/23.
//

import SwiftUI

struct git_clone_view: View {
    @Binding var isPresented: Bool

    @State var gitRepoURL: String = ""
    @State var repoName: String = ""
    @State var DestinationPath: String = ""

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Git Clone")
                    .font(.title)
                    .padding(.top, 20)
                Spacer()
            }
            
            VStack {
                HStack {
                    Text("Source URL:")
                        .frame(width: 115, alignment: .leading)
                    TextField("", text: $gitRepoURL)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("Repository Name:")
                        .frame(width: 115, alignment: .leading)
                    TextField("", text: $repoName)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("Destination Path:")
                        .frame(width: 115, alignment: .leading)
                    TextField("", text: $DestinationPath)
                        .textFieldStyle(.roundedBorder)
                    Button("select", action: {
                        
                    })
                }
            }

          HStack {
              Spacer()
              Button("Cancel") {
                  isPresented = false
              }
              .buttonStyle(BorderedButtonStyle())

              Button("Clone") {
                  isPresented = false
              }
              .buttonStyle(BorderedButtonStyle())
          }
      }
      .padding()
      .frame(width: 600, height: 300)
      .cornerRadius(20)
      .background(.gray.opacity(0.05))
      
  }
}
