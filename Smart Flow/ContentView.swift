import SwiftUI

private func adaptive(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
    Color(UIColor { traits in
        let c = traits.userInterfaceStyle == .dark ? dark : light
        return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
    })
}

// brandColor: the deep purple used for headers, the logo and buttons (was navy blue before). Change these two
// sets of numbers to re-color the whole app; linkColor and pillBackground further down should match it.
// Not private, because the login screen in SmartFlowApp.swift uses it too. A bit brighter in Dark Mode so it stays visible.
let brandColor = adaptive(light: (0.33, 0.16, 0.55), dark: (0.52, 0.38, 0.85))
// pageBackground: the light gray behind every screen (near-black in Dark Mode). Apple's built-in grouped background color.
let pageBackground = Color(.systemGroupedBackground)
// cardBackground: the white behind cards and rows (dark gray in Dark Mode).
let cardBackground = Color(.secondarySystemGroupedBackground)
// confirmGreen: the green used for good news (autopay set, goal reached, payments).
let confirmGreen = adaptive(light: (0.13, 0.47, 0.36), dark: (0.35, 0.78, 0.58))

// The link/button purple and the pale purple used behind "pill" buttons and round icons.
let linkColor = adaptive(light: (0.42, 0.22, 0.70), dark: (0.72, 0.60, 1.0))
let pillBackground = adaptive(light: (0.95, 0.92, 0.99), dark: (0.22, 0.17, 0.32))

// MARK: - Card container
// AccountSection is a reusable "card" container: a purple title bar with white content under it.
// It's used on the Overview, question, import and results screens.
// <Content: View> is a "generic": the card can hold ANY kind of view you put inside it.
// A rounded card with a purple header bar and white content underneath.
struct AccountSection<Content: View>: View {
    // The text shown in the purple header, e.g. "Import a document".
    let title: String
    // @ViewBuilder lets callers write several views inside { } (like a VStack does) and have them passed in as "content".
    @ViewBuilder let content: Content

    var body: some View {
        // Header on top, content below, no gap.
        VStack(spacing: 0) {
            // The purple header bar: white text, stretched full width, left-aligned, with padding and purple background.
            Text(title)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                // maxWidth: .infinity = stretch to the full width of the card; alignment .leading = keep the text on the left.
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
                // The purple background comes AFTER the padding so the colored area includes the padding.
                .background(brandColor)

            // The white body of the card, holding whatever was passed in.
            VStack(spacing: 0) {
                content
            }
            .background(cardBackground)
        }
        // Round the corners of the whole card (header + body) by 14 points.
        .clipShape(RoundedRectangle(cornerRadius: 14))
        // Soft drop shadow: black at 8% opacity, blurred 4 points, shifted 2 points down.
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

// MARK: - Settings screens (opened from the Settings tab)

// Row 1: About
// App name, version number and credits.
struct AppInfoView: View {
    // Reads the version from the project settings (MARKETING_VERSION, currently 1.0),
    // so if you bump the version in Xcode this screen updates by itself. Falls back to "1.0".
    // took A LOT of googling to eventually get right.
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Copying logo from login screen.
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
            // Stretch to full width so everything stays centered. Regardless of device used it should stretch to stay centered.
            .frame(maxWidth: .infinity)
        }
        .background(pageBackground)
        .navigationTitle("About")
        // .inline = small title in the bar (instead of the big one), since the page has its own big title.
        .navigationBarTitleDisplayMode(.inline)
    }
}

