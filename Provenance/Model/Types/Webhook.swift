import Foundation

struct WebhooksResponse: Codable, Hashable {
    var data: [WebhookResource]
    var links: Links
    
    struct WebhookResource: Codable, Hashable, Identifiable {
        var type: String
        var id: String
        var attributes: Attributes
        var relationships: Relationships
        var links: Links?
        
        struct Attributes: Codable, Hashable {
            var url: String
            var description: String?
            var secretKey: String?
            
            private var createdAt: String
            private var creationDateAbsolute: String {
                return formatDate(dateString: createdAt)
            }
            private var creationDateRelative: String {
                return formatDateRelative(dateString: createdAt)
            }
            var creationDate: String {
                switch appDefaults.string(forKey: "dateStyle") {
                    case "Absolute", .none: return creationDateAbsolute
                    case "Relative": return creationDateRelative
                    default: return creationDateAbsolute
                }
            }
        }
        
        struct Relationships: Codable, Hashable {
            var logs: Logs
            
            struct Logs: Codable, Hashable {
                var links: Links?
                
                struct Links: Codable, Hashable {
                    var related: String
                }
            }
        }
        
        struct Links: Codable, Hashable {
            var `self`: String
        }
    }
    
    struct Links: Codable, Hashable {
        var prev: String?
        var next: String?
    }
}
