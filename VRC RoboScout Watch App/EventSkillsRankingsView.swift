//
//  EventSkillsRankingsView.swift
//  VRC RoboScout
//
//  Created by William Castro on 5/19/25.
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
    @State var expandedTeamRanking = TeamSkillsRanking()
    
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
                List($event_skills_rankings_list.rankings_indexes, id: \.self) { rank in
                    let team_ranking = team_ranking(rank: rank.wrappedValue)
                    HStack(alignment: .center) {
                        VStack {
                            Text("#\(team_ranking.rank)").frame(maxWidth: .infinity, alignment: .leading)
                        }.frame(width: 50)
                        Spacer()
                        Text("\(event.get_team(id: team_ranking.team.id)?.number ?? "")").font(.system(size: 15)).frame(width: 60, alignment: .center)
                        Spacer()
                        VStack {
                            Text("\(team_ranking.combined_score)")
                            HStack {
                                Text(String(describing: team_ranking.programming_score)).font(.system(size: 10))
                                Text(String(describing: team_ranking.driver_score)).font(.system(size: 10))
                            }
                        }.frame(width: 50)
                    }.onTapGesture {
                        expandedTeamRanking = team_ranking
                    }
                }.fullScreenCover(isPresented: Binding<Bool>( // I wish we didn't need to do this
                    get: {
                        expandedTeamRanking.team.id != 0
                    }, set: { expanded in
                        if !expanded {
                            expandedTeamRanking = TeamSkillsRanking()
                        }
                    })) {
                    List {
                        Text("\(expandedTeamRanking.combined_score) Combined")
                        Text("\(expandedTeamRanking.programming_score) Prog")
                        Text("\(expandedTeamRanking.driver_score) Driver")
                        Text("\(expandedTeamRanking.programming_attempts) Prog Attempts")
                        Text("\(expandedTeamRanking.driver_attempts) Driver Attempts")
                    }
                }
            }
        }.task{
            fetch_rankings()
        }
            .navigationTitle("Skills Rankings")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct EventSkillsRankings_Previews: PreviewProvider {
    static var previews: some View {
        EventSkillsRankings(event: Event(), teams_map: [String: String]())
    }
}
