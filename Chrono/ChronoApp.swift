
//
//  ChronoApp.swift
//  Chrono
//
//  Created by Dana on 18/12/1447 AH.
//

import SwiftUI

@main
struct ChronoApp: App {
    
    // This magically watches UserDefaults.
    // If it's empty, they haven't taken the quiz. If it has text, they have!
    @AppStorage("userChronotype") private var savedChronotype: String = ""
    
    var body: some Scene {
        WindowGroup {
            // THE ROUTER LOGIC
            if savedChronotype.isEmpty {
                
                // 1. No animal saved yet? Show them the Onboarding Quiz.
                QuizView()
                
            } else {
                
                // 2. Animal is saved? Convert the string back into your Chronotype enum...
                if let type = Chronotype(rawValue: savedChronotype) {
                    
                    // ...and launch the Dashboard we built earlier!
                    ContentView(userChronotype: type)
                        .transition(.opacity) // Smooth fade transition
                    
                } else {
                    
                    // Safe fallback just in case something typos
                    ContentView(userChronotype: .bear)
                }
                
            }
        }
    }
}
