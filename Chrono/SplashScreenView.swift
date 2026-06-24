//
//  SplashScreenView.swift
//  Chrono
//
//  Created by Reema on 21/12/1447 AH.
//


import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimationDone = false
    @State private var opacity = 0.5
    @State private var size = 0.8
    
    // قراءة الحالات التاريخية للمستخدم من الـ UserDefaults
    @AppStorage("userChronotype") private var savedChronotype: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    // ✨ NEW: AppStorage to check if working hours are set
    @AppStorage("hasSetWorkingHours") private var hasSetWorkingHours: Bool = false
    
    let bgGradient = LinearGradient(
        colors: [Color(red: 0.10, green: 0.14, blue: 0.21), Color(red: 0.18, green: 0.28, blue: 0.45)],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        if isAnimationDone {
            // --- THE SMART ROUTER FLOW ---
            if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else if savedChronotype.isEmpty {
                QuizView()
                    .transition(.opacity)
            } else if !hasSetWorkingHours {
                // ✨ NEW: Route to Working Hours before the Dashboard
                WorkingHoursView()
                    .transition(.opacity)
            } else {
                if let type = Chronotype(rawValue: savedChronotype) {
                    ContentView(userChronotype: type)
                        .transition(.opacity)
                } else {
                    ContentView(userChronotype: .bear)
                        .transition(.opacity)
                }
            }
        } else {
            // --- SPLASH SCREEN UI ---
            ZStack {
                bgGradient.ignoresSafeArea()
                
                VStack(spacing: 25) {
                    ZStack {
                      
                        Image("icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 170, height: 170)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 8)
                    }
                    .scaleEffect(size)
                    .opacity(opacity)
                    
                    VStack(spacing: 12) {
                        Text("Chrono")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(1)
                        
                        Text("Your body has a rhythm.\nLet’s sync with it.")
                            .font(.system(size: 17, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.65))
                            .lineSpacing(5)
                    }
                    .opacity(opacity)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 1.0)) {
                    self.size = 1.0
                    self.opacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        self.isAnimationDone = true
                    }
                }
            }
        }
    }
}
