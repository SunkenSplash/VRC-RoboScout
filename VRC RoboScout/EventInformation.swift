//
//  EventInformation.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/27/23.
//

import SwiftUI

struct EventInformation: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @State var event: Event
    @State private var predictions = false
    @State private var calculating_predictions = false
    @State private var total_correct = 0
    @State private var total_matches = 0
    @State private var slider_value = 50.0
    
    let dateFormatter = DateFormatter()
    
    init(event: Event) {
        self.event = event
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }
        
    var body: some View {
        VStack {
            Spacer()
            Text(event.name).font(.title2).multilineTextAlignment(.center).padding()
            VStack {
                List {
                    HStack {
                        Text("Teams")
                        Spacer()
                        Text(String(event.teams.count))
                    }
                    HStack {
                        Menu("Divisions") {
                            ForEach(event.divisions.map{ $0.name }, id: \.self) {
                                Text($0)
                            }
                        }
                        Spacer()
                        Text(String(event.divisions.count))
                    }
                    HStack {
                        Text("City")
                        Spacer()
                        Text(event.city)
                    }
                    HStack {
                        Text("Region")
                        Spacer()
                        Text(event.region)
                    }
                    HStack {
                        Text("Country")
                        Spacer()
                        Text(event.country)
                    }
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(event.start!, style: .date)
                    }
                    HStack {
                        Text("Season")
                        Spacer()
                        Text(API.season_id_map[event.season] ?? "")
                    }
                    HStack {
                        Menu("Developer") {
                            Text("ID: \(String(event.id))")
                            Text("SKU: \(event.sku)")
                        }
                        Spacer()
                        if !calculating_predictions {
                            Button("Test Predictions") {
                                print("PREDICTIONS TEST: Alliance OPR and Opponent DPR AVERAGE")
                                total_correct = 0
                                total_matches = 0
                                predictions = false
                                calculating_predictions = true
                                DispatchQueue.global(qos: .userInteractive).async { [self] in
                                    
                                    let opr_weight = slider_value / 100
                                    let dpr_weight = (100 - slider_value) / 100
                                    
                                    for division in self.event.divisions {
                                        do {
                                            try self.event.calculate_team_performance_ratings(division: division)
                                            
                                            var correct = 0
                                            var matches = 0
                                            
                                            for match in self.event.matches[division]! {
                                                
                                                guard match.round == Round.qualification else {
                                                    continue
                                                }
                                                guard match.started != nil || match.red_score != 0 || match.blue_score != 0 else {
                                                    continue
                                                }
                                                
                                                var predicted_winner: Alliance?
                                                
                                                var red_opr = 0.0
                                                var blue_opr = 0.0
                                                var red_dpr = 0.0
                                                var blue_dpr = 0.0
                                                
                                                for match_team in match.red_alliance {
                                                    red_opr += (self.event.team_performance_ratings[match_team.id] ?? TeamPerformanceRatings(team: match_team, event: self.event, opr: 0, dpr: 0, ccwm: 0)).opr
                                                    red_dpr += (self.event.team_performance_ratings[match_team.id] ?? TeamPerformanceRatings(team: match_team, event: self.event, opr: 0, dpr: 0, ccwm: 0)).dpr
                                                }
                                                for match_team in match.blue_alliance {
                                                    blue_opr += (self.event.team_performance_ratings[match_team.id] ?? TeamPerformanceRatings(team: match_team, event: self.event, opr: 0, dpr: 0, ccwm: 0)).opr
                                                    blue_dpr += (self.event.team_performance_ratings[match_team.id] ?? TeamPerformanceRatings(team: match_team, event: self.event, opr: 0, dpr: 0, ccwm: 0)).dpr
                                                }
                                                
                                                let predicted_red_score = Int(round(opr_weight * red_opr + dpr_weight * blue_dpr))
                                                let predicted_blue_score = Int(round(opr_weight * blue_opr + dpr_weight * red_dpr))
                                                
                                                if predicted_red_score > predicted_blue_score {
                                                    predicted_winner = Alliance.red
                                                }
                                                else if predicted_blue_score > predicted_red_score {
                                                    predicted_winner = Alliance.blue
                                                }
                                                else {
                                                    predicted_winner = nil
                                                }
                                                
                                                if predicted_winner == match.winning_alliance() {
                                                    correct += 1
                                                }
                                                matches += 1
                                            }
                                            print("Division: \(division.name)")
                                            print("Correct: \(correct)")
                                            print("Incorrect: \(matches - correct)")
                                            print("Accuracy: \((Double(correct) / Double(matches)) * 100)%")
                                            DispatchQueue.main.async {
                                                total_correct += correct
                                                total_matches += matches
                                            }
                                        }
                                        catch {}
                                    }
                                    
                                    DispatchQueue.main.async {
                                        print("Total correct: \(total_correct)")
                                        print("Total incorrect: \(total_matches - total_correct)")
                                        print("Total accuracy: \((Double(total_correct) / Double(total_matches)) * 100)%")
                                        predictions = true
                                        calculating_predictions = false
                                    }
                                }
                            }
                        }
                        else {
                            ProgressView()
                        }
                    }
                    VStack {
                        Text("Adjust prediction weights:")
                        Slider(value: $slider_value, in: 0...100).onChange(of: slider_value) { _ in
                            slider_value = round(slider_value)
                        }
                        HStack {
                            Text("OPR: \(Int(slider_value))%")
                            Spacer()
                            Text("DPR: \(Int(100 - slider_value))%")
                        }
                    }
                }
                if predictions {
                    Text("Total correct: \(total_correct)")
                    Text("Total incorrect: \(total_matches - total_correct)")
                    Text("Total accuracy: \(displayRoundedTenths(number: (Double(total_correct) / Double(total_matches)) * 100))%")
                }
            }
        }.background(.clear)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Event Info")
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

struct EventInformation_Previews: PreviewProvider {
    static var previews: some View {
        EventInformation(event: Event())
    }
}

