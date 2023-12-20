//
//  RootView.swift
//  VRC RoboScout
//
//  Created by William Castro on 11/15/23.
//

import SwiftUI

class NavigationBarManager: ObservableObject {
    @Published var title: String
    init(title: String) {
        self.title = title
    }
}

struct RootView: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: RoboScoutDataController
    
    @StateObject var navigation_bar_manager = NavigationBarManager(title: "Favorites")
    
    @State private var tab_selection = 0
    @State private var lookup_type = 0 // 0 is teams, 1 is events
        
    var body: some View {
        NavigationStack {
            TabView(selection: $tab_selection) {
                Favorites(tab_selection: $tab_selection, lookup_type: $lookup_type)
                    .tabItem {
                        if UserSettings.getMinimalistic() {
                            Image(systemName: "star")
                        }
                        else {
                            Label("Favorites", systemImage: "star")
                        }
                    }
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.accentColor())
                    .tag(0)
                WorldSkillsRankings()
                    .tabItem {
                        if UserSettings.getMinimalistic() {
                            Image(systemName: "globe")
                        }
                        else {
                            Label("World Skills", systemImage: "globe")
                        }
                    }
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.accentColor())
                    .tag(1)
                TrueSkillRankings()
                    .tabItem {
                        if UserSettings.getMinimalistic() {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                        }
                        else {
                            Label("TrueSkill", systemImage: "chart.line.uptrend.xyaxis")
                        }
                    }
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.accentColor())
                    .tag(2)
                Lookup(lookup_type: $lookup_type)
                    .tabItem {
                        if UserSettings.getMinimalistic() {
                            Image(systemName: "magnifyingglass")
                        }
                        else {
                            Label("Lookup", systemImage: "magnifyingglass")
                        }
                    }
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.accentColor())
                    .tag(3)
                Settings()
                    .tabItem {
                        if UserSettings.getMinimalistic() {
                            Image(systemName: "gear")
                        }
                        else {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.accentColor())
                    .tag(4)
            }.onAppear {
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithDefaultBackground()
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }.tint(settings.accentColor())
                .background(.clear)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                VStack {
                                    Text(navigation_bar_manager.title)
                                        .fontWeight(.medium)
                                        .font(.system(size: 19))
                                        .foregroundColor(settings.navTextColor())
                                    if navigation_bar_manager.title.contains("TrueSkill") {
                                        Text("Powered by vrc-data-analysis.com")
                                            .font(.system(size: 12))
                                            .foregroundColor(settings.navTextColor().opacity(0.75))
                                    }
                                }
                            }
                            if navigation_bar_manager.title.contains("Skills") {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Link(destination: URL(string: "https://www.robotevents.com/robot-competitions/vex-robotics-competition/standings/skills")!) {
                                        Image(systemName: "link")
                                    }.foregroundColor(settings.navTextColor())
                                }
                            }
                            else if navigation_bar_manager.title.contains("TrueSkill") {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Link(destination: URL(string: "http://vrc-data-analysis.com/")!) {
                                        Image(systemName: "link")
                                    }.foregroundColor(settings.navTextColor())
                                }
                            }
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(settings.tabColor(), for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
        }.tint(settings.navTextColor())
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
