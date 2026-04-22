//
//  SettingView.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2024/1/25.
//

import SwiftUI
import UserNotifications

struct SettingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSetting

    @State private var showingAlert = false
    @State private var logoAnimating = false

    private let recommendedApps: [RecommendedApp] = [
        .init(
            name: "BookTime",
            tagline: String(localized: "Your Reading Timer Companion"),
            assetName: "booktime_icon",
            appStoreURL: URL(string: "https://apps.apple.com/cn/app/booktime-%E6%82%A8%E7%9A%84%E9%98%85%E8%AF%BB%E8%AE%A1%E6%97%B6%E4%BC%B4%E4%BE%A3/id1600654269")!,
            accent: .orange
        ),
        .init(
            name: "PinTime",
            tagline: String(localized: "Mark Your Important Moments"),
            assetName: "PinTimeLogo",
            appStoreURL: URL(string: "https://apps.apple.com/cn/app/pintime-%E6%A0%87%E8%AE%B0%E6%82%A8%E7%9A%84%E9%87%8D%E8%A6%81%E6%97%B6%E5%88%BB/id6757686170")!,
            accent: .indigo
        )
    ]

    var body: some View {
        NavigationStack {
            List {
                brandHeader

                Section("Notifications") {
                    SettingsToggleRow(
                        title: String(localized: "Enable Timer Notifications"),
                        subtitle: String(localized: "Send a notification when the countdown ends"),
                        icon: "bell.badge.fill",
                        color: .red,
                        isOn: $settings.isTimerEnabled
                    )
                    .onChange(of: settings.isTimerEnabled) {
                        handleTimerToggleChanged()
                    }

                    if settings.isTimerEnabled {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Label("Duration", systemImage: "timer")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(
                                    String(
                                        format: String(localized: "%lld minutes"),
                                        locale: Locale.current,
                                        Int(settings.timerDuration)
                                    )
                                )
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }

                            Slider(
                                value: $settings.timerDuration,
                                in: 0...60,
                                step: 5
                            ) {
                                Text("Timer Duration")
                            } minimumValueLabel: {
                                Text("0")
                            } maximumValueLabel: {
                                Text("60")
                            }
                            .tint(.red)
                        }
                        .padding(.vertical, 6)
                    }
                }

                Section("Conversion") {
                    SettingsToggleRow(
                        title: String(localized: "Enable Rate Mode"),
                        subtitle: String(localized: "Convert time value based on the configured ratio"),
                        icon: "scale.3d",
                        color: .blue,
                        isOn: $settings.isEnableRate
                    )
                }

                Section("Theme") {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("SaveTime / KillTime Colors", systemImage: "paintpalette.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        HStack(spacing: 12) {
                            colorThemeOption(
                                title: String(localized: "Default"),
                                saveColor: .red,
                                killColor: .green,
                                isSelected: !settings.swapThemeColors
                            ) {
                                settings.swapThemeColors = false
                            }

                            colorThemeOption(
                                title: String(localized: "Swapped"),
                                saveColor: .green,
                                killColor: .red,
                                isSelected: settings.swapThemeColors
                            ) {
                                settings.swapThemeColors = true
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Support") {
                    Link(destination: URL(string: "mailto:eastern.howls0a@icloud.com")!) {
                        SettingsLinkRow(
                            title: String(localized: "Feedback"),
                            subtitle: String(localized: "Share your thoughts with me"),
                            icon: "envelope.fill",
                            color: .gray
                        )
                    }
                    .buttonStyle(.plain)

                    Link(destination: URL(string: "https://apps.apple.com/cn/app/timebank-%E6%97%B6%E9%97%B4%E6%98%AF%E4%BD%A0%E5%94%AF%E4%B8%80%E6%8B%A5%E6%9C%89%E7%9A%84%E4%B8%9C%E8%A5%BF/id6474505609?action=write-review")!) {
                        SettingsLinkRow(
                            title: String(localized: "Support Me"),
                            subtitle: String(localized: "Leave a review on the App Store"),
                            icon: "heart.fill",
                            color: .pink
                        )
                    }
                    .buttonStyle(.plain)
                }

                Section("More Apps") {
                    ForEach(recommendedApps) { app in
                        Link(destination: app.appStoreURL) {
                            RecommendedAppRow(app: app)
                        }
                        .buttonStyle(.plain)
                    }
                }

                footerView
            }
            .alert("Notification Permission Required", isPresented: $showingAlert) {
                #if os(iOS) || os(visionOS)
                Button("Open Settings") {
                    settings.openAppSettings()
                }
                #endif
                Button("Got it", role: .cancel) {}
            } message: {
                Text("Please enable TimeBank notification permissions in Settings before using the timer.")
            }
#if os(macOS)
            .frame(width: 460, height: 560, alignment: .topLeading)
            .padding()
#endif
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
#elseif !os(watchOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
#endif
            }
            .navigationTitle("Settings")
#if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
#if !os(visionOS)
            .sensoryFeedback(.selection, trigger: settings.timerDuration)
#endif
        }
    }

    private func handleTimerToggleChanged() {
        guard settings.isTimerEnabled else { return }

        Task {
            let result = await settings.requestNotificationPermission()
            switch result {
            case .success(let granted):
                if !granted {
                    showingAlert = true
                }
            case .failure(let error):
                print(error)
                showingAlert = true
            }
        }
    }

    private var brandHeader: some View {
        VStack(spacing: 20) {
            Image("TimeBankLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                }
                .shadow(color: Color.orange.opacity(0.18), radius: 18, y: 10)
                .background {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(logoAnimating ? 0.24 : 0.12))
                            .frame(width: 160, height: 160)
                            .blur(radius: logoAnimating ? 34 : 22)
                            .offset(x: -20)

                        Circle()
                            .fill(Color.green.opacity(logoAnimating ? 0.20 : 0.10))
                            .frame(width: 150, height: 150)
                            .blur(radius: logoAnimating ? 38 : 24)
                            .offset(x: 24, y: 6)
                    }
                    .blendMode(.screen)
                    .scaleEffect(logoAnimating ? 1.08 : 0.92)
                    .frame(width: 10, height: 10)
                }

            VStack(spacing: 6) {
                Text("TimeBank")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Time is the only thing you truly own")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 28)
        .padding(.bottom, 12)
        .listRowBackground(Color.clear)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true)) {
                    logoAnimating = true
                }
            }
        }
    }

    @ViewBuilder
    private func colorThemeOption(
        title: String,
        saveColor: Color,
        killColor: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(saveColor.gradient)
                        .frame(maxWidth: .infinity)
                        .frame(height: 22)

                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(killColor.gradient)
                        .frame(maxWidth: .infinity)
                        .frame(height: 22)
                }

                HStack(spacing: 6) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    Text(isSelected ? "Current Selection" : "Tap to Switch")
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.white.opacity(0.12), lineWidth: 1)
                    }
            }
            .saturation(isSelected ? 1 : 0.45)
            .opacity(isSelected ? 1 : 0.78)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private var footerView: some View {
        VStack(spacing: 6) {
            Text(
                String(
                    format: String(localized: "Version %@"),
                    locale: Locale.current,
                    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                )
            )
            Text("苏ICP备2024057896号-3A")
        }
        .font(.caption)
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .listRowBackground(Color.clear)
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 2)
    }

    private var iconView: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

private struct SettingsLinkRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

private struct RecommendedApp: Identifiable {
    let id = UUID()
    let name: String
    let tagline: String
    let assetName: String
    let appStoreURL: URL
    let accent: Color
}

private struct RecommendedAppRow: View {
    let app: RecommendedApp

    var body: some View {
        HStack(spacing: 10) {
            Image(app.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(app.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(app.tagline)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 8)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(app.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingView()
        .environmentObject(AppSetting())
}
