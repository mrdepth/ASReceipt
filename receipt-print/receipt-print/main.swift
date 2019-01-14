//
//  main.swift
//  receipt
//
//  Created by Artem Shimanski on 23.01.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import ASReceipt

enum ParseError: Error {
	case json
	case invalidBase64
}


class Purchase: Encodable {
	var quantity: Int?
	var productID: String?
	var transactionID: String?
	var originalTransactionID: String?
	var derived: [Purchase]?
	var purchaseDate: Date?
	var originalPurchaseDate: Date?
	var inAppType: Receipt.InAppType?
	var expiresDate: Date?
	var isInIntroOfferPeriod: Bool?
	var isTrialPeriod: Bool?
	var cancellationDate: Date?
	var webOrderLineItemID: Int?
	
	fileprivate enum CodingKeys: CodingKey {
		case quantity
		case productID
		case transactionID
		case originalTransactionID
		case derived
		case purchaseDate
		case originalPurchaseDate
		case inAppType
		case expiresDate
		case isInIntroOfferPeriod
		case isTrialPeriod
		case cancellationDate
		case webOrderLineItemID
	}
	
	init(_ purchase: Receipt.Purchase) {
		quantity = purchase.quantity
		productID = purchase.productID
		transactionID = purchase.transactionID
		originalTransactionID = purchase.originalTransactionID
		purchaseDate = purchase.purchaseDate
		originalPurchaseDate = purchase.originalPurchaseDate
		inAppType = purchase.inAppType
		expiresDate = purchase.expiresDate
		isInIntroOfferPeriod = purchase.isInIntroOfferPeriod
		isTrialPeriod = purchase.isTrialPeriod
		cancellationDate = purchase.cancellationDate
		webOrderLineItemID = purchase.webOrderLineItemID
	}
}

struct Options: OptionSet {
	var rawValue: UInt
	static let showInapps = Options(rawValue: 1 << 0)
	static let base64 = Options(rawValue: 1 << 1)
}

var options: Options = []
var input: URL?

for i in CommandLine.arguments[1...] {
	switch i {
	case "--inapp":
		options.insert(.showInapps)
	case "--base64":
		options.insert(.base64)
	default:
		input = URL(fileURLWithPath: i)
	}
}

if let input = input {
	
	do {
		let data: Data
		if options.contains(.base64) {
			guard let d = try Data(base64Encoded: Data(contentsOf: input)) else {throw ParseError.invalidBase64}
			data = d
		}
		else {
			data = try Data(contentsOf: input)
		}
//		Thread.sleep(forTimeInterval: 5)
//		do {
//			let r = (0..<30).compactMap { _ -> [Receipt.Purchase]? in
//				let r = try! Receipt(data: data)
//				return r.inAppPurchases
////				return try! Receipt(data: data)
//			}
//		}
//		Thread.sleep(forTimeInterval: 5)
		let receipt = try Receipt(data: data)
		
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

		encoder.dateEncodingStrategy = .formatted(dateFormatter)
		
		let encoded: Data
		if options.contains(.showInapps) {
			var map = [String: [Purchase]]()
			
			let purchases = receipt.inAppPurchases?.map {Purchase($0)}
			var root = [Purchase]()
			
			purchases?.forEach { map[$0.transactionID ?? "", default: []].append($0) }
			purchases?.forEach {
				if let originalTransactionID = $0.originalTransactionID, originalTransactionID != $0.transactionID, let original = map[originalTransactionID]?.first {
					var derived = original.derived ?? []
					derived.append($0)
					original.derived = derived
				}
				else {
					root.append($0)
				}
			}
			
			let inapps = root.sorted {$0.purchaseDate ?? .distantPast < $1.purchaseDate ?? .distantPast}
			encoded = try encoder.encode(inapps)
			
		}
		else {
			encoded = try encoder.encode(receipt)
		}
		
		guard let json = String(data: encoded, encoding: .utf8) else {throw ParseError.json}
		print(json)

	}
	catch {
		print ("Unable to load receipt: \(error)")
	}
}
else {
	print("usage: receipt-print source_file [options]")
	print("Options:")
	print("  --inapp\tstructured inapps output")
	print("  --base64\tinput file is base64 encoded")
}
