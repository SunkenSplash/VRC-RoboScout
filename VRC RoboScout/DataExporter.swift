//
//  DataExporter.swift
//  VRC RoboScout
//
//  Created by William Castro on 8/27/23.
//

import SwiftUI
import OrderedCollections
import UniformTypeIdentifiers

struct CSVData: Transferable {
    var csv_string: String
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: UTType("sunkensplashstudios.VRCRoboScout.csv")!) { csv in
            csv.csv_string.data(using: .utf8)!
        }
    }
}

struct DataExporter: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @State var event: Event
    @State var event_teams_list: [String]
    @State var progress: Double = 0
    @State var csv_string: String = ""
    @State var selected: OrderedDictionary = [
        "Team Name": true,
        "Robot Name": true,
        "Team Location": true,
        "Average Qualifiers Ranking (slow)": true,
        "Total Events Attended (slow)": true,
        "Total Awards (slow)": true,
        "Total Matches": true,
        "Total Wins": true,
        "Total Losses": true,
        "Total Ties": true,
        "Winrate": true,
        "World Skills Ranking": true,
        "Combined Skills": true,
        "Programming Skills": true,
        "Driver Skills": true
    ]
    
    func generate_location(team: Team) -> String {
        var location_array = [team.city, team.region, team.country]
        location_array = location_array.filter{ $0 != "" }
        return location_array.joined(separator: ", ")
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("\(event_teams_list.count) Teams")
            List {
                ForEach(Array(selected.keys), id: \.self) { option in
                    HStack {
                        if option.contains("(slow)") {
                            HStack {
                                Text(option.description.replacingOccurrences(of: " (slow)", with: ""))
                                Image(systemName: "timer")
                            }
                        }
                        else {
                            Text(option)
                        }
                        Spacer()
                        if selected[option] ?? false {
                            Image(systemName: "checkmark")
                        }
                    }.contentShape(Rectangle()).onTapGesture{
                        if progress == 0 || progress == 1 {
                            selected[option] = !(selected[option] ?? false)
                            progress = 0
                        }
                    }
                }
            }
            ProgressView(value: progress)
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
                            data += number
                            let team = event.teams.first(where: { $0.number == number })!
                            let world_skills = API.world_skills_for(team: team)
                            for (option, state) in selected {
                                guard state else { continue }
                                if option == "Team Name" {
                                    data += ",\(team.name)"
                                }
                                else if option == "Robot Name" {
                                    data += ",\(team.robot_name)"
                                }
                                else if option == "Team Location" {
                                    data += ",\(generate_location(team: team))"
                                }
                                else if option == "Average Qualifiers Ranking (slow)" {
                                    data += ",\(team.average_ranking())"
                                    sleep(1)
                                }
                                else if option == "Total Events Attended (slow)" {
                                    if selected["Average Qualifiers Ranking (slow)"]! {
                                        data += ",\(team.event_count)"
                                    }
                                    else {
                                        team.fetch_events()
                                        data += ",\(team.events.count)"
                                        sleep(1)
                                    }
                                }
                                else if option == "Total Awards (slow)" {
                                    team.fetch_awards()
                                    data += ",\(team.awards.count)"
                                    sleep(1)
                                }
                                else if option == "Total Matches" {
                                    data += ",\(1)"
                                }
                                else if option == "Total Wins" {
                                    data += ",\(1)"
                                }
                                else if option == "Total Losses" {
                                    data += ",\(1)"
                                }
                                else if option == "Total Ties" {
                                    data += ",\(1)"
                                }
                                else if option == "Winrate" {
                                    data += ",\(1)"
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
                }
                Spacer()
            }
            else {
                ShareLink(item: CSVData(csv_string: csv_string), preview: SharePreview("VRC RoboScout CSV Data.csv", image: Image(systemName: "tablecells"))) {
                    Text("Download")
                }
                Spacer()
            }
            
            Spacer()
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
    }
}

struct DataExporter_Previews: PreviewProvider {
    static var previews: some View {
        DataExporter(event: Event(), event_teams_list: [String]())
    }
}
