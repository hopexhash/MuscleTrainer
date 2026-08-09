import SwiftUI

/// In-app privacy policy and health disclaimer.
/// The same text is served as HTML by the media server (privacy.html) for the
/// public URL App Store Connect requires.
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.spacingL) {
                Text("Effective date: August 9, 2026")
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.textTertiary)

                section("Your data stays on your iPhone",
                        """
                        MuscleTrainer stores everything it knows — your profile, saved workouts, \
                        completed sessions, favorites and preferences — locally on your device \
                        using Apple's SwiftData framework. We do not operate accounts, we do not \
                        run analytics, and we do not collect, transmit, sell or share any personal \
                        data. The app contains no third-party SDKs and no advertising.
                        """)

                section("Exercise videos (optional)",
                        """
                        If you connect a media server in Profile → Exercise videos, the app fetches \
                        a list of exercise videos and streams them from the server URL you entered. \
                        These requests go directly from your device to that server — typically one \
                        you host yourself — and contain no personal information. If you never \
                        configure a server, the app makes no network requests at all.
                        """)

                section("Deleting your data",
                        """
                        Deleting the app removes all locally stored data. There is nothing to \
                        delete on our side, because nothing ever leaves your device.
                        """)

                section("Health & safety",
                        """
                        MuscleTrainer provides general fitness information, not medical advice. \
                        Consult a physician before starting a new exercise program, stop if you \
                        feel pain or discomfort, and train within your abilities. You are \
                        responsible for exercising safely.
                        """)

                section("Children",
                        "MuscleTrainer is not directed at children under 13.")

                section("Changes",
                        """
                        If this policy changes, the updated version ships with the app update and \
                        is published at the same URL, with a new effective date.
                        """)
            }
            .padding(DS.spacingL)
        }
        .background(AppColor.background)
        .navigationTitle("Privacy & Terms")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: DS.spacingS) {
            Text(title)
                .font(AppFont.sectionTitle)
                .kerning(-0.5)
                .foregroundStyle(AppColor.textPrimary)
            Text(body)
                .font(.system(size: 15))
                .lineSpacing(3)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
