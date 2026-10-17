//
//  Safety_FirstApp.swift
//  Safety First
//
//  Created by Farzana  on 9/18/23.
//
// Safety_FirstApp
// SwiftUI is Apple's framework for building the user interface.
import SwiftUI
// CryptoKit = Apple's API for hashing (turning the password into a scrambled fingerprint we can compare safely).
import CryptoKit
// Security = Apple's Keychain API (encrypted storage for passwords).
import Security

// @main marks where the app starts. iOS runs this struct first when the app launches.
@main
// The app itself. ": App" means this struct describes an app (not a single screen).
struct Safety_FirstAppswift: App {
    // calling network and bluetooth.
    @StateObject private var network = NetworkMonitor()
    @StateObject private var bluetooth = BluetoothMonitor()
    // Tracks whether the user is signed in. Lives in AppSession (below) so any screen can log out.
    // It isn't saved to disk, so the user has to log in again every time the app is relaunched.
    @StateObject private var session = AppSession()

    init() {
        // Moves any old plain-text password into the Keychain, and resets the Keychain on a fresh install.
        PasswordVault.prepareOnLaunch()
        // Deletes any Gemini key saved by an earlier version (the app only uses OpenAI now).
        AIKeyVault.removeUnusedKeys()
    }

    // "body" describes the app's scenes (windows). An iPhone app normally has just one.
    var body: some Scene {
        // WindowGroup = the app's main window.
        WindowGroup {
            // Show the home screen only after a successful login; otherwise show the login screen.
            if session.isLoggedIn {
                // The first screen shown: ContentView (in ContentView.swift), which holds the 5 business tabs.
                ContentView()
                    // Share these with every screen. These modifiers must come AFTER the view they attach to.
                    .environmentObject(network)
                    .environmentObject(bluetooth)
                    .environmentObject(session)
            } else {
                // $session.isLoggedIn passes a "binding", so LoginView can flip it to true when the password is correct.
                LoginView(isLoggedIn: $session.isLoggedIn)
            }
        }
    }
}

// AppSession holds the signed-in state. It's an ObservableObject so the app switches screens
// automatically when isLoggedIn changes (log in -> home screen, log out -> login screen).
final class AppSession: ObservableObject {
    @Published var isLoggedIn = false

    // Called by the Log Out buttons (Home ••• menu and Settings tab).
    func logOut() {
        withAnimation { isLoggedIn = false }
    }
}

// note: - Login screen
// The starting username. Not "private", because Settings > Profile & Settings also shows it.
let validUsername = "admin"

// PasswordVault keeps the password safe:
//  - The password itself is never stored. Only its SHA-256 "hash" (a one-way fingerprint) is kept.
//  - A changed password's hash is stored in the iOS Keychain (encrypted), not in UserDefaults.
//  - The default password's hash is below, so the real password doesn't appear in the code.
enum PasswordVault {
    // SHA-256 hash of the default password (the one you were given for this demo).
    private static let defaultPasswordHash = "9a72c3f322b7c34eef4c4558f6114664956bbcd448da5fa4377185a188b6a4ce"
    // Labels that identify our item inside the Keychain.
    private static let service = "TheWealthApp.login"
    private static let account = "passwordHash"

