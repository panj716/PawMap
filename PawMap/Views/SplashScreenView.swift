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
            // Background gradient
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
                
                // Main logo
                VStack(spacing: 20) {
                    ZStack {
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
                        
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.pink)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                    }
                    
                    Text("PawMap")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(textOpacity)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Text("Discover dog-friendly places")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(textOpacity)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                
                Spacer()
                
                VStack(spacing: 15) {
                    Text("Loading...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(pawPrintsOpacity)
                    
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 180, height: 180)
                            .opacity(pawPrintsOpacity)
                        
                        Text("🐕")
                            .font(.system(size: 40))
                            .scaleEffect(y: isAnimating ? 0.9 : 1.0)
                            .offset(y: isAnimating ? 3 : -3)
                            .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: isAnimating)
                            .opacity(pawPrintsOpacity)
                        
                        ForEach(0..<3, id: \.self) { index in
                            Text("🐾")
                                .font(.system(size: 12))
                                .opacity(isAnimating ? 0.7 : 0.4)
                                .offset(x: CGFloat(index * 30 - 30), y: CGFloat((index % 2) * 6 - 3))
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(index) * 0.2), value: isAnimating)
                        }
                    }
                    .frame(width: 200, height: 200)
                    
                    Text("Finding dog-friendly places near you...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .opacity(pawPrintsOpacity)
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
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.6)) {
                textOpacity = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.5)) {
                pawPrintsOpacity = 1.0
                isAnimating = true
            }
        }
        
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
