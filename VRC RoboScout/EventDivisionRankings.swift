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
    
    func sort_by(option: Int, event: Event, division: Division) {
        var sorted = [Int]()
        
        // Create an array of team performance ratings from the event.team_performance_ratings[division] dictionary
        let team_performance_ratings = Array(event.team_performance_ratings[division]!.values)
        
        let team_rankings = event.rankings[division] ?? [TeamRanking]()
        
        // By rank
        if option == 0 {
            // Create the indexes of the rankings in order
            for i in 0..<event.rankings[division]!.count {
                sorted.append(i)
            }
        }
        // By OPR
        else if option == 1 {
            // Sort the team performance ratings for the given division by OPR
            // The larger the OPR, the better the ranking
            let option_order = team_performance_ratings.sorted(by: { $0.opr < $1.opr })
            // Get the indexes of the sorted team performance ratings
            for team_performance_rating in option_order {
                sorted.append(event.rankings[division]!.firstIndex(where: { $0.team.id == team_performance_rating.team.id })!)
            }
        }
        // By DPR
        else if option == 2 {
            // Sort the team performance ratings for the given division by DPR
            // The smaller the DPR, the better the ranking
            let option_order = team_performance_ratings.sorted(by: { $0.dpr > $1.dpr })
            // Get the indexes of the sorted team performance ratings
            for team_performance_rating in option_order {
                sorted.append(event.rankings[division]!.firstIndex(where: { $0.team.id == team_performance_rating.team.id })!)
            }
        }
        // By CCWM
        else if option == 3 {
            // Sort the team performance ratings for the given division by CCWM
            // The larger the CCWM, the better the ranking
            let option_order = team_performance_ratings.sorted(by: { $0.ccwm < $1.ccwm })
            // Get the indexes of the sorted team performance ratings
            for team_performance_rating in option_order {
                sorted.append(event.rankings[division]!.firstIndex(where: { $0.team.id == team_performance_rating.team.id })!)
            }
        }
        // By AP
        else if option == 4 {
            // Sort the team rankings for the given division by AP
            // The larger the AP, the better the ranking
            let option_order = team_rankings.sorted(by: { $0.ap < $1.ap })
            // Get the indexes of the sorted team rankings
            for team_ranking in option_order {
                sorted.append(event.rankings[division]!.firstIndex(where: { $0.team.id == team_ranking.team.id })!)
            }
        }
        // By SP
        else if option == 5 {
            // Sort the team rankings for the given division by SP
            // The larger the SP, the better the ranking
            let option_order = team_rankings.sorted(by: { $0.sp < $1.sp })
            // Get the indexes of the sorted team rankings
            for team_ranking in option_order {
                sorted.append(event.rankings[division]!.firstIndex(where: { $0.team.id == team_ranking.team.id })!)
            }
        }
        // By high score
        else if option == 6 {
            // Sort the team rankings for the given division by high score
            // The larger the high score, the better the ranking
            let option_order = team_rankings.sorted(by: { $0.high_score < $1.high_score })
            // Get the indexes of the sorted team rankings
            for team_ranking in option_order {
                sorted.append(event.rankings[division]!.firstIndex(where: { $0.team.id == team_ranking.team.id })!)
            }
        }
        self.rankings_indexes = sorted
    }
}

