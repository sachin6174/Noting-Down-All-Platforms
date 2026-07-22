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
    
    private let categories = ["General", "Work", "Personal", "Ideas", "Shopping", "Travel", "Health", "Finance", "Education"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: Theme.paddingL) {
                // Recording Status
                VStack(spacing: Theme.paddingM) {
                    ZStack {
                        Circle()
                            .fill(voiceRecorder.isRecording ? .red.opacity(0.2) : Theme.lightGreen)
                            .frame(width: 120, height: 120)
                            .scaleEffect(voiceRecorder.isRecording ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: voiceRecorder.isRecording)
                        
                        Image(systemName: voiceRecorder.isRecording ? "mic.fill" : "mic")
                            .font(.system(size: 40))
                            .foregroundColor(voiceRecorder.isRecording ? .red : Theme.primaryGreen)
                    }
                    
                    Text(voiceRecorder.isRecording ? "Recording..." : "Tap to Record")
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.textPrimary)
                    
                    if voiceRecorder.isRecording {
                        Text(formatTime(voiceRecorder.recordingTime))
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                .onTapGesture {
                    handleRecordingTap()
                }
                
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
                                    Button(category) {
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
                .disabled(noteTitle.isEmpty || (!voiceRecorder.hasRecording && transcribedText.isEmpty))
                .padding(.horizontal, Theme.paddingM)
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
            Text("Please enable microphone access in Settings to record voice notes.")
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
        let newNote = NotesTable(context: viewContext)
        newNote.id = UUID()
        newNote.title = noteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        newNote.noteDescription = """
        🎤 Voice Note
        
        Transcription:
        \(transcribedText)
        
        Recorded on: \(Date().formatted(date: .abbreviated, time: .shortened))
        """
        newNote.category = selectedCategory
        newNote.createdDate = Date()
        newNote.modifiedDate = Date()
        newNote.isFavorite = false
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving voice note: \(error.localizedDescription)")
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

class VoiceRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var hasRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var transcription = ""
    @Published var isProcessing = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func startRecording(completion: @escaping (Bool) -> Void) {
        requestPermissions { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.beginRecording()
                }
                completion(granted)
            }
        }
    }
    
    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { audioGranted in
            SFSpeechRecognizer.requestAuthorization { speechStatus in
                DispatchQueue.main.async {
                    completion(audioGranted && speechStatus == .authorized)
                }
            }
        }
    }
    
    private func beginRecording() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = documentsPath.appendingPathComponent("voiceNote.m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
            hasRecording = true
            startTimer()
            startSpeechRecognition()
            
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopTimer()
        stopSpeechRecognition()
        processRecording()
    }
    
    func pauseRecording() {
        audioRecorder?.pause()
        isRecording = false
        stopTimer()
    }
    
    func resumeRecording() {
        audioRecorder?.record()
        isRecording = true
        startTimer()
    }
    
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.recordingTime += 1
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func startSpeechRecognition() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else { return }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.transcription = result.bestTranscription.formattedString
                }
            }
        }
    }
    
    private func stopSpeechRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
    
    private func processRecording() {
        isProcessing = true
        // Additional processing can be added here
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isProcessing = false
        }
    }
}
