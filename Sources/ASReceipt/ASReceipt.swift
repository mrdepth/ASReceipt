//
//  ASReceipt.swift
//
//
//  Created by Artem Shimanski on 6/28/20.
//

import Foundation
import ASN1Decoder
import CryptoKit

public struct Receipt: ASN1Decodable {
    public struct ReceiptType: RawRepresentable, ASN1Decodable {
        public let rawValue: String
        static let sandbox = ReceiptType(rawValue: "ProductionSandbox")
        static let production = ReceiptType(rawValue: "Production")
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(from decoder: ASN1DecoderProtocol) throws {
            let s = try decoder.value(encoded: .none).decode(String.self, encoded: .utf8String)
            self.init(rawValue: s)
        }

    }

    private enum AttributeID: Int {
        case receiptType = 0
        case bundleID = 2
        case applicationVersion = 3
        case opaqueValue = 4
        case sha1Hash = 5
        case inAppPurchases = 17
        case originalPurchaseDate = 18
        case originalApplicationVersion = 19
        case creationDate = 12
        case expirationDate = 21
        case appItemID = 1
        case downloadID = 15
        case versionExternalIdentifier = 16
        case receiptCreationDate = 8
    }
    
    public var receiptType: ReceiptType?
    public var bundleID: String?
    public var applicationVersion: String?
    public var opaqueValue: Data?
    public var sha1Hash: Data?
    public var originalPurchaseDate: Date?
    public var originalApplicationVersion: String?
    public var creationDate: Date?
    public var expirationDate: Date?
    public var appItemID: Int?
    public var downloadID: Int?
    public var versionExternalIdentifier: Int?
    public var receiptCreationDate: Date?
    public var inAppPurchases = [InAppPurchase]()
    public var unknownAttributes: [Int: Any] = [:]

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }()

    public init(data: Data) throws {
        self = try ASN1Decoder().decode(PKCS7.self, from: data).receipt
    }

    public init(from decoder: ASN1DecoderProtocol) throws {
        
        var c = try decoder.setContainer(encoded: .set)
        let attributes = try c.decodeSequence(of: ReceiptAttribute.self, encoded: .none)

        for attribute in attributes {
            switch AttributeID(rawValue: attribute.type) {
            case .receiptType:
                receiptType = try ASN1Decoder().decode(ReceiptType.self, from: attribute.value)
            case .bundleID:
                bundleID = try ASN1Decoder().value(from: attribute.value).decode(String.self, encoded: .utf8String)
            case .applicationVersion:
                applicationVersion = try ASN1Decoder().value(from: attribute.value).decode(String.self, encoded: .utf8String)
            case .opaqueValue:
                opaqueValue = attribute.value
            case .sha1Hash:
                sha1Hash = attribute.value
            case .inAppPurchases:
                inAppPurchases.append(try ASN1Decoder().decode(InAppPurchase.self, from: attribute.value))
            case .originalPurchaseDate:
                let s = try ASN1Decoder().value(from: attribute.value).decode(String.self, encoded: .ia5String)
                originalPurchaseDate = Self.dateFormatter.date(from: s)
            case .originalApplicationVersion:
                originalApplicationVersion = try ASN1Decoder().value(from: attribute.value).decode(String.self, encoded: .utf8String)
            case .creationDate:
                let s = try ASN1Decoder().value(from: attribute.value).decode(String.self, encoded: .ia5String)
                creationDate = Self.dateFormatter.date(from: s)
            case .expirationDate:
                let s = try ASN1Decoder().value(from: attribute.value).decode(String.self, encoded: .ia5String)
                creationDate = Self.dateFormatter.date(from: s)
            case .appItemID:
                appItemID = try ASN1Decoder().value(from: attribute.value).decode(Int.self, encoded: .integer)
            case .downloadID:
                downloadID = try ASN1Decoder().value(from: attribute.value).decode(Int.self, encoded: .integer)
            case .versionExternalIdentifier:
                versionExternalIdentifier = try ASN1Decoder().value(from: attribute.value).decode(Int.self, encoded: .integer)
            case .receiptCreationDate:
                let s = try ASN1Decoder().value(from: attribute.value).decode(String.self, encoded: .ia5String)
                receiptCreationDate = Self.dateFormatter.date(from: s)
            default:
                let value = (try? ASN1Decoder().value(from: attribute.value).decodeAny()) ?? attribute.value
                if let old = unknownAttributes[attribute.type] {
                    unknownAttributes[attribute.type] = (value, old)
                }
                else {
                    unknownAttributes[attribute.type] = value
                }
            }
        }
    }
    
    @available(OSX 10.15, iOS 13.0, *)
    public func validate(uuid: UUID) -> Bool {
        guard let opaqueValue = opaqueValue, let bundleID = bundleID?.data(using: .utf8), let sha1Hash = sha1Hash else {return false}
        var hash = Insecure.SHA1()
        hash.update(data: uuid.bytes)
        hash.update(data: opaqueValue)
        hash.update(data: bundleID)
        let digest = hash.finalize()
        return digest == sha1Hash
    }
}

