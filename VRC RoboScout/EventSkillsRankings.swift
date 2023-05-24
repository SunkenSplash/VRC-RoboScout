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
    
    init(event: Event, teams_map: [String: String]) {
        self.event = event
        self.teams_map = teams_map
        self.event_skills_rankings_list = EventSkillsRankingsList()
    }
    
    func fetch_rankings() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            _ = event.fetch_skills_rankings()
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
        if showLoading {
            ProgressView().padding()
        }
        
        List {
            ForEach(event_skills_rankings_list.rankings_indexes, id: \.self) { rank in
                VStack {
                    HStack {
                        Text(teams_map[String(team_ranking(rank: rank).team.id)]!).font(.system(size: 20)).minimumScaleFactor(0.01).frame(width: 60, alignment: .leading)
                        Text(event.get_team(id: team_ranking(rank: rank).team.id).name).frame(alignment: .leading)
                        Spacer()
                    }.frame(height: 20)
                    HStack {
                        VStack {
                            HStack {
                                Text("#\(team_ranking(rank: rank).rank)").frame(alignment: .leading).font(.system(size: 15))
                                Spacer()
                            }
                            /*HStack {
                                Text("\(team_ranking(rank: rank).wins)-\(team_ranking(rank: rank).losses)-\(team_ranking(rank: rank).ties)").frame(alignment: .leading).font(.system(size: 15))
                                Spacer()
                            }*/
                        }.frame(width: 60)
                        /*Spacer()
                        VStack {
                            HStack {
                                Text("WP: \(team_ranking(rank: rank).wp)").frame(alignment: .leading).font(.system(size: 12))
                                Spacer()
                            }
                            HStack {
                                Text("HIGH: \(team_ranking(rank: rank).high_score)").frame(alignment: .leading).font(.system(size: 12))
                                Spacer()
                            }
                        }.frame(width: 80)
                        Spacer()
                        VStack {
                            HStack {
                                Text("AP: \(team_ranking(rank: rank).ap)").frame(alignment: .leading).font(.system(size: 12))
                                Spacer()
                            }
                            HStack {
                                Text("AVG: " + displayRounded(number: team_ranking(rank: rank).average_points)).frame(alignment: .leading).font(.system(size: 12))
                                Spacer()
                            }
                        }.frame(width: 80)
                        Spacer()
                        VStack {
                            HStack {
                                Text("SP: \(team_ranking(rank: rank).sp)").frame(alignment: .leading).font(.system(size: 12))
                                Spacer()
                            }
                            HStack {
                                Text("TTL: \(team_ranking(rank: rank).total_points)").frame(alignment: .leading).font(.system(size: 12))
                                Spacer()
                            }
                        }.frame(width: 80)*/
                    }
                }
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
        
    }
}

struct EventSkillsRankings_Previews: PreviewProvider {
    static var previews: some View {
        EventSkillsRankings(event: Event(id: 0, fetch: false), teams_map: [String: String]())
    }
}
