//
//  ConfettiView.swift
//  Sidrat
//
//  Confetti particle animation for celebrations
//

import SwiftUI

struct ConfettiView: View {
    // MARK: - Configuration
    
    let particleCount: Int
    let colors: [Color]
    
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    
    // MARK: - Initialization
    
    init(particleCount: Int = 30, colors: [Color] = [.brandPrimary, .brandAccent, .brandSecondary]) {
        self.particleCount = particleCount
        self.colors = colors
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiParticleView(particle: particle, isAnimating: isAnimating)
                        .position(
                            x: isAnimating ? particle.endX : particle.startX,
                            y: isAnimating ? particle.endY : particle.startY
                        )
                        .opacity(isAnimating ? 0 : 1)
                        .rotationEffect(.degrees(isAnimating ? particle.rotation : 0))
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                startAnimation()
            }
        }
        .allowsHitTesting(false) // Allow touches to pass through
    }
    
    // MARK: - Particle Generation
    
    private func generateParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            // Random spread from center
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = Double.random(in: 100...300)
            
            let endX = centerX + CGFloat(cos(angle) * distance)
            let endY = centerY + CGFloat(sin(angle) * distance)
            
            return ConfettiParticle(
                id: UUID(),
                startX: centerX,
                startY: centerY,
                endX: endX,
                endY: endY,
                color: colors.randomElement() ?? .brandPrimary,
                size: CGFloat.random(in: 8...16),
                rotation: Double.random(in: -360...360),
                shape: ConfettiShape.allCases.randomElement() ?? .circle
            )
        }
    }
    
    private func startAnimation() {
        withAnimation(.easeOut(duration: 1.2).delay(0.1)) {
            isAnimating = true
        }
    }
}

// MARK: - Confetti Particle Model

struct ConfettiParticle: Identifiable {
    let id: UUID
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let shape: ConfettiShape
}

// MARK: - Confetti Shape

enum ConfettiShape: CaseIterable {
    case circle
    case square
    case triangle
    case star
}

// MARK: - Confetti Particle View

struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    let isAnimating: Bool
    
    var body: some View {
        shapeView
            .frame(width: particle.size, height: particle.size)
            .scaleEffect(isAnimating ? 0.5 : 1.0)
    }
    
    @ViewBuilder
    private var shapeView: some View {
        switch particle.shape {
        case .circle:
            Circle().fill(particle.color)
        case .square:
            Rectangle().fill(particle.color)
        case .triangle:
            Triangle().fill(particle.color)
        case .star:
            Star().fill(particle.color)
        }
    }
}

// MARK: - Custom Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4
        let pointCount = 5
        
        for i in 0..<pointCount * 2 {
            let angle = CGFloat(i) * .pi / CGFloat(pointCount) - .pi / 2
            let length = i.isMultiple(of: 2) ? radius : innerRadius
            let x = center.x + cos(angle) * length
            let y = center.y + sin(angle) * length
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("Confetti Animation") {
    ZStack {
        Color.backgroundPrimary
            .ignoresSafeArea()
        
        ConfettiView(particleCount: 40)
    }
}
