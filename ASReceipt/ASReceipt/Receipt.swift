//
//  AppStoreReceipt.swift
//  AppStoreReceipt
//
//  Created by Artem Shimanski on 19.01.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
import StoreKit
#endif
import openssl
import Payload

#if os(iOS)

class RequestDelegate: NSObject, SKRequestDelegate {
	
	var completion: ((SKRequest, Error?) -> Void)?
	
	init(completion: ((SKRequest, Error?) -> Void)?) {
		self.completion = completion
		super.init()
	}
	
	func requestDidFinish(_ request: SKRequest) {
		completion?(request, nil)
	}
	
	func request(_ request: SKRequest, didFailWithError error: Error) {
		completion?(request, error)
	}
	
}
#endif

public enum ReceiptError: Error {
	case unknown
	case pkcs7(String)
	case receiptMalformed
	case validationFailed(String)
	case unableToObtainVendorIdentifier
	case receiptNotFound
	
	static func lastError() -> ReceiptError? {
		ERR_load_crypto_strings()
		defer { ERR_free_strings() }
		guard let reason = ERR_reason_error_string(ERR_get_error()) else {return nil}
		guard let string = String(cString: reason, encoding: .utf8) else {return nil}
		return .pkcs7(string)
	}
}

public enum ReceiptFetchResult {
	case success(Receipt)
	case failure(Error)
}

@objc(ASReceipt)
public class Receipt: NSObject, Encodable {
	
