//
//  VRCRoboScoutApp.swift
//  VRC RoboScout
//
//  Created by William Castro on 2/9/23.
//

import SwiftUI

let API = RoboScoutAPI()
let activities = RoboScoutActivityController()

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct CustomCenter: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context[HorizontalAlignment.center]
    }
}

extension HorizontalAlignment {
    static let customCenter: HorizontalAlignment = .init(CustomCenter.self)
}

/// Detect a Shake gesture in SwiftUI
/// Based on https://stackoverflow.com/a/60085784/128083
struct ShakableViewRepresentable: UIViewControllerRepresentable {
    let onShake: () -> ()
    
    class ShakeableViewController: UIViewController {
        var onShake: (() -> ())?
        
        override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            if motion == .motionShake {
                onShake?()
            }
        }
    }
    
    func makeUIViewController(context: Context) -> ShakeableViewController {
        let controller = ShakeableViewController()
        controller.onShake = onShake
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ShakeableViewController, context: Context) {}
}

extension View {
    func onShake(_ block: @escaping () -> Void) -> some View {
        overlay(
            ShakableViewRepresentable(onShake: block).allowsHitTesting(false)
        )
    }
}

extension UIApplication {
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    static var appBuildNumber: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
}

extension Collection where Indices.Iterator.Element == Index {
    public subscript(safe index: Index) -> Iterator.Element? {
        return (startIndex <= index && index < endIndex) ? self[index] : nil
    }
}

struct LazyView<Content: View>: View {
    private let build: () -> Content
    
    init(_ build: @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}

struct BulletList: View {
    var listItems: [String]
    var listItemSpacing: CGFloat? = nil
    var bullet: String = "•"
    var bulletWidth: CGFloat? = nil
    var bulletAlignment: Alignment = .leading
    
    var body: some View {
        VStack(alignment: .leading,
               spacing: listItemSpacing) {
            ForEach(listItems, id: \.self) { data in
                HStack(alignment: .top) {
                    Text(bullet)
                        .frame(width: bulletWidth,
                               alignment: bulletAlignment)
                    Text(data)
                        .frame(maxWidth: .infinity,
                               alignment: .leading)
                }
            }
        }
    }
}

struct NoData: View {
    var body: some View {
        VStack {
            Image(systemName: "xmark.bin.fill").font(.system(size: 30)).foregroundColor(.secondary)
            Spacer().frame(height: 5)
            Text("No data").foregroundColor(.secondary)
        }
    }
}

struct ImportingData: View {
    var body: some View {
        ProgressView().font(.system(size: 30)).tint(.secondary)
        Spacer().frame(height: 5)
        Text("Importing Data").foregroundColor(.secondary)
    }
}

@main
struct VRCRoboScout: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @ObservedObject var wcSession = WatchSession()
    
    @StateObject var favorites = FavoriteStorage(favorite_teams: defaults.object(forKey: "favorite_teams") as? [String] ?? [String](), favorite_events: defaults.object(forKey: "favorite_events") as? [String] ?? [String]())
    @StateObject var settings = UserSettings()
    @StateObject var dataController = RoboScoutDataController()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(favorites)
                .environmentObject(settings)
                .environmentObject(dataController)
                .tint(settings.buttonColor())
                .onAppear{
                    #if DEBUG
                    print("Debug configuration")
                    #else
                    print("Release configuration")
                    #endif
                    wcSession.updateFavorites()
                    DispatchQueue.global(qos: .userInteractive).async {
                        API.generate_season_id_map()
                        API.update_world_skills_cache()
                        API.update_vrc_data_analysis_cache()
                    }
                }
        }
    }
}
