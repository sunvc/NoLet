//
//  Lang.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/7/12.
//
import Defaults
import Foundation
import StoreKit

extension Multilingual.Country: Defaults.Serializable {}

extension Defaults.Keys {
    static let translateLang = Key<Multilingual.Country>(
        "MultilingualCountry",
        default: Multilingual.firstChoice
    )
}


enum Multilingual {
    struct Country: Identifiable, Equatable, Hashable, Codable {
        var id: String { code }

        let code: String
        let name: String
        let flag: String
    }

    static let firstChoice = Country(code: "en", name: "English", flag: "🌐")

    static func country(for code: String) -> Country? {
        guard let name = Locale.current.localizedString(forLanguageCode: code) else {
            return nil
        }
        return Country(code: code, name: name, flag: "🌐")
    }

    static let commonLanguages: [Country] = {
        let locale = Locale.current

        return Locale.LanguageCode.isoLanguageCodes
            .compactMap { languageCode in
                let code = languageCode.identifier

                guard let name = locale.localizedString(forLanguageCode: code) else {
                    return nil
                }

                return Country(
                    code: code,
                    name: name,
                    flag: "🌐"
                )
            }
            .sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
    }()

    static func resetTransLang() {
        let current = Defaults[.translateLang]

        guard let code = Locale.current.language.languageCode?.identifier,
              current.code != code,
              let language = country(for: code)
        else {
            return
        }

        Defaults[.translateLang] = language
    }
}
