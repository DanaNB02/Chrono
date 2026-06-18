//
//   ContentView.swift
//   Chrono
//
//   Created by Reema on 18/12/1447 AH.
//

import SwiftUI
//import Combine

struct ContentView: View {
    // Passed in from AppStorage Router
    let userChronotype: Chronotype
    
    // MARK: - Energy State
    @State private var dynamicEnergyScore: Double? = nil
    @State private var isLoadingEnergyScore = true
    @State private var showEnergyInfo = false
    @State private var showEnergyInsights = false
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var pullDistance: CGFloat = 0
    @State private var isManualRefreshing = false
    @State private var didJustSync = false
    @State private var lastSyncedAt: Date? = nil
    private let refreshThreshold: CGFloat = 70
    
//    private let energyRefreshTimer = Timer.publish(
//        every: 15 * 60,
//        on: .main,
//        in: .common
//    ).autoconnect()
//
    // MARK: - Logging Sheet State
//    @State private var showLoggingSheet = false
//    @State private var coffeeAmount: Double = 250.0
//    @State private var carbAmount: Double = 100.0
    
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
        guard let score = dynamicEnergyScore else { return .gray }
        return score < 50 ? Color(red: 0.92, green: 0.34, blue: 0.34) : Color(red: 0.35, green: 0.87, blue: 0.65)
    }

    var body: some View {
        ZStack {
            Image(backgroundImageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Fixed Header + Energy Area
                VStack(spacing: 0) {
                    refreshStatusBanner

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

                    Spacer(minLength: 10)

                    if isLoadingEnergyScore {
                        VStack {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                        }
                        .frame(height: 170)
                    } else if let currentScore = dynamicEnergyScore {
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
                                        .contentTransition(.numericText())

                                    Text("%")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.top, 12)
                                }
                            }
                            .frame(width: 170, height: 170)
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    showEnergyInsights = true
                                } label: {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.82))
                                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                                }
                                .buttonStyle(.plain)
                                .offset(x: 8, y: -8)
                            }

                            Text("ENERGY SCORE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.7))

                            if let lastSyncedAt {
                                Text("Last synced " + lastSyncedAt.formatted(date: .omitted, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.58))
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            ZStack(alignment: .topTrailing) {
                                ZStack {
                                    Circle()
                                        .stroke(lineWidth: 18)
                                        .foregroundColor(.white.opacity(0.12))

                                    Circle()
                                        .stroke(style: StrokeStyle(lineWidth: 18, lineCap: .round))
                                        .foregroundColor(.white.opacity(0.05))

                                    HStack(alignment: .top, spacing: 2) {
                                        Text("—")
                                            .font(.system(size: 64, weight: .bold, design: .rounded))
                                            .foregroundColor(.white.opacity(0.45))

                                        Text("%")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white.opacity(0.35))
                                            .padding(.top, 12)
                                    }
                                }
                                .frame(width: 170, height: 170)

                                Button {
                                    showEnergyInfo = true
                                } label: {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.75))
                                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                                }
                                .offset(x: 4, y: -4)
                            }

                            Text("ENERGY SCORE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.45))
                        }
                    }

                    Spacer(minLength: 16)
                }
                .offset(y: pullDistance * 0.18)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            guard !isManualRefreshing else { return }
                            guard value.translation.height > 0 else { return }

                            pullDistance = min(value.translation.height, 110)
                        }
                        .onEnded { value in
                            let shouldRefresh = value.translation.height >= refreshThreshold

                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                pullDistance = 0
                            }

                            if shouldRefresh {
                                Task {
                                    await pullToRefreshEnergyScore()
                                }
                            }
                        }
                )

                // MARK: - Independent Bio-Schedule Scroll
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your Bio-Schedule")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 26)

                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                let currentScoreInt = dynamicEnergyScore != nil ? Int(dynamicEnergyScore!) : nil

                                ForEach(macroActivities) { activity in
                                    BioScheduleCardRow(
                                        activity: activity,
                                        interlapActivities: interlapActivities,
                                        currentScoreInt: currentScoreInt,
                                        lineAccentColor: lineAccentColor
                                    )
                                    .id(activity.id)
                                    .onChange(of: activity.window.contains()) { _, newValue in
                                        if newValue {
                                            refreshEnergyScore(reason: "Chrono Sync - \(activity.title)")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 30)
                        }
                        .onChange(of: dynamicEnergyScore) { _, newValue in
                            guard newValue != nil,
                                  let activeActivity = macroActivities.first(where: { $0.window.contains() })
                            else { return }

                            withAnimation(.spring(response: 0.65, dampingFraction: 0.8)) {
                                proxy.scrollTo(activeActivity.id, anchor: .center)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(.ultraThinMaterial.opacity(0.55))
                .background(Color.white.opacity(0.02))
                .cornerRadius(30, corners: [.topLeft, .topRight])
            }

        }
        .onAppear {
            Task {
                await loadEnergyScoreOnLaunch()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            print("⏰ [System Clock] تم رصد تغيير يدوي في وقت النظام! جاري إعادة تقييم الفترات حيوياً...")
            refreshEnergyScore(reason: "System Clock Sync")
        }
        .alert("Energy Score is Unavailable", isPresented: $showEnergyInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("""
            Score requires:
            • Health permissions
            • Wearing your Apple Watch
            """)
        }
        .sheet(isPresented: $showEnergyInsights) {
            EnergyInsightsSheet(
                insights: healthKitManager.latestInsights,
                currentEnergy: dynamicEnergyScore,
                chronotypeModifier: chronotypeModifier
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    private func loadEnergyScoreOnLaunch() async {
        await MainActor.run {
            self.isLoadingEnergyScore = true
            self.dynamicEnergyScore = nil
        }
        
        print("📱 [App Launch] جاري جلب خط الأساس الأولي للطاقة الصباحية...")
        
        let isAuthorized = await healthKitManager.requestAuthorization()
        
        guard isAuthorized else {
            await MainActor.run {
                withAnimation {
                    self.dynamicEnergyScore = nil
                    self.isLoadingEnergyScore = false
                }
            }
            return
        }
        
        guard let realBaseline = await healthKitManager.calculateLiveEnergyScore() else {
            await MainActor.run {
                withAnimation {
                    self.dynamicEnergyScore = nil
                    self.isLoadingEnergyScore = false
                }
            }
            return
        }
        
        let finalScore = applyChronotypeModifier(to: realBaseline)
        
        await MainActor.run {
            withAnimation {
                self.dynamicEnergyScore = finalScore
                self.isLoadingEnergyScore = false
                self.lastSyncedAt = Date()
                
                print("🎯 [App Launch] تم تعيين الطاقة الصباحية الأولية: \(Int(finalScore))%")
            }
        }
    }

    private func refreshEnergyScore(reason: String) {
        print("🔄 [\(reason)] جاري تحديث ومزامنة البيانات حيوياً...")
        
        Task {
            guard let updatedScore = await healthKitManager.calculateLiveEnergyScore() else {
                print("⚠️ [\(reason)] لا توجد بيانات كافية لتحديث الطاقة.")
                return
            }
            
            let finalScore = applyChronotypeModifier(to: updatedScore)
            
            await MainActor.run {
                withAnimation {
                    self.dynamicEnergyScore = finalScore
                    self.lastSyncedAt = Date()
                    
                    print("✅ [\(reason)] تم تحديث الطاقة: \(Int(finalScore))%")
                }
            }
        }
    }
    
    private func pullToRefreshEnergyScore() async {
        await MainActor.run {
            isManualRefreshing = true
            didJustSync = false
        }

        print("🔄 [Manual Refresh] Syncing latest HealthKit data...")

        guard let updatedScore = await healthKitManager.calculateLiveEnergyScore() else {
            await MainActor.run {
                isManualRefreshing = false
            }
            print("⚠️ [Manual Refresh] Not enough data to update energy.")
            return
        }

        let finalScore = applyChronotypeModifier(to: updatedScore)

        await MainActor.run {
            withAnimation {
                self.dynamicEnergyScore = finalScore
                self.lastSyncedAt = Date()
                self.isManualRefreshing = false
                self.didJustSync = true
                print("✅ [Manual Refresh] Energy updated: \(Int(finalScore))%")
            }
        }

        try? await Task.sleep(for: .seconds(1.8))

        await MainActor.run {
            withAnimation {
                self.didJustSync = false
            }
        }
    }

    @ViewBuilder
    private var refreshStatusBanner: some View {
        if pullDistance > 0 || isManualRefreshing || didJustSync {
            HStack(spacing: 8) {
                if isManualRefreshing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.82)
                } else if didJustSync {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: pullDistance >= refreshThreshold
                          ? "arrow.down.circle.fill"
                          : "arrow.down.circle")
                        .foregroundColor(.white.opacity(0.92))
                }

                Text(isManualRefreshing
                     ? "Syncing Health data..."
                     : didJustSync
                       ? "Health data synced"
                       : pullDistance >= refreshThreshold
                         ? "Release to refresh"
                         : "Pull to refresh")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.96))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial.opacity(0.85))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .clipShape(Capsule())
            .padding(.top, 32)
            .padding(.bottom, 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .allowsHitTesting(false)
        }
    }

    private func applyChronotypeModifier(to baseScore: Double) -> Double {
        return min(
            max(
                baseScore + chronotypeModifier,
                0
            ),
            100
        )
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
    
    private var chronotypeModifier: Double {

        let hour = Calendar.current.component(.hour, from: Date())

        switch userChronotype {

        case .bear:
            switch hour {
            case 9...12: return 5
            case 13...15: return -5
            case 19...21: return 2
            default: return 0
            }

        case .wolf:
            switch hour {
            case 7...10: return -5
            case 16...20: return 5
            default: return 0
            }

        case .lion:
            switch hour {
            case 6...11: return 5
            case 20...23: return -5
            default: return 0
            }

        case .dolphin:
            switch hour {
            case 10...13: return 3
            case 22...23: return -3
            default: return 0
            }
        }
    }
}




