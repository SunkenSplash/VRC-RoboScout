//
//  RootView.swift
//  VRC RoboScout W Watch App
//
//  Created by William Castro on 7/26/24.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject var wcSession: WatchSessionW
    
    @EnvironmentObject var settings: UserSettings
            
    var body: some View {
        NavigationStack {
            TabView {
                FavoritesViewW()
                    .navigationTitle("Favorites")
                    .navigationBarTitleDisplayMode(.automatic)
                    .environmentObject(wcSession)
                Text("Tab 2")
                    .navigationTitle("Tab 2")
                    .navigationBarTitleDisplayMode(.automatic)
                Text("Tab 3")
                    .navigationTitle("Tab 3")
                    .navigationBarTitleDisplayMode(.automatic)
                Text("Tab 4")
                    .navigationTitle("Tab 4")
                    .navigationBarTitleDisplayMode(.automatic)
                Text("Tab 5")
                    .navigationTitle("Tab 5")
                    .navigationBarTitleDisplayMode(.automatic)
            }
        }
    }
}

#Preview {
    RootView()
}
