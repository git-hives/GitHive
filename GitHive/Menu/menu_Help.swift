//
//  menu_Help.swift
//  easy-git
//
//  Created by 1 on 3/11/23.
//

import SwiftUI

struct menu_Help: Commands {
    
    var body: some Commands {
        
        CommandGroup(replacing: CommandGroupPlacement.help) {
            Button(action: {
                
            }) {
                Label("New Item", systemImage: "plus")
            }
        }
        
    }
}