	@objc(ASInAppType)
	public enum InAppType: Int, Codable {
		case unknown = -1
		case nonConsumable = 0
		case consumable = 1
		case nonRenewingSubscription = 2
		case autoRenewableSubscription = 3
		
		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			switch self {
			case .unknown:
				try container.encode("unknown")
			case .nonConsumable:
				try container.encode("nonConsumable")
			case .consumable:
				try container.encode("consumable")
			case .nonRenewingSubscription:
				try container.encode("nonRenewingSubscription")
			case .autoRenewableSubscription:
				try container.encode("autoRenewableSubscription")
			}
//			try container.encode("\(self)")
		}
	}

	public enum ReceiptType: String, Codable {
		case productionSandbox = "ProductionSandbox"
		case production = "Production"
		
		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode("\(self)")
		}
	}

	
	@objc(ASPurchase)
	public class Purchase: NSObject, Encodable {
		private var attributes: [CodingKeys: Any]
		
		@objc public lazy var quantity: Int 					= (self.attributes[.quantity] as? Attribute)?.value() ?? 0
		@objc public lazy var productID: String					= (self.attributes[.productID] as? Attribute)?.value() ?? ""
		@objc public lazy var transactionID: String				= (self.attributes[.transactionID] as? Attribute)?.value() ?? ""
		@objc public lazy var originalTransactionID: String?	= (self.attributes[.originalTransactionID] as? Attribute)?.value()
		@objc public lazy var purchaseDate: Date				= (self.attributes[.purchaseDate] as? Attribute)?.value() ?? .distantPast
		@objc public lazy var originalPurchaseDate: Date?		= (self.attributes[.originalPurchaseDate] as? Attribute)?.value()
		@objc public lazy var inAppType: InAppType				= (self.attributes[.inAppType] as? Attribute)?.value() ?? .unknown
		@objc public lazy var expiresDate: Date?				= (self.attributes[.expiresDate] as? Attribute)?.value()
		@objc public lazy var isInIntroOfferPeriod: Bool		= (self.attributes[.isInIntroOfferPeriod] as? Attribute)?.value() ?? false
		@objc public lazy var isTrialPeriod: Bool				= (self.attributes[.isTrialPeriod] as? Attribute)?.value() ?? false
		@objc public lazy var cancellationDate: Date?			= (self.attributes[.cancellationDate] as? Attribute)?.value()
		@objc public lazy var webOrderLineItemID: Int			= (self.attributes[.webOrderLineItemID] as? Attribute)?.value() ?? 0
		
		fileprivate enum CodingKeys: Int, CodingKey {
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
		
		fileprivate init(attributes: [CodingKeys: Any]) {
			self.attributes = attributes
		}
		
		@objc
		public var isExpired: Bool {
			guard let date = expiresDate else {return true}
			return date < Date()
		}
		
		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			if quantity > 0 {
				try container.encodeIfPresent(quantity, forKey: .quantity)
			}
			try container.encodeIfPresent(productID, forKey: .productID)
			try container.encodeIfPresent(transactionID, forKey: .transactionID)
			try container.encodeIfPresent(originalTransactionID, forKey: .originalTransactionID)
			try container.encodeIfPresent(purchaseDate, forKey: .purchaseDate)
			try container.encodeIfPresent(originalPurchaseDate, forKey: .originalPurchaseDate)
			try container.encodeIfPresent(inAppType, forKey: .inAppType)
			try container.encodeIfPresent(expiresDate, forKey: .expiresDate)
			try container.encodeIfPresent(isInIntroOfferPeriod, forKey: .isInIntroOfferPeriod)
			try container.encodeIfPresent(isTrialPeriod, forKey: .isTrialPeriod)
			try container.encodeIfPresent(cancellationDate, forKey: .cancellationDate)
			if webOrderLineItemID > 0 {
				try container.encodeIfPresent(webOrderLineItemID, forKey: .webOrderLineItemID)
			}
		}
	}
	
	private var pkcs7: UnsafeMutablePointer<PKCS7>
	private var attributes: [CodingKeys: Any]
	
	public lazy var receiptType: ReceiptType?					= (self.attributes[.receiptType] as? Attribute)?.value()
	@objc public lazy var bundleID: String 						= (self.attributes[.bundleID] as? Attribute)?.value() ?? ""
	@objc public lazy var applicationVersion: String			= (self.attributes[.applicationVersion] as? Attribute)?.value() ?? ""
	@objc public lazy var opaqueValue: Data?					= (self.attributes[.opaqueValue] as? Attribute)?.value()
	@objc public lazy var sha1Hash: Data?						= (self.attributes[.sha1Hash] as? Attribute)?.value()
	@objc public lazy var originalPurchaseDate: Date?			= (self.attributes[.originalPurchaseDate] as? Attribute)?.value()
	@objc public lazy var originalApplicationVersion: String?	= (self.attributes[.originalApplicationVersion] as? Attribute)?.value()
	@objc public lazy var creationDate: Date?					= (self.attributes[.creationDate] as? Attribute)?.value()
	@objc public lazy var expirationDate: Date?					= (self.attributes[.expirationDate] as? Attribute)?.value()
	@objc public lazy var inAppPurchases: [Purchase]? = {
		(self.attributes[.inAppPurchases] as? [Attribute])?.flatMap { i -> [Purchase.CodingKeys: Any]? in
			guard let payload: UnsafeMutablePointer<Payload> = i.value() else {return nil}
			return payload.attr(keyedBy: Purchase.CodingKeys.self)
			}.map { Purchase(attributes: $0)}
	}()
	@objc public lazy var appItemID: Int 					= (self.attributes[.appItemID] as? Attribute)?.value() ?? 0
	@objc public lazy var downloadID: Int 					= (self.attributes[.downloadID] as? Attribute)?.value() ?? 0
	@objc public lazy var versionExternalIdentifier: Int 	= (self.attributes[.versionExternalIdentifier] as? Attribute)?.value() ?? 0
	@objc public lazy var receiptCreationDate: Date?		= (self.attributes[.receiptCreationDate] as? Attribute)?.value()


	private enum CodingKeys: Int, CodingKey {
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
	
	@objc
	public init(data: Data) throws {
		let bio = BIO_new(BIO_s_mem())
		defer {BIO_free(bio)}
		
		guard data.withUnsafeBytes ({ ptr in
			BIO_write(bio, ptr, Int32(data.count))
		}) > 0 else { throw ReceiptError.lastError() ?? ReceiptError.unknown }
		
		guard let pkcs7 = d2i_PKCS7_bio(bio, nil) else { throw ReceiptError.lastError() ?? ReceiptError.unknown }
		var isInitialized = false
		defer { if !isInitialized { PKCS7_free(pkcs7) } }
		self.pkcs7 = pkcs7
		
		let payload = pkcs7.pointee.d.sign.pointee.contents.pointee.d.data.pointee
		var ptr: UnsafeMutableRawPointer? = nil
		guard asn_DEF_Payload.ber_decoder(nil, &asn_DEF_Payload, &ptr, payload.data, Int(payload.length), 0).code == RC_OK else { throw ReceiptError.lastError() ?? ReceiptError.unknown }
		guard let pl = ptr?.assumingMemoryBound(to: Payload_t.self) else { throw ReceiptError.lastError() ?? ReceiptError.unknown }
		attributes = pl.attr(keyedBy: CodingKeys.self)
		isInitialized = true
	}
	
	deinit {
		PKCS7_free(pkcs7)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encodeIfPresent(receiptType, forKey: .receiptType)
		try container.encodeIfPresent(bundleID, forKey: .bundleID)
		try container.encodeIfPresent(applicationVersion, forKey: .applicationVersion)
		try container.encodeIfPresent(opaqueValue, forKey: .opaqueValue)
		try container.encodeIfPresent(sha1Hash, forKey: .sha1Hash)
		try container.encodeIfPresent(originalPurchaseDate, forKey: .originalPurchaseDate)
		try container.encodeIfPresent(originalApplicationVersion, forKey: .originalApplicationVersion)
		try container.encodeIfPresent(creationDate, forKey: .creationDate)
		try container.encodeIfPresent(expirationDate, forKey: .expirationDate)
		try container.encodeIfPresent(inAppPurchases?.sorted {$0.purchaseDate < $1.purchaseDate}, forKey: .inAppPurchases)
		
		if appItemID > 0 {
			try container.encodeIfPresent(appItemID, forKey: .appItemID)
		}
		if downloadID > 0 {
			try container.encodeIfPresent(downloadID, forKey: .downloadID)
		}
		if versionExternalIdentifier > 0 {
			try container.encodeIfPresent(versionExternalIdentifier, forKey: .versionExternalIdentifier)
		}
		try container.encodeIfPresent(receiptCreationDate, forKey: .receiptCreationDate)
	}
	
	@objc
	public func verify(uuid: UUID) throws {
		guard let bundleID: Data = (attributes[.bundleID] as? Attribute)?.value(),
			let opaqueValue: Data = (attributes[.opaqueValue] as? Attribute)?.value(),
			let hash: Data = (attributes[.sha1Hash] as? Attribute)?.value() else {throw ReceiptError.receiptMalformed}
		
		var uuid = uuid.uuid
		var ctx = EVP_MD_CTX()
		EVP_MD_CTX_init(&ctx)
		defer{EVP_MD_CTX_cleanup(&ctx)}
		
		EVP_DigestInit_ex(&ctx, EVP_sha1(), nil)
		
		withUnsafePointer(to: &uuid) { ptr -> Void in
			EVP_DigestUpdate(&ctx, ptr, MemoryLayout<uuid_t>.size)
		}
		
		opaqueValue.withUnsafeBytes { ptr -> Void in
			EVP_DigestUpdate(&ctx, ptr, opaqueValue.count)
		}
		
		bundleID.withUnsafeBytes { ptr -> Void in
			EVP_DigestUpdate(&ctx, ptr, bundleID.count)
		}
		
		var digest = Data(count: 20)
		digest.withUnsafeMutableBytes { ptr -> Void in
			EVP_DigestFinal(&ctx, ptr, nil)
		}
		guard digest == hash else {throw ReceiptError.validationFailed(NSLocalizedString("Hash mismatch", comment: ""))}
	}
	
	@objc
	public func verify(rootCertData: Data) throws {
		let bio = BIO_new(BIO_s_mem())
		defer {BIO_free(bio)}
		guard rootCertData.withUnsafeBytes ({ ptr in
			BIO_write(bio, ptr, Int32(rootCertData.count))
		}) > 0 else { throw ReceiptError.lastError() ?? ReceiptError.unknown }

		let store = X509_STORE_new()
		defer { X509_STORE_free(store) }
		
		let apple = d2i_X509_bio(bio, nil)
		defer {X509_free(apple);}
		X509_STORE_add_cert(store, apple)
		
		OpenSSL_add_all_digests()
		defer {EVP_cleanup()}
		guard PKCS7_verify(pkcs7, nil, store, nil, nil, 0) == 1 else {
			ERR_load_crypto_strings()
			defer { ERR_free_strings() }
			let string: String = {
				guard let reason = ERR_reason_error_string(ERR_get_error()) else {return nil}
				guard let string = String(cString: reason, encoding: .utf8) else {return nil}
				return string
			}() ?? NSLocalizedString("Unknown error", comment: "")
			throw ReceiptError.validationFailed(string)
		}
	}
	
	@objc
	public static var local: Receipt? {
		guard let url = Bundle.main.appStoreReceiptURL else {return nil}
		guard let data = try? Data(contentsOf: url) else {return nil}
		return try? Receipt(data: data)
	}

	@objc
	public func purchase(transactionID: String) -> Purchase? {
		return inAppPurchases?.first(where: {$0.transactionID == transactionID})
	}
	
	#if os(iOS)
	public class func fetchValidReceipt(completion: @escaping(ReceiptFetchResult) -> Void) {
		var left = 3
		
		func fetchReceipt(uuid: UUID) {
			do {
				guard let receipt = Receipt.local else {throw ReceiptError.receiptNotFound}
				try receipt.verify(uuid: uuid)
				completion(.success(receipt))
			}
			catch {
				/*let request = SKReceiptRefreshRequest()
				var delegate: RequestDelegate?
				delegate = RequestDelegate { (request, error) in
					DispatchQueue.main.async {
						if let error = error {
							completion(.failure(error))
						}
						else {
							do {
								guard let receipt = Receipt.local else {throw ReceiptError.receiptNotFound}
								try receipt.verify(uuid: uuid)
								completion(.success(receipt))
							}
							catch {
								completion(.failure(error))
							}
						}
						delegate = nil
					}
				}
				request.delegate = delegate
				request.start()*/
				completion(.failure(error))
			}
		}
		
		
		func fetchUUID() {
			if let uuid = UIDevice.current.identifierForVendor {
				fetchReceipt(uuid: uuid)
			}
			else if left > 1{
				left -= 1
				DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
					fetchUUID()
				}
			}
			else {
				completion(.failure(ReceiptError.unableToObtainVendorIdentifier))
			}
		}
		
		fetchUUID()

	}
	#endif
}


