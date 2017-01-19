require "geojson2image/version"
require "oj"

module Geojson2image
  class Convert
    attr_accessor :json, :width, :height, :boundary

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
        # error invalid GeoJSON type
      end
    end

    def pixel_x(x)
      (x.to_f + 180) / 360
    end

    def pixel_y(y)
      sin_y = Math.sin(y.to_f * Math::PI / 180)
      return (0.5 - Math.log((1 + sin_y) / (1 - sin_y)) / (4 * Math::PI))
    end

    def transform_point
    end

    def draw_json
    end

    def draw
    end

  end
end
