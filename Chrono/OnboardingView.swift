//
//  OnboardingView.swift
//  Chrono
//
//  Created by Reema on 21/12/1447 AH.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentPage = 0
    
    let bgGradient = LinearGradient(
        colors: [Color(red: 0.10, green: 0.14, blue: 0.21), Color(red: 0.18, green: 0.28, blue: 0.45)],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        ZStack {
            // 1. الخلفية الثابتة
            bgGradient.ignoresSafeArea()
            
            // 2. المحتوى الرئيسي
            VStack(spacing: 0) {
                
                // الـ TabView يأخذ المساحة كاملة بشكل مستقل دون أن يتأثر بظهور الزر
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        title: "Find Your Biological Rhythm",
                        description: "Are you a Lion, Bear, Wolf, or Dolphin? Discover your genetic sleep and productivity type.",
                        imageName: "figure.walk.motion"
                    ).tag(0)
                    
                    OnboardingPage(
                        title: "Track Your Daily Energy",
                        description: "Connect your Apple Watch. We analyze your sleep and heart rate to show your energy score.",
                        imageName: "applewatch.watchface"
                    ).tag(1)
                    
                    OnboardingPage(
                        title: "Own Your Schedule",
                        description: "See your perfect times for peak focus, collaboration, and rest through a personalized calendar.",
                        imageName: "calendar.badge.clock"
                    ).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                
                // 3. منطقة الزر السفلي (مساحة ثابتة ومحجوزة مسبقاً لمنع الـ Layout Shift)
                VStack {
                    if currentPage == 2 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                hasCompletedOnboarding = true
                            }
                        }) {
                            Text("Start Chronoquiz")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.10, green: 0.14, blue: 0.21))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(16)
                                .padding(.horizontal, 40)
                                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                        }
                        // تأثير دخول ناعم جداً للزر متزامن مع حركة الصفحة
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                        Text("Takes only 3 minutes")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 8)
                            .transition(.opacity)
                    } else {
                        // مساحة فارغة مخفية بنفس حجم الزر تماماً للحفاظ على ثبات الأبعاد أثناء السحب
                        Color.clear
                            .frame(height: 78)
                    }
                }
                // تطبيق أنيمايشن منساب مخصص للزر والنص عند التبديل
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                .padding(.bottom, 40)
            }
        }
    }
}

// الـ Component الخاص بالصفحة يظل كما هو ونظيف
struct OnboardingPage: View {
    let title: String
    let description: String
    let imageName: String
    
    var body: some View {
        VStack(spacing: 35) {
            Spacer()
            
            Image(systemName: imageName)
                .font(.system(size: 85))
                .foregroundColor(.white.opacity(0.85))
                .frame(height: 120)
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Text(description)
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.65))
                    .lineSpacing(6)
                    .padding(.horizontal, 36)
            }
            
            Spacer()
        }
    }
}
