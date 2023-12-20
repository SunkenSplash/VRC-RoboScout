//
//  DataExporter.swift
//  VRC RoboScout
//
//  Created by William Castro on 8/27/23.
//

import SwiftUI
import OrderedCollections
import UniformTypeIdentifiers
import CoreTransferable


struct DataExporter: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @State var event: Event
    @State var event_teams_list: [String]
    @State var progress: Double = 0
    @State var csv_string: String = ""
    @State var show_option = 0
    @State var view_closed = false
    @State var selected: OrderedDictionary = [
        "Team Name": true,
        "Robot Name": true,
        "Team Location": true,
        "Average Qualifiers Ranking (slow)": false,
        "Total Events Attended (slow)": false,
        "Total Awards (slow)": false,
        "Total Matches": true,
        "Total Wins": true,
        "Total Losses": true,
        "Total Ties": true,
        "Winrate": true,
        "World Skills Ranking": true,
        "Combined Skills": true,
        "Programming Skills": true,
        "Driver Skills": true,
        "TrueSkill Ranking": true,
        "TrueSkill Score": true
    ]
    @State var sections: OrderedDictionary = [
        "Team Info": [0, 2],
        "Performance Statistics": [3, 10],
        "Skills Data": [11, 14],
        "TrueSkill": [15, 16]
    ]
    
    func generate_location(team: Team) -> String {
        var location_array = [team.city, team.region, team.country]
        location_array = location_array.filter{ $0 != "" }
        return location_array.joined(separator: " ")
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("\(event_teams_list.count) Teams")
            Spacer()
            ScrollView {
                VStack(spacing: 40) {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Team Info")
                            Spacer()
                            if show_option == 0 {
                                Image(systemName: "chevron.up.circle")
                            }
                            else {
                                Image(systemName: "chevron.down.circle")
                            }
                        }.contentShape(Rectangle()).onTapGesture{
                            show_option = 0
                        }
                        if show_option == 0 {
                            ForEach(Array(Array(selected.keys)[0...2]), id: \.self) { option in
                                HStack {
                                    if option.contains("(slow)") {
                                        HStack {
                                            Text(option.description.replacingOccurrences(of: " (slow)", with: "")).foregroundColor(.secondary)
                                            Image(systemName: "timer").foregroundColor(.secondary)
                                        }
                                    }
                                    else {
                                        Text(option).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selected[option] ?? false {
                                        Image(systemName: "checkmark").foregroundColor(.secondary)
                                    }
                                }.contentShape(Rectangle()).onTapGesture{
                                    if progress == 0 || progress == 1 {
                                        selected[option] = !(selected[option] ?? false)
                                        progress = 0
                                    }
                                }
                            }
                        }
                    }
                    VStack(spacing: 10) {
                        HStack {
                            Text("Performance Statistics")
                            Spacer()
                            if show_option == 1 {
                                Image(systemName: "chevron.up.circle")
                            }
                            else {
                                Image(systemName: "chevron.down.circle")
                            }
                        }.contentShape(Rectangle()).onTapGesture{
                            show_option = 1
                        }
                        if show_option == 1 {
                            ForEach(Array(Array(selected.keys)[3...10]), id: \.self) { option in
                                HStack {
                                    if option.contains("(slow)") {
                                        HStack {
                                            Text(option.description.replacingOccurrences(of: " (slow)", with: "")).foregroundColor(.secondary)
                                            Image(systemName: "timer").foregroundColor(.secondary)
                                        }
                                    }
                                    else {
                                        Text(option).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selected[option] ?? false {
                                        Image(systemName: "checkmark").foregroundColor(.secondary)
                                    }
                                }.contentShape(Rectangle()).onTapGesture{
                                    if progress == 0 || progress == 1 {
                                        selected[option] = !(selected[option] ?? false)
                                        progress = 0
                                    }
                                }
                            }
                        }
                    }
                    VStack(spacing: 10) {
                        HStack {
                            Text("Skills Data")
                            Spacer()
                            if show_option == 2 {
                                Image(systemName: "chevron.up.circle")
                            }
                            else {
                                Image(systemName: "chevron.down.circle")
                            }
                        }.contentShape(Rectangle()).onTapGesture{
                            show_option = 2
                        }
                        if show_option == 2 {
                            ForEach(Array(Array(selected.keys)[11...14]), id: \.self) { option in
                                HStack {
                                    if option.contains("(slow)") {
                                        HStack {
                                            Text(option.description.replacingOccurrences(of: " (slow)", with: "")).foregroundColor(.secondary)
                                            Image(systemName: "timer").foregroundColor(.secondary)
                                        }
                                    }
                                    else {
                                        Text(option).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selected[option] ?? false {
                                        Image(systemName: "checkmark").foregroundColor(.secondary)
                                    }
                                }.contentShape(Rectangle()).onTapGesture{
                                    if progress == 0 || progress == 1 {
                                        selected[option] = !(selected[option] ?? false)
                                        progress = 0
                                    }
                                }
                            }
                        }
                    }
                    VStack(spacing: 10) {
                        HStack {
                            Text("TrueSkill")
                            Spacer()
                            if show_option == 3 {
                                Image(systemName: "chevron.up.circle")
                            }
                            else {
                                Image(systemName: "chevron.down.circle")
                            }
                        }.contentShape(Rectangle()).onTapGesture{
                            show_option = 3
                        }
                        if show_option == 3 {
                            ForEach(Array(Array(selected.keys)[15...16]), id: \.self) { option in
                                HStack {
                                    if option.contains("(slow)") {
                                        HStack {
                                            Text(option.description.replacingOccurrences(of: " (slow)", with: "")).foregroundColor(.secondary)
                                            Image(systemName: "timer").foregroundColor(.secondary)
                                        }
                                    }
                                    else {
                                        Text(option).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selected[option] ?? false {
                                        Image(systemName: "checkmark").foregroundColor(.secondary)
                                    }
                                }.contentShape(Rectangle()).onTapGesture{
                                    if progress == 0 || progress == 1 {
                                        selected[option] = !(selected[option] ?? false)
                                        progress = 0
                                    }
                                }
                            }
                        }
                    }
                }
            }.padding()
            Spacer()
            ProgressView(value: progress).padding().tint(settings.accentColor())
            if progress != 1 {
                Button("Generate") {
                    if progress != 0 {
                        return
                    }
                    progress = 0.001
                    DispatchQueue.global(qos: .userInteractive).async { [self] in
                        var data = "Team Number"
                        for (option, state) in selected {
                            guard state else { continue }
                            data += ",\(option)"
                        }
                        data += "\n"
                        var count = 0
                        for number in event_teams_list {
                            if view_closed {
                                return
                            }
                            data += number
                            let team = event.teams.first(where: { $0.number == number })!
                            let world_skills = API.world_skills_for(team: team) ?? WorldSkills(team: team, data: [String: Any]())
                            let vrc_data_analysis = API.vrc_data_analysis_for(team: team, fetch_re_match_statistics: false)
                            for (option, state) in selected {
                                guard state else { continue }
                                if option == "Team Name" {
                                    data += ",\(team.name.replacingOccurrences(of: ",", with: ""))"
                                }
                                else if option == "Robot Name" {
                                    data += ",\(team.robot_name.replacingOccurrences(of: ",", with: ""))"
                                }
                                else if option == "Team Location" {
                                    data += ",\(generate_location(team: team).replacingOccurrences(of: ",", with: ""))"
                                }
                                else if option == "Average Qualifiers Ranking (slow)" {
                                    data += ",\(team.average_ranking())"
                                    sleep(2)
                                }
                                else if option == "Total Events Attended (slow)" {
                                    if selected["Average Qualifiers Ranking (slow)"]! {
                                        data += ",\(team.event_count)"
                                    }
                                    else {
                                        team.fetch_events()
                                        data += ",\(team.events.count)"
                                        sleep(2)
                                    }
                                }
                                else if option == "Total Awards (slow)" {
                                    team.fetch_awards()
                                    data += ",\(team.awards.count)"
                                    sleep(2)
                                }
                                else if option == "Total Matches" {
                                    data += ",\(vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties)"
                                }
                                else if option == "Total Wins" {
                                    data += ",\(vrc_data_analysis.total_wins)"
                                }
                                else if option == "Total Losses" {
                                    data += ",\(vrc_data_analysis.total_losses)"
                                }
                                else if option == "Total Ties" {
                                    data += ",\(vrc_data_analysis.total_ties)"
                                }
                                else if option == "Winrate" {
                                    data += ",\(((vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties > 0) ? (displayRoundedTenths(number: Double(vrc_data_analysis.total_wins) / Double(vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties))) : "0"))"
                                }
                                else if option == "World Skills Ranking" {
                                    data += ",\(world_skills.ranking)"
                                }
                                else if option == "Combined Skills" {
                                    data += ",\(world_skills.combined)"
                                }
                                else if option == "Programming Skills" {
                                    data += ",\(world_skills.programming)"
                                }
                                else if option == "Driver Skills" {
                                    data += ",\(world_skills.driver)"
                                }
                                else if option == "TrueSkill Ranking" {
                                    data += ",\(vrc_data_analysis.ts_ranking)"
                                }
                                else if option == "TrueSkill Score" {
                                    data += ",\(vrc_data_analysis.trueskill)"
                                }
                            }
                            data += "\n"
                            count += 1
                            DispatchQueue.main.async {
                                progress = Double(count) / Double(event_teams_list.count)
                            }
                        }
                        csv_string = data
                        progress = 1
                    }
                }.padding(10)
                    .background(settings.accentColor())
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            else {
                Button("Save") {
                    let dataPath = URL.documentsDirectory.appendingPathComponent("ScoutingData")
                    if !FileManager.default.fileExists(atPath: dataPath.path) {
                        do {
                            try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
                        } catch {
                            print("Error")
                            print(error.localizedDescription)
                        }
                    }
                    let url = dataPath.appending(path: "\(self.event.name.convertedToSlug() ?? self.event.sku).csv")
                    let csvData = csv_string.data(using: .utf8)!
                    try! csvData.write(to: url)
                    if let sharedUrl = URL(string: "shareddocuments://\(url.path)") {
                        if UIApplication.shared.canOpenURL(sharedUrl) {
                            UIApplication.shared.open(sharedUrl, options: [:])
                        }
                    }
                }.padding(10)
                    .background(settings.accentColor())
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            Spacer()
        }.onDisappear{
            view_closed = true
        }.background(.clear)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Export Data")
                    .fontWeight(.medium)
                    .font(.system(size: 19))
                    .foregroundColor(settings.navTextColor())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(settings.tabColor(), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(settings.accentColor())
    }
}

struct DataExporter_Previews: PreviewProvider {
    static var previews: some View {
        DataExporter(event: Event(), event_teams_list: [String]())
    }
}