struct EnergyInsightsSheet: View {
    let insights: EnergyInsights?
    let currentEnergy: Double?
    let chronotypeModifier: Double

    @Environment(\.dismiss) private var dismiss

    private var chronotypeText: String {
        if chronotypeModifier > 0 {
            return "You are currently in a high-energy window."
        } else if chronotypeModifier < 0 {
            return "You are currently in a lower-energy window."
        } else {
            return "Your current time has a neutral rhythm adjustment."
        }
    }

    private var chronotypeValue: String {
        if chronotypeModifier > 0 {
            return "+\(Int(chronotypeModifier))%"
        } else {
            return "\(Int(chronotypeModifier))%"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let insights {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 22) {

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Current Energy")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text("\(Int(currentEnergy ?? insights.baseEnergy))%")
                                    .font(.system(size: 52, weight: .bold, design: .rounded))

                                Text("Your energy is based on recovery, activity, and your current chronotype window.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            InsightSectionTitle(
                                icon: "sun.max.fill",
                                title: "Morning Recovery",
                                value: "\(Int(insights.morningRecovery))%"
                            )

                            InsightRow(
                                title: "Sleep Score",
                                value: "\(Int(insights.sleepScore))/100",
                                subtitle: "\(Int(insights.sleepMinutes / 60))h \(Int(insights.sleepMinutes.truncatingRemainder(dividingBy: 60)))m sleep"
                            )

                            InsightRow(
                                title: "Duration",
                                value: "\(Int(insights.durationScore))/50",
                                subtitle: "Based on your sleep goal"
                            )

                            InsightRow(
                                title: "Sleep Timing",
                                value: "\(Int(insights.timingScore))/30",
                                subtitle: insights.usesSleepSchedule
                                    ? "Based on your sleep schedule"
                                    : "Neutral score — no sleep schedule set"
                            )

                            InsightRow(
                                title: "Interruptions",
                                value: "\(Int(insights.interruptionScore))/20",
                                subtitle: insights.interruptionScore >= 18
                                    ? "Minimal interruptions detected"
                                    : "Some sleep interruptions were detected"
                            )

                            Divider()

                            InsightSectionTitle(
                                icon: "heart.fill",
                                title: "HRV Readiness",
                                value: "\(Int(insights.hrvReadinessScore))/100"
                            )

                            InsightRow(
                                title: "Heart Rate Variability",
                                value: "\(Int(insights.hrv)) ms",
                                subtitle: "Your usual baseline is \(Int(insights.hrvBaseline)) ms"
                            )

                            Divider()

                            InsightSectionTitle(
                                icon: "flame.fill",
                                title: "Energy Used Today",
                                value: "−\(Int(insights.energyDrain))%"
                            )

                            InsightRow(
                                title: "Active Energy",
                                value: "\(Int(insights.activeCalories)) kcal",
                                subtitle: "Activity gradually reduces today's energy"
                            )

                            Divider()

                            InsightSectionTitle(
                                icon: "clock.fill",
                                title: "Chronotype Adjustment",
                                value: chronotypeValue
                            )

                            Text(chronotypeText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Divider()

                            VStack(spacing: 12) {
                                EnergyMathRow(
                                    title: "Morning Recovery",
                                    value: "\(Int(insights.morningRecovery))%"
                                )

                                EnergyMathRow(
                                    title: "Activity Drain",
                                    value: "−\(Int(insights.energyDrain))%"
                                )

                                EnergyMathRow(
                                    title: "Chronotype Adjustment",
                                    value: chronotypeValue
                                )

                                Divider()

                                EnergyMathRow(
                                    title: "Current Energy",
                                    value: "\(Int(currentEnergy ?? insights.baseEnergy))%",
                                    isBold: true
                                )
                            }
                            .padding(18)
                            .background(Color.secondary.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .padding(24)
                    }
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 42))
                            .foregroundColor(.secondary)

                        Text("Insights are unavailable")
                            .font(.title3.weight(.bold))

                        Text("Sync your Health data to view your energy breakdown.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(30)
                }
            }
            .navigationTitle("Energy Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InsightSectionTitle: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.headline)

            Spacer()

            Text(value)
                .font(.headline.weight(.bold))
        }
    }
}

struct InsightRow: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(value)
                .font(.subheadline.weight(.bold))
        }
    }
}

struct EnergyMathRow: View {
    let title: String
    let value: String
    var isBold: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(isBold ? .headline : .subheadline)

            Spacer()

            Text(value)
                .font(isBold ? .headline.weight(.bold) : .subheadline.weight(.bold))
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
            (a, r, g, b) = (
                int >> 24,
                (int >> 16) & 0xFF,
                (int >> 8) & 0xFF,
                int & 0xFF
            )
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
