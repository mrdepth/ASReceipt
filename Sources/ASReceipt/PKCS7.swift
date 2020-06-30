//
//  PKCS7.swift
//  
//
//  Created by Artem Shimanski on 6/28/20.
//

import Foundation
import ASN1Decoder

public struct PKCS7: ASN1Decodable {
    public var contentType: String
    public var content: SignedData
    
    public var receipt: Receipt {
        content.encapContentInfo.eContent
    }

    public init(from decoder: ASN1DecoderProtocol) throws {
        var c = try decoder.sequenceContainer(encoded: .sequence)
        contentType = try c.decode(String.self, encoded: .objectIdentifier)
        content = try c.decode(SignedData.self, encoded: .explicit(.contextSpecific(0)))
    }
}

public struct AlgorithmIdentifier: ASN1Decodable {
    public var algorithm: String
    public var parameters: Any?
    
    public init(from decoder: ASN1DecoderProtocol) throws {
        var c = try decoder.sequenceContainer(encoded: .sequence)
        algorithm = try c.decode(String.self, encoded: .implicit(.objectIdentifier))
        parameters = try? c.decodeAny()
    }
}

public struct SignerInfo: ASN1Decodable {
    public var version: Int
    public var sid: SignerIdentifier
    public var digestAlgorithm: AlgorithmIdentifier
    public var signedAttrs: [Any]?
    public var signatureAlgorithm: AlgorithmIdentifier
    public var signature: Data
    public var unsignedAttrs: [Any]?
    
    public init(from decoder: ASN1DecoderProtocol) throws {
        var c = try decoder.sequenceContainer(encoded: .sequence)
        version = try c.decode(Int.self, encoded: .integer)
        sid = try c.decode(SignerIdentifier.self, encoded: .none)
        digestAlgorithm = try c.decode(AlgorithmIdentifier.self, encoded: .none)
        
        var set = try? c.setContainer(encoded: .implicit(.contextSpecific(0), .set))
        signedAttrs = try? set?.decodeSequenceOfAny()
        
        signatureAlgorithm = try c.decode(AlgorithmIdentifier.self, encoded: .none)
        signature = try c.decode(Data.self, encoded: .octetString)
        
        set = try? c.setContainer(encoded: .implicit(.contextSpecific(1), .set))
        unsignedAttrs = try? set?.decodeSequenceOfAny()
    }
}

public enum SignerIdentifier: ASN1Decodable {
    case issuerAndSerialNumber(IssuerAndSerialNumber)
    case subjectKeyIdentifier(Data)
    
    public init(from decoder: ASN1DecoderProtocol) throws {
        let c = try decoder.value(encoded: .none)
        if let issuerAndSerialNumber = try? c.decode(IssuerAndSerialNumber.self, encoded: .none) {
            self = .issuerAndSerialNumber(issuerAndSerialNumber)
        }
        else {
            self = try .subjectKeyIdentifier(c.decode(Data.self, encoded: .implicit(.contextSpecific(0), .octetString)))
        }
    }
}

public struct IssuerAndSerialNumber: ASN1Decodable {
    public var issuer: String
    public var serialNumber: Data
    
    public init(from decoder: ASN1DecoderProtocol) throws {
        var c = try decoder.sequenceContainer(encoded: .sequence)
        issuer = try c.decode(String.self, encoded: .utf8String)
        serialNumber = try c.decode(Data.self, encoded: .integer)
    }
}

public struct SignedData: ASN1Decodable {
    public var version: Int
    public var digestAlgorithms: [AlgorithmIdentifier]
    public var encapContentInfo: EncapsulatedContentInfo
    public var certificates: [Any]?
    public var crls: [Any]?
    public var signerInfos: [SignerInfo]

    public init(from decoder: ASN1DecoderProtocol) throws {
        var c = try decoder.sequenceContainer(encoded: .sequence)
        version = try c.decode(Int.self, encoded: .integer)
        var algorightms = try c.setContainer(encoded: .set)
        digestAlgorithms = try algorightms.decodeSequence(of: AlgorithmIdentifier.self, encoded: .none)
        encapContentInfo = try c.decode(EncapsulatedContentInfo.self, encoded: .none)
        
        var set = try? c.setContainer(encoded: .implicit(.contextSpecific(0), .implicit(.set)))
        certificates = try? set?.decodeSequenceOfAny()
        
        set = try? c.setContainer(encoded: .implicit(.contextSpecific(1), .implicit(.set)))
        crls = try? set?.decodeSequenceOfAny()
        
        var set2 = try c.setContainer(encoded: .set)
        signerInfos = try set2.decodeSequence(of: SignerInfo.self, encoded: .none)
    }
}

public struct EncapsulatedContentInfo: ASN1Decodable {
    public var eContentType: String
    public var eContent: Receipt
    
    public init(from decoder: ASN1DecoderProtocol) throws {
        var c = try decoder.sequenceContainer(encoded: .implicit(.sequence))
        eContentType = try c.decode(String.self, encoded: .implicit(.objectIdentifier))
        eContent = try c.decode(Receipt.self, encoded: .explicit(.contextSpecific(0), .explicit(.octetString)))
    }
}
