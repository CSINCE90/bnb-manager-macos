//
//  NotificationService.swift
//  MyBnB
//
//  Created by Francesco Chifari on 28/08/25.
//

import UserNotifications
import SwiftUI

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var pendingNotifications: [NotificationItem] = []
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            }
        }
    }
    
    func scheduleCheckInReminder(for booking: Prenotazione) {
        let content = UNMutableNotificationContent()
        content.title = "Check-in Oggi"
        content.body = "\(booking.nomeOspite) arriverà oggi per il check-in"
        content.sound = .default
        
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: booking.dataCheckIn
        )
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "checkin_\(booking.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            }
        }
    }
    
    func scheduleCheckOutReminder(for booking: Prenotazione) {
        let content = UNMutableNotificationContent()
        content.title = "Check-out Oggi"
        content.body = "\(booking.nomeOspite) farà il check-out oggi"
        content.sound = .default
        
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: booking.dataCheckOut
        )
        dateComponents.hour = 8
        dateComponents.minute = 30
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "checkout_\(booking.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotifications(for bookingId: UUID) {
        let identifiers = [
            "checkin_\(bookingId)",
            "checkout_\(bookingId)"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: identifiers
        )
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

struct NotificationItem: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let date: Date
}

