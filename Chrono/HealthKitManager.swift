//
//  HealthKitManager.swift
//  Chrono
//
//  Updated Energy Formula:
//  Morning Recovery + Energy Drain
//

import Foundation
import HealthKit
import Combine

struct SleepScoreResult {
    let totalScore: Double
    let durationScore: Double
    let timingScore: Double
    let interruptionScore: Double
    let sleepMinutes: Double
    let usesTiming: Bool
}



// Raw HealthKit sleep data only.
// This does not classify a block as "night sleep" or a "nap".
struct SleepBlock: Identifiable {
    let id = UUID()

    let start: Date
    let end: Date
    let asleepMinutes: Double
    let awakeMinutes: Double
    let sources: [String]

    var windowMinutes: Double {
        end.timeIntervalSince(start) / 60.0
    }
}
struct SleepEvent: Identifiable, Codable {
let id: String
let start: Date
let end: Date
let asleepMinutes: Double
let awakeMinutes: Double
let sources: [String]
}

struct EnergyInsights {
    let sleepScore: Double
    let sleepMinutes: Double
    let durationScore: Double
    let timingScore: Double
    let interruptionScore: Double
    let usesSleepSchedule: Bool

    let hrv: Double
    let hrvBaseline: Double
    let hrvReadinessScore: Double

    let morningRecovery: Double
    let activeCalories: Double
    let energyDrain: Double
    let baseEnergy: Double
}


class HealthKitManager: ObservableObject {

    let healthStore = HKHealthStore()
    @Published private(set) var latestInsights: EnergyInsights?
    @Published private(set) var savedSleepEvents: [SleepEvent] = []

    private let sleepEventsStorageKey = "chrono.savedSleepEvents"

