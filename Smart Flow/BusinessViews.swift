import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct BusinessCheckupView: View {
    @ObservedObject private var store = BusinessStore.shared
    @EnvironmentObject var router: TabRouter
    @AppStorage("profile.name") private var fullName = ""

    private var profile: BusinessProfile { store.profile }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                greeting
                actionBar
                progressCard
                CashSplitCard(profile: profile) { router.selected = .interview }
                CashRunwayCard(profile: profile)
            }
            .padding(16)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("Overview")
        .navigationBarHidden(true)
    }

    private var firstName: String {
        fullName.split(separator: " ").first.map(String.init) ?? ""
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 6) {
                Image(systemName: "wind")
                    .font(.system(size: 20, weight: .bold))
                Text("Smart Flow")
                    .font(.system(size: 22, weight: .bold))
            }
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(firstName.isEmpty ? "Hi there" : "Hi, \(firstName)")
                        .font(.system(size: 17, weight: .semibold))
                    Text(profile.displayName)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(profile.completedPhases) of \(BusinessPhase.allCases.count)")
                        .font(.system(size: 24, weight: .bold))
                    Text("phases done")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }

    private var actionBar: some View {
        HStack(spacing: 0) {
            actionButton("Interview", icon: "bubble.left.and.text.bubble.right") {
                router.interviewMode = .chat
                router.selected = .interview
            }
            actionButton("Import", icon: "doc.text.viewfinder") {
                router.selected = .importDocs
            }
            actionButton("Questions", icon: "list.number") {
                router.interviewMode = .phases
                router.selected = .interview
            }
        }
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 16).fill(brandColor))
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 1.5))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your business checkup")
                .font(.system(size: 18, weight: .bold))
            ProgressView(value: Double(profile.completedPhases), total: Double(BusinessPhase.allCases.count))
                .tint(.primary)
            Text("Revenue, payroll, costs, debt, cash and goals. Answers are saved on this iPhone. They're sent to the AI only when you use an AI feature.")
                .font(.system(size: 13))
                .foregroundColor(.primary.opacity(0.75))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(highlightBackground))
    }
}

struct BusinessRow<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination()) {
            BusinessRowLabel(title: title, subtitle: subtitle, icon: icon)
        }
        .buttonStyle(.plain)
    }
}

struct BusinessRowLabel: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 19))
                    .foregroundColor(cream)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(cream.opacity(0.12)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 17, weight: .medium))
                    Text(subtitle).font(.system(size: 14)).foregroundColor(cream.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(cream.opacity(0.6))
            }
            .foregroundColor(cream)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
    }
}

struct BusinessInterviewView: View {
    @StateObject private var agent = BusinessInterviewAgent()
    @ObservedObject private var store = BusinessStore.shared
    @EnvironmentObject var router: TabRouter
    @ObservedObject private var keys = AIKeyStatus.shared
    @State private var draft = ""
    @State private var showSettings = false

    private var hasKey: Bool { AIKeyVault.hasKey(AIFeature.interview.provider) }
    private var allDone: Bool { store.profile.completedPhases == BusinessPhase.allCases.count }

