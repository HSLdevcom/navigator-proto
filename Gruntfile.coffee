module.exports = (grunt) ->
  grunt.initConfig
    pkg: '<json:package.json>'

    coffee:
      lib:
        expand: true
        cwd: 'src'
        src: ['*.coffee']
        dest: 'lib/'
        ext: '.js'

    watch:
      files: [
        'Gruntfile.coffee'
        'src/*.coffee'
      ]
      tasks: 'default'

    connect:
      server:
        options:
          port: 9001
          base: "."
          keepalive: true

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-connect'

  grunt.registerTask 'default', ['coffee']
