import Foundation

/// Arithmetic over other measures: `Formula=MeasureIn + MeasureOut / 1024`.
/// Supports + - * / % ( ), numbers, and measure names as identifiers.
public final class CalcMeasure: Measure {
    private let formula: String

    public override init(name: String, options: Options) {
        self.formula = options.str("formula", default: "0")
        super.init(name: name, options: options)
    }

    public override func update() {
        value = CalcEvaluator.evaluate(formula) { [weak self] identifier in
            self?.resolver?(identifier)?.value
        } ?? 0
    }
}

/// Small recursive-descent evaluator, separate from the measure so tests can
/// exercise it directly.
public enum CalcEvaluator {
    public static func evaluate(_ text: String,
                                lookup: @escaping (String) -> Double?) -> Double? {
        var parser = Parser(text: Array(text), lookup: lookup)
        let result = parser.parseExpression()
        parser.skipWhitespace()
        return parser.failed || !parser.atEnd ? nil : result
    }

    private struct Parser {
        let text: [Character]
        let lookup: (String) -> Double?
        var pos = 0
        var failed = false

        var atEnd: Bool { pos >= text.count }

        mutating func skipWhitespace() {
            while !atEnd, text[pos].isWhitespace { pos += 1 }
        }

        mutating func parseExpression() -> Double {
            var left = parseTerm()
            while true {
                skipWhitespace()
                guard !atEnd, text[pos] == "+" || text[pos] == "-" else { return left }
                let op = text[pos]; pos += 1
                let right = parseTerm()
                left = op == "+" ? left + right : left - right
            }
        }

        mutating func parseTerm() -> Double {
            var left = parseFactor()
            while true {
                skipWhitespace()
                guard !atEnd, "*/%".contains(text[pos]) else { return left }
                let op = text[pos]; pos += 1
                let right = parseFactor()
                switch op {
                case "*": left *= right
                case "/": left = right == 0 ? 0 : left / right
                default:  left = right == 0 ? 0 : left.truncatingRemainder(dividingBy: right)
                }
            }
        }

        mutating func parseFactor() -> Double {
            skipWhitespace()
            guard !atEnd else { failed = true; return 0 }
            if text[pos] == "-" { pos += 1; return -parseFactor() }
            if text[pos] == "(" {
                pos += 1
                let inner = parseExpression()
                skipWhitespace()
                if !atEnd, text[pos] == ")" { pos += 1 } else { failed = true }
                return inner
            }
            if text[pos].isNumber || text[pos] == "." {
                var literal = ""
                while !atEnd, text[pos].isNumber || text[pos] == "." {
                    literal.append(text[pos]); pos += 1
                }
                guard let number = Double(literal) else { failed = true; return 0 }
                return number
            }
            if text[pos].isLetter || text[pos] == "_" {
                var identifier = ""
                while !atEnd, text[pos].isLetter || text[pos].isNumber || text[pos] == "_" {
                    identifier.append(text[pos]); pos += 1
                }
                guard let resolved = lookup(identifier) else { failed = true; return 0 }
                return resolved
            }
            failed = true
            return 0
        }
    }
}
