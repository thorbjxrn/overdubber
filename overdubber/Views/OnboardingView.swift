import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            onboardingPage(
                icon: "waveform.circle",
                title: "Record",
                description: "Tap the record button to capture your first layer",
                page: 0
            )

            onboardingPage(
                icon: "square.stack.3d.up",
                title: "Overdub",
                description: "Add layers on top — hear previous takes while you record new ones",
                page: 1
            )

            onboardingPage(
                icon: "slider.vertical.3",
                title: "Mix & Export",
                description: "Adjust volumes, mute layers, and export your creation",
                page: 2,
                showGetStarted: true
            )
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    private func onboardingPage(
        icon: String,
        title: String,
        description: String,
        page: Int,
        showGetStarted: Bool = false
    ) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(.red)

            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            if showGetStarted {
                Button {
                    hasSeenOnboarding = true
                } label: {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            } else {
                Spacer().frame(height: 80)
            }
        }
        .tag(page)
    }
}
