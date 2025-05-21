//
//  TeamLookup.swift
//  VRC RoboScout
//
//  Created by William Castro on 2/20/23.
//

import SwiftUI
import OrderedCollections
import CoreML

struct TeamInfo: Identifiable {
    let id = UUID()
    let property: String
    let value: String
}

struct TeamInfoRow: View {
    var team_info: TeamInfo
    
    var body: some View {
        HStack{
            Text(team_info.property)
            Spacer()
            Text(team_info.value)
        }
    }
}

struct TeamLookupView: View {
    
    @EnvironmentObject var wcSession: WatchSession
    
    @EnvironmentObject var settings: UserSettings
    
    @State var team_number: String
    @State var fetch: Bool
    @State var fetched: Bool = false
    @State private var team: Team = Team()
    @State private var vrc_data_analysis = VRCDataAnalysis()
    @State private var world_skills = WorldSkills()
    @State private var avg_rank: Double = 0.0
    @State private var award_counts = OrderedDictionary<String, Int>()
    @State private var showLoading: Bool = false
    @State private var showingSheet = false
    
    init(team_number: String = "", fetch: Bool = false) {
        self._team_number = State(initialValue: team_number)
        self._fetch = State(initialValue: fetch)
    }
    
    let adam_score_map = [
        "Low",
        "Low Mid",
        "Mid",
        "High Mid",
        "High",
        "Very High"
    ]
    
    func adam_score() -> String {
        guard let model = try? AdamScore_500(configuration: MLModelConfiguration()) else {
            print("Error loading AdamScore model")
            return "Error"
        }
        guard let score = try? model.prediction(world_skills_ranking: Double(world_skills.ranking), trueskill_ranking: Double(vrc_data_analysis.ts_ranking), average_qualification_ranking: avg_rank, winrate: Double(vrc_data_analysis.total_wins) / Double(vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties)) else {
            print("Runtime error with AdamScore model")
            return "Error"
        }
        return adam_score_map[Int(score.adamscore)]
    }
    
