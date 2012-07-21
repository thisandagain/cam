Pod::Spec.new do |s|
  s.name     = 'DIYCam'
  s.version  = '1.0.0'
  s.license  = 'Apache 2.0'
  s.summary  = 'A delightful iOS and OS X networking framework.'
  s.homepage = 'https://github.com/thisandagain/cam'
  s.authors  = {'Andrew Sliwinski' => 'andrew@diy.org', 'Jon Beilin' => 'jon@diy.org'}
  s.source   = { :git => 'https://github.com/thisandagain/cam.git', :tag => 'v1.0.0' }
  s.source_files = 'DIYCam'

  s.framework = 'UIKit', 'AssetsLibrary', 'AVFoundation', 'CoreGraphics', 'CoreMedia', 'MobileCoreServices', 'QuartzCore'
end