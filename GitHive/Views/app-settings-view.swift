//
//  app-settings-view.swift
//  GitHive
//
//  Created by 1 on 3/11/23.
//

import SwiftUI

struct app_settings_view: View {
    
    private enum Tabs: Hashable {
        case general, advanced
    }
    
    var body: some View {
        TabView {
            SettingsGeneralView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            SettingsAccountView()
                .tabItem {
                    Label("Advanced", systemImage: "star")
                }
                .tag(Tabs.advanced)
        }
        .padding(20)
        .frame(width: 375, height: 150)
    }
    
}

struct SettingsGeneralView: View {
    
    var body: some View {
        Text("1")
    }
}

struct SettingsAccountView: View {
    
    var body: some View {
        Text("1")
    }
}
