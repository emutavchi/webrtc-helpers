{
  'targets': [
    {
      'target_name': 'gtest',
      'toolsets': ['host', 'target'],
      'type': 'static_library',
      'sources': [
        'gtest/src/gtest-death-test.cc',
        'gtest/src/gtest-filepath.cc',
        'gtest/src/gtest-port.cc',
        'gtest/src/gtest-printers.cc',
        'gtest/src/gtest-test-part.cc',
        'gtest/src/gtest-typed-test.cc',
        'gtest/src/gtest.cc',
      ],
      'include_dirs': [
        'gtest',
        'gtest/include',
      ],
      'defines': [
        'GTEST_HAS_POSIX_RE=0',
      ],
      'all_dependent_settings': {
        'include_dirs': [
          'gtest/include',
        ],
        'defines': [
          'GTEST_HAS_POSIX_RE=0',
          'GTEST_LANG_CXX11=1',
        ],
      },
      'direct_dependent_settings': {
        'defines': [
          'UNIT_TEST',
        ],
        'target_conditions': [
          ['_type=="executable"', {
            'test': 1,
          }],
        ],
      },
    },
  ],
}
