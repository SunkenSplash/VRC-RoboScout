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
    @State private var livestream_link = ""
    @State private var calendarAlert = false
    
    let dateFormatter = DateFormatter()
    
    init(event: Event) {
        self.event = event
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }
        
    var body: some View {
        VStack {
            Spacer()
            Text(event.name).font(.title2).multilineTextAlignment(.center).padding()
            if !livestream_link.isEmpty {
                HStack {
                    Spacer()
                    HStack {
                        Image(systemName: "play.tv").foregroundColor(settings.accentColor())
                        Link("Watch Livestream", destination: URL(string: self.livestream_link)!)
                    }
                    Spacer()
                }
            }
            else {
                Text("").frame(height: 20).onAppear{
                    DispatchQueue.global(qos: .userInteractive).async { [self] in
                        let link = self.event.fetch_livestream_link()
                        DispatchQueue.main.async {
                            self.livestream_link = link ?? ""
                        }
                    }
                }
            }
            VStack {
                List {
                    HStack {
                        Text("Teams")
                        Spacer()
                        Text(String(event.teams.count))
                    }.onAppear{
                        print(self.livestream_link)
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
                        Text(API.season_id_map[UserSettings.getGradeLevel() != "College" ? 0 : 1][event.season] ?? "")
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
                                            var correct = 0
                                            var matches = 0
                                            
                                            try self.event.predict_matches(division: division, only_predict: [Round.qualification], predict_completed: true, opr_weight: opr_weight, dpr_weight: dpr_weight)
                                            
                                            guard self.event.matches[division] != nil else {
                                                throw RoboScoutAPIError.missing_data("Missing matches")
                                            }
                                            
                                            for match in self.event.matches[division]! {
                                                do {
                                                    guard let prediction_correct = try match.is_correct_prediction() else {
                                                        continue
                                                    }
                                                    
                                                    if prediction_correct {
                                                        correct += 1
                                                    }
                                                    matches += 1
                                                }
                                                catch {}
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
                                        catch {
                                            print(error)
                                        }
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
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Link(destination: URL(string: "https://www.robotevents.com/robot-competitions/vex-robotics-competition/\(self.event.sku).html")!) {
                        Image(systemName: "link")
                    }
                    Button(action: {
                        self.event.add_to_calendar()
                        calendarAlert = true
                    }, label: {
                        Image(systemName: "calendar.badge.plus").foregroundColor(settings.navTextColor())
                    }).alert(isPresented: $calendarAlert) {
                       Alert(title: Text("Added to calendar"), dismissButton: .default(Text("OK")))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.tabColor(), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(settings.accentColor())
    }
}

struct EventInformation_Previews: PreviewProvider {
    static var previews: some View {
        EventInformation(event: Event())
    }
}

