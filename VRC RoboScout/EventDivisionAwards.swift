//
//  EventDivisionAwards.swift
//  VRC RoboScout
//
//  Created by William Castro on 6/23/23.
//

import SwiftUI

struct ExcellenceEligibleTeams: View {
    
    var event: Event
    let middleSchool: Bool
    let excellenceOffered: Bool
    let middleSchoolExcellenceOffered: Bool
    @State var eligible_teams = [Team]()
    @State var showLoading = true
    
    func generate_location(team: Team) -> String {
        var location_array = [team.city, team.region, team.country]
        location_array = location_array.filter{ $0 != "" }
        return location_array.joined(separator: ", ")
    }
    
    func levelFilter(rankings: [Any]) -> [Any] {
        if !middleSchoolExcellenceOffered {
            return rankings
        }
        
        var output = [Any]()
        for ranking in rankings {
            if let ranking = ranking as? TeamRanking, middleSchool ? event.get_team(id: ranking.team.id)!.grade == "Middle School" : event.get_team(id: ranking.team.id)!.grade != "Middle School" {
                output.append(ranking)
            }
            if let ranking = ranking as? TeamSkillsRanking, middleSchool ? event.get_team(id: ranking.team.id)!.grade == "Middle School" : event.get_team(id: ranking.team.id)!.grade != "Middle School" {
                output.append(ranking)
            }
        }
        return output
    }
    
    func fetch_info() {
        
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            var total_teams = 0
            
            for div in event.divisions {
                event.fetch_rankings(division: div)
                total_teams += levelFilter(rankings: event.rankings[div] ?? [TeamRanking]()).count
                sleep(1)
            }
            
            let THRESHOLD = 0.4
            
            let skills_rankings = levelFilter(rankings: event.skills_rankings) as! [TeamSkillsRanking]
            
            let auton_skills_rankings = skills_rankings.filter {
                $0.programming_score != 0
            }.sorted {
                $0.programming_score > $1.programming_score
            }
            
            let skills_ranking_cutoff = Double(total_teams) * THRESHOLD
            
            let auton_skills_ranking_cutoff = Double(total_teams) * THRESHOLD
            
            print("\nEXCELLENCE ELIGIBILITY CALCULATOR")
            print("\(middleSchool ? "MIDDLE SCHOOL" : "NOT MIDDLE SCHOOL")\n")
            
            // Top 40% in skills rankings
            print("SKILLS THRESHOLD: " + String(skills_ranking_cutoff) + "\n")
            let skills_rankings_teams = skills_rankings.dropLast(max(skills_rankings.count - Int(round(skills_ranking_cutoff)), 0)).map {
                $0.team
            }
            
            // Top 40% in auton skills
            print("AUTON SKILLS THRESHOLD: " + String(auton_skills_ranking_cutoff) + "\n")
            let auton_skills_rankings_teams = auton_skills_rankings.dropLast(max(auton_skills_rankings.count - Int(round(auton_skills_ranking_cutoff)), 0)).map {
                $0.team
            }
            
            var rankings_teams = [Team]()
            
            for div in event.divisions {
                
                if (event.rankings[div] ?? [TeamRanking]()).isEmpty {
                    break
                }
                                
                // Top 40% in qualifier rankings
                let ranking_cutoff = Double(levelFilter(rankings: event.rankings[div] ?? [TeamRanking]()).count) * THRESHOLD
                print("\(div.name.uppercased()) RANKINGS: " + String(ranking_cutoff))
                let rankings = levelFilter(rankings: event.rankings[div] ?? [TeamRanking]()) as! [TeamRanking]
                rankings_teams += rankings.reversed().dropLast(rankings.count - Int(round(ranking_cutoff))).map{
                    $0.team
                }
            }
            
            var eligible_teams = [Team]()
            
            print("RANKINGS ELIGIBLE: \(rankings_teams.map { event.get_team(id: $0.id)?.number ?? "" } )")
            print("SKILLS RANKINGS ELIGIBLE: \(skills_rankings_teams.map { event.get_team(id: $0.id)?.number ?? "" } )")
            print("AUTON SKILLS RANKINGS ELIGIBLE: \(auton_skills_rankings_teams.map { event.get_team(id: $0.id)?.number ?? "" } )")
            
            for team in event.teams {
                if rankings_teams.contains(where: { $0.id == team.id }) && skills_rankings_teams.contains(where: { $0.id == team.id }) && auton_skills_rankings_teams.contains(where: { $0.id == team.id }) {
                    eligible_teams.append(team)
                }
            }
            
            DispatchQueue.main.async {
                self.eligible_teams = eligible_teams
                self.showLoading = false
            }
        }
        
    }
    
    var body: some View {
        VStack {
            Text("Excellence Eligibility").font(.title).padding()
            VStack(alignment: .leading) {
                Text("Requirements:").padding()
                BulletList(listItems: ["Top 40% in qualifier rankings", "Top 40% in skills rankings", "Top 40% in autonomous skills rankings"], listItemSpacing: 10).padding()
                Text("The following teams are eligible:").padding()
            }
            if showLoading {
                List {
                    HStack {
                        Spacer()
                        ProgressView().onAppear { fetch_info() }
                        Spacer()
                    }
                }
            }
            else if !eligible_teams.isEmpty {
                List($eligible_teams) { team in
                    HStack {
                        Text(team.wrappedValue.number).font(.system(size: 20)).minimumScaleFactor(0.01).frame(width: 80, height: 30, alignment: .leading).bold()
                        VStack {
                            Text(team.wrappedValue.name).frame(maxWidth: .infinity, alignment: .leading).frame(height: 20)
                            Spacer().frame(height: 5)
                            Text(generate_location(team: team.wrappedValue)).font(.system(size: 11)).frame(maxWidth: .infinity, alignment: .leading).frame(height: 15)
                        }
                    }
                }
            }
            else {
                List {
                    Text("No eligible teams")
                }
            }
            Spacer()
        }
    }
}

