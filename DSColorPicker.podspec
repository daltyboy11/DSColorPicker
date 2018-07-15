Pod::Spec.new do |s|

  s.name         = "DSColorPicker"
  s.version      = "1.0.1"
  s.summary      = "DSColorPicker is a lightweight view that acts as a color picking utility. There are two available styles: grid and circle."
  s.homepage     = "https://github.com/daltyboy11/DSColorPicker"
  s.license      = "MIT"
  s.author             = { "Dalton Sweeney" => "daltyboy11@gmail.com" }
  s.social_media_url   = "http://twitter.com/daltyboy11"
  s.platform     = :ios
	s.ios.deployment_target = '9.0'
  s.source = { :git => "https://github.com/daltyboy11/DSColorPicker.git", :tag => "1.0.1" } 
  s.source_files  = "DSColorPicker/*.swift", "DSColorPicker/Protocols/*.swift", "DSColorPicker/Pickers/*.swift"
	s.swift_version = "4.2"

end
