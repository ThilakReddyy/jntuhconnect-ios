import SwiftUI

extension Color {
    static let appBackground = Color(uiColor: .systemGroupedBackground)
    static let appSurface = Color(uiColor: .secondarySystemGroupedBackground)
    static let appOutline = Color(uiColor: .separator)
    static let appGold = Color(red: 0.67, green: 0.55, blue: 0.35)
}

enum AppTheme {
    static func heroGradient(for scheme: ColorScheme) -> LinearGradient {
        let colors: [Color] = scheme == .dark
            ? [Color(red: 0.02, green: 0.025, blue: 0.03), Color(red: 0.07, green: 0.08, blue: 0.10), Color(red: 0.15, green: 0.17, blue: 0.20)]
            : [Color(red: 0.13, green: 0.14, blue: 0.15), Color(red: 0.20, green: 0.23, blue: 0.25), Color(red: 0.33, green: 0.36, blue: 0.40)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct AppCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.appOutline.opacity(0.45), lineWidth: 0.5)
            }
    }
}

struct AppLoadingView: View {
    let title: String
    let message: String?
    var compact = false

    init(_ title: String, message: String? = nil, compact: Bool = false) {
        self.title = title
        self.message = message
        self.compact = compact
    }

    var body: some View {
        Group {
            if compact {
                HStack(spacing: 14) {
                    BrandActivityIndicator(size: 42)
                    labels
                    Spacer(minLength: 0)
                }
            } else {
                VStack(spacing: 16) {
                    BrandActivityIndicator(size: 68)
                    labels
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(compact ? 14 : 24)
        .frame(maxWidth: compact ? .infinity : 320, alignment: compact ? .leading : .center)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.appOutline.opacity(0.38), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.06), radius: 18, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(message ?? "Please wait")
        .accessibilityIdentifier("app.loading")
    }

    private var labels: some View {
        VStack(alignment: compact ? .leading : .center, spacing: 5) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct BrandActivityIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let size: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let interval = timeline.date.timeIntervalSinceReferenceDate
            let rotation = reduceMotion ? 28 : interval.truncatingRemainder(dividingBy: 1.2) / 1.2 * 360

            ZStack {
                Circle()
                    .fill(Color.appSurface)

                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 3)

                Circle()
                    .trim(from: 0.08, to: 0.74)
                    .stroke(
                        AngularGradient(
                            colors: [.appGold.opacity(0.2), .appGold, .primary, .appGold.opacity(0.2)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(rotation))

                Image("AppMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.53, height: size * 0.53)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.13, style: .continuous))
            }
            .frame(width: size, height: size)
            .shadow(color: Color.appGold.opacity(0.16), radius: 10)
        }
        .frame(width: size, height: size)
    }
}

struct StatusBarScrollGlass: View {
    let height: CGFloat
    let minimumHeight: CGFloat

    init(height: CGFloat, minimumHeight: CGFloat = 55) {
        self.height = height
        self.minimumHeight = minimumHeight
    }

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                Rectangle()
                    .fill(.clear)
                    .glassEffect(.regular, in: Rectangle())
            } else {
                Rectangle()
                    .fill(.ultraThinMaterial)
            }
        }
        // Keep the status items protected even when a container reports a zero inset.
        .frame(height: max(height, minimumHeight))
        .overlay(alignment: .bottom) {
            Divider().opacity(0.22)
        }
    }
}
