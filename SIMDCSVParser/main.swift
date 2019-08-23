//
//  main.swift
//  SIMDCSVParser
//
//  Created by Chris Eidhof on 22.08.19.
//  Copyright © 2019 Chris Eidhof. All rights reserved.
//

import Foundation

extension String {
    var key: String {
        return padding(toLength: 20, withPad: " ", startingAt: 0)
    }
}

extension Data {
    func parseCSV() {
        assert(count >= 64)
        let chunk = self[0..<64]
        chunk.withUnsafeBytes { buf in
            buf.parseCSVChunk()
        }
    }
}

extension UInt8 {
    static let quote: UInt8 = "\"".utf8.first!
    static let comma: UInt8 = ",".utf8.first!
    static let newline: UInt8 = "\n".utf8.first!
}

extension UInt64 {
    static let evens: UInt64 = (0..<64).reduce(0, { result, bit in
        (bit % 2 == 0) ? result | (1 << bit) : result
    })
    static let odds = ~evens
}

extension UnsafeRawBufferPointer {
    func parseCSVChunk() {
        assert(count == 64)
        let input = self.baseAddress!.assumingMemoryBound(to: UInt8.self)
        let quotes = cmp_mask_against_input(input, .quote)
        print("quotes".key, quotes.bits)
        
        let quoteStarts = ~(quotes << 1) & quotes
        let evenStarts = quoteStarts & .evens
        var endsOfEvenStarts = evenStarts &+ quotes
        endsOfEvenStarts &= ~quotes
        let oddEndsOfEvenStarts = endsOfEvenStarts & .odds
        
        let oddStarts = quoteStarts & .odds
        var endsOfOddStarts = oddStarts &+ quotes
        endsOfOddStarts &= ~quotes
        let evenEndsOfOddStarts = endsOfOddStarts & .evens
        let endsOfOddLength = oddEndsOfEvenStarts | evenEndsOfOddStarts
        print("endsOfOddLength".key, endsOfOddLength.bits)
        
        let stringMask = carryless_multiply(endsOfOddLength, ~0)
        print("stringMask".key, stringMask.bits)
        
        let commas = cmp_mask_against_input(input, .comma)
        let controlCommas = commas & ~stringMask
        print("controlCommas".key, controlCommas.bits)
    }
}

extension UInt64: Collection {
    public var startIndex: Int { 0 }
    public var endIndex: Int { 64 }
    public func index(after i: Int) -> Int {
        return i + 1
    }
    public subscript(index: Int) -> Bool {
        return (self & (1 << index)) > 0
    }
    
    var bits: String {
        map { $0 ? "1" : "0" }.joined(separator: "")
    }
}

let sample = #"""
"Plain Field","Field,with comma","With """"escaped"" quotes","Another field",without quotes
"""#

let data = sample.data(using: .utf8)!
print("CSV".key, sample.prefix(64))
data.parseCSV()
