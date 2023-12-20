//
//  AppDelegate.swift
//  VRC RoboScout
//
//  Created by William Castro on 11/10/23.
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    @Published var deviceToken: String?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(tokenString)")
        defaults.set(tokenString, forKey: "device_token")
        
        // Update the published property for SwiftUI views to observe
        DispatchQueue.main.async {
            self.deviceToken = tokenString
        }

        // Handle the device token as needed, e.g., send it to your server
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }

}
