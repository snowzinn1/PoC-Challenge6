//
//  Display.swift
//  PoC-Challenge6
//
//  Created by Tais Akemi Kawaguti on 10/11/26.
//

enum Display {
        case progress(String)
        case confirmOutside
        case success(title: String, message: String?, celebrate: Bool)
        case failure(String)
    }
