Pod::Spec.new do |s|
  s.name = "OpenIM"

  s.version = '0.0.1'

  s.source = {
    :git => "https://github.com/mxcl/#{s.name}.git",
    :tag => s.version,
    :submodules => true
  }

  s.license = 'MIT'
  s.summary = 'Promises for Swift & ObjC.'
  s.homepage = 'http://mxcl.dev/PromiseKit/'
  s.description = 'A thoughtful and complete implementation of promises for iOS, macOS, watchOS and tvOS with first-class support for both Objective-C and Swift.'
  s.social_media_url = 'https://twitter.com/mxcl'
  s.authors  = { 'Max Howell' => 'mxcl@me.com' }
  s.documentation_url = 'http://mxcl.dev/PromiseKit/reference/v6/Classes/Promise.html'
  s.requires_arc = true
  
  s.swift_versions = ['3.1', '3.2', '3.3', '3.4', '4.0', '4.1', '4.2', '4.3', '4.4', '5.0', '5.1']

  # CocoaPods requires us to specify the root deployment targets
  # even though for us it is nonsense. Our root spec has no
  # sources.
  
  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.9'
  s.watchos.deployment_target = '3.0'
  s.tvos.deployment_target = '10.0'

  s.ios.source_files = s.osx.source_files = [
    'OpenIM/Source/*.{h,m,swift}',
    'OpenIM/Source/*/*.{h,m,swift}',
    'OpenIM/Source/*/*/*.{h,m,swift}',
  ]

  s.dependency 'RxSwift', '>= 6.0.0'
  s.dependency 'Alamofire', '>= 5.2'
  s.dependency 'Starscream', '>= 4.0'
  s.dependency 'GRDB.swift', '>= 5.7.3'
  
end
