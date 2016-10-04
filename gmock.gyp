{
  'targets': [
    {
      'target_name': 'gmock',
      'type': 'static_library',
      'dependencies': [
        'gtest.gyp:gtest',
      ],
      'sources': [
        'gmock/src/gmock-cardinalities.cc',
        'gmock/src/gmock-internal-utils.cc',
        'gmock/src/gmock-matchers.cc',
        'gmock/src/gmock-spec-builders.cc',
        'gmock/src/gmock.cc',
      ],
      'include_dirs': [
        'gmock_custom',
        'gmock/include',
      ],
      'all_dependent_settings': {
        'include_dirs': [
          'gmock_custom',
          'gmock/include',
        ],
      },
      'export_dependent_settings': [
        'gtest.gyp:gtest',
      ],
    },
  ],
}
