import Foundation

// Node for the parse tree
indirect enum Node {
    case variable(String)
    case not(Node)
    case and(Node, Node)
    case or(Node, Node)
    case xor(Node, Node)
    case imply(Node, Node)
    case equal(Node, Node)
    case notEqual(Node, Node)
    case constant(Bool)
}

// Recursive descent parser
class Parser {
    let tokens: [String]
    var currentIndex = 0

    init(tokens: [String]) {
        self.tokens = tokens
    }

    func parse() throws -> Node? {
        return try parseExpression()
    }

    // Recursive parsing functions
    private func parseExpression() throws -> Node? {
        //print("Parsing Expression...")
        var leftNode = try parseTerm()

        while let token = getCurrentToken(), isLogicalOperator(token) {
           // print("Parsing Logical Operator: \(token)")
            currentIndex += 1 // Consume the operator
            let rightNode = try parseTerm()
            leftNode = createBinaryNode(operatorSymbol: token, leftNode: leftNode, rightNode: rightNode)
        }

        return leftNode
    }

    private func parseTerm() throws -> Node? {
        //print("Parsing Term...")
        var leftNode = try parseFactor()

        while let token = getCurrentToken(), isComparisonOperator(token) {
           // print("Parsing Comparison Operator: \(token)")
            currentIndex += 1 // Consume the operator
            let rightNode = try parseFactor()
            leftNode = createBinaryNode(operatorSymbol: token, leftNode: leftNode, rightNode: rightNode)
        }

        return leftNode
    }

    private func parseFactor() throws -> Node? {
        //print("Parsing Factor...")
        guard let token = getCurrentToken() else { return nil }

        if token.lowercased() == "not" {
            //print("Parsing 'not'")
            currentIndex += 1 // use "not"
            if let node = try parseFactor() {
                return Node.not(node)
            }
        } else if token.lowercased() == "true" {
            //print("Parsing 'true'")
            currentIndex += 1 // use "true"
            return Node.constant(true)
        } else if token.lowercased() == "false" {
            //print("Parsing 'false'")
            currentIndex += 1 // use "false"
            return Node.constant(false)
        } else if isVariable(token) {
            //print("Parsing Variable: \(token)")
            currentIndex += 1 // use variable
            return Node.variable(token)
        } else if token == "(" {
            //print("Parsing Parentheses")
            currentIndex += 1 // use "("
            if let node = try parseExpression() {
                if getCurrentToken() == ")" {
                    currentIndex += 1 // use ")"
                    return node
                } else {
                    throw ParsingError.invalidExpression("Expected closing parenthesis.")
                }
            }
        }

        throw ParsingError.invalidExpression("Unexpected token: \(token)")
    }

    // function to create binary nodes based on the operator
    private func createBinaryNode(operatorSymbol: String, leftNode: Node?, rightNode: Node?) -> Node {
        //print("Creating Binary Node: \(operatorSymbol)")
        switch operatorSymbol {
        case "and", "∧":
            return Node.and(leftNode!, rightNode!)
        case "or", "∨":
            return Node.or(leftNode!, rightNode!)
        case "xor", "⊕":
            return Node.xor(leftNode!, rightNode!)
        case "imply", "→":
            return Node.imply(leftNode!, rightNode!)
        case "=", "eq":
            return Node.equal(leftNode!, rightNode!)
        case "≠", "neq":
            return Node.notEqual(leftNode!, rightNode!)
        default:
            return leftNode!
        }
    }

    // functions for token inspection
    private func getCurrentToken() -> String? {
        return currentIndex < tokens.count ? tokens[currentIndex] : nil
    }

    private func isLogicalOperator(_ token: String) -> Bool {
        return ["and", "or", "xor", "imply", "∧", "∨", "⊕", "→"].contains(token.lowercased())
    }

    private func isComparisonOperator(_ token: String) -> Bool {
        return ["=", "≠", "eq", "neq"].contains(token.lowercased())
    }

