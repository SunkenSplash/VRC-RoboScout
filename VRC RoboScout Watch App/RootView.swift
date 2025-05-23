//
//  RootView.swift
//  VRC RoboScout Watch App
//
//  Created by William Castro on 7/26/24.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject var wcSession: WatchSession
    
    @EnvironmentObject var settings: UserSettings
    
    @State var favorite_teams: [String] = defaults.object(forKey: "favorite_teams") as? [String] ?? [String]()
    @State var favorite_events: [String] = defaults.object(forKey: "favorite_events") as? [String] ?? [String]()

    @State var tabId = 0
    @State var wsTitle = "World Skills"
    @State var wsShowFilters = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            
    var body: some View {
        NavigationStack {
            TabView(selection: $tabId) {
                FavoritesView(teams: $favorite_teams, events: $favorite_events)
                    .navigationTitle("Favorites")
                    .navigationBarTitleDisplayMode(.large)
                    .environmentObject(wcSession)
                    .tag(0)
                    .onReceive(timer) { _ in
                        if favorite_teams != defaults.object(forKey: "favorite_teams") as? [String] ?? [String]() {
                            favorite_teams = defaults.object(forKey: "favorite_teams") as? [String] ?? [String]()
                        }
                        if favorite_events != defaults.object(forKey: "favorite_events") as? [String] ?? [String]() {
                            favorite_events = defaults.object(forKey: "favorite_events") as? [String] ?? [String]()
                        }
                    }
                WorldSkillsRankingsView(title: $wsTitle, showFilters: $wsShowFilters)
                    .navigationTitle(wsTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .tag(1)
                Text("TrueSkill")
                    .navigationTitle("TrueSkill")
                    .navigationBarTitleDisplayMode(.inline)
                    .tag(2)
                SettingsView()
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.large)
                    .environmentObject(settings)
                    .tag(3)
            }.toolbar {
                if tabId == 1 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            wsShowFilters = true
                        }, label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        })
                    }
                }
            }
        }
    }
}

#Preview {
    RootView()
}
