# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/kan_api_client.rb')

class Deck
  attr_accessor :id, :ship_ids, :mission_id

  def initialize(json=nil)
    if json
      @id = json["api_id"]
      @ship_ids = json["api_ship"]
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

class Kan
  
  def initialize
    @api_client = KanAPIClient.new
    @api_client.login
    @api_client.deck_port
    update_decks
  end

  def update_decks
    json = @api_client.deck
    decks = json["api_data"]
    @decks = []
    decks.each do |deck|
      @decks << Deck.new(deck)
    end
  end

  def finish_missions
    @decks.each do |deck|
      if deck.mission_finished?
        @api_client.mission_result(deck.id)
      end
    end
  end

  def start_mission(mission_id,deck_id)
    deck = @decks.find{|d| d.id == deck_id}
    deck.ship_ids.each do |ship_id|
      @api_client.charge(ship_id)
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
    start_mission(mission_id,deck_id)
  end

end
