import SwiftUI
import AppKit

// The @main App struct lives in alert-makerApp.swift.

// MARK: - Sound helper
// Plays the alert sound chosen in System Settings > Sound > Alert sound.
enum AlertSound {
    static func play() {
        NSSound.beep()
    }
}

// MARK: - Alert options
enum AlertIcon: String, CaseIterable, Identifiable {
    case caution, info, cheese, cat, ghost, duck

    var id: String { rawValue }

    var label: String {
        switch self {
        case .caution: return "⚠️ Caution"
        case .info:    return "ℹ️ Info"
        case .cheese:  return "🧀 Cheese"
        case .cat:     return "🐱 Cat"
        case .ghost:   return "👻 Ghost"
        case .duck:    return "🦆 Duck"
        }
    }

    // nil means "use the standard system icon"
    var emoji: String? {
        switch self {
        case .caution, .info: return nil
        case .cheese: return "🧀"
        case .cat:    return "🐱"
        case .ghost:  return "👻"
        case .duck:   return "🦆"
        }
    }
}

struct AlertConfig {
    var title = "No."
    var message = "This action cannot be completed."
    var icon: AlertIcon = .caution
    var okLabel = "OK"
    var cancelLabel = "Cancel"
    var showCancel = true
    var playSound = true
    var autoClose = false
}

// Popups are opened by a plain Int id (so alert-makerApp.swift doesn't need to change).
// The settings for each popup are stashed here under that id.
final class AlertStore {
    static let shared = AlertStore()
    var configs: [Int: AlertConfig] = [:]
}

// MARK: - Main window
struct SillyButtonStyle: ButtonStyle {
    let colors: [Color]
    var width: CGFloat = 280

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(width: width, height: 46)
            .background(
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .stroke(Color.white.opacity(0.7), lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: configuration.isPressed ? 1 : 5)
            .offset(y: configuration.isPressed ? 4 : 0)
            .rotationEffect(.degrees(configuration.isPressed ? -3 : 0))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

struct SpawnOption: Identifiable {
    let amount: Int
    let colors: [Color]
    var id: Int { amount }
}

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @State private var counter = 1      // unique id for each popup window (never reset)
    @State private var popupCount = 0   // number shown on screen (reset by "Make It Go Away!")
    @State private var wobble = false

    private let options: [SpawnOption] = [
        SpawnOption(amount: 1,  colors: [.blue, .purple]),
        SpawnOption(amount: 3,  colors: [.purple, .pink]),
        SpawnOption(amount: 5,  colors: [.pink, .orange]),
        SpawnOption(amount: 10, colors: [.orange, .red]),
        SpawnOption(amount: 25, colors: [.green, .mint]),
        SpawnOption(amount: 50, colors: [.indigo, .purple])
    ]

    private let columns = [GridItem(.fixed(170), spacing: 12), GridItem(.fixed(170), spacing: 12)]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.pink.opacity(0.85), Color.orange.opacity(0.8), Color.yellow.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                Text("alert maker :3")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 0, x: 2, y: 3)
                    .rotationEffect(.degrees(wobble ? 3 : -3))
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: wobble)
                    .padding(.top, 20)

                Text("popups made: \(popupCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.75)))
                    .foregroundColor(.purple)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(options) { option in
                        Button(action: { spawn(option.amount) }) {
                            Text(option.amount == 1 ? "1 alert :D" : "\(option.amount) alerts :0")
                        }
                        .buttonStyle(SillyButtonStyle(colors: option.colors, width: 170))
                    }
                }

                Button(action: clearAll) {
                    Text("Make It Go Away! 🧹")
                }
                .buttonStyle(SillyButtonStyle(colors: [.red, .orange]))

                Spacer(minLength: 0)
            }
            .padding(.bottom, 18)
        }
        .frame(width: 400, height: 410)
        .onAppear { wobble = true }
    }

    func spawn(_ amount: Int) {
        for _ in 1...amount {
            openWindow(id: "popup-window", value: counter)
            counter += 1
            popupCount += 1
        }
    }

    func clearAll() {
        NotificationCenter.default.post(name: Notification.Name("ClearAllPopups"), object: nil)
        popupCount = 0
    }
}

// MARK: - Hides the red/yellow/green window buttons
struct HideTrafficLights: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Popup window
struct PopupView: View {
    let idNumber: Int
    @Environment(\.dismiss) private var dismiss

    private var config: AlertConfig {
        AlertStore.shared.configs[idNumber] ?? AlertConfig()
    }

    private var systemIcon: NSImage {
        let name = config.icon == .info ? NSImage.infoName : NSImage.cautionName
        return NSImage(named: name) ?? NSImage()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Help button, top right
            HStack {
                Spacer()
                Button(action: {}) {
                    Text("?")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.gray.opacity(0.25)))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 12)
            .padding(.trailing, 14)

            iconView
                .frame(width: 80, height: 80)
                .padding(.top, 2)

            Text(config.title)
                .font(.system(size: 15, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.top, 18)
                .padding(.horizontal, 24)

            Text(config.message)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.horizontal, 32)

            Spacer(minLength: 12)

            VStack(spacing: 10) {
                Button(action: { dismiss() }) {
                    Text(config.okLabel)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(Color.accentColor)
                        .cornerRadius(7)
                }
                .buttonStyle(.plain)

                if config.showCancel {
                    Button(action: { dismiss() }) {
                        Text(config.cancelLabel)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 30)
                            .background(Color.gray.opacity(0.25))
                            .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 18)
        }
        .frame(width: 332, height: config.showCancel ? 280 : 240)
        .background(Color(nsColor: .windowBackgroundColor))
        .background(HideTrafficLights())
        .onAppear {
            if config.playSound { AlertSound.play() }
            if config.autoClose {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { dismiss() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ClearAllPopups"))) { _ in
            dismiss()
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let emoji = config.icon.emoji {
            Text(emoji)
                .font(.system(size: 62))
        } else {
            Image(nsImage: systemIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}
