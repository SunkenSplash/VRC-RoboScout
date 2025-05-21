//
//  EventDivisionAwardsView.swift
//  VRC RoboScout
//
//  Created by William Castro on 5/19/25.
//

import SwiftUI

struct EventDivisionAwardsView: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @State var event: Event
    @State var division: Division
    @State var showLoading = true
    @State var showQualifications: Bool = false
    @State var expandedAward: DivisionalAward? = nil
    
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
                    VStack {
                        Text(award.title).foregroundColor(award.qualifications.isEmpty ? .primary : .red).frame(maxWidth: .infinity, alignment: .leading)
                        if !award.teams.isEmpty {
                            ForEach(award.teams, id: \.self) { team in
                                if !award.teams.isEmpty {
                                    HStack {
                                        Text(team.number).frame(alignment: .leading).foregroundColor(.secondary).bold()
                                        Spacer()
                                        Text(team.name).frame(alignment: .trailing).foregroundColor(.secondary).lineLimit(1)
                                    }
                                }
                            }
                        }
                    }.onTapGesture {
                        if !award.qualifications.isEmpty {
                            showQualifications = true
                            expandedAward = award
                        }
                    }
                }.fullScreenCover(isPresented: Binding<Bool>( // I wish we didn't need to do this
                    get: {
                        expandedAward != nil
                    }, set: { expanded in
                        if !expanded {
                            expandedAward = nil
                        }
                    })) {
                    VStack {
                        Text("Qualifies for:")
                        List($expandedAward.wrappedValue!.qualifications) { qual in
                            Text(qual)
                        }
                    }
                }
            }
        }.task{
            fetch_awards()
        }
    }
}

struct EventDivisionAwards_Previews: PreviewProvider {
    static var previews: some View {
        EventDivisionAwardsView(event: Event(id: 51488), division: Division(id: 1, name: "North Division"))
    }
}