//Row 2: COPYRIGHT AND PRIVACY SECTION.
// The copyright notice, split into short paragraphs so it's readable on a phone, also added a privacy note.
struct CopyrightPrivacyView: View {
    var body: some View {
        ScrollView {
            // alignment: .leading = left-align everything in the stack.
            VStack(alignment: .leading, spacing: 14) {
                Text("Copyright and Educational Project Notice")
                    .font(.headline)
                Text("© 2026 Brian Sanchez. All rights reserved in original material, subject to applicable law and third-party licenses.")
                Text("This application was created by Brian Sanchez in 2026 using the Swift programming language as an educational project at the University of Wisconsin–Green Bay. Its purpose is to demonstrate software development skills and explore banking application interfaces and functionality.")
                Text("Certain aspects of this application were inspired by existing banking applications for educational study. Similarities may reflect common interface conventions, educational exploration, or coincidence. No affiliation with, sponsorship by, or endorsement from any bank, financial institution, or other application developer is claimed or implied. Reference to the University of Wisconsin–Green Bay identifies the academic context of the project and does not imply university endorsement.")
                Text("Copyright is claimed only in original code, text, graphics, and other protectable material authored and owned by Brian Sanchez. Any third-party code, images, names, logos, trademarks, or other materials remain the property of their respective owners and are subject to applicable licenses and legal protections. This notice does not grant permission to use third-party material.")
                Text("U.S. copyright law protects original expression, subject to statutory limitations and exceptions. Fair use under 17 U.S.C. § 107 requires a case-specific assessment of the purpose and character of the use, the nature of the copyrighted work, the amount and substantiality used, and the effect on the potential market for the original work. An educational purpose alone does not establish fair use. This notice does not assert that every use of third-party material qualifies as fair use.")
                Text("This application is intended as an educational demonstration and should not be relied upon for banking services, financial advice, or real financial transactions.")

                // Privacy part. Keep this true whenever a feature starts sending data somewhere.
                Text("Privacy")
                    .font(.headline)
                    .padding(.top, 8)
                Text("Everything you enter (profile details and business answers) is saved on this device. Your password is never stored as plain text; only a scrambled fingerprint of it is kept in the iPhone Keychain, and your OpenAI API key is kept in the Keychain too. Face ID is checked by iOS; the app never sees your face data. When you use an AI feature, the information it needs is sent to OpenAI: the AI interview sends your messages and business answers, document import sends the file or photo you pick or take, and the action plan sends your answers and results. The camera is used only when you choose to take a picture of a document. Nothing else is sent to any server. Bluetooth permission is used only to show whether Bluetooth is turned on. Deleting the app deletes all of its saved data.")
            }
            .font(.subheadline)
            .padding()
        }
        .background(pageBackground)
        .navigationTitle("Copyright & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

//  Row 3: Profile & Settings
// let's add name, phone, email and ability to change password.
// Shows (and lets you edit) name, phone and email, plus a Change Password button.
// @AppStorage saves each value on the phone as soon as it changes, so there's no Save button needed.
struct ProfileSettingsView: View {
    @AppStorage("profile.name") private var fullName = "" // left empty intentionally.
    @AppStorage("profile.phone") private var phone = ""
    @AppStorage("profile.email") private var email = ""
    // Same key the login screen uses (SmartFlowApp.swift), so they always match.
    @AppStorage("login.username") private var username = validUsername
    // Whether the Change Password sheet is open.
    @State private var showingChangePassword = false
    // Whether Face ID login is on (the login screen reads the same value).
    @AppStorage("login.faceID") private var faceIDEnabled = false

    var body: some View {
        // Form = a List made for data entry (text boxes, toggles, buttons).
        Form {
            Section(header: Text("Profile")) {
                // Each row: label on the left, editable box on the right.
                HStack {
                    Text("Name")
                    TextField("Full name", text: $fullName)
                        .multilineTextAlignment(.trailing)   // right-align the typed text
                        .textContentType(.name)              // lets iOS suggest your name
                }
                HStack {
                    Text("Phone")
                    TextField("(555) 555-5555", text: $phone)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.phonePad)             // number keypad
                        .textContentType(.telephoneNumber)
                }
                HStack {
                    Text("Email")
                    TextField("name@example.com", text: $email)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.emailAddress)         // keyboard with @ and .
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never) // emails shouldn't start with a capital
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
                // Face ID login. Turning it on asks for Face ID once, to prove it's the phone's owner.
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
        .navigationTitle("Profile & Settings")
        .navigationBarTitleDisplayMode(.inline)
        // "Done" button above the keyboard (the phone pad has no Return key, so this is the way to close it).
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { hideKeyboard() }
            }
        }
        // .sheet slides the Change Password screen up from the bottom.
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordSheet()
        }
    }
}

// The Change Password screen. Checks the current password, then saves the new one.
// PasswordVault (in SmartFlowApp.swift) saves it in the iPhone Keychain, so the new password works at the next login.
struct ChangePasswordSheet: View {
    // dismiss() closes this sheet.
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    // Red message shown under the boxes. nil = no error.
    @State private var errorMessage: String?
    // Shows the "Password changed" popup.
    @State private var showingSuccess = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Current password", text: $currentPassword) // checks for current password, if wrong error is shown.
                }
                Section(footer: Text("Use at least 6 characters.")) {
                    SecureField("New password", text: $newPassword) // new password
                    SecureField("Confirm new password", text: $confirmPassword) // confirming the passwrod.
                }
                // Only shown after a failed Save.
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: savePassword)
                        // Greyed out until all three boxes have something in them.
                        .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                }
            }
            // After OK is tapped, close the sheet.
            .alert("Password changed", isPresented: $showingSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Use your new password the next time you log in.")
            }
        }
    }

    // Runs the checks in order and stops at the first problem.
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

