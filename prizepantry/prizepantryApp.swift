//
//  prizepantryApp.swift
//  prizepantry
//
//  Updated for Secure Auth
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
            if isLoggedIn || Auth.auth().currentUser != nil {
                ContentView()
                    // Pass the login state so ContentView can offer a "Sign Out" button if needed
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}
