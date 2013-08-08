# local_config.coffee contains deployment-specific settings. One can also
# use them for local testing. The default and area-specific settings
# committed into the codebase are in config.coffee.
#
# This template works as an example for what can be done with
# local_config.coffee. It is likely that one does not need all of the
# functionality.

# window.citynavi should have been defined in init.coffee.

citynavi.update_configs
    # Update existing configs.
    ##########################

    # The value of "defaults" is merged into the configuration first.
    defaults:
        new_feature_api_url: "http://example.com/"
    helsinki:
        cities: citynavi.configs.helsinki.cities.concat ["Inarinjärvi"]

    # Or create new configs.
    ########################

    llanfairpwll:
        country: "gb"

    # The value of "overrides" is merged into the configuration after the
    # area-specific configuration. Useful for local testing.
    overrides:
        osm_notes_url: "http://api06.dev.openstreetmap.org/api/0.6/notes.json"

# Choose the area.
citynavi.set_config "helsinki"
