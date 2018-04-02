# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'cryptoterminal' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
      pod 'CSVImporter', '~> 1.7'
      pod 'CorePlot', '~> 2.2'
      pod 'SwiftDate', '~> 4.4.0’
      pod 'GRDB.swift’
      pod 'SigmaSwiftStatistics', '~> 6.0'
  end
    # Pods for cryptoterminal

  target 'cryptoterminalTests' do
    inherit! :search_paths
    use_frameworks!
      	pod 'CSVImporter', '~> 1.7'
      	pod 'CorePlot', '~> 2.2'
      	pod 'SwiftDate', '~> 4.4.0’
      	pod 'GRDB.swift’
      	pod 'SigmaSwiftStatistics', '~> 6.0'
    # Pods for testing
  end

  target 'cryptoterminalUITests' do
    inherit! :search_paths
    # Pods for testing
  end

  post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = ‘4.0’
        end
    end
end
