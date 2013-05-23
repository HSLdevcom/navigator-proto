module.exports = (grunt) ->
  grunt.initConfig
    pkg: '<json:package.json>'

    coffee:
      lib:
        expand: true
        cwd: 'src'
        src: ['*.coffee']
        dest: 'static/js/'
        ext: '.js'

    watch:
      files: [
        'Gruntfile.coffee'
        'src/*.coffee'
      ]
      tasks: 'default'

    testem:
      desktop:
        options:
          launch_in_ci: ['firefox']
          before_tests: 'coffee -c tests/*.coffee'
          after_tests: 'rm tests/*.js'
          serve_files: 'tests/*.js'
          src_files: 'tests/*.coffee'
        files:
          'test_functional.tap': ['index.html']
      mobile:
        options:
          launch_in_ci: ['android', 'iphone', 'ipad']
          launchers:
            android:
              command: 'saucelauncher launch android <url> --os=Linux'
              protocol: 'browser'
            iphone:
              command: 'saucelauncher launch iphone <url> --os="OS X 10.8"'
              protocol: 'browser'
            ipad:
              command: 'saucelauncher launch ipad <url> --os="OS X 10.8"'
              protocol: 'browser'
          on_start:
            command: 'saucelauncher tunnel'
            wait_for_text: 'Connected! You may start your tests.'
          host: '0.0.0.0',  # for accessing the server from SauceLabs
          before_tests: 'coffee -c tests/*.coffee'
          after_tests: 'rm tests/*.js'
          serve_files: 'tests/*.js'
          src_files: 'tests/*.coffee'
        files:
          'test_functional.tap': ['index.html']
    exec:
      robot:
        command: 'bin/pybot tests'
    connect:
      server:
        options:
          port: 9001
          base: "."

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-exec'
  grunt.loadNpmTasks 'grunt-testem'

  grunt.registerTask 'default', ['coffee']
  grunt.registerTask 'server', ['coffee', 'connect', 'watch']
  grunt.registerTask 'test', ['coffee', 'testem:desktop']
  grunt.registerTask 'test-mobile', ['coffee', 'testem:mobile']
  grunt.registerTask 'test-robot', ['coffee', 'connect', 'exec:robot']
