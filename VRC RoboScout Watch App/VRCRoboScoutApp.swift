//
//  VRCRoboScoutApp.swift
//  VRC RoboScout Watch App
//
//  Created by William Castro on 7/26/24.
//

import SwiftUI

let API = RoboScoutAPI()

struct NoData: View {
    var body: some View {
        VStack {
            Image(systemName: "xmark.bin.fill").foregroundColor(.secondary)
        }
    }
}

struct ImportingData: View {
    var body: some View {
        ProgressView().tint(.secondary)
    }
}

@main
struct VRCRoboScout: App {
    
    @ObservedObject var wcSession = WatchSession()
    
    @StateObject var settings = UserSettings()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(wcSession)
                //.environmentObject(favorites)
                .environmentObject(settings)
                //.environmentObject(dataController)
                .onAppear{
                    #if DEBUG
                    print("Debug configuration")
                    #else
                    print("Release configuration")
                    #endif
                    settings.setSelectedSeasonID(id: 181)
                    settings.updateUserDefaults(updateTopBarContentColor: false)
                    DispatchQueue.global(qos: .userInteractive).async {
                        API.generate_season_id_map()
                        API.update_world_skills_cache()
                        API.update_vrc_data_analysis_cache()
                    }
                }
        }
    }
}
