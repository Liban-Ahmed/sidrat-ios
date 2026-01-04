//
//  LaunchSplashView.swift
//  Sidrat
//
//  Animated splash shown immediately after launch
//

import SwiftUI

struct LaunchSplashView: View {
    private enum Constants {
        static let logoSize: CGFloat = 170
        static let logoCornerRadius: CGFloat = 34
        static let logoInset: CGFloat = 0

        static let ring1Size: CGFloat = 280
        static let ring2Size: CGFloat = 360

        static let sparkleRadius: CGFloat = 140

        static let floatDuration: TimeInterval = 2.1
        static let introDuration: TimeInterval = 0.85

        static let subtitleDelay: TimeInterval = 0.15
        static let subtitleDuration: TimeInterval = 0.55

        static let step1Delay: TimeInterval = 0.6
        static let step2Delay: TimeInterval = 1.8
        static let step3Delay: TimeInterval = 3.0
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isAnimating = false
    @State private var storyboardStep = 0
    @State private var isFloating = false
    @State private var isSparkling = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: Spacing.md) {
                ZStack {
                    if storyboardStep >= 1 && !reduceMotion {
                        ZStack {
                            Circle()
                                .fill(Color.brandAccent.opacity(0.18))
                                .frame(width: Constants.ring1Size, height: Constants.ring1Size)
                                .blur(radius: 18)
                                .scaleEffect(isAnimating ? 1.0 : 0.75)
                                .opacity(isAnimating ? 1 : 0)
                                .animation(.easeOut(duration: 0.6), value: isAnimating)

                            Circle()
                                .fill(Color.brandSecondaryLight.opacity(0.18))
                                .frame(width: Constants.ring2Size, height: Constants.ring2Size)
                                .blur(radius: 22)
                                .scaleEffect(isAnimating ? 1.0 : 0.65)
                                .opacity(isAnimating ? 1 : 0)
                                .animation(.easeOut(duration: 0.8).delay(0.15), value: isAnimating)
                        }
                    }

                    if storyboardStep >= 2 && !reduceMotion {
                        sparkles
                    }

                    Image("SidratLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: Constants.logoSize, height: Constants.logoSize)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.logoCornerRadius, style: .continuous))
                        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 12)
                        .overlay {
                            RoundedRectangle(cornerRadius: Constants.logoCornerRadius, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                        }
                        .offset(y: isFloating && !reduceMotion ? -10 : 0)
                        .animation(
                            reduceMotion ? .none : .easeInOut(duration: Constants.floatDuration).repeatForever(autoreverses: true),
                            value: isFloating
                        )
                        .accessibilityHidden(true)
                }
                .rotationEffect(.degrees(storyboardStep >= 1 && !reduceMotion ? 0 : -180))
                .scaleEffect(storyboardStep >= 1 ? 1.0 : 0.15)
                .opacity(storyboardStep >= 1 ? 1 : 0)
                .animation(reduceMotion ? .none : .spring(response: Constants.introDuration, dampingFraction: 0.72, blendDuration: 0.2), value: storyboardStep)

                VStack(spacing: 6) {
                    Text("بِسْمِ ٱللَّٰهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                        .font(.system(size: 28, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.white.opacity(0.88))
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, Spacing.lg)
                        .opacity(storyboardStep >= 3 ? 1 : 0)
                        .offset(y: storyboardStep >= 3 ? 0 : 10)
                        .animation(
                            reduceMotion
                                ? .none
                                : .easeOut(duration: Constants.subtitleDuration).delay(Constants.subtitleDelay),
                            value: storyboardStep
                        )
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bismillah")
        .onAppear {
            isAnimating = true

            if reduceMotion {
                storyboardStep = 3
                isFloating = false
                isSparkling = false
                return
            }

            storyboardStep = 0
            isFloating = false
            isSparkling = false

            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.step1Delay) {
                storyboardStep = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.step2Delay) {
                storyboardStep = 2
                isFloating = true
                isSparkling = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.step3Delay) {
                storyboardStep = 3
            }
        }
    }

    private var sparkles: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                let angle = (Double(index) / 8.0) * (Double.pi * 2)
                Image(systemName: index.isMultiple(of: 2) ? "sparkles" : "sparkle")
                    .font(.system(size: index.isMultiple(of: 3) ? 18 : 14, weight: .semibold))
                    .foregroundStyle(Color.brandAccent.opacity(index.isMultiple(of: 2) ? 0.9 : 0.75))
                    .shadow(color: Color.brandAccent.opacity(0.35), radius: 10, x: 0, y: 6)
                    .offset(
                        x: CGFloat(cos(angle)) * Constants.sparkleRadius,
                        y: CGFloat(sin(angle)) * (Constants.sparkleRadius - 12)
                    )
                    .opacity(isSparkling ? 1 : 0)
                    .scaleEffect(isSparkling ? 1.0 : 0.2)
                    .animation(
                        .easeInOut(duration: 1.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.12),
                        value: isSparkling
                    )
            }
        }
        .rotationEffect(.degrees(isSparkling ? 360 : 0))
        .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: isSparkling)
        .accessibilityHidden(true)
    }

    private var background: some View {
        ZStack {
            Color.brandPrimary
                .ignoresSafeArea()

            if storyboardStep >= 1 && !reduceMotion {
                Circle()
                    .fill(Color.brandPrimaryLight.opacity(0.32))
                    .frame(width: 320, height: 320)
                    .blur(radius: 60)
                    .offset(x: isAnimating ? -120 : -160, y: isAnimating ? -220 : -180)
                    .animation(
                        .easeInOut(duration: Constants.floatDuration).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                Circle()
                    .fill(Color.brandAccent.opacity(0.22))
                    .frame(width: 260, height: 260)
                    .blur(radius: 70)
                    .offset(x: isAnimating ? 160 : 120, y: isAnimating ? 220 : 260)
                    .animation(
                        .easeInOut(duration: Constants.floatDuration + 0.4).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                Circle()
                    .fill(Color.brandSecondaryLight.opacity(0.18))
                    .frame(width: 220, height: 220)
                    .blur(radius: 70)
                    .offset(x: isAnimating ? 170 : 210, y: isAnimating ? -220 : -260)
                    .animation(
                        .easeInOut(duration: Constants.floatDuration + 0.9).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
    }
}

#Preview {
    LaunchSplashView()
}
