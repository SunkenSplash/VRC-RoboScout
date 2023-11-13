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
struct MatchUpdatesLiveActivity: Widget {
    
    func nameColor(team: String, match: [String]) -> Color {
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
                ForEach((context.state.matches.count - 2)..<context.state.matches.count, id: \.self) { index in
                    HStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(context.state.matches[index][0]).font(.system(size: 15)).bold().foregroundColor(nameColor(team: context.attributes.teamNumber, match: context.state.matches[index]))
                                Text(context.state.matches[index][1]).font(.system(size: 12))
                            }.frame(width: 60)
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
                            Text(context.state.matches[index][2]).foregroundColor(.red).font(.system(size: 23)).bold().underline(scoreUnderline(team: context.attributes.teamNumber, alliance: 0, match: context.state.matches[index]))
                            Spacer()
                            Text(context.state.matches[index][3]).foregroundColor(.blue).font(.system(size: 23)).bold().underline(scoreUnderline(team: context.attributes.teamNumber, alliance: 1, match: context.state.matches[index]))
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
            }.padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T")
            } minimal: {
                Text("M")
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MatchUpdatesAttributes {
    fileprivate static var preview: MatchUpdatesAttributes {
        MatchUpdatesAttributes(teamNumber: "229V", eventName: "Mall of America Signature Event")
    }
}

extension MatchUpdatesAttributes.ContentState {
    fileprivate static var empty: MatchUpdatesAttributes.ContentState {
        MatchUpdatesAttributes.ContentState(matches: [[String]]())
    }
     
    fileprivate static var matchListAvailable: MatchUpdatesAttributes.ContentState {
        MatchUpdatesAttributes.ContentState(matches: [["Q1", "Q2", "Q3", "Q4"]])
    }
}
    
@available(iOS 16.2, *)
struct MatchUpdatesLiveActivity_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            MatchUpdatesAttributes.preview
                .previewContext(
                    MatchUpdatesAttributes.ContentState.empty,
                    viewKind: .content
                )
            MatchUpdatesAttributes.preview
                .previewContext(
                    MatchUpdatesAttributes.ContentState.matchListAvailable,
                    viewKind: .dynamicIsland(.expanded)
                )
        }
    }
}