    private func isVariable(_ token: String) -> Bool {
        let validCharacterSet = CharacterSet.lowercaseLetters.union(CharacterSet.uppercaseLetters)
        return token.rangeOfCharacter(from: validCharacterSet.inverted) == nil
    }
}

// Custom error for parsing issues
enum ParsingError: Error {
    case invalidExpression(String)
}

// Truth table generator
class TruthTableGenerator {
    static func generateTable(variables: [String], expression: Node) {
        print("Truth Table:")
        let header = variables.map { $0.uppercased() }.joined(separator: " | ") + " | Result"
        let separator = String(repeating: "-", count: header.count)
        print(header)
        print(separator)

        for values in generateAllPossibleValues(variables) {
            var variableAssignments: [String: Bool] = [:]
            for (index, variable) in variables.enumerated() {
                variableAssignments[variable] = values[index]
            }

            let result = evaluateExpression(expression: expression, variableValues: variableAssignments)
            let valuesString = values.map { $0 ? "1" : "0" }.joined(separator: " | ")
            print("\(valuesString) | \(result)")
        }
    }

    private static func generateAllPossibleValues(_ variables: [String]) -> [[Bool]] {
        let numVariables = variables.count
        return (0..<(1 << numVariables)).map { i in
            return (0..<numVariables).map { j in
                return (i & (1 << j)) != 0
            }
        }
    }

    private static func evaluateExpression(expression: Node, variableValues: [String: Bool]) -> Bool {
        switch expression {
        case let .variable(variable):
            return variableValues[variable] ?? false
        case let .not(node):
            return !evaluateExpression(expression: node, variableValues: variableValues)
        case let .and(left, right):
            return evaluateExpression(expression: left, variableValues: variableValues) && evaluateExpression(expression: right, variableValues: variableValues)
        case let .or(left, right):
            return evaluateExpression(expression: left, variableValues: variableValues) || evaluateExpression(expression: right, variableValues: variableValues)
        case let .xor(left, right):
            return evaluateExpression(expression: left, variableValues: variableValues) != evaluateExpression(expression: right, variableValues: variableValues)
        case let .imply(left, right):
            return !evaluateExpression(expression: left, variableValues: variableValues) || evaluateExpression(expression: right, variableValues: variableValues)
        case let .equal(left, right):
            return evaluateExpression(expression: left, variableValues: variableValues) == evaluateExpression(expression: right, variableValues: variableValues)
        case let .notEqual(left, right):
            return evaluateExpression(expression: left, variableValues: variableValues) != evaluateExpression(expression: right, variableValues: variableValues)
        case let .constant(value):
            return value
        }
    }
}

// Main program
print("Enter a boolean expression:")
if let input = readLine() {
    do {
        let tokens = input.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        print("Tokens: \(tokens)")
        let parser = try Parser(tokens: tokens)
        if let parseTree = try parser.parse() {
            print("Parse Tree: \(parseTree)")
            let variables = extractVariables(from: parseTree)
            print("Variables: \(variables)")
            TruthTableGenerator.generateTable(variables: variables, expression: parseTree)
        } else {
            print("Invalid expression.")
        }
    } catch let error as ParsingError {
        print("Parsing Error: \(error)")
    } catch {
        print("An unexpected error occurred.")
    }
}
// Helper function to extract variables from the parse tree
func extractVariables(from node: Node) -> [String] {
    var variables: [String] = []

    func traverse(node: Node) {
        switch node {
        case let .variable(variable):
            variables.append(variable)
        case let .not(child):
            traverse(node: child)
        case let .and(left, right),
             let .or(left, right),
             let .xor(left, right),
             let .imply(left, right),
             let .equal(left, right),
             let .notEqual(left, right):
            traverse(node: left)
            traverse(node: right)
        case .constant, .variable:
            break
        }
    }

    traverse(node: node)
    return Array(Set(variables)).sorted()
}
