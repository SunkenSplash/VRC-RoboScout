//
//  VRCRoboScoutWApp.swift
//  VRC RoboScout W Watch App
//
//  Created by William Castro on 7/26/24.
//

import SwiftUI

let API = RoboScoutAPI()

@main
struct VRCRoboScoutW: App {
    
    @ObservedObject var wcSession = WatchSessionW()
    
    @StateObject var settings = UserSettings()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(wcSession)
                //.environmentObject(favorites)
                .environmentObject(settings)
                //.environmentObject(dataController)
                .tint(settings.buttonColor())
                .onAppear{
                    #if DEBUG
                    print("Debug configuration")
                    #else
                    print("Release configuration")
                    #endif
                    DispatchQueue.global(qos: .userInteractive).async {
                        API.generate_season_id_map()
                        API.update_world_skills_cache()
                        API.update_vrc_data_analysis_cache()
                    }
                }
        }
    }
}
