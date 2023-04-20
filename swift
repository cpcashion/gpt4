import SwiftUI
import AVFoundation
import Combine

class EqualizerSettings: ObservableObject {
    @Published var frequency1: Float = 0
    @Published var frequency2: Float = 0
    @Published var frequency3: Float = 0
    @Published var frequency4: Float = 0
    @Published var frequency5: Float = 0
    
    lazy var audioPlayer = AudioPlayer(equalizerSettings: self)
}

class AudioPlayer: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let equalizer = AVAudioUnitEQ(numberOfBands: 5)
    private var cancellables = Set<AnyCancellable>()
    
    init(equalizerSettings: EqualizerSettings) {
        // Set up the equalizer
        for (index, filter) in equalizer.bands.enumerated() {
            filter.filterType = .parametric
            filter.frequency = Float(100 * (index + 1))
            filter.bandwidth = 1
            filter.bypass = false
        }
        
        // Attach nodes and connect the nodes
        audioEngine.attach(playerNode)
        audioEngine.attach(equalizer)
        audioEngine.connect(playerNode, to: equalizer, format: nil)
        audioEngine.connect(equalizer, to: audioEngine.mainMixerNode, format: nil)
        
        // Observe equalizer settings changes
        equalizerSettings.$frequency1.sink { [weak self] gain in
            self?.updateEqualizerBand(at: 0, gain: gain)
        }.store(in: &cancellables)
        equalizerSettings.$frequency2.sink { [weak self] gain in
            self?.updateEqualizerBand(at: 1, gain: gain)
        }.store(in: &cancellables)
        equalizerSettings.$frequency3.sink { [weak self] gain in
            self?.updateEqualizerBand(at: 2, gain: gain)
        }.store(in: &cancellables)
        equalizerSettings.$frequency4.sink { [weak self] gain in
            self?.updateEqualizerBand(at: 3, gain: gain)
        }.store(in: &cancellables)
        equalizerSettings.$frequency5.sink { [weak self] gain in
            self?.updateEqualizerBand(at: 4, gain: gain)
        }.store(in: &cancellables)
    }
    
    private func updateEqualizerBand(at index: Int, gain: Float) {
        equalizer.bands[index].gain = gain
    }
    
    func startAudioPlayer() {
        do {
            try audioEngine.start()
            playerNode.play()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    func stopAudioPlayer() {
        playerNode.stop()
        audioEngine.stop()
    }
}

struct CustomSlider: View {
    @Binding var value: Float
    let frequency: String
    
    var body: some View {
        VStack {
            Slider(value: $value, in: -10...10, step: 0.1)
                .padding(.horizontal)
            Text("\(frequency): \(value, specifier: "%.1f") dB")
                .font(.caption)
        }
    }
}

struct ContentView: View {
    @StateObject private var equalizerSettings = EqualizerSettings()
    
    var body: some View {
        VStack(spacing: 20) {
            CustomSlider(value: $equalizerSettings.frequency1, frequency: "Frequency 1")
            Custom