    private var savedNote: String {
        let names = agent.lastSaved.prefix(3).map { $0.question }.joined(separator: " · ")
        let extra = agent.lastSaved.count > 3 ? " +\(agent.lastSaved.count - 3) more" : ""
        return "Saved: " + names + extra
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $router.interviewMode) {
                Text("AI chat").tag(InterviewMode.chat)
                Text("Phases").tag(InterviewMode.phases)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if router.interviewMode == .chat {
                chatContent
            } else {
                BusinessPhasesList()
            }
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle(router.interviewMode == .chat ? "AI Interview" : "Phases")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if router.interviewMode == .chat {
                    Button {
                        agent.restart()
                        agent.start()
                    } label: { Image(systemName: "arrow.counterclockwise") }
                    .disabled(agent.isThinking || !hasKey)
                    .accessibilityLabel("Restart interview")
                }
            }
        }
        .sheet(isPresented: $showSettings, onDismiss: { startChatIfReady() }) { AISettingsView() }
        .onAppear { startChatIfReady() }
        .onChange(of: router.interviewMode) { _ in startChatIfReady() }
    }

    private func startChatIfReady() {
        if hasKey && router.interviewMode == .chat { agent.start() }
    }

    @ViewBuilder private var chatContent: some View {
            phaseStrip
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        introCard
                        ForEach(agent.lines) { line in
                            chatBubble(line).id(line.id)
                        }
                        if !agent.lastSaved.isEmpty && !agent.isThinking {
                            Label(savedNote, systemImage: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(confirmGreen)
                        }
                        if agent.isThinking {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Thinking…").foregroundColor(.secondary)
                            }
                            .id("thinking")
                        }
                        if let error = agent.errorText {
                            errorCard(error)
                        }
                        if agent.isFinished || allDone {
                            Button { router.selected = .results } label: {
                                Label("See results", systemImage: "chart.bar.doc.horizontal.fill")
                                    .font(.system(size: 17, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(brandColor)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .id("results")
                        }
                    }
                    .padding(16)
                }
                .onChange(of: agent.lines.count) { _ in
                    if let last = agent.lines.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onChange(of: agent.isThinking) { thinking in
                    if thinking { withAnimation { proxy.scrollTo("thinking", anchor: .bottom) } }
                }
            }
            inputBar
    }

    private var phaseStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BusinessPhase.allCases) { phase in
                    let done = store.profile.isComplete(phase)
                    Label(phase.title, systemImage: done ? "checkmark.circle.fill" : phase.icon)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundColor(cream)
                        .background(Capsule().fill(brandColor))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Business checkup interview", systemImage: "sparkles")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(accentTealText)
            Text(hasKey
                 ? "I'll ask about revenue, payroll, costs, debt, cash and goals, and save your answers as we go. Estimates are fine. Your answers are sent to \(AIFeature.interview.provider.rawValue) to run this chat."
                 : "Add a \(AIFeature.interview.provider.rawValue) API key to start the interview. You can also answer the questions yourself without AI.")
                .font(.system(size: 14))
                .foregroundColor(accentTealText.opacity(0.85))
            if !hasKey {
                Button("Add API key") { showSettings = true }
                    .buttonStyle(.borderedProminent)
                    .tint(accentTealText)
                    .foregroundColor(accentTeal)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(accentTeal))
    }

    private func chatBubble(_ line: BusinessChatLine) -> some View {
        HStack {
            if line.fromUser { Spacer(minLength: 40) }
            Text(markdown(line.text))
                .font(.system(size: 16))
                .foregroundColor(line.fromUser ? .white : .primary)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16).fill(line.fromUser ? brandColor : cardBackground))
                .textSelection(.enabled)
            if !line.fromUser { Spacer(minLength: 40) }
        }
    }

    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 15))
                .foregroundColor(.red)
            HStack {
                Button("Try again") { agent.retry() }
                Spacer()
                Button("AI settings") { showSettings = true }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(brandColor)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(cardBackground))
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            messageField
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 20).fill(cardBackground))
            Button {
                agent.send(draft)
                draft = ""
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(brandColor)
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || agent.isThinking || !hasKey)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder private var messageField: some View {
        if #available(iOS 16.0, *) {
            TextField("Type your answer…", text: $draft, axis: .vertical).lineLimit(1...4)
        } else {
            TextField("Type your answer…", text: $draft)
        }
    }
}

func markdown(_ text: String) -> AttributedString {
    let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
}

struct BusinessPhasesList: View {
    @ObservedObject private var store = BusinessStore.shared
    private var profile: BusinessProfile { store.profile }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(profile.completedPhases) of \(BusinessPhase.allCases.count) phases complete")
                        .font(.system(size: 17, weight: .semibold))
                    ProgressView(value: Double(profile.completedPhases), total: Double(BusinessPhase.allCases.count))
                        .tint(brandColor)
                    Text("Answers from the AI chat and document import show up here too. Tap a phase to review or change them.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 0) {
                    Text("Phases")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(cream)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 2)
                    ForEach(BusinessPhase.allCases) { phase in
                        if phase != .revenue { Rectangle().fill(cream.opacity(0.15)).frame(height: 1).padding(.leading, 76) }
                        BusinessRow(title: "\(phase.rawValue + 1). \(phase.title)",
                                    subtitle: status(phase),
                                    icon: profile.isComplete(phase) ? "checkmark.circle.fill" : phase.icon) {
                            BusinessQuestionsView(startAt: phase)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 16).fill(brandColor))
            }
            .padding(16)
        }
    }

    private func status(_ phase: BusinessPhase) -> String {
        let left = profile.missing(in: phase).count
        return left == 0 ? "Complete" : "\(left) question\(left == 1 ? "" : "s") left"
    }
}

