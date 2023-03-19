//
//  view_empty.swift
//  GitHive
//
//  Created by 1 on 3/19/23.
//

import SwiftUI

struct view_empty: View {
    var text: String
    
    var body: some View {
        VStack {
            Spacer()
            Text(text)
                .font(.title2)
                .fontWeight(.light)
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