struct EventDivisionAwards: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @State var event: Event
    @State var division: Division
    @State var showLoading = true
    @State var showingExcellenceEligibility = false
    @State var showingMiddleSchoolExcellenceEligibility = false
    @State var excellenceOffered = false
    @State var middleSchoolExcellenceOffered = false
    
    init(event: Event, division: Division) {
        self.event = event
        self.division = division
    }
    
    func fetch_awards() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            event.fetch_awards(division: division)
            event.fetch_rankings(division: division)
            event.fetch_skills_rankings()
            DispatchQueue.main.async {
                self.showLoading = false
            }
        }
    }
    
    var body: some View {
        VStack {
            if showLoading {
                ProgressView().padding()
                Spacer()
            }
            else if (event.awards[division] ?? [DivisionalAward]()).isEmpty {
                NoData()
            }
            else {
                List(event.awards[division]!, id: \.self) { award in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(award.title)
                            Spacer()
                            if !award.qualifications.isEmpty {
                                Menu {
                                    Text("Qualifies for:")
                                    ForEach(award.qualifications, id: \.self) { qual in
                                        Text(qual)
                                    }
                                } label: {
                                    Image(systemName: "globe.americas")
                                }
                            }
                        }
                        if award.teams.isEmpty && award.title.contains("Excellence") && !(event.rankings[division] ?? [TeamRanking]()).isEmpty && !event.skills_rankings.isEmpty {
                            Spacer().frame(height: 5)
                            Button("Show eligible teams") {
                                if award.title.contains("Middle") {
                                    showingMiddleSchoolExcellenceEligibility = true
                                    showingExcellenceEligibility = true
                                }
                                else {
                                    showingMiddleSchoolExcellenceEligibility = false
                                    showingExcellenceEligibility = true
                                }
                            }.font(.system(size: 14)).onAppear {
                                if award.title.contains("Middle") {
                                    middleSchoolExcellenceOffered = true
                                }
                                else {
                                    excellenceOffered = true
                                }
                            }
                        }
                        else if !award.teams.isEmpty {
                            Spacer().frame(height: 5)
                            ForEach(award.teams, id: \.self) { team in
                                if !award.teams.isEmpty {
                                    HStack {
                                        Text(team.number).frame(maxWidth: .infinity, alignment: .leading).frame(width: 60).font(.system(size: 14)).foregroundColor(.secondary).bold()
                                        Text(team.name).frame(maxWidth: .infinity, alignment: .leading).font(.system(size: 14)).foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }.sheet(isPresented: $showingExcellenceEligibility) {
                    ExcellenceEligibleTeams(event: event, middleSchool: showingMiddleSchoolExcellenceEligibility, excellenceOffered: excellenceOffered, middleSchoolExcellenceOffered: middleSchoolExcellenceOffered)
                }
            }
        }.task{
            fetch_awards()
        }.onAppear{
            navigation_bar_manager.title = "\(division.name) Awards"
        }
    }
}

struct EventDivisionAwards_Previews: PreviewProvider {
    static var previews: some View {
        EventDivisionAwards(event: Event(), division: Division())
    }
}
