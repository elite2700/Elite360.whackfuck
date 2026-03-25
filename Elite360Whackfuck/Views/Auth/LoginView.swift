import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var displayName = ""
    @State private var username = ""
    @State private var showResetPassword = false

    private var isEmailValid: Bool {
        let pattern = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
        return email.wholeMatch(of: pattern) != nil
    }

    private var isPasswordValid: Bool {
        password.count >= 8
    }

    private var canSubmit: Bool {
        isEmailValid && isPasswordValid && (!isSignUp || (!displayName.isEmpty && !username.isEmpty))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Color(red: 0, green: 0.15, blue: 0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    VStack(spacing: 8) {
                        Image("Elite360WF")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                        Text("by The Elite360 Corporation")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 20)

                    // Form Fields
                    VStack(spacing: 16) {
                        if isSignUp {
                            StyledTextField(text: $displayName, placeholder: "Full Name", icon: "person")
                            StyledTextField(text: $username, placeholder: "Username", icon: "at")
                        }

                        StyledTextField(text: $email, placeholder: "Email", icon: "envelope")
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)

                        StyledTextField(text: $password, placeholder: "Password", icon: "lock", isSecure: true)

                        if !email.isEmpty && !isEmailValid {
                            Text("Enter a valid email address")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        if !password.isEmpty && !isPasswordValid {
                            Text("Password must be at least 8 characters")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.horizontal, 32)

                    // Error
                    if let error = authVM.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // Primary Action
                    Button {
                        Task {
                            if isSignUp {
                                await authVM.signUp(
                                    email: email,
                                    password: password,
                                    displayName: displayName,
                                    username: username
                                )
                            } else {
                                await authVM.signIn(email: email, password: password)
                            }
                        }
                    } label: {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)

                    // Toggle Sign Up / Sign In
                    Button {
                        withAnimation { isSignUp.toggle() }
                    } label: {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }

                    if !isSignUp {
                        Button("Forgot Password?") {
                            showResetPassword = true
                        }
                        .font(.caption)
                        .foregroundStyle(.gray)
                    }

                    // Divider
                    HStack {
                        Rectangle().fill(.gray.opacity(0.3)).frame(height: 1)
                        Text("OR").font(.caption).foregroundStyle(.gray)
                        Rectangle().fill(.gray.opacity(0.3)).frame(height: 1)
                    }
                    .padding(.horizontal, 32)

                    // Apple Sign-In
                    SignInWithAppleButton(.signIn) { request in
                        let hash = authVM.prepareAppleSignIn()
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = hash
                    } onCompletion: { result in
                        Task { await authVM.handleAppleSignIn(result: result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 32)

                    Spacer(minLength: 40)

                    // Disclaimer
                    Text("Elite360.Whackfuck is for entertainment purposes only.\nNo real-money gambling facilitation.")
                        .font(.caption2)
                        .foregroundStyle(.gray.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)
                }
            }
        }
        .alert("Reset Password", isPresented: $showResetPassword) {
            TextField("Email", text: $email)
            Button("Send Reset Link") {
                Task { await authVM.resetPassword(email: email) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct StyledTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .foregroundStyle(.white)
        .padding()
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.green.opacity(0.3)))
    }
}
