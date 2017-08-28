//
//  Http.swift
//  Patchr
//
//  Created by Jay Massena on 11/23/16.
//  Copyright © 2016 3meters. All rights reserved.
//
import Foundation

/**
 HTTP status codes as per http://en.wikipedia.org/wiki/List_of_HTTP_status_codes
 The RF2616 standard is completely covered (http://www.ietf.org/rfc/rfc2616.txt)
 */

enum HTTPStatusCode: Int {
    // Informational
    case Continue                      = 100
    case SwitchingProtocols            = 101
    case Processing                    = 102
    
    // Success
    case OK                            = 200
    case Created                       = 201
    case Accepted                      = 202
    case NonAuthoritativeInformation   = 203
    case NoContent                     = 204
    case ResetContent                  = 205
    case PartialContent                = 206
    case MultiStatus                   = 207
    case AlreadyReported               = 208
    case IMUsed                        = 226
    
    // Redirections
    case MultipleChoices               = 300
    case MovedPermanently              = 301
    case Found                         = 302
    case SeeOther                      = 303
    case NotModified                   = 304
    case UseProxy                      = 305
    case SwitchProxy                   = 306
    case TemporaryRedirect             = 307
    case PermanentRedirect             = 308
    
    // Client Errors
    case BadRequest                    = 400
    case Unauthorized                  = 401
    case PaymentRequired               = 402
    case Forbidden                     = 403
    case NotFound                      = 404
    case MethodNotAllowed              = 405
    case NotAcceptable                 = 406
    case ProxyAuthenticationRequired   = 407
    case RequestTimeout                = 408
    case Conflict                      = 409
    case Gone                          = 410
    case LengthRequired                = 411
    case PreconditionFailed            = 412
    case RequestEntityTooLarge         = 413
    case RequestURITooLong             = 414
    case UnsupportedMediaType          = 415
    case RequestedRangeNotSatisfiable  = 416
    case ExpectationFailed             = 417
    case ImATeapot                     = 418
    case AuthenticationTimeout         = 419
    case UnprocessableEntity           = 422
    case Locked                        = 423
    case FailedDependency              = 424
    case UpgradeRequired               = 426
    case PreconditionRequired          = 428
    case TooManyRequests               = 429
    case RequestHeaderFieldsTooLarge   = 431
    case LoginTimeout                  = 440
    case NoResponse                    = 444
    case RetryWith                     = 449
    case UnavailableForLegalReasons    = 451
    case RequestHeaderTooLarge         = 494
    case CertError                     = 495
    case NoCert                        = 496
    case HTTPToHTTPS                   = 497
    case TokenExpired                  = 498
    case ClientClosedRequest           = 499
    
    // Server Errors
    case InternalServerError           = 500
    case NotImplemented                = 501
    case BadGateway                    = 502
    case ServiceUnavailable            = 503
    case GatewayTimeout                = 504
    case HTTPVersionNotSupported       = 505
    case VariantAlsoNegotiates         = 506
    case InsufficientStorage           = 507
    case LoopDetected                  = 508
    case BandwidthLimitExceeded        = 509
    case NotExtended                   = 510
    case NetworkAuthenticationRequired = 511
    case NetworkTimeoutError           = 599
}

extension HTTPStatusCode {
    /// Informational - Request received, continuing process.
    var isInformational: Bool {
        return inRange(range: Range(uncheckedBounds: (lower: 100, upper: 199)))
    }
    /// Success - The action was successfully received, understood, and accepted.
    var isSuccess: Bool {
        return inRange(range: Range(uncheckedBounds: (lower: 200, upper: 299)))
    }
    /// Redirection - Further action must be taken in order to complete the request.
    var isRedirection: Bool {
        return inRange(range: Range(uncheckedBounds: (lower: 300, upper: 399)))
    }
    /// Client Error - The request contains bad syntax or cannot be fulfilled.
    var isClientError: Bool {
        return inRange(range: Range(uncheckedBounds: (lower: 400, upper: 499)))
    }
    /// Server Error - The server failed to fulfill an apparently valid request.
    var isServerError: Bool {
        return inRange(range: Range(uncheckedBounds: (lower: 500, upper: 599)))
    }
    
    /// :returns: true if the status code is in the provided range, false otherwise.
    private func inRange(range: Range<Int>) -> Bool {
        return range.contains(rawValue)
    }
}

extension HTTPStatusCode {
    var localizedReasonPhrase: String {
        return HTTPURLResponse.localizedString(forStatusCode: rawValue)
    }
}

// MARK: - Printing

extension HTTPStatusCode: CustomDebugStringConvertible, CustomStringConvertible {
    var description: String {
        return "\(rawValue) - \(localizedReasonPhrase)"
    }
    var debugDescription: String {
        return "HTTPStatusCode:\(description)"
    }
}

// MARK: - HTTP URL Response

extension HTTPStatusCode {
    /// Obtains a possible status code from an optional HTTP URL response.
    init?(HTTPResponse: HTTPURLResponse?) {
        if let value = HTTPResponse?.statusCode {
            self.init(rawValue: value)
        }
        else {
            return nil
        }
    }
}

extension HTTPURLResponse {
    var statusCodeValue: HTTPStatusCode? {
        return HTTPStatusCode(HTTPResponse: self)
    }
}

