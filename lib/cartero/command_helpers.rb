require 'command_line_reporter'

module Cartero
class CommandHelpers
  include CommandLineReporter

  def generate_table(p, name)
    cols = Integer(`tput co`) / 2
    table do
      row do
        column("Command:", :width => 16, :bold => true)
        column(name, :width => cols)
      end
      row do
        column("-"*16)
        column("-"*cols)
      end
      p.each do |key,value|
        case value
        when String
          row do
            column(key.to_s.capitalize! + ":", :width => 16, :bold => true)
            column(value, :width => cols)
          end
        when Array
          row do
            column(key)
            column(value[0])
          end
          value[1..-1].each do |v|
            row do
              column("")
              column(v, :width => cols)
            end
          end
        end

        row do
          column("")
          column("")
        end
      end
    end
  end
end
end
