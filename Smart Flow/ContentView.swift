import SwiftUI

private func adaptive(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
    Color(UIColor { traits in
        let c = traits.userInterfaceStyle == .dark ? dark : light
        return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
    })
}

let brandColor = adaptive(light: (0.07, 0.07, 0.07), dark: (0.45, 0.45, 0.45))
let pageBackground = adaptive(light: (0.96, 0.93, 0.89), dark: (0.07, 0.07, 0.07))
let cardBackground = adaptive(light: (1.0, 1.0, 1.0), dark: (0.13, 0.13, 0.13))
let confirmGreen = adaptive(light: (0.13, 0.47, 0.36), dark: (0.35, 0.78, 0.58))

let cream = Color(red: 0.96, green: 0.93, blue: 0.89)
let accentTeal = adaptive(light: (0.89, 0.97, 0.94), dark: (0.09, 0.22, 0.18))
let accentTealText = adaptive(light: (0.06, 0.15, 0.29), dark: (0.89, 0.97, 0.94))
let highlightBackground = adaptive(light: (0.97, 0.72, 0.79), dark: (0.42, 0.24, 0.31))

extension View {
    @ViewBuilder func creamListBackground() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden).background(pageBackground.ignoresSafeArea())
        } else {
            self
        }
    }
}

struct AccountSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 2)

            VStack(spacing: 0) {
                content
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

struct AppInfoView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: "dollarsign.building.classical")
                    .font(.system(size: 64))
                    .foregroundColor(brandColor)
                    .padding(.top, 32)
                Text("Smart Flow")
                    .font(.title).bold()
                    .foregroundColor(brandColor)
                Text("Version \(version)")
                    .foregroundColor(.secondary)
                Text("Copyright © 2026, BrianSanchez LLC. All rights reserved.\n\nCreated in Xcode with Swift, using Apple SDKs. Any trademarks therein are registered in the U.S. and other countries.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
            }
            .frame(maxWidth: .infinity)
        }
        .background(pageBackground)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CopyrightPrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Copyright and Educational Project Notice")
                    .font(.headline)
                Text("© 2026 Brian Sanchez. All rights reserved in original material, subject to applicable law and third-party licenses.")
                Text("This application was created by Brian Sanchez in 2026 using the Swift programming language as an educational project at the University of Wisconsin–Green Bay. Its purpose is to demonstrate software development skills and explore banking application interfaces and functionality.")
                Text("Certain aspects of this application were inspired by existing banking applications for educational study. Similarities may reflect common interface conventions, educational exploration, or coincidence. No affiliation with, sponsorship by, or endorsement from any bank, financial institution, or other application developer is claimed or implied. Reference to the University of Wisconsin–Green Bay identifies the academic context of the project and does not imply university endorsement.")
                Text("Copyright is claimed only in original code, text, graphics, and other protectable material authored and owned by Brian Sanchez. Any third-party code, images, names, logos, trademarks, or other materials remain the property of their respective owners and are subject to applicable licenses and legal protections. This notice does not grant permission to use third-party material.")
                Text("U.S. copyright law protects original expression, subject to statutory limitations and exceptions. Fair use under 17 U.S.C. § 107 requires a case-specific assessment of the purpose and character of the use, the nature of the copyrighted work, the amount and substantiality used, and the effect on the potential market for the original work. An educational purpose alone does not establish fair use. This notice does not assert that every use of third-party material qualifies as fair use.")
                Text("This application is intended as an educational demonstration and should not be relied upon for banking services, financial advice, or real financial transactions.")

                Text("Privacy")
                    .font(.headline)
                    .padding(.top, 8)
                Text("Everything you enter (profile details and business answers) is saved on this device. Your password is never stored as plain text; only a scrambled fingerprint of it is kept in the iPhone Keychain, and your OpenAI API key is kept in the Keychain too. Face ID is checked by iOS; the app never sees your face data. When you use an AI feature, the information it needs is sent to OpenAI: the AI interview sends your messages and business answers, document import sends the files or photos you pick or take (up to 10 at a time), and the action plan sends your answers and results. The camera is used only when you choose to take a picture of a document. Nothing else is sent to any server. Bluetooth permission is used only to show whether Bluetooth is turned on. Deleting the app deletes all of its saved data.")
            }
            .font(.subheadline)
            .padding()
        }
        .background(pageBackground)
        .navigationTitle("Copyright & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileSettingsView: View {
    @AppStorage("profile.name") private var fullName = ""
    @AppStorage("profile.phone") private var phone = ""
    @AppStorage("profile.email") private var email = ""
    @AppStorage("login.username") private var username = validUsername
    @State private var showingChangePassword = false
    @AppStorage("login.faceID") private var faceIDEnabled = false

    var body: some View {
        Form {
            Section(header: Text("Profile")) {
                HStack {
                    Text("Name")
                    TextField("Full name", text: $fullName)
                        .multilineTextAlignment(.trailing)
                        .textContentType(.name)
                }
                HStack {
                    Text("Phone")
                    TextField("(555) 555-5555", text: $phone)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                HStack {
                    Text("Email")
                    TextField("name@example.com", text: $email)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }

            Section(header: Text("Sign-in")) {
                HStack {
                    Text("Username")
                    Spacer()
                    Text(username).foregroundColor(.secondary)
                }
                Button("Change Password") { showingChangePassword = true }
                if BiometricAuth.isAvailable {
                    Toggle("Log in with \(BiometricAuth.name)", isOn: Binding(
                        get: { faceIDEnabled },
                        set: { turnOn in
                            if turnOn {
                                Task {
                                    if await BiometricAuth.authenticate(reason: "Turn on \(BiometricAuth.name) login for Smart Flow.") {
                                        faceIDEnabled = true
                                    }
                                }
                            } else {
                                faceIDEnabled = false
                            }
                        }))
                } else {
                    Text("Face ID isn't set up on this device.")
                        .foregroundColor(.secondary)
                }
            }
        }
        .creamListBackground()
        .navigationTitle("Profile & Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { hideKeyboard() }
            }
        }
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordSheet()
        }
    }
}

struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var showingSuccess = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Current password", text: $currentPassword)
                }
                Section(footer: Text("Use at least 6 characters.")) {
                    SecureField("New password", text: $newPassword)
                    SecureField("Confirm new password", text: $confirmPassword)
                }
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }
            }
            .creamListBackground()
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: savePassword)
                        .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                }
            }
            .alert("Password changed", isPresented: $showingSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Use your new password the next time you log in.")
            }
        }
    }

    private func savePassword() {
        if !PasswordVault.matches(currentPassword) {
            errorMessage = "Current password is incorrect."
            currentPassword = ""
        } else if newPassword.count < 6 {
            errorMessage = "New password must be at least 6 characters."
        } else if newPassword != confirmPassword {
            errorMessage = "New passwords don't match."
            confirmPassword = ""
        } else if newPassword == currentPassword {
            errorMessage = "New password must be different from the current one."
        } else {
            PasswordVault.setPassword(newPassword)
            errorMessage = nil
            hideKeyboard()
            showingSuccess = true
        }
    }
}

struct HelpView: View {
    private struct HelpTopic: Identifiable {
        let question: String
        let answer: String
        var id: String { question }
    }

    private let topics: [HelpTopic] = [
        HelpTopic(question: "I can't log in",
                  answer: "• Username and password are case-sensitive, so check for capital letters.\n• Make sure there are no extra spaces at the end of the password.\n• If you changed your password and forgot it, deleting and reinstalling the app resets it to the original password (this also erases your saved data)."),
        HelpTopic(question: "The AI features say to add a key",
                  answer: "• Go to Settings > AI keys and paste your OpenAI API key. One key runs the interview, document import and action plan.\n• Keys come from platform.openai.com > API keys. The account needs billing or credit turned on."),
        HelpTopic(question: "The AI shows an error",
                  answer: "• Check that the phone is online (Settings > This device).\n• \"Didn't accept the API key\" means the key is wrong or was revoked: save a new one in Settings > AI keys.\n• \"Rate-limiting\" means too many requests or no credit left. Wait a minute or add credit.\n• Your answers are saved as you go, so tap Try again or restart the interview without losing anything."),
        HelpTopic(question: "Import didn't find my numbers",
                  answer: "• Clear, full-page PDFs work best. For photos (picked or taken with the camera), use good light and keep the whole page in view.\n• You can pick up to 10 files or photos at once. Each must be under 15 MB, and all together under 50 MB.\n• Anything it can't find can be typed in on Overview > Questions."),
        HelpTopic(question: "My results look wrong",
                  answer: "• Unanswered questions count as $0. Overview shows which phases still have questions left.\n• Fields marked / mo are monthly amounts; revenue is for the last 12 months. You can fix any answer on Overview > Phases."),
        HelpTopic(question: "My answers disappeared",
                  answer: "• Answers are saved on this phone only, so they won't appear on another device.\n• Deleting or reinstalling the app, or Settings > Clear all business answers, erases them."),
        HelpTopic(question: "The keyboard won't go away",
                  answer: "• Tap Done in the bar just above the keyboard."),
        HelpTopic(question: "Face ID doesn't show up",
                  answer: "• Turn it on in Settings > Profile & Settings > Log in with Face ID.\n• Make sure Face ID is set up in the iPhone's Settings > Face ID & Passcode, and that Smart Flow is allowed to use it.\n• In the Simulator, choose Features > Face ID > Enrolled."),
        HelpTopic(question: "The app is frozen or acting strange",
                  answer: "• Swipe up from the bottom of the screen (or double-press Home), swipe the app away, then reopen it.\n• Restart your iPhone.\n• Make sure iOS is up to date in Settings > General > Software Update.")
    ]

