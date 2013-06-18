
# CityNavIcon is for providing svg or png icons depending of the support by the web browser.
class CityNavIcon
    constructor: (opts) ->
        _.extend @, opts
        @staticSVGPath = "static/images/"
        @staticPNGPath = "static/images/grunticon/png/"
        
    get_icon_path: (name) ->
       if document.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#Image", "1.1") ||
          document.implementation.hasFeature("org.w3c.dom.svg", "1.0")
            return @staticSVGPath + name + '.svg'
        else
            return @staticPNGPath + name + '.png'
            
    get_icon_html: (name) ->
        return '<img src="' + @.get_icon_path(name) + '" style="height: 20px" class="ui-li-icon"></div>'

window.citynavicon = new CityNavIcon

$('*[id*=citynavicon]:visible').each( ->
    $(this).attr('src', citynavicon.get_icon_path(this.id.substring(12)));
);

