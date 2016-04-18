#encoding: utf-8
require 'command_line_reporter'

module Cartero
# Documentation:
# Class used to store helper methods used on Command
# that I do not want to include on Commands class.
class CommandHelpers
  include CommandLineReporter

  def generate_table(p, name)
    cols = Integer(`tput co`) - 20
    table do
      row(:color => 'red') do
        column("Command:", :width => 16, :bold => true)
        column(name, :width => cols)
      end
      p.each do |key,value|
        case value
        when String
          row(:color => 'blue') do
            column(key.to_s.capitalize + ":", :width => 16, :bold => true)
            column(value, :width => cols)
          end
        when Array
          row(:color => 'blue') do
            column(key.to_s.capitalize + ":")
            column(value[0])
          end
          value[1..-1].each do |v|
            row do
              column("")
              column(v, :width => cols)
            end
          end
        when Hash
          values = value.to_a
          row(:color => 'blue') do
            column(key.to_s.capitalize + ":")
            column(values[0][0].to_s + " = " + values[0][1].to_s)
          end
          values[1..-1].each do |k,v|
            row(:color => 'blue') do
              column("")
              column(k.to_s + " = " + v.to_s)
            end
          end
        end
      end
    end
  end
end
end
