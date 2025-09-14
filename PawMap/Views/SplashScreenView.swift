//
//  SplashScreenView.swift
//  PawMap
//
//  Created by Sunny on 9/11/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showMainApp = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var pawPrintsOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.pink.opacity(0.8),
                    Color.pink.opacity(0.6),
                    Color.orange.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 主Logo动画
                VStack(spacing: 20) {
                    // 狗狗脚印图标
                    ZStack {
                        // 背景圆圈
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white, Color.white.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                        
                        // 主图标
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.pink)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                    }
                    
                    // 应用名称
                    Text("PawMap")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(textOpacity)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    // 副标题
                    Text("发现狗狗友好的地方")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(textOpacity)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                
                Spacer()
                
                // 底部装饰性脚印
                HStack(spacing: 20) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.3))
                            .opacity(pawPrintsOpacity)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                                value: isAnimating
                            )
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            startAnimation()
        }
        .fullScreenCover(isPresented: $showMainApp) {
            ContentView()
        }
    }
    
    private func startAnimation() {
        // 第一阶段：Logo出现
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // 第二阶段：文字出现
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.6)) {
                textOpacity = 1.0
            }
        }
        
        // 第三阶段：装饰脚印出现
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.5)) {
                pawPrintsOpacity = 1.0
                isAnimating = true
            }
        }
        
        // 3秒后转到主应用
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showMainApp = true
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
