import SwiftUI
import StoreKit

// ── MARK: PaywallView ─────────────────────────────────────────────
// Presented as a sheet when the user tries to create a chapter
// beyond the free tier limit (1 chapter).
//
// Usage:
//   .sheet(isPresented: $showPaywall) { PaywallView() }

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showError = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            Color.theoPaper(scheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // ── Header ───────────────────────────────
                    VStack(spacing: 20) {
                        Spacer().frame(height: 48)

                        // Theodore signature mark
                        ZStack {
                            Circle()
                                .fill(Color.theoRed.opacity(0.12))
                                .frame(width: 88, height: 88)
                            Text("T")
                                .font(.system(size: 42, weight: .light, design: .serif))
                                .italic()
                                .foregroundStyle(Color.theoRed)
                        }

                        Text("Your story continues")
                            .font(.theoTitle)
                            .foregroundStyle(Color.theoText(scheme))
                            .multilineTextAlignment(.center)

                        Text("Theodore has more to say.")
                            .font(.theoBody)
                            .foregroundStyle(Color.theoMuted)
                    }
                    .padding(.horizontal, 32)

                    Spacer().frame(height: 40)

                    // ── Value props ──────────────────────────
                    VStack(spacing: 0) {
                        ValueRow(
                            icon: "book.closed",
                            title: "Unlimited chapters",
                            subtitle:"Every period of your life, written."
                        )
                        Divider()
                            .overlay(Color.theoS2)
                            .padding(.leading, 60)
                        ValueRow(
                            icon: "eye",
                            title: "Theodore sees your photos",
                            subtitle:"Vision AI reads each image and finds what you didn't say."
                        )
                        Divider()
                            .overlay(Color.theoS2)
                            .padding(.leading, 60)
                        ValueRow(
                            icon: "bubble.left.and.bubble.right",
                            title: "Revise with conversation",
                            subtitle:"Ask Theodore to rewrite, shift mood, or go deeper."
                        )
                        Divider()
                            .overlay(Color.theoS2)
                            .padding(.leading, 60)
                        ValueRow(
                            icon: "icloud",
                            title: "Your book, always",
                            subtitle:"Stored privately on your device. No cloud. No tracking."
                        )
                    }
                    .background(Color.theoCard(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 40)

                    // ── Price pill ───────────────────────────
                    VStack(spacing: 6) {
                        Text("$29.99")
                            .font(.system(size: 38, weight: .semibold, design: .serif))
                            .foregroundStyle(Color.theoText(scheme))
                        Text("per year · cancel anytime")
                            .font(.theoCaption)
                            .foregroundStyle(Color.theoMuted)
                    }

                    Spacer().frame(height: 28)

                    // ── CTA ──────────────────────────────────
                    Button {
                        Task { await purchase() }
                    } label: {
                        ZStack {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Continue with Theodore+")
                                    .font(.system(size: 16, weight: .semibold, design: .serif))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [Color.theoRed2, Color.theoRed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(isPurchasing || subscriptionService.isLoading)
                    .padding(.horizontal, 20)

                    // ── Restore ──────────────────────────────
                    Button {
                        Task {
                            await subscriptionService.restore()
                            if subscriptionService.isSubscribed { dismiss() }
                        }
                    } label: {
                        Text("Restore purchase")
                            .font(.theoCaption)
                            .foregroundStyle(Color.theoMuted)
                            .underline()
                    }
                    .padding(.top, 16)

                    // ── Legal ────────────────────────────────
                    Text("Billed annually. Payment charged to your Apple ID. Subscription renews automatically unless cancelled at least 24 hours before the current period ends.")
                        .font(.system(size: 10, weight: .regular, design: .serif))
                        .foregroundStyle(Color.theoMuted.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }

            // ── Dismiss X ────────────────────────────────────
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.theoMuted)
                    .frame(width: 32, height: 32)
                    .background(Color.theoCard(scheme))
                    .clipShape(Circle())
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
        .alert("Purchase failed", isPresented: $showError, presenting: purchaseError) { _ in
            Button("OK", role: .cancel) {}
        } message: { err in
            Text(err)
        }
        .onChange(of: subscriptionService.isSubscribed) { _, subscribed in
            if subscribed { dismiss() }
        }
    }

    // ── Purchase Flow ─────────────────────────────────────────

    private func purchase() async {
        isPurchasing = true
        do {
            try await subscriptionService.purchase()
        } catch {
            purchaseError = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }
}

// ── MARK: ValueRow ────────────────────────────────────────────────

private struct ValueRow: View {
    @Environment(\.colorScheme) private var scheme

    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.theoAmber)
                .frame(width: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.theoText(scheme))
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundStyle(Color.theoMuted)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// ── MARK: PaywallModifier ─────────────────────────────────────────
// Convenience modifier — attach to any view that can trigger the paywall.
//
// Usage:
//   .paywallGate(isPresented: $showPaywall)

struct PaywallModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                PaywallView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
    }
}

extension View {
    func paywallGate(isPresented: Binding<Bool>) -> some View {
        modifier(PaywallModifier(isPresented: isPresented))
    }
}
