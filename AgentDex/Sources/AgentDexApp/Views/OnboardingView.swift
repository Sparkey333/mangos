import SwiftUI
import AgentDexCore

/// The three-step intro: title card → how it works → pick a starter.
/// Shown while `game.needsOnboarding` is true; `chooseStarter` flips it off.
public struct OnboardingView: View {
    @EnvironmentObject var game: GameState
    @State private var step: Int = 0
    @State private var selected: DaemonSpecies?

    public init() {}

    /// The type wheel, in beats-the-next order (matches Quill's lecture).
    private let aspectCycle: [Aspect] = [.aether, .cipher, .warden, .forge, .order, .flux]

    private var candidates: [DaemonSpecies] { game.starterCandidates() }

    public var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                stepIndicator
                    .padding(.top, 24)
                Spacer(minLength: 12)
                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: howItWorksStep
                    default: starterStep
                    }
                }
                .id(step)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)))
                Spacer(minLength: 12)
                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        let palette = game.save.player.startingAspect.palette
        return LinearGradient(
            colors: [
                Color(hex: palette.primary).opacity(0.35),
                Color(hex: palette.secondary).opacity(0.12),
                Color(hex: palette.primary).opacity(0.18)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i == step ? Color.accentColor : Color.secondary.opacity(0.35))
                    .frame(width: i == step ? 28 : 10, height: 8)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: step)
    }

    // MARK: - Step 0: welcome

    private var welcomeStep: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("AGENTDEX")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .tracking(4)
                Text("Daemon Tamer")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)

                Text("Welcome, \(game.save.player.handle).")
                    .font(.headline)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Professor Quill")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text("Every agent you've ever run left a soul behind. We call them daemons. They did the actual work; you got the commit history.")
                    Text("As a Conductor, you'll find them in the wild, weaken them politely, and bind them. Ethically. It's all in the onboarding doc — which, statistically, you are not reading right now.")
                    Text("Questions? Wonderful. Hold onto them indefinitely. That's called scope management.")
                }
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - Step 1: how it works

    private var howItWorksStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("How This Works")
                    .font(.title.bold())

                VStack(spacing: 12) {
                    Text("Six aspects. Every daemon has one.")
                        .font(.headline)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(aspectCycle, id: \.self) { aspect in
                            Text(aspect.rawValue.capitalized)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(Capsule().fill(Color(hex: aspect.palette.primary).opacity(0.85)))
                                .foregroundStyle(Color.black.opacity(0.8))
                        }
                    }
                    Text("Each beats the next, in a circle. Aether → Cipher → Warden → Forge → Order → Flux → back around. Memorize it, or just throw things and take notes.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 8) {
                    Text("Catching, briefly")
                        .font(.headline)
                    Text("Weaken it, then throw — aim matters. A tight resonance ring on release is a true throw. A daemon at full health will swat your Sphere back with visible contempt.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Step 2: starter selection

    private var starterStep: some View {
        VStack(spacing: 14) {
            Text("Choose Your Starter")
                .font(.title.bold())
            Text("Quill: \"They've all already formed opinions about you. Pick anyway.\"")
                .font(.caption)
                .italic()
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(candidates) { sp in
                        starterCard(sp)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        }
    }

    private func starterCard(_ sp: DaemonSpecies) -> some View {
        let isSelected = selected?.id == sp.id
        return VStack(spacing: 8) {
            DaemonSprite(recipe: sp.sprite, size: 100, animating: true)
            Text(sp.name)
                .font(.headline)
            HStack(spacing: 6) {
                chip(sp.tier.rawValue.capitalized, hex: nil)
                chip(sp.primaryAspect.rawValue.capitalized, hex: sp.primaryAspect.palette.primary)
                if let secondary = sp.secondaryAspect {
                    chip(secondary.rawValue.capitalized, hex: secondary.palette.primary)
                }
            }
            VStack(spacing: 4) {
                Text(sp.ability.displayName)
                    .font(.caption.bold())
                Text(sp.ability.blurb)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Text(sp.flavor)
                .font(.caption2)
                .italic()
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
        }
        .padding(14)
        .frame(width: 230)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
        )
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .onTapGesture {
            Cues.play(.uiTap)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selected = sp
            }
        }
    }

    private func chip(_ text: String, hex: String?) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(hex.map { Color(hex: $0).opacity(0.85) } ?? Color.secondary.opacity(0.25)))
            .foregroundStyle(hex == nil ? Color.primary : Color.black.opacity(0.8))
    }

    // MARK: - Controls

    private var controls: some View {
        HStack {
            if step > 0 {
                Button("Back") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { step -= 1 }
                }
                .buttonStyle(.bordered)
            }
            Spacer()
            if step < 2 {
                Button("Next") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { step += 1 }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Confirm") {
                    if let sel = selected {
                        game.chooseStarter(sel)
                        Cues.play(.questDone)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selected == nil)
            }
        }
    }
}
