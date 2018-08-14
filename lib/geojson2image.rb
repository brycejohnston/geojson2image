require "geojson2image/version"
require "oj"
require "chunky_png"

module Geojson2image
  class Convert

    def initialize(json: nil, width: nil, height: nil,  padding: nil,
      background: nil, fill: nil, stroke: nil,
      output: nil)
      begin
        @parsed_json = Oj.load(json)
        @width = width || 500
        @height = height || 500
        @padding = padding || 50
        @background = (background.nil? ? ChunkyPNG::Color::WHITE : ChunkyPNG::Color.from_hex(background))
        @fill = (fill.nil? ? ChunkyPNG::Color::TRANSPARENT : ChunkyPNG::Color.from_hex(fill))
        @stroke = (stroke.nil? ? ChunkyPNG::Color::BLACK : ChunkyPNG::Color.from_hex(stroke))
        @output = output || "output.png"
        @min_xy = [-1, -1]
        @max_xy = [-1, -1]
        @coordinates = []
        @width_padding = 0
        @height_padding = 0
        @global_ratio = 0
        @png = ChunkyPNG::Image.new(@width, @height, @background_color)
      rescue Oj::ParseError
        puts "GeoJSON parse error"
      end
    end

    def get_points(json)
      case json['type']
      when 'GeometryCollection'
        json['geometries'].each do |geometry|
          get_points(geometry)
        end

      when 'FeatureCollection'
        json['features'].each do |feature|
          get_points(feature)
        end

      when 'Feature'
        get_points(json['geometry'])

      when 'Point'
        @coordinates << [json['coordinates'][0], json['coordinates'][1]]

      when 'MultiPoint'
        json['coordinates'].each do |point|
          @coordinates << [point[0], point[1]]
        end

      when 'LineString'
        json['coordinates'].each do |point|
          @coordinates << [point[0], point[1]]
        end

      when 'MultiLineString'
        json['coordinates'].each do |linestrings|
          linestrings.each do |point|
            @coordinates << [point[0], point[1]]
          end
        end

      when 'Polygon'
        json['coordinates'].each do |linestrings|
          linestrings.each do |point|
            @coordinates << [point[0], point[1]]
          end
        end

      when 'MultiPolygon'
        json['coordinates'].each do |polygons|
          polygons.each do |linestrings|
            linestrings.each do |point|
              @coordinates << [point[0], point[1]]
            end
          end
        end

      else
        puts "get_points - invalid GeoJSON parse error"
      end
    end

    def get_boundary
      quarter_pi = Math::PI / 4.0

      @coordinates.each_with_index do |point,i|
        lon = @coordinates[i][0] * Math::PI / 180
        lat = @coordinates[i][1] * Math::PI / 180

        @coordinates[i][0] = lon
        @coordinates[i][1] = Math.log(Math.tan(quarter_pi + 0.5 * lat))

        @min_xy[0] = (@min_xy[0] == -1 ? @coordinates[i][0] : [@min_xy[0], @coordinates[i][0]].min)
        @min_xy[1] = (@min_xy[1] == -1 ? @coordinates[i][1] : [@min_xy[1], @coordinates[i][1]].min)
      end

      @coordinates.each_with_index do |point,i|
        @coordinates[i][0] = @coordinates[i][0] - @min_xy[0]
        @coordinates[i][1] = @coordinates[i][1] - @min_xy[1]

        @max_xy[0] = (@max_xy[0] == -1 ? @coordinates[i][0] : [@max_xy[0], @coordinates[i][0]].max)
        @max_xy[1] = (@max_xy[1] == -1 ? @coordinates[i][1] : [@max_xy[1], @coordinates[i][1]].max)
      end
    end

    def transform_point(point)
      quarter_pi = Math::PI / 4.0

      lon = point[0] * Math::PI / 180
      lat = point[1] * Math::PI / 180

      xy = []
      xy[0] = lon - @min_xy[0]
      val = Math.log(Math.tan(quarter_pi + 0.5 * lat))
      xy[1] = val - @min_xy[1]

      xy[0] = (@width_padding + (xy[0] * @global_ratio)).to_i
      xy[1] = (@height - @height_padding - (xy[1] * @global_ratio)).to_i

      return xy
    end

    def draw(json, properties = nil)
      case json['type']
      when 'GeometryCollection'
        json['geometries'].each do |geometry|
          draw(geometry)
        end

      when 'FeatureCollection'
        return_boundary = nil
        json['features'].each do |feature|
          draw(feature)
        end

      when 'Feature'
        if json.key?('properties')
          draw(json['geometry'], json['properties'])
        else
          draw(json['geometry'])
        end

      when 'Point'
        tmp_stroke = @stroke
        if !properties.nil?
          if properties.key?('stroke') && !properties['stroke'].nil?
            tmp_stroke = ChunkyPNG::Color.from_hex(properties['stroke'])
          end
        end

        point = json['coordinates']
        new_point = transform_point(point)
        @png.compose_pixel(new_point[0], new_point[1], tmp_stroke)

      when 'MultiPoint'
        json['coordinates'].each do |coordinate|
          point = {
            "type" => "Point",
            "coordinates" => coordinate
          }
          draw(point)
        end

      when 'LineString'
        tmp_stroke = @stroke
        if !properties.nil?
          if properties.key?('stroke') && !properties['stroke'].nil?
            tmp_stroke = ChunkyPNG::Color.from_hex(properties['stroke'])
          end
        end

        last_point = null

        json['coordinates'].each do |point|
          new_point = transform_point(point)
          if !last_point.nil?
            @png.line(last_point[0], last_point[1], new_point[0], new_point[1], tmp_stroke)
          end
          last_point = new_point
        end

      when 'MultiLineString'
        json['coordinates'].each do |coordinate|
          linestring = {
            "type" => "LineString",
            "coordinates" => coordinate
          }
          draw(linestring)
        end

      when 'Polygon'
        tmp_fill = @fill
        tmp_stroke = @stroke
        if !properties.nil?
          if properties.key?('fill') && !properties['fill'].nil?
            tmp_fill = ChunkyPNG::Color.from_hex(properties['fill'])
          end
          if properties.key?('stroke') && !properties['stroke'].nil?
            tmp_stroke = ChunkyPNG::Color.from_hex(properties['stroke'])
          end
        end

        json['coordinates'].each do |linestrings|
          border_points = []
          if linestrings[0] != linestrings[linestrings.count - 1]
            linestrings << linestrings[0]
          end

          linestrings.each do |point|
            new_point = transform_point(point)
            border_points << "#{new_point[0]},#{new_point[1]}"
          end

          points = ChunkyPNG::Vector.multiple_from_string(border_points.join(", "))
          @png.polygon(points, tmp_stroke, tmp_fill)
        end

      when 'MultiPolygon'
        json['coordinates'].each do |polygon|
          poly = {
            "type" => "Polygon",
            "coordinates" => polygon
          }
          draw(poly)
        end

      else
        puts "draw - invalid GeoJSON parse error - #{json['type']}"
      end
    end

    def to_image
      get_points(@parsed_json)
      get_boundary

      padding_both = @padding * 2

      map_width = @width - padding_both
      map_height = @height - padding_both

      map_width_ratio = map_width / @max_xy[0]
      map_height_ratio = map_height / @max_xy[1]

      @global_ratio = [map_width_ratio, map_height_ratio].min
      @width_padding = (@width - (@global_ratio * @max_xy[0])) / 2
      @height_padding = (@height - (@global_ratio * @max_xy[1])) / 2

      draw(@parsed_json)
      @png.save(@output)
    end

  end
end
