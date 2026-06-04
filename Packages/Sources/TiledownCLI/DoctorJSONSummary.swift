struct DoctorJSONSummary: Codable, Equatable {
    var errors: Int
    var warnings: Int
    var pages: Int
    var publishedPosts: Int
    var draftPosts: Int
}
