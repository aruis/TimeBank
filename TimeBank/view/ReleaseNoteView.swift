//
//  ReleaseNoteView.swift
//  TimeBank
//
//  Created by Codex on 2026/3/26.
//

import SwiftUI

struct ReleaseNoteView: View {
    let note: ReleaseNote
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                header

                ScrollView {
                    featureList
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: .infinity)

                Spacer(minLength: 8)

                confirmButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(releaseBackgroundColor.ignoresSafeArea())
        }
#if !os(macOS)
        .toolbar(.hidden, for: .navigationBar)
#endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image("TimeBankLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Spacer()

                Button {
                    onConfirm()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("关闭更新说明")
            }

            Text("版本更新")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("v\(note.version)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(note.features.enumerated()), id: \.offset) { index, feature in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.orange)
                        .padding(.top, 2)

                    Text(feature)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(releaseCardColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .accessibilityLabel("更新\(index + 1): \(feature)")
            }
        }
    }

    private var confirmButton: some View {
        Button {
            onConfirm()
        } label: {
            Text("我知道了")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.orange)
                )
        }
        .buttonStyle(.plain)
    }

    private var releaseBackgroundColor: Color {
#if os(macOS)
        Color(nsColor: .windowBackgroundColor)
#else
        Color(uiColor: .systemGroupedBackground)
#endif
    }

    private var releaseCardColor: Color {
#if os(macOS)
        Color(nsColor: .controlBackgroundColor)
#else
        Color(uiColor: .secondarySystemGroupedBackground)
#endif
    }
}

#if DEBUG
struct ReleaseNoteView_Previews: PreviewProvider {
    static var previews: some View {
        ReleaseNoteView(
            note: ReleaseNote(
                version: "1.25.2",
                features: [
                    "设置页面改成了更清晰的分组布局",
                    "新增了“更多应用”推荐区域，可以直接查看 BookTime 和 PinTime",
                    "优化了设置页的品牌展示与通知引导"
                ]
            ),
            onConfirm: {}
        )
    }
}
#endif
