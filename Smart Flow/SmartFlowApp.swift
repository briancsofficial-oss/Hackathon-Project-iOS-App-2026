import SwiftUI
import CryptoKit
import Security

@main
struct SmartFlowApp: App {
    @StateObject private var network = NetworkMonitor()
    @StateObject private var bluetooth = BluetoothMonitor()
    @StateObject private var session = AppSession()

    init() {
        PasswordVault.prepareOnLaunch()
        AIKeyVault.removeUnusedKeys()
    }

    var body: some Scene {
        WindowGroup {
            if session.isLoggedIn {
                ContentView()
                    .environmentObject(network)
                    .environmentObject(bluetooth)
                    .environmentObject(session)
            } else {
                LoginView(isLoggedIn: $session.isLoggedIn)
            }
        }
    }
}

final class AppSession: ObservableObject {
    @Published var isLoggedIn = false

    func logOut() {
        withAnimation { isLoggedIn = false }
    }
}

let validUsername = "admin"

enum PasswordVault {
    private static let defaultPasswordHash = "9a72c3f322b7c34eef4c4558f6114664956bbcd448da5fa4377185a188b6a4ce"
    private static let service = "SmartFlow.login"
    private static let account = "passwordHash"

    static func hash(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    static func matches(_ password: String) -> Bool {
        hash(password) == (readStoredHash() ?? defaultPasswordHash)
    }

    static func setPassword(_ password: String) {
        let base = baseQuery
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = Data(hash(password).utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    static func prepareOnLaunch() {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "app.hasLaunchedBefore") {
            SecItemDelete(baseQuery as CFDictionary)
            defaults.set(true, forKey: "app.hasLaunchedBefore")
        }
        if let oldPassword = defaults.string(forKey: "login.password") {
            setPassword(oldPassword)
            defaults.removeObject(forKey: "login.password")
        }
    }

    private static var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    private static func readStoredHash() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

private var didOfferFaceIDThisLaunch = false

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var username = ""
    @State private var password = ""
    @State private var showError = false
    @AppStorage("login.username") private var savedUsername = validUsername
    @AppStorage("login.faceID") private var faceIDEnabled = false

    private var canUseFaceID: Bool { faceIDEnabled && BiometricAuth.isAvailable }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "dollarsign.building.classical")
                .font(.system(size: 64))
                .foregroundColor(brandColor)
            Text("Smart Flow")
                .font(.largeTitle).bold()
                .foregroundColor(brandColor)
            Text("Sign in to continue")
                .foregroundColor(.secondary)

            TextField("Username", text: $username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .onSubmit(attemptLogin)

            if showError {
                Text("Incorrect username or password.")
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button(action: attemptLogin) {
                Text("Log In")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(brandColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(username.isEmpty || password.isEmpty)
            .opacity(username.isEmpty || password.isEmpty ? 0.5 : 1)

            if canUseFaceID {
                Button(action: attemptFaceID) {
                    Label("Log in with \(BiometricAuth.name)", systemImage: "faceid")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(brandColor)
                        .background(RoundedRectangle(cornerRadius: 10).stroke(brandColor, lineWidth: 1.5))
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            if canUseFaceID && !didOfferFaceIDThisLaunch {
                didOfferFaceIDThisLaunch = true
                attemptFaceID()
            }
        }
    }

    private func attemptFaceID() {
        Task {
            if await BiometricAuth.authenticate(reason: "Log in to Smart Flow.") {
                showError = false
                withAnimation { isLoggedIn = true }
            }
        }
    }

    private func attemptLogin() {
        if username.trimmingCharacters(in: .whitespaces) == savedUsername && PasswordVault.matches(password) {
            showError = false
            password = ""
            withAnimation { isLoggedIn = true }
        } else {
            showError = true
            password = ""
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))
    }
}
