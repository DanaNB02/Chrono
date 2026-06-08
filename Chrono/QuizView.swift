import SwiftUI

struct QuizView: View {
    @Environment(\.dismiss) var dismiss
    @State private var viewModel = QuizViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.16, blue: 0.22),
                    Color(red: 0.22, green: 0.32, blue: 0.45)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.currentIndex < viewModel.questions.count && viewModel.finalResult == nil {
                let currentQ = viewModel.questions[viewModel.currentIndex]
                
                VStack(alignment: .leading, spacing: 30) {
                    Button(action: {
                        if viewModel.currentIndex > 0 {
                            viewModel.goBack()
                        } else {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                hasCompletedOnboarding = false
                            }
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
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Question \(viewModel.currentIndex + 1) / \(viewModel.questions.count)")
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
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("answer to what feels more accurate to you")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(currentQ.text)
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .id(viewModel.currentIndex)
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                    .padding(.bottom, 20)
                    
                    VStack(spacing: 16) {
                        ForEach(currentQ.options) { option in
                            QuizOptionButton(
                                title: option.text,
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
                ChronotypeResultView(chronotype: result) {
                    viewModel.confirmAndGoToDashboard()
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                
            } else {
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
