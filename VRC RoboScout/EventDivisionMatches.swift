//
//  EventDivisionMatches.swift
//  VRC RoboScout
//
//  Created by William Castro on 6/19/23.
//

import SwiftUI

struct EventDivisionMatches: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @Binding var teams_map: [String: String]
    
    @State var event: Event
    @State var division: Division
    @State private var matches = [Match]()
    @State private var matches_list = [String]()
    @State private var showLoading = true
    
    func fetch_info() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            self.event.fetch_matches(division: division)
            let matches = self.event.matches[division] ?? [Match]()

            // Time should be in the format of "HH:mm" AM/PM
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"

            DispatchQueue.main.async {
                self.matches = matches
                self.matches_list.removeAll()
                var count = 0
                for match in matches {
                    var name = match.name
                    name.replace("Qualifier", with: "Q")
                    name.replace("Practice", with: "P")
                    name.replace("Final", with: "F")
                    name.replace("#", with: "")
                    
                    // If match.started is not nil, then use it
                    // Otherwise use match.scheduled
                    // If both are nil, then use ""
                    let date: String = {
                        if let started = match.started {
                            return formatter.string(from: started)
                        }
                        else if let scheduled = match.scheduled {
                            return formatter.string(from: scheduled)
                        }
                        else {
                            return " "
                        }
                    }()
                    
                    // count, name, red1, red2, blue1, blue2, red_score, blue_score, scheduled time
                    self.matches_list.append("\(count)&&\(name)&&\(match.red_alliance[0].id)&&\(match.red_alliance[1].id)&&\(match.blue_alliance[0].id)&&\(match.blue_alliance[1].id)&&\(match.red_score)&&\(match.blue_score)&&\(date)")
                    count += 1
                }
                self.showLoading = false
            }
        }
    }
        
    var body: some View {
        VStack {
            if showLoading {
                ProgressView().padding()
            }
            else if matches.isEmpty {
                NoData()
            }
            else {
                List($matches_list) { name in
                    HStack {
                        VStack {
                            Text(name.wrappedValue.split(separator: "&&")[1]).font(.system(size: 15)).frame(width: 60, alignment: .leading)
                            Spacer().frame(maxHeight: 4)
                            Text(name.wrappedValue.split(separator: "&&")[8]).font(.system(size: 12)).frame(width: 60, alignment: .leading)
                        }
                        VStack {
                            Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[2])] ?? "")).foregroundColor(.red).font(.system(size: 15))
                            Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[3])] ?? "")).foregroundColor(.red).font(.system(size: 15))
                        }.frame(width: 80)
                        Text(name.wrappedValue.split(separator: "&&")[6]).foregroundColor(.red).font(.system(size: 19)).frame(alignment: .leading)
                        Spacer()
                        Text(name.wrappedValue.split(separator: "&&")[7]).foregroundColor(.blue).font(.system(size: 19)).frame(alignment: .trailing)
                        VStack {
                            Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[4])] ?? "")).foregroundColor(.blue).font(.system(size: 15))
                            Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[5])] ?? "")).foregroundColor(.blue).font(.system(size: 15))
                        }.frame(width: 80)
                    }.frame(maxHeight: 30)
                }
            }
        }.task{
            fetch_info()
        }.onAppear{
            navigation_bar_manager.title = "\(division.name) Match List"
        }
            .background(.clear)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("\(division.name) Match List")
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

struct EventDivisionMatches_Previews: PreviewProvider {
    static var previews: some View {
        EventDivisionMatches(teams_map: .constant([String: String]()), event: Event(), division: Division())
    }
}
