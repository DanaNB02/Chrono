//
//  ContentView.swift
//  Chrono
//
//  Created by Dana on 18/12/1447 AH.
//

import SwiftUI

struct ContentView: View {
    // Passed in from AppStorage Router
    let userChronotype: Chronotype
    
    @State private var mockEnergyScore: Double? = nil
    @StateObject private var healthKitManager = HealthKitManager()
    
    // MARK: - Logging Sheet State
    @State private var showLoggingSheet = false
    @State private var coffeeAmount: Double = 250.0
    @State private var carbAmount: Double = 100.0
    
    // Dynamic Day of the Week
    var currentDayString: String {
        Date().formatted(.dateTime.weekday(.wide))
    }
    
    // Dynamic Ring Color Logic
    var ringColor: Color {
        guard let score = mockEnergyScore else { return .gray }
        return score < 50 ? Color(red: 0.92, green: 0.34, blue: 0.34) : Color(red: 0.35, green: 0.87, blue: 0.65)
    }

    var body: some View {
        ZStack {
            // 1. Dynamic Background based on Chronotype
            LinearGradient(
                colors: themeColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - HEADER
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentDayString)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                        Text("Good Morning")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // 2. The Animal Button (Triggers the Logging Sheet)
                    Button(action: { showLoggingSheet = true }) {
                        Text(emoji)
                            .font(.system(size: 40))
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60) // Clears the Dynamic Island safely
                
                // MARK: - ENERGY RING
                Spacer(minLength: 16) // Tight gap to prevent clipping
                
                if let currentScore = mockEnergyScore {
                    VStack(spacing: 16) {
                        ZStack {
                            // Background Track
                            Circle()
                                .stroke(lineWidth: 18) // Thinner line
                                .opacity(0.2)
                                .foregroundColor(ringColor)
                            
                            // Progress Fill
                            Circle()
                                .trim(from: 0.0, to: CGFloat(currentScore) / 100.0)
                                .stroke(style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
                                .foregroundColor(ringColor)
                                .rotationEffect(Angle(degrees: 270.0))
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentScore)
                            
                            // Score Text
                            HStack(alignment: .top, spacing: 2) {
                                Text("\(Int(currentScore))")
                                    .font(.system(size: 64, weight: .bold, design: .rounded)) // Smaller number
                                    .foregroundColor(.white)
                                    .contentTransition(.numericText())
                                Text("%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.top, 12)
                            }
                        }
                        .frame(width: 170, height: 170) // Scaled down completely
                        
                        Text("ENERGY SCORE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    // Loading or Empty State
                    VStack {
                        ProgressView().tint(.white).scaleEffect(1.5)
                    }
                    .frame(height: 170)
                }
                
                Spacer(minLength: 16) // Tight gap to prevent clipping
                
                // MARK: - BIO-SCHEDULE CARD
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your Bio-Schedule")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 30)
                    
                    VStack(spacing: 16) { // Tightened spacing
                        
                        BioScheduleRow(title: "Cold rinse", timeRange: "6:30 AM - 8:00 AM", tag: "Morning", suggestion: nil, isActive: false)
                        
                        BioScheduleRow(title: "Single coffee", timeRange: "9:00 AM - 10:30 AM", tag: "Boost", suggestion: nil, isActive: false)
                        
                        // The Active Demo Block!
                        BioScheduleRow(
                            title: "Focus window",
                            timeRange: "11:00 AM - 1:00 PM",
                            tag: "Deep Work",
                            suggestion: "Your score is 94%. High energy detected. Tackle your hardest coding problems right now.",
                            isActive: true
                        )
                        
                        BioScheduleRow(title: "Light workout", timeRange: "3:00 PM - 5:00 PM", tag: "Fitness", suggestion: nil, isActive: false)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20) // Shrunk bottom padding so it doesn't clip
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(cardColor)
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .task {
            // Fetch Health Data on Load
            let isAuthorized = await healthKitManager.requestAuthorization()
            if isAuthorized {
                if let realBaseline = await healthKitManager.calculateMorningBaseline() {
                    withAnimation { mockEnergyScore = realBaseline }
                }
            }
        }
        // MARK: - THE LOGGING SHEET
        .sheet(isPresented: $showLoggingSheet) {
            LoggingSheetView(
                coffeeAmount: $coffeeAmount,
                carbAmount: $carbAmount,
                onLogCoffee: { logExactCoffee() },
                onLogCarbs: { logExactCarbs() }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Math Engines
    private func logExactCoffee() {
        let pointsToAdd = (coffeeAmount / 250.0) * 15.0
        adjustEnergy(by: pointsToAdd)
        showLoggingSheet = false
    }
    
    private func logExactCarbs() {
        let pointsToSubtract = (carbAmount / 100.0) * -10.0
        adjustEnergy(by: pointsToSubtract)
        showLoggingSheet = false
    }
    
    private func adjustEnergy(by amount: Double) {
        guard let currentScore = mockEnergyScore else { return }
        withAnimation {
            let newScore = currentScore + amount
            mockEnergyScore = min(max(newScore, 0.0), 100.0)
        }
    }
    
    // MARK: - Theme Helpers matched to your custom UI
    
    private var themeColors: [Color] {
        switch userChronotype {
        case .dolphin: return [Color(red: 0.0, green: 0.45, blue: 0.62), Color(red: 0.0, green: 0.32, blue: 0.48)]
        case .wolf: return [Color(red: 0.18, green: 0.14, blue: 0.36), Color(red: 0.14, green: 0.10, blue: 0.28)]
        case .bear: return [Color(red: 0.45, green: 0.28, blue: 0.15), Color(red: 0.35, green: 0.20, blue: 0.10)]
        case .lion: return [Color(red: 0.98, green: 0.72, blue: 0.15), Color(red: 0.92, green: 0.62, blue: 0.06)]
        }
    }
    
    private var cardColor: Color {
        switch userChronotype {
        case .dolphin: return Color(red: 0.0, green: 0.25, blue: 0.38)
        case .wolf: return Color(red: 0.12, green: 0.09, blue: 0.24)
        case .bear: return Color(red: 0.28, green: 0.16, blue: 0.08)
        case .lion: return Color(red: 0.88, green: 0.58, blue: 0.05)
        }
    }
    
    private var emoji: String {
        switch userChronotype {
        case .dolphin: return "🐬"
        case .wolf: return "🐺"
        case .bear: return "🐻"
        case .lion: return "🦁"
        }
    }
}

// MARK: - Subviews

struct BioScheduleRow: View {
    let title: String
    let timeRange: String
    let tag: String
    let suggestion: String?
    let isActive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // Top Row: Time Range & Tag Pill
            HStack {
                Text(timeRange)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(isActive ? .white : .white.opacity(0.5))
                
                Spacer()
                
                Text(tag)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isActive ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
                    .foregroundColor(isActive ? .white : .white.opacity(0.5))
                    .clipShape(Capsule())
            }
            
            // Title
            Text(title)
                .font(isActive ? .title2 : .title3)
                .fontWeight(.bold)
                .foregroundColor(isActive ? .white : .white.opacity(0.8))
            
            // Suggestion (Only renders if the block is active and has text)
            if isActive, let activeSuggestion = suggestion {
                Text(activeSuggestion)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    // THIS is the magic modifier that forces text to wrap instead of cutting off
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
                    .padding(.top, 2)
            }
        }
        .padding(isActive ? 16 : 0)
        .background(isActive ? Color.white.opacity(0.15) : Color.clear)
        .cornerRadius(20)
        .padding(.horizontal, isActive ? 0 : 16)
    }
}

// The UI for the Bottom Sheet
struct LoggingSheetView: View {
    @Binding var coffeeAmount: Double
    @Binding var carbAmount: Double
    var onLogCoffee: () -> Void
    var onLogCarbs: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chemical Boost")) {
                    Stepper("\(Int(coffeeAmount)) ml Coffee", value: $coffeeAmount, in: 0...1000, step: 50)
                    Button("Log Coffee", action: onLogCoffee)
                        .foregroundColor(.blue)
                }
                
                Section(header: Text("Digestive Drag")) {
                    Stepper("\(Int(carbAmount)) g Carbs", value: $carbAmount, in: 0...500, step: 10)
                    Button("Log Meal", action: onLogCarbs)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Log Modifiers")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Extension to round specific corners for the bottom card
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
