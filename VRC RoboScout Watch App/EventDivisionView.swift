//
//  EventDivisionView.swift
//  VRC RoboScout Watch App
//
//  Created by William Castro on 5/26/25.
//

import SwiftUI

struct EventDivisionView: View {
    
    @EnvironmentObject var wcSession: WatchSession
    
    @EnvironmentObject var settings: UserSettings
    
    @State var event: Event
    @State var event_teams: [Team]
    @State var division: Division
    @State var teams_map: [String: String]
    @State var division_teams_list: [String]

    @State var tabId = 0
    @State var showRankingSortingOptions = false
    @State var sortingOption = 0
    
    init(event: Event, event_teams: [Team], division: Division, teams_map: [String: String]) {
        self.event = event
        self.event_teams = event_teams
        self.division = division
        self.teams_map = teams_map
        self.division_teams_list = [String]()
    }
            
    var body: some View {
        NavigationStack {
            TabView(selection: $tabId) {
                EventTeamsView(event: self.event, division: self.division, teams_map: $teams_map, event_teams: $event_teams, event_teams_list: [String]())
                    .tag(0)
                EventDivisionMatchesView(teams_map: $teams_map, event: self.event, division: self.division)
                    .tag(1)
                EventDivisionRankingsView(event: self.event, division: self.division, teams_map: teams_map, sortingOption: $sortingOption)
                    .tag(2)
                EventDivisionAwardsView(event: self.event, division: self.division)
                    .tag(3)
            }.navigationTitle(division.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                if tabId == 2 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            showRankingSortingOptions = true
                        }, label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        })
                    }
                }
            }.fullScreenCover(isPresented: $showRankingSortingOptions) {
                VStack {
                    Button("Rank") {
                        sortingOption = 0
                        showRankingSortingOptions = false
                    }
                    Button("AP") {
                        sortingOption = 4
                        showRankingSortingOptions = false
                    }
                    Button("SP") {
                        sortingOption = 5
                        showRankingSortingOptions = false
                    }
                }
            }
        }
    }
}

#Preview {
    EventDivisionView(event: Event(), event_teams: [Team](), division: Division(), teams_map: [String: String]())
}