struct BusinessQuestionsView: View {
    @ObservedObject private var store = BusinessStore.shared
    @EnvironmentObject var router: TabRouter
    @State private var phase: BusinessPhase

    init(startAt: BusinessPhase) {
        _phase = State(initialValue: startAt)
    }

    private var isLast: Bool { phase == BusinessPhase.allCases.last }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Phase \(phase.rawValue + 1) of \(BusinessPhase.allCases.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        ProgressView(value: Double(phase.rawValue + 1), total: Double(BusinessPhase.allCases.count))
                            .tint(brandColor)
                        Text(phase.purpose)
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }

                    AccountSection(title: phase.title) {
                        let fields = BusinessField.fields(in: phase).filter { store.profile.applies($0) }
                        ForEach(Array(fields.enumerated()), id: \.element) { index, field in
                            if index > 0 { Divider().padding(.horizontal, 20) }
                            BusinessQuestionRow(field: field, store: store)
                        }
                    }
                }
                .padding(16)
            }

            HStack(spacing: 12) {
                if phase != .revenue {
                    Button { move(-1) } label: {
                        Text("Back").frame(maxWidth: .infinity).padding(.vertical, 14)
                    }
                    .foregroundColor(brandColor)
                    .background(RoundedRectangle(cornerRadius: 12).stroke(brandColor, lineWidth: 1.5))
                }
                if isLast {
                    Button { hideKeyboard(); router.selected = .results } label: {
                        Text("See results").bold().frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(brandColor))
                            .foregroundColor(.white)
                    }
                    .disabled(!store.profile.isAnswered(.annualRevenue))
                } else {
                    Button { move(1) } label: {
                        Text("Continue").bold().frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(brandColor))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(cardBackground)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle(phase.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { hideKeyboard() }
            }
        }
    }

    private func move(_ offset: Int) {
        hideKeyboard()
        guard let next = BusinessPhase(rawValue: phase.rawValue + offset) else { return }
        withAnimation { phase = next }
    }
}

struct BusinessQuestionRow: View {
    let field: BusinessField
    @ObservedObject var store: BusinessStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(field.question).font(.system(size: 17, weight: .medium))
                if field.isOptional {
                    Spacer()
                    Text("Optional").font(.system(size: 12)).foregroundColor(.gray)
                }
            }
            Text(field.hint).font(.system(size: 14)).foregroundColor(.gray)
            input
        }
        .padding(20)
    }

    @ViewBuilder private var input: some View {
        switch field.kind {
        case .money(let suffix):
            numberBox(prefix: "$", suffix: suffix)
        case .percent:
            numberBox(prefix: nil, suffix: "%")
        case .count(let unit):
            numberBox(prefix: nil, suffix: unit)
        case .text:
            TextField("Type here", text: textBinding)
                .font(.system(size: 18))
                .padding(12)
                .background(pageBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        case .choice(let options):
            VStack(spacing: 8) {
                ForEach(options, id: \.self) { option in choiceButton(option) }
            }
        case .yesNo:
            HStack(spacing: 8) {
                choiceButton("Yes")
                choiceButton("No")
            }
        }
    }

    private func numberBox(prefix: String?, suffix: String) -> some View {
        HStack(spacing: 4) {
            if let prefix = prefix { Text(prefix).foregroundColor(.gray) }
            TextField("0", text: numberBinding).keyboardType(.numberPad)
            if !suffix.isEmpty { Text(suffix).foregroundColor(.gray) }
        }
        .font(.system(size: 20))
        .padding(12)
        .background(pageBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func choiceButton(_ option: String) -> some View {
        let selected = store.profile.text(field) == option
        return Button {
            store.profile.set(field, from: option)
        } label: {
            HStack {
                Text(option).font(.system(size: 16))
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
            }
            .foregroundColor(selected ? .white : .primary)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(selected ? brandColor : pageBackground))
        }
        .buttonStyle(.plain)
    }

    private var numberBinding: Binding<String> {
        Binding(
            get: {
                store.profile.isAnswered(field) ? String(Int(store.profile[field].rounded())) : ""
            },
            set: { newValue in
                let digits = newValue.filter(\.isNumber)
                if digits.isEmpty {
                    store.profile.numbers.removeValue(forKey: field.rawValue)
                } else {
                    store.profile.set(field, from: digits)
                }
            })
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { store.profile.text(field) ?? "" },
            set: { store.profile.texts[field.rawValue] = $0.isEmpty ? nil : $0 })
    }
}

