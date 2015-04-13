# Extends the default marker allowing icon rotation
L.RotatedMarker = L.Marker.extend
  options:
    angle: 0

  _setPos: (pos) ->
    L.Marker::_setPos.call @, pos

    if L.DomUtil.TRANSFORM
      @_icon.style[L.DomUtil.TRANSFORM] += " rotate(#{@options.angle}deg)"

L.rotatedMarker = (pos, options) -> new L.RotatedMarker pos, options

