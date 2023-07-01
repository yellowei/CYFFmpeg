#
#  Be sure to run `pod spec lint CYFFmpeg.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "CYFFmpeg"
  s.version      = "0.3.3"
  s.summary      = "CYFFmpeg, a framework for ffmpeg, include x264, fdk-aac, smbclient, and cmdutils for ffmpeg."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
                    CYFFmpeg
                    a framework for ffmpeg,
                    include x264, fdk-aac, smbclient, and cmdutils for ffmpeg.
                   DESC

  s.homepage     = "https://github.com/yellowei/CYFFmpeg"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  # s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.author             = { "yellowei" => "me@yellowei.com" }
  # Or just: s.author    = "yellowei"
  # s.authors            = { "yellowei" => "me@yellowei.com" }
  # s.social_media_url   = "http://twitter.com/yellowei"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # s.platform     = :ios
  s.platform     = :ios, "8.0"

  #  When using multiple platforms
  # s.ios.deployment_target = "5.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/yellowei/CYFFmpeg.git", :tag => "#{s.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = "CYFFmpeg.framework/Headers/*.{h}"
  # s.exclude_files = "Classes/Exclude"

  s.vendored_frameworks = 'CYFFmpeg.framework'

  s.public_header_files = "CYFFmpeg.framework/Headers/CYFFmpeg.h"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # s.framework  = "SomeFramework"
  s.frameworks = "VideoToolbox", "AudioToolbox", "OpenAL", "Foundation", "OpenGLES", "QuartzCore", "CoreAudio", "CoreGraphics", "CoreMedia", "AVFoundation", "CoreVideo"

  # s.library   = "iconv"
  s.libraries = "iconv", "resolv", "bz2", "z"

  # s.user_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '"$(inherited)" "${PODS_ROOT}/ProductFramework/CYFFmpeg.framework/Headers"' }
  # s.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '"$(inherited)" "${PODS_ROOT}/ProductFramework/CYFFmpeg.framework/Headers"' }

  #设置cfiles及子目录结构保持不变
  # s.header_mappings_dir = "CYFFmpeg.framework/Headers/**"

  #将这些文件设置为private_file或public_file
  # s.private_header_files = "CYFFmpeg.framework/Headers/**/*.h"

  

  #因为我的C头文件有嵌套，需要查找子目录，所以需要将non-recursive改为recursive ${PODS_ROOT}/Headers/Private/**
  #-undefined dynamic_lookup 这个表明了当主工程和framework都包含同一个库时，会优先使用主工程的库。
  s.pod_target_xcconfig = {
  	  'VALID_ARCHS' => 'arm64 armv7 x86_64',
      'FRAMEWORK_SEARCH_PATHS'	=> '$(inherited) "${PODS_ROOT}/CYFFmpeg/**" ',
      'HEADER_SEARCH_PATHS'    	=> '$(inherited) "${PODS_ROOT}/CYFFmpeg/CYFFmpeg.framework/Headers/**" ',
      'OTHER_LDFLAGS'           => '$(inherited) -ObjC',
      'ENABLE_BITCODE'          => 'YES'
  }

  # s.user_target_xcconfig = { 
  #   'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  # }


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # s.requires_arc = true

  #往主工程里添加必要的路径
  s.xcconfig = {"HEADER_SEARCH_PATHS" => '${PODS_ROOT}/CYFFmpeg/CYFFmpeg.framework/Headers/**'}
  # s.dependency "JSONKit", "~> 1.4"

end
