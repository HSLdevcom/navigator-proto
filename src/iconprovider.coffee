{
    icon_base_path,
    icon_grunticon_png_path
} = citynavi.config

# IconProvider is for providing svg or png icons depending of the support by the web browser.
class IconProvider
    constructor: (opts) ->
        _.extend @, opts
    
    # Use `citynavicon.get_icon_path("myicon")` to get path to image that
    # you can, for example use as src attribute in an img html element.   
    get_icon_path: (name) ->
        if document.implementation.hasFeature 'http://www.w3.org/TR/SVG11/feature#Image', '1.1' || document.implementation.hasFeature 'org.w3c.dom.svg', '1.0'
            return icon_base_path + name + '.svg'
        else
            return icon_grunticon_png_path + name + '.png'
    
    # Use `citynavicon.get_icon_html(name, [attribute_string])` function to get an img element
    # with the specified name and with an optional attribute_string such as
    # ``style="height: 20px" class="ui-li-icon"``.
    get_icon_html: (name, param_string) ->
        params = param_string ? ''
        return '<img src="' + @get_icon_path(name) + '"' + params + '>'

    # In html you can include images via defining img element with class="citynavicon-myicon" where
    # "citynavicon-" is mandatory part and "myicon" specifies name of the image. In addition to defining the class
    # call the function `modify_img_elements(parent_id)` for the parent with parent_id of the
    # img element to generate the src attributes for the img elements under the parent.
    modify_img_elements: (parent_id) ->
    
        self = @;
        
        $(parent_id).find('img[class*=iconprovider]').each ->
            $(@).attr 'src', self.get_icon_path($(@).attr('class').substring(13))


citynavi.iconprovider = new IconProvider

