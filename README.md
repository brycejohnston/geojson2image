# geojson2image

[![Gem Version](http://img.shields.io/gem/v/geojson2image.svg)][gem]

[gem]: https://rubygems.org/gems/geojson2image

Ruby library for generating images from GeoJSON.

Currently, MultiPolygon and Polygon GeoJSON types should output images properly. Other GeoJSON types have not been thoroughly tested, and properties from the GeoJSON are not being parsed. 

## Installation

You will need [ImageMagick](http://imagemagick.org/) installed. Then Add this line to your application's Gemfile:

```ruby
gem 'geojson2image'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install geojson2image

## Usage

Initialize new Geojson2image::Convert object and call to_image
```ruby
gjson = '{"type":"Feature","geometry":{"type":"MultiPolygon","coordinates":[......'
g2i = Geojson2image::Convert.new(
  json: gjson,
  width: 500,
  height: 500,
  padding: 50,
  background_color: 'white',
  fill_color: 'rgba(0, 158, 40, 0.3)',
  stroke_color: 'rgb(0, 107, 27)',
  stroke_width: 3,
  output: "output.jpg"
)
g2i.to_image
```

### Example Output
![Example Output](example/example_output.jpg?raw=true "Example Output")

### Color Options

ImageMagick Color Names Reference: https://www.imagemagick.org/script/color.php

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/brycejohnston/geojson2image.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