// ---- Row 4: Help ----
// Basic troubleshooting. Each question is a DisclosureGroup: tap it to expand the answer.
struct HelpView: View {
    // One help topic: a question and its answer steps.
    // Identifiable (with id = question) lets ForEach tell the topics apart.
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
                  answer: "• Clear, full-page PDFs work best. For photos (picked or taken with the camera), use good light and keep the whole page in view.\n• Files must be under 15 MB.\n• Anything it can't find can be typed in on Overview > Answer the questions."),
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
                // ForEach makes one expandable row per topic.
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
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared helpers

// Formats as whole dollars with no cents, e.g. 1234.56 -> "$1,235".
func money(_ value: Double) -> String {
    value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
}

// Closes the on-screen keyboard (used by all the "Done" buttons).
func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// MARK: - SETTINGS TAB

// The Settings tab: AI keys, business data, account (profile, password, Face ID), device status, about, log out.
struct BusinessSettingsView: View {
    // Used by the Log Out button.
    @EnvironmentObject var session: AppSession
    // Wi-Fi and Bluetooth status (NetworkMonitor.swift, Bluetooth Monitor.swift).
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
                // Signs out and goes back to the login screen.
                Button(role: .destructive) {
                    session.logOut()
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .confirmationDialog("Clear every business answer?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear answers", role: .destructive) { store.reset() }
        }
    }

    private var keySummary: String {
        AIKeyVault.hasKey(.openAI) ? "Saved" : "Not set"
    }
}

// MARK: - THE TAB BAR (ContentView): what the app shows after logging in

// The five tabs. Rename the titles and change the icons here.
enum AppTab: Hashable {
    case overview, interview, importDocs, results, settings
}

// The Interview tab's two views: the AI chat, or the list of 6 phases to answer yourself.
enum InterviewMode: Hashable {
    case chat, phases
}

// Lets any screen switch tabs, e.g. the "See results" buttons (router.selected = .results),
// and pick which half of the Interview tab shows (router.interviewMode = .phases).
final class TabRouter: ObservableObject {
    @Published var selected: AppTab = .overview
    @Published var interviewMode: InterviewMode = .chat
}

struct ContentView: View {
    @StateObject private var router = TabRouter()

    var body: some View {
        // selection: the TabView follows router.selected, so buttons elsewhere can change tabs.
        TabView(selection: $router.selected) {
            // Tab 1: Overview (progress, phases, step-by-step questions).
            tab { BusinessCheckupView() }
                .tabItem {
                    Text("Overview")
                    Image(systemName: "briefcase")
                }
                .tag(AppTab.overview)

            // Tab 2: AI interview (OpenAI).
            tab { BusinessInterviewView() }
                .tabItem {
                    Text("Interview")
                    Image(systemName: "bubble.left.and.text.bubble.right")
                }
                .tag(AppTab.interview)

            // Tab 3: Document import (OpenAI).
            tab { BusinessDocumentImportView() }
                .tabItem {
                    Text("Import")
                    Image(systemName: "doc.text.viewfinder")
                }
                .tag(AppTab.importDocs)

            // Tab 4: Results + AI action plan (OpenAI).
            tab { BusinessResultsView() }
                .tabItem {
                    Text("Results")
                    Image(systemName: "chart.bar.doc.horizontal")
                }
                .tag(AppTab.results)

            // Tab 5: Settings (AI keys, profile, password, Face ID, help, log out).
            tab { BusinessSettingsView() }
                .tabItem {
                    Text("Settings")
                    Image(systemName: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .environmentObject(router)
    }

    // Each tab gets its own navigation stack, so its screens can open further screens with a Back button.
    // .stack keeps the iPhone-style single column on iPad too.
    private func tab<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        NavigationView { content() }
            .navigationViewStyle(.stack)
    }
}

// Xcode preview: lets me see ContentView in Xcode's canvas without running the simulator.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            // The preview needs its own copies of the shared objects, or it crashes looking for them.
            .environmentObject(NetworkMonitor())
            .environmentObject(BluetoothMonitor())
            .environmentObject(AppSession())
    }
}