    // MARK: - Health Types to Read
    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let activeCaloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let typesToRead: Set<HKObjectType> = [
            sleepType,
            hrvType,
            activeCaloriesType
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            return true
        } catch {
            print("HealthKit Authorization Failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Energy Score

    func calculateLiveEnergyScore() async -> Double? {
    #if targetEnvironment(simulator)
    print("ℹ️ [HealthKit Engine] Running on Simulator - Returning empty/nil to trigger empty state.")
    return nil
    #else

    print("\n📊 [HealthKit Engine] Calculating Energy Bank...")

    let now = Date()
    let calendar = Calendar.current

    let sleepStart = calendar.date(
        byAdding: .hour,
        value: -24,
        to: now
    )!

    let thirtySixHoursAgo = calendar.date(
        byAdding: .hour,
        value: -36,
        to: now
    )!

    let fourteenDaysAgo = calendar.date(
        byAdding: .day,
        value: -14,
        to: now
    )!

    let sleepPredicate = HKQuery.predicateForSamples(
        withStart: sleepStart,
        end: now,
        options: []
    )

    let hrvRecentPredicate = HKQuery.predicateForSamples(
        withStart: thirtySixHoursAgo,
        end: now,
        options: []
    )

    let hrvBaselinePredicate = HKQuery.predicateForSamples(
        withStart: fourteenDaysAgo,
        end: now,
        options: []
    )

    let todayPredicate = HKQuery.predicateForSamples(
        withStart: calendar.startOfDay(for: now),
        end: now,
        options: []
    )

    let sleepBlocks = await fetchSleepBlocks(
        predicate: sleepPredicate
    )

    printSleepBlocks(sleepBlocks)

    let newSleepEvents = saveNewSleepEvents(
        from: sleepBlocks
    )

    if !newSleepEvents.isEmpty {
        print("🌙 [Sleep Events] New events saved: \(newSleepEvents.count)")
    }

    let completedBlocks = sleepBlocks.filter {
        $0.end <= now
    }

    let hrvValue = await fetchLastHRV(
        predicate: hrvRecentPredicate
    )

    let hrvBaseline = await fetchAverageHRV(
        predicate: hrvBaselinePredicate
    )

    let activeCalories = await fetchTodayActiveCalories(
        predicate: todayPredicate
    ) ?? 0.0

    guard !completedBlocks.isEmpty,
          let hrvActual = hrvValue,
          let baseline = hrvBaseline,
          baseline > 0 else {

        print("🚨 [Energy Bank] Not enough Health data.")
        print("   Sleep blocks: \(completedBlocks.count)")
        print("   HRV available: \(hrvValue != nil)")
        print("   Baseline available: \(hrvBaseline != nil)")

        await MainActor.run {
            self.latestInsights = nil
        }

        return nil
    }

    let totalSleepMinutes = completedBlocks.reduce(0.0) {
        $0 + $1.asleepMinutes
    }

    let totalAwakeMinutes = completedBlocks.reduce(0.0) {
        $0 + $1.awakeMinutes
    }

    // Temporary product target for the MVP.
    // Later this becomes the user's selected sleep goal.
    let sleepGoalMinutes = 480.0

    let durationPoints = min(
        (totalSleepMinutes / sleepGoalMinutes) * 50.0,
        50.0
    )

    let totalSleepWindow = totalSleepMinutes + totalAwakeMinutes

    let continuityPoints: Double

    if totalSleepWindow > 0 {
        continuityPoints = min(
            (totalSleepMinutes / totalSleepWindow) * 20.0,
            20.0
        )
    } else {
        continuityPoints = 0
    }

    let hrvReadiness = min(
        max(hrvActual / baseline, 0.0),
        1.2
    )

    let hrvPoints = min(
        hrvReadiness * 30.0,
        30.0
    )

    let sleepRecharge = durationPoints + continuityPoints
    let recovery = sleepRecharge + hrvPoints

    let energyDrain = activeCalories / 25.0

    let energyBank = min(
        max(recovery - energyDrain, 0.0),
        100.0
    )

    print("--------- 🔋 Energy Bank Report ---------")
    print("🌙 Completed sleep blocks: \(completedBlocks.count)")
    print("💤 Total sleep: \(Int(totalSleepMinutes)) min")
    print("⏰ Total awake: \(Int(totalAwakeMinutes)) min")
    print("🔋 Sleep Recharge: \(Int(sleepRecharge))/70")
    print("❤️ HRV: \(Int(hrvActual)) ms")
    print("📈 HRV Baseline: \(Int(baseline)) ms")
    print("🫀 HRV Contribution: \(Int(hrvPoints))/30")
    print("🔥 Active Calories: \(Int(activeCalories)) kcal")
    print("📉 Energy Drain: \(Int(energyDrain))")
    print("🎯 Energy Bank: \(Int(energyBank))%")
    print("-----------------------------------------")

    let insights = EnergyInsights(
        sleepScore: sleepRecharge,
        sleepMinutes: totalSleepMinutes,
        durationScore: durationPoints,
        timingScore: 0,
        interruptionScore: continuityPoints,
        usesSleepSchedule: false,
        hrv: hrvActual,
        hrvBaseline: baseline,
        hrvReadinessScore: hrvReadiness * 100.0,
        morningRecovery: recovery,
        activeCalories: activeCalories,
        energyDrain: energyDrain,
        baseEnergy: energyBank
    )

    await MainActor.run {
        self.latestInsights = insights
    }

    return energyBank

    #endif

    }
    private func saveNewSleepEvents(
        from blocks: [SleepBlock]
    ) -> [SleepEvent] {

        let existingEvents = loadSavedSleepEvents()
        let existingIDs = Set(existingEvents.map(\.id))

        let newEvents = blocks.compactMap { block -> SleepEvent? in
            guard block.end <= Date() else { return nil }

            let sourceKey = block.sources
                .sorted()
                .joined(separator: "|")

            let eventID =
                "\(Int(block.start.timeIntervalSince1970))" +
                "_\(Int(block.end.timeIntervalSince1970))" +
                "_\(sourceKey)"

            guard !existingIDs.contains(eventID) else {
                return nil
            }

            return SleepEvent(
                id: eventID,
                start: block.start,
                end: block.end,
                asleepMinutes: block.asleepMinutes,
                awakeMinutes: block.awakeMinutes,
                sources: block.sources
            )
        }

        guard !newEvents.isEmpty else {
            self.savedSleepEvents = existingEvents
            return []
        }

        let updatedEvents = (existingEvents + newEvents)
            .sorted { $0.start < $1.start }

        saveSleepEvents(updatedEvents)

        self.savedSleepEvents = updatedEvents

        return newEvents
    }

    private func loadSavedSleepEvents() -> [SleepEvent] {
        guard let data = UserDefaults.standard.data(
            forKey: sleepEventsStorageKey
        ) else {
            return []
        }

        do {
            return try JSONDecoder().decode(
                [SleepEvent].self,
                from: data
            )
        } catch {
            print("⚠️ Could not load saved sleep events.")
            return []
        }
    }

    private func saveSleepEvents(
        _ events: [SleepEvent]
    ) {
        do {
            let data = try JSONEncoder().encode(events)

            UserDefaults.standard.set(
                data,
                forKey: sleepEventsStorageKey
            )
        } catch {
            print("⚠️ Could not save sleep events.")
        }
    }
    
    private static func sleepStageName(_ value: Int) -> String {
        switch value {
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            return "Awake"
        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
            return "Asleep"
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
            return "Core"
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
            return "Deep"
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            return "REM"
        default:
            return "Other (\(value))"
        }
    }

    // MARK: - Raw Sleep Blocks

    // Builds only continuous HealthKit blocks.
    // It does not merge separate sleeps based on a made-up time-gap rule.
    private func fetchSleepBlocks(predicate: NSPredicate) async -> [SleepBlock] {
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample],
                      !samples.isEmpty else {
                    continuation.resume(returning: [])
                    return
                }

                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]

                let relevantSamples = samples
                    .filter {
                        asleepValues.contains($0.value) ||
                        $0.value == HKCategoryValueSleepAnalysis.awake.rawValue
                    }
                    .sorted { $0.startDate < $1.startDate }

                guard !relevantSamples.isEmpty else {
                    continuation.resume(returning: [])
                    return
                }

                // A new block starts only when there is an actual gap in
                // HealthKit's consecutive sleep/awake samples.
                var groups: [[HKCategorySample]] = []
                var currentGroup: [HKCategorySample] = []
                var groupEnd: Date?

                for sample in relevantSamples {
                    if let previousEnd = groupEnd,
                       sample.startDate.timeIntervalSince(previousEnd) > 60 {
                        // Merge overlapping or directly adjacent HealthKit stages.
                        // 60 seconds is only a timestamp-tolerance, not a sleep-session rule.

                        if !currentGroup.isEmpty {
                            groups.append(currentGroup)
                        }

                        currentGroup = [sample]
                        groupEnd = sample.endDate

                    } else {
                        currentGroup.append(sample)

                        if let previousEnd = groupEnd {
                            groupEnd = max(previousEnd, sample.endDate)
                        } else {
                            groupEnd = sample.endDate
                        }
                    }
                }

                if !currentGroup.isEmpty {
                    groups.append(currentGroup)
                }

                let blocks = groups.compactMap { group -> SleepBlock? in
                    guard let start = group.map(\.startDate).min(),
                          let end = group.map(\.endDate).max() else {
                        return nil
                    }

                    let asleepIntervals = group
                        .filter { asleepValues.contains($0.value) }
                        .map { (start: $0.startDate, end: $0.endDate) }

                    let awakeIntervals = group
                        .filter {
                            $0.value == HKCategoryValueSleepAnalysis.awake.rawValue
                        }
                        .map { (start: $0.startDate, end: $0.endDate) }

                    let asleepMinutes = Self.mergedMinutes(asleepIntervals)
                    let awakeMinutes = Self.mergedMinutes(awakeIntervals)

                    guard asleepMinutes > 0 else {
                        return nil
                    }

                    let sources = Array(
                        Set(group.map { $0.sourceRevision.source.name })
                    ).sorted()

                    return SleepBlock(
                        start: start,
                        end: end,
                        asleepMinutes: asleepMinutes,
                        awakeMinutes: awakeMinutes,
                        sources: sources
                    )
                }

                continuation.resume(returning: blocks)
            }

