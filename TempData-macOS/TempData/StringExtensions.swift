//
//  StringExtensions.swift
//  TempData
//
//  Created by Michele Primavera on 23/12/23.
//

import Foundation

extension String {
    func replaceAccents() -> String {
        var result = ""
        for char in self {
            switch char {
            case "â", "ä", "ã", "å":
                result.append("a")
                break;
            case "à", "á":
                result.append("a'")
                break;
            case "ê", "ë":
                result.append("e")
                break
            case "è", "é":
                result.append("e'")
                break
            case "î", "ï":
                result.append("i")
                break;
            case "ì", "í":
                result.append("i'")
                break;
            case "ô", "ö", "õ", "ø":
                result.append("o")
                break;
            case "œ":
                result.append("oe")
                break;
            case "ò", "ó":
                result.append("o'")
                break;
            case "û", "ü":
                result.append("u")
                break;
            case "ù", "ú":
                result.append("u'")
                break;
            case "ç":
                result.append("c")
                break;
            case "æ":
                result.append("ae")
                break;
            case "ñ":
                result.append("n")
                break;
            case "ß":
                result.append("B")
                break;
            case "Â", "Ä", "Ã", "Å":
                result.append("A")
                break;
            case "À", "Á":
                result.append("A'")
                break
            case "Ê", "Ë":
                result.append("E")
                break
            case "È", "É":
                result.append("E'")
                break;
            case "Î", "Ï":
                result.append("I")
                break;
            case "Ì", "Í":
                result.append("I'")
                break;
            case "Ô", "Ö", "Õ", "Ø":
                result.append("O")
                break;
            case "Œ":
                result.append("OE")
                break;
            case "Ò", "Ó":
                result.append("O'")
                break;
            case "Ù", "Ú":
                result.append("U'")
                break;
            case "Ç":
                result.append("C")
                break;
            case "Æ":
                result.append("AE")
                break;
            case "Û", "Ü":
                result.append("U")
                break;
            case "’":
                result.append("'")
                break;
            default:
                result.append(char)
                break
            }
        }
        return result
    }
}
