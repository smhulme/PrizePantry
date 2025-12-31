//
//  prizepantryApp.swift
//  prizepantry
//
//  Created by Shawn Hulme on 12/29/25.
//

import SwiftUI
import FirebaseCore

// This helper class connects your app to Firebase when it starts up
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct prizepantryApp: App {
    // This tells SwiftUI to use the helper class above
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Note: The '.modelContainer' line is gone because Firebase handles storage now
    }
}
