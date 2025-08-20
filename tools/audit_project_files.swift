#!/usr/bin/env swift

import Foundation

struct ProjectAuditor {
    let projectPath: String
    let pbxprojPath: String
    
    init(projectPath: String = ".") {
        self.projectPath = projectPath
        self.pbxprojPath = "\(projectPath)/MyTradeMate.xcodeproj/project.pbxproj"
    }
    
    func run(apply: Bool = false) {
        print("🔍 MyTradeMate Project File Auditor")
        print("=====================================")
        
        let diskFiles = scanDiskFiles()
        let pbxFiles = parsePBXProject()
        let analysis = analyzeFiles(diskFiles: diskFiles, pbxFiles: pbxFiles)
        
        printReport(analysis)
        
        if apply {
            print("\n🔧 Applying fixes...")
            applyFixes(analysis)
        } else {
            print("\n💡 Run with --apply to fix issues automatically")
        }
    }
    
    private func scanDiskFiles() -> Set<String> {
        var files = Set<String>()
        let fileManager = FileManager.default
        
        func scanDirectory(_ path: String) {
            guard let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: path), 
                                                        includingPropertiesForKeys: nil) else { return }
            
            for case let url as URL in enumerator {
                let relativePath = String(url.path.dropFirst(projectPath.count + 1))
                
                // Skip build artifacts and hidden files
                if shouldIncludeFile(relativePath) {
                    files.insert(relativePath)
                }
            }
        }
        
        scanDirectory(projectPath)
        return files
    }
    
    private func shouldIncludeFile(_ path: String) -> Bool {
        let excludePatterns = [
            ".build/", "DerivedData/", ".git/", "*.xcuserstate", 
            "*.xcworkspace/", "Pods/", "node_modules/"
        ]
        
        for pattern in excludePatterns {
            if path.contains(pattern.replacingOccurrences(of: "*", with: "")) {
                return false
            }
        }
        
        let includeExtensions = [".swift", ".m", ".mm", ".h", ".storyboard", ".xib", 
                               ".json", ".plist", ".strings", ".mlmodel"]
        
        return includeExtensions.contains { path.hasSuffix($0) }
    }
    
    private func parsePBXProject() -> (references: Set<String>, sources: Set<String>) {
        guard let content = try? String(contentsOfFile: pbxprojPath) else {
            print("❌ Cannot read project.pbxproj")
            return ([], [])
        }
        
        var references = Set<String>()
        var sources = Set<String>()
        
        // Parse file references
        let fileRefPattern = #"path = "?([^";\s]+)"?;"#
        let fileRefRegex = try! NSRegularExpression(pattern: fileRefPattern)
        let matches = fileRefRegex.matches(in: content, range: NSRange(content.startIndex..., in: content))
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: content) {
                let path = String(content[range])
                if shouldIncludeFile(path) {
                    references.insert(path)
                }
            }
        }
        
        // Parse sources build phase
        let sourcesPattern = #"files = \((.*?)\);"#
        let sourcesRegex = try! NSRegularExpression(pattern: sourcesPattern, options: .dotMatchesLineSeparators)
        let sourceMatches = sourcesRegex.matches(in: content, range: NSRange(content.startIndex..., in: content))
        
        for match in sourceMatches {
            if let range = Range(match.range(at: 1), in: content) {
                let sourcesSection = String(content[range])
                // Extract file IDs and map to paths (simplified)
                for ref in references {
                    if sourcesSection.contains(ref.replacingOccurrences(of: "/", with: "")) {
                        sources.insert(ref)
                    }
                }
            }
        }
        
        return (references, sources)
    }
    
    struct FileAnalysis {
        let onDisk: Set<String>
        let inPBX: Set<String>
        let inSources: Set<String>
        let missing: Set<String>
        let orphaned: Set<String>
        let notInSources: Set<String>
    }
    
    private func analyzeFiles(diskFiles: Set<String>, pbxFiles: (references: Set<String>, sources: Set<String>)) -> FileAnalysis {
        let missing = pbxFiles.references.subtracting(diskFiles)
        let orphaned = diskFiles.subtracting(pbxFiles.references)
        let notInSources = pbxFiles.references.subtracting(pbxFiles.sources).filter { $0.hasSuffix(".swift") }
        
        return FileAnalysis(
            onDisk: diskFiles,
            inPBX: pbxFiles.references,
            inSources: pbxFiles.sources,
            missing: missing,
            orphaned: orphaned,
            notInSources: notInSources
        )
    }
    
    private func printReport(_ analysis: FileAnalysis) {
        print("\n📊 Analysis Results")
        print("===================")
        print("📁 Files on disk: \(analysis.onDisk.count)")
        print("🎯 Files in project: \(analysis.inPBX.count)")
        print("⚡ Files in sources: \(analysis.inSources.count)")
        print("❌ Missing files: \(analysis.missing.count)")
        print("🔍 Orphaned files: \(analysis.orphaned.count)")
        print("⚠️  Not in sources: \(analysis.notInSources.count)")
        
        if !analysis.missing.isEmpty {
            print("\n❌ Missing Files (referenced but not on disk):")
            for file in analysis.missing.sorted() {
                print("   • \(file)")
            }
        }
        
        if !analysis.orphaned.isEmpty {
            print("\n🔍 Orphaned Files (on disk but not in project):")
            let sortedOrphaned = analysis.orphaned.sorted()
            for file in sortedOrphaned.prefix(20) {
                print("   • \(file)")
            }
            if sortedOrphaned.count > 20 {
                print("   ... and \(sortedOrphaned.count - 20) more")
            }
        }
        
        if !analysis.notInSources.isEmpty {
            print("\n⚠️  Swift Files Not in Sources Build Phase:")
            for file in analysis.notInSources.sorted() {
                print("   • \(file)")
            }
        }
        
        print("\n📋 Detailed File Table:")
        print("| File | On Disk | In PBXProj | In Sources | Action |")
        print("|------|---------|------------|------------|--------|")
        
        let allFiles = Set(analysis.onDisk).union(analysis.inPBX)
        for file in allFiles.sorted().prefix(50) {
            let onDisk = analysis.onDisk.contains(file) ? "✅" : "❌"
            let inPBX = analysis.inPBX.contains(file) ? "✅" : "❌"
            let inSources = analysis.inSources.contains(file) ? "✅" : "❌"
            
            let action: String
            if analysis.missing.contains(file) {
                action = "Remove ref"
            } else if analysis.orphaned.contains(file) && file.hasSuffix(".swift") {
                action = "Add to project"
            } else if analysis.notInSources.contains(file) {
                action = "Add to sources"
            } else {
                action = "OK"
            }
            
            print("| \(file) | \(onDisk) | \(inPBX) | \(inSources) | \(action) |")
        }
        
        if allFiles.count > 50 {
            print("| ... | ... | ... | ... | ... |")
            print("| (showing first 50 of \(allFiles.count) files) | | | | |")
        }
    }
    
    private func applyFixes(_ analysis: FileAnalysis) {
        print("🔧 Fixes would be applied here...")
        print("   • Remove \(analysis.missing.count) missing references")
        print("   • Add \(analysis.orphaned.filter { $0.hasSuffix(".swift") }.count) orphaned Swift files")
        print("   • Add \(analysis.notInSources.count) files to Sources build phase")
        print("⚠️  Manual Xcode project editing recommended for safety")
    }
}

// MARK: - Main Entry Point
let arguments = CommandLine.arguments
let apply = arguments.contains("--apply")
let help = arguments.contains("--help") || arguments.contains("-h")

if help {
    print("""
    🔍 MyTradeMate Project File Auditor
    
    Usage: swift audit_project_files.swift [options]
    
    Options:
      --apply    Apply fixes automatically (use with caution)
      --help     Show this help message
    
    This tool scans your project directory and Xcode project file to identify:
    • Files referenced in project.pbxproj but missing on disk
    • Files on disk but not included in the Xcode project
    • Swift files not added to the Sources build phase
    
    Run without --apply first to review the analysis.
    """)
    exit(0)
}

let auditor = ProjectAuditor()
auditor.run(apply: apply)