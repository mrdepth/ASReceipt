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

class UnsafeDeallocatorMutablePointer<T> {
	var pointer: UnsafeMutablePointer<T>
	var deallocator: (UnsafeMutablePointer<T>) -> Void
	
	init(_ pointer: UnsafeMutablePointer<T>, _ deallocator: @escaping (UnsafeMutablePointer<T>) -> Void) {
		self.pointer = pointer
		self.deallocator = deallocator
	}
	
	deinit {
		deallocator(pointer)
	}
}

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

public class Receipt: Encodable {
	
	public enum InAppType: Int, Encodable {
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
		}
	}

	public enum ReceiptType: String, Codable {
		case productionSandbox = "ProductionSandbox"
		case production = "Production"
	}

	
	public struct Purchase: Encodable {

		public let quantity: Int?
		public let productID: String?
		public let transactionID: String?
		public let originalTransactionID: String?
		public let purchaseDate: Date?
		public let originalPurchaseDate: Date?
		public let inAppType: InAppType?
		public let expiresDate: Date?
		public let isInIntroOfferPeriod: Bool?
		public let isTrialPeriod: Bool?
		public let cancellationDate: Date?
		public let webOrderLineItemID: Int?
		
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
			quantity 				= (attributes[.quantity] as? Attribute)?.value()
			productID 				= (attributes[.productID] as? Attribute)?.value()
			transactionID 			= (attributes[.transactionID] as? Attribute)?.value()
			originalTransactionID 	= (attributes[.originalTransactionID] as? Attribute)?.value()
			purchaseDate 			= (attributes[.purchaseDate] as? Attribute)?.value()
			originalPurchaseDate 	= (attributes[.originalPurchaseDate] as? Attribute)?.value()
			inAppType 				= (attributes[.inAppType] as? Attribute)?.value()
			expiresDate 			= (attributes[.expiresDate] as? Attribute)?.value()
			isInIntroOfferPeriod 	= (attributes[.isInIntroOfferPeriod] as? Attribute)?.value()
			isTrialPeriod 			= (attributes[.isTrialPeriod] as? Attribute)?.value()
			cancellationDate 		= (attributes[.cancellationDate] as? Attribute)?.value()
			webOrderLineItemID 		= (attributes[.webOrderLineItemID] as? Attribute)?.value()
		}
		
		public var isExpired: Bool {
			guard let date = expiresDate else {return true}
			return date <= Date()
		}
		
		public var isCancelled: Bool {
			guard let cancellationDate = cancellationDate else {return false}
			return cancellationDate <= Date()
		}
	}
	
	private var pkcs7: UnsafeDeallocatorMutablePointer<PKCS7>
	private var attributes: [CodingKeys: Any]
	
	public lazy var receiptType: ReceiptType?					= (self.attributes[.receiptType] as? Attribute)?.value()
	public lazy var bundleID: String? 							= (self.attributes[.bundleID] as? Attribute)?.value()
	public lazy var applicationVersion: String?					= (self.attributes[.applicationVersion] as? Attribute)?.value()
	public lazy var opaqueValue: Data?							= (self.attributes[.opaqueValue] as? Attribute)?.value()
	public lazy var sha1Hash: Data?								= (self.attributes[.sha1Hash] as? Attribute)?.value()
	public lazy var originalPurchaseDate: Date?					= (self.attributes[.originalPurchaseDate] as? Attribute)?.value()
	public lazy var originalApplicationVersion: String?			= (self.attributes[.originalApplicationVersion] as? Attribute)?.value()
	public lazy var creationDate: Date?							= (self.attributes[.creationDate] as? Attribute)?.value()
	public lazy var expirationDate: Date?						= (self.attributes[.expirationDate] as? Attribute)?.value()
	public lazy var inAppPurchases: [Purchase]? = {
		(self.attributes[.inAppPurchases] as? [Attribute])?.compactMap { i -> Purchase? in
			guard let payload: UnsafeDeallocatorMutablePointer<Payload> = i.value() else {return nil}
			return Purchase(attributes: payload.pointer.attr(keyedBy: Purchase.CodingKeys.self))
		}
	}()
	public lazy var appItemID: Int? 							= (self.attributes[.appItemID] as? Attribute)?.value()
	public lazy var downloadID: Int? 							= (self.attributes[.downloadID] as? Attribute)?.value()
	public lazy var versionExternalIdentifier: Int? 			= (self.attributes[.versionExternalIdentifier] as? Attribute)?.value()
	public lazy var receiptCreationDate: Date?					= (self.attributes[.receiptCreationDate] as? Attribute)?.value()


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
	
	public convenience init() throws {
		guard let url = Bundle.main.appStoreReceiptURL else {throw ReceiptError.receiptNotFound}
		let data = try Data(contentsOf: url)
		try self.init(data: data)
	}
	
	private var payload: UnsafeDeallocatorMutablePointer<Payload>

	public init(data: Data) throws {
		let bio = BIO_new(BIO_s_mem())
		defer {BIO_free(bio)}
		
		guard data.withUnsafeBytes ({ ptr in
			BIO_write(bio, ptr.baseAddress, Int32(data.count))
		}) > 0 else { throw ReceiptError.lastError() ?? ReceiptError.unknown }
		
		guard let pkcs7ptr = d2i_PKCS7_bio(bio, nil) else { throw ReceiptError.lastError() ?? ReceiptError.unknown }
		let pkcs7 = UnsafeDeallocatorMutablePointer(pkcs7ptr) { ptr in
			PKCS7_free(ptr)
		}
		self.pkcs7 = pkcs7
		
		let payload = pkcs7.pointer.pointee.d.sign.pointee.contents.pointee.d.data.pointee
		var ptr: UnsafeMutableRawPointer? = nil
		guard asn_DEF_Payload.ber_decoder(nil, &asn_DEF_Payload, &ptr, payload.data, Int(payload.length), 0).code == RC_OK,
			let pl = ptr?.assumingMemoryBound(to: Payload_t.self) else {
				asn_DEF_Payload.free_struct(&asn_DEF_Payload, ptr, 0)
				throw ReceiptError.lastError() ?? ReceiptError.unknown
		}

		self.payload = UnsafeDeallocatorMutablePointer(pl, { ptr in
			asn_DEF_Payload.free_struct(&asn_DEF_Payload, ptr, 0)
		})

		attributes = pl.attr(keyedBy: CodingKeys.self)
	}
	
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
			EVP_DigestUpdate(&ctx, ptr.baseAddress, opaqueValue.count)
		}
		
		bundleID.withUnsafeBytes { ptr -> Void in
			EVP_DigestUpdate(&ctx, ptr.baseAddress, bundleID.count)
		}
		
		var digest = Data(count: 20)
		digest.withUnsafeMutableBytes { ptr -> Void in
			EVP_DigestFinal(&ctx, ptr.bindMemory(to: UInt8.self).baseAddress, nil)
		}
		guard digest == hash else {throw ReceiptError.validationFailed(NSLocalizedString("Hash mismatch", comment: ""))}
	}
	
	public func verify(rootCertData: Data) throws {
		let bio = BIO_new(BIO_s_mem())
		defer {BIO_free(bio)}
		guard rootCertData.withUnsafeBytes ({ ptr in
			BIO_write(bio, ptr.baseAddress, Int32(rootCertData.count))
		}) > 0 else { throw ReceiptError.lastError() ?? ReceiptError.unknown }

		let store = X509_STORE_new()
		defer { X509_STORE_free(store) }
		
		let apple = d2i_X509_bio(bio, nil)
		defer {X509_free(apple);}
		X509_STORE_add_cert(store, apple)
		
		OpenSSL_add_all_digests()
		defer {EVP_cleanup()}
		guard PKCS7_verify(pkcs7.pointer, nil, store, nil, nil, 0) == 1 else {
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
	
	public func purchase(transactionID: String) -> Purchase? {
		return inAppPurchases?.first(where: {$0.transactionID == transactionID})
	}
	
	#if os(iOS)
	public class func fetchValidReceipt(refreshIfNeeded refresh: Bool, completion: @escaping(ReceiptFetchResult) -> Void) {
		var left = 3
		
		func fetchReceipt(uuid: UUID) {
			do {
				let receipt = try Receipt()
				try receipt.verify(uuid: uuid)
				completion(.success(receipt))
			}
			catch {
				if refresh {
					let request = SKReceiptRefreshRequest()
					var delegate: RequestDelegate?
					delegate = RequestDelegate { (request, error) in
						DispatchQueue.main.async {
							if let error = error {
								completion(.failure(error))
							}
							else {
								do {
									let receipt = try Receipt()
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
					request.start()
				}
				else {
					completion(.failure(error))
				}
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
		try container.encodeIfPresent(inAppPurchases?.sorted {($0.purchaseDate ?? .distantPast) < ($1.purchaseDate ?? .distantPast)}, forKey: .inAppPurchases)
		try container.encodeIfPresent(appItemID, forKey: .appItemID)
		try container.encodeIfPresent(downloadID, forKey: .downloadID)
		try container.encodeIfPresent(versionExternalIdentifier, forKey: .versionExternalIdentifier)
		try container.encodeIfPresent(receiptCreationDate, forKey: .receiptCreationDate)
	}
}


extension UnsafeMutablePointer where Pointee == Payload {
	
	func attr<Key>(keyedBy: Key.Type) -> [Key: Any] where Key: CodingKey {
		let pairs = (0..<Int(pointee.list.count)).compactMap {pointee.list.array[$0]}.compactMap{ i -> (Key, Any)? in
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
	
	func value() -> UnsafeDeallocatorMutablePointer<Payload>? {
		switch type {
		case (V_ASN1_SET, let length, let ptr):
			var payload: UnsafeMutableRawPointer? = nil
			guard asn_DEF_Payload.ber_decoder(nil, &asn_DEF_Payload, &payload, ptr, length, 0).code == RC_OK else {
				asn_DEF_Payload.free_struct(&asn_DEF_Payload, payload, 0)
				return nil
			}
			return (payload?.assumingMemoryBound(to: Payload.self)).map{UnsafeDeallocatorMutablePointer($0, { ptr in
				asn_DEF_Payload.free_struct(&asn_DEF_Payload, ptr, 0)
			})}
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



