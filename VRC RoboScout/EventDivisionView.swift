//
//  EventDivisionView.swift
//  VRC RoboScout
//
//  Created by William Castro on 4/20/23.
//

import SwiftUI

struct EventDivisionView: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    
    @StateObject var navigation_bar_manager = NavigationBarManager(title: "Rankings")
    
    @State var event: Event
    @State var event_teams: [Team]
    @State var division: Division
    @State var teams_map: [String: String]
    @State var showingPopover = false
    
    init(event: Event, event_teams: [Team], division: Division, teams_map: [String: String]) {
        self.event = event
        self.event_teams = event_teams
        self.division = division
        self.teams_map = teams_map
    }
    
    var body: some View {
        TabView {
            EventTeams(event: self.event, division: self.division, teams_map: $teams_map, event_teams: $event_teams, event_teams_list: [String]())
                .tabItem {
                    if settings.getMinimalistic() {
                        Image(systemName: "person.3.fill")
                    }
                    else {
                        Label("Teams", systemImage: "person.3.fill")
                    }
                }
                .environmentObject(favorites)
                .environmentObject(settings)
                .environmentObject(navigation_bar_manager)
                .tint(settings.accentColor())
            EventDivisionMatches(teams_map: $teams_map, event: self.event, division: self.division)
                .tabItem {
                    if settings.getMinimalistic() {
                        Image(systemName: "calendar.badge.clock")
                    }
                    else {
                        Label("Teams", systemImage: "calendar.badge.clock")
                    }
                }
                .environmentObject(favorites)
                .environmentObject(settings)
                .environmentObject(navigation_bar_manager)
                .tint(settings.accentColor())
            EventDivisionRankings(event: self.event, division: self.division, teams_map: teams_map)
                .tabItem {
                    if settings.getMinimalistic() {
                        Image(systemName: "list.number")
                    }
                    else {
                        Label("Rankings", systemImage: "list.number")
                    }
                }
                .environmentObject(favorites)
                .environmentObject(settings)
                .environmentObject(navigation_bar_manager)
                .tint(settings.accentColor())
        }.onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }.tint(settings.accentColor())
            .background(.clear)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text(navigation_bar_manager.title)
                                .fontWeight(.medium)
                                .font(.system(size: 19))
                                .foregroundColor(settings.navTextColor())
                        }
                        if navigation_bar_manager.title.contains("Rankings") {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    showingPopover = true
                                }, label: {
                                    Image(systemName: "info.circle")
                                }).popover(isPresented: $showingPopover) {
                                    ScrollView {
                                        Text("Ranking Performance Ratings")
                                            .font(.headline)
                                            .padding()
                                        VStack(alignment: .leading) {
                                            Text("WP (Win Points) are the primary deciding factor in rankings. They are awarded by:").padding()
                                            BulletList(listItems: ["Winning a match (+2 win points)", "Drawing a match (+1 win point)", "Earning the Autonomous Win Point (+1 win point)"], listItemSpacing: 10).padding()
                                            Text("AP (Autonomous Points) are the first tiebreaker in rankings. They are awarded by:").padding()
                                            BulletList(listItems: ["Winning the autonomous period (full points)", "Autonomous tie (half points)"], listItemSpacing: 10).padding()
                                            Text("SP (Strength of Schedule Points) are the second tiebreaker in rankings. They are a measure of how difficult a team's schedule is, and are equal to the sum of the losing alliance scores for each match.").padding()
                                            Text("OPR (Offensive Power Rating) is the scoring power a robot has. It can be considered a measure of how many additional points a team brings to their alliance in a match. Higher is better.").padding()
                                            Text("DPR (Defensive Power Rating) is the defensive power of a robot and represents how much a team stops its opponents from scoring. Lower is better.").padding()
                                            Text("CCWM (Calculated Contribution to Winning Margin) is a measure of the positive impact a robot brings to an alliance. It is equal to OPR - DPR. Higher is better.").padding()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(settings.tabColor(), for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct EventDivisionView_Previews: PreviewProvider {
    static var previews: some View {
        EventDivisionView(event: Event(), event_teams: [Team](), division: Division(), teams_map: [String: String]())
    }
}