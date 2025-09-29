# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'TrackMyCafe Beta' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for TrackMyCafe Beta
	pod 'AnimatedTextInput'
	pod 'R.swift'

end

target 'TrackMyCafe Dev' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for TrackMyCafe Dev
	pod 'AnimatedTextInput'
	pod 'R.swift'

end

target 'TrackMyCafe Prod' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for TrackMyCafe Prod
	pod 'AnimatedTextInput'
	pod 'R.swift'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['CLANG_ENABLE_OBJC_ARC'] = 'YES'
      config.build_settings['CLANG_ENABLE_OBJC_WEAK'] = 'YES'
    end
  end
end
