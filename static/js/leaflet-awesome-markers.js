(function() {

  (function(window, document, undefined_) {
    L.AwesomeMarkers = {};
    L.AwesomeMarkers.version = "1.0";
    L.AwesomeMarkers.Icon = L.Icon.extend({
      options: {
        iconSize: [35, 45],
        iconAnchor: [17, 42],
        popupAnchor: [1, -32],
        shadowAnchor: [10, 12],
        shadowSize: [36, 16],
        className: "awesome-marker",
        icon: "home",
        color: "blue",
        iconColor: "white"
      },
      initialize: function(options) {
        return options = L.setOptions(this, options);
      },
      createIcon: function() {
        var div, options;
        div = document.createElement("div");
        options = this.options;
        if (options.icon) {
          div.innerHTML = this._createInner();
        }
        if (options.bgPos) {
          div.style.backgroundPosition = (-options.bgPos.x) + "px " + (-options.bgPos.y) + "px";
        }
        this._setIconStyles(div, "icon-" + options.color);
        return div;
      },
      _createInner: function() {
        var iconClass;
        if (this.options.svg != null) {
          return "<img src='" + this.options.svg + "' height='18' style='margin-top: 8px; -webkit-filter: invert(1);'>";
        }
        if (this.options.icon.slice(0, 5) === "icon-") {
          iconClass = this.options.icon;
        } else {
          iconClass = "icon-" + this.options.icon;
        }
        return "<i class='" + iconClass + (this.options.spin ? " icon-spin" : "") + (this.options.iconColor ? " icon-" + this.options.iconColor : "") + "'></i>";
      },
      _setIconStyles: function(img, name) {
        var anchor, options, size;
        options = this.options;
        size = L.point(options[(name === "shadow" ? "shadowSize" : "iconSize")]);
        anchor = void 0;
        if (name === "shadow") {
          anchor = L.point(options.shadowAnchor || options.iconAnchor);
        } else {
          anchor = L.point(options.iconAnchor);
        }
        if (!anchor && size) {
          anchor = size.divideBy(2, true);
        }
        img.className = "awesome-marker-" + name + " " + options.className;
        if (anchor) {
          img.style.marginLeft = (-anchor.x) + "px";
          img.style.marginTop = (-anchor.y) + "px";
        }
        if (size) {
          img.style.width = size.x + "px";
          return img.style.height = size.y + "px";
        }
      },
      createShadow: function() {
        var div, options;
        div = document.createElement("div");
        options = this.options;
        this._setIconStyles(div, "shadow");
        return div;
      }
    });
    return L.AwesomeMarkers.icon = function(options) {
      return new L.AwesomeMarkers.Icon(options);
    };
  })(this, document);

}).call(this);
