# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/kan.rb')

class KanConsole

  def initialize 
    @kan = Kan.new
  end

  def run
    while(input = get_input)
      tokens = input.split(" ")
      if tokens[0] == 'help'
        if tokens.size == 1
          puts "commands: exit, material, decks, update, start_mission, charge_deck"
        else
          command_name = tokens[1]
          puts "#{help_for(command_name)}"
        end
      elsif tokens[0] == 'material'
        material = @kan.material
        puts "燃料:#{material.fuel} 弾薬:#{material.bullet}  鉄鋼:#{material.steel} ボーキサイト:#{material.bauxite}"
      elsif tokens[0] == 'decks'
        print_deck
      elsif tokens[0] == 'exit' || tokens[0] == 'quit'
        return
      elsif tokens[0] == 'update'
        @kan.update_all
        puts "updated."
      elsif tokens[0] == 'start_mission'
        puts "usage: mission mission_id deck_id" if tokens.size < 3
        mission_id = tokens[1].to_i
        deck_id = tokens[2].to_i
        @kan.start_mission_if_possible(mission_id,deck_id)
        puts "mission #{mission_id} started."
      elsif tokens[0] == 'charge_deck'
        puts "usage: charge_deck deck_id" if tokens.size < 2
        deck_id = tokens[1].to_i
        @kan.charge_deck(deck_id) 
        puts "deck #{deck_id} charged."
      else
        puts "invalid command #{tokens[0]}"
      end
    end
  end

  def print_deck
    decks = @kan.decks
    ships = @kan.ships
    decks.each do |deck|
      puts deck
      deck.ship_ids.each do |ship_id|
        if ship_id != -1
          ship = ships.find{|s| s.id == ship_id}
          print_ship(ship)
        end
      end
    end
  end

  def print_ship(ship)
    puts "  #{ship}"
  end

  def get_input
    print ">> "
    gets
  end

  def help_for(command_name)
    case command_name
    when "exit"
      "クライアントを終了します。"
    when "material"
      "資源を表示します。"
    when "decks"
      "艦隊一覧を表示します。"
    when "update"
      "情報を更新します。"
    when "start_mission"
      "指定した艦隊を補給して遠征を始めます。\n" +
      "usage: start_mission mission_id deck_id"
    when "charge_deck"
      "指定した艦隊を補給します\n" + 
      "usage: charge_deck deck_id"
    end
  end

end
