# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/kan.rb')

class KanConsole

  def initialize 
    @kan = Kan.new
  end

  def run
    while(input = get_input)
      tokens = input.split(" ")
      if tokens[0] == 'material'
        material = @kan.material
        puts "燃料:#{material.fuel} 弾薬:#{material.bullet}  鉄鋼:#{material.steel} ボーキサイト:#{material.bauxite}"
      elsif tokens[0] == 'exit' || tokens[0] == 'quit'
        return
      else
        puts "invalid command #{tokens[0]}"
      end
    end
  end

  def get_input
    print ">> "
    gets
  end

end

console = KanConsole.new
console.run
