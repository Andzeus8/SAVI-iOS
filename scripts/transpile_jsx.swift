import Foundation
import JavaScriptCore

let jsxURL = URL(fileURLWithPath: CommandLine.arguments[1])
let babelURL = URL(fileURLWithPath: CommandLine.arguments[2])

let jsx = try String(contentsOf: jsxURL, encoding: .utf8)
let babel = try String(contentsOf: babelURL, encoding: .utf8)

let context = JSContext()!
context.exceptionHandler = { _, exception in
    fputs("JS exception: \(exception?.toString() ?? "unknown")\n", stderr)
}

context.evaluateScript(
    "var window=this; var self=this; var global=this; var process={env:{}}; " +
    "var setTimeout=function(fn){return 0;}; var clearTimeout=function(){}; " +
    "var setInterval=function(fn){return 0;}; var clearInterval=function(){};"
)
context.evaluateScript(babel)

guard let transform = context.objectForKeyedSubscript("Babel")?.objectForKeyedSubscript("transform") else {
    fatalError("Babel.transform unavailable")
}

let result = transform.call(withArguments: [jsx, ["presets": ["env", "react"]]])
let code = result?.forProperty("code")?.toString() ?? ""
print(code)
