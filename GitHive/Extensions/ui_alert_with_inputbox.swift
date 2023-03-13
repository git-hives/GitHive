//
//  ui_alert_with_inputbox.swift
//  GitHive
//
//  Created by 1 on 3/13/23.
//

import SwiftUI

struct ui_alert_with_inputbox: View {
    @Binding var isPresented: Bool
    @State private var inputValue = ""
    
    var title: String
    var placeholder: String = ""
    var onConfirm: ((String) -> Void)?
    var onCancel: (() -> Void)?
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 20)
            
            TextField(placeholder, text: $inputValue)
                .frame(height: 40)
                .padding(.horizontal)
            
            HStack(alignment: .lastTextBaseline) {
                Spacer()
                Button("Cancel") {
                    self.isPresented = false
                    self.onCancel?()
                }
                
                Button("Confirm") {
                    self.isPresented = false
                    self.onConfirm?(self.inputValue)
                }
            }
            .padding(.top, 20)
        }
        .padding()
        .frame(width: 400, height: 210)
    }
}
