Pod::Spec.new do |s|
  s.name     = 'AFNetworkActivityLogger'
  s.version  = '2.0.4'
  s.license  = 'MIT'
  s.summary  = 'AFNetworking 2.0 Extension for Network Request Logging'
  s.homepage = 'https://github.com/AFNetworking/AFNetworkActivityLogger'
  s.authors  = { 'Mattt Thompson' => 'm@mattt.me' }
  s.source   = { :git => 'https://github.com/AFNetworking/AFNetworkActivityLogger.git', :tag => s.version }
  s.source_files = 'AFNetworkActivityLogger'
  s.requires_arc = true
  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
  s.watchos.deployment_target = '2.0'

  s.subspec 'NSURLConnection' do |ss|
    ss.ios.deployment_target = '6.0'
    ss.osx.deployment_target = '10.8'

    ss.dependency 'AFNetworking/NSURLConnection', '~> 2.0'
  end

  s.subspec 'NSURLSession' do |ss|
    ss.ios.deployment_target = '6.0'
    ss.osx.deployment_target = '10.8'
    ss.watchos.deployment_target = '2.0'

    ss.dependency 'AFNetworking/NSURLSession', '~> 2.0'
  end
  
end
