require "fileutils"

system "defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES"
system "defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES"

macros = File.expand_path("ci_scripts/macros.json", __dir__)
dest = File.expand_path("Library/org.swift.swiftpm/security", Dir.home)
FileUtils.mkdir_p(dest)
FileUtils.cp(macros, File.join(dest, "macros.json")) if File.file?(macros)

install! "cocoapods", :integrate_targets => false
workspace "ForkFuel"
platform :ios, "17.0"
target "ForkFuel" do
end
