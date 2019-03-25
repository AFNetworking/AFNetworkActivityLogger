Pod::Spec.new do |s|
  s.name     = 'AFNetworkingLogger'
  s.version  = '1.0.0'
  s.license  = 'MIT'
  s.summary  = 'AFNetworking 3.0 Extension for Network Request Logging'
  s.homepage = 'https://github.com/leleliu008/AFNetworkingLogger'
  s.authors  = { 'fpliu' => '792793182@qq.com' }
  s.source   = { :git => 'https://github.com/leleliu008/AFNetworkingLogger.git', :tag => s.version }
  s.source_files = 'AFNetworkingLogger'
  s.requires_arc = true
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

  s.dependency 'AFNetworking/NSURLSession', '~> 3.0'
end
