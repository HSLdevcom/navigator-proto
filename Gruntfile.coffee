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
      options:
        launch_in_ci: ['chrome', 'firefox']
        before_tests: 'coffee -c tests/*.coffee'
        after_tests: 'rm tests/*.js'
        serve_files: 'tests/*.js'
        src_files: 'tests/*.coffee'
      main:
        files:
          'test_functional.tap': ['index.html']

    connect:
      server:
        options:
          port: 9001
          base: "."

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-testem'

  grunt.registerTask 'default', ['coffee']
  grunt.registerTask 'server', ['coffee', 'connect', 'watch']
  grunt.registerTask 'test', ['coffee', 'connect', 'testem']