            healthStore.execute(query)
        }
    }

    private static func mergedMinutes(
        _ intervals: [(start: Date, end: Date)]
    ) -> Double {
        guard !intervals.isEmpty else { return 0 }

        let sorted = intervals.sorted { $0.start < $1.start }

        var mergedStart = sorted[0].start
        var mergedEnd = sorted[0].end
        var total: TimeInterval = 0

        for interval in sorted.dropFirst() {
            if interval.start <= mergedEnd {
                mergedEnd = max(mergedEnd, interval.end)
            } else {
                total += mergedEnd.timeIntervalSince(mergedStart)
                mergedStart = interval.start
                mergedEnd = interval.end
            }
        }

        total += mergedEnd.timeIntervalSince(mergedStart)
        return total / 60.0
    }

    private func printSleepBlocks(_ blocks: [SleepBlock]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, HH:mm"

        print("\\n🌙 HEALTHKIT CONTINUOUS SLEEP BLOCKS")
        print("------------------------------------------------")

        if blocks.isEmpty {
            print("No sleep blocks found.")
        }

        for (index, block) in blocks.enumerated() {
            print("""
            Block \(index + 1):
            \(formatter.string(from: block.start)) → \(formatter.string(from: block.end))
            Asleep: \(Int(block.asleepMinutes))m
            Awake: \(Int(block.awakeMinutes))m
            Window: \(Int(block.windowMinutes))m
            Source: \(block.sources.joined(separator: ", "))
            """)
        }

        print("------------------------------------------------\\n")
    }

    // MARK: - Sleep Score

    private func fetchLastNightSleepScore(
        predicate: NSPredicate,
        sleepGoalMinutes: Double,
        expectedBedtimeHour: Double?
    ) async -> SleepScoreResult? {
        
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in

                guard let samples = samples as? [HKCategorySample],
                      !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                let formatter = DateFormatter()
                formatter.dateFormat = "dd MMM, HH:mm"

                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]

                let asleepIntervals = samples
                    .filter { asleepValues.contains($0.value) }
                    .map { (start: $0.startDate, end: $0.endDate) }
                    .sorted { $0.start < $1.start }

                guard !asleepIntervals.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Groups close sleep stages into one sleep session.
                let maxGap: TimeInterval = 2 * 60 * 60
                var sessions: [[(start: Date, end: Date)]] = []
                var currentSession: [(start: Date, end: Date)] = []

                for interval in asleepIntervals {
                    if let last = currentSession.last {
                        let gap = interval.start.timeIntervalSince(last.end)

                        if gap <= maxGap {
                            currentSession.append(interval)
                        } else {
                            sessions.append(currentSession)
                            currentSession = [interval]
                        }
                    } else {
                        currentSession = [interval]
                    }
                }

                if !currentSession.isEmpty {
                    sessions.append(currentSession)
                }
                let bestSession = sessions.max { first, second in
                    let firstMinutes = first.reduce(0.0) {
                        $0 + $1.end.timeIntervalSince($1.start)
                    }

                    let secondMinutes = second.reduce(0.0) {
                        $0 + $1.end.timeIntervalSince($1.start)
                    }

                    return firstMinutes < secondMinutes
                }

                guard let session = bestSession,
                      let firstInterval = session.first else {
                    continuation.resume(returning: nil)
                    return
                }
          

                print("\n🌙 RAW HEALTHKIT SLEEP SAMPLES")
                print("------------------------------------------------")

                for sample in samples {
                    let minutes = Int(sample.endDate.timeIntervalSince(sample.startDate) / 60.0)
                    let stage = Self.sleepStageName(sample.value)
                    let source = sample.sourceRevision.source.name

                    print("""
                    \(stage) | \(formatter.string(from: sample.startDate)) → \(formatter.string(from: sample.endDate))
                    Duration: \(minutes)m | Source: \(source)
                    """)
                }
                print("🌙 CHRONO SESSIONS WITH CURRENT 2-HOUR RULE")

                for (index, candidate) in sessions.enumerated() {
                    guard let first = candidate.first,
                          let last = candidate.last else { continue }

                    let totalMinutes = candidate.reduce(0.0) {
                        $0 + $1.end.timeIntervalSince($1.start)
                    } / 60.0

                    print("""
                    Session \(index + 1):
                    \(formatter.string(from: first.start)) → \(formatter.string(from: last.end))
                    Sleep minutes: \(Int(totalMinutes))
                    Intervals: \(candidate.count)
                    """)
                }
                print("------------------------------------------------\n")
                print("------------------------------------------------\n")

                let sleepMinutes = session.reduce(0.0) {
                    $0 + $1.end.timeIntervalSince($1.start)
                } / 60.0

                guard sleepMinutes > 0 else {
                    continuation.resume(returning: nil)
                    return
                }

                // Counts awake gaps of 5 minutes or more.
                var interruptionCount = 0

                if session.count > 1 {
                    for index in 1..<session.count {
                        let previousEnd = session[index - 1].end
                        let currentStart = session[index].start
                        let gapMinutes = currentStart.timeIntervalSince(previousEnd) / 60.0

                        if gapMinutes >= 5 {
                            interruptionCount += 1
                        }
                    }
                }

                let usesTiming = expectedBedtimeHour != nil

                let durationScore: Double
                let timingScore: Double
                let interruptionScore: Double

                if let expectedBedtimeHour = expectedBedtimeHour {

                    // User has a Sleep Schedule / expected bedtime.
                    // Duration: 50 | Timing: 30 | Interruptions: 20

                    durationScore = min(
                        (sleepMinutes / sleepGoalMinutes) * 50.0,
                        50.0
                    )

                    let bedtimeMinutes = Self.minutesSinceMidnight(firstInterval.start)
                    let targetBedtimeMinutes = expectedBedtimeHour * 60.0
                    let timingDifference = Self.circularMinuteDifference(
                        bedtimeMinutes,
                        targetBedtimeMinutes
                    )

                    // Every 15 minutes away from the expected bedtime removes 1 point.
                    timingScore = max(
                        30.0 - (timingDifference / 15.0),
                        0.0
                    )

                    interruptionScore = max(
                        20.0 - (Double(interruptionCount) * 4.0),
                        0.0
                    )

                } else {

                    // No Sleep Schedule:
                    // Keep Apple's normal 50 / 30 / 20 structure.
                    // Until we calculate the user's usual bedtime from past nights,
                    // give neutral timing points instead of removing Timing entirely.

                    durationScore = min(
                        (sleepMinutes / sleepGoalMinutes) * 50.0,
                        50.0
                    )

                    timingScore = 24.0

                    interruptionScore = max(
                        20.0 - (Double(interruptionCount) * 4.0),
                        0.0
                    )
                }

                let totalScore = min(
                    durationScore + timingScore + interruptionScore,
                    100.0
                )

                print("🛌 Sleep session intervals count: \(session.count)")
                print("🧮 App Sleep Score: \(Int(totalScore))")

                continuation.resume(
                    returning: SleepScoreResult(
                        totalScore: totalScore,
                        durationScore: durationScore,
                        timingScore: timingScore,
                        interruptionScore: interruptionScore,
                        sleepMinutes: sleepMinutes,
                        usesTiming: usesTiming
                    )
                )
            }

            healthStore.execute(query)
        }
    }
    private static func minutesSinceMidnight(_ date: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
    }

    private static func circularMinuteDifference(_ a: Double, _ b: Double) -> Double {
        let dayMinutes = 24.0 * 60.0
        let difference = abs(a - b)
        return min(difference, dayMinutes - difference)
    }

    // MARK: - HRV

    private func fetchLastHRV(predicate: NSPredicate) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(
                    returning: sample.quantity.doubleValue(for: HKUnit(from: "ms"))
                )
            }

            healthStore.execute(query)
        }
    }

    private func fetchAverageHRV(predicate: NSPredicate) async -> Double? {
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: hrvType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                guard let average = statistics?.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(
                    returning: average.doubleValue(for: HKUnit(from: "ms"))
                )
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Active Calories

    private func fetchTodayActiveCalories(predicate: NSPredicate) async -> Double? {
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeCaloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                guard let stats = statistics,
                      let sum = stats.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }

                continuation.resume(
                    returning: sum.doubleValue(for: .kilocalorie())
                )
            }

            healthStore.execute(query)
        }
    }
}
