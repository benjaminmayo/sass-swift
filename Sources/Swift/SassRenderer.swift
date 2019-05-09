import Foundation
import libsass

public final class SassRenderer {
    public var options = Options()
    
    public init() {
        
    }
    
    public func compile(_ input: String, labelledWithFilePath filePathLabel: String = "") throws -> String {
        let input = strdup(input)
        
        let context = sass_make_data_context(input)
        
        let options = sass_data_context_get_options(context)
        
        self.applyOptions(to: options!)
        
        if !filePathLabel.isEmpty {
            let filePathLabel = strdup(filePathLabel)
            
            sass_option_set_input_path(options!, filePathLabel)
        }
        
        sass_data_context_set_options(context, options)
        
        let compiler = sass_make_data_compiler(context)
        
        defer {
            sass_delete_compiler(compiler)
            sass_delete_data_context(context)
        }
        
        sass_compiler_parse(compiler)
        sass_compiler_execute(compiler)
        
        guard let output = sass_context_get_output_string(context) else {
           throw Error(for: context)
        }
        
        let result = String(cString: output)
    
        return result
    }
    
    public struct Options {
        public var precision: Precision = .default
        public var outputStyle: OutputStyle = .humane
        public var canInsertSourceReferenceComments: Bool = false
        public var baseURLForImportedFiles: URL?
        
        public struct Precision {
            public let significantFigures: Int
            
            public init(significantFigures: Int) {
                self.significantFigures = significantFigures
            }
            
            public static var `default`: Precision {
                return .init(significantFigures: 10)
            }
        }
        
        public enum OutputStyle {
            case humane
            case compact
            case compressed
        }
        
        public init() {
            
        }
    }
    
    public enum Error : Swift.Error, CustomStringConvertible {
        case parsingFailed(SourceLocation, message: String)
        case internalFault(message: String)
        
        public var description: String {
            switch self {
                case .parsingFailed(_, message: let message):
                    return message
                case .internalFault(message: let message):
                    return message
            }
        }
    }
    
    public struct SourceLocation {
        public let line: Int
        public let column: Int
    }
}

extension SassRenderer {
    private func applyOptions(to optionsContext: OpaquePointer) {
        sass_option_set_precision(optionsContext, Int32(self.options.precision.significantFigures))
        
        let outputStyle: Sass_Output_Style
        
        switch self.options.outputStyle {
            case .compact:
                outputStyle = SASS_STYLE_COMPACT
            case .humane:
                outputStyle = SASS_STYLE_EXPANDED
            case .compressed:
                outputStyle = SASS_STYLE_COMPRESSED
        }
        
        sass_option_set_output_style(optionsContext, outputStyle)
        
        sass_option_set_source_comments(optionsContext, self.options.canInsertSourceReferenceComments)
        
        if let baseURLForImportedFiles = self.options.baseURLForImportedFiles {
            let includePath = strdup(baseURLForImportedFiles.path)
            
            sass_option_set_include_path(optionsContext, includePath)
        }
    }
}

extension SassRenderer.Error {
    fileprivate init(for context: OpaquePointer!) {
        let statusCode = sass_context_get_error_status(context)
        
        func defaultFallbackError() -> SassRenderer.Error {
            return .internalFault(message: "Unknown error with status code \(statusCode)")
        }
    
        guard
            let jsonError = sass_context_get_error_json(context).map({ String(cString: $0) }),
            let errorData = try? JSONDecoder().decode(JSONErrorData.self, from: Data(jsonError.utf8))
        else {
            self = defaultFallbackError()
            
            return
        }

        let sourceLocation = SassRenderer.SourceLocation(line: errorData.line, column: errorData.column)
        
        self = .parsingFailed(sourceLocation, message: errorData.message)
    }
    
    private struct JSONErrorData : Decodable {
        let line: Int
        let column: Int
        
        let message: String
    
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
    
            self.line = try container.decode(Int.self, forKey: .line)
            self.column = try container.decode(Int.self, forKey: .column)
    
            if let formatted = try container.decodeIfPresent(String.self, forKey: .formattedMessage), !formatted.isEmpty {
                self.message = formatted
            } else if let message = try container.decodeIfPresent(String.self, forKey: .message), !message.isEmpty {
                self.message = message
            } else {
                throw DecodingError.keyNotFound(CodingKeys.message, DecodingError.Context(codingPath: container.codingPath, debugDescription: "A message is required."))
            }
        }
        
        private enum CodingKeys : String, CodingKey {
            case line
            case column
            case message
            case formattedMessage = "formatted"
        }
    }
}
