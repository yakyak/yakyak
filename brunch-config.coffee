commonRequireDefinition = require './src/require-wrap'

exports.config =

    paths:
        public: 'output/Yakayak.app/Contents/Resources/app'

    files:
        javascripts:
            defaultExtension: 'coffee'
            joinTo: 'js/app.js'

        stylesheets:
            defaultExtension: 'less'
            joinTo: 'css/app.css'

    modules:
        definition: -> commonRequireDefinition('brequire')
        wrapper: (path, data, isVendor) ->
            nameCleaner = (path) -> (path
                .replace(/^app\//, '')
                .replace(new RegExp('\\\\', 'g'), '/')
                .replace(new RegExp('^(\.\.\/)*', 'g'), '')
                .replace(/\.\w+$/, ''))
            clean = nameCleaner(path)
            if isVendor
                return data
            else
                """
                brequire.define({"#{clean}": function(exports, brequire, module) {
                  #{data}
                }});\n\n
                """