    func fetch_info(number: String) {
        
        showLoading = true
        team_number = number.uppercased()
        
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            let fetched_team = Team(number: number)
            
            if fetched_team.id == 0 {
                DispatchQueue.main.async {
                    showLoading = false
                }
                return
            }
            
            let fetced_vrc_data_analysis = API.vrc_data_analysis_for(team: fetched_team, fetch_re_match_statistics: true)
            let fetched_world_skills = API.world_skills_for(team: fetched_team) ?? WorldSkills(team: team, data: [String: Any]())
            let fetched_avg_rank = fetched_team.average_ranking()
            fetched_team.fetch_awards()
            
            fetched_team.awards.sort(by: {
                $0.order < $1.order
            })
            
            var fetched_award_counts = OrderedDictionary<String, Int>()
            for award in fetched_team.awards {
                fetched_award_counts[award.title] = (fetched_award_counts[award.title] ?? 0) + 1
            }
            
            DispatchQueue.main.async {
                team = fetched_team
                vrc_data_analysis = fetced_vrc_data_analysis
                world_skills = fetched_world_skills
                avg_rank = fetched_avg_rank
                award_counts = fetched_award_counts
                
                showLoading = false
                fetched = true
            }
        }
    }
    
    var body: some View {
        List {
            HStack {
                Spacer().frame(width: 10, height: 10)
                Text($team_number.wrappedValue).frame(maxWidth: .infinity, alignment: .center).multilineTextAlignment(.center).font(.system(size: 36)).onAppear{
                    if fetch {
                        fetch_info(number: team_number)
                        fetch = false
                    }
                }
                VStack {
                    if showLoading {
                        ProgressView()
                    }
                }.frame(width: 10, height: 10)
            }.padding(EdgeInsets(top: -20, leading: 10, bottom: -20, trailing: 10)).listRowBackground(Color.clear)
            HStack {
                Text("Name")
                Spacer()
                Text(team.name)
            }
            HStack {
                Text("Robot")
                Spacer()
                Text(team.robot_name)
            }
            HStack {
                Text("Org")
                Spacer()
                Text(team.organization)
            }
            HStack {
                Image(systemName: "mappin")
                Text(fetched ? "\(team.city), \(team.region)" : "")
            }.frame(maxWidth: .infinity, alignment: .center)
            HStack {
                ExpandableView("TrueSkill") {
                    List {
                        Text(fetched && $vrc_data_analysis.wrappedValue.ts_ranking != 0 ? "\(displayRoundedTenths(number: vrc_data_analysis.trueskill)) TrueSkill" : "No TrueSkill data")
                        Text((vrc_data_analysis.ranking_change >= 0 ? "Up " : "Down ") + "\(abs(vrc_data_analysis.ranking_change))" + " places since last update")
                    }
                }
                Spacer()
                Text(fetched && $vrc_data_analysis.wrappedValue.ts_ranking != 0 ? "# \(vrc_data_analysis.ts_ranking) of \(API.vrc_data_analysis_cache.teams.count)" : "")
            }.foregroundColor(.red)
            VStack {
                HStack {
                    Text("Skills")
                    Spacer()
                    Text(fetched && world_skills.ranking != 0 ? "# \(world_skills.ranking) of \(API.world_skills_cache.teams.count)" : "")
                }
                Divider()
                HStack {
                    ExpandableView("Highest Score") {
                        List {
                            Text("\(world_skills.driver) Driver")
                            Text("\(world_skills.programming) Programming")
                            Text("\(world_skills.highest_driver) Highest Driver")
                            Text("\(world_skills.highest_programming) Highest Programming")
                        }
                    }
                    Spacer()
                    Text(fetched && world_skills.ranking != 0 ? "\(world_skills.combined)" : "")
                }
            }.foregroundColor(.red)
            HStack {
                ExpandableView("Matches") {
                    List {
                        Text("Average Qualifiers Ranking: \(displayRoundedTenths(number: avg_rank))")
                        Text("CCWM: \(displayRoundedTenths(number: vrc_data_analysis.ccwm ?? 0))")
                        Text("Winrate: " + ((vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties > 0) ? ((displayRoundedTenths(number: Double(vrc_data_analysis.total_wins) / Double(vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties) * 100.0)) + "%") : ""))
                        Text("Total Matches: \(vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties)")
                        Text("Total Wins: \(vrc_data_analysis.total_wins)")
                        Text("Total Losses: \(vrc_data_analysis.total_losses)")
                        Text("Total Ties: \(vrc_data_analysis.total_ties)")
                    }
                }
                Spacer()
                Text(fetched ? "\(vrc_data_analysis.total_wins)-\(vrc_data_analysis.total_losses)-\(vrc_data_analysis.total_ties)" : "")
            }.foregroundColor(.red)
            HStack {
                ExpandableView("Awards") {
                    List(0..<award_counts.count, id: \.self) { index in
                        Text("\(Array(award_counts.values)[index])x \(Array(award_counts.keys)[index])")
                    }
                }
                Spacer()
                Text(fetched && team.registered ? "\(self.team.awards.count)" : "")
            }.foregroundColor(.red)
            HStack {
                Text("Quals")
                Spacer()
                Text("\(vrc_data_analysis.qualified_for_worlds == 1 ? "Worlds" : "")\(vrc_data_analysis.qualified_for_worlds == 1 && vrc_data_analysis.qualified_for_regionals == 1 ? ", " : "")\(vrc_data_analysis.qualified_for_regionals == 1 ? "Regionals" : "")\(fetched && vrc_data_analysis.qualified_for_worlds == 0 && vrc_data_analysis.qualified_for_regionals == 0 ? "None" : "")")
            }
            if UserSettings.getAdamScore() {
                HStack {
                    Text("AdamScore™")
                    Spacer()
                    Text(fetched && $vrc_data_analysis.wrappedValue.trueskill != 0.0 && world_skills.ranking != 0 ? adam_score() : "")
                }
            }
        }.navigationTitle("Team Lookup")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct TeamLookupView_Previews: PreviewProvider {
    static var previews: some View {
        TeamLookupView(team_number: "229V", fetch: true).environmentObject(UserSettings())
    }
}
