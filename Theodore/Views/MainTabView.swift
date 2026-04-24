import SwiftUI

struct MainTabView: View {
    @State private var activeTab: TheodoreTab = .library
    @State private var showNewChapter = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $activeTab) {
                BookLibraryView()
                    .tag(TheodoreTab.library)
                TheodoreChatView()
                    .tag(TheodoreTab.theodore)
                ProfileView()
                    .tag(TheodoreTab.you)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            TheodoreTabBar(active: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// ── Tab enum ──────────────────────────────────────────────────────

enum TheodoreTab: Hashable {
    case library, theodore, you
}

// ── Custom tab bar ────────────────────────────────────────────────

struct TheodoreTabBar: View {
    @Binding var active: TheodoreTab

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(id: .library, active: active, label: "Library") {
                LibraryTabIcon(on: active == .library)
            } onTap: { active = .library }

            TabBarItem(id: .theodore, active: active, label: "Theodore") {
                TLogoTabIcon(on: active == .theodore)
            } onTap: { active = .theodore }

            TabBarItem(id: .you, active: active, label: "You") {
                YouTabIcon(on: active == .you)
            } onTap: { active = .you }
        }
        .frame(height: 82)
        .padding(.top, 10)
        .background(Color.theoParch.opacity(0.92).background(.ultraThinMaterial))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.theoNavy.opacity(0.08))
                .frame(height: 1)
        }
    }
}

private struct TabBarItem<Icon: View>: View {
    let id: TheodoreTab
    let active: TheodoreTab
    let label: String
    @ViewBuilder let icon: () -> Icon
    let onTap: () -> Void

    var isActive: Bool { active == id }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                icon()
                Text(label)
                    .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? Color.theoNavy : Color.theoMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }
}

// ── Tab icons ─────────────────────────────────────────────────────

private struct LibraryTabIcon: View {
    let on: Bool
    var body: some View {
        Image(systemName: on ? "books.vertical.fill" : "books.vertical")
            .font(.system(size: 20))
            .foregroundStyle(on ? Color.theoNavy : Color.theoMuted)
    }
}

private struct TLogoTabIcon: View {
    let on: Bool
    var body: some View {
        RoundedRectangle(cornerRadius: 7)
            .fill(on ? Color.theoNavy : Color.clear)
            .stroke(on ? Color.theoNavy : Color.theoMuted, lineWidth: 1.5)
            .frame(width: 24, height: 24)
            .overlay {
                Text("T")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundStyle(on ? Color.theoParch : Color.theoMuted)
            }
    }
}

private struct YouTabIcon: View {
    let on: Bool
    var body: some View {
        Image(systemName: on ? "person.fill" : "person")
            .font(.system(size: 20))
            .foregroundStyle(on ? Color.theoNavy : Color.theoMuted)
    }
}
