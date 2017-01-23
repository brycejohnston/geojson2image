require "geojson2image/version"
require "oj"
require "mini_magick"

module Geojson2image
  class Convert
    attr_accessor :parsed_json, :img_width, :img_height, :width, :height, :output, :canvas

    def initialize(json: nil, width: nil, height: nil, output: nil)
      begin
        @parsed_json = Oj.load(json)
        @img_width = width || 500
        @img_height = height || 500
        @width = (@img_width * 0.9).to_i
        @height = (@img_height * 0.9).to_i
        @output = output || "output.jpg"
      rescue Oj::ParseError
        puts "GeoJSON parse error"
      end
    end

    def compute_boundary(boundary, boundary2)
      if boundary.nil?
        return boundary2
      else
        return [
          [boundary[0], boundary2[0]].min,
          [boundary[1], boundary2[1]].max,
          [boundary[2], boundary2[2]].min,
          [boundary[3], boundary2[3]].max
        ]
      end
    end

    def get_boundary(json)
      case json['type']
      when 'GeometryCollection'
        return_boundary = nil
        json['geometries'].each do |geometry|
          return_boundary = compute_boundary(return_boundary, get_boundary(geometry))
        end
        puts "get_boundary - GeometryCollection" # DEBUG
        return return_boundary

      when 'FeatureCollection'
        return_boundary = nil
        json['features'].each do |feature|
          return_boundary = compute_boundary(return_boundary, get_boundary(feature))
        end
        puts "get_boundary - FeatureCollection" # DEBUG
        return return_boundary

      when 'Feature'
        puts "get_boundary - Feature" # DEBUG
        return get_boundary(json['geometry'])

      when 'Point'
        puts "get_boundary - Point" # DEBUG
        return [
          json['coordinates'][0],
          json['coordinates'][0],
          json['coordinates'][1],
          json['coordinates'][1]
        ]

      when 'MultiPoint'
        return_boundary = nil
        json['coordinates'].each do |point|
          return_boundary = compute_boundary(return_boundary, [point[0], point[0], point[1], point[1]])
        end
        puts "get_boundary - MultiPoint" # DEBUG
        return return_boundary

      when 'LineString'
        return_boundary = nil
        json['coordinates'].each do |point|
          return_boundary = compute_boundary(return_boundary, [point[0], point[0], point[1], point[1]])
        end
        puts "get_boundary - LineString" # DEBUG
        return return_boundary

      when 'MultiLineString'
        return_boundary = nil
        json['coordinates'].each do |linestrings|
          linestrings.each do |point|
            return_boundary = compute_boundary(return_boundary, [point[0], point[0], point[1], point[1]])
          end
        end
        puts "get_boundary - MultiLineString" # DEBUG
        return return_boundary

      when 'Polygon'
        return_boundary = nil
        json['coordinates'].each do |linestrings|
          linestrings.each do |point|
            return_boundary = compute_boundary(return_boundary, [point[0], point[0], point[1], point[1]])
          end
        end
        puts "get_boundary - Polygon" # DEBUG
        return return_boundary

      when 'MultiPolygon'
        return_boundary = nil
        json['coordinates'].each do |polygons|
          polygons.each do |linestrings|
            linestrings.each do |point|
              return_boundary = compute_boundary(return_boundary, [point[0], point[0], point[1], point[1]])
            end
          end
        end
        puts "get_boundary - MultiPolygon" # DEBUG
        return return_boundary

      else
        puts "get_boundary invalid GeoJSON parse error"
      end
    end

    def pixel_x(x)
      (x.to_f + 180) / 360
    end

    def pixel_y(y)
      sin_y = Math.sin(y.to_f * Math::PI / 180)
      return (0.5 - Math.log((1 + sin_y) / (1 - sin_y)) / (4 * Math::PI))
    end

    def adjust_point(point)
      point += 180
      point = (point > 360 ? point - 360 : point)
    end

    def transform_point(point, boundary)
      if point[0] == 180 || point[0] == -180
        return false
      end

      x_delta = pixel_x(boundary[1]) - pixel_x(boundary[0])
      y_delta = pixel_y(boundary[3]) - pixel_y(boundary[2])

      new_point = []
      new_point[0] = ((pixel_x(adjust_point(point[0]) + boundary[4]) - pixel_x(adjust_point(boundary[0]) + boundary[4])) * width / x_delta).floor + (@width * 0.05)
      new_point[1] = ((pixel_y(boundary[3]) - pixel_y(point[1])) * height / y_delta).floor + (@height * 0.05)

      return new_point
    end

    def draw(json, boundary, options = {})
      x_delta = boundary[1] - boundary[0]
      y_delta = boundary[3] - boundary[2]
      max_delta = [x_delta, y_delta].max

      case json['type']
      when 'GeometryCollection'
        json['geometries'].each do |geometry|
          draw(geometry, boundary, options)
        end
        puts "draw - GeometryCollection" # DEBUG

      when 'FeatureCollection'
        return_boundary = nil
        json['features'].each do |feature|
          draw(feature, boundary)
        end
        puts "draw - FeatureCollection" # DEBUG

      when 'Feature'
        draw(json['geometry'], boundary, json['properties'])
        puts "draw - Feature" # DEBUG

      when 'Point'
        if !options.nil? && options.has_key?("point_background_color")
          # background_color = ""
          # background_color = ChunkyPNG::Color::BLACK
        end

        if !options.nil? && options.has_key?("point_border_color")
          # border_color = ""
        else
          # border_color = ChunkyPNG::Color::BLACK
        end

        if !options.nil? && options.has_key?("point_border_size")
          border_size = options['point_border_size']
        else
          border_size = 1
        end

        point_size = 10
        point = json['coordinates']
        new_point = transform_point(point, boundary)
        # imagefilledellipse(gd, new_point[0], new_point[1], point_size, point_size, background_color)

        border_size.times do |n|
          # imageellipse(gd, new_point[0], new_point[1], point_size - 1 + n, point_size - 1 + n, border_color)
        end
        puts "draw - Point" # DEBUG

      when 'MultiPoint'
        json['coordinates'].each do |coordinate|
          point = {
            "type" => "Point",
            "coordinates" => coordinate
          }
          draw(point, boundary, options)
          puts "draw - MultiPoint" # DEBUG
        end

      when 'LineString'
        last_point = null

        if !options.nil? && options.has_key?("line_border_color")
          # border_color = ""
        else
          # border_color = ChunkyPNG::Color::BLACK
        end

        if !options.nil? && options.has_key?("line_border_size")
          border_size = options['line_border_size']
        else
          border_size = 3
        end

        json['coordinates'].each do |point|
          new_point = transform_point(point, boundary)
          if !last_point.nil?
            @png.line_xiaolin_wu(last_point[0], last_point[1], new_point[0], new_point[1], stroke_color = ChunkyPNG::Color::BLACK)
          end
          last_point = new_point
        end
        puts "draw - LineString" # DEBUG

      when 'MultiLineString'
        json['coordinates'].each do |coordinate|
          linestring = {
            "type" => "LineString",
            "coordinates" => coordinate
          }
          draw(linestring, boundary, options)
        end
        puts "draw - MultiLineString" # DEBUG

      when 'Polygon'
        if !options.nil? && options.has_key?("polygon_background_color") && options['polygon_background_color'] != false
          # background_color = ""
        else
          # no color if no polygon_background_color
          # background_color = nil
        end

        if !options.nil? && options.has_key?("polygon_border_color")
          # border_color = ""
        else
          # border_color = ChunkyPNG::Color::BLACK
        end

        if !options.nil? && options.has_key?("polygon_border_size")
          # border_size = options['polygon_border_size']
        else
          # border_size = 6
        end

        json['coordinates'].each do |linestrings|
          border_points = []
          if linestrings[0] != linestrings[linestrings.count - 1]
            linestrings << linestrings[0]
          end

          linestrings.each do |point|
            new_point = transform_point(point, boundary)
            border_points << "#{new_point[0].floor},#{new_point[1].floor}"
          end

          border = "polygon " + border_points.join(", ")
          @convert.draw(border)
        end
        puts "draw - Polygon" # DEBUG

      when 'MultiPolygon'
        json['coordinates'].each do |polygon|
          poly = {
            "type" => "Polygon",
            "coordinates" => polygon
          }
          draw(poly, boundary, options)
        end
        puts "draw - MultiPolygon" # DEBUG

      else
        puts "draw invalid GeoJSON parse error - #{json['type']}"
      end
    end

    def to_image
      @convert = MiniMagick::Tool::Convert.new
      @convert.size("#{@img_width}x#{@img_height}")
      @convert.xc('white')
      @convert.fill('rgba(0, 158, 40, 0.3)')
      @convert.stroke('rgb(0, 107, 27)')
      @convert.strokewidth(4)

      boundary = get_boundary(@parsed_json)
      boundary[4] = 0

      if boundary[1] > boundary[0]
        draw(@parsed_json, boundary)
      else
        boundary[1] += 360
        draw(@parsed_json, boundary)

        boundary[1] -= 360
        boundary[0] -= 360
        draw(@parsed_json, boundary)
      end

      @convert << @output
      @convert.call
    end

  end
end