struct BusinessDocumentImportView: View {
    @ObservedObject private var store = BusinessStore.shared
    @ObservedObject private var keys = AIKeyStatus.shared
    @State private var showFilePicker = false
    @State private var showSettings = false
    @State private var isReading = false
    @State private var errorText: String?
    @State private var fileName = ""
    @State private var findings: DocumentFindings?
    @State private var selected: Set<BusinessField> = []
    @State private var savedCount: Int?

    private let maxBytes = 15 * 1024 * 1024
    private var hasKey: Bool { AIKeyVault.hasKey(AIFeature.documentImport.provider) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AccountSection(title: "Import a document") {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Pick or take a picture of a profit & loss statement, bank statement, payroll report or balance sheet. \(AIFeature.documentImport.provider.rawValue) reads it and suggests answers. You choose what to save.")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                        if hasKey {
                            Button { showFilePicker = true } label: {
                                Label("Choose a PDF or image from Files", systemImage: "folder")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .foregroundColor(.white)
                            .background(RoundedRectangle(cornerRadius: 10).fill(brandColor))
                            .disabled(isReading)
                            if #available(iOS 16.0, *) {
                                BusinessPhotoButton(disabled: isReading) { data in
                                    read(AIAttachment(data: data, mimeType: "image/jpeg", filename: "photo.jpg"), name: "Photo")
                                }
                            }
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                BusinessCameraButton(disabled: isReading) { data in
                                    read(AIAttachment(data: data, mimeType: "image/jpeg", filename: "photo.jpg"), name: "Photo")
                                }
                            }
                        } else {
                            Button("Add a \(AIFeature.documentImport.provider.rawValue) API key") { showSettings = true }
                                .foregroundColor(brandColor)
                        }
                        Text("Tip: cover account numbers before taking a photo. The file is sent to \(AIFeature.documentImport.provider.rawValue) to be read.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                }

                if isReading {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Reading \(fileName)…").foregroundColor(.secondary)
                    }
                }
                if let error = errorText {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let count = savedCount {
                    Label("Saved \(count) answer\(count == 1 ? "" : "s").", systemImage: "checkmark.circle.fill")
                        .foregroundColor(confirmGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let findings = findings {
                    findingsCard(findings)
                }
            }
            .padding(16)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("Import Document")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .sheet(isPresented: $showSettings) { AISettingsView() }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf, .image],
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                loadFile(url)
            case .failure(let error):
                errorText = error.localizedDescription
            }
        }
    }

    private func findingsCard(_ f: DocumentFindings) -> some View {
        AccountSection(title: f.documentType) {
            VStack(alignment: .leading, spacing: 0) {
                if !f.notes.isEmpty {
                    Text(f.notes).font(.system(size: 14)).foregroundColor(.gray).padding(20)
                    Divider()
                }
                if f.values.isEmpty {
                    Text("No figures this checkup uses were found in this document.")
                        .font(.system(size: 15)).foregroundColor(.gray).padding(20)
                }
                ForEach(f.values, id: \.field) { item in
                    Toggle(isOn: Binding(
                        get: { selected.contains(item.field) },
                        set: { on in if on { selected.insert(item.field) } else { selected.remove(item.field) } })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.field.question).font(.system(size: 15, weight: .medium))
                            Text(preview(item.field, item.value)).font(.system(size: 14)).foregroundColor(brandColor)
                        }
                    }
                    .tint(brandColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    Divider().padding(.leading, 20)
                }
                if !f.values.isEmpty {
                    Button {
                        var profile = store.profile
                        for item in f.values where selected.contains(item.field) {
                            profile.set(item.field, from: item.value)
                        }
                        store.profile = profile
                        savedCount = selected.count
                        findings = nil
                    } label: {
                        Text("Save \(selected.count) selected").bold()
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(brandColor))
                            .foregroundColor(.white)
                    }
                    .disabled(selected.isEmpty)
                    .padding(20)
                }
            }
        }
    }

    private func preview(_ field: BusinessField, _ value: Double) -> String {
        var probe = BusinessProfile()
        probe.set(field, from: value)
        let found = "Found " + probe.formatted(field)
        return store.profile.isAnswered(field) ? found + " (you entered \(store.profile.formatted(field)))" : found
    }

    private func loadFile(_ url: URL) {
        let opened = url.startAccessingSecurityScopedResource()
        defer { if opened { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let type = UTType(filenameExtension: url.pathExtension)
            let mime = type?.conforms(to: .pdf) == true ? "application/pdf" : (type?.preferredMIMEType ?? "image/jpeg")
            read(AIAttachment(data: data, mimeType: mime, filename: url.lastPathComponent), name: url.lastPathComponent)
        } catch {
            errorText = "Couldn't open that file: \(error.localizedDescription)"
        }
    }

    private func read(_ attachment: AIAttachment, name: String) {
        guard attachment.data.count <= maxBytes else {
            errorText = "That file is over 15 MB. Try exporting a shorter date range or a smaller PDF."
            return
        }
        fileName = name
        errorText = nil
        savedCount = nil
        findings = nil
        isReading = true
        Task {
            do {
                let result = try await BusinessDocumentReader.read(attachment)
                findings = result
                selected = Set(result.values.map(\.field))
            } catch {
                errorText = error.localizedDescription
            }
            isReading = false
        }
    }
}

