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
        if tokens.size < 3
          puts "usage: mission mission_id deck_id" 
        else
          mission_id = tokens[1].to_i
          deck_id = tokens[2].to_i
          @kan.start_mission_if_possible(mission_id,deck_id)
          puts "mission #{mission_id} started."
        end
      elsif tokens[0] == 'charge_deck'
        if tokens.size < 2
          puts "usage: charge_deck deck_id" 
        else
          deck_id = tokens[1].to_i
          @kan.charge_deck(deck_id) 
          puts "deck #{deck_id} charged."
        end
      elsif tokens[0] == "start_map"
        if tokens.size < 4
          puts "usage: start_map deck_id maparea_id mapinfo_no"
        else
          deck_id = tokens[1].to_i
          maparea_id = tokens[2].to_i
          mapinfo_no = tokens[3].to_i
          map = @kan.start_map(deck_id,maparea_id,mapinfo_no)
          if map.enemy?
            formation_id = 0
            while(!(1..5).include?(formation_id))
              puts "敵に遭遇しました。陣形を選んでください。(1~5)"
              formation_id = get_input.to_i
            end
            battle = @kan.start_battle(formation_id)
            if battle.midnight?
              do_midnight = nil
              while(!(do_midnight == 'y' || do_midnight == 'n'))
                puts "夜戦を行いますか？ y/n"
                do_midnight = get_input.strip
              end
              @kan.start_midnight_battle if do_midnight
            end
            battle_result = @kan.battle_result
            puts battle_result
            @kan.update_all
          else
            puts "資源を拾いました"
          end
        end
      elsif tokens[0] == "docks"
        docks = @kan.update_docks
        docks.each{|dock| puts dock}
      else
        puts "invalid command: #{tokens[0]}, type 'help' or 'help command_name' to see help."
      end
    end
  end

  private

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
    when "start_map"
      "出撃します\n" + 
      "usage: start_map deck_id maparea_id, mapinfo_no\n" + 
      "example: start_map 1 3 2\n" +
      "デッキ1を3-2の海域に出撃させます"
    end
  end

end
