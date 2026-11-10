//
//  State.swift
//  PoC-Challenge6
//
//  Created by Tais Akemi Kawaguti on 10/11/26.
//

import Foundation


enum State: Equatable {
        case present(Date)               // bateu o ponto (horário)
        case absent(justified: Bool)     // falta (justificada ou não)
        case today                       // hoje, ainda sem registro
        case future                      // dia que ainda não chegou
    }
