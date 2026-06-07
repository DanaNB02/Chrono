//
//  QuizView.swift
//  Chrono
//
//  Created by Dana on 18/12/1447 AH.
//

import SwiftUI

struct QuizView: View {
    @Environment(\.dismiss) var dismiss
    
    // Using @State because your ViewModel uses the modern @Observable macro
    @State private var viewModel = QuizViewModel()
    
    var body: some View {
        ZStack {
            // 1. The Dark Gradient Background
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.16, blue: 0.22),
                    Color(red: 0.22, green: 0.32, blue: 0.45)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Safety check: Only show the quiz if we haven't finished
            if viewModel.currentIndex < viewModel.questions.count && viewModel.finalResult == nil {
                
                let currentQ = viewModel.questions[viewModel.currentIndex]
                
                VStack(alignment: .leading, spacing: 30) {
                    
                    // 2. Custom Back Button
                    Button(action: {
                        if viewModel.currentIndex > 0 {
                            viewModel.goBack()
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .padding(.top, 10)
                    
                    // 3. Progress Indicator
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Question \(viewModel.currentIndex + 1) \\ \(viewModel.questions.count)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 6)
                                
                                Capsule()
                                    .fill(Color.white)
                                    .frame(
                                        width: geometry.size.width * CGFloat(viewModel.currentIndex + 1) / CGFloat(viewModel.questions.count),
                                        height: 6
                                    )
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentIndex)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.bottom, 10)
                    
                    // 4. Dynamic Question Text
                    VStack(alignment: .leading, spacing: 12) {
                        Text("answer to what feels more accurate to you")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(currentQ.text)
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .id(viewModel.currentIndex) // Forces a clean fade animation when text changes
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                    .padding(.bottom, 20)
                    
                    // 5. Dynamic Answer Buttons
                    VStack(spacing: 16) {
                        // Loops through the options and creates exactly the right number of buttons
                        ForEach(currentQ.options) { option in
                            QuizOptionButton(
                                title: option.text,
                                // Give visual feedback if this specific button was just tapped
                                isSelected: viewModel.selectedOptionId == option.id
                            ) {
                                viewModel.selectOption(option: option)
                            }
                        }
                    }
                    
                    Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                } else if let result = viewModel.finalResult {
                                    
                                    // BOOM: Show the glorious result page instead of a spinner!
                                    ChronotypeResultView(chronotype: result) {
                                        // When you tap "Continue" on the result page, THEN it dismisses back to your dashboard
                                        dismiss()
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    
                                } else {
                                    // Just a micro-second fallback while it calculates
                                    VStack {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(1.5)
                                    }
                                }
                            }
                            .navigationBarHidden(true)
                        }
                    }
// MARK: - Reusable Custom Button Component
struct QuizOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .black : .white)
                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(height: 64)
            // Changes color slightly when tapped to give the user feedback
            .background(isSelected ? Color.white : Color(red: 0.30, green: 0.34, blue: 0.40))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

#Preview {
    QuizView()
}