extension UnsafeMutablePointer where Pointee == Payload {
	
	func attr<Key>(keyedBy: Key.Type) -> [Key: Any] where Key: CodingKey {
		let pairs = (0..<Int(pointee.list.count)).flatMap {pointee.list.array[$0]}.flatMap{ i -> (Key, Any)? in
			guard let key = Key(intValue: i.pointee.type) else {return nil}
			return i.type.0 == V_ASN1_SET ? (key, [i]) : (key, i)
		}
		
		return Dictionary(pairs) { (first, last) -> [Any] in
			guard let a = first as? [Any], let b = last as? [Any] else {return [first, last]}
			return Array([a, b].joined())
		}
	}
}

fileprivate let dateFormatter: DateFormatter = {
	let dateFormatter = DateFormatter()
	dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
	dateFormatter.locale = Locale(identifier: "en_US_POSIX")
	dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
	return dateFormatter
}()

typealias Attribute = UnsafeMutablePointer<ReceiptAttribute>

extension UnsafeMutablePointer where Pointee == ReceiptAttribute {
	
	private var type: (Int32, Int, UnsafePointer<UInt8>?) {
		var length: Int = 0
		var asn1Type: Int32 = 0
		var xclass: Int32 = 0
		var ptr = UnsafePointer(pointee.value.buf)
		ASN1_get_object(&ptr, &length, &asn1Type, &xclass, Int(self.pointee.value.size))
		return asn1Type == V_ASN1_SET ? (asn1Type, Int(pointee.value.size), UnsafePointer(pointee.value.buf)) : (asn1Type, length, ptr)
	}
	
