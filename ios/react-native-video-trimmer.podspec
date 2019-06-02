
Pod::Spec.new do |s|
  s.name         = "react-native-video-trimmer"
  s.homepage	 = "http://facebook.github.io/react-native/"
  s.version      = "1.0.0"
  s.summary      = "react-native-video-trimmer"
  s.license      = "MIT"
  s.ios.deployment_target  = '9.0'
  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "fishkingsin@gmail.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/fishkingsin/react-native-video-trimmer/releases", :tag => "master" }
  s.source_files  = "*.{h,m}"
  s.resources = "RNVideoTrimmer/*.xib"
  s.resource_bundles = {
	'RNVideoTrimmer' => [
		'*.xib'
	]
  }
  s.requires_arc = true


  s.dependency "React"
  s.dependency "ICGVideoTrimmer"
  s.dependency "SDAVAssetExportSession"
  #s.dependency "others"

end


