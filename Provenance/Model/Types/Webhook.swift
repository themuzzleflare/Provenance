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
            var createdDate: String {
                return formatDate(dateString: createdAt)
            }
            var createdDateRelative: String {
                return formatDateRelative(dateString: createdAt)
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
