# Load all required libraries.
gulp          = require 'gulp'
exec          = require 'child_process'
  .exec
sass          = require 'gulp-sass'
insert        = require 'gulp-insert'
rename        = require 'gulp-rename'
autoprefixer  = require 'gulp-autoprefixer'
svgo          = require 'gulp-svgo'
imagemin      = require 'gulp-imagemin'
cssBase64     = require 'gulp-css-base64'
iconfont      = require 'gulp-iconfont'
Table         = require 'cli-table2'
fontmin       = require 'gulp-fontmin'
filter        = require 'gulp-filter'
coffee        = require 'gulp-coffee'
concat        = require 'gulp-concat'
notify        = require 'gulp-notify'
csso          = require 'gulp-csso'
cssbeautify   = require 'gulp-cssbeautify'

states = ['min', 'narrow', 'medium', 'wide', 'max']
paths = 
  components: 'build/components'
  sass: 'build/sass/*.sass'
  css: 'themes/off/css/'
  res: 'themes/off/res/'
  icons: 'build/icons/'
  js: 'themes/off/js/'

gulp.task 'styleguide', ['sass', 'coffee'], (cb) ->
  cmd = 'node_modules/.bin/kss '
  cmd += '--source build/components '
  cmd += '--css styleguide.css '
  cmd += '--title "Product Opener Styleguide" '
  cmd += '--builder build/styleguide-builder '
  
  exec cmd, (err, stdout, stderr) ->
    notify 'Something went wrong during styleguide creation'
    console.log stdout
    console.log stderr
    cb err
    return

sassTasks = []

states.forEach (state) ->
  taskName = 'sass-' + state
  environment = ''
  states.forEach (currentState) ->
    environment += '$' + currentState + ': '
    environment += if currentState == state then 'true' else 'false'
    environment += '; \n'
    return
  if state == 'max'
    environment += '$max: true; \n'
    environment += '$wide: true; \n'
  if state == 'min'
    environment += '$min: true; \n'
    environment += '$narrow: true; \n'
  sassTasks.push taskName

  gulp.task taskName, ->
    gulp
      .src paths.sass
      .pipe insert.prepend environment
      .pipe sass()
      .pipe rename state + '.css'
      .pipe gulp.dest paths.css
  return

gulp.task 'sass', sassTasks, ->
  options = 
    maxWeightResource: 131072
    extensionsAllowed: ['.png', '.svg']
    baseDir: paths.css 

  gulp.src paths.css + '*.css'
    .pipe cssBase64()
    #.pipe csso() # optimise css
    #.pipe sass() # re-disoptimise the things you don't want optimied
    .pipe autoprefixer()
    .pipe gulp.dest paths.css

gulp.task 'coffee', ->
  gulp
    .src 'build/components/**/*.coffee'
    .pipe coffee
      bare: true
    .pipe concat 'scripts.js'
    .pipe gulp.dest paths.js

gulp.task 'images', ->
  gulp
    .src 'build/images/*.svg' 
    .pipe svgo() 
    .pipe gulp.dest paths.res
  gulp
    .src 'build/images/*.png'
    .pipe imagemin()
    .pipe gulp.dest paths.res

# the uppercase aphabet
allowedCharacters  = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
# the lowercase aphabet
allowedCharacters += 'abcdefghijklmnopqrstuvwxyz'
# germanisms
allowedCharacters += 'ÖÄÜöäüß„“‚‘'
# italisms
allowedCharacters += 'ãÃáÁéÉèÈóÓòÒúÚñÑÇçøØíÍ'
# numbers
allowedCharacters += '0123456789'
# dashes
allowedCharacters += '-–­'
# punctuation
allowedCharacters += '!"§$%&/()=?… “”‘’«»‹›№.@©'

gulp.task 'fonts', ->
  options = 
    text: allowedCharacters
    quiet: false

  removeFolder = (path) ->
    path.dirname = ''
  
  onlyWoff = filter ['**/*.woff']

  gulp
    .src 'build/fonts/**/*.ttf'
    .pipe fontmin options
    .pipe onlyWoff
    .pipe rename removeFolder
    .pipe gulp.dest paths.res
  gulp.run 'sass'

gulp.task 'icons', ->
  options = 
    fontName: 'icons'
    prependUnicode: true
    ascent: 800
    descent: 200
    formats: [
      'ttf'
      'woff'
    ]
  gulp
    .src paths.icons + '*.svg'
    .pipe iconfont options
    .on 'glyphs', (glyphs, options) ->
      console.log 'Create font "' + options.fontName + '"'
      table = new Table('head': [
        'NAME'
        'UNICODE'
      ])
      for index of glyphs
        table.push [
          glyphs[index].name
          glyphs[index].unicode[0]
        ]
      console.log table.toString()
      return
    .pipe gulp.dest paths.res
  gulp.run 'sass'

gulp.task 'watch', ['styleguide', 'sass'], ->
  gulp.watch 'build/components/**/*.sass', ['styleguide']
  gulp.watch 'build/components/**/*.scss', ['styleguide']
  gulp.watch 'build/components/**/*.twig', ['styleguide']
  gulp.watch 'build/components/**/*.coffee', ['styleguide']
  gulp.watch 'build/styleguide-builder/kss-assets/kss.css', ['styleguide']
  gulp.watch 'build/styleguide-builder/index.twig', ['styleguide']
  gulp.watch 'build/images/*.svg', ['images']
  gulp.watch 'build/images/*.png', ['images']
  gulp.watch 'build/fonts/**/*.ttf', ['fonts']
  gulp.watch paths.icons + '*.svg', ['icons']
  gulp.watch paths.components, ['sass']
  gulp.watch paths.sass, ['sass']

# Default task call every tasks created so far.
gulp.task 'default', ['watch']