//
//  TrueSkill.swift
//  VRC RoboScout
//
//  Created by William Castro on 2/27/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct TrueSkillTeam: Identifiable, Hashable {
    let id = UUID()
    let number: String
    let trueskill: Double
    let abs_ranking: Int
    let ranking: Int
    let ranking_change: Int
    let ccwm: Double
    let total_wins: Int
    let total_losses: Int
    let total_ties: Int
}

struct TrueSkillRow: View {
    var team_trueskill: TrueSkillTeam

    var body: some View {
        HStack {
            HStack {
                Text("#\(team_trueskill.ranking)").font(.system(size: 18))
                if team_trueskill.ranking_change != 0 {
                    Text("\(team_trueskill.ranking_change >= 0 ? Image(systemName: "arrow.up") : Image(systemName: "arrow.down"))\(abs(team_trueskill.ranking_change))").font(.system(size: 12)).foregroundColor(team_trueskill.ranking_change >= 0 ? .green : .red)
                }
                Spacer()
            }.frame(width: 100)
            Spacer()
            Text("\(team_trueskill.number)").font(.system(size: 18))
            Spacer()
            HStack {
                Spacer()
                Menu("\(displayRoundedTenths(number: team_trueskill.trueskill))") {
                    Text("CCWM: \(displayRoundedTenths(number: team_trueskill.ccwm))")
                    Text("Total Wins: \(team_trueskill.total_wins)")
                    Text("Total Losses: \(team_trueskill.total_losses)")
                    Text("Total Ties: \(team_trueskill.total_ties)")
                }.font(.system(size: 18))
            }.frame(width: 100)
        }
    }
}

class TrueSkillTeams: ObservableObject {
    
    var trueskill_teams: [TrueSkillTeam]
    
    init(region: String = "", letter: Character = "0", filter_array: [String] = [], fetch: Bool = false) {
        if fetch {
            API.update_vrc_data_analysis_cache()
        }
        self.trueskill_teams = [TrueSkillTeam]()
        // Favorites
        if filter_array.count != 0 {
            var rank = 1
            for team in API.vrc_data_analysis_cache.teams {
                if !filter_array.contains(team.team_number) {
                    continue
                }
                self.trueskill_teams.append(TrueSkillTeam(number: team.team_number, trueskill: team.trueskill, abs_ranking: rank, ranking: team.ts_ranking, ranking_change: team.ranking_change, ccwm: team.ccwm, total_wins: team.total_wins, total_losses: team.total_losses, total_ties: team.total_ties))
                rank += 1
            }
        }
        // Region
        else if region != "" {
            var rank = 1
            for team in API.vrc_data_analysis_cache.teams {
                if region != "" && region != team.loc_region {
                    continue
                }
                self.trueskill_teams.append(TrueSkillTeam(number: team.team_number, trueskill: team.trueskill, abs_ranking: rank, ranking: team.ts_ranking, ranking_change: team.ranking_change, ccwm: team.ccwm, total_wins: team.total_wins, total_losses: team.total_losses, total_ties: team.total_ties))
                rank += 1
            }
        }
        // Letter
        else if letter != "0" {
            var rank = 1
            for team in API.vrc_data_analysis_cache.teams {
                if letter != team.team_number.last {
                    continue
                }
                self.trueskill_teams.append(TrueSkillTeam(number: team.team_number, trueskill: team.trueskill, abs_ranking: rank, ranking: team.ts_ranking, ranking_change: team.ranking_change, ccwm: team.ccwm, total_wins: team.total_wins, total_losses: team.total_losses, total_ties: team.total_ties))
                rank += 1
            }
        }
        // World
        else {
            if API.vrc_data_analysis_cache.teams.count == 0 {
                return
            }
            for i in 0..<API.vrc_data_analysis_cache.teams.count {
                let team = API.vrc_data_analysis_cache.teams[i]
                self.trueskill_teams.append(TrueSkillTeam(number: team.team_number, trueskill: team.trueskill, abs_ranking: i + 1, ranking: team.ts_ranking, ranking_change: team.ranking_change, ccwm: team.ccwm, total_wins: team.total_wins, total_losses: team.total_losses, total_ties: team.total_ties))
            }
        }
    }
}

struct TrueSkillRankings: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @State private var display_trueskill = "World TrueSkill"
    @State private var region = ""
    @State private var letter: Character = "0"
    @State private var trueskill_rankings = TrueSkillTeams(fetch: false)
    @State private var show_leaderboard = false
    @State private var importing = true
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        
    var body: some View {
        VStack {
            if importing && API.vrc_data_analysis_cache.teams.isEmpty {
                ImportingData()
                    .onReceive(timer) { _ in
                        if API.imported_trueskill {
                            trueskill_rankings = TrueSkillTeams(fetch: false)
                            importing = false
                        }
                    }
            }
            else if !importing && API.vrc_data_analysis_cache.teams.isEmpty {
                NoData()
            }
            else {
                Menu("Filter") {
                    Button("Favorites") {
                        display_trueskill = "Favorites TrueSkill"
                        navigation_bar_manager.title = display_trueskill
                        region = ""
                        letter = "0"
                        trueskill_rankings = TrueSkillTeams(filter_array: favorites.teams_as_array(), fetch: false)
                    }
                    Menu("Region") {
                        Button("World") {
                            display_trueskill = "World TrueSkill"
                            navigation_bar_manager.title = display_trueskill
                            region = ""
                            letter = "0"
                            trueskill_rankings = TrueSkillTeams(fetch: false)
                        }
                        ForEach(API.vrc_data_analysis_regions_map.sorted(by: <)) { region_str in
                            Button(region_str) {
                                display_trueskill = "\(region_str) TrueSkill"
                                navigation_bar_manager.title = display_trueskill
                                region = region_str
                                letter = "0"
                                trueskill_rankings = TrueSkillTeams(region: region_str, fetch: false)
                            }
                        }
                    }
                    Menu("Letter") {
                        ForEach(["A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"], id: \.self) { char in
                            Button(char) {
                                display_trueskill = "\(char) TrueSkill"
                                navigation_bar_manager.title = display_trueskill
                                letter = char.first!
                                trueskill_rankings = TrueSkillTeams(letter: char.first!, fetch: false)
                            }
                        }
                    }
                    Button("Clear Filters") {
                        display_trueskill = "World TrueSkill"
                        navigation_bar_manager.title = display_trueskill
                        region = ""
                        trueskill_rankings = TrueSkillTeams(fetch: false)
                    }
                }.fontWeight(.medium)
                    .font(.system(size: 19))
                    .padding(20)
                if (show_leaderboard) {
                    List($trueskill_rankings.trueskill_teams) { team in
                        TrueSkillRow(team_trueskill: team.wrappedValue).id(team.wrappedValue.abs_ranking)
                    }
                }
            }
        }.onAppear{
            self.show_leaderboard = true
            navigation_bar_manager.title = $display_trueskill.wrappedValue
            if self.trueskill_rankings.trueskill_teams.isEmpty {
                display_trueskill = "World TrueSkill"
                navigation_bar_manager.title = display_trueskill
                region = ""
                trueskill_rankings = TrueSkillTeams(fetch: false)
            }
        }
        .onDisappear{
            self.show_leaderboard = false
        }
    }
}

struct TrueSkillRankings_Previews: PreviewProvider {
    static var previews: some View {
        TrueSkillRankings()
    }
}

