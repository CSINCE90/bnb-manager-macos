//
//  SpesaRow.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//

import SwiftUI

struct SpesaRow: View {
    let spesa: Spesa
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(spesa.descrizione)
                    .font(.headline)
                HStack {
                    Text(spesa.categoria.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(5)
                    
                    Text(formattaData(spesa.data))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text(String(format: "€%.2f", spesa.importo))
                .fontWeight(.semibold)
                .foregroundColor(.red)
        }
        .padding(.vertical, 5)
    }
    
    func formattaData(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
}
