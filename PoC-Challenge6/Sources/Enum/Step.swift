//
//  Step.swift
//  PoC-Challenge6
//
//  Created by Tais Akemi Kawaguti on 10/11/26.
//

import Foundation

enum Step: Equatable {
        case idle
        case reading                    // folha do NFC (do sistema)
        case checkingServer
        case authenticating             // Face ID (do sistema)
        case validatingLocation
        case confirmingOutsideAcademy   // aguardando decisão do aluno
        case registering
        case success(Date)
        case absenceSent
        case failed(String)
    }
