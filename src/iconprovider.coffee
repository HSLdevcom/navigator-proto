
# CityNavIcon is for providing svg or png icons depending of the support by the web browser.
class IconProvider
    constructor: (opts) ->
        _.extend @, opts
        @static_svg_path = 'static/images/'
        @static_png_path = 'static/images/grunticon/png/'
        
    get_icon_path: (name) ->
       if document.implementation.hasFeature 'http://www.w3.org/TR/SVG11/feature#Image', '1.1' ||
          document.implementation.hasFeature 'org.w3c.dom.svg', '1.0'
            return @static_svg_path + name + '.svg'
       else
            return @static_png_path + name + '.png'
            
    get_icon_html: (name, param_string) ->
        params = param_string ? ''
        return '<img src="' + @.get_icon_path(name) + '"' + params + '>'

window.citynavi.iconprovider = new IconProvider

$('img[class*=iconprovider]').each ->
    $(@).attr 'src', citynavi.iconprovider.get_icon_path($(@).attr('class').substring(13))

