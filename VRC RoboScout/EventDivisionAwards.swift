//
//  EventDivisionAwards.swift
//  VRC RoboScout
//
//  Created by William Castro on 6/23/23.
//

import SwiftUI

struct EventDivisionAwards: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @State var event: Event
    @State var division: Division
    @State var showLoading = true
    
    init(event: Event, division: Division) {
        self.event = event
        self.division = division
    }
    
    func fetch_awards() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            event.fetch_awards(division: division)
            DispatchQueue.main.async {
                self.showLoading = false
            }
        }
    }
    
    var body: some View {
        VStack {
            if showLoading {
                ProgressView().padding()
            }
            else if (event.awards[division] ?? [DivisionalAward]()).isEmpty {
                NoData()
            }
            else {
                List {
                    ForEach(0..<event.awards[division]!.count, id: \.self) { i in
                        VStack(alignment: .leading) {
                            Text(event.awards[division]![i].title)
                            if !event.awards[division]![i].teams.isEmpty {
                                Spacer().frame(height: 5)
                            }
                            ForEach(0..<event.awards[division]![i].teams.count, id: \.self) { j in
                                if !event.awards[division]![i].teams.isEmpty {
                                    HStack {
                                        Text(event.awards[division]![i].teams[j].number).frame(maxWidth: .infinity, alignment: .leading).frame(width: 60).font(.system(size: 14)).foregroundColor(.secondary)
                                        Text(event.awards[division]![i].teams[j].name).frame(maxWidth: .infinity, alignment: .leading).font(.system(size: 14)).foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
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
