import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showError = false

    enum PaywallPlan: String {
        case monthly, yearly
        var price: String    { self == .yearly ? "$49.99" : "$9.99" }
        var period: String   { self == .yearly ? "/year" : "/month" }
        var monthly: String? { self == .yearly ? "$4.17/mo" : nil }
        var badge: String?   { self == .yearly ? "Save 58%" : nil }
        var label: String    { self == .yearly ? "Yearly" : "Monthly" }
    }

    private let features: [(String, String)] = [
        ("Unlimited chapters",      "Write your whole story"),
        ("Export memoir as PDF",    "Print or share anytime"),
        ("Writing streak tracking", "Build a daily habit"),
        ("Photo memory search",     "Find any moment instantly"),
        ("Priority rewrites",       "Theodore refines your drafts"),
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            parchBackground
            VStack(spacing: 0) {
                dismissButton
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                        featuresSection
                        planToggle
                        comparisonCard
                    }
                    .padding(.horizontal, 26)
                    .padding(.bottom, 20)
                }
                ctaSection
            }
        }
        .alert("Purchase failed", isPresented: $showError, presenting: purchaseError) { _ in
            Button("OK", role: .cancel) {}
        } message: { err in Text(err) }
        .onChange(of: subscriptionService.isSubscribed) { _, subscribed in
            if subscribed { dismiss() }
        }
    }

    // ── Dismiss ───────────────────────────────────────────────────

    private var dismissButton: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.theoMuted)
                    .frame(width: 30, height: 30)
                    .background(Color.theoNavy.opacity(0.07), in: Circle())
            }
            .padding(.top, 18)
            .padding(.trailing, 20)
        }
    }

    // ── Header ────────────────────────────────────────────────────

    private var headerSection: some View {
        VStack(spacing: 0) {
            TLogo(size: 48)
                .padding(.bottom, 16)

            Text("Your first chapter\nis just the beginning")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(Color.theoNavy)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.bottom, 8)

            GoldLine()
                .padding(.bottom, 14)

            Text("Unlock Theodore to keep writing.\nYour whole life deserves to be told.")
                .font(.system(size: 14, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(Color.theoSlate)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 28)
        }
    }

    // ── Features ──────────────────────────────────────────────────

    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(features, id: \.0) { feature, sub in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.theoGold.opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.theoGold.opacity(0.20), lineWidth: 1))
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.theoGold)
                    }
                    .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(feature)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.theoNavy)
                        Text(sub)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.theoMuted)
                    }
                    Spacer()
                }
            }
        }
        .padding(.bottom, 26)
    }

    // ── Plan toggle ───────────────────────────────────────────────

    private var planToggle: some View {
        HStack(spacing: 8) {
            ForEach([PaywallPlan.yearly, .monthly], id: \.rawValue) { plan in
                Button { selectedPlan = plan } label: {
                    ZStack(alignment: .topTrailing) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.label)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(selectedPlan == plan
                                                 ? Color.theoParch.opacity(0.7)
                                                 : Color.theoMuted)
                                .padding(.bottom, 2)

                            Text(plan.price)
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .foregroundStyle(selectedPlan == plan ? Color.theoParch : Color.theoNavy)

                            Text(plan.period)
                                .font(.system(size: 11))
                                .foregroundStyle(selectedPlan == plan
                                                 ? Color.theoParch.opacity(0.6)
                                                 : Color.theoMuted)

                            if let monthly = plan.monthly {
                                Text("\(monthly) billed annually")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(selectedPlan == plan
                                                     ? Color.theoGold.opacity(0.9)
                                                     : Color.theoBrown)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selectedPlan == plan ? Color.theoNavy : Color.white.opacity(0.62),
                                    in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedPlan == plan ? Color.theoNavy : Color.white.opacity(0.80), lineWidth: 1))
                        .shadow(color: Color.theoNavy.opacity(selectedPlan == plan ? 0.18 : 0.04),
                                radius: 12, x: 0, y: 2)

                        if let badge = plan.badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.theoGold, in: Capsule())
                                .offset(x: -8, y: -12)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 18)
    }

    // ── Free vs paid comparison ───────────────────────────────────

    private var comparisonCard: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("FREE")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.theoBrown)
                    .padding(.bottom, 10)
                ForEach(["1 chapter", "Basic writing", "No export"], id: \.self) { item in
                    HStack(spacing: 6) {
                        ZStack {
                            Circle().fill(Color.theoNavy.opacity(0.06))
                            Image(systemName: "xmark")
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundStyle(Color.theoMuted)
                        }
                        .frame(width: 14, height: 14)
                        Text(item)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.theoMuted)
                    }
                    .padding(.bottom, 7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 12)
            .overlay(alignment: .trailing) {
                Rectangle().fill(Color.theoNavy.opacity(0.06)).frame(width: 1)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("THEODORE+")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.theoBrown)
                    .padding(.bottom, 10)
                ForEach(["Unlimited chapters", "All writing tools", "PDF export"], id: \.self) { item in
                    HStack(spacing: 6) {
                        ZStack {
                            Circle().fill(Color.theoGold.opacity(0.12))
                            Image(systemName: "checkmark")
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundStyle(Color.theoGold)
                        }
                        .frame(width: 14, height: 14)
                        Text(item)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.theoNavy)
                    }
                    .padding(.bottom, 7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12)
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
        .padding(.bottom, 22)
    }

    // ── CTA ───────────────────────────────────────────────────────

    private var ctaSection: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.theoNavy.opacity(0.06))
            VStack(spacing: 0) {
                Button {
                    Task { await purchase() }
                } label: {
                    ZStack {
                        if isPurchasing {
                            ProgressView().tint(Color.theoParch)
                        } else {
                            Text("Start \(selectedPlan.label) — \(selectedPlan.price)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.theoParch)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.theoNavy, in: Capsule())
                    .shadow(color: Color.theoNavy.opacity(0.22), radius: 20, x: 0, y: 4)
                }
                .disabled(isPurchasing)

                Button("Maybe later") { dismiss() }
                    .font(.system(size: 13))
                    .foregroundStyle(Color.theoMuted)
                    .padding(.top, 10)

                Button {
                    Task {
                        await subscriptionService.restore()
                        if subscriptionService.isSubscribed { dismiss() }
                    }
                } label: {
                    Text("Restore purchases")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.theoMuted)
                }
                .padding(.top, 4)

                Text("Cancel anytime · Renews automatically · Restore purchases")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.theoMuted.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .background(Color.theoParch.opacity(0.90).background(.ultraThinMaterial))
        }
    }

    // ── Background ────────────────────────────────────────────────

    private var parchBackground: some View {
        LinearGradient(
            colors: [Color(red: 0.961, green: 0.941, blue: 0.910),
                     Color(red: 0.929, green: 0.910, blue: 0.871),
                     Color(red: 0.902, green: 0.867, blue: 0.816)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // ── Purchase ──────────────────────────────────────────────────

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

// ── PaywallModifier ───────────────────────────────────────────────

struct PaywallModifier: ViewModifier {
    @Binding var isPresented: Bool
    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
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
