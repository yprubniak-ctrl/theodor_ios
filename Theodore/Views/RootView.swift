import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("isOnboarded") private var isOnboarded = false

    var body: some View {
        if isOnboarded {
            MainTabView()
        } else {
            OnboardingView(isOnboarded: $isOnboarded)
        }
    }
}
