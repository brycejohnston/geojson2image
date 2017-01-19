require "geojson2image/version"
require "oj"

module Geojson2image
  class Convert
    attr_accessor :json, :width, :height

    def initialize(json: nil, width: nil, height: nil)
      begin
        @json = Oj.load(json)
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
        [
          [boundary[0], boundary2[0]].min,
          [boundary[1], boundary2[1]].max,
          [boundary[2], boundary2[2]].min,
          [boundary[3], boundary2[3]].max
        ]
      end
    end

    def get_boundary
      case @json['type']
      when 'GeometryCollection'
        return_boundary = nil;
        @json['geometries'].each do |geometry|
          return_boundary = compute_boundary(return_boundary, get_boundary(geometry))
        end
        return return_boundary
      when 'FeatureCollection'
        return_boundary = nil;
        @json['features'].each do |feature|
          return_boundary = compute_boundary(return_boundary, get_boundary(feature))
        end
        return return_boundary
      when 'Feature'
        return get_boundary(@json['geometry']);
      when 'Point'
        return [
          @json['coordinates'][0],
          @json['coordinates'][0],
          @json['coordinates'][1],
          @json['coordinates'][1]
        ]
      when 'MultiPoint'
        return_boundary = nil
        @json['coordinates'].each do |point|
          return_boundary = compute_boundary(return_boundary, [point[0], point[0], point[1], point[1]])
        end
        return return_boundary
      when 'LineString'
        return_boundary = nil
        @json['coordinates'].each do |point|
          return_boundary = compute_boundary(return_boundary, [point[0], point[0], point[1], point[1]])
        end
        return return_boundary
      when 'MultiLineString'
        return_boundary = nil
        @json['coordinates'].each do |linestrings|
          linestrings.each do |point|
            return_boundary = compute_boundary(return_boundary, [point[0], point[0], point[1], point[1]])
          end
        end
        return return_boundary
      when 'Polygon'
        return_boundary = nil
        @json['coordinates'].each do |linestrings|
          linestrings.each do |point|
            return_boundary = compute_boundary(return_boundary, [point[0], point[0], point[1], point[1]])
          end
        end
        return return_boundary
      when 'MultiPolygon'
        return_boundary = nil
        @json['coordinates'].each do |polygons|
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

    def transform_point(point)
      if point[0] == 180 || point[0] == -180
        return false
      end

      x_delta = pixel_(@boundary[1]) - pixel_x(@boundary[0])
      y_delta = pixel_y(@boundary[3]) - pixel_y(@boundary[2])

      new_point = []
      new_point[0] = ((pixel_x(adjust_point(point[0]) + @boundary[4]) - pixel_x(adjust_point(@boundary[0]) + @boundary[4])) * @width / x_delta).floor
      new_point[1] = ((pixel_y(@boundary[3]) - pixel_y(@point[1])) * @height / y_delta).floor

      return new_point
    end

    def draw_json(boundary)
      case @json['type']
      when 'GeometryCollection'
        #
      when 'FeatureCollection'
        #
      when 'Feature'
        #
      when 'Point'
        #
      when 'MultiPoint'
        #
      when 'LineString'
        #
      when 'MultiLineString'
        #
      when 'Polygon'
        #
      when 'MultiPolygon'
        #
      else
        puts "Invalid GeoJSON parse error"
      end
    end

    def draw
      boundary = get_boundary(@json)

      boundary[4] = 0

      if boundary[1] > boundary[0]
        draw_json($gd, boundary)
      else
        boundary[1] += 360;
        draw_json($gd, boundary)

        boundary[1] -= 360;
        boundary[0] -= 360;
        draw_json($gd, boundary)
      end

    end

  end
end
