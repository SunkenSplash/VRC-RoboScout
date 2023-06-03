//
//  EventDivisionRankings.swift
//  VRC RoboScout
//
//  Created by William Castro on 4/6/23.
//

import SwiftUI

class EventDivisionRankingsList: ObservableObject {
    @Published var rankings_indexes: [Int]
    
    init(rankings_indexes: [Int] = [Int]()) {
        self.rankings_indexes = rankings_indexes.sorted()
    }
}

struct EventDivisionRankings: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @State var event: Event
    @State var division: Division
    @State var teams_map: [String: String]
    @State var event_rankings_list: EventDivisionRankingsList
    @State var showLoading = true;
    
    init(event: Event, division: Division, teams_map: [String: String]) {
        self.event = event
        self.division = division
        self.teams_map = teams_map
        self.event_rankings_list = EventDivisionRankingsList()
    }
    
    func fetch_rankings() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            event.fetch_rankings(division: division)
            var fetched_rankings_indexes = [Int]()
            var counter = 0
            for _ in (event.rankings[division] ?? [TeamRanking]()) {
                fetched_rankings_indexes.append(counter)
                counter += 1
            }
            DispatchQueue.main.async {
                self.event_rankings_list = EventDivisionRankingsList(rankings_indexes: fetched_rankings_indexes)
                self.showLoading = false
            }
        }
    }
    
    func team_ranking(rank: Int) -> TeamRanking {
        return event.rankings[division]![rank]
    }
    
    var body: some View {
        if showLoading {
            ProgressView().padding()
        }
        List {
            ForEach(event_rankings_list.rankings_indexes.reversed(), id: \.self) { rank in
                VStack {
                    HStack {
                        HStack {
                            Spacer().frame(width: 22)
                            Text(teams_map[String(team_ranking(rank: rank).team.id)] ?? "").font(.system(size: 20)).minimumScaleFactor(0.01).frame(width: 60, alignment: .leading)
                            Text((event.get_team(id: team_ranking(rank: rank).team.id) ?? Team(id: 0, fetch: false)).name).frame(alignment: .leading)
                        }
                        Spacer()
                    }.frame(height: 20, alignment: .leading)
                    HStack {
                        HStack {
                            Spacer().frame(width: 22)
                            VStack(alignment: .leading) {
                                Text("#\(team_ranking(rank: rank).rank)").frame(alignment: .leading).font(.system(size: 16))
                                Text("\(team_ranking(rank: rank).wins)-\(team_ranking(rank: rank).losses)-\(team_ranking(rank: rank).ties)").frame(alignment: .leading).font(.system(size: 16))
                            }.frame(width: 60, alignment: .leading)
                            Spacer()
                        }
                        HStack {
                            VStack(alignment: .leading) {
                                Text("WP: \(team_ranking(rank: rank).wp)").frame(alignment: .leading).font(.system(size: 12))
                                Text("OPR: \(displayRoundedTenths(number: (self.event.team_performance_ratings[team_ranking(rank: rank).team.id] ?? TeamPerformanceRatings(team: team_ranking(rank: rank).team, event: self.event, opr: 0.0, dpr: 0.0, ccwm: 0.0)).opr))").frame(alignment: .leading).font(.system(size: 12))
                                Text("HIGH: \(team_ranking(rank: rank).high_score)").frame(alignment: .leading).font(.system(size: 12))
                            }.frame(width: 90, alignment: .leading)
                            VStack(alignment: .leading) {
                                Text("AP: \(team_ranking(rank: rank).ap)").frame(alignment: .leading).font(.system(size: 12))
                                Text("DPR: \(displayRoundedTenths(number: (self.event.team_performance_ratings[team_ranking(rank: rank).team.id] ?? TeamPerformanceRatings(team: team_ranking(rank: rank).team, event: self.event, opr: 0.0, dpr: 0.0, ccwm: 0.0)).dpr))").frame(alignment: .leading).font(.system(size: 12))
                                Text("AVG: " + displayRounded(number: team_ranking(rank: rank).average_points)).frame(alignment: .leading).font(.system(size: 12))
                            }.frame(width: 90, alignment: .leading)
                            VStack(alignment: .leading) {
                                Text("SP: \(team_ranking(rank: rank).sp)").frame(alignment: .leading).font(.system(size: 12))
                                Text("CCWM: \(displayRoundedTenths(number: (self.event.team_performance_ratings[team_ranking(rank: rank).team.id] ?? TeamPerformanceRatings(team: team_ranking(rank: rank).team, event: self.event, opr: 0.0, dpr: 0.0, ccwm: 0.0)).ccwm))").frame(alignment: .leading).font(.system(size: 12))
                                Text("TTL: \(team_ranking(rank: rank).total_points)").frame(alignment: .leading).font(.system(size: 12))
                            }.frame(width: 90, alignment: .leading)
                        }
                    }
                }
            }
        }.task{
            self.event.calculate_performance_ratings(division: self.division)
            fetch_rankings()
        }.background(.clear)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(division.name) Rankings")
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

struct EventDivisionRankings_Previews: PreviewProvider {
    static var previews: some View {
        EventDivisionRankings(event: Event(id: 0, fetch: false), division: Division(), teams_map: [String: String]())
    }
}