struct EventDivisionRankings: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: RoboScoutDataController
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @State var event: Event
    @State var division: Division
    @State var teams_map: [String: String]
    @State var event_rankings_list: EventDivisionRankingsList
    @State var showLoading = true
    @State var showingSheet = false
    @State var sortingOption = 0
    @State var teamNumberQuery = ""
    
    var searchResults: [Int] {
        if teamNumberQuery.isEmpty {
            return event_rankings_list.rankings_indexes.reversed()
        }
        else {
            return event_rankings_list.rankings_indexes.reversed().filter{ (teams_map[String(team_ranking(rank: $0).team.id)] ?? "").lowercased().contains(teamNumberQuery.lowercased()) }
        }
    }
    
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
        VStack {
            if showLoading {
                ProgressView().padding()
                Spacer()
            }
            else if (event.rankings[division] ?? [TeamRanking]()).isEmpty {
                NoData()
            }
            else {
                Picker("Sort", selection: $sortingOption) {
                    Text("Rank").tag(0)
                    Text("AP").tag(4)
                    Text("SP").tag(5)
                    Text("OPR").tag(1)
                    Text("DPR").tag(2)
                    Text("CCWM").tag(3)
                }.pickerStyle(.segmented).padding([.top, .leading, .trailing], 10)
                    .onChange(of: sortingOption) { option in
                        self.event_rankings_list.sort_by(option: option, event: self.event, division: self.division)
                        self.showLoading = true
                        self.showLoading = false
                    }.onShake{
                        self.sortingOption = 6
                        self.event_rankings_list.sort_by(option: self.sortingOption, event: self.event, division: self.division)
                        self.showLoading = true
                        self.showLoading = false
                        let sel = UISelectionFeedbackGenerator()
                        sel.selectionChanged()
                    }
                NavigationView {
                    List {
                        ForEach(searchResults, id: \.self) { rank in
                            NavigationLink(destination: EventTeamMatches(teams_map: $teams_map, event: self.event, team: Team(id: team_ranking(rank: rank).team.id, fetch: false), division: self.division).environmentObject(settings).environmentObject(dataController)) {
                                VStack {
                                    HStack {
                                        Text(teams_map[String(team_ranking(rank: rank).team.id)] ?? "").font(.system(size: 20)).minimumScaleFactor(0.01).frame(width: 70, alignment: .leading).bold()
                                        Text((event.get_team(id: team_ranking(rank: rank).team.id) ?? Team()).name).frame(alignment: .leading)
                                        Spacer()
                                        if favorites.favorite_teams.contains(teams_map[String(team_ranking(rank: rank).team.id)] ?? "") {
                                            Image(systemName: "star.fill")
                                        }
                                    }.frame(maxWidth: .infinity, alignment: .leading).frame(height: 20)
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("# \(team_ranking(rank: rank).rank)").frame(alignment: .leading).font(.system(size: 16))
                                            Text("\(team_ranking(rank: rank).wins)-\(team_ranking(rank: rank).losses)-\(team_ranking(rank: rank).ties)").frame(alignment: .leading).font(.system(size: 16))
                                        }.frame(alignment: .leading)
                                        Spacer()
                                        VStack(alignment: .leading) {
                                            Text("WP: \(team_ranking(rank: rank).wp)").frame(alignment: .leading).font(.system(size: 12)).foregroundColor(.secondary)
                                            Text("OPR: \(displayRoundedTenths(number: (self.event.team_performance_ratings[division]![team_ranking(rank: rank).team.id] ?? TeamPerformanceRatings(team: team_ranking(rank: rank).team, event: self.event, opr: 0.0, dpr: 0.0, ccwm: 0.0)).opr))").frame(alignment: .leading).font(.system(size: 12)).foregroundColor(.secondary)
                                            Text("HIGH: \(team_ranking(rank: rank).high_score)").frame(alignment: .leading).font(.system(size: 12)).foregroundColor(.secondary)
                                        }.frame(alignment: .leading)
                                        Spacer()
                                        VStack(alignment: .leading) {
                                            Text("AP: \(team_ranking(rank: rank).ap)").frame(alignment: .leading).font(.system(size: 12)).foregroundColor(.secondary)
                                            Text("DPR: \(displayRoundedTenths(number: (self.event.team_performance_ratings[division]![team_ranking(rank: rank).team.id] ?? TeamPerformanceRatings(team: team_ranking(rank: rank).team, event: self.event, opr: 0.0, dpr: 0.0, ccwm: 0.0)).dpr))").frame(alignment: .leading).font(.system(size: 12)).foregroundColor(.secondary)
                                            Text("AVG: " + displayRounded(number: team_ranking(rank: rank).average_points)).frame(alignment: .leading).font(.system(size: 12)).foregroundColor(.secondary)
                                        }.frame(alignment: .leading)
                                        Spacer()
                                        VStack(alignment: .leading) {
                                            Text("SP: \(team_ranking(rank: rank).sp)").frame(alignment: .leading).font(.system(size: 12)).foregroundColor(.secondary)
                                            Text("CCWM: \(displayRoundedTenths(number: (self.event.team_performance_ratings[division]![team_ranking(rank: rank).team.id] ?? TeamPerformanceRatings(team: team_ranking(rank: rank).team, event: self.event, opr: 0.0, dpr: 0.0, ccwm: 0.0)).ccwm))").frame(alignment: .leading).font(.system(size: 12)).foregroundColor(.secondary)
                                            Text("TTL: \(team_ranking(rank: rank).total_points)").frame(alignment: .leading).font(.system(size: 12)).foregroundColor(.secondary)
                                        }.frame(alignment: .leading)
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
            do {
                try self.event.calculate_team_performance_ratings(division: self.division)
            }
            catch {}
            fetch_rankings()
        }.onAppear{
            navigation_bar_manager.title = "\(division.name) Rankings"
        }
    }
}

struct EventDivisionRankings_Previews: PreviewProvider {
    static var previews: some View {
        EventDivisionRankings(event: Event(), division: Division(), teams_map: [String: String]())
    }
}
