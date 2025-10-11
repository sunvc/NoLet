import UniformTypeIdentifiers
import UIKit
import os

public class Clipboard {

    class func set(_ message: String? = nil, _ items:[String : Any]...) {
        var result:[[String:Any]] = []
        
        if let message { result.append([UTType.utf8PlainText.identifier: message]) }
        
        UIPasteboard.general.items = result + items
    }
    
    class func getText() -> String? {
        UIPasteboard.general.string
    }
    
    class func getNSAttributedString() -> NSAttributedString {
        let result = NSMutableAttributedString()

        for item in UIPasteboard.general.items {
            for (type, value) in item {
                if type == "public.rtf", let data = value as? Data {
                    if let attrStr = try? NSAttributedString(data: data, options: [
                        .documentType: NSAttributedString.DocumentType.rtf
                    ], documentAttributes: nil) {
                        result.append(attrStr)
                    }
                } else if type == "public.html", let htmlString = value as? String {
                    if let data = htmlString.data(using: .utf8),
                       let attrStr = try? NSAttributedString(data: data, options: [
                           .documentType: NSAttributedString.DocumentType.html,
                           .characterEncoding: String.Encoding.utf8.rawValue
                       ], documentAttributes: nil) {
                        result.append(attrStr)
                    }
                } else if type.hasPrefix("public.image"), let image = value as? UIImage {
                    let attachment = NSTextAttachment()
                    attachment.image = image
                    let imageAttrStr = NSAttributedString(attachment: attachment)
                    result.append(imageAttrStr)
                } else if type == "public.utf8-plain-text", let text = value as? String {
                    let textAttrStr = NSAttributedString(string: text)
                    result.append(textAttrStr)
                }
            }
        }

        return result
    }

}

public enum Haptic {
    
    private static var lastImpactTime: Date?
    private static var minInterval: TimeInterval = 0.1 // 最小震动间隔

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
                       limitFrequency: Bool = false) {
        guard canTrigger(limitFrequency: limitFrequency) else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType,
                       limitFrequency: Bool = false) {
        guard canTrigger(limitFrequency: limitFrequency) else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    static func selection(limitFrequency: Bool = false) {
        guard canTrigger(limitFrequency: limitFrequency) else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    private static func canTrigger(limitFrequency: Bool) -> Bool {
        guard limitFrequency else { return true }
        let now = Date()
        if let last = lastImpactTime, now.timeIntervalSince(last) < minInterval {
            return false
        }
        lastImpactTime = now
        return true
    }
}

//var Log = os.Logger()
public enum NLog {
    
    /// 日志级别
    enum Level: String {
        case LOG
        case ERROR
    }
    
    /// 基础日志方法
    /// - Parameters:
    ///   - level: 日志级别
    ///   - message: 日志消息
    ///   - file: 调用日志的文件名（自动捕获）
    ///   - function: 调用日志的函数名（自动捕获）
    ///   - line: 调用日志的行号（自动捕获）
    static func base(level: Level,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line,
                     _ message: Any?... ) {
        
#if DEBUG
        Task.detached( priority: .background){
            let currentDate = Date()
            if level == .ERROR{
                print("\n")
                print(Array(repeating: "‼️", count: 50).joined())
                print("[‼️\(level.rawValue)] - \(currentDate.formatString())" )
            }else{
                print( "\n[☘️\(level.rawValue)] - \(currentDate.formatString())" )
            }
            
            print("🏳️‍🌈: \((file as NSString).lastPathComponent)\(" - \(line) ") 🎖️: \(function) -> ")
           
            for item in message{
                if String("\(item ?? "")"
                    .trimmingCharacters(in:
                            .whitespacesAndNewlines)).count > 0{
                    print("- ",item ?? "")
                }
            }
            
            if level == .ERROR{
                print(Array(repeating: "‼️", count: 50).joined())
            }
        }
        
        
#endif
        
    }
    
    /// 打印调试日志
    static func log(file: String = #file,
                    function: String = #function,
                    line: Int = #line,
                    _ message: Any?...) {
        base(level: .LOG, file: file, function: function, line: line, message)
    }
    
    /// 打印错误日志
    static func error(file: String = #file,
                      function: String = #function,
                      line: Int = #line,
                      _ message: Any?...) {
        base(level: .ERROR, file: file, function: function, line: line, message)
    }
}
