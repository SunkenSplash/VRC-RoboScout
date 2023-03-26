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
            Text("#\(team_trueskill.ranking) (\(team_trueskill.ranking_change >= 0 ? "-" : "+")\(abs(team_trueskill.ranking_change)))")
            Spacer()
            Text("\(team_trueskill.number)")
            Spacer()
            Menu("\(displayRoundedTenths(number: team_trueskill.trueskill))") {
                Text("CCWM: \(displayRoundedTenths(number: team_trueskill.ccwm))")
                Text("Total Wins: \(team_trueskill.total_wins)")
                Text("Total Losses: \(team_trueskill.total_losses)")
                Text("Total Ties: \(team_trueskill.total_ties)")
            }
        }
    }
}

class TrueSkillTeams: ObservableObject {
    
    var trueskill_teams: [TrueSkillTeam]
    
    init(begin: Int, end: Int, region: String = "", letter: Character = "0", filter_array: [String] = [], fetch: Bool = false) {
        if fetch {
            API.update_vrc_data_analysis_cache()
        }
        var end = end
        self.trueskill_teams = [TrueSkillTeam]()
        if end == 0 {
            end = API.vrc_data_analysis_cache.count
        }
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
            for i in begin - 1...end - 1 {
                if API.vrc_data_analysis_cache.count == 0 {
                    return
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

struct TrueSkill: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteTeams
    
    @State private var display_trueskill = "World TrueSkill"
    @State private var start = 1
    @State private var end = 200
    @State private var region = ""
    @State private var letter: Character = "0"
    @State private var current_index = 100
    @State private var trueskill_rankings = TrueSkillTeams(begin: 1, end: 200, fetch: false)
    @State private var progress = 0.0
    @State private var total_teams = 0
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    if progress < 1.0 {
                        VStack {
                            Button("Import") {
                                
                                DispatchQueue.global(qos: .userInteractive).async { [self] in
                                    
                                    let components = URLComponents(string: "http://vrc-data-analysis.com/v1/allteams")!
                                    
                                    let request = NSMutableURLRequest(url: components.url! as URL)
                                    request.httpMethod = "GET"
                                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                                    
                                    let json = API.fetch_raw_vrc_data_analysis()
                                    
                                    if json.count == 0 {
                                        print("Failed to update VRC Data Analysis cache")
                                        return
                                    }
                                    
                                    API.vrc_data_analysis_cache = [[String: Any]]()
                                    
                                    var abs_ranking = 0
                                    var prev_count = 0
                                    for team in json {
                                        
                                        if team["ts_ranking"] as? Int ?? 0 == 99999 {
                                            break
                                        }
                                        
                                        let team = team as [String: Any]
                                        
                                        var team_data_dict = [String: Any]()
                                        
                                        team_data_dict = [
                                            "abs_ranking": abs_ranking,
                                            "trueskill_ranking": team["ts_ranking"] as? Int ?? 0,
                                            "trueskill_ranking_change": team["ranking_change"] as? Int ?? 0,
                                            "name": team["team_name"] as? String ?? "",
                                            "id": Int(team["id"] as? Double ?? 0.0),
                                            "number": team["team_number"] as? String ?? "",
                                            "grade": team["grade"] as? String ?? "",
                                            "region": team["event_region"] as? String ?? "",
                                            "country": team["loc_country"] as? String ?? "",
                                            "trueskill": team["trueskill"] as? Double ?? 0.0,
                                            "ccwm": team["ccwm"] as? Double ?? 0.0,
                                            "opr": team["opr"] as? Double ?? 0.0,
                                            "dpr": team["dpr"] as? Double ?? 0.0,
                                            "ap_per_match": team["ap_per_match"] as? Double ?? 0.0,
                                            "awp_per_match": team["awp_per_match"] as? Double ?? 0.0,
                                            "wp_per_match": team["wp_per_match"] as? Double ?? 0.0,
                                            "total_wins": Int(team["total_wins"] as? Double ?? 0.0),
                                            "total_losses": Int(team["total_losses"] as? Double ?? 0.0),
                                            "total_ties": Int(team["total_ties"] as? Double ?? 0.0),
                                            "elimination_wins": Int(team["elimination_wins"] as? Double ?? 0.0),
                                            "elimination_losses": Int(team["elimination_losses"] as? Double ?? 0.0),
                                            "elimination_ties": Int(team["elimination_ties"] as? Double ?? 0.0),
                                            "qualifier_wins": Int(team["qual_wins"] as? Double ?? 0.0),
                                            "qualifier_losses": Int(team["qual_losses"] as? Double ?? 0.0),
                                            "qualifier_ties": Int(team["qual_ties"] as? Double ?? 0.0),
                                            "regionals_qualified": team["qualified_for_regionals"] as? Int == 1,
                                            "worlds_qualified": team["qualified_for_worlds"] as? Int == 1
                                        ]
                                        
                                        API.vrc_data_analysis_cache.append(team_data_dict)
                                        
                                        API.vrc_data_analysis_cache = API.vrc_data_analysis_cache.sorted(by: {
                                            ($0["abs_ranking"] as! Int) < ($1["abs_ranking"] as! Int)
                                        })
                                        
                                        if API.vrc_data_analysis_cache.count > prev_count {
                                            abs_ranking += 1
                                        }
                                        prev_count = API.vrc_data_analysis_cache.count
                                        
                                        DispatchQueue.main.async {
                                            progress = Double(API.vrc_data_analysis_cache.count) / Double(json.count)
                                            total_teams = json.count
                                        }
                                        
                                    }
                                    print("Updated VRC Data Analysis cache")
                                    
                                    progress = 1.0
                                    display_trueskill = "World TrueSkill"
                                    start = 1
                                    end = 200
                                    region = ""
                                    current_index = 100
                                    trueskill_rankings = TrueSkillTeams(begin: 1, end: 200, fetch: false)
                                }
                            }
                            if progress != 0 {
                                ProgressView(value: progress) {
                                    Text("Processed \(API.vrc_data_analysis_cache.count) out of \(Int(total_teams)) teams").font(.system(size: 12, design: .monospaced))
                                }.padding()
                            }
                        }
                    }
                    else {
                        Menu("Filter") {
                            Button("Favorites") {
                                display_trueskill = "Favorites TrueSkill"
                                start = 1
                                end = 200
                                region = ""
                                letter = "0"
                                current_index = 100
                                trueskill_rankings = TrueSkillTeams(begin: 1, end: API.vrc_data_analysis_cache.count, filter_array: favorites.as_array(), fetch: false)
                            }
                            Menu("Region") {
                                Button("World") {
                                    display_trueskill = "World TrueSkill"
                                    start = 1
                                    end = 200
                                    region = ""
                                    letter = "0"
                                    current_index = 100
                                    trueskill_rankings = TrueSkillTeams(begin: 1, end: 200, fetch: false)
                                }
                                ForEach(region_list.sorted(by: <)) { region_str in
                                    Button(region_str) {
                                        display_trueskill = "\(region_str) TrueSkill"
                                        start = 1
                                        end = 200
                                        region = region_str
                                        letter = "0"
                                        current_index = 100
                                        trueskill_rankings = TrueSkillTeams(begin: 1, end: API.vrc_data_analysis_cache.count, region: region_str, fetch: false)
                                    }
                                }
                            }
                            Menu("Letter") {
                                ForEach(["A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"], id: \.self) { char in
                                    Button(char) {
                                        display_trueskill = "\(char) TrueSkill"
                                        start = 1
                                        end = 200
                                        letter = char.first!
                                        current_index = 100
                                        trueskill_rankings = TrueSkillTeams(begin: 1, end: API.vrc_data_analysis_cache.count, letter: char.first!, fetch: false)
                                    }
                                }
                            }
                            Button("Clear Filters") {
                                display_trueskill = "World TrueSkill"
                                start = 1
                                end = 200
                                region = ""
                                current_index = 100
                                trueskill_rankings = TrueSkillTeams(begin: 1, end: 200, fetch: false)
                            }
                        }
                    }
                }.fontWeight(.medium)
                    .font(.system(size: 19))
                    .padding(20)
                ScrollViewReader { proxy in
                    List($trueskill_rankings.trueskill_teams) { team in
                        TrueSkillRow(team_trueskill: team.wrappedValue).id(team.wrappedValue.abs_ranking).onAppear{
                            if region != "" {
                                return
                            }
                            let cache_size = API.vrc_data_analysis_cache.count
                            if Int(team.wrappedValue.abs_ranking) == current_index + 100 {
                                current_index += 50
                                start = start + 50 > cache_size ? cache_size - 50 : start + 50
                                end = end + 50 > cache_size ? cache_size : end + 50
                                Task {
                                    trueskill_rankings = TrueSkillTeams(begin: start, end: end)
                                    proxy.scrollTo(current_index - 25)
                                }
                            }
                            else if Int(team.wrappedValue.abs_ranking) == current_index - 100 + 1 && Int(team.wrappedValue.abs_ranking) != 1 {
                                current_index -= 50
                                start = start - 50 < 1 ? 1 : start - 50
                                end = end - 50 < 1 ? 1 + 50 : end - 50
                                Task {
                                    trueskill_rankings = TrueSkillTeams(begin: start, end: end)
                                    proxy.scrollTo(current_index + 25)
                                }
                            }
                        }
                    }
                }
                .background(.clear)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text($display_trueskill.wrappedValue)
                            .fontWeight(.medium)
                            .font(.system(size: 19))
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(settings.tabColor(), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
    }
}

struct TrueSkill_Previews: PreviewProvider {
    static var previews: some View {
        TrueSkill()
    }
}

