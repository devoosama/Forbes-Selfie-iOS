import SwiftUI

struct MainView: View {
    @StateObject private var vm = MainViewModel()
    @State private var focusedField: Int? = nil

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "#07091A"), Color(hex: "#0A0F1E"), Color(hex: "#07091A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle radial glow
            RadialGradient(
                colors: [Color(hex: "#0EA5E9").opacity(0.06), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 52)

                    // MARK: Logo Section
                    logoSection

                    Spacer().frame(height: 36)

                    GlowDivider()
                        .padding(.horizontal, 48)

                    Spacer().frame(height: 36)

                    // MARK: Code Card
                    codeCard

                    Spacer().frame(height: 28)

                    // MARK: Start Button
                    startButton

                    Spacer().frame(height: 32)

                    // MARK: Status Section
                    statusSection

                    Spacer().frame(height: 40)

                    // Version
                    Text("FacePass v1.0.0")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(hex: "#1E3A5F"))

                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .onTapGesture { focusedField = nil }
        .sheet(isPresented: $vm.showBrowser) {
            BrowserView(url: vm.browserURL!, customUA: vm.sessionUA)
                .ignoresSafeArea()
        }
        .alert(vm.alertTitle, isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
    }

    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(spacing: 12) {
            // Circle with icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "#0A2540"), Color(hex: "#070D1C")],
                            center: .center,
                            startRadius: 0,
                            endRadius: 56
                        )
                    )
                    .frame(width: 112, height: 112)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#0EA5E9").opacity(0.8), lineWidth: 1.5)
                    )
                    .shadow(color: Color(hex: "#0EA5E9").opacity(0.25), radius: 18)

                FaceDetectionIcon()
                    .frame(width: 64, height: 64)
            }

            Spacer().frame(height: 6)

            // FORBES SELFIE title
            VStack(spacing: 2) {
                Text("FACE")
                    .font(.system(size: 38, weight: .black, design: .default))
                    .foregroundColor(.white)
                    .tracking(6)

                Text("P A S S")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "#0EA5E9"))
                    .tracking(4)
            }

            Text("Biometric Identity System")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(hex: "#4A6A8A"))
        }
    }

    // MARK: - Code Card
    private var codeCard: some View {
        VStack(spacing: 20) {
            // Card label
            HStack {
                Rectangle()
                    .fill(Color(hex: "#0EA5E9"))
                    .frame(width: 3, height: 14)
                    .cornerRadius(2)
                Text("SESSION CODE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#4A6A8A"))
                    .tracking(2)
                Spacer()
            }

            // OTP boxes
            OTPInputView(code: $vm.code, focusedField: $focusedField)

            // Error message
            if !vm.errorMessage.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#EF4444"))
                    Text(vm.errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#EF4444"))
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "#0A0F1E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "#1A2744"), lineWidth: 1.5)
                )
                .shadow(color: Color(hex: "#0EA5E9").opacity(0.05), radius: 20)
        )
        .cardBrackets(padding: 12)
        .animation(.easeInOut(duration: 0.2), value: vm.errorMessage)
    }

    // MARK: - Start Button
    private var startButton: some View {
        Button(action: vm.startSession) {
            ZStack {
                if vm.isLoading {
                    HStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.85)
                        Text("CONNECTING...")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(2)
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("START SESSION")
                            .font(.system(size: 15, weight: .black, design: .default))
                            .tracking(2)
                    }
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                vm.codeIsFull && !vm.isLoading
                ? AnyShapeStyle(LinearGradient(
                    colors: [Color(hex: "#0EA5E9"), Color(hex: "#0055A5")],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                : AnyShapeStyle(Color(hex: "#111827"))
            )
            .cornerRadius(16)
            .shadow(
                color: vm.codeIsFull && !vm.isLoading
                    ? Color(hex: "#0EA5E9").opacity(0.35)
                    : .clear,
                radius: 12
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        vm.codeIsFull && !vm.isLoading
                            ? Color.clear
                            : Color(hex: "#1A2744"),
                        lineWidth: 1
                    )
            )
        }
        .disabled(!vm.codeIsFull || vm.isLoading)
        .animation(.easeInOut(duration: 0.2), value: vm.codeIsFull)
        .animation(.easeInOut(duration: 0.2), value: vm.isLoading)
    }

    // MARK: - Status Section
    private var statusSection: some View {
        HStack(spacing: 10) {
            // Dot
            Circle()
                .fill(vm.statusDotColor)
                .frame(width: 8, height: 8)
                .shadow(color: vm.statusDotColor.opacity(0.7), radius: 4)

            Text(vm.statusText)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(vm.statusTextColor)

            Spacer()
        }
        .padding(.horizontal, 4)
        .animation(.easeInOut(duration: 0.3), value: vm.statusText)
    }
}

#Preview {
    MainView()
}
