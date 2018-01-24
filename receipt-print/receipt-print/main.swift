//
//  main.swift
//  receipt
//
//  Created by Artem Shimanski on 23.01.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import ASReceipt


if CommandLine.arguments.count == 2 {
	enum ParseError: Error {
		case json
	}

	do {
		let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))

		let receipt = try Receipt(data: data)
		
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

		encoder.dateEncodingStrategy = .formatted(dateFormatter)
		let encoded = try encoder.encode(receipt)
		guard let json = String(data: encoded, encoding: .utf8) else {throw ParseError.json}
		print(json)
	}
	catch {
		print ("Unable to load receipt")
	}
}
else {
	print("usage: receipt-print source_file")
}
