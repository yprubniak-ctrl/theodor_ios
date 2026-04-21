import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("isOnboarded") private var isOnboarded = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if isOnboarded {
            BookLibraryView()
        } else {
            OnboardingView(isOnboarded: $isOnboarded)
        }
    }
}

