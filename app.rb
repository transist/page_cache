require 'rubygems'
require 'bundler'
require 'sinatra'
require 'yajl'

Bundler.require
set :mongo_db, 'page_cache'

require 'uri'

configure :development do
  enable :logging, :dump_errors, :run, :sessions
  Mongoid.load!(File.join(File.dirname(__FILE__), "config", "mongoid.yml"))
end

class Page
  include Mongoid::Document
  field :url, type: String
  field :html, type: String
  field :text, type: String
  
  def self.init(u)   
    Spider.new(:url => u).perform.save if Page.where(:url => u).first_or_create.html == nil
    Page.where(:url => u).first
  end
end

class Spider
  attr_accessor :url, :user_agent, :html, :page, :cache
  
  def initialize(options)
    self.url = options[:url]
    self.user_agent = (options[:user_agent] || "Echidna")
    self.cache = (options[:user_agent] || true)
    self.page = Page.where(:url => self.url).first_or_create
  end
  
  def perform
    c = Curl::Easy.new(self.url) do|curl|
      curl.follow_location = true
    end
    c.perform
    self.html = c.body_str
    self
  end
  
  def save
    p = Page.where(:url => self.url).first_or_create
    p.html = self.html
    p.save
    p
  end
end

get '/' do
  content_type 'application/json'
  page = Page.init(params[:url])
  page = Yajl::Encoder.encode page
  page
end
