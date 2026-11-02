import Foundation
import CoreFoundation

public class EncodingDetector {
    /// 尝试检测给定文件的文本编码并读取为字符串
    public static func detectAndRead(from fileURL: URL) throws -> (content: String, encodingName: String) {
        let data = try Data(contentsOf: fileURL)
        return try detectAndRead(from: data)
    }

    /// 尝试检测给定二进制数据的编码并解码
    public static func detectAndRead(from data: Data) throws -> (content: String, encodingName: String) {
        // 1. 检查常见 BOM
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            if let str = String(data: data.subdata(in: 3..<data.count), encoding: .utf8) {
                return (str, "UTF-8 (BOM)")
            }
        }
        if data.starts(with: [0xFF, 0xFE]) {
            if let str = String(data: data.subdata(in: 2..<data.count), encoding: .utf16LittleEndian) {
                return (str, "UTF-16LE")
            }
        }
        if data.starts(with: [0xFE, 0xFF]) {
            if let str = String(data: data.subdata(in: 2..<data.count), encoding: .utf16BigEndian) {
                return (str, "UTF-16BE")
            }
        }

        // 2. 尝试无 BOM 的 UTF-8（严格校验）
        if let utf8Str = String(data: data, encoding: .utf8) {
            return (utf8Str, "UTF-8")
        }

        // 3. 尝试 GB18030 / GBK / GB2312（涵盖绝大多数国内 Windows txt 小说）
        let gbkEnc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        if let gbkStr = String(data: data, encoding: String.Encoding(rawValue: gbkEnc)) {
            return (gbkStr, "GB18030 / GBK")
        }

        // 4. 尝试繁体 Big5
        let big5Enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.big5.rawValue))
        if let big5Str = String(data: data, encoding: String.Encoding(rawValue: big5Enc)) {
            return (big5Str, "Big5")
        }

        // 5. 尝试 UTF-16
        if let utf16Str = String(data: data, encoding: .utf16) {
            return (utf16Str, "UTF-16")
        }

        // 6. 兜底策略：使用有损 UTF-8
        let lossyStr = String(decoding: data, as: UTF8.self)
        return (lossyStr, "UTF-8 (Lossy)")
    }
}