    // Turns text into its SHA-256 hash, written as 64 hex characters.
    static func hash(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    // True when the typed password matches the saved one (or the default, if it was never changed).
    static func matches(_ password: String) -> Bool {
        hash(password) == (readStoredHash() ?? defaultPasswordHash)
    }

    // Saves a new password (as a hash) in the Keychain.
    static func setPassword(_ password: String) {
        let base = baseQuery
        SecItemDelete(base as CFDictionary)   // remove the old one first, if any
        var add = base
        add[kSecValueData as String] = Data(hash(password).utf8)
        // Only readable while the phone is unlocked, and never copied to other devices or backups.
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    // Runs once at every launch.
    static func prepareOnLaunch() {
        let defaults = UserDefaults.standard
        // Keychain items survive deleting the app, but UserDefaults don't. So if this flag is missing,
        // this is a fresh install: clear any old password so reinstalling resets it to the default
        // (that's what the Help screen promises).
        if !defaults.bool(forKey: "app.hasLaunchedBefore") {
            SecItemDelete(baseQuery as CFDictionary)
            defaults.set(true, forKey: "app.hasLaunchedBefore")
        }
        // Older versions of the app saved a changed password as plain text. Move it into the Keychain and erase it.
        if let oldPassword = defaults.string(forKey: "login.password") {
            setPassword(oldPassword)
            defaults.removeObject(forKey: "login.password")
        }
    }

    // The search "address" of our Keychain item.
    private static var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    // Reads the saved hash from the Keychain. nil = the password was never changed.
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

// Face ID is offered automatically only once per launch (not again right after you log out).
private var didOfferFaceIDThisLaunch = false

// Below code is just for Login -.-
// Below code is what shows FIRST when opening app. if login is successful, you're able to proceed.
struct LoginView: View {
    // @Binding means this value belongs to the parent (the App above); changing it here changes it there.
    @Binding var isLoggedIn: Bool
    // What the user has typed into each box.
    @State private var username = ""
    @State private var password = ""
    // True when the last attempt was wrong, so we can show a red error message.
    @State private var showError = false
    // The saved username (shared with Settings > Profile & Settings). Uses the default above until changed.
    @AppStorage("login.username") private var savedUsername = validUsername
    // Turned on in Settings > Profile & Settings. When on, Face ID can be used instead of the password.
    @AppStorage("login.faceID") private var faceIDEnabled = false

    // Show the Face ID button only if it's turned on AND this phone has Face ID set up.
    private var canUseFaceID: Bool { faceIDEnabled && BiometricAuth.isAvailable }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            // App logo / title area. brandColor is defined in ContentView.swift.
            Image(systemName: "dollarsign.building.classical")
                .font(.system(size: 64))
                .foregroundColor(brandColor)
            Text("The Wealth App")
                .font(.largeTitle).bold()
                .foregroundColor(brandColor)
            Text("Sign in to continue")
                .foregroundColor(.secondary)

            // Username box. Turn off auto-capitalization and autocorrect so "admin" isn't changed to "Admin".
            TextField("Username", text: $username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            // SecureField hides the characters as dots.
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                // Pressing Return on the keyboard also tries to log in.
                .onSubmit(attemptLogin)

            // Only shown after a wrong attempt.
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
            // Grey out the button until both boxes have something in them.
            .disabled(username.isEmpty || password.isEmpty)
            .opacity(username.isEmpty || password.isEmpty ? 0.5 : 1)

            // Face ID login (BiometricAuth.swift).
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
        // When the app first opens, show the Face ID prompt right away (if it's turned on).
        .onAppear {
            if canUseFaceID && !didOfferFaceIDThisLaunch {
                didOfferFaceIDThisLaunch = true
                attemptFaceID()
            }
        }
    }

    // Shows the Face ID prompt; logs in if it's the phone's owner.
    private func attemptFaceID() {
        Task {
            if await BiometricAuth.authenticate(reason: "Log in to The Wealth App.") {
                showError = false
                withAnimation { isLoggedIn = true }
            }
        }
    }

    // Compares what was typed against the saved username and the password in PasswordVault.
    private func attemptLogin() {
        // Trim spaces from the username in case the keyboard added one.
        if username.trimmingCharacters(in: .whitespaces) == savedUsername && PasswordVault.matches(password) {
            showError = false
            password = ""   // don't keep the password in memory after logging in
            // withAnimation makes the switch to the home screen fade in smoothly.
            withAnimation { isLoggedIn = true }
        } else {
            showError = true
            password = ""   // clear the password box so they can retype it
        }
    }
}

// Lets you see the login screen in Xcode's Canvas preview.
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))
    }
}
