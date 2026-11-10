//
//  Reason.swift
//  PoC-Challenge6
//
//  Created by Tais Akemi Kawaguti on 10/11/26.
//


enum Reason: String, CaseIterable, Identifiable {
        case health = "Saúde"
        case personal = "Compromisso pessoal"
        case transport = "Transporte"
        case other = "Outro"
        var id: String { rawValue }
    }