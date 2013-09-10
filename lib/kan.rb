# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/kan_api_client.rb')

class Deck
  attr_accessor :id, :ship_ids, :mission_id

  def initialize(json=nil)
    if json
      @id = json["api_id"]
      @ship_ids = json["api_ship"].map(&:to_i)
      @mission_state = json["api_mission"][0]
      @mission_id = json["api_mission"][1]
    end
  end

  def in_mission?
    @mission_state == 1
  end

  def mission_finished?
    @mission_state == 2
  end

end

class Material
  attr_accessor :fuel, :bullet, :steel, :bauxite

  def initialize(json=nil)
    if json
      json.each do |mat|
        value = mat["api_value"].to_i
        case mat["api_id"].to_i
        when 1
          @fuel = value
        when 2
          @bullet = value
        when 3
          @steel = value
        when 4
          @bauxite = value
        end
      end
    end
  end

end

class Ship
  attr_accessor :id, :name, :hp, :max_hp, :fuel, :max_fuel, :bullet, :max_bullet, :dock_items, :dock_time

  def initialize(json=nil)
    @id = json["api_id"].to_i
    @name = json["api_name"]
    @hp = json["api_nowhp"].to_i
    @max_hp = json["api_maxhp"].to_i
    @fuel = json["api_fuel"].to_i
    @max_fuel = json["api_fuel_max"].to_i
    @bullet = json["api_bull"].to_i
    @max_bullet = json["api_bull_max"].to_i
    @dock_items = json["api_ndock_item"].map(&:to_i)
    @dock_time = json["api_ndock_time"].to_i
  end

  def damaged?
    @hp < @max_hp
  end

  def need_supply?
    @fuel < @max_fuel || @bullet < @max_bullet
  end

end

class Dock
  attr_accessor :id, :state, :ship_id

  def initialize(json=nil)
    @id = json["api_id"].to_i
    @state = json["api_state"].to_i
    @ship_id = json["ship_id"].to_i
  end

end

class Kan
  attr_reader :decks, :ships, :material
  
  def initialize
    @api_client = KanAPIClient.new
    @api_client.login
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
  end

  def finish_missions
    @decks.each do |deck|
      if deck.mission_finished?
        @api_client.mission_result(deck.id)
      end
    end
  end

  def charge_and_start_mission(mission_id,deck_id)
    deck = @decks.find{|d| d.id == deck_id}
    deck.ship_ids.each do |ship_id|
      @api_client.charge(ship_id) if ship_id != -1
    end
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

