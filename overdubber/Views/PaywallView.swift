import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var theme
    var purchaseManager: PurchaseManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    benefitsSection
                    purchaseSection
                    restoreSection
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                            .font(.title2)
                    }
                }
            }
        }
        .onChange(of: purchaseManager.isPremium) { _, isPremium in
            if isPremium {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                dismiss()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(theme.current.accent)
                .padding(.top, 8)

            Text("Upgrade to Premium")
                .font(.title)
                .fontWeight(.bold)

            Text("Unlock the full power of Overdubber")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            benefitRow(icon: "square.stack.3d.up", title: "Unlimited Layers", subtitle: "Stack as many layers as you need")
            benefitRow(icon: "square.stack.3d.down.right", title: "Export Stems", subtitle: "Export individual tracks for mixing in your DAW")
            benefitRow(icon: "eye.slash", title: "No Ads", subtitle: "Clean, distraction-free experience")
            benefitRow(icon: "paintbrush", title: "Themes", subtitle: "Porta, Synth, Sampler color themes")
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func benefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(theme.current.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if let product = purchaseManager.product {
                Text("One-time purchase")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    Task { try? await purchaseManager.purchase() }
                } label: {
                    HStack {
                        if purchaseManager.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Upgrade for \(product.displayPrice)")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.current.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(purchaseManager.isLoading)
            } else if purchaseManager.productLoadFailed {
                VStack(spacing: 8) {
                    Text("Unable to load product")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        Task { await purchaseManager.loadProducts() }
                    }
                    .font(.subheadline)
                    .foregroundStyle(theme.current.accent)
                }
            } else {
                ProgressView("Loading...")
            }

            if let error = purchaseManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var restoreSection: some View {
        Button {
            Task { await purchaseManager.restorePurchases() }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundStyle(theme.current.accent)
        }
        .disabled(purchaseManager.isLoading)
        .padding(.bottom, 8)
    }
}