extension Receipt {
    public struct InAppPurchase: ASN1Decodable {
        private enum AttributeID: Int {
            case quantity = 1701
            case productID = 1702
            case transactionID = 1703
            case originalTransactionID = 1705
            case purchaseDate = 1704
            case originalPurchaseDate = 1706
            case inAppType = 1707
            case expiresDate = 1708
            case isInIntroOfferPeriod = 1719
            case isTrialPeriod = 1713
            case cancellationDate = 1712
            case webOrderLineItemID = 1711
        }
        
        public struct InAppType: RawRepresentable, ASN1Decodable {
            public let rawValue: Int8
            
            public init(rawValue: Int8) {
                self.rawValue = rawValue
            }
            
            public init(from decoder: ASN1DecoderProtocol) throws {
                let i = try decoder.value(encoded: .none).decode(Int8.self, encoded: .integer)
                self.init(rawValue: i)
            }
            static let unknown = InAppType(rawValue: -1)
            static let nonConsumable = InAppType(rawValue: 0)
            static let consumable = InAppType(rawValue: 1)
            static let nonRenewingSubscription = InAppType(rawValue: 2)
            static let autoRenewableSubscription = InAppType(rawValue: 3)
        }
        
        public var quantity: Int?
        public var productID: String?
        public var transactionID: String?
        public var originalTransactionID: String?
        public var purchaseDate: Date?
        public var originalPurchaseDate: Date?
        public var inAppType: InAppType?
        public var expiresDate: Date?
        public var isInIntroOfferPeriod: Bool?
        public var isTrialPeriod: Bool?
        public var cancellationDate: Date?
        public var webOrderLineItemID: Int?
        public var unknownAttributes: [Int: Any] = [:]

        public init(from decoder: ASN1DecoderProtocol) throws {
            var c = try decoder.setContainer(encoded: .set)
            let attributes = try c.decodeSequence(of: ReceiptAttribute.self, encoded: .none)
            
            for attribute in attributes {
                switch AttributeID(rawValue: attribute.type) {
                case .quantity:
                    quantity = try ASN1Decoder().value(from: attribute.value).decode(Int.self, encoded: .integer)
                case .productID:
                    productID = try ASN1Decoder().value(from: attribute.value).decode(String.self, encoded: .utf8String)
                case .transactionID:
                    transactionID = try ASN1Decoder().value(from: attribute.value).decode(String.self, encoded: .utf8String)
                case .originalTransactionID:
                    originalTransactionID = try ASN1Decoder().value(from: attribute.value).decode(String.self, encoded: .utf8String)
                case .purchaseDate:
                    let s = try ASN1Decoder().value(from: attribute.value).decode(String.self, encoded: .ia5String)
                    purchaseDate = Receipt.dateFormatter.date(from: s)
                case .originalPurchaseDate:
                    let s = try ASN1Decoder().value(from: attribute.value).decode(String.self, encoded: .ia5String)
                    originalPurchaseDate = Receipt.dateFormatter.date(from: s)
                case .inAppType:
                    inAppType = try ASN1Decoder().decode(InAppType.self, from: attribute.value)
                case .expiresDate:
                    let s = try ASN1Decoder().value(from: attribute.value).decode(String.self, encoded: .ia5String)
                    expiresDate = Receipt.dateFormatter.date(from: s)
                case .isInIntroOfferPeriod:
                    isInIntroOfferPeriod = try ASN1Decoder().value(from: attribute.value).decode(Bool.self, encoded: .integer)
                case .isTrialPeriod:
                    isTrialPeriod = try ASN1Decoder().value(from: attribute.value).decode(Bool.self, encoded: .integer)
                case .cancellationDate:
                    let s = try ASN1Decoder().value(from: attribute.value).decode(String.self, encoded: .ia5String)
                    cancellationDate = Receipt.dateFormatter.date(from: s)
                case .webOrderLineItemID:
                    webOrderLineItemID = try ASN1Decoder().value(from: attribute.value).decode(Int.self, encoded: .integer)
                default:
                    let value = (try? ASN1Decoder().value(from: attribute.value).decodeAny()) ?? attribute.value
                    if let old = unknownAttributes[attribute.type] {
                        unknownAttributes[attribute.type] = (value, old)
                    }
                    else {
                        unknownAttributes[attribute.type] = value
                    }
                }
            }
        }
    }
}

struct ReceiptAttribute: ASN1Decodable {
    var type: Int
    var version: Int
    var value: Data
    init(from decoder: ASN1DecoderProtocol) throws {
        var c = try decoder.sequenceContainer(encoded: .sequence)
        type = try c.decode(Int.self, encoded: .integer)
        version = try c.decode(Int.self, encoded: .integer)
        value = try c.decode(Data.self, encoded: .octetString)
    }
}

extension UUID {
    var bytes: [UInt8] {
        let uuid = self.uuid
        return [uuid.0, uuid.1, uuid.2, uuid.3,
                uuid.4, uuid.5, uuid.6, uuid.7,
                uuid.8, uuid.9, uuid.10, uuid.11,
                uuid.12, uuid.13, uuid.14, uuid.15]
    }
}
