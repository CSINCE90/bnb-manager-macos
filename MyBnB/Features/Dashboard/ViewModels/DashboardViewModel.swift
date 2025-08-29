//
//  DashboardViewModel.swift
//  MyBnB
//
//  Created by Francesco Chifari on 28/08/25.
//

import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var prenotazioni: [Prenotazione] = []
    @Published var spese: [Spesa] = []
    @Published var metrics: BusinessMetrics?
    @Published var isLoading = false
    
    private let prenotazioneRepo: PrenotazioneRepository
    private let spesaRepo: SpesaRepository
    private let analyticsService: AnalyticsService
    private let notificationService: NotificationService
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.prenotazioneRepo = PrenotazioneRepository()
        self.spesaRepo = SpesaRepository()
        self.analyticsService = AnalyticsService(
            prenotazioneRepo: prenotazioneRepo,
            spesaRepo: spesaRepo
        )
        self.notificationService = NotificationService.shared
        
        setupBindings()
        Task {
            await loadData()
        }
    }
    
    private func setupBindings() {
        prenotazioneRepo.$prenotazioni
            .assign(to: &$prenotazioni)
        
        spesaRepo.$spese
            .assign(to: &$spese)
        
        analyticsService.$metrics
            .assign(to: &$metrics)
    }
    
    func loadData() async {
        isLoading = true
        await analyticsService.calculateMetrics(for: .currentMonth)
        isLoading = false
    }
    
    func addPrenotazione(_ prenotazione: Prenotazione) async {
        do {
            try await prenotazioneRepo.create(prenotazione)
            
            // Schedule notifications
            notificationService.scheduleCheckInReminder(for: prenotazione)
            notificationService.scheduleCheckOutReminder(for: prenotazione)
            
            await loadData()
        } catch {
            print("Error adding prenotazione: \(error)")
        }
    }
    
    func deletePrenotazione(_ prenotazione: Prenotazione) async {
        do {
            try await prenotazioneRepo.delete(id: prenotazione.id)
            notificationService.cancelNotifications(for: prenotazione.id)
            await loadData()
        } catch {
            print("Error deleting prenotazione: \(error)")
        }
    }
    
    func addSpesa(_ spesa: Spesa) async {
        do {
            try await spesaRepo.create(spesa)
            await loadData()
        } catch {
            print("Error adding spesa: \(error)")
        }
    }
    
    func deleteSpesa(_ spesa: Spesa) async {
        do {
            try await spesaRepo.delete(id: spesa.id)
            await loadData()
        } catch {
            print("Error deleting spesa: \(error)")
        }
    }
    
    var entrateTotali: Double {
        metrics?.revenue ?? 0
    }
    
    var speseTotali: Double {
        metrics?.expenses ?? 0
    }
    
    var profittoNetto: Double {
        metrics?.profit ?? 0
    }
    
    var prenotazioniAttive: [Prenotazione] {
        prenotazioni.filter {
            $0.statoPrenotazione == .confermata || $0.statoPrenotazione == .inAttesa
        }.sorted { $0.dataCheckIn < $1.dataCheckIn }
    }
}
