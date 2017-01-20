require "geojson2image/version"
require "oj"
require "rmagick"

module Geojson2image
  class Convert
    attr_accessor :parsed_json, :width, :height

    def initialize(json: nil, width: nil, height: nil)
      begin
        @parsed_json = Oj.load(json)
        @width = width || 200
        @height = height || 200
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
        return return_boundary

      when 'FeatureCollection'
        return_boundary = nil
        json['features'].each do |feature|
          return_boundary = compute_boundary(return_boundary, get_boundary(feature))
        end
        return return_boundary

      when 'Feature'
        return get_boundary(json['geometry'])

      when 'Point'
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
        return return_boundary

      when 'LineString'
        return_boundary = nil
        json['coordinates'].each do |point|
          return_boundary = compute_boundary(return_boundary, [point[0], point[0], point[1], point[1]])
        end
        return return_boundary

      when 'MultiLineString'
        return_boundary = nil
        json['coordinates'].each do |linestrings|
          linestrings.each do |point|
            return_boundary = compute_boundary(return_boundary, [point[0], point[0], point[1], point[1]])
          end
        end
        return return_boundary

      when 'Polygon'
        return_boundary = nil
        json['coordinates'].each do |linestrings|
          linestrings.each do |point|
            return_boundary = compute_boundary(return_boundary, [point[0], point[0], point[1], point[1]])
          end
        end
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
        return return_boundary

      else
        puts "Invalid GeoJSON parse error"
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

      x_delta = pixel_(boundary[1]) - pixel_x(boundary[0])
      y_delta = pixel_y(boundary[3]) - pixel_y(boundary[2])

      new_point = []
      new_point[0] = ((pixel_x(adjust_point(point[0]) + boundary[4]) - pixel_x(adjust_point(boundary[0]) + boundary[4])) * width / x_delta).floor
      new_point[1] = ((pixel_y(boundary[3]) - pixel_y(point[1])) * height / y_delta).floor

      return new_point
    end

    def draw_json(json, boundary, options = {})
      x_delta = boundry[1] - boundry[0]
      y_delta = boundry[3] - boundry[2]
      max_delta = [x_delta, y_delta].max

      case json['type']
      when 'GeometryCollection'
        json['geometries'].each do |geometry|
          draw_json(geometry, boundry, options)
        end

      when 'FeatureCollection'
        return_boundary = nil
        json['features'].each do |feature|
          draw_json(feature, boundry)
        end

      when 'Feature'
        draw_json(json['geometry'], boundry, json['properties'])

      when 'Point'
        if options.has_key?("point_background_color")
          # background_color = imagecolorallocate(gd, options['point_background_color'][0], options['point_background_color'][1], options['point_background_color'][2])
        else
          # default red
          # background_color = imagecolorallocate(gd, 255, 0, 0)
        end

        if options.has_key?("point_border_color")
          # border_color = imagecolorallocate(gd, options['point_border_color'][0], options['point_border_color'][1], options['point_border_color'][2])
        else
          # border_color = imagecolorallocate(gd, 0, 0, 0)
        end

        if options.has_key?("point_border_size")
          border_size = options['point_border_size']
        else
          border_size = 1
        end

        point_size = 10
        point = json['coordinates']
        new_point = transform_point(point, boundry)
        # imagefilledellipse(gd, new_point[0], new_point[1], point_size, point_size, background_color)

        border_size.times do |n|
          # imageellipse(gd, new_point[0], new_point[1], point_size - 1 + n, point_size - 1 + n, border_color)
        end

      when 'MultiPoint'
        json['coordinates'].each do |coordinate|
          point = {
            'type': 'Point',
            'coordinates': coordinate
          }
          draw_json(point, boundry, options)
        end

      when 'LineString'
        last_point = null

        if options.has_key?("line_border_color")
          # border_color = imagecolorallocate(gd, options['line_border_color'][0], options['line_border_color'][1], options['line_border_color'][2])
        else
          # border_color = imagecolorallocate(gd, 0, 0, 0)
        end

        if options.has_key?("line_border_size")
          border_size = options['line_border_size']
        else
          border_size = 3
        end

        json['coordinates'].each do |point|
          new_point = transform_point(point, boundry)
          if !last_point.nil?
            imagesetthickness(gd, border_size)
            imageline(gd, last_point[0], last_point[1], new_point[0], new_point[1], border_color)
          end
          last_point = new_point
        end

      when 'MultiLineString'
        json['coordinates'].each do |coordinate|
          linestring = {
            'type': 'LineString',
            'coordinates': coordinate
          }
          draw_json(linestring, boundry, options)
        end

      when 'Polygon'
        if options.has_key?("polygon_background_color") && options['polygon_background_color'] != false
          # background_color = imagecolorallocate(gd, options['polygon_background_color'][0], options['polygon_background_color'][1], options['polygon_background_color'][2])
        else
          # no color if no polygon_background_color
          # background_color = nil
        end

        if options.has_key?("polygon_border_color")
          # border_color = imagecolorallocate(gd, options['polygon_border_color'][0], options['polygon_border_color'][1], options['polygon_border_color'][2])
        else
          # border_color = imagecolorallocate(gd, 0, 0, 0)
        end

        if options.has_key?("polygon_border_size")
          border_size = options['polygon_border_size']
        else
          border_size = 6
        end

        filled_points = []
        json['coordinates'].each do |linestrings|
          border_points = []
          if linestrings[0] != linestrings[linestrings.count - 1]
            linestrings[] = linestrings[0]
          end

          # if linestrings.count <= 3
            # skip 2 points
            # continue 2
          # end

          linestrings.each do |point|
            new_point = transform_point(point, boundry)
            border_points[] = new_point[0].floor
            filled_points[] = new_point[0].floor
            border_points[] = new_point[1].floor
            filled_points[] = new_point[1].floor
          end

          # if border_points.count < 3
            # continue
          # end

          if !border_size.nil? && !border_size.empty?
            # imagesetthickness(gd, border_size)
            # imagepolygon(gd, border_points, border_points.count / 2, border_color)
          end
        end

        if !background_color.nil? && filled_points.count >= 1
          # imagefilledpolygon(gd, filled_points, filled_points.count / 2, background_color)
        end

      when 'MultiPolygon'
        json['coordinates'].each do |polygon|
          poly = {
            'type': 'Polygon',
            'coordinates': polygon
          }
          draw_json(poly, boundry, options)
        end

      else
        puts "Invalid GeoJSON parse error"
      end
    end

    def draw
      boundary = get_boundary(@parsed_json)

      boundary[4] = 0

      if boundary[1] > boundary[0]
        draw_json(@parsed_json, boundary)
      else
        boundary[1] += 360
        draw_json(@parsed_json, boundary)

        boundary[1] -= 360
        boundary[0] -= 360
        draw_json(@parsed_json, boundary)
      end

    end

  end
end
