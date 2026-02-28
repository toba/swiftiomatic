---
# sv4-2xr
title: Remove child/nested config merging support
status: completed
type: task
priority: normal
created_at: 2026-02-28T22:30:09Z
updated_at: 2026-02-28T22:33:26Z
---

- [x] Delete Configuration+Merging.swift
- [x] Simplify FileGraph.resultingConfiguration to not merge multiple configs
- [x] Remove loadedConfigFiles/includesFile from FileGraph
- [x] Remove basedOnCustomConfigurationFiles from Configuration
- [x] Remove nested config cache from Configuration+Cache.swift
- [x] Clean up Configuration Hashable/Equatable
- [x] Build to verify (delegated to other agent)


## Summary of Changes

Removed all child/nested configuration merging support:
- Deleted Configuration+Merging.swift (merged(), configuration(for:), directory walking)
- Simplified FileGraph to just hold rootDirectory (removed loadedConfigFiles, includesFile)
- Simplified resultingConfiguration to use last config file instead of merging
- Removed parentConfiguration from Configuration+Parsing init and validation methods
- Removed basedOnCustomConfigurationFiles property
- Removed nested config cache (nestedConfigIsSelfByIdentifier) from Configuration+Cache
- Removed parent-related Issue cases (ruleDisabledInParentConfiguration, ruleNotEnabledInParentOnlyRules)
- Cleaned up Hashable/Equatable