    var body: some View {
        List {
            Section(header: Text("Troubleshooting")) {
                ForEach(topics) { topic in
                    DisclosureGroup(topic.question) {
                        Text(topic.answer)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .creamListBackground()
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

func money(_ value: Double) -> String {
    value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
}

func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

struct BusinessSettingsView: View {
    @EnvironmentObject var session: AppSession
    @EnvironmentObject var network: NetworkMonitor
    @EnvironmentObject var bluetooth: BluetoothMonitor
    @ObservedObject private var store = BusinessStore.shared
    @ObservedObject private var keys = AIKeyStatus.shared
    @State private var confirmClear = false

    var body: some View {
        List {
            Section(header: Text("AI")) {
                NavigationLink(destination: AISettingsForm()) {
                    HStack {
                        Label("AI key (OpenAI)", systemImage: "key.fill")
                        Spacer()
                        Text(keySummary).foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Business data")) {
                HStack {
                    Label("Phases complete", systemImage: "checklist")
                    Spacer()
                    Text("\(store.profile.completedPhases) of \(BusinessPhase.allCases.count)").foregroundColor(.secondary)
                }
                Button(role: .destructive) {
                    confirmClear = true
                } label: {
                    Label("Clear all business answers", systemImage: "trash")
                }
                .disabled(store.profile.isEmpty)
            }

            Section(header: Text("Account")) {
                NavigationLink(destination: ProfileSettingsView()) {
                    Label("Profile & Settings", systemImage: "person.crop.circle")
                }
            }

            Section(header: Text("This device")) {
                HStack {
                    Label("Wi-Fi", systemImage: network.isOnWiFi ? "wifi" : "wifi.slash")
                    Spacer()
                    Text(network.isOnWiFi ? "Connected" : (network.isConnected ? "Using cellular" : "Offline"))
                        .foregroundColor(.secondary)
                }
                HStack {
                    Label("Bluetooth", systemImage: "antenna.radiowaves.left.and.right")
                    Spacer()
                    Text(bluetooth.statusText).foregroundColor(.secondary)
                }
            }

            Section {
                NavigationLink(destination: AppInfoView()) {
                    Label("About", systemImage: "info.circle")
                }
                NavigationLink(destination: CopyrightPrivacyView()) {
                    Label("Copyright & Privacy", systemImage: "doc.text")
                }
                NavigationLink(destination: HelpView()) {
                    Label("Help", systemImage: "questionmark.circle")
                }
            }

            Section {
                Button(role: .destructive) {
                    session.logOut()
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .listStyle(.insetGrouped)
        .creamListBackground()
        .navigationTitle("Settings")
        .confirmationDialog("Clear every business answer?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear answers", role: .destructive) { store.reset() }
        }
    }

    private var keySummary: String {
        AIKeyVault.hasKey(.openAI) ? "Saved" : "Not set"
    }
}

enum AppTab: Hashable {
    case overview, interview, importDocs, results, settings
}

enum InterviewMode: Hashable {
    case chat, phases
}

final class TabRouter: ObservableObject {
    @Published var selected: AppTab = .overview
    @Published var interviewMode: InterviewMode = .chat
}

struct ContentView: View {
    @StateObject private var router = TabRouter()

    var body: some View {
        TabView(selection: $router.selected) {
            tab { BusinessCheckupView() }
                .tabItem {
                    Text("Overview")
                    Image(systemName: "briefcase")
                }
                .tag(AppTab.overview)

            tab { BusinessInterviewView() }
                .tabItem {
                    Text("Interview")
                    Image(systemName: "bubble.left.and.text.bubble.right")
                }
                .tag(AppTab.interview)

            tab { BusinessDocumentImportView() }
                .tabItem {
                    Text("Import")
                    Image(systemName: "doc.text.viewfinder")
                }
                .tag(AppTab.importDocs)

            tab { BusinessResultsView() }
                .tabItem {
                    Text("Results")
                    Image(systemName: "chart.bar.doc.horizontal")
                }
                .tag(AppTab.results)

            tab { BusinessSettingsView() }
                .tabItem {
                    Text("Settings")
                    Image(systemName: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .environmentObject(router)
    }

    private func tab<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        NavigationView { content() }
            .navigationViewStyle(.stack)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(NetworkMonitor())
            .environmentObject(BluetoothMonitor())
            .environmentObject(AppSession())
    }
}
