//
//  styles.swift
//  easy-git
//
//  Created by 1 on 3/1/23.
//

import SwiftUI

struct tbStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.icon
            .foregroundColor(.red)
    }
}
