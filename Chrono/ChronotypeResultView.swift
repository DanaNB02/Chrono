//
//  ChronotypeResultView.swift
//  Chrono
//
//  Created by Dana on 21/12/1447 AH.
//

import SwiftUI

struct ChronotypeResultView: View {
    // The result passed from the Quiz
    let chronotype: Chronotype
    
    @Environment(\.dismiss) var dismiss
    
    // This allows the parent view to handle the navigation when "Continue" is tapped
    var onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // 1. Dynamic Background Gradient
            LinearGradient(
                colors: themeColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // 2. Custom Back Button
                HStack {
                    Button(action: { dismiss() }) {
//                        Image(systemName: "chevron.left")
//                            .font(.title3)
//                            .fontWeight(.semibold)
//                            .foregroundColor(.white)
//                            .frame(width: 44, height: 44)
//                            .background(Color.white.opacity(0.15))
//                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                Spacer()
                
                // 3. Main Center Content
                VStack(spacing: 16) {
                    Text("YOU ARE A")
                        .font(.subheadline)
                        .tracking(2) // Adds premium letter spacing
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(emoji)
                        .font(.system(size: 110))
                        .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 10)
                        .padding(.bottom, 8)
                    
                    Text(titleText)
                        .font(.system(size: 60, weight: .heavy, design: .default))
                        .foregroundColor(.white)
                    
                    Text(descriptionText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(6)
                }
                
                Spacer()
                
                // 4. Continue Button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Dynamic Theme Engine
    // Automatically updates the UI based on the Chronotype
    
    private var themeColors: [Color] {
        switch chronotype {
        case .dolphin:
            return [Color(red: 0.10, green: 0.45, blue: 0.60), Color(red: 0.05, green: 0.20, blue: 0.30)]
        case .wolf:
            return [Color(red: 0.20, green: 0.15, blue: 0.35), Color(red: 0.10, green: 0.10, blue: 0.20)]
        case .bear:
            return [Color(red: 0.35, green: 0.20, blue: 0.10), Color(red: 0.20, green: 0.12, blue: 0.05)]
        case .lion:
            return [Color(red: 0.95, green: 0.65, blue: 0.15), Color(red: 0.85, green: 0.40, blue: 0.05)]
        }
    }
    
    private var emoji: String {
        switch chronotype {
        case .dolphin: return "🐬"
        case .wolf: return "🐺"
        case .bear: return "🐻"
        case .lion: return "🦁"
        }
    }
    
    private var titleText: String {
        switch chronotype {
        case .dolphin: return "DOLPHIN"
        case .wolf: return "WOLF"
        case .bear: return "BEAR"
        case .lion: return "LION"
        }
    }
    
    private var descriptionText: String {
        switch chronotype {
        case .dolphin:
            return "Light sleeper, perfectionist, intelligent. Peak focus mid-morning, mindful evenings are your superpower."
        case .wolf:
            return "Creative, introspective, late-peaking. Your prime hours are 5 PM – 10 PM — design your day around them."
        case .bear:
            return "Steady energy, social, sun aligned. Most productivity late morning. You make up 50% of the population."
        case .lion:
            return "Early rising, optimistic and most focused before noon. Your peak hours are 6 AM - 12 PM. Protect them."
        }
    }
}

// MARK: - Previews for testing all 4 variations instantly
#Preview("Dolphin") { ChronotypeResultView(chronotype: .dolphin, onContinue: {}) }
#Preview("Wolf") { ChronotypeResultView(chronotype: .wolf, onContinue: {}) }
#Preview("Bear") { ChronotypeResultView(chronotype: .bear, onContinue: {}) }
#Preview("Lion") { ChronotypeResultView(chronotype: .lion, onContinue: {}) }
