# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/kan.rb')
require File.expand_path(File.dirname(__FILE__) + '/kan_util.rb')
require 'colorize'

class KanConsole

  def initialize 
    @kan = Kan.new
    print_deck
  end

  def run
    while(input = get_input)
      tokens = input.split(" ")
      begin
       cmd = Command.new(self,tokens)
       return unless cmd.exec
      rescue => e
        puts e
      end
    end
  end

  class Command
    COMMAND_PARAMS = {
      help: {param_size: 0, usage: "help [command name]", description: "ヘルプです"},
      material: {param_size: 0, usage: "material", description: "資源を表示します"},
      decks: {param_size: 0, usage: "decks", description: "艦隊一覧を表示します"},
      ships: {param_size: 0, usage: "ships", description: "船艦一覧を表示します"},
      main_ships: {param_size: 0, usage: "main_ships", description: "kan_utilのmain_ship_idsで列挙されるIDを持つ船艦を表示します"},
      docks: {param_size: 0, usage: "docks", description: "ドック一覧を表示します"},
      update: {param_size: 0, usage: "udpate", description: "情報を更新します"},
      charge_deck: {param_size: 1, usage: "charge_deck deck_id", description: "指定した艦隊に補給します"},
      change: {param_size: 3, usage: "change ship_id index deck_id", description: "ship_idの船をdeck_idで指定される艦隊のindex番目に入れます。indexは0から数えます"},
      start_map: {param_size: 3, usage: "start_map deck_id maparea_id mapinfo_no", description: "出撃します。例：start_map 1 3 2 (艦隊１が3-2に出撃 )"},
      start_mission: {param_size: 2, usage: "mission mission_id deck_id", description: "遠征を開始します。"},
      exit: {param_size: 0, usage: "exit", description: "コンソールを終了します。"},
      quit: {param_size: 0, usage: "quit", description: "コンソールを終了します。"},
      build_all_green_deck: {param_size: 0, usage: "build_all_green_deck", description: "第一艦隊を出撃できる艦隊で編成し直します。艦船はkan_utilのmain_deck_poolsに列挙される艦船から選ばれます"}
    }
    
    def initialize(console,tokens,logger=nil)
      raise "no tokens" if tokens.size == 0
      @console = console
      @tokens = tokens
      @logger = logger
      @params = COMMAND_PARAMS[@tokens[0].to_sym]
      raise "invalid command: #{@tokens[0]}, type 'help' or 'help command_name' to see help." unless @params
    end

    def exec
      raise "#{@params[:description]}\nusage: #{@params[:usage]}" if @tokens.size < @params[:param_size] + 1
      method_name = @params[:method] ? @params[:method] : "exec_#{@tokens[0]}"
      @console.send(method_name,@tokens)
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

  def print_ship(ship,with_deck_id=false)
    if @kan.in_dock?(ship.id)
      puts "!#{ship}".red
    else
      deck = @kan.decks.find{|deck| deck.ship_ids.include?(ship.id)}
      deck_str = deck && with_deck_id ? deck.id : " "

      if !ship.all_green?
        s = ship.to_s
        attrs = s.split(", ")
        unless ship.enough_hp_for_battle?
          attrs[3] = attrs[3].on_yellow
        end
        unless ship.good_condition?
          attrs[4] = attrs[4].on_yellow
        end
        puts "#{deck_str}#{attrs.map(&:red).join(', ')}"
      else
        puts "#{deck_str}#{ship}"
      end
    end
  end

  def get_input
    print ">> "
    gets
  end

  #methods called by commands
  
  def exec_help(params)
    if params.size == 1
      puts "commands: #{Command::COMMAND_PARAMS.keys.join(',')}"
    else
      params = Command::COMMAND_PARAMS[params[1].to_sym]
      puts params[:description]
      puts "usage: #{params[:usage]}"
    end
    true
  end

  def exec_material(params)
    material = @kan.material
    puts "燃料:#{material.fuel} 弾薬:#{material.bullet}  鉄鋼:#{material.steel} ボーキサイト:#{material.bauxite}"
    true
  end

  def exec_decks(params)
    print_deck
    true
  end

  def exec_ships(params)
    @kan.ships.each{|ship| print_ship(ship,true)}
    true
  end

  def exec_main_ships(params)
    util = KanUtil.new
    util.main_deck_pools.each do |pool|
      ships = @kan.ships.select{|s| pool.include?(s.id)}
      ships.each{|ship| print_ship(ship,true)}
      puts
    end
    true
  end

  def exec_change(params)
    ship_id = params[1].to_i
    index = params[2].to_i
    deck_id = params[3].to_i
    @kan.change(ship_id,index,deck_id)
    @kan.update_all
    puts "交替しました"
    print_deck
    true
  end

  def exec_docks(params)
    @kan.update_docks.each{|dock| puts dock}
    true
  end

  def exec_start_map(params)
    deck_id = params[1].to_i
    maparea_id = params[2].to_i
    mapinfo_no = params[3].to_i
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
      @kan.charge_deck(deck_id)
      @kan.update_all
      print_deck
    else
      puts "資源を拾いました"
    end
    true
  end

  def exec_charge_deck(params)
    deck_id = params[1].to_i
    @kan.charge_deck(deck_id) 
    @kan.update_all
    puts "deck #{deck_id} charged."
    print_deck
    true
  end

  def exec_start_mission(param)
    mission_id = params[1].to_i
    deck_id = params[2].to_i
    @kan.start_mission_if_possible(mission_id,deck_id)
    puts "mission #{mission_id} started."
    true
  end

  def exec_update(params)
    @kan.update_all
    puts "updated."
    true
  end

  def exec_exit(params)
    false 
  end

  def exec_quit(params)
    false
  end

  def exec_build_all_green_deck(params)
    util = KanUtil.new(@kan)
    if util.build_all_green_deck
      puts "艦隊を編成しました"
      @kan.update_all
      print_deck
    else
      puts "出撃できる艦隊を編成できませんでした"
    end
    true
  end

end
