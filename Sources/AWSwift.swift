import Foundation
import CryptoSwift

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum AWSRegion: String {
    case euWest1 = "eu-west-1"
}

enum AWSService: String {
    case dynamoDB = "dynamoDB"
}

protocol Aws4Signer {
    func createCanonicalRequestHash(method: HTTPMethod, uri: String?, query: String?, headers: [String: String], signedHeaders: [String], body: String?) -> String
    func createSigningString(requestDate: Date, region: AWSRegion, service: AWSService, canonicalRequestHash: String) -> String
    func createSigningKey(awsAccessSecret: String, requestDate: Date, region: AWSRegion, service: AWSService) -> Array<UInt8>
    func createSignature(signingKey: Array<UInt8>, signingString: String) -> String
    func createCredentialsHeader(awsAccessId: String, requestDate: Date, region: AWSRegion, service: AWSService) -> String
    func createAuthorizationHeader(credentialsHeader: String, signedHeaders: [String], signature: String) -> String
}

struct HeaderSignerGenerator: Aws4Signer {
    func createCanonicalRequestHash(method: HTTPMethod, uri: String?, query: String?, headers: [String : String], signedHeaders: [String], body: String?) -> String{
        
        // HTTP Method
        var canonicalRequest = "\(method.rawValue)\n"
        
        // URI
        if let uri = uri {
            canonicalRequest += uri
        }
        else {
            canonicalRequest += "/"
        }
        
        canonicalRequest += "\n"
        
        // Query
        if let query = query {
            canonicalRequest += query
        }
        
        canonicalRequest += "\n"
        
        // Headers
        // Header keys must be in alphabetical order and lowercase and trimmed
        
        // TODO need to trum
        let sortedKeys = Array(headers.keys).sorted()
        
        for key in sortedKeys {
            canonicalRequest += "\(key.lowercased()):\(headers[key]!)\n"
        }
        canonicalRequest += "\n"
        
        // Signed Headers
        canonicalRequest += getSignedHeadersString(signedHeaders)
        canonicalRequest += "\n"
        
        // Payload Hash
        var bodyPayload = ""
        
        if let body = body {
            bodyPayload = body
        }
        
        canonicalRequest += bodyPayload.sha256()
        
        // Return SHA256
        
        return canonicalRequest.sha256()
    }
    
    func createSigningString(requestDate: Date, region: AWSRegion, service: AWSService, canonicalRequestHash: String) -> String {
        
        let formatter = DateFormatter()
        let dateOnlyFormatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateOnlyFormatter.dateFormat = "yyyyMMdd"
        
        // Algorithm
        var signingString = "AWS4-HMAC-SHA256\n"
        
        // Request Date
        // TODO convert to UTC
        signingString += "\(formatter.string(from: requestDate))\n"
        
        // Credentials Scope
        signingString += "\(dateOnlyFormatter.string(from: requestDate))/\(region.rawValue)/\(service.rawValue)/aws4_request\n"
        
        // Hashed Canonical Request
        signingString += "\(canonicalRequestHash)\n"
        
        return signingString
    }
    
    func createSigningKey(awsAccessSecret: String, requestDate: Date, region: AWSRegion, service: AWSService) -> Array<UInt8> {
        
        // TODO sort out unwraps
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"

        let kDate = try? HMAC(key: "AWS4\(awsAccessSecret)", variant: .sha256).authenticate([UInt8](formatter.string(from: requestDate).utf8))
        let kRegion = try? HMAC(key: kDate!, variant: .sha256).authenticate([UInt8](region.rawValue.utf8))
        let kService = try? HMAC(key: kRegion!, variant: .sha256).authenticate([UInt8](service.rawValue.utf8))
        let kSigning = try? HMAC(key: kService!, variant: .sha256).authenticate([UInt8]("aws4_request".utf8))
        return kSigning!
    }
    
    func createSignature(signingKey: Array<UInt8>, signingString: String) -> String {
        let signatureBytes = try? HMAC(key: signingKey, variant: .sha256).authenticate([UInt8](signingString.utf8))
        
        let hexString = NSMutableString()
        for byte in signatureBytes! {
            hexString.appendFormat("%02x", UInt(byte))
        }
        
        let signature = String(hexString)
        return signature
    }
    
    func createCredentialsHeader(awsAccessId: String, requestDate: Date, region: AWSRegion, service: AWSService) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let credentialsHeader = "\(awsAccessId)/\(formatter.string(from: requestDate))/\(region.rawValue)/\(service.rawValue)/aws4_request"
        return credentialsHeader
    }
    
    func createAuthorizationHeader(credentialsHeader: String, signedHeaders: [String], signature: String) -> String {
        let signedHeaderString = getSignedHeadersString(signedHeaders)
        let authHeader = "AWS4-HMAC-SHA256 Credential=\(credentialsHeader), SignedHeaders=\(signedHeaderString), Signature=\(signature)"
        return authHeader
    }
    
    func getSignedHeadersString(_ signedHeaders: [String]) -> String {
        // TODO do this properly - check we have the ones we need etc
        var signedHeadersString = ""
        let sortedSignedHeaderKeys = signedHeaders.sorted()
        for key in sortedSignedHeaderKeys {
            signedHeadersString += "\(key);"
        }
        return signedHeadersString
    }
}

