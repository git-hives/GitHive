//
//  menu_Repository.swift
//  easy-git
//
//  Created by 1 on 3/11/23.
//

import SwiftUI

struct menu_File: Commands {
//    @EnvironmentObject var gitObservable: GitObservable
    
    var body: some Commands {
        
        CommandGroup(replacing: CommandGroupPlacement.newItem) {
            Button("New Repository", action: {
                openLocalRepository.open()
            })
            
            Button("Clone Repository", action: {
                
            })
        }
    }
}
