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
  def nyukyo_any_ships_if_possible
    dock_id = open_dock_id
    return unless dock_id
    @ships.each do |ship|
      if ship.damaged? && !in_dock?(ship.id) && enough_material_for_nyukyo?(ship.id)
        start_nyukyo(ship.id,dock_id)
        update_material
        update_ships
        update_docks
        return unless dock_id = open_dock_id
      end
    end
  end

  #出撃
  def start_map(deck_id,maparea_id,mapinfo_no,formation_id=1)
    json = @api_client.start_map(deck_id,maparea_id,mapinfo_no,formation_id)
    puts json
    @map = Map.new(json["api_data"])
  end

  #戦闘
  def start_battle(formation_id)
    @battle = nil
    json = @api_client.start_battle(formation_id)
    puts json
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

  private

  def open_dock_id
    dock = @docks.find{|d| d.state == 0}
    dock ? dock.id : nil
  end

  def in_dock?(ship_id)
    @docks.map(&:ship_id).include?(ship_id)
  end

  def enough_material_for_nyukyo?(ship_id)
    ship = @ships.find{|s| s.id == ship_id}
    ship.dock_items[0] <= @material.fuel && ship.dock_items[1] <= @material.steel
  end

end

