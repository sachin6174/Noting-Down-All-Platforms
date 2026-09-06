import SwiftUI
import Speech
import AVFoundation

struct VoiceNoteView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var voiceRecorder = VoiceRecorder()
    @State private var transcribedText = ""
    @State private var noteTitle = ""
    @State private var selectedCategory = "Personal"
    @State private var showingPermissionAlert = false
    @State private var isProcessing = false
    @State private var saveError = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let categories = ["General", "Work", "Personal", "Ideas", "Shopping", "Travel", "Health", "Finance", "Education"]
    
    var body: some View {
        NavigationView {
            ScrollView { VStack(spacing: Theme.paddingL) {
                // Recording Status
                VStack(spacing: Theme.paddingM) {
                    ZStack {
                        Circle()
                            .fill(voiceRecorder.isRecording ? .red.opacity(0.2) : Theme.lightGreen)
                            .frame(width: 120, height: 120)
                            .scaleEffect(voiceRecorder.isRecording && !reduceMotion ? 1.1 : 1.0)
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: voiceRecorder.isRecording)
                        
                        Image(systemName: voiceRecorder.isRecording ? "mic.fill" : "mic")
                            .font(.system(size: 40))
                            .foregroundColor(voiceRecorder.isRecording ? .red : Theme.primaryGreen)
                    }
                    
                    Text(LocalizedStringKey(voiceRecorder.isRecording ? "Recording..." : "Tap to Record"))
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.textPrimary)
                    
                    if voiceRecorder.isRecording {
                        Text(formatTime(voiceRecorder.recordingTime))
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(voiceRecorder.isRecording ? "Stop recording" : "Start recording")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { handleRecordingTap() }
                .onTapGesture { handleRecordingTap() }
                
                // Control Buttons
                HStack(spacing: Theme.paddingL) {
                    Button(action: {
                        voiceRecorder.stopRecording()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(.red)
                            .cornerRadius(25)
                    }
                    .accessibilityLabel("Stop recording")
                    .disabled(!voiceRecorder.isRecording)
                    .opacity(voiceRecorder.isRecording ? 1.0 : 0.5)
                    
                    Button(action: {
                        if voiceRecorder.isRecording {
                            voiceRecorder.pauseRecording()
                        } else {
                            voiceRecorder.resumeRecording()
                        }
                    }) {
                        Image(systemName: voiceRecorder.isRecording ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Theme.primaryGreen)
                            .cornerRadius(25)
                    }
                    .accessibilityLabel(voiceRecorder.isRecording ? "Pause recording" : "Resume recording")
                    .disabled(!voiceRecorder.hasRecording)
                    .opacity(voiceRecorder.hasRecording ? 1.0 : 0.5)
                }
                
                // Transcription Section
                if !transcribedText.isEmpty || isProcessing {
                    VStack(alignment: .leading, spacing: Theme.paddingM) {
                        Text("Transcription")
                            .font(Theme.headlineFont)
                            .foregroundColor(Theme.textPrimary)
                        
                        if isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Processing audio...")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding(Theme.paddingM)
                            .cardStyle()
                        } else {
                            ScrollView {
                                Text(transcribedText)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 150)
                            .padding(Theme.paddingM)
                            .cardStyle()
                        }
                    }
                }
                
                // Note Details
                VStack(alignment: .leading, spacing: Theme.paddingM) {
                    VStack(alignment: .leading, spacing: Theme.paddingS) {
                        Text("Note Title")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                        
                        TextField("Enter title for your voice note", text: $noteTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.paddingS) {
                        Text("Category")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.paddingS) {
                                ForEach(categories, id: \.self) { category in
                                    Button(LocalizedStringKey(category)) {
                                        selectedCategory = category
                                    }
                                    .font(Theme.captionFont)
                                    .foregroundColor(selectedCategory == category ? .white : Theme.categoryColors[category])
                                    .padding(.horizontal, Theme.paddingM)
                                    .padding(.vertical, Theme.paddingS)
                                    .background(selectedCategory == category ? (Theme.categoryColors[category] ?? .gray) : (Theme.categoryColors[category] ?? .gray).opacity(0.2))
                                    .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal, Theme.paddingS)
                        }
                    }
                }
                .padding(.horizontal, Theme.paddingM)
                
                Spacer()
                
                // Save Button
                Button("Save Voice Note") {
                    saveVoiceNote()
                }
                .primaryButtonStyle()
                .disabled(noteTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || transcribedText.isEmpty || voiceRecorder.isRecording)
                .padding(.horizontal, Theme.paddingM)
            }
            }
            .padding(.vertical, Theme.paddingL)
            .background(Theme.lightGreen)
            .navigationTitle("Voice Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        voiceRecorder.stopRecording()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .onDisappear { voiceRecorder.stopRecording() }
        .alert("Could not save note", isPresented: $saveError) {
            Button("OK", role: .cancel) { }
        } message: { Text("Your draft is still open. Please try again.") }
        .onReceive(voiceRecorder.$transcription) { newTranscription in
            if !newTranscription.isEmpty {
                transcribedText = newTranscription
                isProcessing = false
            }
        }
        .onReceive(voiceRecorder.$isProcessing) { processing in
            isProcessing = processing
        }
        .alert("Microphone Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable microphone and speech recognition access in Settings to transcribe voice notes.")
        }
    }
    
    private func handleRecordingTap() {
        if voiceRecorder.isRecording {
            voiceRecorder.stopRecording()
        } else {
            voiceRecorder.startRecording { granted in
                if !granted {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func saveVoiceNote() {
        do {
            voiceRecorder.stopRecording()
            try NoteStore(context: viewContext).save(
                title: noteTitle, body: transcribedText, category: selectedCategory)
            presentationMode.wrappedValue.dismiss()
        } catch { saveError = true }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

@MainActor
final class VoiceRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var hasRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var transcription = ""
    @Published var isProcessing = false

    private var recordingTimer: Timer?
    private let speechRecognizer = SFSpeechRecognizer(locale: .current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var tapInstalled = false
    private var sessionID = UUID()

    func startRecording(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { audioGranted in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor [weak self] in
                    guard let self, audioGranted, status == .authorized else {
                        completion(false)
                        return
                    }
                    completion(self.beginRecording())
                }
            }
        }
    }

    private func beginRecording() -> Bool {
        stopRecording()
        guard let speechRecognizer, speechRecognizer.isAvailable else { return false }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            // Prefer local recognition when the device and language support it.
            request.requiresOnDeviceRecognition = speechRecognizer.supportsOnDeviceRecognition
            recognitionRequest = request
            let input = audioEngine.inputNode
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
                request.append(buffer)
            }
            tapInstalled = true
            let activeSession = sessionID
            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self, self.sessionID == activeSession else { return }
                    if let result { self.transcription = result.bestTranscription.formattedString }
                    if error != nil || result?.isFinal == true { self.stopRecording() }
                }
            }
            audioEngine.prepare()
            try audioEngine.start()
            transcription = ""
            recordingTime = 0
            isRecording = true
            hasRecording = true
            startTimer()
            return true
        } catch {
            stopRecording()
            return false
        }
    }

    func stopRecording() {
        sessionID = UUID()
        audioEngine.stop()
        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
        hasRecording = false
        stopTimer()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func pauseRecording() {
        guard hasRecording else { return }
        audioEngine.pause()
        isRecording = false
        stopTimer()
    }

    func resumeRecording() {
        guard hasRecording else { return }
        do {
            try audioEngine.start()
            isRecording = true
            startTimer()
        } catch { stopRecording() }
    }

    private func startTimer() {
        stopTimer()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.recordingTime += 1 }
        }
    }

    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}
