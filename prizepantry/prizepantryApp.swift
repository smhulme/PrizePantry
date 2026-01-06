//
//  prizepantryApp.swift
//  prizepantry
//
//  Updated for Secure Auth and Reliable Sign Out
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct prizepantryApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Track login state
    @State private var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                // Rely ONLY on this variable to decide which view to show
                if isLoggedIn {
                    ContentView(isLoggedIn: $isLoggedIn)
                } else {
                    LoginView(isLoggedIn: $isLoggedIn)
                }
            }
            .onAppear {
                // Check if user is already signed in ONLY when the app first appears
                if Auth.auth().currentUser != nil {
                    isLoggedIn = true
                }
            }
        }
    }
}