	func value() -> String? {
		switch type {
		case (V_ASN1_UTF8STRING, let length, let ptr):
			return ptr?.withMemoryRebound(to: CChar.self, capacity: length, { (ptr) -> String? in
				let ptr = UnsafeMutablePointer<CChar>(mutating: ptr)
				return String.init(bytesNoCopy: ptr, length: length, encoding: .utf8, freeWhenDone: false)
			})
		case (V_ASN1_IA5STRING, let length, let ptr):
			return ptr?.withMemoryRebound(to: CChar.self, capacity: length, { (ptr) -> String? in
				let ptr = UnsafeMutablePointer<CChar>(mutating: ptr)
				return String.init(bytesNoCopy: ptr, length: length, encoding: .ascii, freeWhenDone: false)
			})
		default:
			return nil
		}
	}
	
	func value() -> Int? {
		switch type {
		case (V_ASN1_INTEGER, let length, var ptr):
			let integer = c2i_ASN1_INTEGER(nil, &ptr, length)
			defer {ASN1_INTEGER_free(integer)}
			return ASN1_INTEGER_get(integer)
		default:
			return nil
		}
	}
	
	func value() -> Bool? {
		guard let i: Int = value() else {return false}
		return i != 0
	}
	
	func value() -> UnsafeMutablePointer<Payload>? {
		switch type {
		case (V_ASN1_SET, let length, let ptr):
			var payload: UnsafeMutableRawPointer? = nil
			guard asn_DEF_Payload.ber_decoder(nil, &asn_DEF_Payload, &payload, ptr, length, 0).code == RC_OK else {return nil}
			return payload?.assumingMemoryBound(to: Payload.self)
		default:
			return nil
		}
	}
	
	func value() -> Data? {
		return Data(bytesNoCopy: pointee.value.buf, count: Int(pointee.value.size), deallocator: Data.Deallocator.none)
	}
	
	
	func value() -> Date? {
		guard let s: String = value() else {return nil}
		return dateFormatter.date(from: s)
	}
	
	func value<T>() -> T? where T: RawRepresentable, T.RawValue == Int {
		guard let value: T.RawValue = value() else {return nil}
		return T(rawValue: value)
	}
	
	func value<T>() -> T? where T: RawRepresentable, T.RawValue == String {
		guard let value: T.RawValue = value() else {return nil}
		return T(rawValue: value)
	}

}



