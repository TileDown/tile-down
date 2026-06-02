import Foundation
import TileCore

extension TileKit.Site.ConfigurationFile {
    struct ServiceBindingBuilder: Equatable {
        var contractPath: String?
        var mode: String?
        var proxyRoute: String?
        var availability: String?
    }

    static func applyServiceBinding(
        _ item: (key: String, value: String),
        to serviceBindings: inout [String: ServiceBindingBuilder],
    ) throws -> Bool {
        guard item.key.hasPrefix("service.") else {
            return false
        }
        let parsedKey = try serviceBindingKey(item.key)
        var binding = serviceBindings[parsedKey.serviceID] ?? .init()
        switch parsedKey.field {
        case "contract":
            binding.contractPath = item.value
        case "mode":
            binding.mode = try serviceBindingMode(item.value, serviceID: parsedKey.serviceID)
        case "proxyRoute":
            binding.proxyRoute = item.value.isEmpty ? nil : item.value
        case "availability":
            binding.availability = try serviceBindingAvailability(
                item.value,
                serviceID: parsedKey.serviceID,
            )
        default:
            throw TileKit.Site.ConfigurationFileError.unknownKey(item.key)
        }
        serviceBindings[parsedKey.serviceID] = binding
        return true
    }

    static func resolvedServiceBindings(
        from builders: [String: ServiceBindingBuilder],
    ) throws -> [TileKit.Site.ServiceBindingConfiguration] {
        try builders.keys.sorted().map { serviceID in
            let builder = builders[serviceID] ?? .init()
            guard let contractPath = nonEmpty(builder.contractPath) else {
                throw TileKit.Site.ConfigurationFileError.missingServiceBindingField(
                    serviceID: serviceID,
                    field: "contract",
                )
            }
            guard let mode = nonEmpty(builder.mode) else {
                throw TileKit.Site.ConfigurationFileError.missingServiceBindingField(
                    serviceID: serviceID,
                    field: "mode",
                )
            }
            return .init(
                serviceID: serviceID,
                contractPath: contractPath,
                mode: mode,
                proxyRoute: nonEmpty(builder.proxyRoute),
                availability: nonEmpty(builder.availability) ?? "required",
            )
        }
    }

    private static func serviceBindingKey(
        _ key: String,
    ) throws -> (serviceID: String, field: String) {
        let suffix = String(key.dropFirst("service.".count))
        let parts = suffix.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 2,
              parts.allSatisfy({ !$0.isEmpty })
        else {
            throw TileKit.Site.ConfigurationFileError.invalidServiceBindingKey(key)
        }
        return (String(parts[0]), String(parts[1]))
    }

    private static func serviceBindingMode(
        _ value: String,
        serviceID: String,
    ) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard ["static", "local", "remote", "proxy", "build"].contains(trimmed) else {
            throw TileKit.Site.ConfigurationFileError.invalidServiceBindingMode(
                serviceID: serviceID,
                mode: value,
            )
        }
        return trimmed
    }

    private static func serviceBindingAvailability(
        _ value: String,
        serviceID: String,
    ) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard ["required", "optional", "unchecked"].contains(trimmed) else {
            throw TileKit.Site.ConfigurationFileError.invalidServiceBindingAvailability(
                serviceID: serviceID,
                availability: value,
            )
        }
        return trimmed
    }

    private static func nonEmpty(
        _ value: String?,
    ) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else {
            return nil
        }
        return trimmed
    }
}
