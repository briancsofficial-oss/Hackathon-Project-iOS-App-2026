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
                Text("A small-business financial checkup built for the UWGB Hackathon.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                VStack(spacing: 6) {
                    Text("Lead developer")
                        .font(.caption).foregroundColor(.secondary)
                    Text("Brian Sanchez")
                        .font(.headline)
                    Text("Team")
                        .font(.caption).foregroundColor(.secondary)
                        .padding(.top, 8)
                    Text("Chaewon · Jasmin · Sarah")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(cardBackground))
                .padding(.horizontal)

                Text("Copyright © 2026 UWGB Hackathon Group. All rights reserved.\n\nBuilt in Xcode with Swift and Apple SDKs. AI features use the OpenAI API. Apple, Face ID and OpenAI are trademarks of their respective owners.")
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
                Text("Copyright")
                    .font(.headline)
                Text("© 2026 UWGB Hackathon Group. Lead developer: Brian Sanchez. Team: Chaewon, Jasmin and Sarah. All rights reserved in the original code, text and design of Smart Flow.")
                Text("Smart Flow was created at the University of Wisconsin–Green Bay Hackathon as an educational project. It helps small-business owners check their finances: cash flow, cash runway, debt coverage and payroll share, with an AI interview, document import and an AI-written action plan. Naming the University of Wisconsin–Green Bay identifies where the project was made and does not imply university endorsement.")
                Text("Smart Flow is not affiliated with, sponsored by or endorsed by OpenAI, Apple, any bank or any other financial institution. Third-party names, trademarks, code and services belong to their owners and are used under their own terms.")

                Text("Not financial advice")
                    .font(.headline)
                    .padding(.top, 8)
                Text("Smart Flow gives educational estimates only. Its numbers depend on the answers you enter, and unanswered questions count as $0. AI suggestions, document readings and action plans can be wrong or incomplete, so check them before relying on them. For tax, legal, lending or investment decisions, talk to a CPA or a qualified advisor. Smart Flow does not move money or connect to bank accounts.")

                Text("Privacy")
                    .font(.headline)
                    .padding(.top, 8)
                Text("What stays on your iPhone: your profile details, business answers, your latest action plan and app settings are saved only on this device. Your password is never stored as plain text; only a scrambled fingerprint of it is kept in the iPhone Keychain, along with your OpenAI API key. Face ID is checked by iOS; Smart Flow never sees your face data.")
                Text("What is sent to OpenAI, and only when you use an AI feature: the AI interview sends your messages and business answers; document import sends the files or photos you pick or take (up to 10 at a time); the action plan sends your answers and the results Smart Flow calculated. OpenAI handles this data under its own terms and privacy policy. Nothing else is sent to any server, and Smart Flow has no account system, ads or analytics.")
                Text("Permissions: the camera is used only when you choose to take a picture of a document, and only the photos you pick are read. Wi-Fi and Bluetooth status are checked on the device just to show them in Settings.")
                Text("Your control: Settings > Clear all business answers erases your answers, Settings > AI key (OpenAI) lets you remove your key, and deleting the app deletes everything it saved. Cover account numbers and personal details before importing a document.")
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
                  answer: "• Go to Settings > AI key (OpenAI) and paste your OpenAI API key. One key runs the AI interview, document import and action plan.\n• Keys come from platform.openai.com > API keys. The account needs billing or credit turned on."),
        HelpTopic(question: "The AI shows an error",
                  answer: "• Check that the phone is online (Settings > This device).\n• \"Didn't accept the API key\" means the key is wrong or was revoked: save a new one in Settings > AI key (OpenAI).\n• \"Rate-limiting\" means too many requests or no credit left. Wait a minute or add credit.\n• Your answers are saved as you go, so tap Try again or restart the interview without losing anything."),
        HelpTopic(question: "How do I add my cash on hand?",
                  answer: "• On the Overview, tap Add cash on hand on the Cash runway card. Tap Update cash on hand to change it later.\n• The runway also needs your monthly costs. If they're missing, tap Add monthly costs, or answer them in Interview > Phases."),
        HelpTopic(question: "How do I see daily or yearly cash flow?",
                  answer: "• Tap the Monthly button in the top-right corner of the cash flow card on the Overview and choose Daily, Monthly or Yearly.\n• Smart Flow converts your monthly numbers: yearly is 12 months, daily is a 365-day average."),
        HelpTopic(question: "Import didn't find my numbers",
                  answer: "• Clear, full-page PDFs work best. For photos (picked or taken with the camera), use good light and keep the whole page in view.\n• You can pick up to 10 files or photos at once. Each must be under 15 MB, and all together under 50 MB.\n• Anything it can't find can be typed in on Overview > Questions."),
        HelpTopic(question: "I don't see the Take a photo button",
                  answer: "• It appears only on an iPhone with a camera, not in the Simulator.\n• If you said no to camera access, turn it on in the iPhone's Settings > Smart Flow > Camera."),
        HelpTopic(question: "The action plan has no charts",
                  answer: "• Charts appear only where they help explain a step, up to 3 per plan.\n• Smart Flow draws them from your own numbers, so a chart is skipped when its numbers are missing. Answer more questions, then tap Regenerate plan on the Results tab.\n• Plans written before this update have no charts. Regenerate to get the new format."),
        HelpTopic(question: "My results look wrong",
                  answer: "• Unanswered questions count as $0. Interview > Phases shows which phases still have questions left.\n• Amounts marked / mo are monthly; revenue is for the last 12 months. You can fix any answer in Interview > Phases."),
        HelpTopic(question: "My answers disappeared",
                  answer: "• Answers are saved on this phone only, so they won't appear on another device.\n• Deleting or reinstalling the app, or Settings > Clear all business answers, erases them."),
        HelpTopic(question: "The keyboard won't go away",
                  answer: "• Tap Done in the bar just above the keyboard."),
        HelpTopic(question: "Face ID doesn't show up",
                  answer: "• Turn it on in Settings > Profile & Settings > Log in with Face ID.\n• Make sure Face ID is set up in the iPhone's Settings > Face ID & Passcode, and that Smart Flow is allowed to use it."),
        HelpTopic(question: "The app is frozen or acting strange",
                  answer: "• Swipe up from the bottom of the screen and swipe the app away, then reopen it.\n• Restart your iPhone.\n• Make sure iOS is up to date in Settings > General > Software Update.")
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