@available(iOS 16.0, *)
struct BusinessPhotoButton: View {
    let disabled: Bool
    let onPick: (Data) -> Void
    @State private var item: PhotosPickerItem?

    init(disabled: Bool, onPick: @escaping (Data) -> Void) {
        self.disabled = disabled
        self.onPick = onPick
    }

    var body: some View {
        PhotosPicker(selection: $item, matching: .images) {
            Label("Choose a photo", systemImage: "photo")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundColor(brandColor)
                .background(RoundedRectangle(cornerRadius: 10).stroke(brandColor, lineWidth: 1.5))
        }
        .disabled(disabled)
        .onChange(of: item) { newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.8) {
                    onPick(jpeg)
                }
                item = nil
            }
        }
    }
}

struct BusinessCameraButton: View {
    let disabled: Bool
    let onPick: (Data) -> Void
    @State private var showCamera = false

    init(disabled: Bool, onPick: @escaping (Data) -> Void) {
        self.disabled = disabled
        self.onPick = onPick
    }

    var body: some View {
        Button { showCamera = true } label: {
            Label("Take a photo", systemImage: "camera")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundColor(brandColor)
                .background(RoundedRectangle(cornerRadius: 10).stroke(brandColor, lineWidth: 1.5))
        }
        .disabled(disabled)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                if let jpeg = image.jpegData(compressionQuality: 0.8) {
                    onPick(jpeg)
                }
            }
            .ignoresSafeArea()
        }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct BusinessResultsView: View {
    @ObservedObject private var store = BusinessStore.shared
    @AppStorage("business.actionPlan") private var plan = ""
    @AppStorage("business.actionPlanDate") private var planDate = ""
    @State private var isWriting = false
    @State private var planError: String?
    @State private var showSettings = false

    @EnvironmentObject var router: TabRouter
    @ObservedObject private var keys = AIKeyStatus.shared

    private var m: BusinessMetrics { BusinessMetrics(p: store.profile) }
    private var p: BusinessProfile { store.profile }

    var body: some View {
        Group {
            if p.isAnswered(.annualRevenue) {
                results
            } else {
                emptyState
            }
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("Business Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .sheet(isPresented: $showSettings) { AISettingsView() }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 44))
                .foregroundColor(brandColor)
            Text("No results yet")
                .font(.system(size: 20, weight: .semibold))
            Text("Start with your yearly revenue. Chat with the AI, import a document, or answer the questions on the Overview tab.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Start the AI interview") { router.selected = .interview }
                .buttonStyle(.borderedProminent)
                .tint(brandColor)
            Button("Go to Overview") { router.selected = .overview }
                .foregroundColor(brandColor)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var results: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    BusinessMetricTile(title: "Debt coverage (DSCR)",
                                       value: m.dscr.map { String(format: "%.2fx", $0) } ?? (m.debtService == 0 ? "No debt" : "—"),
                                       caption: "Lenders want 1.25x+", rating: m.dscrRating)
                    BusinessMetricTile(title: "Cash cushion",
                                       value: m.cashCoverageMonths.map { String(format: "%.1f mo", $0) } ?? "—",
                                       caption: "Of fixed costs · aim 3+", rating: m.cashRating)
                    BusinessMetricTile(title: "Payroll share",
                                       value: m.payrollShare.map { "\(Int(($0 * 100).rounded()))%" } ?? "—",
                                       caption: "Of revenue, incl. you", rating: m.payrollRating)
                    BusinessMetricTile(title: "Current ratio",
                                       value: m.currentRatio.map { String(format: "%.2f", $0) } ?? (m.currentLiabilities == 0 ? "No bills" : "—"),
                                       caption: "Short-term assets ÷ debts", rating: m.currentRatioRating)
                }

                AccountSection(title: "Monthly cash flow") {
                    VStack(spacing: 10) {
                        flowRow("Revenue", m.monthlyRevenue)
                        if m.monthlyCOGS > 0 { flowRow("Cost of goods sold", -m.monthlyCOGS) }
                        if p[.otherIncome] > 0 { flowRow("Other income", p[.otherIncome]) }
                        flowRow("Gross profit", m.grossProfit, bold: true)
                        Divider()
                        flowRow("Payroll, contractors & owner pay", -m.payrollCost)
                        flowRow("Operating costs", -m.operatingCost)
                        flowRow("Operating income", m.netOperatingIncome, bold: true)
                        Divider()
                        flowRow("Debt payments", -m.debtService)
                        flowRow("Net cash flow", m.netCashFlow, bold: true, colored: true)
                    }
                    .padding(20)
                }

                let warnings = watchOuts
                if !warnings.isEmpty {
                    AccountSection(title: "Watch-outs") {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(warnings, id: \.self) { text in
                                Label(text, systemImage: "exclamationmark.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                AccountSection(title: "Action plan · \(AIFeature.actionPlan.provider.rawValue)") {
                    planContent.padding(20)
                }

                Text("Missing answers count as $0, so results get sharper as you finish each phase. Educational estimates, not financial advice.")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .padding(16)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(p.displayName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            Text("\(m.netCashFlow >= 0 ? "+" : "")\(money(m.netCashFlow)) / mo")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.white)
            Text(m.runwayMonths.map { String(format: "Losing money each month. Cash lasts about %.1f months at this pace.", $0) }
                 ?? "Net cash flow after payroll, costs and debt payments.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(m.netCashFlow >= 0 ? brandColor : Color.red.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    private func flowRow(_ label: String, _ amount: Double, bold: Bool = false, colored: Bool = false) -> some View {
        HStack {
            Text(label).font(.system(size: 16, weight: bold ? .semibold : .regular))
            Spacer()
            Text(money(amount))
                .font(.system(size: 16, weight: bold ? .semibold : .regular))
                .foregroundColor(colored ? (amount >= 0 ? confirmGreen : .red) : .primary)
        }
    }

    private var watchOuts: [String] {
        var list: [String] = []
        if p[.backTaxesOwed] > 0 {
            list.append("\(money(p[.backTaxesOwed])) in past-due taxes. Penalties and interest keep growing; a payment plan with the IRS or state is often possible.")
        }
        if let runway = m.runwayMonths, runway < 6 {
            list.append(String(format: "At the current pace the cash lasts about %.1f months.", runway))
        }
        if p[.mcaPayment] > 0 {
            list.append("Merchant cash advance payments of \(money(p[.mcaPayment])) / mo. These are usually the most expensive financing; refinancing them can free up cash.")
        }
        if let use = m.lineUtilization, use > 0.7 {
            list.append("Line of credit is \(Int((use * 100).rounded()))% used, leaving little room for surprises.")
        }
        if p[.daysToGetPaid] > 45 {
            list.append("Customers take \(Int(p[.daysToGetPaid])) days to pay. Deposits, shorter terms or card payments could speed this up.")
        }
        if let payday = m.cashPerPayroll, p.isAnswered(.cashOnHand), p[.cashOnHand] < payday * 2 {
            list.append("Cash in the bank covers fewer than 2 paydays (\(money(payday)) each).")
        }
        if p.isAnswered(.yearsInBusiness), p[.yearsInBusiness] < 2, p.text(.primaryFocus) == BusinessFocus.financing.rawValue {
            list.append("Many banks and SBA lenders look for 2+ years in business; newer businesses may need alternative lenders.")
        }
        if p[.ownerPay] == 0 && p.isAnswered(.ownerPay) {
            list.append("You're not paying yourself. Results look better than they would with a market-rate owner salary.")
        }
        return list
    }

    @ViewBuilder private var planContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isWriting {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Writing your plan…").foregroundColor(.secondary)
                }
            } else if !plan.isEmpty {
                Text(markdown(plan))
                    .font(.system(size: 15))
                    .textSelection(.enabled)
                if !planDate.isEmpty {
                    Text("Written \(planDate). Regenerate after changing answers.")
                        .font(.system(size: 12)).foregroundColor(.gray)
                }
            } else {
                Text("Get a step-by-step plan based on your answers and the numbers above. Your answers are sent to \(AIFeature.actionPlan.provider.rawValue).")
                    .font(.system(size: 15)).foregroundColor(.gray)
            }

            if let error = planError {
                Text(error).font(.system(size: 14)).foregroundColor(.red)
            }

            if AIKeyVault.hasKey(AIFeature.actionPlan.provider) {
                Button(plan.isEmpty ? "Write my action plan" : "Regenerate plan") { writePlan() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(brandColor)
                    .disabled(isWriting)
            } else {
                Button("Add a \(AIFeature.actionPlan.provider.rawValue) API key") { showSettings = true }
                    .foregroundColor(brandColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func writePlan() {
        isWriting = true
        planError = nil
        let snapshot = store.profile
        Task {
            do {
                plan = try await BusinessPlanWriter.write(for: snapshot)
                planDate = Date().formatted(date: .abbreviated, time: .shortened)
            } catch {
                planError = error.localizedDescription
            }
            isWriting = false
        }
    }
}

struct BusinessMetricTile: View {
    let title: String
    let value: String
    let caption: String
    let rating: BusinessRating

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 14, weight: .medium)).foregroundColor(.gray)
            Text(value).font(.system(size: 24, weight: .semibold)).minimumScaleFactor(0.7).lineLimit(1)
            Text(rating.label)
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .foregroundColor(rating.color)
                .background(Capsule().fill(rating.color.opacity(0.15)))
            Text(caption).font(.system(size: 12)).foregroundColor(.gray)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(cardBackground))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

struct AISettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            AISettingsForm()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

struct AISettingsForm: View {
    @State private var drafts: [AIProvider: String] = [:]
    @ObservedObject private var keys = AIKeyStatus.shared

    var body: some View {
            Form {
                ForEach(AIProvider.allCases) { provider in
                    Section {
                        HStack {
                            Text("Status")
                            Spacer()
                            Text(AIKeyVault.hasKey(provider) ? "Saved" : "Not set")
                                .foregroundColor(AIKeyVault.hasKey(provider) ? confirmGreen : .gray)
                        }
                        SecureField("Paste API key", text: Binding(
                            get: { drafts[provider] ?? "" },
                            set: { drafts[provider] = $0 }))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Save key") {
                            AIKeyVault.save(drafts[provider] ?? "", for: provider)
                            drafts[provider] = ""
                        }
                        .disabled((drafts[provider] ?? "").trimmingCharacters(in: .whitespaces).isEmpty)
                        if AIKeyVault.hasKey(provider) {
                            Button("Remove key", role: .destructive) {
                                AIKeyVault.remove(provider)
                            }
                        }
                        Link("Get a \(provider.rawValue) key", destination: provider.keyPageURL)
                    } header: {
                        Text(provider.rawValue)
                    }
                }

                Section {
                    ForEach(AIFeature.allCases) { feature in
                        HStack {
                            Text(feature.rawValue)
                            Spacer()
                            Text(feature.model).foregroundColor(.gray)
                        }
                    }
                } header: {
                    Text("Model used by each feature")
                } footer: {
                    Text("Your key is kept in this iPhone's Keychain. When you use an AI feature, your business answers (or the document you picked) are sent to OpenAI to be processed.")
                }
            }
            .creamListBackground()
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
    }
}
