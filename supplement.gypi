{
  'variables': {
    'webrtc_pkg_deps%': 'openssl libevent vpx alsa expat',
  },
  'target_defaults': {
    'configurations': {
      'Debug_Base': {
        'abstract': 1,
        'defines': [
          '_DEBUG',
        ],
        'cflags': [
          '-g',
        ],
      },
      'Release_Base': {
        'abstract': 1,
        'defines': [
          'NDEBUG',
        ],
        'cflags': [
          '-O3',
        ],
      },
      'Debug': {
        'inherit_from': ['Debug_Base'],
      },
      'Release': {
        'inherit_from': ['Release_Base'],
      },
    },
    'sources/': [
      ['exclude', '_win(_browsertest|_unittest|_test)?\\.(h|cc)$'],
      ['exclude', '(^|/)win/'],
      ['exclude', '(^|/)win_[^/]*\\.(h|cc)$'],
      ['exclude', '_(cocoa|mac|mach)(_unittest|_test)?\\.(h|cc|c|mm?)$'],
      ['exclude', '(^|/)(cocoa|mac|mach)/'],
      ['exclude', '_ios(_unittest|_test)?\\.(h|cc|mm?)$'],
      ['exclude', '(^|/)ios/'],
      ['exclude', '\\.mm?$' ],
      ['exclude', '_android(_unittest|_test)?\\.(h|cc)$'],
      ['exclude', '(^|/)android/'],
      ['exclude', '_(x|x11)(_interactive_uitest|_unittest)?\\.(h|cc)$'],
      ['exclude', '(^|/)x11_[^/]*\\.(h|cc)$'],
      ['exclude', '(^|/)x11/'],
      ['exclude', '(^|/)x/'],
    ],
    'defines': [
      'LIBYUV_DISABLE_MIPS',
      'LIBYUV_DISABLE_X86',
      'LIBYUV_DISABLE_NEON',
      '_LARGEFILE_SOURCE',
      '_LARGEFILE64_SOURCE',
      '_FILE_OFFSET_BITS=64',
      'ENABLE_WEBRTC',
    ],
    'cflags_cc': [
      '-fno-exceptions',
      '-fvisibility-inlines-hidden',
      '-std=gnu++11',
    ],
    'cflags': [
      '-fPIC',
      '-pthread',
      '-fstack-protector',
      '--param=ssp-buffer-size=4',
      '-fno-strict-aliasing',
      '-fvisibility=hidden',
      '-pipe',
      '<!@(pkg-config --cflags <(webrtc_pkg_deps))',
    ],
    'ldflags': [
      '-fPIC',
      '-pthread',
      '-Wl,-z,noexecstack',
      '-Wl,--no-undefined',
      '-Wl,-z,defs',
      '<!@(pkg-config --libs-only-L --libs-only-other <(webrtc_pkg_deps))',
    ],
    'libraries': [
      '<!@(pkg-config --libs-only-l <(webrtc_pkg_deps))',
      '-lusrsctp', '-ljsoncpp',
    ],
  },
}
