//
//  DayStatus.swift
//  PoC-Challenge6
//
//  Created by Tais Akemi Kawaguti on 10/11/26.
//


// MARK: - Status do dia

enum DayStatus {
    case present             // círculo branco
    case justifiedAbsence    // círculo cinza
    case unjustifiedAbsence // círculo só com contorno cinza
    case upcoming            // dia ainda não chegou (bem apagado)
}