//
//  EventSkillsRankings.swift
//  VRC RoboScout
//
//  Created by William Castro on 4/24/23.
//

import SwiftUI

class EventSkillsRankingsList: ObservableObject {
    @Published var rankings_indexes: [Int]
    
    init(rankings_indexes: [Int] = [Int]()) {
        self.rankings_indexes = rankings_indexes.sorted()
    }
}

struct EventSkillsRankings: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @State var event: Event
    @State var teams_map: [String: String]
    @State var event_skills_rankings_list: EventSkillsRankingsList
    @State var showLoading = true;
    @State var teamNumberQuery = ""
    
    var searchResults: [Int] {
        if teamNumberQuery.isEmpty {
            return event_skills_rankings_list.rankings_indexes
        }
        else {
            return event_skills_rankings_list.rankings_indexes.filter{ (event.get_team(id: team_ranking(rank: $0).team.id) ?? Team()).number.lowercased().contains(teamNumberQuery.lowercased()) }
        }
    }
    
    init(event: Event, teams_map: [String: String]) {
        self.event = event
        self.teams_map = teams_map
        self.event_skills_rankings_list = EventSkillsRankingsList()
    }
    
    func fetch_rankings() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            event.fetch_skills_rankings()
            var fetched_rankings_indexes = [Int]()
            var counter = 0
            for _ in (event.skills_rankings) {
                fetched_rankings_indexes.append(counter)
                counter += 1
            }
            DispatchQueue.main.async {
                self.event_skills_rankings_list = EventSkillsRankingsList(rankings_indexes: fetched_rankings_indexes)
                self.showLoading = false
            }
        }
    }
    
    func team_ranking(rank: Int) -> TeamSkillsRanking {
        return event.skills_rankings[rank]
    }
    
    var body: some View {
        VStack {
            if showLoading {
                ProgressView().padding()
                Spacer()
            }
            else if event.skills_rankings.isEmpty {
                NoData()
            }
            else {
                NavigationView {
                    List {
                        ForEach(searchResults, id: \.self) { rank in
                            VStack {
                                HStack {
                                    HStack {
                                        Text(teams_map[String(team_ranking(rank: rank).team.id)] ?? "").font(.system(size: 20)).minimumScaleFactor(0.01).frame(width: 70, alignment: .leading).bold()
                                        Text((event.get_team(id: team_ranking(rank: rank).team.id) ?? Team()).name).frame(alignment: .leading)
                                    }
                                    Spacer()
                                }.frame(height: 20, alignment: .leading)
                                HStack {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("# \(team_ranking(rank: rank).rank)").frame(alignment: .leading).font(.system(size: 16))
                                            Text("\(team_ranking(rank: rank).combined_score)").frame(alignment: .leading).font(.system(size: 16))
                                        }.frame(width: 60, alignment: .leading)
                                        Spacer()
                                        VStack(alignment: .leading) {
                                            Text("Prog: \(team_ranking(rank: rank).programming_attempts)").frame(alignment: .leading).font(.system(size: 16)).foregroundColor(.secondary)
                                            Text("\(team_ranking(rank: rank).programming_score)").frame(alignment: .leading).font(.system(size: 16)).foregroundColor(.secondary)
                                        }.frame(width: 90, alignment: .leading)
                                        Spacer()
                                        VStack(alignment: .leading) {
                                            Text("Driver: \(team_ranking(rank: rank).driver_attempts)").frame(alignment: .leading).font(.system(size: 16)).foregroundColor(.secondary)
                                            Text("\(team_ranking(rank: rank).driver_score)").frame(alignment: .leading).font(.system(size: 16)).foregroundColor(.secondary)
                                        }.frame(width: 90, alignment: .leading)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }.navigationViewStyle(StackNavigationViewStyle())
                    .searchable(text: $teamNumberQuery, prompt: "Enter a team number...")
                    .tint(settings.navTextColor())
            }
        }.task{
            fetch_rankings()
        }.background(.clear)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Skills Rankings")
                    .fontWeight(.medium)
                    .font(.system(size: 19))
                    .foregroundColor(settings.navTextColor())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(settings.tabColor(), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(settings.accentColor())
    }
}

struct EventSkillsRankings_Previews: PreviewProvider {
    static var previews: some View {
        EventSkillsRankings(event: Event(), teams_map: [String: String]())
    }
}
