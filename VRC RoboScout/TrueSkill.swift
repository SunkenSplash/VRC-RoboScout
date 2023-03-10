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
    
    init(begin: Int, end: Int, region: String = "", filter_array: [String] = [], fetch: Bool = false) {
        if API.vrc_data_analysis_cache.count == 0 {
            self.trueskill_teams = [TrueSkillTeam]()
            return
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
                if !filter_array.contains(team.team.number) {
                    continue
                }
                self.trueskill_teams.append(TrueSkillTeam(number: team.team.number, trueskill: team.trueskill, abs_ranking: team.abs_ranking, ranking: team.tsranking, ranking_change: team.tsranking_change, ccwm: team.ccwm, total_wins: team.total_wins, total_losses: team.total_losses, total_ties: team.total_ties))
                rank += 1
            }
        }
        // Region
        else if region != "" {
            var rank = 1
            for team in API.vrc_data_analysis_cache {
                if region != "" && region != team.region {
                    continue
                }
                self.trueskill_teams.append(TrueSkillTeam(number: team.team.number, trueskill: team.trueskill, abs_ranking: team.abs_ranking, ranking: team.tsranking, ranking_change: team.tsranking_change, ccwm: team.ccwm, total_wins: team.total_wins, total_losses: team.total_losses, total_ties: team.total_ties))
                rank += 1
            }
        }
        // World
        else {
            for i in begin - 1...end - 1 {
                let team = API.vrc_data_analysis_cache[i]
                self.trueskill_teams.append(TrueSkillTeam(number: team.team.number, trueskill: team.trueskill, abs_ranking: team.abs_ranking, ranking: team.tsranking, ranking_change: team.tsranking_change, ccwm: team.ccwm, total_wins: team.total_wins, total_losses: team.total_losses, total_ties: team.total_ties))
            }
        }
    }
}

var region_list: [String] = [
    "Louisiana",
    "Texas",
    "California",
    "Florida",
    "Nebraska",
    "Ohio",
    "West Virginia",
    "Minnesota",
    "Virginia",
    "New Mexico",
    "British Columbia",
    "Massachusetts",
    "Wyoming",
    "South Carolina",
    "Alabama",
    "Maryland",
    "Michigan",
    "Illinois",
    "New Hampshire",
    "Chihuahua",
    "Idaho",
    "Arkansas",
    "Alberta",
    "Indiana",
    "Missouri",
    "New York",
    "Nevada",
    "Rhode Island",
    "Kansas",
    "Shanghai",
    "New Zealand",
    "Singapore",
    "Kentucky",
    "Tennessee",
    "Oregon",
    "Jiangsu",
    "Ireland",
    "Hainan",
    "Pennsylvania",
    "Georgia",
    "Ontario",
    "Washington",
    "New Jersey",
    "Wisconsin",
    "Guangdong",
    "Mississippi",
    "Colorado",
    "Puerto Rico",
    "Taiwan",
    "Connecticut",
    "Iowa",
    "Maine",
    "Arizona",
    "Delaware",
    "United Kingdom",
    "South Korea",
    "North Carolina",
    "United Arab Emirates",
    "Beijing",
    "Australia",
    "Oklahoma",
    "Mexico City",
    "Azerbaijan",
    "Utah",
    "Liaoning",
    "Michoacán",
    "Quebec",
    "Fujian",
    "Sichuan",
    "Hawaii",
    "Rheinland-Pfalz",
    "Jalisco",
    "South Dakota",
    "Türkiye",
    "Zhejiang",
    "Finland",
    "Waadt",
    "Philippines",
    "Jilin",
    "Kazakhstan",
    "Chiapas",
    "Vermont",
    "Vietnam",
    "District of Columbia",
    "Hong Kong",
    "Shaanxi",
    "Barcelona",
    "Basel-Landschaft",
    "Macau",
    "Thailand",
    "Andorra",
    "Henan",
    "Niedersachsen",
    "Japan",
    "Tianjin",
    "North Dakota",
    "American Samoa",
    "Chongqing",
    "Baden-Württemberg",
    "Tessin",
    "Shanxi",
    "Panama",
    "Tamaulipas",
    "Montana",
    "Colombia",
    "Durango",
    "Girona",
    "Hubei",
    "Anhui",
    "Qinghai",
    "Guizhou",
    "Nuevo León",
    "Hamburg",
    "Brazil",
    "Brandenburg",
    "Berlin",
    "Castellon"
]

struct TrueSkill: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteTeams
    
    @State private var showLoading = false
    @State private var showImporter = false
    @State private var display_trueskill = "World TrueSkill"
    @State private var start = 1
    @State private var end = 200
    @State private var region = ""
    @State private var current_index = 100
    @State private var trueskill_rankings = TrueSkillTeams(begin: 1, end: 200, fetch: false)
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Spacer()
                    Button("Import") {
                        showImporter = true
                        showLoading = true
                    }.fileImporter(
                        isPresented: $showImporter,
                        allowedContentTypes: [UTType("org.openxmlformats.spreadsheetml.sheet")!],
                        allowsMultipleSelection: false,
                        onCompletion: { result in
                            if let urls = try? result.get() {
                                do {
                                    let url = urls[0]
                                    guard url.startAccessingSecurityScopedResource() else { return }
                                    
                                    Task {
                                        API.update_vrc_data_analysis_cache(data: try Data(contentsOf: url))
                                        url.stopAccessingSecurityScopedResource()
                                        showLoading = false
                                        display_trueskill = "World TrueSkill"
                                        start = 1
                                        end = 200
                                        region = ""
                                        current_index = 100
                                        trueskill_rankings = TrueSkillTeams(begin: 1, end: 200, fetch: false)
                                    }
                                }
                                catch {
                                    print("Invalid file at url \(urls[0])")
                                }
                            }
                        }
                    )
                    Spacer()
                    Menu("Filter") {
                        Menu("Region") {
                            Button("World") {
                                display_trueskill = "World TrueSkill"
                                start = 1
                                end = 200
                                region = ""
                                current_index = 100
                                trueskill_rankings = TrueSkillTeams(begin: 1, end: 200, fetch: false)
                            }
                            ForEach(region_list.sorted(by: <)) { region_str in
                                Button(region_str) {
                                    display_trueskill = "\(region_str) TrueSkill"
                                    start = 1
                                    end = 200
                                    region = region_str
                                    current_index = 100
                                    trueskill_rankings = TrueSkillTeams(begin: 1, end: API.vrc_data_analysis_cache.count, region: region_str, fetch: false)
                                }
                            }
                        }
                        Button("Favorites") {
                            display_trueskill = "Favorites TrueSkill"
                            start = 1
                            end = 200
                            region = ""
                            current_index = 100
                            trueskill_rankings = TrueSkillTeams(begin: 1, end: API.vrc_data_analysis_cache.count, filter_array: favorites.as_array(), fetch: false)
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
                    Spacer()
                }.fontWeight(.medium)
                    .font(.system(size: 19))
                    .padding(20)
                if showLoading {
                    ProgressView()
                }
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

