Pod::Spec.new do |s|
  s.name = "OpenIMUI"

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
  # s.default_subspecs = 'UIKit', 'Foundation'
  s.requires_arc = true
  
  s.swift_versions = ['3.1', '3.2', '3.3', '3.4', '4.0', '4.1', '4.2', '4.3', '4.4', '5.0', '5.1']

  # CocoaPods requires us to specify the root deployment targets
  # even though for us it is nonsense. Our root spec has no
  # sources.
  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.10'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'
  
#   s.pod_target_xcconfig = {
#     'OTHER_SWIFT_FLAGS' => '-DPMKCocoaPods',
#   }

  s.ios.source_files = s.osx.source_files = [
    'OpenIMUI/*/*.{h,m,swift}',
    'OpenIMUI/*/*/*.{h,m,swift}',
  ]
  
  s.ios.resource_bundles = {
    'OpenIMUI' => [
      'OpenIMUI/*.xcassets',
      'OpenIMUI/*.lproj',
    ],
  }
  
  # s.ios.frameworks = s.watchos.frameworks = 'WatchConnectivity'
  s.dependency 'Kingfisher', '>= 6.0'
  s.dependency 'OpenIM', '>= 0.0.1'
  s.ios.deployment_target = '11.0'
end
