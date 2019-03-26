
Pod::Spec.new do |s|
  s.name         = "react-native-video-trimmer"
  s.homepage	 = "http://facebook.github.io/react-native/"
  s.version      = "1.0.0-dev10"
  s.summary      = "react-native-video-trimmer"
  s.license      = "MIT"
  s.ios.deployment_target  = '9.0'
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://git.nixplay.ninja/mobile/react-native-video-trimmer.git", :tag => "master" }
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
  #s.dependency "others"

end


