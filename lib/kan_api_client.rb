# -*- coding: utf-8 -*-
require 'rubygems'
require 'mechanize'
require 'json'
require 'yaml'
require 'logger'

class KanAPIClient

  SWF_VERSION = "1.3.8"
  API_HOST = "http://125.6.189.7"
  API_BASE_URL = API_HOST + "/kcsapi"

  def initialize
    @agent = Mechanize.new
    config = YAML.load_file(File.expand_path('../../config.yml', __FILE__))
    @email = config["email"]
    @password = config["password"]
    @logger = Logger.new(File.expand_path('../../api.log', __FILE__))
  end

  def login
    login_page = @agent.get("https://www.dmm.com/my/-/login")
    page = login_page.form_with(:action => 'https://www.dmm.com/my/-/login/auth/') do |form|
      form.login_id = @email
      form.password = @password
    end.submit
    
    top_page = @agent.get("http://www.dmm.com/netgame/social/-/gadgets/=/app_id=854854/")
    
    swf_src = top_page.iframes[0].src
    st = URI.unescape(swf_src.split("&st=")[1].split("#rpctoken")[0])

    swf_src =~ /owner\=(.*?)\&/
    owner = $1
    
    response = @agent.post('http://osapi.dmm.com/gadgets/makeRequest',
    {
      "url" =>  "#{API_BASE_URL}/api_auth_member/dmmlogin/#{owner}/1/1378145601790",
      "httpMethod" => "GET",
      "headers" => nil,
      "postData" => nil,
      "authz" => "signed",
      "st" => st,
      "contentType" => "JSON",
      "numEntries" => 3,
      "getSummaries" => false,
      "signOwner" => true,
      "signViewer" => true,
      "gadget" => "http://203.104.105.167/gadget.xml",
      "container" => "dmm",
      "bypassSpecCache" => nil,
      "getFullHeaders" => false,
      "oauthState" => nil,
    })
    
    body = URI.unescape(response.body)
    body =~ /\\\"api_token\\\"\:\\\"(.*?)\\\"/
    @api_token = $1
  end
  
  def api_post(path,params)
    base_params = {
      "api_verno" => 1,
      "api_token" => @api_token
    }
    response = @agent.post(API_BASE_URL + path,
                          params.merge(base_params),
                          {"Referer" => "#{API_HOST}/kcs/port.swf?version=#{SWF_VERSION}"})
    str = URI.unescape(response.body).split("=")[1..-1].join #先頭のsvdata=を消す
    json = JSON.parse(str)
    @logger.info "path = #{path}, params = #{params}, response = #{json}"
    json
  end

  #用途不明
  def start
    path = "/api_start"
    params = {}
    api_post(path,params)
  end

  #用途不明
  def logincheck
    path = "/api_auth_member/logincheck"
    params = {}
    api_post(path,params)
  end

  #ユーザ情報取得
  def basic
    path = "/api_get_member/basic"
    params = {}
    api_post(path,params)
  end

  #船情報取得
  def ship2
    path = "/api_get_member/ship2"
    params = {}
    api_post(path,params)
  end

  #艦隊情報取得
  def deck_port
    path = "/api_get_member/deck_port"
    params = {}
    api_post(path,params)
  end

  #艦隊情報取得
  def deck
    path = "/api_get_member/deck"
    params = {}
    api_post(path,params)
  end

  #遠征開始
  def start_mission(mission_id,deck_id)
    path = "/api_req_mission/start"
    params = {"api_deck_id" => deck_id, "api_mission_id" => mission_id}
    api_post(path,params)
  end

  #遠征結果取得
  def mission_result(deck_id)
    path = "/api_req_mission/result"
    params = {"api_deck_id" => deck_id}
    api_post(path,params)
  end

  #まとめて補給
  def charge(ship_ids)
    path = "/api_req_hokyu/charge"
    params = {"api_kind" => 3, "api_id_items" => ship_ids}
    api_post(path,params)
  end

  #def start_nyukyo(ship_id,dock_id)
  #  params = {
  #    "api_ship_id" => ship_id,
  #    "api_ndock_id" => dock_id,
  #    "api_highspeed" => 0,
  #  }
  #end

end
