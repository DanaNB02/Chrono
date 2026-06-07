//
//  ContentView.swift
//  Chrono
//
//  Created by Dana on 18/12/1447 AH.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - Live Data
    let userChronotype: Chronotype
    
    // Changed to an Optional Double. 'nil' means no permissions or no data.
    @State private var mockEnergyScore: Double? = nil
    
    @StateObject private var healthKitManager = HealthKitManager()
    
    // MARK: - Popup State Variables
        @State private var showCoffeeSheet = false
        @State private var coffeeAmount: Double = 250.0
        
        @State private var showCarbSheet = false
        @State private var carbAmount: Double = 100.0
    
    var dailySchedule: [ChronotypeActivity] {
        ScheduleEngine.getFullSchedule(for: userChronotype)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                
                // Header
                Text("\(userChronotype.rawValue) Schedule")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // MARK: - DYNAMIC UI STATE
                if let currentScore = mockEnergyScore {
                    // SHOW RING IF WE HAVE A SCORE
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 20)
                            .opacity(0.2)
                            .foregroundColor(.blue)
                        
                        Circle()
                            .trim(from: 0.0, to: CGFloat(currentScore) / 100.0)
                            .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                            .foregroundColor(.blue)
                            .rotationEffect(Angle(degrees: 270.0))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentScore)
                        
                        VStack(spacing: 4) {
                            Text("\(Int(currentScore))")
                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                            Text("Energy Score")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 200, height: 200)
                    
                    // CONTEXTUAL MODIFIERS
                    VStack(alignment: .leading, spacing: 12) {
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                    
                                    // 1. Exact Coffee
                                    Button(action: {
                                        coffeeAmount = 250.0 // Reset to default
                                        showCoffeeSheet = true
                                    }) {
                                        ModifierButtonView(icon: "cup.and.saucer.fill", title: "Coffee")
                                    }
                                    
                                    // 2. Exact Carbs
                                    Button(action: {
                                        carbAmount = 100.0 // Reset to default
                                        showCarbSheet = true
                                    }) {
                                        ModifierButtonView(icon: "fork.knife", title: "Carbs")
                                    }
                                    
                                }
                                .padding(.horizontal, 20)
                        }
                    }
                } else {
                    // SHOW EMPTY STATE IF NO PERMISSION / NO DATA
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Health Data Unavailable")
                            .font(.headline)
                        Text("Allow Chrono to read your sleep and heart rate data in the Health app to calculate your energy.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(height: 200)
                }
                
                // MARK: - DEMO OVERRIDE SLIDER
                VStack(spacing: 8) {
                    
                    // Binds the slider so moving it safely forces a score
                    Slider(value: Binding(
                        get: { mockEnergyScore ?? 0.0 },
                        set: { mockEnergyScore = $0 }
                    ), in: 0...100, step: 1)
                    .tint(.purple)
                }
                .padding(.horizontal, 40)
                
                // MARK: - The Daily Timeline
                VStack(alignment: .leading, spacing: 20) {
                    Text("TODAY'S AGENDA")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundColor(.secondary)
                        .kerning(1.2)
                        .padding(.horizontal, 20)
                    
                    ForEach(dailySchedule) { activity in
                        // Pass either the score, or 0 if nil so the rows don't crash
                        ActivityRowView(activity: activity, currentEnergyScore: Int(mockEnergyScore ?? 0))
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .task {
            let isAuthorized = await healthKitManager.requestAuthorization()
            if isAuthorized {
                let realBaseline = await healthKitManager.calculateMorningBaseline()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    mockEnergyScore = realBaseline
                }
            }
        }
        // Attach these directly below your .background modifier, right above .task
                .sheet(isPresented: $showCoffeeSheet) {
                    VStack(spacing: 24) {
                        Text("Log Coffee")
                            .font(.headline)
                        
                        // The Stepper handles the + and - buttons automatically
                        Stepper("\(Int(coffeeAmount)) ml", value: $coffeeAmount, in: 0...1000, step: 50)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            logExactCoffee()
                            showCoffeeSheet = false
                        }) {
                            Text("Log Drink")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }
                    .presentationDetents([.height(250)]) // Keeps it as a sleek bottom popup
                    .presentationDragIndicator(.visible)
                }
                
                .sheet(isPresented: $showCarbSheet) {
                    VStack(spacing: 24) {
                        Text("Log Carbs")
                            .font(.headline)
                        
                        Stepper("\(Int(carbAmount)) g", value: $carbAmount, in: 0...500, step: 10)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            logExactCarbs()
                            showCarbSheet = false
                        }) {
                            Text("Log Meal")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }
                    .presentationDetents([.height(250)])
                    .presentationDragIndicator(.visible)
                }
    }
    
    // MARK: - Math Logic
    private func adjustEnergy(by amount: Double) {
        guard let currentScore = mockEnergyScore else { return }
        withAnimation {
            let newScore = currentScore + amount
            mockEnergyScore = min(max(newScore, 0.0), 100.0)
        }
    }
    
    // MARK: - Exact Math Calculators
        private func logExactCoffee() {
            // The Math: (Input ml / 250 standard ml) * 15 points
            let pointsToAdd = (coffeeAmount / 250.0) * 15.0
            adjustEnergy(by: pointsToAdd)
        }
        
        private func logExactCarbs() {
            // The Math: (Input grams / 100 standard grams) * -10 points
            let pointsToSubtract = (carbAmount / 100.0) * -10.0
            adjustEnergy(by: pointsToSubtract)
        }
}

// MARK: - Modifier Button UI Component
struct ModifierButtonView: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .foregroundColor(.primary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}


// MARK: - Reusable Row Component (Unchanged)
struct ActivityRowView: View {
    let activity: ChronotypeActivity
    let currentEnergyScore: Int
    
    var isActiveRightNow: Bool {
        activity.window.contains(date: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(activity.window.displayString)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(isActiveRightNow ? .blue : .secondary)
                
                Spacer()
                
                Text(activity.category.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isActiveRightNow ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                    .foregroundColor(isActiveRightNow ? .blue : .secondary)
                    .clipShape(Capsule())
            }
            
            Text(activity.title)
                .font(.headline)
                .fontWeight(isActiveRightNow ? .heavy : .semibold)
            
            if isActiveRightNow {
                Text(activity.getSuggestion(actualEnergyScore: currentEnergyScore))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(isActiveRightNow ? Color(UIColor.secondarySystemGroupedBackground) : Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .opacity(isActiveRightNow ? 1.0 : 0.6)
    }
}

#Preview {
    ContentView(userChronotype: .bear)
}

