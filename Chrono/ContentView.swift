//
//   ContentView.swift
//   Chrono
//
//   Created by Reema on 18/12/1447 AH.
//

import SwiftUI

struct ContentView: View {
    // Passed in from AppStorage Router
    let userChronotype: Chronotype
    
    @State private var mockEnergyScore: Double? = nil
    @StateObject private var healthKitManager = HealthKitManager()
    
    // MARK: - Isolated Sub-expressions for Scope and Compiler Health
    
    private var allActivities: [ChronotypeActivity] {
        ScheduleEngine.getFullSchedule(for: userChronotype)
    }
    
    private var macroActivities: [ChronotypeActivity] {
        allActivities.filter { !$0.isInterlap }
    }
    
    private var interlapActivities: [ChronotypeActivity] {
        allActivities.filter { $0.isInterlap }
    }
    
    // Dynamic Day of the Week
    var currentDayString: String {
        Date().formatted(.dateTime.weekday(.wide))
    }
    
    // Dynamic Greeting Logic
    var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0...11:  return "Good Morning"
        case 12...16: return "Good Afternoon"
        default:      return "Good Evening"
        }
    }
    
    // Dynamic Ring Color Logic
    var ringColor: Color {
        guard let score = mockEnergyScore else { return .gray }
        return score < 50 ? Color(red: 0.92, green: 0.34, blue: 0.34) : Color(red: 0.35, green: 0.87, blue: 0.65)
    }

    var body: some View {
        ZStack {
            // 1. YOUR ORIGINAL FIGMA BACKGROUND IMAGE
            Image(backgroundImageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - HEADER
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentDayString)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(greetingMessage)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // The Custom Figma Asset Profile Button at top right
                    Image(emojiImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 65, height: 65)
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 4)
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                // MARK: - ENERGY RING
                Spacer(minLength: 16)
                
                if let currentScore = mockEnergyScore {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 18)
                                .opacity(0.2)
                                .foregroundColor(ringColor)
                            
                            Circle()
                                .trim(from: 0.0, to: CGFloat(currentScore) / 100.0)
                                .stroke(style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
                                .foregroundColor(ringColor)
                                .rotationEffect(Angle(degrees: 270.0))
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentScore)
                            
                            HStack(alignment: .top, spacing: 2) {
                                Text("\(Int(currentScore))")
                                    .font(.system(size: 64, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.top, 12)
                            }
                        }
                        .frame(width: 170, height: 170)
                        
                        Text("ENERGY SCORE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    VStack {
                        ProgressView().tint(.white).scaleEffect(1.5)
                    }
                    .frame(height: 170)
                }
                
                Spacer(minLength: 16)
                
                // MARK: - BIO-SCHEDULE BOTTOM CONTAINER CARD
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your Bio-Schedule")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 30)
                    
                    ScrollView(showsIndicators: false) {
                        ScrollViewReader { proxy in
                            VStack(spacing: 16) {
                                let currentScoreInt = mockEnergyScore != nil ? Int(mockEnergyScore!) : nil
                                
                                ForEach(macroActivities) { activity in
                                    BioScheduleCardRow(
                                        activity: activity,
                                        interlapActivities: interlapActivities,
                                        currentScoreInt: currentScoreInt,
                                        lineAccentColor: lineAccentColor
                                    )
                                    .id(activity.id)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 30)
                            .onChange(of: mockEnergyScore) { newValue in
                                if newValue != nil {
                                    if let activeActivity = macroActivities.first(where: { $0.window.contains() }) {
                                        withAnimation(.spring(response: 0.65, dampingFraction: 0.8)) {
                                            proxy.scrollTo(activeActivity.id, anchor: .center)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial.opacity(0.55))
                .background(Color.white.opacity(0.02))
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .onAppear {
            Task {
                let authorized = await healthKitManager.requestAuthorization()
                if authorized {
                    if let baseline = await healthKitManager.calculateMorningBaseline() {
                        await MainActor.run {
                            self.mockEnergyScore = baseline
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Themes & Assets
    
    private var backgroundImageName: String {
        switch userChronotype {
        case .dolphin: return "bg_dolphin"
        case .wolf:    return "bg_wolf"
        case .bear:    return "bg_bear"
        case .lion:    return "bg_lion"
        }
    }
    
    private var lineAccentColor: Color {
        switch userChronotype {
        case .lion:    return Color(red: 0.98, green: 0.62, blue: 0.06)
        case .bear:    return Color(red: 0.68, green: 0.41, blue: 0.23)
        case .wolf:    return Color(red: 0.55, green: 0.45, blue: 0.92)
        case .dolphin: return Color(red: 0.22, green: 0.68, blue: 0.84)
        }
    }
    
    private var emojiImageName: String {
        switch userChronotype {
        case .dolphin: return "dolphin_emoji"
        case .wolf:    return "wolf_emoji"
        case .bear:    return "bear_emoji"
        case .lion:    return "lion_emoji"
        }
    }
}

// MARK: - EXTRACTED ROW VIEW COMPONENT

struct BioScheduleCardRow: View {
    let activity: ChronotypeActivity
    let interlapActivities: [ChronotypeActivity]
    let currentScoreInt: Int?
    let lineAccentColor: Color
    
    var body: some View {
        let isCurrentlyActive = activity.window.contains()
        let derivedSuggestion = activity.getSuggestion(actualEnergyScore: currentScoreInt)
        let activeNestedItems = interlapActivities.filter { isCurrentlyActive && $0.window.contains() }
        
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text(activity.window.displayString)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(isCurrentlyActive ? .white : .white.opacity(0.4))
                
                Spacer(minLength: 16)
                
                Text(activity.category.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(lineAccentColor.opacity(isCurrentlyActive ? 0.4 : 0.15))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            
            Text(activity.title)
                .font(isCurrentlyActive ? .system(size: 22, weight: .bold) : .system(size: 18, weight: .bold))
                .foregroundColor(isCurrentlyActive ? .white : .white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            
            ForEach(activeNestedItems) { childItem in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 5, height: 5)
                    
                    Text("\(childItem.window.displayString.lowercased()) \(childItem.title.lowercased())")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .padding(.top, 2)
            }
            
            if isCurrentlyActive {
                HStack(alignment: .top, spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(lineAccentColor)
                        .frame(width: 3, height: 38)
                    
                    Text(derivedSuggestion)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(isCurrentlyActive ? AnyShapeStyle(.thinMaterial.opacity(0.4)) : AnyShapeStyle(Color.white.opacity(0.02)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isCurrentlyActive ? Color.white.opacity(0.25) : Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - LAYER CORNER CLIPPING EXTENSIONS

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

// MARK: - UTILITIES

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 7:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 1)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
