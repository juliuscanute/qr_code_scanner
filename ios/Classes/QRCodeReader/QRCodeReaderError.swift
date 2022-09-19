//
//  Error.swift
//  QRCodeReader
//
//  Created by kazuhiro nanko on 2022/09/18.
//

import Foundation

public enum QRCodeReaderError: Error {
    case someReason

    var localizedDescription: String { "EnumError.localizedDescription" }
}
