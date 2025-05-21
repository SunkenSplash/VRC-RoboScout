//
//  MatchUpdatesLiveActivity.swift
//  MatchUpdates
//
//  Created by William Castro on 11/8/23.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MatchUpdatesAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var matches: [[String]]
    }

    // Fixed non-changing properties about your activity go here!
    var teamNumber: String
    var eventName: String
}

@available(iOS 16.2, *)
struct LiveMatchUpdatesView: View {
    
    let context: ActivityViewContext<MatchUpdatesAttributes>
    
    func nameColor(team: String, match: [String]) -> Color {
        if match[2].isEmpty || match[3].isEmpty {
            return .primary
        }
        if Int(match[2]) == Int(match[3]) {
            return .yellow
        }
        if match[4] == team || match[5] == team {
            if Int(match[2])! > Int(match[3])! {
                return .green
            }
        }
        else if match[6] == team || match[7] == team {
            if Int(match[3])! > Int(match[2])! {
                return .green
            }
        }
        return .red
    }

    // 0 is red alliance, 1 is blue alliance
    func scoreUnderline(team: String, alliance: Int, match: [String]) -> Bool {
        if (match[4] == team || match[5] == team) && alliance == 0 {
            return true
        }
        else if (match[6] == team || match[7] == team) && alliance == 1 {
            return true
        }
        return false
    }
    
    var body: some View {
        if !context.state.matches.isEmpty {
            ForEach((context.state.matches.count - 2)..<context.state.matches.count, id: \.self) { index in
                HStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(context.state.matches[index][0]).font(.system(size: 15)).bold().foregroundColor(nameColor(team: context.attributes.teamNumber, match: context.state.matches[index]))
                            if !context.state.matches[index][1].isEmpty {
                                Text(context.state.matches[index][1]).font(.system(size: 12))
                            }
                        }.frame(width: 60, alignment: .leading)
                        VStack(alignment: .leading) {
                            if !context.state.matches[index][5].isEmpty {
                                VStack {
                                    Text(context.state.matches[index][4]).foregroundColor(.red).font(.system(size: 14)).underline(context.state.matches[index][4] == context.attributes.teamNumber)
                                    Text(context.state.matches[index][5]).foregroundColor(.red).font(.system(size: 14)).underline(context.state.matches[index][5] == context.attributes.teamNumber)
                                }
                            }
                            else {
                                VStack {
                                    Text(context.state.matches[index][4]).foregroundColor(.red).font(.system(size: 14)).underline(context.state.matches[index][4] == context.attributes.teamNumber)
                                }
                            }
                        }.frame(width: 70)
                        if (context.state.matches[index][2].isEmpty || context.state.matches[index][3].isEmpty) {
                            Text("0h 10m").font(.system(size: 21)).bold().frame(maxWidth: .infinity)
                        }
                        else {
                            Text(context.state.matches[index][2]).foregroundColor(.red).font(.system(size: 23)).bold().underline(scoreUnderline(team: context.attributes.teamNumber, alliance: 0, match: context.state.matches[index]))
                            Spacer()
                            Text(context.state.matches[index][3]).foregroundColor(.blue).font(.system(size: 23)).bold().underline(scoreUnderline(team: context.attributes.teamNumber, alliance: 1, match: context.state.matches[index]))
                        }
                        VStack(alignment: .leading) {
                            if !context.state.matches[index][7].isEmpty {
                                VStack {
                                    Text(context.state.matches[index][6]).foregroundColor(.blue).font(.system(size: 14)).underline(context.state.matches[index][6] == context.attributes.teamNumber)
                                    Text(context.state.matches[index][7]).foregroundColor(.blue).font(.system(size: 14)).underline(context.state.matches[index][7] == context.attributes.teamNumber)
                                }
                            }
                            else {
                                VStack {
                                    Text(context.state.matches[index][6]).foregroundColor(.red).font(.system(size: 14)).underline(context.state.matches[index][6] == context.attributes.teamNumber)
                                }
                            }
                        }.frame(width: 70)
                    }
                    .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                }
            }
        }
        else {
            Text("Missing match data...").foregroundColor(.secondary)
        }
    }
}

@available(iOS 16.2, *)
struct MatchUpdatesLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MatchUpdatesAttributes.self) { context in
            // Lock screen/banner UI goes here
            
            /// Matches string array structure
            /// 0 Name
            /// 1 Time
            /// 2 Red score
            /// 3 Blue score
            /// 4 Red team 1 number
            /// 5 Red team 2 number
            /// 6 Blue team 1 number
            /// 7 Blue team 2 number
            
            VStack {
                HStack {
                    Text(context.attributes.teamNumber).font(.system(size: 21)).bold()
                    Spacer()
                    Text(context.attributes.eventName).font(.system(size: 21))
                }.frame(height: 30)
                LiveMatchUpdatesView(context: context)
            }.padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.teamNumber).bold().padding(.leading, 10)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("0h 10m").padding(.trailing, 10)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveMatchUpdatesView(context: context)
                }
            } compactLeading: {
                Text(context.attributes.teamNumber)
            } compactTrailing: {
                Text("0h 10m")
            } minimal: {
                Text("0:10")
            }
            .keylineTint(Color.red)
        }
    }
}

extension MatchUpdatesAttributes {
    fileprivate static var preview: MatchUpdatesAttributes {
        MatchUpdatesAttributes(teamNumber: "229V", eventName: "Mecha Mayhem 2025 Signature Event")
    }
}

extension MatchUpdatesAttributes.ContentState {
    fileprivate static var empty: MatchUpdatesAttributes.ContentState {
        MatchUpdatesAttributes.ContentState(matches: [[String]]())
    }
     
    fileprivate static var matchListAvailable: MatchUpdatesAttributes.ContentState {
        MatchUpdatesAttributes.ContentState(matches: [
            ["Q 16", "11:23 AM", "37", "11", "781X", "229V", "68411C", "86744B"],
            ["Q 25", "11:56 AM", "31", "40", "10009A", "27455B", "229V", "221B"],
            ["Q 43", "1:00 PM", "42", "20", "5327A", "229V", "871X", "6019B"],
            ["Q 72", "3:50 PM", "24", "49", "9181G", "6659C", "229V", "210Z"],
            ["Q 84", "3:14 PM", "45", "20", "229V", "221S", "3150B", "7899X"],
            ["Q 104", "4:26 PM", "0", "45", "3284B", "2088A", "9594M", "229V"],
            ["Q 125", "5:41 PM", "58", "3", "886Y", "229V", "45519H", "45519E"],
            ["Q 142", "7:09 PM", "17", "46", "3565X", "27455G", "1023E", "229V"],
            ["Q 157", "8:03 PM", "45", "21", "98549V", "229V", "1028Z", "60410C"],
            ["Q 177", "10:58 AM", "", "", "315A", "3300B", "87265D", "229V"],
        ])
    }
}

@available(iOS 18.0, *)
#Preview("Notification", as: .content, using: MatchUpdatesAttributes.preview) {
   MatchUpdatesLiveActivity()
} contentStates: {
    MatchUpdatesAttributes.ContentState.empty
    MatchUpdatesAttributes.ContentState.matchListAvailable
}
