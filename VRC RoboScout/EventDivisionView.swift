//
//  EventDivisionView.swift
//  VRC RoboScout
//
//  Created by William Castro on 4/20/23.
//

import SwiftUI

public enum PredictionState {
    case disabled
    case off
    case calculating
    case on
}

public class PredictionManager: ObservableObject {
    @Published var state = PredictionState.off
}

struct EventDivisionView: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: RoboScoutDataController
    
    @StateObject var navigation_bar_manager = NavigationBarManager(title: "Rankings")
    @StateObject var prediction_manager = PredictionManager()
    
    @State var event: Event
    @State var event_teams: [Team]
    @State var division: Division
    @State var teams_map: [String: String]
    @State var showingSheet = false
    
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
                    if UserSettings.getMinimalistic() {
                        Image(systemName: "person.3.fill")
                    }
                    else {
                        Label("Teams", systemImage: "person.3.fill")
                    }
                }
                .environmentObject(favorites)
                .environmentObject(settings)
                .environmentObject(dataController)
                .environmentObject(navigation_bar_manager)
                .tint(settings.accentColor())
            EventDivisionMatches(teams_map: $teams_map, event: self.event, division: self.division)
                .tabItem {
                    if UserSettings.getMinimalistic() {
                        Image(systemName: "clock.fill")
                    }
                    else {
                        Label("Match List", systemImage: "clock.fill")
                    }
                }
                .environmentObject(favorites)
                .environmentObject(settings)
                .environmentObject(navigation_bar_manager)
                .environmentObject(prediction_manager)
                .environmentObject(dataController)
                .tint(settings.accentColor())
            EventDivisionRankings(event: self.event, division: self.division, teams_map: teams_map)
                .tabItem {
                    if UserSettings.getMinimalistic() {
                        Image(systemName: "list.number")
                    }
                    else {
                        Label("Rankings", systemImage: "list.number")
                    }
                }
                .environmentObject(favorites)
                .environmentObject(settings)
                .environmentObject(dataController)
                .environmentObject(navigation_bar_manager)
                .tint(settings.accentColor())
                .sheet(isPresented: $showingSheet) {
                    Text("Ranking Performance Ratings")
                        .font(.headline)
                        .padding()
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text("WP (Win Points) are the primary deciding factor in rankings. They are awarded by:").padding()
                            BulletList(listItems: ["Winning a match (+2 win points)", "Drawing a match (+1 win point)", "Earning the Autonomous Win Point (+1 win point)"], listItemSpacing: 10).padding()
                            Text("AP (Autonomous Points) are the first tiebreaker in rankings. They are awarded by:").padding()
                            BulletList(listItems: ["Winning the autonomous period (full points)", "Autonomous tie (half points)"], listItemSpacing: 10).padding()
                            Text("SP (Strength of Schedule Points) are the second tiebreaker in rankings. They are a measure of how difficult a team's schedule is, and are equal to the sum of the losing alliance scores for each match.").padding()
                            Text("OPR (Offensive Power Rating) is the scoring power a robot has. It can be considered a measure of how many additional points a team brings to their alliance in a match. Higher is better.").padding()
                            Text("DPR (Defensive Power Rating) is the defensive power of a robot and can be considered a measure of how much a team contibutes to the score of the opposing alliance. Lower is better.").padding()
                            Text("CCWM (Calculated Contribution to Winning Margin) is a measure of the positive impact a robot brings to an alliance. It is equal to OPR - DPR. Higher is better.").padding()
                        }
                    }
                }
            EventDivisionAwards(event: self.event, division: self.division)
                .tabItem {
                    if UserSettings.getMinimalistic() {
                        Image(systemName: "trophy")
                    }
                    else {
                        Label("Awards", systemImage: "trophy")
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
                                    showingSheet = true
                                }, label: {
                                    Image(systemName: "info.circle").foregroundColor(settings.navTextColor())
                                })
                            }
                        }
                        else if navigation_bar_manager.title.contains("Match List") {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    if prediction_manager.state == PredictionState.off {
                                        prediction_manager.state = PredictionState.calculating
                                    }
                                    else if prediction_manager.state == PredictionState.on {
                                        prediction_manager.state = PredictionState.off
                                    }
                                    self.event = self.event
                                }, label: {
                                    if prediction_manager.state == PredictionState.disabled {
                                        Image(systemName: "bolt.slash").foregroundColor(settings.navTextColor())
                                    }
                                    else if prediction_manager.state == PredictionState.off {
                                        Image(systemName: "bolt").foregroundColor(settings.navTextColor())
                                    }
                                    else if prediction_manager.state == PredictionState.calculating {
                                        ProgressView().foregroundColor(settings.navTextColor())
                                    }
                                    else {
                                        Image(systemName: "bolt.fill").foregroundColor(settings.navTextColor())
                                    }
                                })
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
