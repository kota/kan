# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/kan_api_client.rb')
require File.expand_path(File.dirname(__FILE__) + '/models.rb')

class Kan
  attr_reader :decks, :ships, :material, :map
  
  def initialize
    @api_client = KanAPIClient.new
    @api_client.login
    @api_client.deck_port
    update_all
  end

  def update_all
    @api_client.logincheck
    @api_client.deck_port
    update_decks
    update_material
    update_ships
    update_docks
  end

  def update_decks
    json = @api_client.deck
    decks = json["api_data"]
    @decks = []
    decks.each do |deck|
      @decks << Deck.new(deck)
    end
  end

  def update_material
    json = @api_client.material
    @material = Material.new(json["api_data"])
  end

  def update_ships
    json = @api_client.ship
    ships = json["api_data"]
    @ships = []
    ships.each do |ship|
      @ships << Ship.new(ship)
    end
  end

  def update_docks
    json = @api_client.ndock
    docks = json["api_data"]
    @docks = []
    docks.each do |dock|
      @docks << Dock.new(dock)
    end
    @docks
  end

  def finish_missions
    @decks.each do |deck|
      if deck.mission_finished?
        @api_client.mission_result(deck.id)
      end
    end
  end

  def charge_deck(deck_id)
    deck = @decks.find{|d| d.id == deck_id}
    deck.ship_ids.each do |ship_id|
      @api_client.charge(ship_id) if ship_id != -1
    end
  end

  def change(ship_id,index,deck_id)
    @api_client.change(ship_id,index,deck_id)
  end

  def charge_and_start_mission(mission_id,deck_id)
    charge_deck(deck_id)
    @api_client.start_mission(mission_id,deck_id)
  end

  def start_mission_if_possible(mission_id,deck_id)
    deck = @decks.find{|d| d.id == deck_id}
    raise "deck not found" unless deck
    return if deck.in_mission?
    if deck.mission_finished?
      @api_client.mission_result(deck.id)
    end
    charge_and_start_mission(mission_id,deck_id)
  end

  def start_nyukyo(ship_id,dock_id,high_speed=0)
    @api_client.start_nyukyo(ship_id,dock_id,high_speed)
  end

  def start_nyukyo_if_possible(ship_id)
    dock_id = open_dock_id
    return unless dock_id #全ドック使用中
    ship = @ships.find{|s| s.id == ship_id}
    if ship.damaged? && enough_material_for_nyukyo?(ship_id)
      start_nyukyo(ship.id,dock_id)
    end
  end

  #ドックが空いていて資源が足りていれば損傷している船を入渠させる
  def nyukyo_any_ships_if_possible(ignore_small_damage=false)#trueならhpがmaxの80%以下になるまでは入渠しない
    dock_id = open_dock_id
    return unless dock_id
    damaged_ships = @ships.select do |ship|
      (ignore_small_damage ? !ship.enough_hp_for_battle? : ship.damaged?) && !in_dock?(ship.id) && enough_material_for_nyukyo?(ship.id)
    end
    return if damaged_ships.size == 0

    #入渠時間が少ない船艦から入渠させる
    damaged_ships.sort_by{|ship| ship.dock_time}.each do |ship|
      start_nyukyo(ship.id,dock_id)
      update_material
      update_ships
      update_docks
      return unless dock_id = open_dock_id
    end
  end

  #出撃
  def start_map(deck_id,maparea_id,mapinfo_no,formation_id=1)
    json = @api_client.start_map(deck_id,maparea_id,mapinfo_no,formation_id)
    @map = Map.new(json["api_data"])
  end

  def next_map
    @api_client.next
  end

  #戦闘
  def start_battle(formation_id)
    @battle = nil
    json = @api_client.start_battle(formation_id)
    @battle = Battle.new(json["api_data"])
  end

  def start_midnight_battle
    @api_client.start_midnight_battle
  end

  #戦闘結果
  def battle_result
    json = @api_client.battle_result
    result = BattleResult.new(json["api_data"])
  end

  def all_green?(deck_id)
    deck = @decks.find{|d| d.id == deck_id}
    return false unless deck
    return false if deck.in_mission?
    deck.ship_ids.all?{|id| ready_to_battle?(id)}
  end

  def ready_to_battle?(ship_id)
    ship = find_ship(ship_id)
    ship.all_green? & !in_dock?(ship_id)
  end

  def in_dock?(ship_id)
    @docks.map(&:ship_id).include?(ship_id)
  end

  def find_ship(ship_id)
    @ships.find{|s| s.id == ship_id}
  end

  def find_deck(deck_id)
    @decks.find{|d| d.id == deck_id}
  end

  private

  def open_dock_id
    dock = @docks.find{|d| d.state == 0}
    dock ? dock.id : nil
  end

  def enough_material_for_nyukyo?(ship_id)
    ship = @ships.find{|s| s.id == ship_id}
    ship.dock_items[0] <= @material.fuel && ship.dock_items[1] <= @material.steel
  end

end

