import SwiftUI

enum AppTab: String, Hashable { case home, explore, profile }

enum AppRoute: Hashable {
    case student(RollNumber, StudentResultSection)
    case extended(ResultRequest)
    case resource(ResourceKind)
    case channels
    case helpCenter
    case privacy
}

struct RootView: View {
    @SceneStorage("selectedAppTab") private var selectedTab: AppTab = .home
    @State private var recentStore = RecentSearchStore()
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house", value: .home) {
                    HomeView(recentStore: recentStore, onNavigate: navigate)
                }
                Tab("Explore", systemImage: "safari", value: .explore) {
                    ExploreView(recentStore: recentStore, onNavigate: navigate)
                }
                Tab("Settings", systemImage: "gearshape", value: .profile) {
                    ProfileView(recentStore: recentStore, onNavigate: navigate)
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            .tint(.primary)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .student(let roll, let section):
                    StudentResultView(rollNumber: roll, recentStore: recentStore, initialSection: section)
                case .extended(let request):
                    ExtendedResultView(request: request)
                case .resource(let kind):
                    ContentTreeView(kind: kind, recentStore: recentStore)
                case .channels:
                    ChannelsView()
                case .helpCenter:
                    HelpCenterView()
                case .privacy:
                    PrivacyPolicyView()
                }
            }
        }
    }

    private func navigate(_ route: AppRoute) {
        path.append(route)
    }
}
