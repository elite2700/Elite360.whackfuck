import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isLoading {
                SplashView()
            } else if authVM.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authVM.isAuthenticated)
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "figure.golf")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                Text("Elite360")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("WHACKFUCK")
                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.green)
                    .tracking(6)
                ProgressView()
                    .tint(.green)
                    .padding(.top, 24)
            }
        }
    }
}
