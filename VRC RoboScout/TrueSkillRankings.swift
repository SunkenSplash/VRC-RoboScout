//
//  TrueSkill.swift
//  VRC RoboScout
//
//  Created by William Castro on 2/27/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct TrueSkillTeam: Identifiable {
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
                Text("#\(team_trueskill.ranking)")
                if team_trueskill.ranking_change != 0 {
                    Text("\(team_trueskill.ranking_change >= 0 ? Image(systemName: "arrow.up") : Image(systemName: "arrow.down"))\(abs(team_trueskill.ranking_change))").font(.system(size: 12)).foregroundColor(team_trueskill.ranking_change >= 0 ? .green : .red)
                }
                Spacer()
            }.frame(width: 100)
            Spacer()
            Text("\(team_trueskill.number)")
            Spacer()
            HStack {
                Spacer()
                Menu("\(displayRoundedTenths(number: team_trueskill.trueskill))") {
                    Text("CCWM: \(displayRoundedTenths(number: team_trueskill.ccwm))")
                    Text("Total Wins: \(team_trueskill.total_wins)")
                    Text("Total Losses: \(team_trueskill.total_losses)")
                    Text("Total Ties: \(team_trueskill.total_ties)")
                }
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
            for team in API.vrc_data_analysis_cache {
                if !filter_array.contains(team["number"] as! String) {
                    continue
                }
                self.trueskill_teams.append(TrueSkillTeam(number: team["number"] as! String, trueskill: team["trueskill"] as! Double, abs_ranking: team["abs_ranking"] as! Int, ranking: team["trueskill_ranking"] as! Int, ranking_change: team["trueskill_ranking_change"] as! Int, ccwm: team["ccwm"] as! Double, total_wins: team["total_wins"] as! Int, total_losses: team["total_losses"] as! Int , total_ties: team["total_ties"] as! Int))
                rank += 1
            }
        }
        // Region
        else if region != "" {
            var rank = 1
            for team in API.vrc_data_analysis_cache {
                if region != "" && region != (team["region"] as! String) {
                    continue
                }
                self.trueskill_teams.append(TrueSkillTeam(number: team["number"] as! String, trueskill: team["trueskill"] as! Double, abs_ranking: team["abs_ranking"] as! Int, ranking: team["trueskill_ranking"] as! Int, ranking_change: team["trueskill_ranking_change"] as! Int, ccwm: team["ccwm"] as! Double, total_wins: team["total_wins"] as! Int, total_losses: team["total_losses"] as! Int , total_ties: team["total_ties"] as! Int))
                rank += 1
            }
        }
        // Letter
        else if letter != "0" {
            var rank = 1
            for team in API.vrc_data_analysis_cache {
                if letter != (team["number"] as! String).last {
                    continue
                }
                self.trueskill_teams.append(TrueSkillTeam(number: team["number"] as! String, trueskill: team["trueskill"] as! Double, abs_ranking: team["abs_ranking"] as! Int, ranking: team["trueskill_ranking"] as! Int, ranking_change: team["trueskill_ranking_change"] as! Int, ccwm: team["ccwm"] as! Double, total_wins: team["total_wins"] as! Int, total_losses: team["total_losses"] as! Int , total_ties: team["total_ties"] as! Int))
                rank += 1
            }
        }
        // World
        else {
            for var i in 0..<API.vrc_data_analysis_cache.count {
                if API.vrc_data_analysis_cache.count == 0 || API.vrc_data_analysis_cache.count == i {
                    return
                }
                if i == API.vrc_data_analysis_cache.count {
                    i -= 1
                    continue
                }
                let team = API.vrc_data_analysis_cache[i]
                self.trueskill_teams.append(TrueSkillTeam(number: team["number"] as! String, trueskill: team["trueskill"] as! Double, abs_ranking: team["abs_ranking"] as! Int, ranking: team["trueskill_ranking"] as! Int, ranking_change: team["trueskill_ranking_change"] as! Int, ccwm: team["ccwm"] as! Double, total_wins: team["total_wins"] as! Int, total_losses: team["total_losses"] as! Int , total_ties: team["total_ties"] as! Int))
            }
        }
    }
}

var region_list: [String] = [
    "South Dakota",
    "Pennsylvania - East",
    "Virginia",
    "Kansas",
    "New York - South",
    "Hawaii",
    "District of Columbia",
    "China",
    "Michigan",
    "Taiwan",
    "Alabama",
    "California - Region 4",
    "Tennessee",
    "Texas - Region 3",
    "Washington",
    "Kentucky",
    "Georgia",
    "Arizona",
    "Texas - Region 2",
    "Louisiana",
    "Colorado",
    "California - Region 2",
    "Minnesota",
    "Southern New England",
    "Maryland",
    "Australia",
    "South Carolina",
    "Ontario",
    "Wisconsin",
    "Mississippi",
    "Japan",
    "Ohio",
    "Florida - North/Central",
    "Oregon",
    "Quebec",
    "Texas - Region 4",
    "North Carolina",
    "New Jersey",
    "Montana",
    "Nebraska",
    "Utah",
    "Alberta/Saskatchewan",
    "British Columbia (BC)",
    "Indiana",
    "Florida - South",
    "Singapore"
]

struct TrueSkillRankings: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @State private var display_trueskill = "World TrueSkill"
    @State private var region = ""
    @State private var letter: Character = "0"
    @State private var trueskill_rankings = TrueSkillTeams(fetch: false)
        
    var body: some View {
        VStack {
            if API.vrc_data_analysis_cache.isEmpty {
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
                        ForEach(region_list.sorted(by: <)) { region_str in
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
                ScrollViewReader { proxy in
                    List($trueskill_rankings.trueskill_teams) { team in
                        TrueSkillRow(team_trueskill: team.wrappedValue).id(team.wrappedValue.abs_ranking)
                    }
                }
            }
        }.onAppear{
            navigation_bar_manager.title = $display_trueskill.wrappedValue
        }
    }
}

struct TrueSkillRankings_Previews: PreviewProvider {
    static var previews: some View {
        TrueSkillRankings()
    }
}

