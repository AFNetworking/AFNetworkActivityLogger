Pod::Spec.new do |s|
  s.name     = 'AFNetworkActivityLogger'
  s.version  = '4.0.0'
  s.license  = 'MIT'
  s.summary  = 'AFNetworking 4.0 Extension for Network Request Logging'
  s.homepage = 'https://github.com/AFNetworking/AFNetworkActivityLogger'
  s.authors  = { 'Mattt Thompson' => 'm@mattt.me' }
  s.source   = { :git => 'https://github.com/AFNetworking/AFNetworkActivityLogger.git', :tag => s.version }
  s.source_files = 'AFNetworkActivityLogger'
  s.requires_arc = true
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

  s.dependency 'AFNetworking/NSURLSession', '~> 4.0'
end
