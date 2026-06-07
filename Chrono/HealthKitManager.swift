//
//  HealthKitManager.swift
//  Chrono
//
//  Created by Reema on 18/12/1447 AH.
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    
    let healthStore = HKHealthStore()
    
    // MARK: - Health Types to Read
    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
    
    /// Requests access to Apple Health
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        let typesToRead: Set<HKObjectType> = [sleepType, hrvType, rhrType]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            return true
        } catch {
            print("HealthKit Authorization Failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// The Core Math Matrix: Fetches metrics and computes the baseline 0-100 score
    func calculateMorningBaseline() async -> Double? {
        
        // 🚨 SIMULATOR OVERRIDE FOR PREVIEWS / DEMOS
        #if targetEnvironment(simulator)
        return 94.0
        #else
        
        print("\n📊 [HealthKit Engine] جاري بدء فحص البيانات الحيوية الفلكية...")
        
        let now = Date()
        let calendar = Calendar.current
        
        // 💡 حل مشكلة الـ Predicate الصارم:
        // نوسع النطاق لـ 36 ساعة لتغطية بداية وقت النوم ليلة أمس بالكامل، وألغينا خيار .strictStartDate لمرونة الجلب
        let thirtySixHoursAgo = calendar.date(byAdding: .hour, value: -36, to: now)!
        let generalPredicate = HKQuery.predicateForSamples(withStart: thirtySixHoursAgo, end: now, options: [])
        
        let sleepMinutes = await fetchLastNightSleep(predicate: generalPredicate)
        let hrvValue = await fetchLastHRV(predicate: generalPredicate)
        let rhrValue = await fetchLastRHR(predicate: generalPredicate)
        
        // طباعة تقرير المستشعرات في الـ Console لمراقبة عملية الجلب الحية
        print("--------- 🩺 تقرير المستشعرات الحالية ---------")
        if let sleep = sleepMinutes {
            print("💤 ساعات النوم المجلوبة: \(String(format: "%.1f", sleep / 60.0)) ساعة (\(Int(sleep)) دقيقة)")
        } else {
            print("💤 ساعات النوم المجلوبة: ⚠️ لا توجد قراءة حية (سيتم استخدام الـ Fallback للأفرج بيرسون)")
        }
        
        print("❤️ قراءة HRV المجلوبة: \(hrvValue != nil ? "\(Int(hrvValue!)) ms" : "⚠️ لا توجد قراءة حية (سيتم استخدام الـ Fallback للأفرج بيرسون)")")
        print("💓 قراءة RHR المجلوبة: \(rhrValue != nil ? "\(Int(rhrValue!)) bpm" : "⚠️ لا توجد قراءة حية (سيتم استخدام الـ Fallback للأفرج بيرسون)")")
        print("---------------------------------------------")
        
        // THE PRIVACY CHECK:
        if sleepMinutes == nil && hrvValue == nil && rhrValue == nil {
            print("🚨 [HealthKit Engine] تم رفض الصلاحيات بالكامل أو لا توجد بيانات نهائياً.")
            return nil
        }
        
        let finalSleep = sleepMinutes ?? 450.0
        let finalHRV = hrvValue ?? 50.0
        let finalRHR = rhrValue ?? 65.0
        
        // المصفوفة الحسابية الرياضية (The Math Matrix)
        let sleepScore = min((finalSleep / 480.0) * 50.0, 50.0)
        let hrvScore = min((finalHRV / 50.0) * 30.0, 30.0)
        let rhrScore = min((65.0 / finalRHR) * 20.0, 20.0)
        
        let totalScore = sleepScore + hrvScore + rhrScore
        let finalRoundedScore = min(max(totalScore, 0.0), 100.0)
        
        print("🎯 [HealthKit Engine] السكور النهائي المحسوب للطاقة: \(Int(finalRoundedScore))%\n")
        return finalRoundedScore
        
        #endif
    }
    
    // MARK: - Background Fetch Helpers
    
    private func fetchLastNightSleep(predicate: NSPredicate) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let sampleQuery = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let totalAsleepTime = sleepSamples
                    .filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue || $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue || $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue || $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                
                let minutes = totalAsleepTime / 60.0
                continuation.resume(returning: minutes > 0 ? minutes : nil)
            }
            healthStore.execute(sampleQuery)
        }
    }
    
    private func fetchLastHRV(predicate: NSPredicate) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let hrvInMs = sample.quantity.doubleValue(for: HKUnit(from: "ms"))
                continuation.resume(returning: hrvInMs)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchLastRHR(predicate: NSPredicate) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: rhrType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: bpm)
            }
            healthStore.execute(query)
        }
    }
}
